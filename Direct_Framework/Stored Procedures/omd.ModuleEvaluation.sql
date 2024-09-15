/*******************************************************************************
 * [omd].[ModuleEvaluation]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Checks if the Module Instance is able to proceed based on the state of all Module Instances for the particular Module.
 *
 * Inputs:
 *   - Module Instance Id, the Module Instance Id to evaluate
 *   - Module Instance Id Column Name (defaults to MODULE_INSTANCE_ID)
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

DECLARE @InternalProcessingStatusCode VARCHAR(10);

EXEC [omd].[ModuleEvaluation]
  @ModuleInstanceId = <Id>,
  @InternalProcessingStatusCode = @InternalProcessingStatusCode OUTPUT;

PRINT @InternalProcessingStatusCode;

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[ModuleEvaluation]
(
  -- Mandatory parameters
  @ModuleInstanceId             BIGINT,
  -- Optional parameters
  @ModuleInstanceIdColumnName   VARCHAR(1000) = 'MODULE_INSTANCE_ID',
  @Debug                        CHAR(1)       = 'N',
  -- Output parameters
  @InternalProcessingStatusCode NVARCHAR(10)  = NULL OUTPUT,
  @SuccessIndicator             CHAR(1)       = 'N' OUTPUT,
  @MessageLog                   NVARCHAR(MAX) = N'' OUTPUT
)
AS
BEGIN TRY
  SET NOCOUNT ON;
  SET ANSI_WARNINGS OFF; -- Suppress NULL elimination warning within SET operation.

  -- Default output logging setup
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
  SET @LogMessage = @ModuleInstanceId;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleInstanceId', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleInstanceIdColumnName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleInstanceIdColumnName', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail NVARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  DECLARE @ModuleId INT;
  DECLARE @BatchId INT;
  DECLARE @MinimumActiveModuleInstance BIGINT;
  DECLARE @ActiveModuleInstanceCount INT;
  DECLARE @BatchModuleActiveIndicator CHAR(1);

  SET @LogMessage = 'Start of the Module Evaluation process. (' + @SpName + ') - ModuleInstanceId: ' + CONVERT(NVARCHAR(20), @ModuleInstanceId)
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  SELECT @ModuleId = omd.GetModuleIdByModuleInstanceId(@ModuleInstanceId);

  -- Exception handling
  -- The Module Id cannot be NULL
  IF @ModuleId IS NULL
  BEGIN
    SET @EventDetail = 'The Module Id was not found for Module Instance Id ''' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + '''';
    EXEC [omd].[InsertIntoEventLog]
      @EventDetail = @EventDetail;

    GOTO  ModuleFailure
  END

  SET @LogMessage = 'For Module Instance Id ' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + ' the Module Id ' + CONVERT(NVARCHAR(10), @ModuleId) + ' was found in [omd].[MODULE].'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  /*
    Region: Check for multiple active Module Instances
    Multiple active instances indicate corruption in the DIRECT repository.
  */

  SET @LogMessage = 'Beginning of active instance checks.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)


  -- Check for the lowest instance of the Module Instances since the process must continue if it's the first of the started instances for the particular Module.
  SELECT @MinimumActiveModuleInstance = MIN(MODULE_INSTANCE_ID)
  FROM omd.MODULE_INSTANCE
  WHERE EXECUTION_STATUS_CODE = 'Executing'
    AND MODULE_ID = @ModuleId
  GROUP BY MODULE_ID

  -- Check if there are no additional running instances other than the current Module Instance. The count should be 1.
  SELECT @ActiveModuleInstanceCount = COUNT(*)
  FROM omd.MODULE_INSTANCE
  WHERE EXECUTION_STATUS_CODE = 'Executing'
     AND MODULE_ID = @ModuleId
     AND MODULE_INSTANCE_ID <> @ModuleInstanceId
  GROUP BY MODULE_ID

  SET @LogMessage = 'The number of active Module Instances is '+ COALESCE(CONVERT(NVARCHAR(10), @ActiveModuleInstanceCount), '0') + '.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  SET @LogMessage = 'The minimum active Module Instance Id is '+ COALESCE(CONVERT(NVARCHAR(10), @MinimumActiveModuleInstance), '0') + '.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  IF ((@ActiveModuleInstanceCount IS NULL) OR (@ActiveModuleInstanceCount IS NOT NULL AND @MinimumActiveModuleInstance = @ModuleInstanceId))
  BEGIN
    -- Continue, either there is only 1 active instance for the Module (this one) OR this instance is the first of many running instances and this one should be allowed to continue.
    SET @LogMessage = 'Either there is only 1 active instance for the Module (this one) OR this instance is the first (MIN) of many running instances and should be allowed to continue.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Go to the next step in the process.
    GOTO BatchModuleEvaluation
  END
  ELSE -- There are already multiple running instances for the same Module, the process must be aborted.
  BEGIN

    SET @LogMessage = 'There are already multiple running instances for the same Module, the process must be aborted. (abort and go to end of procedure).'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Call the Abort event.
    EXEC [omd].[UpdateModuleInstance]
      @ModuleInstanceId = @ModuleInstanceId,
      @EventCode = N'Abort',
      @Debug = @Debug

    SET @InternalProcessingStatusCode = 'Abort';
    SET @SuccessIndicator = 'Y'

    GOTO EndOfProcedure
    -- End
  END

  BatchModuleEvaluation:
  /*
    Region: Batch/Module relationship validation.
    In case the Module is called from a parent Batch this task verifies if the administration is done properly
    and if the Module is disabled as part of the Batch configuration (BATCH_MODULE).

    If the current instance is started from a Batch (Batch Instance <> 0) then the Batch / Module flag must be set to ACTIVE_INDICATOR = 'Y'
    If the current instance has a Batch Instance Id (or Batch Id) of 0 then this step can be skipped, as the Module was not started by a Batch.
  */

  SELECT @BatchId = omd.GetBatchIdByModuleInstanceId(@ModuleInstanceId);

  -- Exception handling, The Batch Id cannot be NULL
  IF @BatchId IS NULL
  BEGIN
    SET @EventDetail = 'The Batch Id was not found for Module Instance Id ''' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + '''';
    EXEC [omd].[InsertIntoEventLog]
      @EventDetail = @EventDetail;

    GOTO ModuleFailure
  END

  SET @LogMessage = 'Start of Batch / Module relationship evalation step.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  IF @BatchId = 0 -- The Module was run stand-alone (not from a Batch).
    BEGIN
      -- The Module Instance was not started from a Batch, so processing can skip this step and continue.
      SET @LogMessage = 'The Module Instance was not started from a Batch (0), so processing can skip this step and continue to Rollback Evaluation.'
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

      GOTO RollBackEvaluation -- Go to the next process step after this section.
    END
  ELSE -- Batch Id has a value, so the Module was run from a Batch and we need to check if the Module is active for the Batch.
    BEGIN

      SET @LogMessage = 'The Module Instance was started from a Batch (Id: ' + CONVERT(NVARCHAR(10), @BatchId) + '), so processing will evaluate if the Batch/Module registration is correct.'
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

      -- The Module Instance was started by a Batch, so we must check if the Module is allowed to run.
      SELECT @BatchModuleActiveIndicator = [omd].[GetBatchModuleActiveIndicatorValue](@BatchId, @ModuleId)

      SET @LogMessage = 'The Batch / Module inactive flag value is ' + @BatchModuleActiveIndicator
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

      IF (@BatchModuleActiveIndicator = 'N') -- Skip
      BEGIN
        SET @LogMessage = 'The Module Instance will be skipped / cancelled'
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

        -- If the inactive indicator at Batch/Module level is set to 'Y' the process is disabled in the framework.
        -- In this case, the Module must be skipped / cancelled (was attempted to be run, but not allowed).

        -- Call the Cancel (skip) event.
        EXEC [omd].[UpdateModuleInstance]
          @ModuleInstanceId = @ModuleInstanceId,
          @EventCode = N'Cancel',
          @Debug = @Debug

        SET @InternalProcessingStatusCode = 'Cancel';
        SET @SuccessIndicator = 'Y'

        GOTO EndOfProcedure
    END

    IF (@BatchModuleActiveIndicator = 'U') -- Abort
    BEGIN
      SET @LogMessage = 'The Module Instance will be aborted.'
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

      -- If the inactive indicator at Batch/Module level is NULL then there is an error in the framework registration / setup.
      -- In this case, the Module must be aborted. The module was attempted to be run form a Batch it is not registered for).

      -- Call the Abort event.
      EXEC [omd].[UpdateModuleInstance]
        @ModuleInstanceId = @ModuleInstanceId,
        @EventCode = N'Abort',
        @Debug = @Debug

      SET @InternalProcessingStatusCode = 'Abort';
      SET @SuccessIndicator = 'Y'

      GOTO EndOfProcedure
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
  END

  RollBackEvaluation:
  /*
    Region: Rollback.
    Any erroneous previous instances must be rolled-back before processing can continue.
  */

  SET @LogMessage = 'Start of rollback evaluation process step.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  DECLARE @PreviousModuleInstanceTable TABLE
  (
    LastBatchInstanceID       BIGINT,
    LastModuleInstanceID      BIGINT,
    LastStartTimestamp        DATETIME2,
    LastEndTimestamp          DATETIME2,
    LastExecutionStatus       NVARCHAR(100),
    LastNextExecutionFlag     NVARCHAR(100),
    LastModuleInstanceIDList  VARCHAR(MAX),
    ActiveIndicator           CHAR(1)
  );

  INSERT @PreviousModuleInstanceTable
  SELECT * FROM [omd].[GetPreviousModuleInstanceDetails](@ModuleId, @BatchId)

  /* Internal debug only
  SELECT * FROM @PreviousModuleInstanceTable;
  */

  -- If the previously completed Module Instance (for the same Module) is set to cancel OR the module is set to inactive the run must be cancelled.
  IF ((SELECT LastNextExecutionFlag FROM @PreviousModuleInstanceTable) = 'Cancel') OR((SELECT ActiveIndicator FROM @PreviousModuleInstanceTable) = 'N')
  BEGIN
    SET @LogMessage = 'The last Execution Flag is ''Cancel'' OR the Active Indicator at Module level is ''N''. The process will be cancelled. The Module Instance will be cancelled'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Call the Cancel (skip) event.
    EXEC [omd].[UpdateModuleInstance]
      @ModuleInstanceId = @ModuleInstanceId,
      @EventCode = N'Cancel',
      @Debug = @Debug

    SET @InternalProcessingStatusCode = N'Cancel';
    SET @SuccessIndicator = 'Y'

    GOTO EndOfProcedure
   END

  -- Proceed with success
  -- If the previous run for the module (the previous Module Instance) was completed successfully and the Module is not disabled, the process can report 'proceed' for
  -- any code execution in the body (e.g. the data logistics process itself).
  IF ((SELECT LastNextExecutionFlag FROM @PreviousModuleInstanceTable) = 'Proceed') AND ((SELECT ActiveIndicator FROM @PreviousModuleInstanceTable) <> 'N')
  BEGIN
    SET @LogMessage = 'The last Execution Flag is ''Proceed'' AND the Active Indicator at Module level is not ''N''. The process can proceed (no rollback is required). The Module Instance will be set to proceed'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    EXEC [omd].[UpdateModuleInstance]
      @ModuleInstanceId = @ModuleInstanceId,
      @EventCode = N'Proceed',
      @Debug = @Debug

    SET @InternalProcessingStatusCode = N'Proceed';
    SET @SuccessIndicator = 'Y'

    GOTO EndOfProcedure
  END

  -- Proceed with Rollback.
  -- If the previous Module Instance is set to Rollback, this will trigger the current Module instance to do so before proceeding.
  IF ((SELECT LastNextExecutionFlag FROM @PreviousModuleInstanceTable) = 'Rollback') AND ((SELECT ActiveIndicator FROM @PreviousModuleInstanceTable) <> 'N')
  BEGIN
    SET @LogMessage = 'The last Execution Code is ''Rollback'' and the Active Indicator at Module level is not ''N''. The process should perform a rollback. The Module Instance will be set to rollback'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    EXEC [omd].[UpdateModuleInstance]
      @ModuleInstanceId = @ModuleInstanceId,
      @EventCode = N'Rollback',
      @Debug = @Debug

    SET @InternalProcessingStatusCode = 'Rollback';
    GOTO CallRollback
  END

  /*
    Region: execution of rollback.
  */

  CallRollback:

  SET @LogMessage = 'Start of rollback evaluation process step.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  BEGIN TRY
    -- Call the rollback procedure for the current Module.
    -- Technically, this is rolling back of the previous Module Instance.
    -- This has to happen in the same transaction block to prevent process setting to commence before rollback ends.

  BEGIN -- Rollback
    DECLARE @ModuleInstanceIdList VARCHAR(MAX);
    SET @ModuleInstanceIdList = (SELECT LastModuleInstanceIDList FROM @PreviousModuleInstanceTable);

    SET @LogMessage = 'Input variables are Module ' + CONVERT(VARCHAR(10), @ModuleId) + ' with Previous Module Instance Id list ' + @ModuleInstanceIdList + '.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    DECLARE @SqlStatement VARCHAR(MAX);
    --DECLARE @AreaCode VARCHAR(10);
    --SELECT @AreaCode = AREA_CODE FROM omd.MODULE WHERE MODULE_ID=@ModuleId;
    DECLARE @TableCode VARCHAR(255);
    SELECT @TableCode = DATA_OBJECT_TARGET FROM [omd].[MODULE] WHERE MODULE_ID=@ModuleId;

    SET @LogMessage = 'The Table Code (DATA_OBJECT_TARGET) for Module ' + CONVERT(VARCHAR(10), @ModuleId) + ' is ' + @TableCode + '.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Rollback
    BEGIN
      BEGIN TRY

      SET @LogMessage = 'Rollback.'
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

      DECLARE @LocalAreaCode NVARCHAR(100) = (SELECT omd.GetModuleAreaByModuleId(@ModuleId));

      IF @TableCode <> 'N/A'
      BEGIN
      --IF @LocalAreaCode = 'INT'
        --SET @SqlStatement = 'DELETE FROM '+@TableCode+' WHERE (omd_module_instance_id IN '+@ModuleInstanceIdList+') OR (omd_update_module_instance_id IN '+@ModuleInstanceIdList+')';
      --ELSE
        SET @SqlStatement = 'DELETE FROM ' + @TableCode + ' WHERE ' + @ModuleInstanceIdColumnName + ' IN ' + @ModuleInstanceIdList;

        SET @LogMessage = 'Rollback SQL statement is: ' + @SqlStatement
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

        EXEC (@SqlStatement);

        SET @SqlStatement = 'DELETE FROM omd.SOURCE_CONTROL WHERE MODULE_INSTANCE_ID IN ' + @ModuleInstanceIdList;

        SET @LogMessage = 'Source Control Rollback SQL statement is: ' + @SqlStatement
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

        EXEC (@SqlStatement);
      END
      ELSE
      BEGIN
        SET @LogMessage = 'No rollback is required for '+@TableCode
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
      END

      END TRY
      BEGIN CATCH
        -- Module Failure
        EXEC [omd].[UpdateModuleInstance]
        @ModuleInstanceId = @ModuleInstanceId,
        @Debug = @Debug,
        @EventCode = 'Failure';

        SET @InternalProcessingStatusCode = 'Failure';

        THROW
      END CATCH
    END

  END -- End of Rollback


    -- After rollback is completed, the process is allowed to continue.
    IF @Debug = 'Y'
      PRINT 'The Module Instance will be set to proceed';

    EXEC [omd].[UpdateModuleInstance]
     @ModuleInstanceId  = @ModuleInstanceId,
     @EventCode         = N'Proceed',
     @Debug             = @Debug

    SET @InternalProcessingStatusCode = 'Proceed';

    GOTO EndOfProcedure

  END TRY
  BEGIN CATCH
      -- Module Failure
    SET @SuccessIndicator = 'N'
    EXEC [omd].[UpdateModuleInstance]
      @ModuleInstanceId   = @ModuleInstanceId,
      @Debug              = @Debug,
      @EventCode          = 'Failure';

  SET @InternalProcessingStatusCode = 'Failure';

  -- Logging and exception handling
  SET @EventDetail = 'Failure during rollback process in Module Evaluation, with error: ' + ERROR_MESSAGE();
  SET @EventReturnCode = ERROR_NUMBER();

  EXEC [omd].[InsertIntoEventLog]
    @ModuleInstanceId   = @ModuleInstanceId,
    @EventDetail        = @EventDetail,
    @EventReturnCode    = @EventReturnCode;

    THROW
  END CATCH
  -- All branches completed

  ModuleFailure:
  -- The procedure should not be able to end in this part, so this is just to be sure there is a failure reported when this happens.
  EXEC [omd].[UpdateModuleInstance]
    @ModuleInstanceId   = @ModuleInstanceId,
    @Debug              = @Debug,
    @EventCode          = 'Failure';

  SET @InternalProcessingStatusCode = 'Failure';

  /*
    Region: end of processing, final step.
  */

  SET @LogMessage = 'Module Instance Id ''' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + ''' was processed'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
  SET @LogMessage = 'The result (processing status code) is ''' + @InternalProcessingStatusCode + ''''
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

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
    @ModuleInstanceId  = @ModuleInstanceId;

  THROW
END CATCH
