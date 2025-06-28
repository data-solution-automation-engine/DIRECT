/*******************************************************************************
 * [omd].[AddBatchToParentBatch]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Assigns a Batch to be associated with a Parent Batch.
 *   Both Batches must already exist.
 *
 * Inputs:
 *   - Batch Code
 *   - Parent Batch Code
 *   - Sequence
 *   - Active Indicator (Y/N defaults to Y)
 *   - Debug Flag (Y/N, defaults to N)
 *   - CheckDag (direction / Directed Acyclic Graph)
 *
 * Outputs:
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

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

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[AddBatchToParentBatch]
  (
  -- Mandatory parameters
  @BatchCode         NVARCHAR(1000),
  @ParentBatchCode   NVARCHAR(1000),
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
BEGIN TRY;
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
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Procedure', @LogMessage, @MessageLog);
  SET @LogMessage = @DirectVersion;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Version',@LogMessage, @MessageLog)
  SET @LogMessage = @StartTimestampString;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Start Timestamp', @LogMessage, @MessageLog)

  -- Log parameters
  SET @LogMessage = @BatchCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchCode', @LogMessage, @MessageLog)
  SET @LogMessage = @ParentBatchCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ParentBatchCode', @LogMessage, @MessageLog)
  SET @LogMessage = CONVERT(NVARCHAR(10), @Sequence);
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @Sequence', @LogMessage, @MessageLog)
  SET @LogMessage = @ActiveIndicator;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ActiveIndicator', @LogMessage, @MessageLog)
  SET @LogMessage = @CheckDag;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @CheckDag', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail NVARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  -- Local procedure variables
  DECLARE @BatchId INT;
  DECLARE @ParentBatchId INT;

  -- Find the Child Batch Id
  BEGIN TRY
    SET @BatchId = [omd].[GetBatchIdByName](@BatchCode)

    IF @BatchId IS NOT NULL
    BEGIN
  SET @LogMessage = 'Batch Id ''' + CONVERT(NVARCHAR(10), @BatchId) + ''' has been retrieved for Batch Code ''' + @BatchCode + '''.';
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)
END
    ELSE
    BEGIN
  SET @LogMessage = 'No Batch Id was found for Batch Code ''' + @BatchCode + '''.';
  SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

  GOTO EndOfProcedureFailure
END
  END TRY
  BEGIN CATCH
    SET @LogMessage = 'Error Processing Batch Code.';
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)
    SET @SuccessIndicator = 'N';

    THROW 50000, @LogMessage ,1
  END CATCH

  -- Validate the DAG
  BEGIN TRY
    -- DAG Check: Ensure that adding @ParentBatchId -> @BatchId does not form a cycle
    IF @CheckDag = 'Y'
    BEGIN
  ;WITH
    Ancestors
    AS
    (
              SELECT BATCH_ID, PARENT_BATCH_ID
        FROM [omd].[BATCH_HIERARCHY]
        WHERE BATCH_ID = @ParentBatchId

      UNION ALL

        SELECT h.BATCH_ID, h.PARENT_BATCH_ID
        FROM [omd].[BATCH_HIERARCHY] h
          INNER JOIN Ancestors a ON h.BATCH_ID = a.PARENT_BATCH_ID
    )
  SELECT BATCH_ID
  INTO #DagViolation
  FROM Ancestors
  WHERE PARENT_BATCH_ID = @BatchId;

  IF EXISTS (SELECT 1
  FROM #DagViolation)
      BEGIN
    SET @LogMessage = 'Circular relationship detected: adding BatchId ' + CONVERT(NVARCHAR(10), @BatchId) +
                          ' under ParentBatchId ' + CONVERT(NVARCHAR(10), @ParentBatchId) +
                          ' would create a cycle.';
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
    DROP TABLE IF EXISTS #DagViolation;
    GOTO EndOfProcedureFailure;
  END

  DROP TABLE IF EXISTS #DagViolation;
END


  END TRY
  BEGIN CATCH
    SET @LogMessage = 'Error testing for circular relationships in the DAG check.';
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
    SET @SuccessIndicator = 'N';

    THROW 50000, @LogMessage, 1
  END CATCH

  -- Find the Parent Batch Id
  BEGIN TRY
    SET @ParentBatchId = [omd].[GetBatchIdByName](@ParentBatchCode)

    IF @ParentBatchId IS NOT NULL
    BEGIN
  SET @LogMessage = 'Batch Id ''' + CONVERT(NVARCHAR(10), @ParentBatchId) + ''' has been retrieved for Parent Batch Code ''' + @ParentBatchCode + '''.';
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

END
    ELSE
    BEGIN
  SET @LogMessage = 'No Batch Id was found for Parent Batch Code ''' + @ParentBatchCode + '''.';
  SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

  GOTO EndOfProcedureFailure
END
  END TRY
  BEGIN CATCH
    SET @LogMessage = 'Error Processing Parent Batch Code.';
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)
    SET @SuccessIndicator = 'N';

    THROW 50000, @LogMessage, 1
  END CATCH

  /*
    Batch - Parent Batch Registration.
  */

  BEGIN TRY

    -- TODO: Consider an update for existing mappings here?

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
    SET @MessageLog = [omd].[AddLogMessage]('SUCCESS', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

    SET @LogMessage =
      'SELECT * FROM [omd].[BATCH_HIERARCHY]' + CHAR(10) +
      'WHERE' + CHAR(10) +
      '  [PARENT_BATCH_ID] = ' + CONVERT(NVARCHAR(10), @ParentBatchId) + CHAR(10) +
      '  AND [BATCH_ID] = ' + CONVERT(NVARCHAR(10), @BatchId);

    SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

    GOTO EndOfProcedureSuccess
  END TRY

  BEGIN CATCH
    SET @SuccessIndicator = 'N';
    SET @LogMessage = 'Unknown Error';
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);

    THROW 50000, @LogMessage ,1
  END CATCH

  EndOfProcedureFailure:

    SET @SuccessIndicator = 'N';
    SET @LogMessage = N'Batch to Parent Batch registration process encountered errors.'
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

    GOTO EndOfProcedure

  EndOfProcedureSuccess:

    SET @SuccessIndicator = 'Y';
    SET @LogMessage = N'Batch to Parent Batch registration process completed succesfully.';
    SET @MessageLog = [omd].[AddLogMessage]('SUCCESS', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

    GOTO EndOfProcedure

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
    @EventReturnCode   = @EventReturnCode;

  THROW
END CATCH
