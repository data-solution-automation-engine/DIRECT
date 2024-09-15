/*******************************************************************************
 * [omd].[CreateLoadWindow]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 *
 * Purpose:
 *   Create a Load Window for a Module Instance.
 *
 * Inputs:
 *   - Module Instance Id, the currently involved Module Instance Id
 *   - Load Window Attribute Name, the name of the attribute used to determine the load window
 *   - Module Instance Id Column Name
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Start Value, can be datetime or identifier, datetime, whatever.
 *   - End Value
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

DECLARE
  @StartValue NVARCHAR(MAX),
  @EndValue NVARCHAR(MAX)

EXEC [omd].[CreateLoadWindow]
  @ModuleInstanceId = <ModuleInstanceId>,
  @Debug = N'Y',
  @StartValue = @StartValue OUTPUT,
  @EndValue = @EndValue OUTPUT

SELECT
  @StartValue as N'@StartValue',
  @EndValue as N'@EndValue'

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[CreateLoadWindow]
(
  -- Mandatory parameters
  @ModuleInstanceId             BIGINT,
  -- Optional parameters
  @LoadWindowAttributeName      NVARCHAR(1000) = 'INSCRIPTION_TIMESTAMP',
  @ModuleInstanceIdColumnName   NVARCHAR(1000) = 'MODULE_INSTANCE_ID',
  @Debug                        CHAR(1) = 'N',
  -- Output parameters
  @StartValue                   NVARCHAR(MAX) = NULL OUTPUT,
  @EndValue                     NVARCHAR(MAX) = NULL OUTPUT,
  @SuccessIndicator             CHAR(1)       = 'N' OUTPUT,
  @MessageLog                   NVARCHAR(MAX) = N'' OUTPUT
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
  SET @LogMessage = @LoadWindowAttributeName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @LoadWindowAttributeName', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleInstanceIdColumnName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleInstanceIdColumnName', @LogMessage, @MessageLog)

    -- Process variables
  DECLARE @EventDetail NVARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  SET @LogMessage = 'Start of the Create Load Window process (' + @SpName +').'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  -- Local variables (Module Id and source Data Object)
  DECLARE @ModuleId BIGINT = [omd].[GetModuleIdByModuleInstanceId](@ModuleInstanceId);

  -- Exception handling - The Module Id cannot be NULL
  IF @ModuleId IS NULL
  BEGIN
    SET @EventDetail = 'The Module Id was not found for Module Instance Id ''' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + '''';
    EXEC [omd].[InsertIntoEventLog] @EventDetail = @EventDetail;

    THROW 50000, @EventDetail, 1;
  END

  -- Figure out what the source is.
  DECLARE @SourceDataObject NVARCHAR(1000);
  SELECT @SourceDataObject = DATA_OBJECT_SOURCE FROM omd.MODULE WHERE MODULE_ID = @ModuleId;

  SET @LogMessage = 'For Module Instance Id ' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + ' the following Module Id was found in omd.MODULE: ' + CONVERT(NVARCHAR(10), @ModuleId) + '.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
  SET @LogMessage = 'For Module Id ' + CONVERT(NVARCHAR(10), @ModuleId) + ' the Source Data Object is ' + @SourceDataObject + '.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  -- Exception handling
  IF @ModuleId = NULL OR @ModuleId = 0
  BEGIN;
    THROW 50000, 'The Module Id could not be retrieved based on the Module Instance Id.', 1
  END

  -- Parse the start value as input, or revert to default.
  DECLARE @StartValueSql NVARCHAR(MAX);

  BEGIN
    IF @StartValue IS NOT NULL
    BEGIN

      SET @LogMessage =  'A load window start value was provided: ' + CONVERT(NVARCHAR(1000), @StartValue)
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)


      SET @StartValueSql = '''' + CONVERT(NVARCHAR(1000), @StartValue) + '''';
    END
  ELSE
    BEGIN
      SET @StartValueSql =
'SELECT
  MAX(END_VALUE) AS NEW_START_VALUE
FROM
(
  SELECT
   ROW_NUMBER() OVER (PARTITION BY A.MODULE_ID ORDER BY INSERT_TIMESTAMP DESC) AS RN
  ,END_VALUE
  FROM omd.SOURCE_CONTROL A
  JOIN omd.MODULE_INSTANCE B ON (A.MODULE_INSTANCE_ID = B.MODULE_INSTANCE_ID)
  WHERE B.MODULE_ID = ' + CONVERT(NVARCHAR(10), @ModuleId) + '
  -- Default value
  UNION
  SELECT 1,''1900-01-01''
) sub
WHERE RN=1';

      SET @LogMessage =  'No load window start value was provided, so the most recent value will be retrieved from the source control table for the source data object.'
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
      SET @LogMessage =  'The following code will be used to determine the start value: ' + CHAR(10) + @StartValueSql
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    END
  END

  -- Parse the end value as input, or revert to default.
  DECLARE @EndValueSql NVARCHAR(MAX);
  BEGIN
    IF @EndValue IS NOT NULL
    BEGIN

      SET @LogMessage =  'A load window end value was provided: ' + CONVERT(NVARCHAR(100), @EndValue)
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

      SET @EndValueSql = '''' + CONVERT(NVARCHAR(100), @EndValue) + '''';
    END
    ELSE
    BEGIN
      SET @EndValueSql =
'SELECT COALESCE(MAX(' + @LoadWindowAttributeName + '),''1900-01-01'') AS END_VALUE
FROM ' + @SourceDataObject + ' sdo
JOIN omd.MODULE_INSTANCE modinst ON sdo.' + @ModuleInstanceIdColumnName + ' = modinst.MODULE_INSTANCE_ID
WHERE modinst.EXECUTION_STATUS_CODE = ''Succeeded''';


      SET @LogMessage =  'No load window end value was provided, so the maximum date will be retrieved directly from the source data object.'
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
      SET @LogMessage =  'The following code will be used to determine the end value: ' + CHAR(10) + @EndValueSql
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    END
  END

  DECLARE @SqlStatement NVARCHAR(MAX);
  SET @SqlStatement = N'
      INSERT INTO omd.[SOURCE_CONTROL]
      (
       [MODULE_ID]
      ,[MODULE_INSTANCE_ID]
      ,[INSERT_TIMESTAMP]
      ,[START_VALUE]
      ,[END_VALUE]
      )
      VALUES
      (
       ' + CONVERT(NVARCHAR(10), @ModuleId) + '
      ,' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + '
      ,SYSUTCDATETIME()
      ,(
         '+@StartValueSql+'
       ) -- Interval Start Value
       , (
         '+@EndValueSql+'
       ) -- Interval End Value
      )'

  SET @LogMessage =  'Load Window SQL statement is: ' + @SqlStatement
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  EXEC (@SqlStatement);

  -- Retrieve values for return.
  SELECT @StartValue = [omd].[GetModuleLoadWindowValue](@ModuleId, 1);
  SELECT @EndValue = [omd].[GetModuleLoadWindowValue](@ModuleId, 2);

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
    @EventReturnCode   = @EventReturnCode,
    @ModuleInstanceId  = @ModuleInstanceId;

  THROW
END CATCH
