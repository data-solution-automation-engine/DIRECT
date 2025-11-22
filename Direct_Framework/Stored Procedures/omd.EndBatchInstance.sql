/**
 * @procedure [omd].[EndBatchInstance]
 * @description End the status of a Batch Instance based on an input event code.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {BIGINT}        @BatchInstanceId  [in]  (required)
 *   The Batch Instance identifier to update.
 * @param {NVARCHAR(100)} @EventCode        [in]  (optional)
 *   One of: 'Proceed', 'Cancel', 'Abort', 'Rollback', 'Success', 'Failure'.
 * @param {CHAR(1)}       @Debug            [in]  (optional, default='N')
 *   Enables debug logging.
 * @param {CHAR(1)}       @SuccessIndicator [out] (optional)
 *   'Y' if the operation completed successfully; otherwise 'N'.
 * @param {NVARCHAR(MAX)} @MessageLog       [out] (optional)
 *   Structured JSON-format log for diagnostics.
 *
 * @returns {INT} Return code: 0 = success, -1 = failure, -2 = unhandled error.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     function [omd_metadata].[GetFrameworkVersion]
 * - writes:
 *     table [omd].[BATCH_INSTANCE]
 *     procedure [omd].[InsertIntoEventLog]
 * - utilities:
 *     function [omd].[AddLogMessage]
 *     procedure [omd].[PrintMessageLog]
 *
 * @example
 * DECLARE @SuccessIndicator CHAR(1), @MessageLog NVARCHAR(MAX);
 * EXEC [omd].[UpdateBatchInstance]
 *   @BatchInstanceId = 42,
 *   @EventCode = 'Success',
 *   @Debug = 'Y',
 *   @SuccessIndicator = @SuccessIndicator OUTPUT,
 *   @MessageLog = @MessageLog OUTPUT;
 * EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;
 */

CREATE PROCEDURE [omd].[EndBatchInstance]
(
   -- Required parameters
   @BatchInstanceId        BIGINT         = NULL
   -- Optional parameters
  ,@EventCode              NVARCHAR(100)  = NULL
  ,@Debug                  CHAR(1)        = 'N'
  -- Output parameters
  ,@SuccessIndicator       CHAR(1)        = 'N' OUTPUT
  ,@MessageLog             NVARCHAR(MAX)  = N'' OUTPUT
)
AS
BEGIN
  BEGIN TRY
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    /* standard setup and initialization */
    SET @Debug = CASE WHEN TRIM(UPPER(@Debug)) = 'Y' THEN 'Y' ELSE 'N' END;
    SET @SuccessIndicator = 'N';
    SET @MessageLog = N'[]';
    DECLARE @LogMessage NVARCHAR(2048);

    /* Event and return codes */
    DECLARE @ReturnCode INT = 0;
    DECLARE @EventTypeCode NVARCHAR(100) = N'2';
    DECLARE @EventDetail NVARCHAR(4000) = N'';
    DECLARE @EventReturnCode NVARCHAR(100) = N'';

    /* Load framework settings */
    DECLARE @AddLogsToEventLog CHAR(1)      = [omd_metadata].[GetSettingFlag]('LOG_TO_EVENT_LOG');
    DECLARE @PrintMessages CHAR(1)          = [omd_metadata].[GetSettingFlag]('SP_PRINT_MESSAGES');
    DECLARE @ProcessMessageLog CHAR(1)      = [omd_metadata].[GetSettingFlag]('SP_PROCESS_MESSAGE_LOG');
    DECLARE @ThrowOnFailure CHAR(1)         = [omd_metadata].[GetSettingFlag]('THROW_ON_FAILURE');
    DECLARE @DefaultTimeZone NVARCHAR(4000) = [omd_metadata].[GetSetting]('DEFAULT_TIMEZONE');
    DECLARE @FailBatchOnModuleFailure CHAR(1) = [omd_metadata].[GetSettingFlag]('FAIL_BATCH_ON_MODULE_FAILURE');
    DECLARE @EndModuleOnBatchEnd CHAR(1) = [omd_metadata].[GetSettingFlag]('END_MODULE_ON_BATCH_END');

