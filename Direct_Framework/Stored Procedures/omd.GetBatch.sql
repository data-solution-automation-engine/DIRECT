/*******************************************************************************
 * [omd].[GetBatch]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Gets attributes for an existing Batch by name (Batch Code)
 *
 * Inputs:
 *   - Batch Code
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs as resultset 0:
 *   - Batch Id
 *   - Batch Code
 *   - Batch Type
 *   - Frequency Code
 *   - Active Indicator
 *   - Batch Description
 *
 * Output variables:
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

EXEC [omd].[GetBatch]
  @BatchCode = 'MyExistingBatch'

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[GetBatch]
(
  -- Mandatory parameters
  @BatchCode                NVARCHAR(1000),
  -- Optional parameters
  @Debug                    CHAR(1)         = 'N',
  -- Output parameters
  @BatchDetails             NVARCHAR(MAX)   = NULL  OUTPUT,
  @SuccessIndicator         CHAR(1)         = 'N'   OUTPUT,
  @MessageLog               NVARCHAR(MAX)   = NULL  OUTPUT
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
  SET @LogMessage = @BatchCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchCode', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail NVARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  DECLARE @Results TABLE (
    [BATCH_ID]            INT                         NULL,
    [BATCH_CODE]          NVARCHAR (1000)             NULL,
    [BATCH_TYPE]          NVARCHAR (100)              NULL,
    [FREQUENCY_CODE]      NVARCHAR (100)              NULL,
    [ACTIVE_INDICATOR]    CHAR (1)                    NULL,
    [BATCH_DESCRIPTION]   NVARCHAR (4000)             NULL
  )

  INSERT INTO @Results
    SELECT
    [BATCH_ID],
    [BATCH_CODE],
    [BATCH_TYPE],
    [FREQUENCY_CODE],
    [ACTIVE_INDICATOR],
    [BATCH_DESCRIPTION]
  FROM
    [omd].[BATCH]
  WHERE
    [BATCH_CODE] = @BatchCode;

  IF EXISTS (SELECT 1 FROM @Results)
  BEGIN
      SET @SuccessIndicator = 'Y';
      SET @LogMessage = 'Batch with Code ''' + @BatchCode + ''' was found.'
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Batch Found', @LogMessage, @MessageLog)

  END
  ELSE
  BEGIN
      SET @SuccessIndicator = 'N';
    SET @LogMessage = 'No Batch with Code ''' + @BatchCode + ''' was found.'
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, N'Error Message', @LogMessage, @MessageLog)
  END

/*******************************************************************************
 * Return Resultset
 ******************************************************************************/

  SELECT *
  FROM @Results;

/*******************************************************************************
 * EndOfProcedure Label
 ******************************************************************************/

  EndOfProcedure:

  SET @EndTimestamp = SYSUTCDATETIME();
  SET @EndTimestampString = FORMAT(@EndTimestamp, 'yyyy-MM-dd HH:mm:ss.fffffff');
  SET @LogMessage = @EndTimestampString;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'End Timestamp', @LogMessage, @MessageLog)
  SET @LogMessage = DATEDIFF(SECOND, @StartTimestamp, @EndTimestamp);
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Elapsed Time (s)', @LogMessage, @MessageLog)

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
