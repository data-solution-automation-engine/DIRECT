/**
 * @procedure [omd].[EndModuleInstance]
 * @description End a Module Instance and set status codes
 * and row counts based on event inputs.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {BIGINT}  @ModuleInstanceId   [in]  (required)
 *   The Module Instance identifier to update.
 * @param {NVARCHAR(100)} @EventCode    [in]  (optional, default='Failure')
 *   One of: 'Proceed', 'Cancel', 'Abort', 'Rollback', 'Success', 'Failure'.
 * @param {NVARCHAR(4000)} @EventDetail  [in]  (optional)
 *   Additional details for the event log.
 * @param {BIGINT}  @RowCountSelect     [in]  (optional, default=0)
 *   Rows read during processing.
 * @param {BIGINT}  @RowCountInserted   [in]  (optional, default=0)
 *   Rows inserted during processing.
 * @param {BIGINT}  @RowCountUpdated    [in]  (optional, default=0)
 *   Rows updated during processing.
 * @param {BIGINT}  @RowCountDeleted    [in]  (optional, default=0)
 *   Rows deleted during processing.
 * @param {BIGINT}  @RowCountDiscarded  [in]  (optional, default=0)
 *   Rows discarded during processing.
 * @param {BIGINT}  @RowCountRejected   [in]  (optional, default=0)
 *   Rows rejected during processing.
 * @param {DATETIME2} @EndTimestamp     [in]  (optional)
 *   Override end timestamp for the instance.
 * @param {CHAR(1)} @Debug              [in]  (optional, default='N')
 *   Enables debug logging.
 * @param {CHAR(1)} @SuccessIndicator   [out] (optional)
 *   'Y' if the operation completed successfully; otherwise 'N'.
 * @param {NVARCHAR(MAX)} @MessageLog   [out] (optional)
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
 *     table [omd].[MODULE_INSTANCE]
 *     procedure [omd].[InsertIntoEventLog]
 * - utilities:
 *     function [omd].[AddLogMessage]
 *     procedure [omd].[PrintMessageLog]
 *
 * @example
 * DECLARE @SuccessIndicator CHAR(1), @MessageLog NVARCHAR(MAX);
 * EXEC [omd].[UpdateModuleInstance]
 *   @ModuleInstanceId = 1001,
 *   @EventCode = 'Success',
 *   @RowCountSelect = 100,
 *   @RowCountInserted = 100,
 *   @Debug = 'Y',
 *   @SuccessIndicator = @SuccessIndicator OUTPUT,
 *   @MessageLog = @MessageLog OUTPUT;
 * EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;
 */