/* ----- Validate input parameters ------------------------------------------ */

    IF @BatchInstanceId IS NULL OR @BatchInstanceId <= 0
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @LogMessage = N'Parameter @BatchInstanceId is required.'
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
         [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END;

    IF @EventCode IS NULL OR TRIM(@EventCode) = ''
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @LogMessage = N'Parameter @EventCode is required.'
      IF @ProcessMessageLog = 'Y'
        SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END;

    IF @EventCode NOT IN ('Proceed', 'Cancel', 'Abort', 'Rollback', 'Success', 'Failure')
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @LogMessage = N'Parameter @EventCode has an invalid Event Code specified. The available options are Proceed, Cancel, Abort, Success, Failure, and Rollback'
      IF @ProcessMessageLog = 'Y'
        SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END;

    -- check that the Batch Instance exists
    IF NOT EXISTS (
      SELECT 1
      FROM [omd].[BATCH_INSTANCE]
      WHERE BATCH_INSTANCE_ID = @BatchInstanceId
    )
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @LogMessage = N'Batch Instance not found.';
      IF @ProcessMessageLog = 'Y'
        SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Batch Instance', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END;

/* ----- Default logging setup ---------------------------------------------- */

    DECLARE @StartTimestamp DATETIME2 = SYSUTCDATETIME();
    DECLARE @StartTimestampString NVARCHAR(4000) = [omd_metadata].[GetTimestampString](@StartTimestamp);
    DECLARE @SpName NVARCHAR(300) = CONCAT(
      QUOTENAME(COALESCE(OBJECT_SCHEMA_NAME(@@PROCID),'Unknown')), N'.',
      QUOTENAME(COALESCE(OBJECT_NAME(@@PROCID), 'Unknown')));

    IF @ProcessMessageLog = 'Y'
    BEGIN
      /* Log standard metadata */
      SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Procedure',
        @SpName, @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Version',
        [omd_metadata].[GetFrameworkVersion](), @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Start Timestamp',
        @StartTimestampString, @MessageLog);
      /* Log parameters */
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @BatchInstanceId',
        @BatchInstanceId, @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @EventCode',
        @EventCode, @MessageLog);
    END

