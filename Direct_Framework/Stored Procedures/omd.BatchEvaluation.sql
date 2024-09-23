/*******************************************************************************
 * [omd].[BatchEvaluation]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Checks if the provided Batch Instance is able to proceed,
 *   based on the state of all Batch Instances of the related Batch.
 *
 * Inputs:
 *   - Batch Instance Id
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Internal Processing Status Code
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

DECLARE @InternalProcessingStatusCode NVARCHAR(10);

EXEC [omd].[BatchEvaluation]
  -- Mandatory parameters
  @BatchInstanceId = <Id>,
  -- Optional parameters
  @Debug = 'Y',
  -- Output parameters
  @InternalProcessingStatusCode = @InternalProcessingStatusCode OUTPUT,
  @SuccessIndicator = @SuccessIndicator OUTPUT,
  @MessageLog = @MessageLog OUTPUT;

PRINT @InternalProcessingStatusCode;

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[BatchEvaluation]
(
  -- Mandatory parameters
  @BatchInstanceId                BIGINT,
  -- Optional parameters
  @Debug                          CHAR(1)       = 'N',
  -- Output parameters
  @InternalProcessingStatusCode   NVARCHAR(10)  = NULL OUTPUT,
  @SuccessIndicator               CHAR(1)       = 'N' OUTPUT,
  @MessageLog                     NVARCHAR(MAX) = N'' OUTPUT
)
AS
BEGIN TRY
  SET NOCOUNT ON;

  -- Default output logging
  DECLARE @SpName NVARCHAR(100) = N'[' + OBJECT_SCHEMA_NAME(@@PROCID) + '].[' + OBJECT_NAME(@@PROCID) + ']';
  DECLARE @DirectVersion NVARCHAR(10) = [omd_metadata].[GetFrameworkVersion]();
  DECLARE @StartTimestamp DATETIME = SYSUTCDATETIME();
  DECLARE @StartTimestampString NVARCHAR(20) = FORMAT(@StartTimestamp, 'yyyy-MM-dd HH:mm:ss.fffffff');
  DECLARE @EndTimestamp DATETIME = NULL;
  DECLARE @EndTimestampString NVARCHAR(20) = N'';
  DECLARE @LogMessage NVARCHAR(MAX);

  -- Log standard metadata
  SET @LogMessage = @SpName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Procedure', @LogMessage, @MessageLog)
  SET @LogMessage = @DirectVersion;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Version',@LogMessage, @MessageLog)
  SET @LogMessage = @StartTimestampString;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Start Timestamp', @LogMessage, @MessageLog)

  -- Log parameters
  SET @LogMessage = @BatchInstanceId;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchInstanceId', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  -- Local procedure variables
  DECLARE @BatchId INT;
  DECLARE @ActiveInstanceCount INT;

  SET @LogMessage = 'Beginning of Batch Evaluation for Batch Instance Id ' + CONVERT(NVARCHAR(20), @BatchInstanceId)
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  -- Get the Batch Id for this Batch Instance.
  SELECT @BatchId = [omd].[GetBatchIdByBatchInstanceId](@BatchInstanceId);

  -- Exception handling, the Batch Id cannot be NULL
  IF @BatchId IS NULL
  BEGIN
    SET @LogMessage = 'The Batch Id was not found for Batch Instance Id ''' + CONVERT(NVARCHAR(20), @BatchInstanceId) + ''''
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    EXEC [omd].[InsertIntoEventLog] @EventDetail = @EventDetail;

    GOTO FailureEndOfProcedure
  END

  SET @LogMessage = 'For Batch Instance Id ' + CONVERT(NVARCHAR(20), @BatchInstanceId)+  ' the Batch Id ' + CONVERT(NVARCHAR(10), @BatchId) + ' was found in [omd].[BATCH].'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)


  /*
  Region: Check for multiple active Batch Instances
  Multiple active instances indicate corruption in the DIRECT repository.
  */

  SET @LogMessage = 'Beginning of active instance checks.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  -- Check if there are no additional running instances other than the current Batch Instance. The count should be 0.
  SELECT @ActiveInstanceCount = COUNT(*)
  FROM omd.BATCH_INSTANCE
  WHERE
    EXECUTION_STATUS_CODE = 'Executing' AND
    BATCH_ID = @BatchId AND
    BATCH_INSTANCE_ID < @BatchInstanceId

  SET @LogMessage = 'The number of active Batch Instances is '+COALESCE(CONVERT(NVARCHAR(10),@ActiveInstanceCount),'0')+'.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  IF @ActiveInstanceCount = 0
  BEGIN
    -- Continue,  there is no other active instance for this Batch.
    SET @LogMessage = 'Either there are no other active instance for the Batch (except this one), so the evaluation can continue.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

   -- Go to the next step in the process.
    GOTO BatchInactiveEvaluation
  END
  ELSE -- There are already multiple running instances for the same Batch, the process must be aborted.
  BEGIN

    SET @LogMessage = 'There are multiple running instances for the same Batch, the process must be aborted (abort and go to end of procedure).'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Call the Abort event.
    EXEC [omd].[UpdateBatchInstance]
    @BatchInstanceId = @BatchInstanceId,
    @EventCode = N'Abort',
    @Debug = @Debug

    SET @InternalProcessingStatusCode = 'Abort';
    GOTO EndOfProcedure
    -- End
  END

  BatchInactiveEvaluation:
  /*
  Region: Batch active check.
  In case the Batch has the ACTIVE_INDICATOR = 'N' the process can be cancelled / skipped as the Batch is not supposed to run.
  */
  DECLARE @BatchActiveIndicator CHAR(1);

  SET @LogMessage = 'Start of Batch Inactive evalation step.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  SELECT @BatchActiveIndicator = ACTIVE_INDICATOR
  FROM omd.BATCH
  WHERE BATCH_ID= @BatchId

  IF @BatchActiveIndicator = 'Y' -- The Batch is enabled, so the process can continue.
  BEGIN

    SET @LogMessage = 'The Batch is enabled (Active Indicator is set to ' + @BatchActiveIndicator + '), so the process can continue.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    GOTO RollBackEvaluation -- Go to the next process step after this section.

  END
  ELSE -- Batch has something other than 'Y' and should be skipped / cancelled.
  BEGIN

    SET @LogMessage = 'The Batch is disabled (Active Indicator is set to ' + @BatchActiveIndicator + '), so the process must cancel / skip.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Call the Cancel (skip) event.
    EXEC [omd].[UpdateBatchInstance]
      @BatchInstanceId = @BatchInstanceId,
      @EventCode = N'Cancel',
      @Debug = @Debug

    SET @InternalProcessingStatusCode = 'Cancel';

    GOTO EndOfProcedure
  END

  /*
  Region: rollback.
  Any erroneous previous instances must be rolled-back before processing can continue.
  */
  RollBackEvaluation:

  SET @LogMessage = 'Start of the rollback evaluation process step.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  DECLARE @LastExecutionStatusCode NVARCHAR(10);
  DECLARE @LastNextRunStatusCode NVARCHAR(10);

  -- Get the Next Run Status Code and Execution Status Code from the previous Batch Instance.
  DECLARE @PreviousBatchInstanceTable TABLE
  (
    LastExecutionStatusCode NVARCHAR(10),
    LastNextRunStatusCode NVARCHAR(10)
  );

  INSERT @PreviousBatchInstanceTable
  SELECT * FROM [omd].[GetPreviousBatchInstanceDetails](@BatchId)

  SELECT @LastExecutionStatusCode = LastExecutionStatusCode FROM @PreviousBatchInstanceTable;

  SET @LogMessage = 'The previous Batch Instance Execution Status Code is ' + @LastExecutionStatusCode
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  SELECT @LastNextRunStatusCode = LastNextRunStatusCode FROM @PreviousBatchInstanceTable;

  SET @LogMessage = 'The previous Batch Instance Next Run Status Code is ' + @LastNextRunStatusCode
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  -- Proceed
  -- The execution can proceed if the previous run for the Batch (the previous Batch Instance) was without failure, was not set to rerun and was not cancelled.
  IF
  (
    (@LastExecutionStatusCode <> 'Failed') AND
    (@LastNextRunStatusCode NOT IN ('Cancel','Rollback'))
  )
  BEGIN

    SET @LogMessage = 'The last Execution Code is ' + @LastExecutionStatusCode + ' and last Next Run Status Code is ' + @LastNextRunStatusCode + '. The process can proceed (no rollback is required). The Batch Instance will be set to proceed.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    EXEC [omd].[UpdateBatchInstance]
      @BatchInstanceId = @BatchInstanceId,
      @EventCode = N'Proceed',
      @Debug = @Debug

     SET @InternalProcessingStatusCode = 'Proceed';

     GOTO EndOfProcedure
  END

  -- Proceed with RollBack.
  -- If the previous Batch Instance has failed and the previous next run indicator is not set to skip OR the previous next run indicator is set to rerun the rollback step must be initiatied.
  IF
  (
    (@LastExecutionStatusCode = 'Failed' AND @LastNextRunStatusCode <> 'Cancelled') OR
    @LastNextRunStatusCode = 'Rollback'
  )
  BEGIN

    SET @LogMessage = 'The last Execution Flag is ' + @LastExecutionStatusCode + ' and last Next Run Indicator is ' + @LastNextRunStatusCode + '. The process must initiate a rollback. The Batch Instance will be set to rollback.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

   -- NOTE the below status update on the Batch Instance will always trigger a full rollback, whereas partial rollback is the default.

   -- EXEC [omd].[UpdateBatchInstance]
   --   @BatchInstanceId = @BatchInstanceId,
    --@EventCode = N'Rollback',
   --   @Debug = @Debug

    SET @InternalProcessingStatusCode = 'Rollback';
    GOTO CallRollback
  END

  /*
  Region: execution of rollback.
  Call the rollback procedure for the current Batch.
  Technically, this is disabling any Modules that were part of earlier failed Batches, as the rollback itself happens at Module level.
  */

  CallRollback:

  SET @LogMessage = 'Start of rollback evaluation process step.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  DECLARE @SqlStatement VARCHAR(MAX);

  DECLARE @FailedBatchIdArray VARCHAR(MAX) = omd.[GetFailedBatchIdList](@BatchId);

  SET @LogMessage = 'The array of earlier failed Batch Instances is ' + @FailedBatchIdArray + '.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  IF @LastNextRunStatusCode = 'Rollback' -- Full rollback for all Modules in the Batch.
  BEGIN
    BEGIN TRY

    SET @SqlStatement = 'UPDATE omd.MODULE_INSTANCE SET NEXT_RUN_STATUS_CODE = ''Rollback'' WHERE BATCH_INSTANCE_ID IN '+@FailedBatchIdArray;

    SET @LogMessage = 'Rollback SQL statement (full) is: ' + @SqlStatement
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    EXEC (@SqlStatement);

    -- After rollback is completed, the process is allowed to continue.
    SET @LogMessage = 'The Module Instance will be set to proceed';
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    EXEC [omd].[UpdateBatchInstance]
      @BatchInstanceId = @BatchInstanceId,
      @EventCode = N'Proceed',
      @Debug = @Debug

    SET @InternalProcessingStatusCode = 'Proceed';

    GOTO EndOfProcedure

   END TRY
   BEGIN CATCH

    -- Batch Failure
     EXEC [omd].[UpdateBatchInstance]
      @BatchInstanceId = @BatchInstanceId,
      @Debug = @Debug,
      @EventCode = 'Failure';
    SET @InternalProcessingStatusCode = 'Failure';

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

  IF @LastNextRunStatusCode = 'Proceed' -- Partial rollback - skip previously succesfull Modules in the Batch.
  BEGIN
    BEGIN TRY

    SET @SqlStatement = 'UPDATE omd.MODULE_INSTANCE SET NEXT_RUN_STATUS_CODE = ''Cancel'' WHERE EXECUTION_STATUS_CODE <> ''Failed'' AND BATCH_INSTANCE_ID IN '+@FailedBatchIdArray;

    SET @LogMessage = 'Rollback SQL statement (partial) is: ' + @SqlStatement;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    EXEC (@SqlStatement);

    -- After rollback is completed, the process is allowed to continue.
    SET @LogMessage = 'The Batch Instance will be set to proceed'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)


    EXEC [omd].[UpdateBatchInstance]
      @BatchInstanceId = @BatchInstanceId,
      @EventCode = N'Proceed',
      @Debug = @Debug

    SET @InternalProcessingStatusCode = 'Proceed';

    SET @SuccessIndicator = 'Y'

    GOTO EndOfProcedure

  END TRY
  BEGIN CATCH
    -- Batch Failure
    SET @SuccessIndicator = 'N'
    EXEC [omd].[UpdateBatchInstance]
       @BatchInstanceId = @BatchInstanceId,
       @Debug = @Debug,
       @EventCode = 'Failure';

    SET @InternalProcessingStatusCode = 'Failure';

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

  SET @InternalProcessingStatusCode = 'Failure';

  RAISERROR('Incorrect Batch Evaluation path encountered (post-rollback).',1,1)

  FailureEndOfProcedure:

    SET @SuccessIndicator = 'N'
    SET @LogMessage = N'' + @SpName + ' ended in failure.';
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

  GOTO EndOfProcedure

  /*
  Region: end of processing, final step.
  */

  SET @LogMessage = 'Batch Instance Id ' + CONVERT(NVARCHAR(10) , @BatchInstanceId) + ' was processed';
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Result', @LogMessage, @MessageLog)
  SET @LogMessage = 'The result (processing status code) is ' + @InternalProcessingStatusCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Result', @LogMessage, @MessageLog)

  -- End of procedure label
  EndOfProcedure:

  SET @EndTimestamp = SYSUTCDATETIME();
  SET @EndTimestampString = FORMAT(@EndTimestamp, 'yyyy-MM-dd HH:mm:ss.fffffff');
  SET @LogMessage = @EndTimestampString;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'End Timestamp', @LogMessage, @MessageLog)
  SET @LogMessage = DATEDIFF(SECOND, @StartTimestamp, @EndTimestamp);
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Elapsed Time (s)', @LogMessage, @MessageLog)
  SET @LogMessage = @SuccessIndicator;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @SuccessIndicator', @LogMessage, @MessageLog)

  IF @Debug = 'Y'
  BEGIN
    EXEC [omd].[PrintMessageLog] @MessageLog;
  END

