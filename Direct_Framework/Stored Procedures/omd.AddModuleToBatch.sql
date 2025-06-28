/*******************************************************************************
 * [omd].[AddModuleToBatch]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Assigns a Module to be associated with a Batch.
 *   Both the Batch and Module must already exist.
 *
 * Inputs:
 *   - Module Code
 *   - Batch Code
 *   - Sequence
 *   - Active Indicator (Y/N defaults to Y)
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

DECLARE @BatchId INT

EXEC [omd].[AddModuleToBatch]
  -- Mandatory parameters
  @ModuleCode = 'MyNewModule'
  ,@BatchCode = 'MyNewBatch'
  -- Optional parameters
  ,@ActiveIndicator = 'Y'
  ,@Debug = 'Y'

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[AddModuleToBatch]
(
  -- Mandatory parameters
  @ModuleCode         NVARCHAR(1000),
  @BatchCode          NVARCHAR(1000),
  -- Optional parameters
  @Sequence           INT           = 0,
  @ActiveIndicator    CHAR(1)       = 'Y',
  @Debug              CHAR(1)       = 'N',
  -- Output parameters
  @SuccessIndicator   CHAR(1)       = 'N' OUTPUT,
  @MessageLog         NVARCHAR(MAX) = N'' OUTPUT
)
AS
BEGIN TRY
  SET NOCOUNT ON;

  -- Default output logging
  DECLARE @SpName NVARCHAR(100) = N'[' + OBJECT_SCHEMA_NAME(@@PROCID) + '].[' + OBJECT_NAME(@@PROCID) + ']';
  DECLARE @DirectVersion NVARCHAR(10) = [omd_metadata].[GetFrameworkVersion]();
  DECLARE @StartTimestamp DATETIME2 = SYSUTCDATETIME();
  DECLARE @StartTimestampString NVARCHAR(20) = FORMAT(@StartTimestamp, 'yyyy-MM-dd HH:mm:ss.fffffff');
  DECLARE @EndTimestamp DATETIME2 = NULL;
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
  SET @LogMessage = @ModuleCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleCode', @LogMessage, @MessageLog)
  SET @LogMessage = @BatchCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchCode', @LogMessage, @MessageLog)
  SET @LogMessage = CONVERT(NVARCHAR(10), @Sequence);
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @Sequence', @LogMessage, @MessageLog)
  SET @LogMessage = @ActiveIndicator;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ActiveIndicator', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail NVARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  -- Local procedure variables
  DECLARE @ModuleId INT;
  DECLARE @BatchId INT;

  -- Find the Module Id
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
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)
    SET @SuccessIndicator = 'N';
    THROW 50000, @LogMessage ,1
  END CATCH

  /*
    Batch - Module Registration.
  */

  BEGIN TRY

    IF EXISTS (SELECT 1 FROM [omd].[BATCH_MODULE] WHERE [BATCH_ID] = @BatchId AND [MODULE_ID] = @ModuleId)
    BEGIN
      SET @LogMessage = 'The Module ''' + @ModuleCode + ''' (' + CONVERT(NVARCHAR(10), @ModuleId) + ') is already associated with Batch ''' + @BatchCode + ''' (' + CONVERT(NVARCHAR(10), @BatchId) + '). No update to the existing record will be done.';
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)
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

  EndOfProcedureFailure:

    SET @SuccessIndicator = 'N';
    SET @LogMessage = N'Batch/Module addition process encountered errors.'
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

    GOTO EndOfProcedure

  EndOfProcedureSuccess:

    SET @SuccessIndicator = 'Y';
    SET @LogMessage = N'Batch/Module addition process completed successfully.';
    SET @MessageLog = [omd].[AddLogMessage]('SUCCESS', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

    GOTO EndOfProcedure

/*******************************************************************************
 * EndOfProcedure Label
 ******************************************************************************/

  EndOfProcedure:

  SET @EndTimestamp = SYSUTCDATETIME();
  SET @EndTimestampString = FORMAT(@EndTimestamp, 'yyyy-MM-dd HH:mm:ss.fffffff');
  SET @LogMessage = @EndTimestampString;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'End Timestamp', @LogMessage, @MessageLog)
  SET @LogMessage = DATEDIFF(SECOND, @StartTimestamp, @EndTimestamp);
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Elapsed Time (seconds)', @LogMessage, @MessageLog)

  IF @Debug = 'Y'
  BEGIN
    EXEC [omd].[PrintMessageLog] @MessageLog;
  END

END TRY
BEGIN CATCH

/*******************************************************************************
 * SP-wide error handler and logging
 ******************************************************************************/

  SET @SuccessIndicator = 'N'

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
    PRINT 'Error in: '''      + @SpName + ''''
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

  EXEC [omd].[AddMessageLogToEventLog] @MessageLog;

  EXEC [omd].[InsertIntoEventLog]
    @EventDetail       = @EventDetail,
    @EventReturnCode   = @EventReturnCode;

  THROW
END CATCH