/* ----- Start of main process ---------------------------------------------- */
    BEGIN TRY
      BEGIN TRANSACTION;

      /* If spawned modules should be ended by batch end, then do so.
         If the module should be failed, then fail it */
      IF @EndModuleOnBatchEnd = 'Y'
      BEGIN
        UPDATE mi
        SET mi.EXECUTION_STATUS_CODE =
            CASE
              WHEN @FailBatchOnModuleFailure = 'Y' THEN N'Failed'
              ELSE N'Cancelled'
            END,
            mi.INTERNAL_PROCESSING_CODE =
            CASE
              WHEN @FailBatchOnModuleFailure = 'Y' THEN N'Abort'
              ELSE N'Cancel'
            END,
            mi.NEXT_RUN_STATUS_CODE = N'Proceed',
            mi.END_TIMESTAMP = @StartTimestamp
        FROM [omd].[MODULE_INSTANCE] mi
        WHERE mi.BATCH_INSTANCE_ID = @BatchInstanceId
          AND (mi.EXECUTION_STATUS_CODE = N'Executing' OR
              mi.END_TIMESTAMP IS NULL);
      END

      /* If fail batch on module failure is set, derive end status from modules */
      IF @FailBatchOnModuleFailure = 'Y'
      BEGIN
        IF EXISTS (
          SELECT 1
          FROM [omd].[MODULE_INSTANCE] mi
          WHERE mi.BATCH_INSTANCE_ID = @BatchInstanceId
            AND mi.EXECUTION_STATUS_CODE = N'Failed'
        ) SET @EventCode = N'Failure';
      END

      -- Abort event
      -- This is an end-state event (no further processing)
      IF @EventCode = N'Abort'
      BEGIN
        SET @LogMessage = CONCAT(N'Setting the Batch Instance ', @BatchInstanceId,
            N' to ', @EventCode + N'.');
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update',
            @LogMessage, @MessageLog);

        UPDATE [omd].[BATCH_INSTANCE]
          SET
            EXECUTION_STATUS_CODE     = N'Aborted',
            INTERNAL_PROCESSING_CODE  = N'Abort',
            NEXT_RUN_STATUS_CODE      = N'Proceed',
            END_TIMESTAMP             = @StartTimestamp
          WHERE BATCH_INSTANCE_ID = @BatchInstanceId;
      END

      -- Skip / Cancel event
      -- This is an end-state event (no further processing)
      ELSE IF @EventCode = N'Cancel'
      BEGIN
        SET @LogMessage = CONCAT(N'Setting the Batch Instance ', @BatchInstanceId,
            N' to ', @EventCode, N'.');
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update',
            @LogMessage, @MessageLog);

        UPDATE [omd].[BATCH_INSTANCE]
          SET
            EXECUTION_STATUS_CODE     = N'Cancelled',
            INTERNAL_PROCESSING_CODE  = N'Cancel',
            NEXT_RUN_STATUS_CODE      = N'Proceed',
            END_TIMESTAMP             = @StartTimestamp
          WHERE BATCH_INSTANCE_ID = @BatchInstanceId;
      END

      -- Success event
      -- This is an end-state event (no further processing)
      ELSE IF @EventCode = N'Success'
      BEGIN
        SET @LogMessage = CONCAT(N'Setting the Batch Instance ', @BatchInstanceId,
            N' to ', @EventCode, N'.');
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update',
            @LogMessage, @MessageLog);

        UPDATE [omd].[BATCH_INSTANCE]
          SET
            EXECUTION_STATUS_CODE     = N'Succeeded',
            NEXT_RUN_STATUS_CODE      = N'Proceed',
            INTERNAL_PROCESSING_CODE  = N'Proceed',
            END_TIMESTAMP             = @StartTimestamp
          WHERE BATCH_INSTANCE_ID     = @BatchInstanceId;

        GOTO EndOfProcedureSuccess;
      END

      -- Failure event
      -- This is an end-state event (no further processing)
      ELSE IF @EventCode = N'Failure'
      BEGIN
        SET @LogMessage = CONCAT('Setting the Batch Instance ', @BatchInstanceId,
            N' to ', @EventCode, N'.');
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update',
            @LogMessage, @MessageLog)

        -- Note that the default behavior is that Next Run Indicator at Batch level is 'Proceed'.
        -- This will only skip/cancel already successfully completed Modules when a failed Batch is rerun.
        UPDATE [omd].[BATCH_INSTANCE]
          SET
            EXECUTION_STATUS_CODE   = N'Failed',
            NEXT_RUN_STATUS_CODE    = N'Proceed',
            END_TIMESTAMP           = @StartTimestamp
          WHERE BATCH_INSTANCE_ID   = @BatchInstanceId
      END

      -- Rollback event
      ELSE IF @EventCode = N'Rollback'
      BEGIN
        SET @LogMessage = CONCAT(N'Setting the Batch Instance ', @BatchInstanceId,
            N' to ', @EventCode, N'.');
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update',
            @LogMessage, @MessageLog)

        UPDATE [omd].[BATCH_INSTANCE]
          SET
            INTERNAL_PROCESSING_CODE = N'Rollback'
          WHERE BATCH_INSTANCE_ID = @BatchInstanceId;
      END

      -- Proceed event
      ELSE IF @EventCode = N'Proceed'
      BEGIN
        SET @LogMessage = CONCAT('Setting the Batch Instance ', @BatchInstanceId,
            N' to ', @EventCode, N'.');
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update',
            @LogMessage, @MessageLog);

        UPDATE [omd].[BATCH_INSTANCE]
          SET INTERNAL_PROCESSING_CODE = 'Proceed'
          WHERE BATCH_INSTANCE_ID = @BatchInstanceId;
      END

      COMMIT TRANSACTION;
      GOTO EndOfProcedureSuccess;
    END TRY
    BEGIN CATCH
      IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
      SET @SuccessIndicator = 'N';
      IF COALESCE(TRIM(@MessageLog), '') = '' SET @MessageLog = N'[]';

      SET @LogMessage = 'Unknown Transaction Processing Error';
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('ERROR', DEFAULT, 'Process Output', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END CATCH;

/* ----- Start of end state management -------------------------------------- */

    EndOfProcedureFailure:

      SET @SuccessIndicator = 'N';
      SET @LogMessage = N'End Batch Instance process encountered errors.';
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('ERROR', DEFAULT, 'Processing Error', @LogMessage, @MessageLog);
      SET @ReturnCode = -1;

      GOTO EndOfProcedure;

    EndOfProcedureSuccess:

      SET @SuccessIndicator = 'Y';
      SET @LogMessage = N'End Batch Instance process completed successfully.';
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('SUCCESS', DEFAULT, 'Processing Completion', @LogMessage, @MessageLog);
      SET @ReturnCode = 0;

      GOTO EndOfProcedure;

    EndOfProcedure:

      DECLARE @EndTimestamp DATETIME2 = SYSUTCDATETIME();
      DECLARE @EndTimestampString NVARCHAR(4000) = [omd_metadata].[GetTimestampString](@EndTimestamp);
      DECLARE @DurationSeconds NVARCHAR(10) =
        CAST(COALESCE(DATEDIFF(SECOND, @StartTimestamp, @EndTimestamp), 0) AS NVARCHAR(10));

      IF @ProcessMessageLog = 'Y'
      BEGIN
        SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'End Timestamp', @EndTimestampString, @MessageLog);
        SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Elapsed Time (s)', @DurationSeconds, @MessageLog);
        SET @MessageLog =
          [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @SuccessIndicator', @SuccessIndicator, @MessageLog);
      END

      IF @Debug = 'Y' AND @ProcessMessageLog = 'Y' AND @PrintMessages = 'Y'
        EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;

      RETURN @ReturnCode;
  END TRY

/* ----- Common, standardized, Procedure-wrapping error handling ------------ */

  BEGIN CATCH
    /* reset all return/output values except the message log */
    SET @SuccessIndicator = 'N';
    SET @ReturnCode = -2;

    IF @ProcessMessageLog <> 'Y' SET @MessageLog = N'[]'
    ELSE SET @MessageLog =
      [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Parameter @SuccessIndicator',
      @SuccessIndicator, @MessageLog);

    DECLARE
      @ErrorMessage     NVARCHAR(4000),
      @ErrorSeverity    NVARCHAR(10),
      @ErrorState       NVARCHAR(10),
      @ErrorProcedure   NVARCHAR(128),
      @ErrorNumber      NVARCHAR(10),
      @ErrorLine        NVARCHAR(10);

    SELECT
      @ErrorMessage   = COALESCE(ERROR_MESSAGE(), 'No Message'),
      @ErrorSeverity  = COALESCE(CAST(ERROR_SEVERITY() AS NVARCHAR(10)), 'N/A'),
      @ErrorState     = COALESCE(CAST(ERROR_STATE()    AS NVARCHAR(10)), 'N/A'),
      @ErrorProcedure = ERROR_PROCEDURE(),
      @ErrorLine      = COALESCE(CAST(ERROR_LINE()     AS NVARCHAR(10)), 'N/A'),
      @ErrorNumber    = COALESCE(CAST(ERROR_NUMBER()   AS NVARCHAR(10)), 'N/A');

    IF @Debug = 'Y' AND @PrintMessages = 'Y'
    BEGIN
      PRINT 'Error in:         ' + @SpName;
      PRINT 'Error Message:    ' + @ErrorMessage;
      PRINT 'Error Severity:   ' + @ErrorSeverity;
      PRINT 'Error State:      ' + @ErrorState;
      PRINT 'Error Procedure:  ' + @ErrorProcedure;
      PRINT 'Error Line:       ' + @ErrorLine;
      PRINT 'Error Number:     ' + @ErrorNumber;
      PRINT 'SuccessIndicator: ' + @SuccessIndicator;
    END;

    SET @EventTypeCode = N'2';
    DECLARE @ErrorProcedureString NVARCHAR(500);
    IF TRIM(ISNULL(@ErrorProcedure, '')) <> ''
      SET @ErrorProcedureString = CONCAT(', called from procedure: ''', @ErrorProcedure, '''');

    SET @EventDetail = CONCAT(
      'Error in procedure: ''', @SpName,''', at line: ''', @ErrorLine, '''',
      @ErrorProcedureString, ', error message:', CHAR(10), @ErrorMessage
    );
    SET @EventReturnCode = ERROR_NUMBER();

    EXEC [omd].[InsertIntoEventLog]
       @EventTypeCode     = @EventTypeCode
      ,@EventDetail       = @EventDetail
      ,@EventReturnCode   = @EventReturnCode;

    IF @ProcessMessageLog = 'Y'
    BEGIN
      SET @MessageLog = [omd].[AddLogMessage]
        ('CRITICAL', DEFAULT, N'Error EventTypeCode', @EventTypeCode, @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]
        ('CRITICAL', DEFAULT, N'Error Details', @EventDetail, @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]
        ('CRITICAL', DEFAULT, N'Error EventReturnCode', @EventReturnCode, @MessageLog);
    END

    IF @Debug = 'Y' AND @ProcessMessageLog = 'Y' AND @PrintMessages = 'Y'
      EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;

    IF @ThrowOnFailure = 'Y' THROW;
    RETURN @ReturnCode;

  END CATCH;
END;
