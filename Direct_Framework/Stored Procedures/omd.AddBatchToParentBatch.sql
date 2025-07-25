/*******************************************************************************
Procedure:      [omd].[AddBatchToParentBatch]
Documentation:  https://github.com/data-solution-automation-engine/DIRECT
Version:        DIRECT Framework 2.1.0
********************************************************************************

Purpose:
  Assigns a Batch to be associated with a Parent Batch.
  Both Batches must already exist.

Inputs:
  - Batch Code
  - Parent Batch Code
  - Sequence. Optional ordinal for processing order
  - Active Indicator (Y/N defaults to Y)
  - Debug Flag (Y/N, defaults to N)
  - CheckDag (Y/N, defaults to N). Checks the relationship graph before adding

Outputs:
  - Success Indicator (Y/N)
  - Message Log

********************************************************************************

Example Usage:

DECLARE @BatchId          INT;
DECLARE @SuccessIndicator CHAR(1);
DECLARE @MessageLog       NVARCHAR(MAX);

EXEC [omd].[AddBatchToParentBatch]
  -- Mandatory parameters
  @BatchCode        = 'MyBatch',
  @ParentBatchCode  = 'MyParentBatch',
  -- Optional parameters
  @ActiveIndicator  = 'Y',
  @Debug            = 'Y',
  -- Output parameters
  @SuccessIndicator = @SuccessIndicator OUTPUT,
  @MessageLog       = @MessageLog OUTPUT;

PRINT('New hierarchy item registered: ' + @SuccessIndicator)

*******************************************************************************/

CREATE PROCEDURE [omd].[AddBatchToParentBatch]
(
  -- Mandatory parameters
  @BatchCode          NVARCHAR(500) = NULL,
  @ParentBatchCode    NVARCHAR(500) = NULL,
  -- Optional parameters
  @Sequence           INT           = 0,
  @ActiveIndicator    CHAR(1)       = 'Y',
  @Debug              CHAR(1)       = 'N',
  @CheckDag           CHAR(1)       = 'N',
  -- Output parameters
  @SuccessIndicator   CHAR(1)       = 'N' OUTPUT,
  @MessageLog         NVARCHAR(MAX) = N'' OUTPUT
)
AS
BEGIN
  BEGIN TRY
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- standard setup and initialization
    SET @Debug = CASE WHEN UPPER(@Debug) = 'Y' THEN 'Y' ELSE 'N' END;
    SET @SuccessIndicator = 'N';
    SET @MessageLog = N'[]';

    -- Event and return codes
    DECLARE @ReturnCode INT = 0;
    DECLARE @EventTypeCode NVARCHAR(100) = N'2';
    DECLARE @EventDetail NVARCHAR(4000) = N'';
    DECLARE @EventReturnCode NVARCHAR(100) = N'';

    -- Load framework settings
    DECLARE @AddLogsToEventLog CHAR(1)      = [omd_metadata].[GetSettingFlag]('LOG_TO_EVENT_LOG');
    DECLARE @PrintMessages CHAR(1)          = [omd_metadata].[GetSettingFlag]('SP_PRINT_MESSAGES');
    DECLARE @ProcessMessageLog CHAR(1)      = [omd_metadata].[GetSettingFlag]('SP_PROCESS_MESSAGE_LOG');
    DECLARE @ThrowOnFailure CHAR(1)         = [omd_metadata].[GetSettingFlag]('THROW_ON_FAILURE');
    DECLARE @DefaultTimeZone NVARCHAR(4000) = [omd_metadata].[GetSetting]('DEFAULT_TIMEZONE');

