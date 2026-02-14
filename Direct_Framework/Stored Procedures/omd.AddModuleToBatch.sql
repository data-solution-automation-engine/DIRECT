/**
 * @procedure [omd].[AddModuleToBatch]
 * @description
 *   Assigns a Module to be associated with a Batch.
 *   Both the Batch and the Module must already exist.
 *   Register new Batches using [omd].[RegisterBatch]
 *   and register new Modules using [omd].[RegisterModule].
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {NVARCHAR(500)} @ModuleCode       [in]  (required)
 *   The code of the module to associate.
 * @param {NVARCHAR(500)} @BatchCode        [in]  (required)
 *   The code of the batch to associate.
 * @param {INT}           @Sequence         [in]  (optional, default=0)
 *   Ordinal for module processing order.
 * @param {CHAR(1)}       @ActiveIndicator  [in]  (optional, default='Y')
 *   Relationship active state indicator.
 * @param {CHAR(1)}       @Debug            [in]  (optional, default='N')
 *   Enables debug logging.
 * @param {CHAR(1)}       @SuccessIndicator [out] (optional)
 *   'Y' if successful, 'N' otherwise.
 * @param {NVARCHAR(MAX)} @MessageLog       [out] (optional)
 *   Structured JSON-format log for diagnostics.
 *
 * @returns {INT} Return code: 0 = success, -1 = failure, -2 = unhandled error.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     function [omd_metadata].[GetSetting]
 *     function [omd_metadata].[GetSettingFlag]
 *     function [omd].[GetBatchIdByName]
 * - writes:
 *     table [omd].[BATCH_MODULE]
 *     procedure [omd].[InsertIntoEventLog]
 *
 * @example

DECLARE @RC INT
  ,@SuccessIndicator CHAR(1)
  ,@MessageLog NVARCHAR(MAX);

EXEC @RC = [omd].[AddModuleToBatch]
   @ModuleCode = 'MyModule'
  ,@BatchCode = 'MyBatch'
  ,@Sequence = 4
  ,@ActiveIndicator = 'Y'
  ,@Debug = 'Y'
  ,@SuccessIndicator = @SuccessIndicator OUTPUT
  ,@MessageLog = @MessageLog OUTPUT;

PRINT(CONCAT('New Module to Batch relationship registered. Success: ', @SuccessIndicator));
PRINT(CONCAT('Return Code: ', @RC));
EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;

 */