CREATE PROCEDURE [omd].[EndModuleInstance]
(
   -- Mandatory parameters
   @ModuleInstanceId   BIGINT         = NULL
   -- Optional parameters
  ,@EventCode          NVARCHAR(100)  = 'Failure'
  ,@EventDetail        NVARCHAR(4000) = NULL
   -- Optional row count updates
  ,@RowCountInput      BIGINT         = NULL
  ,@RowCountInserted   BIGINT         = NULL
  ,@RowCountUpdated    BIGINT         = NULL
  ,@RowCountDeleted    BIGINT         = NULL
  ,@RowCountDiscarded  BIGINT         = NULL
  ,@RowCountRejected   BIGINT         = NULL
   -- Optional parameters
  ,@EndTimestamp       DATETIME2      = NULL
  ,@Debug              CHAR(1)        = 'N'
   -- Output parameters
  ,@SuccessIndicator   CHAR(1)        = 'N' OUTPUT
  ,@MessageLog         NVARCHAR(MAX)  = N'' OUTPUT
)
AS
BEGIN
  BEGIN TRY
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    /* ----- Standard setup and initialization ------------------------------ */
    DECLARE @ProcessDescription NVARCHAR(4000) = N'End Module Instance process';

    SET @Debug = CASE WHEN TRIM(UPPER(@Debug)) = 'Y' THEN 'Y' ELSE 'N' END;
    SET @SuccessIndicator = 'N';
    SET @MessageLog = N'[]';
    DECLARE @LogMessage NVARCHAR(2048);

    /* Event and return codes */
    DECLARE @ReturnCode INT = 0;
    DECLARE @EventTypeCode NVARCHAR(100) = N'2';
    -- reusing event detail for internal processing, consider reworking
    -- DECLARE @EventDetail NVARCHAR(4000) = N'';
    DECLARE @EventReturnCode NVARCHAR(100) = N'';

    /* Load framework settings */
    DECLARE @AddLogsToEventLog CHAR(1)      = [omd_metadata].[GetSettingFlag]('LOG_TO_EVENT_LOG');
    DECLARE @PrintMessages CHAR(1)          = [omd_metadata].[GetSettingFlag]('SP_PRINT_MESSAGES');
    DECLARE @ProcessMessageLog CHAR(1)      = [omd_metadata].[GetSettingFlag]('SP_PROCESS_MESSAGE_LOG');
    DECLARE @ThrowOnFailure CHAR(1)         = [omd_metadata].[GetSettingFlag]('THROW_ON_FAILURE');
    DECLARE @DefaultTimeZone NVARCHAR(4000) = [omd_metadata].[GetSetting]('DEFAULT_TIMEZONE');

    /* ----- Default logging setup ------------------------------------------ */

    DECLARE @StartTimestamp DATETIME2 = SYSUTCDATETIME();
    DECLARE @StartTimestampString NVARCHAR(4000) =
      [omd_metadata].[GetTimestampString](@StartTimestamp);
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

      /* Log parameters and their values as single json block */
      DECLARE @paramsJson NVARCHAR(max) =
        (SELECT
          @ModuleInstanceId   AS ModuleInstanceId,
          @EventCode          AS EventCode,
          @EventDetail        AS EventDetail,
          @RowCountInput      AS RowCountInput,
          @RowCountInserted   AS RowCountInserted,
          @RowCountUpdated    AS RowCountUpdated,
          @RowCountDeleted    AS RowCountDeleted,
          @RowCountDiscarded  AS RowCountDiscarded,
          @RowCountRejected   AS RowCountRejected,
          @EndTimestamp       AS EndTimestamp,
          @Debug              AS Debug
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

      SET @MessageLog = [omd].[AddLogMessage]
        ('INFO', DEFAULT, N'Parameters', @paramsJson, @MessageLog);
    END;

    /* ----- Validate input parameters -------------------------------------- */

    IF @ModuleInstanceId IS NULL OR @ModuleInstanceId <= 0
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @LogMessage = N'Parameter @ModuleInstanceId is required.'
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END;

    IF @EventCode IS NULL OR TRIM(@EventCode) NOT IN
      ('Proceed', 'Cancel', 'Abort', 'Rollback', 'Success', 'Failure')
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @LogMessage = concat(N'Parameter @EventCode is required and must be ',
        N'one of the following values: ',
        N'Proceed, Cancel, Abort, Rollback, Success, Failure.')
      IF @ProcessMessageLog = 'Y'
        SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END;

    /* Normalize all other input parameters */
    SELECT
      @EndTimestamp       = COALESCE(@EndTimestamp, @StartTimestamp)
      -- @RowCountInput      = CASE WHEN @RowCountInput      >= 0 THEN @RowCountInput      ELSE 0 END,
      -- @RowCountInserted   = CASE WHEN @RowCountInserted   >= 0 THEN @RowCountInserted   ELSE 0 END,
      -- @RowCountUpdated    = CASE WHEN @RowCountUpdated    >= 0 THEN @RowCountUpdated    ELSE 0 END,
      -- @RowCountDeleted    = CASE WHEN @RowCountDeleted    >= 0 THEN @RowCountDeleted    ELSE 0 END,
      -- @RowCountDiscarded  = CASE WHEN @RowCountDiscarded  >= 0 THEN @RowCountDiscarded  ELSE 0 END,
      -- @RowCountRejected   = CASE WHEN @RowCountRejected   >= 0 THEN @RowCountRejected   ELSE 0 END;

    /* Add normalized parameters log here if required */

    DECLARE @RowsAffected INT = 0;

    /* ----- Start of main process ------------------------------------------ */

    BEGIN TRY
      BEGIN TRANSACTION;

        SET @LogMessage = CONCAT('Setting Module Instance ',
          @ModuleInstanceId, ' to ', @EventCode, '.')

        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT,
          N'Status Update', @LogMessage, @MessageLog);

        ;WITH StatusMap AS (
          SELECT *
          FROM (VALUES
            ('Abort',    'Aborted',   'Abort',    'Proceed',  1, 1),
            ('Cancel',   'Cancelled', 'Cancel',   'Proceed',  1, 1),
            ('Success',  'Succeeded', 'Proceed',  'Proceed',  1, 1),
            ('Failure',  'Failed',    NULL,       'Rollback', 1, 1),
            ('Rollback', NULL,        'Rollback', NULL,       1, 1),
            ('Proceed',  NULL,        'Proceed',  NULL,       1, 1)
          ) AS map(EventCode, ExecutionStatusCode, InternalProcessingCode,
            NextRunStatusCode, ApplyEndTimestamp, ApplyRowCounts)
        )
        UPDATE mi
        SET
          EXECUTION_STATUS_CODE = COALESCE(sm.ExecutionStatusCode, mi.EXECUTION_STATUS_CODE),
          INTERNAL_PROCESSING_CODE = COALESCE(sm.InternalProcessingCode, mi.INTERNAL_PROCESSING_CODE),
          NEXT_RUN_STATUS_CODE = COALESCE(sm.NextRunStatusCode, mi.NEXT_RUN_STATUS_CODE),
          END_TIMESTAMP = CASE WHEN sm.ApplyEndTimestamp = 1 THEN @EndTimestamp ELSE mi.END_TIMESTAMP END,
          /* Update row counts if settings are enabled for it and
          values are provided as parameters. If not, keep existing values.
          If both are null, set them to 0 */
          ROWS_INPUT = CASE
            WHEN sm.ApplyRowCounts = 0 THEN mi.ROWS_INPUT
            WHEN @RowCountInput >= 0 THEN @RowCountInput
            WHEN @RowCountInput IS NULL AND mi.ROWS_INPUT IS NULL THEN 0
            ELSE mi.ROWS_INPUT
          END,

          ROWS_INSERTED = CASE
            WHEN sm.ApplyRowCounts = 0 THEN mi.ROWS_INSERTED
            WHEN @RowCountInserted >= 0 THEN @RowCountInserted
            WHEN @RowCountInserted IS NULL AND mi.ROWS_INSERTED IS NULL THEN 0
            ELSE mi.ROWS_INSERTED
          END,
          ROWS_UPDATED = CASE
            WHEN sm.ApplyRowCounts = 0 THEN mi.ROWS_UPDATED
            WHEN @RowCountUpdated >= 0 THEN @RowCountUpdated
            WHEN @RowCountUpdated IS NULL AND mi.ROWS_UPDATED IS NULL THEN 0
            ELSE mi.ROWS_UPDATED
          END,
          ROWS_DELETED = CASE
            WHEN sm.ApplyRowCounts = 0 THEN mi.ROWS_DELETED
            WHEN @RowCountDeleted >= 0 THEN @RowCountDeleted
            WHEN @RowCountDeleted IS NULL AND mi.ROWS_DELETED IS NULL THEN 0
            ELSE mi.ROWS_DELETED
          END,
          ROWS_DISCARDED = CASE
            WHEN sm.ApplyRowCounts = 0 THEN mi.ROWS_DISCARDED
            WHEN @RowCountDiscarded >= 0 THEN @RowCountDiscarded
            WHEN @RowCountDiscarded IS NULL AND mi.ROWS_DISCARDED IS NULL THEN 0
            ELSE mi.ROWS_DISCARDED
          END,
          ROWS_REJECTED = CASE
            WHEN sm.ApplyRowCounts = 0 THEN mi.ROWS_REJECTED
            WHEN @RowCountRejected >= 0 THEN @RowCountRejected
            WHEN @RowCountRejected IS NULL AND mi.ROWS_REJECTED IS NULL THEN 0
            ELSE mi.ROWS_REJECTED
          END
        FROM [omd].[MODULE_INSTANCE] AS mi
        INNER JOIN StatusMap AS sm
          ON sm.EventCode = @EventCode
        WHERE mi.MODULE_INSTANCE_ID = @ModuleInstanceId;

        SET @RowsAffected = @@ROWCOUNT;

        IF @RowsAffected = 0
        BEGIN
          IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
          SET @SuccessIndicator = 'N';
          SET @LogMessage = CONCAT('No module instance row updated for ModuleInstanceId ',
            @ModuleInstanceId, ' and EventCode ''', @EventCode, '''.');
          IF @ProcessMessageLog = 'Y'
            SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT,
              N'Transaction Error', @LogMessage, @MessageLog);
          IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
          GOTO EndOfProcedureFailure;
        END;

      COMMIT TRANSACTION;
      GOTO EndOfProcedureSuccess;
    END TRY
    BEGIN CATCH
      DECLARE
        @TxnErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(),
        @TxnErrorNumber INT = ERROR_NUMBER(),
        @TxnErrorSeverity INT = ERROR_SEVERITY(),
        @TxnErrorState INT = ERROR_STATE(),
        @TxnErrorLine INT = ERROR_LINE();

      IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
      SET @SuccessIndicator = 'N';
      IF COALESCE(TRIM(@MessageLog), '') = '' SET @MessageLog = N'[]';

      SET @LogMessage = CONCAT('Transaction error (', @TxnErrorNumber, '/', @TxnErrorState,
        ') at line ', @TxnErrorLine, ': ', COALESCE(@TxnErrorMessage, 'No additional details.'));
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('ERROR', DEFAULT, 'Transaction Error', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW;
      GOTO EndOfProcedureFailure;
    END CATCH;

/* ----- Start of end state management -------------------------------------- */

    EndOfProcedureFailure:

      SET @SuccessIndicator = 'N';
      SET @LogMessage = CONCAT(@ProcessDescription, N' encountered errors.');
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('ERROR', DEFAULT, 'Processing Error', @LogMessage, @MessageLog);
      SET @ReturnCode = -1;

      GOTO EndOfProcedure;

    EndOfProcedureSuccess:

      SET @SuccessIndicator = 'Y';
      SET @LogMessage = CONCAT(@ProcessDescription, N' completed successfully.');
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('SUCCESS', DEFAULT, 'Processing Completion', @LogMessage, @MessageLog);
      SET @ReturnCode = 0;

      GOTO EndOfProcedure;

    EndOfProcedure:

      DECLARE @ProcessEndTimestamp DATETIME2 = SYSUTCDATETIME();
      DECLARE @ProcessEndTimestampString NVARCHAR(4000) = [omd_metadata].[GetTimestampString](@ProcessEndTimestamp);
      DECLARE @DurationSeconds NVARCHAR(10) =
        CAST(COALESCE(DATEDIFF(SECOND, @StartTimestamp, @ProcessEndTimestamp), 0) AS NVARCHAR(10));

      IF @ProcessMessageLog = 'Y'
      BEGIN
        SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'End Timestamp', @ProcessEndTimestampString, @MessageLog);
        SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Elapsed Time (s)', @DurationSeconds, @MessageLog);
        SET @MessageLog =
          [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @SuccessIndicator', @SuccessIndicator, @MessageLog);
      END

      IF @Debug = 'Y' AND @ProcessMessageLog = 'Y' AND @PrintMessages = 'Y'
        EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;

      RETURN @ReturnCode;
  END TRY

  /* ----- Common, standardized, Procedure-wrapping error handling ---------- */

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