/* ----- Validate input parameters ------------------------------------------ */
    IF @BatchCode IS NULL OR TRIM(@BatchCode) = ''
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, N'Batch Code is required.', @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, 'Batch Code is required.', 1;
      ELSE GOTO EndOfProcedureFailure;
    END;

    IF @ParentBatchCode IS NULL OR TRIM(@ParentBatchCode) = ''
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, N'Parent Batch Code is required.', @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, 'Parent Batch Code is required.', 1;
      ELSE GOTO EndOfProcedureFailure;
    END;

    IF @Sequence IS NULL OR @Sequence < 0 SET @Sequence = 0;
    SET @ActiveIndicator = CASE WHEN UPPER(@ActiveIndicator) = 'Y' THEN 'Y' ELSE 'N' END;
    SET @CheckDag = CASE WHEN UPPER(@CheckDag) = 'Y' THEN 'Y' ELSE 'N' END;

    -- Default logging setup
    DECLARE @StartTimestamp DATETIME2 = SYSUTCDATETIME();
    DECLARE @StartTimestampString NVARCHAR(4000) = [omd_metadata].[GetTimestampString](@StartTimestamp);
    DECLARE @LogMessage NVARCHAR(MAX);
    DECLARE @SpName NVARCHAR(300) = CONCAT(QUOTENAME(COALESCE(OBJECT_SCHEMA_NAME(@@PROCID),'Unknown')),
            N'.', QUOTENAME(COALESCE(OBJECT_NAME(@@PROCID), 'Unknown')));

    -- Log standard metadata
    SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Procedure', @SpName, @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Version', [omd_metadata].[GetFrameworkVersion](), @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Start Timestamp', @StartTimestampString, @MessageLog);

    -- Log parameters
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @BatchCode', @BatchCode, @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @ParentBatchCode', @ParentBatchCode, @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @Sequence', CONVERT(NVARCHAR(10), @Sequence), @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @ActiveIndicator', @ActiveIndicator, @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @CheckDag', @CheckDag, @MessageLog);

