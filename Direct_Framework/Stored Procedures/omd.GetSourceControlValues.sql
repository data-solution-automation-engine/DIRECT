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
  -- Alternative key parameters, one of these are required
   @ModuleInstanceId    BIGINT          = NULL
  ,@ModuleId            INT             = NULL
  ,@ModuleCode          NVARCHAR(1000)  = NULL
  -- Optional parameters
  ,@Debug               CHAR(1)         = 'N'
  -- Output parameters
  ,@SourceControlId     BIGINT          OUTPUT
  ,@StartValue          NVARCHAR(100)   OUTPUT
  ,@EndValue            NVARCHAR(100)   OUTPUT
  ,@SuccessIndicator    CHAR(1)         OUTPUT
  ,@MessageLog          NVARCHAR(MAX)   OUTPUT
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

    DECLARE @EventDetail NVARCHAR(4000);
    DECLARE @EventReturnCode NVARCHAR(100);
    DECLARE @AddLogsToEventLog CHAR(1) = [omd_metadata].[GetSettingFlag]('LOG_TO_EVENT_LOG');
    DECLARE @ThrowOnFailure CHAR(1) = [omd_metadata].[GetSettingFlag]('THROW_ON_FAILURE');

    -- Prepare output parameters
    SET @SourceControlId = NULL;
    SET @StartValue = NULL;
    SET @EndValue = NULL;

    -- Validate input parameters
    IF (@ModuleCode IS NULL OR TRIM(@ModuleCode) = '')
      AND (@ModuleInstanceId IS NULL OR @ModuleInstanceId <= 0)
      AND (@ModuleId IS NULL OR @ModuleId <= 0)
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, N'At least one key parameter is required.', @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, 'At least one key parameter is required.', 1;
      ELSE GOTO EndOfProcedureFailure;
    END;

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
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @ModuleInstanceId', @ModuleInstanceId, @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @ModuleId', @ModuleId, @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @ModuleCode', @ModuleCode, @MessageLog);

/*******************************************************************************
* Start of main process
*******************************************************************************/

    IF @ModuleInstanceId IS NOT NULL AND @ModuleInstanceId > 0
    BEGIN
      -- If Module Instance Id is provided, check if that instance
      -- already has a parameter value stored, and return that
      SELECT
        @SourceControlId = SOURCE_CONTROL_ID,
        @StartValue = START_VALUE,
        @EndValue = END_VALUE
      FROM
        [omd].[SOURCE_CONTROL]
      WHERE
        MODULE_INSTANCE_ID = @ModuleInstanceId

      IF @SourceControlId IS NOT NULL
      BEGIN
        SET @LogMessage = 'Found existing source control values for Module Instance Id ' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + '.';
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog);
        GOTO EndOfProcedureSuccess;
      END
    END

    -- If no valid module id is passed try to get the module from the instance id if that is good
    IF (@ModuleId IS NULL OR @ModuleId <= 0) AND @ModuleInstanceId IS NOT NULL AND @ModuleInstanceId > 0
      SET @ModuleId = [omd].[GetModuleIdByModuleInstanceId](@ModuleInstanceId);

    IF @ModuleId IS NOT NULL AND @ModuleId > 0
    BEGIN
    -- get the latest values from SOURCE_CONTROL table using the now identified Module Id
      SELECT TOP 1
        @SourceControlId = SOURCE_CONTROL_ID,
        @StartValue = START_VALUE,
        @EndValue = END_VALUE
      FROM
        [omd].[SOURCE_CONTROL]
      WHERE
        MODULE_ID = @ModuleId
      ORDER BY
        -- id or insert timestamp here?
        SOURCE_CONTROL_ID DESC;

      IF @SourceControlId IS NOT NULL
      BEGIN
        SET @LogMessage = 'Found existing source control values for Module Id ' + CONVERT(NVARCHAR(20), @ModuleId) + '.';
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog);
        GOTO EndOfProcedureSuccess;
      END
    END

    -- If Module Id did not work, use the Module Code
    SET @ModuleId = [omd].[GetModuleIdByName](@ModuleCode);
    IF @ModuleId IS NOT NULL AND @ModuleId > 0
    BEGIN
      -- get the latest values from SOURCE_CONTROL table using the now identified Module Id
      SELECT TOP 1
        @SourceControlId = SOURCE_CONTROL_ID,
        @StartValue = START_VALUE,
        @EndValue = END_VALUE
      FROM
        [omd].[SOURCE_CONTROL]
      WHERE
        MODULE_ID = @ModuleId
      ORDER BY
        -- id or insert timestamp here?
        SOURCE_CONTROL_ID DESC;

      IF @SourceControlId IS NOT NULL
      BEGIN
        SET @LogMessage = 'Found existing source control values for Module Code ' + @ModuleCode + '.';
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog);
        GOTO EndOfProcedureSuccess;
      END
    -- Nothing found, log an error and exit
    END

    SET @LogMessage = 'No existing source control values found for Module Code ' + @ModuleCode + '.';
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, N'Status Update', @LogMessage, @MessageLog);
    GOTO EndOfProcedureFailure;

