/*******************************************************************************
 * [omd].[InsertIntoEventLog]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Inserts an event log entry capturing failures or other noteworthy events.
 *
 * Input:
 *   - Batch Instance Id (0 if not set)
 *   - Module Instance Id (0 if not set)
 *   - Event Details
 *   - Event Datetime (defaults to SYSUTCDATETIME() if not set)
 *   - Event Type Code (see omd.EVENT_TYPE table contents for options)
 *   - Error Return Code
 *   - Error Bitmap
 *   - Debug flag Y/N (default to N)
 *
 * Outputs:
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

EXEC [omd].[InsertIntoEventLog]
  @ModuleInstanceId = <123>,
  @EventDetail = '<event or error details>',
  @EventTypeCode = '<2>'

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[InsertIntoEventLog]
(
  -- Mandatory parameters
  @ModuleInstanceId   BIGINT          = 0,
  @EventDetail        NVARCHAR(4000),
  -- Optional parameters
  @BatchInstanceId    BIGINT          = 0,
  @EventTimestamp     DATETIME2       = NULL,
  @EventTypeCode      NVARCHAR(100)   = '2',
  @EventReturnCode    NVARCHAR(1000)  = 'N/A',
  @ErrorBitmap        NUMERIC(20,0)   = 0,
  @Debug              CHAR(1)         = 'N',
  -- Output parameters
  @SuccessIndicator     CHAR(1)         = 'N' OUTPUT,
  @MessageLog           NVARCHAR(MAX)   = N'' OUTPUT
)
AS
BEGIN TRY
  SET NOCOUNT ON;

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
  SET @LogMessage = @EventDetail;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @EventDetail', @LogMessage, @MessageLog)
  SET @LogMessage = @BatchInstanceId
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchInstanceId', @LogMessage, @MessageLog)
  SET @LogMessage = @EventTimestamp
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @EventTimestamp', @LogMessage, @MessageLog)
  SET @LogMessage = @EventTypeCode
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @EventTypeCode', @LogMessage, @MessageLog)
  SET @LogMessage = @EventReturnCode
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @EventReturnCode', @LogMessage, @MessageLog)
  SET @LogMessage = @ErrorBitmap
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ErrorBitmap', @LogMessage, @MessageLog)

  -- Process variables
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  SET @EventTimestamp = COALESCE(@EventTimestamp, SYSUTCDATETIME());

  SET @LogMessage = 'Inserting record in Event Log for Module Instance Id ''' + CONVERT(NVARCHAR(20), COALESCE(@ModuleInstanceId, 0)) + ''''
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
  SET @LogMessage = 'Batch Instance Id ''' + CONVERT(NVARCHAR(20), COALESCE(@BatchInstanceId, 0)) + ''''
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
  SET @LogMessage = 'Message: '+@EventDetail
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  INSERT INTO [omd].[EVENT_LOG]
  (
    [MODULE_INSTANCE_ID],
    [BATCH_INSTANCE_ID],
    [EVENT_TYPE_CODE],
    [EVENT_TIMESTAMP],
    [EVENT_RETURN_CODE],
    [EVENT_DETAIL],
    [ERROR_BITMAP]
  )
  VALUES
  (
    COALESCE(@ModuleInstanceId, 0),
    COALESCE(@BatchInstanceId, 0),
    @EventTypeCode,
    @EventTimestamp,
    @EventReturnCode,
    @EventDetail,
    @ErrorBitmap
  )

  -- End of procedure label
  EndOfProcedure:

  SET @SuccessIndicator = 'Y'

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

  END;

  THROW
END CATCH
