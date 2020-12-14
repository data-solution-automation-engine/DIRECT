/*
Process: Batch Evaluation
Purpose: Checks if the Batch Instance is able to proceed, based on the state of all Batch Instances related to the particular Batch.
Input: 
  - Batch Instance Id
  - Debug flag Y/N (default to N)
Returns:
  - ProcessIndicator
Usage:
    DECLARE @ProcessIndicator VARCHAR(10);
    EXEC [omd].[BatchEvaluation]
      @BatchInstanceId = <Id>,
      @ProcessIndicator = @ProcessIndicator OUTPUT;
    PRINT @ProcessIndicator;
*/

CREATE PROCEDURE [omd].[BatchEvaluation]
	@BatchInstanceId INT, -- The Batch Instance Id
	@Debug VARCHAR(1) = 'N',
	@ProcessIndicator VARCHAR(10) = NULL OUTPUT
AS

BEGIN
  SET NOCOUNT ON;

  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;

  DECLARE @BatchId INT;
  DECLARE @ActiveInstanceCount INT;

  IF @Debug = 'Y'
    PRINT '-- Beginning of Batch Evaluation for Batch Instance Id '+CONVERT(VARCHAR(10),@BatchInstanceId);

  SELECT @BatchId = omd.GetBatchIdByBatchInstanceId(@BatchInstanceId);

  IF @Debug = 'Y'
    PRINT 'For Batch Instance Id '+CONVERT(VARCHAR(10),@BatchInstanceId)+' the Batch Id '+CONVERT(VARCHAR(10),@BatchId)+' was found in omd.BATCH.';

  /* 
    Region: Check for multiple active Batch Instances
	Multiple active instances indicate corruption in the DIRECT repository.
  */

  IF @Debug = 'Y'
    PRINT CHAR(13)+'-- Beginning of active instance checks.';
       
  -- Check if there are no additional running instances other than the current Batch Instance. The count should be 0.
  SELECT @ActiveInstanceCount = COUNT(*)
  FROM omd.BATCH_INSTANCE 
  WHERE EXECUTION_STATUS_CODE = 'E' 
    AND BATCH_ID = @BatchId and BATCH_INSTANCE_ID < @BatchInstanceId            

  IF @Debug = 'Y'
  BEGIN
    PRINT 'The number of active Batch Instances is '+COALESCE(CONVERT(VARCHAR(10),@ActiveInstanceCount),'0')+'.';
  END

  IF @ActiveInstanceCount = 0
    BEGIN
	  -- Continue,  there is no other active instance for this Batch.
	  IF @Debug = 'Y'
	    PRINT 'Either there are no other active instance for the Batch (except this one), so the evaluation can continue.'
     
	 -- Go to the next step in the process.
	  GOTO BatchInactiveEvaluation
	END
  ELSE -- There are already multiple running instances for the same Batch, the process must be aborted.
	BEGIN
	  IF @Debug = 'Y'
	    PRINT 'There are multiple running instances for the same Batch, the process must be aborted (abort and go to end of procedure).'

	  -- Call the Abort event.
	  EXEC [omd].[UpdateBatchInstance]
		@BatchInstanceId = @BatchInstanceId,
		@EventCode = N'Abort',
		@Debug = @Debug

      SET @ProcessIndicator = 'Abort';
	  GOTO EndOfProcedure
	  -- End
	END

  BatchInactiveEvaluation:
  /* 
    Region: Batch active check.
	In case the Batch is has an INACTIVE_INDICATOR='N' the pcoess can be cancelled / skipped as the Batch is not supposed to run.
  */
  DECLARE @BatchInactiveIndicator VARCHAR(1);

  IF @Debug='Y'
    PRINT CHAR(13)+'-- Start of Batch Inactive evalation step.';
	
  SELECT @BatchInactiveIndicator = INACTIVE_INDICATOR
  FROM omd.BATCH
  WHERE BATCH_ID= @BatchId                

  IF @BatchInactiveIndicator = 'N' -- The Batch is enabled, so the process can continue.
    BEGIN

	  IF @Debug='Y'
        PRINT 'The Batch is enabled (Inactive Indicator is set to '+@BatchInactiveIndicator+'), so the process can continue.';

	  GOTO RollBackEvaluation -- Go to the next process step after this section.
    END
  ELSE -- Batch has something else than 'N' and should be skipped / cancelled.
    BEGIN 
      IF @Debug='Y'
      	PRINT 'The Batch is disabled (Inactive Indicator is set to '+@BatchInactiveIndicator+'), so the process must cancel / skip.';
              
      -- Call the Cancel (skip) event.
      EXEC [omd].[UpdateBatchInstance]
        @BatchInstanceId = @BatchInstanceId,
      	@EventCode = N'Cancel',
        @Debug = @Debug
      
      SET @ProcessIndicator = 'Cancel';
      GOTO EndOfProcedure 
    END


  /* 
    Region: rollback.
	Any erroneous previous instances must be rolled-back before processing can continue.
  */
  RollBackEvaluation:

  IF @Debug='Y'
	PRINT CHAR(13)+'-- Start of rollback evaluation process step.';

  DECLARE @LastExecutionStatusCode VARCHAR(1);
  DECLARE @LastNextRunIndicator VARCHAR(1);

  -- Get the Next Run Indicator and Execution Status Code from the previous Batch Instance.
  DECLARE @PreviousBatchInstanceTable TABLE
  (
    LastExecutionStatusCode VARCHAR(1),
    LastNextRunIndicator VARCHAR(1)
  );

  INSERT @PreviousBatchInstanceTable 
  SELECT * FROM [omd].[GetPreviousBatchInstanceDetails](@BatchId)

  SELECT @LastExecutionStatusCode = LastExecutionStatusCode FROM @PreviousBatchInstanceTable;
  IF @Debug='Y'
    PRINT 'The previous Batch Instance Execution Status Code is '+@LastExecutionStatusCode;

  SELECT @LastNextRunIndicator = LastNextRunIndicator FROM @PreviousBatchInstanceTable;
  IF @Debug='Y'
    PRINT 'The previous Batch Instance Next Run Indicator is '+@LastNextRunIndicator;

  -- Proceed
  -- The execution can proceed if the previous run for the Batch (the previous Batch Instance) was without failure, was not set to rerun and was not cancelled.
  IF ( (@LastExecutionStatusCode != 'F') AND (@LastNextRunIndicator NOT IN ('C','R')) ) 
    BEGIN
	  IF @Debug='Y'
	    PRINT 'The last Execution Flag is '+@LastExecutionStatusCode+' and last Next Run Indicator is '+@LastNextRunIndicator+'. The process can proceed (no rollback is required).';

	  IF @Debug='Y'
		PRINT 'The Batch Instance will be set to proceed';

	  EXEC [omd].[UpdateBatchInstance]
	    @BatchInstanceId = @BatchInstanceId,
		@EventCode = N'Proceed',
	    @Debug = @Debug

	   SET @ProcessIndicator = 'Proceed';
	   GOTO EndOfProcedure
    END

  -- Proceed with RollBack.
  -- If the previous Batch Instance has failed and the previous next run indicator is not set to skip OR the previous next run indicator is set to rerun the rollback step must be initiatied.
  IF ( (@LastExecutionStatusCode = 'F' AND @LastNextRunIndicator != 'C') OR @LastNextRunIndicator = 'R' ) 
    BEGIN
	  IF @Debug='Y'
	    PRINT 'The last Execution Flag is '+@LastExecutionStatusCode+' and last Next Run Indicator is '+@LastNextRunIndicator+'. The process must initiate a rollback.';

	  IF @Debug='Y'
		PRINT 'The Batch Instance will be set to rollback.';

     -- NOTE the below status update on the Batch Instance will always trigger a full rollback, whereas partial rollback is the default.
	      
	 -- EXEC [omd].[UpdateBatchInstance]
	 --   @BatchInstanceId = @BatchInstanceId,
		--@EventCode = N'Rollback',
	 --   @Debug = @Debug

	  SET @ProcessIndicator = 'Rollback';
	  GOTO CallRollback
    END


  /*
    Region: execution of rollback.
	Call the rollback procedure for the current Batch.
	Technically, this is disabling any Modules that were part of earlier failed Batches, as the rollback itself happens at Module level.
  */

  CallRollback:
  
  IF @Debug='Y'
	PRINT CHAR(13)+'-- Start of rollback evaluation process step.';

  DECLARE @SqlStatement VARCHAR(MAX);

  DECLARE @FailedBatchIdArray VARCHAR(MAX) = omd.[GetFailedBatchIdList](@BatchId);

  IF @Debug='Y'
	PRINT 'The array of earlier failed Batch Instances is '+@FailedBatchIdArray+'.';

  IF @LastNextRunIndicator = 'R' -- Full rollback for all Modules in the Batch.
    BEGIN  
      BEGIN TRY

	    SET @SqlStatement = 'UPDATE omd.MODULE_INSTANCE SET NEXT_RUN_INDICATOR = ''R'' WHERE BATCH_INSTANCE_ID IN '+@FailedBatchIdArray;

		IF @Debug='Y'
		  PRINT 'Rollback SQL statement (full) is: '+@SqlStatement;

		EXEC (@SqlStatement);

        -- After rollback is completed, the process is allowed to continue.
        IF @Debug='Y'
          PRINT 'The Module Instance will be set to proceed';

	    EXEC [omd].[UpdateBatchInstance]
	      @BatchInstanceId = @BatchInstanceId,
	      @EventCode = N'Proceed',
	     @Debug = @Debug

	    SET @ProcessIndicator = 'Proceed';
        GOTO EndOfProcedure

     END TRY
	 BEGIN CATCH

		-- Batch Failure
       EXEC [omd].[UpdateBatchInstance]
	      @BatchInstanceId = @BatchInstanceId,
		  @Debug = @Debug,
		  @EventCode = 'Failure';
	    SET @ProcessIndicator = 'Failure';

  	    -- Logging
	   SET @EventDetail = ERROR_MESSAGE();
	   SET @EventReturnCode = ERROR_NUMBER();
	   
	   EXEC [omd].[InsertIntoEventLog]
	     @BatchInstanceId = @BatchInstanceId,
	     @EventDetail = @EventDetail,
	     @EventReturnCode = @EventReturnCode;

	   THROW
	 END CATCH
  END

  IF @LastNextRunIndicator = 'P' -- Partial rollback - skip previously succesfull Modules in the Batch.
    BEGIN  
      BEGIN TRY

	    SET @SqlStatement = 'UPDATE omd.MODULE_INSTANCE SET NEXT_RUN_INDICATOR = ''C'' WHERE EXECUTION_STATUS_CODE!=''F'' AND BATCH_INSTANCE_ID IN '+@FailedBatchIdArray;

		IF @Debug='Y'
		  PRINT 'Rollback SQL statement (partial) is: '+@SqlStatement;

		EXEC (@SqlStatement);

        -- After rollback is completed, the process is allowed to continue.
        IF @Debug='Y'
          PRINT 'The Batch Instance will be set to proceed';

	    EXEC [omd].[UpdateBatchInstance]
	      @BatchInstanceId = @BatchInstanceId,
	      @EventCode = N'Proceed',
	     @Debug = @Debug

	    SET @ProcessIndicator = 'Proceed';
        GOTO EndOfProcedure

     END TRY
	 BEGIN CATCH
		-- Batch Failure
       EXEC [omd].[UpdateBatchInstance]
	      @BatchInstanceId = @BatchInstanceId,
		  @Debug = @Debug,
		  @EventCode = 'Failure';
	    SET @ProcessIndicator = 'Failure';

  	    -- Logging
	   SET @EventDetail = ERROR_MESSAGE();
	   SET @EventReturnCode = ERROR_NUMBER();
	   
	   EXEC [omd].[InsertIntoEventLog]
	     @BatchInstanceId = @BatchInstanceId,
	     @EventDetail = @EventDetail,
	     @EventReturnCode = @EventReturnCode;

	   THROW
	 END CATCH
  END

  -- All branches completed

  -- The procedure should not be able to end in this part.
  -- Batch Failure
  EXEC [omd].[UpdateBatchInstance]
    @BatchInstanceId = @BatchInstanceId,
    @Debug = @Debug,
    @EventCode = 'Failure';

  SET @ProcessIndicator = 'Failure';

  RAISERROR('Incorrect Batch Evaluation path encountered (post-rollback).',1,1)

  /*
    Region: end of processing, final step.
  */

  EndOfProcedure:
   -- End label

  IF @Debug = 'Y'
  BEGIN
     BEGIN TRY
       PRINT 'Batch Instance Id '+CONVERT(VARCHAR(10),@BatchInstanceId)+' was processed';
       PRINT 'The result (processing indicator) is '+@ProcessIndicator;  
       PRINT CHAR(13)+'-- Batch Evaluation completed.';
	 END TRY
	 BEGIN CATCH

	   -- Logging
	   SET @EventDetail = ERROR_MESSAGE();
	   SET @EventReturnCode = ERROR_NUMBER();
	   
	   EXEC [omd].[InsertIntoEventLog]
	     @BatchInstanceId = @BatchInstanceId,
	     @EventDetail = @EventDetail,
	     @EventReturnCode = @EventReturnCode;

	   THROW
	 END CATCH
  END

END