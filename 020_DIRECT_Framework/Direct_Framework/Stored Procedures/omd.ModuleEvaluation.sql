/*
Process: Module Evaluation
Purpose: Checks if the Module Instance is able to proceed, based on the state of all Module Instances for the particular Module.
Input: 
  - Module Instance Id
  - Debug flag Y/N (default to N)
Returns:
  - ProcessIndicator
Usage:
    DECLARE @ProcessIndicator VARCHAR(10);
    EXEC [omd].[ModuleEvaluation]
      @ModuleInstanceId = <Id>,
      @ProcessIndicator = @ProcessIndicator OUTPUT;
    PRINT @ProcessIndicator;
*/

CREATE PROCEDURE [omd].[ModuleEvaluation]
	@ModuleInstanceId INT, -- The Batch Instance Id, if the Module is run from a Batch.
	@Debug VARCHAR(1) = 'N',
	@ProcessIndicator VARCHAR(10) = NULL OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET ANSI_WARNINGS OFF; -- Suppress NULL elimination warning within SET operation.

  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;

  DECLARE @ModuleId INT;
  DECLARE @BatchId INT;
  DECLARE @MinimumActiveModuleInstance INT;
  DECLARE @ActiveModuleInstanceCount INT;
  DECLARE @BatchModuleInactiveIndicator VARCHAR(3);

  IF @Debug = 'Y'
    PRINT '-- Beginning of Module Evaluation for Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId);

  SELECT @ModuleId = omd.GetModuleIdByModuleInstanceId(@ModuleInstanceId);

  IF @Debug = 'Y'
    PRINT 'For Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' the Module Id '+CONVERT(VARCHAR(10),@ModuleId)+' was found in omd.MODULE.';

  /* 
    Region: Check for multiple active Module Instances
	Multiple active instances indicate corruption in the DIRECT repository.
  */
  IF @Debug = 'Y'
    PRINT CHAR(13)+'-- Beginning of active instance checks.';

  -- Check for the lowest instance of the Module Instances since the process must continue if it's the first of the started instances for the particular Module.  
  SELECT @MinimumActiveModuleInstance =
    MIN(MODULE_INSTANCE_ID)  
  FROM omd.MODULE_INSTANCE
  WHERE EXECUTION_STATUS_CODE = 'E' 
    AND MODULE_ID = @ModuleId
  GROUP BY MODULE_ID
        
  -- Check if there are no additional running instances other than the current Module Instance. The count should be 1.
  SELECT @ActiveModuleInstanceCount = 
    COUNT(*)
  FROM omd.MODULE_INSTANCE
  WHERE EXECUTION_STATUS_CODE = 'E' 
     AND MODULE_ID = @ModuleId
     AND MODULE_INSTANCE_ID != @ModuleInstanceId
  GROUP BY MODULE_ID

  IF @Debug = 'Y'
  BEGIN
    PRINT 'The number of active Module Instances is '+COALESCE(CONVERT(VARCHAR(10),@ActiveModuleInstanceCount),'0')+'.';
    PRINT 'The minimum active Module Instance Id is '+COALESCE(CONVERT(VARCHAR(10),@MinimumActiveModuleInstance),'0')+'.';
  END

  IF (@ActiveModuleInstanceCount IS NULL) OR (@ActiveModuleInstanceCount IS NOT NULL AND @MinimumActiveModuleInstance = @ModuleInstanceId)
    BEGIN
	  -- Continue, either there is only 1 active instance for the Module (this one) OR this instance is the first of many running instances and this one should be allowed to continue.
	  IF @Debug = 'Y'
	    PRINT 'Either there is only 1 active instance for the Module (this one) OR this instance is the first (MIN) of many running instances and should be allowed to continue.'
     
	 -- Go to the next step in the process.
	  GOTO BatchModuleEvaluation
	END
  ELSE -- There are already multiple running instances for the same Module, the process must be aborted.
	BEGIN
	  IF @Debug = 'Y'
	    PRINT 'There are already multiple running instances for the same Module, the process must be aborted. (abort and go to end of procedure).'

	  -- Call the Abort event.
	  EXEC [omd].[UpdateModuleInstance]
		@ModuleInstanceId = @ModuleInstanceId,
		@EventCode = N'Abort',
		@Debug = @Debug

      SET @ProcessIndicator = 'Abort';
	  GOTO EndOfProcedure
	  -- End
	END

  BatchModuleEvaluation:
  /* 
    Region: Batch/Module relationship validation.
	In case the Module is called from a parent Batch this task verifies if the administration is done properly
	and if the Module is disabled as part of the Batch configuration (BATCH_MODULE).

	If the current instance is started from a Batch (Batch Instance <> 0) then the Batch / Module flag must be set to INACTIVE_INDICATOR='N'
	If the current instance has a Batch Instance Id (or Batch Id) of 0 then this step can be skipped, as the Module was not started by a Batch.
  */

  SELECT @BatchId = omd.GetBatchIdByModuleInstanceId(@ModuleInstanceId);

  IF @Debug='Y'
    PRINT CHAR(13)+'-- Start of Batch / Module relationship evalation step.';
	PRINT 'The Batch Id found is '+CONVERT(VARCHAR(10),@BatchId);
	
  IF @BatchId = 0 -- The Module was run stand-alone (not from a Batch).
    BEGIN
	  -- The Module Instance was not started from a Batch, so processing can skip this step and continue.
	  IF @Debug='Y'
        PRINT 'The Module Instance was not started from a Batch (0), so processing can skip this step and continue to Rollback Evaluation.';

	  GOTO RollBackEvaluation -- Go to the next process step after this section.
    END
  ELSE -- Batch Id has a value, so the Module was run from a Batch and we need to check if the Module is active for the Batch.
    BEGIN

	  IF @Debug='Y'
        PRINT 'The Module Instance was  started from a Batch (Id: '+CONVERT(VARCHAR(10),@BatchId)+'), so processing will evaluate if the Batch/Module registration is correct.';

	  -- The Module Instance was started by a Batch, so we must check if the Module is allowed to run.
	  SELECT @BatchModuleInactiveIndicator= omd.[GetBatchModuleActiveIndicatorValue](@BatchId,@ModuleId)	  

	  IF @Debug='Y'
		PRINT 'The Batch / Module inactive flag value is '+@BatchModuleInactiveIndicator;

      IF (@BatchModuleInactiveIndicator='Y') -- Skip
      BEGIN
	  	IF @Debug='Y'
		  PRINT 'The Module Instance will be skipped / cancelled';

	    -- If the inactive indicator at Batch/Module level is set to 'Y' the process is disabled in the framework.
	    -- In this case, the Module must be skipped / cancelled (was attempted to be run, but not allowed).
	   
	    -- Call the Cancel (skip) event.
	    EXEC [omd].[UpdateModuleInstance]
	  	  @ModuleInstanceId = @ModuleInstanceId,
		  @EventCode = N'Cancel',
	      @Debug = @Debug

		SET @ProcessIndicator = 'Cancel';
	    GOTO EndOfProcedure
		-- End
      END

	  IF (@BatchModuleInactiveIndicator = 'N/A') -- Abort
        BEGIN
	  	  IF @Debug='Y'
		    PRINT 'The Module Instance will be aborted.';

	      -- If the inactive indicator at Batch/Module level is NULL then there is an error in the framework registration / setup.
	      -- In this case, the Module must be aborted. The module was attempted to be run form a Batch it is not registered for).
	  
	      -- Call the Abort event.
	      EXEC [omd].[UpdateModuleInstance]
		    @ModuleInstanceId = @ModuleInstanceId,
		    @EventCode = N'Abort',
		    @Debug = @Debug

          SET @ProcessIndicator = 'Abort';
	      GOTO EndOfProcedure
	      -- End
        END
	  ELSE -- Continue with regular processing
	    GOTO RollBackEvaluation

	  -- The procedure should not be able to end in this part.
	  -- Logging and exception handling
	  SET @EventDetail = 'Incorrect Module Evaluation path encountered during BatchModuleEvaluation step.'

	  EXEC [omd].[InsertIntoEventLog]
	    @ModuleInstanceId = @ModuleInstanceId,
		@EventDetail = @EventDetail;
		
      GOTO ModuleFailure
	   --THROW 50000,@EventDetail,1;	   
	END


  RollBackEvaluation:
  /* 
    Region: rollback.
	Any erroneous previous instances must be rolled-back before processing can continue.
  */

  IF @Debug='Y'
	PRINT CHAR(13)+'-- Start of rollback evaluation process step.';

  DECLARE @PreviousModuleInstanceTable TABLE
  (
    LastBatchInstanceID INT,
    LastModuleInstanceID INT ,
    LastStartTime DATETIME2(7),
    LastEndTime DATETIME2(7),
    LastExecutionStatus VARCHAR(1),
    LastNextExecutionFlag VARCHAR(1),
    LastModuleInstanceIDList VARCHAR(MAX),
    InactiveIndicator VARCHAR(1)
  );

  INSERT @PreviousModuleInstanceTable 
  SELECT * FROM [omd].[GetPreviousModuleInstanceDetails](@ModuleId,@BatchId)

  -- If the previously completed Module Instance (for the same Module) is set to skip OR the module is set to inactive the run must be cancelled.
  IF ((SELECT LastNextExecutionFlag FROM @PreviousModuleInstanceTable) = 'C') OR ((SELECT InactiveIndicator FROM @PreviousModuleInstanceTable) = 'Y')
    BEGIN
	  IF @Debug='Y'
	    PRINT 'The last Execution Flag is ''C'' OR the Inactive Indicator at Module level is ''Y''. The process will be skipped / cancelled.';

	  IF @Debug='Y'
	    PRINT 'The Module Instance will be skipped / cancelled';

	  -- Call the Cancel (skip) event.
	  EXEC [omd].[UpdateModuleInstance]
	    @ModuleInstanceId = @ModuleInstanceId,
		@EventCode = N'Cancel',
	    @Debug = @Debug

	  SET @ProcessIndicator = 'Cancel';
	  GOTO EndOfProcedure
   END

  -- Proceed with success 
  -- If the previous run for the module (the previous Module Instance) was completed successfully and the Module is not disabled, the process can report 'proceed' for
  -- any code execution in the body (e.g. the ETL itself).
  IF ((SELECT LastNextExecutionFlag FROM @PreviousModuleInstanceTable) = 'P') AND ((SELECT InactiveIndicator FROM @PreviousModuleInstanceTable) != 'Y')
    BEGIN
	  IF @Debug='Y'
	    PRINT 'The last Execution Flag is ''P'' AND the Inactive Indicator at Module level is not ''Y''. The process can proceed (no rollback is required).';

	  IF @Debug='Y'
		PRINT 'The Module Instance will be set to proceed';

	  EXEC [omd].[UpdateModuleInstance]
	    @ModuleInstanceId = @ModuleInstanceId,
		@EventCode = N'Proceed',
	    @Debug = @Debug

	   SET @ProcessIndicator = 'Proceed';
	   GOTO EndOfProcedure
    END

  -- Proceed with RollBack.
  -- If the previous Module Instance is set to Rollback, this will trigger the current Module instance to do so before proceeding.
  IF ((SELECT LastNextExecutionFlag FROM @PreviousModuleInstanceTable) = 'R') AND ((SELECT InactiveIndicator FROM @PreviousModuleInstanceTable) != 'Y')
    BEGIN
	  IF @Debug='Y'
	    PRINT 'The last Execution Flag is ''R'' AND the Inactive Indicator at Module level is not ''Y''. The process should perform a rollback.';

	  IF @Debug='Y'
		PRINT 'The Module Instance will be set to rollback';

	  EXEC [omd].[UpdateModuleInstance]
	    @ModuleInstanceId = @ModuleInstanceId,
		@EventCode = N'Rollback',
	    @Debug = @Debug

	  SET @ProcessIndicator = 'Rollback';
	  GOTO CallRollback
    END

  /*
    Region: execution of rollback.
  */

  CallRollback:
  
  IF @Debug='Y'
	PRINT CHAR(13)+'-- Start of rollback evaluation process step.';

  BEGIN TRY
      -- Call the rollback procedure for the current Module.
	  -- Technically, this is rolling back of the previous Module Instance.
      -- This has to happen in the same transaction block to prevent process setting to commence before rollback ends.

	BEGIN -- Rollback
	  DECLARE @ModuleInstanceIdList VARCHAR(MAX);
	  SET @ModuleInstanceIdList = (SELECT LastModuleInstanceIDList FROM @PreviousModuleInstanceTable);

	  IF @Debug='Y'
	    PRINT 'Input variables are Module '+CONVERT(VARCHAR(10),@ModuleId)+' with Previous Module Instance Id list '+@ModuleInstanceIdList+'.';

	  DECLARE @SqlStatement VARCHAR(MAX);
	  --DECLARE @AreaCode VARCHAR(10);
	  --SELECT @AreaCode = AREA_CODE FROM omd.MODULE WHERE MODULE_ID=@ModuleId;
	  DECLARE @TableCode VARCHAR(255);
	  SELECT @TableCode = DATA_OBJECT_TARGET FROM omd.MODULE WHERE MODULE_ID=@ModuleId; 

	  IF @Debug='Y'
	  BEGIN
		--PRINT 'The Area Code for Module '+CONVERT(VARCHAR(10),@ModuleId)+' is '+@AreaCode+'.';
		PRINT 'The Table Code (DATA_OBJECT_TARGET) for Module '+CONVERT(VARCHAR(10),@ModuleId)+' is '+@TableCode+'.';
	  END

	  -- Rollback
	  BEGIN
	    BEGIN TRY
		  IF @Debug='Y'
		  PRINT 'Rollback.';

		  DECLARE @LocalAreaCode VARCHAR(255) = (SELECT omd.GetModuleAreaByModuleId(@ModuleId));

		  --IF @LocalAreaCode = 'INT'
		    --SET @SqlStatement = 'DELETE FROM '+@TableCode+' WHERE (omd_module_instance_id IN '+@ModuleInstanceIdList+') OR (omd_update_module_instance_id IN '+@ModuleInstanceIdList+')';
		  --ELSE
		    SET @SqlStatement = 'DELETE FROM '+@TableCode+' WHERE MODULE_INSTANCE_ID IN '+@ModuleInstanceIdList;

		  IF @Debug='Y'
		    PRINT 'Rollback SQL statement is: '+@SqlStatement;

		  EXEC (@SqlStatement);

		  SET @SqlStatement = 'DELETE FROM omd.SOURCE_CONTROL WHERE MODULE_INSTANCE_ID IN '+@ModuleInstanceIdList;

		  IF @Debug='Y'
		    PRINT 'Source Control Rollback SQL statement is: '+@SqlStatement;

		  EXEC (@SqlStatement);

		  -- Not implemented expiry date reset. Insert only!
		  --UPDATE <Table Code> SET EXPIRY_DATETIME = '9999-12-31', CURRENT_RECORD_INDICATOR = 'Y' WHERE MODULE_INSTANCE_ID IN <List>;

	    END TRY
	    BEGIN CATCH
		  -- Module Failure
		  EXEC [omd].[UpdateModuleInstance]
			@ModuleInstanceId = @ModuleInstanceId,
			@Debug = @Debug,
			@EventCode = 'Failure';
	      SET @ProcessIndicator = 'Failure';
		  THROW
	    END CATCH
	  END

	END -- End of Rollback


    -- After rollback is completed, the process is allowed to continue.
    IF @Debug='Y'
      PRINT 'The Module Instance will be set to proceed';

    EXEC [omd].[UpdateModuleInstance]
	   @ModuleInstanceId = @ModuleInstanceId,
	   @EventCode = N'Proceed',
	   @Debug = @Debug

	SET @ProcessIndicator = 'Proceed';
    GOTO EndOfProcedure
  END TRY
  BEGIN CATCH
      -- Module Failure
    EXEC [omd].[UpdateModuleInstance]
         @ModuleInstanceId = @ModuleInstanceId,
      @Debug = @Debug,
      @EventCode = 'Failure';
	SET @ProcessIndicator = 'Failure';

	-- Logging and exception handling
	SET @EventDetail = 'Failure during rollack process in Module Evaluation, with error: '+ERROR_MESSAGE();
    SET @EventReturnCode = ERROR_NUMBER();

	EXEC [omd].[InsertIntoEventLog]
	  @ModuleInstanceId = @ModuleInstanceId,
	  @EventDetail = @EventDetail,
	  @EventReturnCode = @EventReturnCode;

    THROW
  END CATCH
  -- All branches completed

  ModuleFailure:
  -- The procedure should not be able to end in this part, so this is just to be sure there is a failure reported when this happens.
    -- Module Failure
  EXEC [omd].[UpdateModuleInstance]
    @ModuleInstanceId = @ModuleInstanceId,
    @Debug = @Debug,
    @EventCode = 'Failure';
  SET @ProcessIndicator = 'Failure';

  /*
    Region: end of processing, final step.
  */

  EndOfProcedure:
   -- End label

  IF @Debug = 'Y'
  BEGIN
     BEGIN TRY
       PRINT 'Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' was processed';
       PRINT 'The result (processing indicator) is '+@ProcessIndicator;  
       PRINT CHAR(13)+'-- Module Evaluation completed.';
	 END TRY
	 BEGIN CATCH

	    -- Logging and exception handling
	    SET @EventDetail = ERROR_MESSAGE();
        SET @EventReturnCode = ERROR_NUMBER();

	    EXEC [omd].[InsertIntoEventLog]
	      @ModuleInstanceId = @ModuleInstanceId,
		  @EventDetail = @EventDetail,
		  @EventReturnCode = @EventReturnCode;

	   THROW

	 END CATCH
  END
END