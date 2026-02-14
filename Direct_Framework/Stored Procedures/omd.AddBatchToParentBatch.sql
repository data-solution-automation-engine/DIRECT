/**
 * @procedure [omd].[AddBatchToParentBatch]
 * @description
 *   Assigns a Batch to be associated with a Parent Batch.
 *   Both Batches must already exist.
 *   Register new Batches using [omd].[RegisterBatch].
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {NVARCHAR(500)} @BatchCode        [in]  (required)
 *   The code of the batch to associate.
 * @param {NVARCHAR(500)} @ParentBatchCode  [in]  (required)
 *   The code of the parent batch to associate.
 * @param {INT}           @Sequence         [in]  (optional, default=0)
 *   Ordinal for child processing order.
 * @param {CHAR(1)}       @ActiveIndicator  [in]  (optional, default='Y')
 *   Relationship active state indicator.
 * @param {CHAR(1)}       @Debug            [in]  (optional, default='N')
 *   Enables debug logging.
 * @param {CHAR(1)}       @CheckDag         [in]  (optional, default='N')
 *   Checks DAG, existing relationship graph, for cycles.
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
 *     table [omd].[BATCH_HIERARCHY]
 *     procedure [omd].[InsertIntoEventLog]
 *
 * @example

DECLARE @RC INT
  ,@SuccessIndicator CHAR(1)
  ,@MessageLog NVARCHAR(MAX);

EXEC @RC = [omd].[AddBatchToParentBatch]
   @BatchCode = 'MyBatch'
  ,@ParentBatchCode = 'MyParentBatch'
  ,@Sequence = 3
  ,@ActiveIndicator = 'Y'
  ,@Debug = 'Y'
  ,@SuccessIndicator = @SuccessIndicator OUTPUT
  ,@MessageLog = @MessageLog OUTPUT;

PRINT(CONCAT('New hierarchy relationship registered. Success: ', @SuccessIndicator));
PRINT(CONCAT('Return Code: ', @RC));
EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;

 */

CREATE PROCEDURE [omd].[AddBatchToParentBatch]
(
   /* Required parameters */
   @BatchCode           NVARCHAR(500) = NULL
  ,@ParentBatchCode     NVARCHAR(500) = NULL
   /* Optional parameters with defaults */
  ,@Sequence            INT           = 0
  ,@ActiveIndicator     CHAR(1)       = 'Y'
  ,@Debug               CHAR(1)       = 'N'
  ,@CheckDag            CHAR(1)       = 'N'
   /* Output parameters */
  ,@SuccessIndicator    CHAR(1)       = 'N' OUTPUT
  ,@MessageLog          NVARCHAR(MAX) = N'' OUTPUT
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

    IF @BatchCode IS NULL OR TRIM(@BatchCode) = ''
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @LogMessage = N'Parameter @BatchCode is required.'
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END;

    IF @ParentBatchCode IS NULL OR TRIM(@ParentBatchCode) = ''
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @LogMessage = N'Parameter @ParentBatchCode is required.'
      IF @ProcessMessageLog = 'Y'
        SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END;

    IF @Sequence IS NULL OR @Sequence < 0
    BEGIN
      SET @Sequence = 0;
      IF @ProcessMessageLog = 'Y'
        SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @Sequence', N'Default value 0 applied.', @MessageLog);
    END;
    SET @ActiveIndicator = CASE WHEN TRIM(UPPER(@ActiveIndicator)) = 'Y' THEN 'Y' ELSE 'N' END;
    SET @CheckDag = CASE WHEN TRIM(UPPER(@CheckDag)) = 'Y' THEN 'Y' ELSE 'N' END;

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
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @BatchCode',
        @BatchCode, @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @ParentBatchCode',
        @ParentBatchCode, @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @Sequence',
        CONVERT(NVARCHAR(10), @Sequence), @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @ActiveIndicator',
        @ActiveIndicator, @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @CheckDag',
        @CheckDag, @MessageLog);
    END