END TRY
BEGIN CATCH
  -- SP-wide error handler and logging
  SET @SuccessIndicator = 'N'
  SET @LogMessage = @SuccessIndicator;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @SuccessIndicator', @LogMessage, @MessageLog)

  DECLARE @ErrorMessage NVARCHAR(4000);
  DECLARE @ErrorSeverity INT;
  DECLARE @ErrorState INT;
  DECLARE @ErrorProcedure NVARCHAR(128);
  DECLARE @ErrorNumber INT;
  DECLARE @ErrorLine INT;

  SELECT
    @ErrorMessage   = COALESCE(ERROR_MESSAGE(),     'No Message'    ),
    @ErrorSeverity  = COALESCE(ERROR_SEVERITY(),    -1              ),
    @ErrorState     = COALESCE(ERROR_STATE(),       -1              ),
    @ErrorProcedure = COALESCE(ERROR_PROCEDURE(),   'No Procedure'  ),
    @ErrorLine      = COALESCE(ERROR_LINE(),        -1              ),
    @ErrorNumber    = COALESCE(ERROR_NUMBER(),      -1              );

  IF @Debug = 'Y'
  BEGIN
    PRINT 'Error in '''       + @SpName + ''''
    PRINT 'Error Message: '   + @ErrorMessage
    PRINT 'Error Severity: '  + CONVERT(NVARCHAR(10), @ErrorSeverity)
    PRINT 'Error State: '     + CONVERT(NVARCHAR(10), @ErrorState)
    PRINT 'Error Procedure: ' + @ErrorProcedure
    PRINT 'Error Line: '      + CONVERT(NVARCHAR(10), @ErrorLine)
    PRINT 'Error Number: '    + CONVERT(NVARCHAR(10), @ErrorNumber)
    PRINT 'SuccessIndicator: '+ @SuccessIndicator

    -- Spool message log
    EXEC [omd].[PrintMessageLog] @MessageLog;

  END

  SET @EventDetail = 'Error in ''' + COALESCE(@SpName,'N/A') + ''' from ''' + COALESCE(@ErrorProcedure,'N/A') + ''' at line ''' + CONVERT(NVARCHAR(10), COALESCE(@ErrorLine,'N/A')) + ''': '+ CHAR(10) + COALESCE(@ErrorMessage,'N/A');
  SET @EventReturnCode = ERROR_NUMBER();

  EXEC [omd].[InsertIntoEventLog]
    @EventDetail       = @EventDetail,
    @EventReturnCode   = @EventReturnCode,
    @BatchInstanceId   = @BatchInstanceId;

  THROW
END CATCH
