/*******************************************************************************
 * [omd].[GetSourceControlValues]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT Framework v2.1.0
 *
 * Purpose:
 *   Get a Load Window parameter value for source control.
 *
 * Inputs:
 *   - Module Instance Id, the currently involved Module Instance Id
 *   - Load Window Attribute Name,
 *     the name of the attribute used to determine the load window
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Source Control Id
 *   - Start Value
 *   - End Value
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

DECLARE
  @SourceControlId BIGINT,
  @StartValue NVARCHAR(100),
  @EndValue NVARCHAR(100)

EXEC [omd].[SetSourceControlValues]
  @ModuleInstanceId = <ModuleInstanceId>,
  @Debug = N'Y',
  @SourceControlId = @SourceControlId OUTPUT,
  @StartValue = @StartValue OUTPUT,
  @EndValue = @EndValue OUTPUT

SELECT
  @SourceControlId as N'@SourceControlId',
  @StartValue as N'@StartValue',
  @EndValue as N'@EndValue'

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[GetSourceControlValues]
  (
  -- Mandatory parameters
  @ModuleInstanceId   BIGINT
  -- Optional parameters
  ,@Debug             CHAR(1)       = 'N'
  -- Output parameters
  ,@SourceControlId   BIGINT        = NULL OUTPUT
  ,@StartValue        NVARCHAR(100) = NULL OUTPUT
  ,@EndValue          NVARCHAR(100) = NULL OUTPUT
  ,@SuccessIndicator  CHAR(1)       = 'N' OUTPUT
  ,@MessageLog        NVARCHAR(MAX) = N'' OUTPUT
)
AS
BEGIN TRY
  SET NOCOUNT ON;

  -- Default output logging setup
  DECLARE @SpName NVARCHAR(100) = N'[' + OBJECT_SCHEMA_NAME(@@PROCID) + '].[' + OBJECT_NAME(@@PROCID) + ']';
  DECLARE @DirectVersion NVARCHAR(100) = [omd_metadata].[GetFrameworkVersion]();
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
  SET @LogMessage = @ModuleInstanceId;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleInstanceId', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail NVARCHAR(4000) = N'';
  DECLARE @EventReturnCode NVARCHAR(100);

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  SET @LogMessage = 'Start of the Get Source Control Value process (' + @SpName + ').'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  -- Local variables (Module Id and source Data Object)
  DECLARE @ModuleId INT = [omd].[GetModuleIdByModuleInstanceId](@ModuleInstanceId);

  -- Exception handling - The Module Instance Id or Module Id cannot be NULL or 0
  IF @ModuleInstanceId IS NULL OR @ModuleId IS NULL OR @ModuleId = 0
  BEGIN
  SET @LogMessage = 'A valid Module Id was not found for Module Instance Id ''' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + '''';
  SET @EventDetail = LEFT(@LogMessage, 4000);
  EXEC [omd].[InsertIntoEventLog] @EventDetail = @EventDetail;
  SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter Error', @LogMessage, @MessageLog);

  GOTO FailureEndOfProcedure
END

  SET @LogMessage = 'For Module Instance Id ' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + ' the following Module Id was found in omd.MODULE: ' + CONVERT(NVARCHAR(10), @ModuleId) + '.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  -- Get the latest/current source control values
  SELECT
  TOP 1
  @SourceControlId = SOURCE_CONTROL_ID
  ,@StartValue = START_VALUE
  ,@EndValue = END_VALUE
FROM
  [omd].[SOURCE_CONTROL]
WHERE
    MODULE_ID = @ModuleId
ORDER BY
    SOURCE_CONTROL_ID DESC

  SET @SuccessIndicator = 'Y';

  GOTO EndOfProcedure;

  FailureEndOfProcedure:

    SET @SourceControlId = NULL;
    SET @SuccessIndicator = 'N'
    SET @StartValue = NULL;
    SET @EndValue = NULL;

    SET @LogMessage = N'' + @SpName + ' ended in failure.';
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

  GOTO EndOfProcedure;

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
  SET @SourceControlId = NULL;
  SET @SuccessIndicator = 'N'
  SET @StartValue = NULL;
  SET @EndValue = NULL;

  SET @LogMessage = @SuccessIndicator;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @SuccessIndicator', @LogMessage, @MessageLog)

  DECLARE @ErrorMessage NVARCHAR(4000);
  DECLARE @ErrorSeverity INT;
  DECLARE @ErrorState INT;
  DECLARE @ErrorProcedure NVARCHAR(128);
  DECLARE @ErrorNumber INT;
  DECLARE @ErrorLine INT;

  SELECT
  @ErrorMessage   = COALESCE(ERROR_MESSAGE(),     'No Message'    )
  ,@ErrorSeverity  = COALESCE(ERROR_SEVERITY(),    -1              )
  ,@ErrorState     = COALESCE(ERROR_STATE(),       -1              )
  ,@ErrorProcedure = COALESCE(ERROR_PROCEDURE(),   'No Procedure'  )
  ,@ErrorLine      = COALESCE(ERROR_LINE(),        -1              )
  ,@ErrorNumber    = COALESCE(ERROR_NUMBER(),      -1              );

  IF @Debug = 'Y'
  BEGIN
  PRINT 'Error in '''       + @SpName + '''';
  PRINT 'Error Message: '   + @ErrorMessage;
  PRINT 'Error Severity: '  + CONVERT(NVARCHAR(10), @ErrorSeverity);
  PRINT 'Error State: '     + CONVERT(NVARCHAR(10), @ErrorState);
  PRINT 'Error Procedure: ' + @ErrorProcedure;
  PRINT 'Error Line: '      + CONVERT(NVARCHAR(10), @ErrorLine);
  PRINT 'Error Number: '    + CONVERT(NVARCHAR(10), @ErrorNumber);
  PRINT 'SuccessIndicator: '+ @SuccessIndicator;

  -- Spool message log
  EXEC [omd].[PrintMessageLog] @MessageLog;
END

  SET @EventDetail = 'Error in ''' + COALESCE(@SpName,'N/A') + ''' from ''' + COALESCE(@ErrorProcedure,'N/A') + ''' at line ''' + CONVERT(NVARCHAR(10), COALESCE(@ErrorLine,'N/A')) + ''': '+ CHAR(10) + COALESCE(@ErrorMessage,'N/A');
  SET @EventReturnCode = ERROR_NUMBER();

  EXEC [omd].[InsertIntoEventLog]
    @EventDetail       = @EventDetail,
    @EventReturnCode   = @EventReturnCode,
    @ModuleInstanceId  = @ModuleInstanceId;

END CATCH