/*******************************************************************************
* Start of end state management
*******************************************************************************/

    EndOfProcedureFailure:
      SET @SourceControlId = NULL;
      SET @StartValue = NULL;
      SET @EndValue = NULL;

      SET @SuccessIndicator = 'N';
      SET @LogMessage = N'Get Source Control Values process encountered errors.';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);

      GOTO EndOfProcedure;

    EndOfProcedureSuccess:

      SET @SuccessIndicator = 'Y';
      SET @LogMessage = N'Get Source Control Values process completed successfully.';
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, DEFAULT, @LogMessage, @MessageLog);

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

  END TRY
/*******************************************************************************
* Common, standardized, Procedure-wrapping error handling
*******************************************************************************/
  BEGIN CATCH
    SET @SourceControlId = NULL;
    SET @StartValue = NULL;
    SET @EndValue = NULL;
    SET @SuccessIndicator = 'N';
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @SuccessIndicator Exit Value', @SuccessIndicator, @MessageLog);

    DECLARE
      @ErrorMessage NVARCHAR(4000),
      @ErrorSeverity INT,
      @ErrorState INT,
      @ErrorProcedure NVARCHAR(128),
      @ErrorNumber INT,
      @ErrorLine INT;

    SELECT
      @ErrorMessage   = COALESCE(ERROR_MESSAGE(),     'No Message'    ),
      @ErrorSeverity  = COALESCE(ERROR_SEVERITY(),    -1              ),
      @ErrorState     = COALESCE(ERROR_STATE(),       -1              ),
      @ErrorProcedure = COALESCE(ERROR_PROCEDURE(),   'No Procedure'  ),
      @ErrorLine      = COALESCE(ERROR_LINE(),        -1              ),
      @ErrorNumber    = COALESCE(ERROR_NUMBER(),      -1              );

    IF @Debug = 'Y'
    BEGIN
      PRINT 'Error in:         ' + @SpName;
      PRINT 'Error Message:    ' + @ErrorMessage;
      PRINT 'Error Severity:   ' + CONVERT(NVARCHAR(10), @ErrorSeverity);
      PRINT 'Error State:      ' + CONVERT(NVARCHAR(10), @ErrorState);
      PRINT 'Error Procedure:  ' + @ErrorProcedure;
      PRINT 'Error Line:       ' + CONVERT(NVARCHAR(10), @ErrorLine);
      PRINT 'Error Number:     ' + CONVERT(NVARCHAR(10), @ErrorNumber);
      PRINT 'SuccessIndicator: ' + @SuccessIndicator;

      -- Spool full message log
      EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;
    END;

    SET @EventDetail =
      CONCAT('Error in ''', @SpName,
      ''' from ''', @ErrorProcedure, ''' at line ''',
      CONVERT(NVARCHAR(10), COALESCE(@ErrorLine,'N/A')), ''': ', CHAR(10),
      COALESCE(@ErrorMessage,'N/A'));
    SET @EventReturnCode = ERROR_NUMBER();

    EXEC [omd].[InsertIntoEventLog]
      @EventDetail       = @EventDetail,
      @EventReturnCode   = @EventReturnCode;

    SET @MessageLog = [omd].[AddLogMessage]
      ('CRITICAL', DEFAULT, N'Error Details', @EventDetail, @MessageLog);

    IF @ThrowOnFailure = 'Y' THROW 50000, @EventDetail, 1;

  END CATCH
END;