/* ----- Start of main process ---------------------------------------------- */

    /* Local procedure variables */
    DECLARE @BatchId INT;
    DECLARE @ParentBatchId INT;

    /* Find the Child Batch Id from the Batch Code */
    BEGIN TRY
      SET @BatchId = [omd].[GetBatchIdByName](@BatchCode);

      IF @BatchId IS NULL OR @BatchId = 0
      BEGIN
        SET @LogMessage = 'No Valid Batch Id was found for Batch Code ''' + @BatchCode + '''.';
        IF @ProcessMessageLog = 'Y' SET @MessageLog =
          [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
        IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
        GOTO EndOfProcedureFailure;
      END;
      ELSE
      BEGIN
        SET @LogMessage = 'Batch Id ''' + CONVERT(NVARCHAR(10), @BatchId) + ''' has been retrieved for @BatchCode ''' +
          @BatchCode + '''.';
        IF @ProcessMessageLog = 'Y' SET @MessageLog =
          [omd].[AddLogMessage]('INFO', DEFAULT, 'Status Update', @LogMessage, @MessageLog);
      END;
    END TRY
    BEGIN CATCH
      SET @LogMessage = 'Error Processing Batch Code.';
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
      SET @SuccessIndicator = 'N';
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END CATCH;

    /* Find the Parent Batch Id from the Parent Batch Code */
    BEGIN TRY
      SET @ParentBatchId = [omd].[GetBatchIdByName](@ParentBatchCode);

      IF @ParentBatchId IS NULL OR @ParentBatchId = 0
      BEGIN
        SET @LogMessage = 'No Valid Batch Id was found for @ParentBatchCode ''' + @ParentBatchCode + '''.';
        IF @ProcessMessageLog = 'Y' SET @MessageLog =
          [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
        IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
        GOTO EndOfProcedureFailure;
      END;
      ELSE
      BEGIN
        SET @LogMessage = 'Parent Batch Id ''' + CONVERT(NVARCHAR(10), @ParentBatchId) +
          ''' has been retrieved for @ParentBatchCode ''' + @ParentBatchCode + '''.';
        IF @ProcessMessageLog = 'Y' SET @MessageLog =
          [omd].[AddLogMessage]('INFO', DEFAULT, 'Status Update', @LogMessage, @MessageLog);
      END;
    END TRY
    BEGIN CATCH
      SET @LogMessage = 'Error Processing @ParentBatchCode.';
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
      SET @SuccessIndicator = 'N';
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END CATCH;

/* ----- Start of dag validation process ------------------------------------ */

    /* Always prevent a batch from being its own parent */
    IF @BatchId = @ParentBatchId
    BEGIN
      SET @LogMessage = CONCAT('A batch cannot be its own parent. ',
        'BatchId and ParentBatchId are both: ''', @BatchId, '''.');
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      GOTO EndOfProcedureFailure;
    END

    /*
      Validate the relationship DAG
      Ensure that adding @ParentBatchId -> @BatchId
      does not create a cyclic relationship.
    */
    IF @CheckDag = 'Y'
    BEGIN
      BEGIN TRY
        DROP TABLE IF EXISTS #DagViolation;
        WITH Ancestors AS
        (
          SELECT BATCH_ID, PARENT_BATCH_ID
          FROM [omd].[BATCH_HIERARCHY]
          WHERE BATCH_ID = @ParentBatchId

          UNION ALL

          SELECT bh.BATCH_ID, bh.PARENT_BATCH_ID
          FROM [omd].[BATCH_HIERARCHY] bh
          INNER JOIN Ancestors a ON bh.BATCH_ID = a.PARENT_BATCH_ID
        )
        SELECT BATCH_ID
        INTO #DagViolation
        FROM Ancestors
        WHERE PARENT_BATCH_ID = @BatchId;

        IF EXISTS (SELECT 1 FROM #DagViolation)
        BEGIN
          SET @LogMessage = CONCAT(
            'Circular relationship detected: adding BatchId ',
            @BatchId,
            ' under ParentBatchId ',
            @ParentBatchId,
            ' would create a cycle.');
          IF @ProcessMessageLog = 'Y' SET @MessageLog =
            [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
          DROP TABLE IF EXISTS #DagViolation;
          IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
          GOTO EndOfProcedureFailure;
        END;
      DROP TABLE IF EXISTS #DagViolation;
      END TRY
      BEGIN CATCH
        DROP TABLE IF EXISTS #DagViolation;
        SET @LogMessage = 'Error testing for circular relationships in the DAG check.';
        IF @ProcessMessageLog = 'Y' SET @MessageLog =
          [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
        SET @SuccessIndicator = 'N';
        IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
        GOTO EndOfProcedureFailure;
      END CATCH;
    END

/* ----- Start of "Batch - Parent Batch" Registration ----------------------- */

    BEGIN TRY
      BEGIN TRANSACTION;
        DECLARE @MergeActions TABLE (Action NVARCHAR(10));
        DECLARE @MergeAction NVARCHAR(10);

        MERGE [omd].[BATCH_HIERARCHY] AS target
        USING (
          SELECT
            @ParentBatchId AS [PARENT_BATCH_ID],
            @BatchId AS [BATCH_ID],
            @Sequence AS [SEQUENCE],
            @ActiveIndicator AS [ACTIVE_INDICATOR]
        ) AS source
        ON target.[PARENT_BATCH_ID] = source.[PARENT_BATCH_ID]
          AND target.[BATCH_ID] = source.[BATCH_ID]
        WHEN NOT MATCHED THEN
          INSERT ([PARENT_BATCH_ID], [BATCH_ID], [SEQUENCE], [ACTIVE_INDICATOR])
          VALUES (source.[PARENT_BATCH_ID], source.[BATCH_ID], source.[SEQUENCE], source.[ACTIVE_INDICATOR])
        OUTPUT $action INTO @MergeActions(Action);

        SELECT TOP 1 @MergeAction = Action FROM @MergeActions;

        IF @MergeAction = 'INSERT'
        BEGIN
          SET @LogMessage = CONCAT(
            'The Batch ''', @BatchCode, ''' (', @BatchId, ') ',
            'is associated with Parent Batch ''', @ParentBatchCode, ''' (', @ParentBatchId, ').');
          IF @ProcessMessageLog = 'Y'
            SET @MessageLog = [omd].[AddLogMessage]('SUCCESS', DEFAULT, 'Process Output', @LogMessage, @MessageLog);
        END
        ELSE
        BEGIN
          SET @LogMessage = CONCAT(
            'No new hierarchy entry was created; relationship between Batch ''', @BatchCode,
             ''' and Parent Batch ''', @ParentBatchCode, ''' already exists.');
          IF @ProcessMessageLog = 'Y'
            SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, 'No-op Insert', @LogMessage, @MessageLog);
        END

        SET @LogMessage = CONCAT(
          'SELECT *', CHAR(10),
          'FROM [omd].[BATCH_HIERARCHY]', CHAR(10),
          'WHERE', CHAR(10),
          '  [PARENT_BATCH_ID] = ', @ParentBatchId, CHAR(10),
          '  AND [BATCH_ID] = ', @BatchId
        );

      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('DEBUG', DEFAULT, 'Metadata Review Query', @LogMessage, @MessageLog);

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
      SET @LogMessage = N'Batch to Parent Batch registration process encountered errors.';
      IF @ProcessMessageLog = 'Y' SET @MessageLog =
        [omd].[AddLogMessage]('ERROR', DEFAULT, 'Processing Error', @LogMessage, @MessageLog);
      SET @ReturnCode = -1;

      GOTO EndOfProcedure;

    EndOfProcedureSuccess:

      SET @SuccessIndicator = 'Y';
      SET @LogMessage = N'Batch to Parent Batch registration process completed successfully.';
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