/* ----- Start of main process ---------------------------------------------- */

    -- Local procedure variables
    DECLARE @BatchId INT;
    DECLARE @ParentBatchId INT;

    -- Find the Child Batch Id
    BEGIN TRY
      SET @BatchId = [omd].[GetBatchIdByName](@BatchCode);

      IF @BatchId IS NULL OR @BatchId = 0
      BEGIN
        SET @LogMessage = 'No Valid Batch Id was found for Batch Code ''' + @BatchCode + '''.';
        SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter Error', @LogMessage, @MessageLog);
        IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1
        ELSE GOTO EndOfProcedureFailure;
      END
      ELSE
      BEGIN
        SET @LogMessage = 'Batch Id ''' + CONVERT(NVARCHAR(10), @BatchId) + ''' has been retrieved for Batch Code ''' + @BatchCode + '''.';
        SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, 'Status Update', @LogMessage, @MessageLog);
      END;
    END TRY
    BEGIN CATCH
      SET @LogMessage = 'Error Processing Batch Code.';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
      SET @SuccessIndicator = 'N';
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1
      ELSE GOTO EndOfProcedureFailure;
    END CATCH;

    -- Find the Parent Batch Id
    BEGIN TRY
      SET @ParentBatchId = [omd].[GetBatchIdByName](@ParentBatchCode);

      IF @ParentBatchId IS NULL OR @ParentBatchId = 0
      BEGIN
        SET @LogMessage = 'No Valid Batch Id was found for Parent Batch Code ''' + @ParentBatchCode + '''.';
        SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter Error', @LogMessage, @MessageLog);
        IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1
        ELSE GOTO EndOfProcedureFailure;
      END
      ELSE
      BEGIN
        SET @LogMessage = 'Parent Batch Id ''' + CONVERT(NVARCHAR(10), @ParentBatchId) + ''' has been retrieved for Parent Batch Code ''' + @ParentBatchCode + '''.';
        SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, 'Status Update', @LogMessage, @MessageLog);
      END;
    END TRY
    BEGIN CATCH
      SET @LogMessage = 'Error Processing Parent Batch Code.';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter Error', @LogMessage, @MessageLog);
      SET @SuccessIndicator = 'N';
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1
      ELSE GOTO EndOfProcedureFailure;
    END CATCH;

/* ----- Start of dag validation process ------------------------------------ */

    -- Validate the relationship DAG
    -- Ensure that adding @ParentBatchId -> @BatchId
    -- does not create a cyclic relationship.
    IF @CheckDag = 'Y'
    BEGIN
      BEGIN TRY
        DROP TABLE IF EXISTS #DagViolation;
        ;WITH Ancestors AS
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
            CONVERT(NVARCHAR(10), @BatchId),
            ' under ParentBatchId ',
            CONVERT(NVARCHAR(10), @ParentBatchId),
            ' would create a cycle.');
          SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
          DROP TABLE IF EXISTS #DagViolation;
          IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1
          ELSE GOTO EndOfProcedureFailure;
        END
      DROP TABLE IF EXISTS #DagViolation;
      END TRY
      BEGIN CATCH
        DROP TABLE IF EXISTS #DagViolation;
        SET @LogMessage = 'Error testing for circular relationships in the DAG check.';
        SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
        SET @SuccessIndicator = 'N';
        IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1
        ELSE GOTO EndOfProcedureFailure;
      END CATCH
    END

/* ----- Start of "Batch - Parent Batch" Registration ----------------------- */
    BEGIN TRY
      BEGIN TRANSACTION;

      INSERT INTO [omd].[BATCH_HIERARCHY]
        ([PARENT_BATCH_ID], [BATCH_ID], [SEQUENCE], [ACTIVE_INDICATOR])
      SELECT [PARENT_BATCH_ID], [BATCH_ID], [SEQUENCE], [ACTIVE_INDICATOR]
      FROM
      (
        VALUES
        (@ParentBatchId, @BatchId, @Sequence, @ActiveIndicator)
      ) AS refData([PARENT_BATCH_ID], [BATCH_ID], [SEQUENCE], [ACTIVE_INDICATOR])
      WHERE NOT EXISTS
      (
        SELECT NULL
        FROM [omd].[BATCH_HIERARCHY] bh
        WHERE bh.PARENT_BATCH_ID = refData.PARENT_BATCH_ID AND bh.BATCH_ID = refData.BATCH_ID
      );

      SET @LogMessage =
        'The Batch ''' + @BatchCode + ''' ('+CONVERT(NVARCHAR(10), @BatchId) + ') ' +
        'is associated with Parent Batch ''' + @ParentBatchCode + ''' (' + CONVERT(NVARCHAR(10), @ParentBatchId) + ').';
      SET @MessageLog = [omd].[AddLogMessage]('SUCCESS', DEFAULT, 'Process Output', @LogMessage, @MessageLog);

      SET @LogMessage =
        'SELECT * FROM [omd].[BATCH_HIERARCHY]' + CHAR(10) +
        'WHERE' + CHAR(10) +
        '  [PARENT_BATCH_ID] = ' + CONVERT(NVARCHAR(10), @ParentBatchId) + CHAR(10) +
        '  AND [BATCH_ID] = ' + CONVERT(NVARCHAR(10), @BatchId);

      SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, 'Metadata Review', @LogMessage, @MessageLog);

      COMMIT TRANSACTION;
      GOTO EndOfProcedureSuccess;
    END TRY
    BEGIN CATCH
      IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
      SET @SuccessIndicator = 'N';
      SET @LogMessage = 'Unknown Processing Error';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Process Output', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1
      ELSE GOTO EndOfProcedureFailure;
    END CATCH

/* ----- Start of end state management -------------------------------------- */

    EndOfProcedureFailure:

      SET @SuccessIndicator = 'N';
      SET @LogMessage = N'Batch to Parent Batch registration process encountered errors.';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
      SET @ReturnCode = -1;

      GOTO EndOfProcedure;

    EndOfProcedureSuccess:

      SET @SuccessIndicator = 'Y';
      SET @LogMessage = N'Batch to Parent Batch registration process completed successfully.';
      SET @MessageLog = [omd].[AddLogMessage]('SUCCESS', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
      SET @ReturnCode = 0;

      GOTO EndOfProcedure;

    EndOfProcedure:

      DECLARE @EndTimestamp DATETIME2 = SYSUTCDATETIME();
      DECLARE @EndTimestampString NVARCHAR(4000) = [omd_metadata].[GetTimestampString](@EndTimestamp);
      DECLARE @DurationSeconds NVARCHAR(10) = CONVERT(NVARCHAR(10), COALESCE(DATEDIFF(SECOND, @StartTimestamp, @EndTimestamp), 0));

      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'End Timestamp', @EndTimestampString, @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Elapsed Time (s)', @DurationSeconds, @MessageLog);
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @SuccessIndicator', @SuccessIndicator, @MessageLog);

      IF @Debug = 'Y'
      BEGIN
        EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;
      END;
      RETURN @ReturnCode;

  END TRY

/* ----- Common, standardized, Procedure-wrapping error handling ------------ */

  BEGIN CATCH
    -- reset all return/output values except the message log
    SET @SuccessIndicator = 'N';
    SET @ReturnCode = -2;

    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT,
      N'Parameter @SuccessIndicator Exit Value', @SuccessIndicator, @MessageLog);

    DECLARE
      @ErrorMessage     NVARCHAR(4000),
      @ErrorSeverity    NVARCHAR(10),
      @ErrorState       NVARCHAR(10),
      @ErrorProcedure   NVARCHAR(128),
      @ErrorNumber      NVARCHAR(10),
      @ErrorLine        NVARCHAR(10);

    SELECT
      @ErrorMessage   = COALESCE(ERROR_MESSAGE(), 'No Message'),
      @ErrorSeverity  = COALESCE(CONVERT(NVARCHAR(10), ERROR_SEVERITY()),  'N/A'),
      @ErrorState     = COALESCE(CONVERT(NVARCHAR(10), ERROR_STATE()),     'N/A'),
      @ErrorProcedure = ERROR_PROCEDURE(),
      @ErrorLine      = COALESCE(CONVERT(NVARCHAR(10), ERROR_LINE()),       'N/A'),
      @ErrorNumber    = COALESCE(CONVERT(NVARCHAR(10), ERROR_NUMBER()),     'N/A');

    IF @Debug = 'Y'
    BEGIN
      PRINT 'Error in:         ' + @SpName;
      PRINT 'Error Message:    ' + @ErrorMessage;
      PRINT 'Error Severity:   ' + @ErrorSeverity;
      PRINT 'Error State:      ' + @ErrorState;
      PRINT 'Error Procedure:  ' + @ErrorProcedure;
      PRINT 'Error Line:       ' + @ErrorLine;
      PRINT 'Error Number:     ' + @ErrorNumber;
      PRINT 'SuccessIndicator: ' + @SuccessIndicator;

      -- Spool full message log
      EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;
    END;

    SET @EventTypeCode = N'2';
    DECLARE @ErrorProcedureString NVARCHAR(260);
    IF @ErrorProcedure IS NOT NULL AND TRIM(@ErrorProcedure) <> ''
      SET @ErrorProcedureString = CONCAT(
      ', called from procedure: ''', @ErrorProcedure, '''');

    SET @EventDetail = CONCAT(
      'Error in procedure: ''', @SpName,''', at line: ''',
      CONVERT(NVARCHAR(10), @ErrorLine), '''',
      @ErrorProcedureString, ', error message:', CHAR(10),
      @ErrorMessage
    );
    SET @EventReturnCode = ERROR_NUMBER();

    EXEC [omd].[InsertIntoEventLog]
       @EventTypeCode     = @EventTypeCode
      ,@EventDetail       = @EventDetail
      ,@EventReturnCode   = @EventReturnCode;

    SET @MessageLog = [omd].[AddLogMessage]
      ('CRITICAL', DEFAULT, N'Error Details', @EventDetail, @MessageLog);

    IF @ThrowOnFailure = 'Y' THROW 50000, @EventDetail, 1;

    RETURN @ReturnCode;

  END CATCH
END;
