/*******************************************************************************
 * [omd].[RegisterModule]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Creates (registers) a new Module by name (Module Code)
 *   Updates any existing Module if the checksums are different.
 *
 * Inputs:
 *   - Module Code
 *   - Module Area Code
 *   - Executable
 *   - Module Description
 *   - Module Type
 *   - Module Source DataObject
 *   - Module Target DataObject
 *   - Module Frequency
 *   - Module Active Indicator
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Module Id (for the created module)
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

DECLARE @ModuleId INT

EXEC [omd].[RegisterModule]
  @ModuleCode = 'MyNewModule',
  @ModuleAreaCode = 'Maintenance',
  @Executable = 'SELECT SYSUTCDATETIME()',
  -- Optional parameters
  @ModuleDescription = 'Data logistics Example',
  @Debug = 'Y',
  -- Output parameters
  @ModuleId = @ModuleId OUTPUT;

PRINT 'The new Modules Id is: ''' + CONVERT(NVARCHAR(10), @ModuleId) + '''.';

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[RegisterModule]
(
  -- Mandatory parameters
  @ModuleCode               NVARCHAR(1000),
  @ModuleAreaCode           NVARCHAR(100),
  -- Optional parameters
  @ModuleType               NVARCHAR(1000)  = N'SQL',
  @Executable               VARCHAR(MAX)    = N'',
  @ModuleDescription        NVARCHAR(4000)  = N'',
  @ModuleSourceDataObject   NVARCHAR(1000)  = N'N/A',
  @ModuleTargetDataObject   NVARCHAR(1000)  = N'N/A',
  @ModuleFrequency          NVARCHAR(100)   = N'On-demand',
  @ModuleActiveIndicator    CHAR(1)         = 'Y',
  @Debug                    CHAR(1)         = 'N',
  -- Output parameters
  @ModuleId                 INT             = NULL  OUTPUT,
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
  SET @LogMessage = @ModuleCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleCode', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleAreaCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleAreaCode', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleType
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleType', @LogMessage, @MessageLog)
  SET @LogMessage = @Executable
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @Executable', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleDescription
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleDescription', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleSourceDataObject
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleSourceDataObject', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleTargetDataObject
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleTargetDataObject', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleFrequency
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleFrequency', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleActiveIndicator
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleActiveIndicator', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail NVARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  INSERT INTO [omd].[MODULE]
  (
    [MODULE_CODE],
    [MODULE_TYPE],
    [DATA_OBJECT_SOURCE],
    [DATA_OBJECT_TARGET],
    [AREA_CODE],
    [FREQUENCY_CODE],
    [ACTIVE_INDICATOR],
    [MODULE_DESCRIPTION],
    [EXECUTABLE]
  )
  SELECT *
  FROM
  (
    VALUES
    (
      @ModuleCode,
      @ModuleType,
      @ModuleSourceDataObject,
      @ModuleTargetDataObject,
      @ModuleAreaCode,
      @ModuleFrequency,
      @ModuleActiveIndicator,
      @ModuleDescription,
      @Executable
    )
  ) AS refData
  (
    [MODULE_CODE],
    [MODULE_TYPE],
    [DATA_OBJECT_SOURCE],
    [DATA_OBJECT_TARGET],
    [AREA_CODE],
    [FREQUENCY_CODE],
    [ACTIVE_INDICATOR],
    [MODULE_DESCRIPTION],
    [EXECUTABLE]
  )
  WHERE NOT EXISTS
  (
    SELECT NULL
    FROM [omd].[MODULE] m
    WHERE m.MODULE_CODE = refData.MODULE_CODE
  );

  SET @ModuleId = SCOPE_IDENTITY();

  -- The module can be created, because it does not exist yet.
  IF @ModuleId IS NOT NULL
  BEGIN
    SET @LogMessage = 'A new Module Id ''' + CONVERT(NVARCHAR(10), @ModuleId) + ''' has been created for Module Code ''' + @ModuleCode + '''.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
  END
  ELSE
  BEGIN
    -- Get the existing Module's Id
    SELECT @ModuleId = [MODULE_ID] FROM [omd].[MODULE] WHERE [MODULE_CODE] = @ModuleCode;

    SET @LogMessage = 'The Module ''' + @ModuleCode + ''' already exists in [omd].[MODULE] with Module Id ''' + CONVERT(NVARCHAR(10), @ModuleId) + '''.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
    SET @LogMessage = 'SELECT * FROM [omd].[MODULE] where [MODULE_CODE] = ''' + @ModuleCode + '''.'
    SET @MessageLog = [omd].[AddLogMessage]('WARNING', DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Evaluate the incoming values to see if the Module should be updated.
    -- Note that the active indicator is excluded here,
    -- to allow it to be managed separately.
    DECLARE @NewChecksum BINARY(20) =
    HASHBYTES('SHA1',
      @ModuleType             + '!' +
      @ModuleSourceDataObject + '!' +
      @ModuleTargetDataObject + '!' +
      @ModuleAreaCode         + '!' +
      @ModuleFrequency        + '!' +
      @ModuleDescription      + '!' +
      @Executable
    );

    SET @LogMessage = 'The incoming attribute checksum is ''' + CONVERT(VARCHAR(40), @NewChecksum, 2) + '''.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Evaluate the existing values to see if the Module requires to be updated.
    DECLARE @ExistingChecksum BINARY(20);
    SELECT @ExistingChecksum =
    HASHBYTES('SHA1',
      COALESCE([MODULE_TYPE],         'N/A') + '!' +
      COALESCE([DATA_OBJECT_SOURCE],  'N/A') + '!' +
      COALESCE([DATA_OBJECT_TARGET],  'N/A') + '!' +
      COALESCE([AREA_CODE],           'N/A') + '!' +
      COALESCE([FREQUENCY_CODE],      'N/A') + '!' +
      COALESCE([MODULE_DESCRIPTION],  'N/A') + '!' +
      COALESCE([EXECUTABLE],          'N/A'))
    FROM [omd].[MODULE] WHERE [MODULE_CODE] = @ModuleCode;

    SET @LogMessage = 'The existing attribute checksum is ''' + CONVERT(VARCHAR(40), @ExistingChecksum, 2) + '''.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Update the existing Module with new values, if they are different.
    IF @NewChecksum <> @ExistingChecksum
    BEGIN

      SET @LogMessage = CONCAT('The checksums are different, and Module ''',@ModuleCode, ''' with Module Id ''' + CONVERT(NVARCHAR(10), @ModuleId)+ ''' will be updated.')
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

      UPDATE [omd].[MODULE]
      SET
        [MODULE_DESCRIPTION]    = @ModuleDescription,
        [MODULE_TYPE]           = @ModuleType,
        [DATA_OBJECT_SOURCE]    = @ModuleSourceDataObject,
        [DATA_OBJECT_TARGET]    = @ModuleTargetDataObject,
        [AREA_CODE]             = @ModuleAreaCode,
        [FREQUENCY_CODE]        = @ModuleFrequency,
        [EXECUTABLE]            = @Executable
      WHERE [MODULE_ID] = @ModuleId;

      SET @LogMessage = CONCAT('The Module ''', @ModuleCode, ''' has been updated with the new attribute values.')
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    END

    SET @SuccessIndicator = 'Y'
  END

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