CREATE PROCEDURE [omd].[AddModuleToBatch]
(
   /* Required parameters */
   @ModuleCode         NVARCHAR(500)  = NULL
  ,@BatchCode          NVARCHAR(500)  = NULL
   /* Optional parameters with defaults */
  ,@Sequence           INT            = 0
  ,@ActiveIndicator    CHAR(1)        = 'Y'
  ,@Debug              CHAR(1)        = 'N'
   /* Output parameters */
  ,@SuccessIndicator   CHAR(1)        = 'N' OUTPUT
  ,@MessageLog         NVARCHAR(MAX)  = N'' OUTPUT
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

/* ----- Validate input parameters ------------------------------------------ */

-- TODO add validation for all variables incl @ModuleCode and @BatchCode

    /* Local procedure variables */
    DECLARE @ModuleId INT;
    DECLARE @BatchId INT;

    /* Find the Module Id */
    BEGIN TRY
      SELECT @ModuleId = MODULE_ID FROM [omd].[MODULE] WHERE MODULE_CODE = @ModuleCode;

      IF @ModuleId IS NOT NULL
      BEGIN
        SET @LogMessage = 'Module Id ' + CONVERT(NVARCHAR(10), @ModuleId) + ' has been retrieved for Module Code: ' + @ModuleCode + '''.';
        SET @MessageLog = [omd].[AddLogMessage]('SUCCESS', DEFAULT, DEFAULT, @LogMessage, @MessageLog)
      END
      ELSE
      BEGIN
        SET @LogMessage = 'No Module Id has been found for Module Code ''' + @ModuleCode + '''.';
        SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

        GOTO EndOfProcedureFailure
      END
    END TRY

    BEGIN CATCH
      SET @LogMessage = 'Incorrect Module Code specified.';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
      SET @SuccessIndicator = 'N';
      THROW 50000, @LogMessage, 1
    END CATCH

    -- Find the Batch Id
    BEGIN TRY
      SELECT @BatchId = BATCH_ID FROM [omd].[BATCH] WHERE BATCH_CODE = @BatchCode;

      IF @BatchId IS NOT NULL
      BEGIN
        SET @LogMessage = 'Batch Id ' + CONVERT(NVARCHAR(10), @BatchId) + ' has been retrieved for Batch Code: ' + @BatchCode + '''.';
        SET @MessageLog = [omd].[AddLogMessage]('SUCCESS', DEFAULT, DEFAULT, @LogMessage, @MessageLog)
      END
      ELSE
      BEGIN
        SET @LogMessage = 'No Batch Id has been found for Batch Code ''' + @BatchCode + '''.';
        SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

        GOTO EndOfProcedureFailure
      END
    END TRY

    BEGIN CATCH
      SET @LogMessage = 'Incorrect Batch Code specified.';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
      SET @SuccessIndicator = 'N';
      THROW 50000, @LogMessage, 1;
    END CATCH

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
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @ModuleCode',
        @ModuleCode, @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @BatchCode',
        @BatchCode, @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @Sequence',
        CAST(@Sequence AS NVARCHAR(10)), @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @ActiveIndicator',
        @ActiveIndicator, @MessageLog);
    END

/* ----- Start of main process ---------------------------------------------- */

    BEGIN TRY

      IF EXISTS (SELECT 1 FROM [omd].[BATCH_MODULE] WHERE [BATCH_ID] = @BatchId AND [MODULE_ID] = @ModuleId)
      BEGIN
        SET @LogMessage = 'The Module ''' + @ModuleCode + ''' (' + CONVERT(NVARCHAR(10), @ModuleId) + ') is already associated with Batch ''' + @BatchCode + ''' (' + CONVERT(NVARCHAR(10), @BatchId) + '). No update to the existing record will be done.';
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog);
      END
      ELSE
      BEGIN
        INSERT INTO [omd].[BATCH_MODULE] ([BATCH_ID], [MODULE_ID], [SEQUENCE], [ACTIVE_INDICATOR])
        SELECT [BATCH_ID], [MODULE_ID], [SEQUENCE], [ACTIVE_INDICATOR]
        FROM
        (
          VALUES (@BatchId, @ModuleId, @Sequence, @ActiveIndicator)
        ) AS refData([BATCH_ID], [MODULE_ID], [SEQUENCE], [ACTIVE_INDICATOR])
        WHERE NOT EXISTS
        (
          SELECT NULL
          FROM [omd].[BATCH_MODULE] bm
          WHERE bm.BATCH_ID = refData.BATCH_ID AND bm.MODULE_ID = refData.MODULE_ID
        );

        SET @LogMessage = 'The Module ''' + @ModuleCode + ''' (' + CONVERT(NVARCHAR(10), @ModuleId) + ') is associated with Batch ''' + @BatchCode + ''' (' + CONVERT(NVARCHAR(10), @BatchId) + ').';
        SET @MessageLog = [omd].[AddLogMessage]('SUCCESS', DEFAULT, DEFAULT, @LogMessage, @MessageLog)
      END

      SET @LogMessage = 'SELECT * FROM [omd].[BATCH_MODULE] where [BATCH_ID] = ' + CONVERT(NVARCHAR(10), @BatchId) + ' and [MODULE_ID] = ' + CONVERT(NVARCHAR(10), @ModuleId);
      SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, 'Debug Query', @LogMessage, @MessageLog)

      GOTO EndOfProcedureSuccess
    END TRY
    BEGIN CATCH
      SET @LogMessage = 'Unknown Error.';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
      SET @SuccessIndicator = 'N';
      THROW;
    END CATCH

/* ----- Start of end state management -------------------------------------- */

    EndOfProcedureFailure:

      SET @SuccessIndicator = 'N';
      SET @LogMessage = N'Module to Batch registration process encountered errors.';
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('ERROR', DEFAULT, 'Processing Error', @LogMessage, @MessageLog);
      SET @ReturnCode = -1;

      GOTO EndOfProcedure;

    EndOfProcedureSuccess:

      SET @SuccessIndicator = 'Y';
      SET @LogMessage = N'Module to Batch registration process completed successfully.';
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
