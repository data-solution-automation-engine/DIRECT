/*******************************************************************************
Procedure:      [omd].[SetSourceControlValues]
Documentation:  https://github.com/data-solution-automation-engine/DIRECT
Version:        DIRECT Framework v2.1.0
********************************************************************************

Purpose:
  Set a Source Control value/Load Window parameter value set for a Module Instance.
  The Source Control table can maintain the start and end of the load window, or
  just the start value. The values are data type and usage agnostic, so can be
  used for any purpose, such as a load window, a data quality check

Inputs:
  - Module Instance Id, the currently involved Module Instance Id
  - Start Value
  - End Value
  - Debug Flag (Y/N, defaults to N)

Outputs:
  - Source Control Id for the created Load Window record
  - Success Indicator (Y/N)
  - Message Log

******************************************************************************

Example Usage:

DECLARE
  @SourceControlId BIGINT

EXEC [omd].[SetSourceControlValues]
  @ModuleInstanceId = <ModuleInstanceId>,
  @StartValue = N'<StartValue>',
  @EndValue = N'<EndValue>',
  @Debug = N'Y',
  @SourceControlId = @SourceControlId OUTPUT

SELECT
  @SourceControlId as N'@SourceControlId'

*******************************************************************************/

CREATE PROCEDURE [omd].[SetSourceControlValues]
(
  -- Mandatory parameters
   @ModuleInstanceId    BIGINT
  ,@StartValue          NVARCHAR(100)
  -- Optional parameters
  ,@EndValue            NVARCHAR(100)   = NULL
  ,@Debug               CHAR(1)         = 'N'
  -- Output parameters
  ,@SourceControlId     BIGINT          OUTPUT
  ,@SuccessIndicator    CHAR(1)         OUTPUT
  ,@MessageLog          NVARCHAR(MAX)   OUTPUT
)
AS
BEGIN
  BEGIN TRY
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Prepare/clean standard parameters
    SET @Debug = CASE WHEN UPPER(@Debug) = 'Y' THEN 'Y' ELSE 'N' END;
    SET @SuccessIndicator = 'N';
    SET @MessageLog = N'[]';

    -- Prepare/clean process parameters
    SET @SourceControlId = NULL;

    -- Standard setup and initialization
    DECLARE @ReturnCode INT = 0;
    DECLARE @EventDetail NVARCHAR(4000);
    DECLARE @EventReturnCode NVARCHAR(100);
    DECLARE @AddLogsToEventLog CHAR(1) = [omd_metadata].[GetSettingFlag]('LOG_TO_EVENT_LOG');
    DECLARE @ThrowOnFailure CHAR(1) = [omd_metadata].[GetSettingFlag]('THROW_ON_FAILURE');
    DECLARE @StartTimestamp DATETIME2 = SYSUTCDATETIME();
    DECLARE @StartTimestampString NVARCHAR(4000) = [omd_metadata].[GetTimestampString](@StartTimestamp);
    DECLARE @LogMessage NVARCHAR(MAX);
    DECLARE @SpName NVARCHAR(300) = CONCAT(QUOTENAME(COALESCE(OBJECT_SCHEMA_NAME(@@PROCID),'Unknown')),N'.',QUOTENAME(COALESCE(OBJECT_NAME(@@PROCID), 'Unknown')));

    -- Validate input parameters
    IF (@ModuleInstanceId IS NULL OR @ModuleInstanceId <= 0
        OR @StartValue IS NULL OR TRIM(@StartValue) = '')
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @SourceControlId = NULL;
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, N'Missing required parameter.', @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, 'At least one key parameter is required.', 1;
      ELSE GOTO EndOfProcedureFailure;
    END;

    -- Log standard metadata
    SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Procedure', @SpName, @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Version', [omd_metadata].[GetFrameworkVersion](), @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Start Timestamp', @StartTimestampString, @MessageLog);

    -- Log parameters
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @ModuleInstanceId', @ModuleInstanceId, @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @StartValue', @StartValue, @MessageLog);
    SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, N'Parameter @EndValue', @EndValue, @MessageLog);

/*******************************************************************************
* Start of main process
*******************************************************************************/

    -- Local variables (Module Id and source Data Object)
    DECLARE @ModuleId INT = [omd].[GetModuleIdByModuleInstanceId](@ModuleInstanceId);

    -- Exception handling - The Module Id cannot be NULL or negative
    IF @ModuleId IS NULL OR @ModuleId <= 0
    BEGIN
      SET @LogMessage = 'The Module Id was not found for Module Instance Id ''' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + '''';
      SET @EventDetail = LEFT(@LogMessage, 4000);
      EXEC [omd].[InsertIntoEventLog] @EventDetail = @EventDetail;
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter Error', @LogMessage, @MessageLog);
      SET @SuccessIndicator = 'N';
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      ELSE GOTO EndOfProcedureFailure;
    END

    SET @LogMessage = 'For Module Instance Id ' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + ' the following Module Id was found in omd.MODULE: ' + CONVERT(NVARCHAR(10), @ModuleId) + '.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- If the End Value is NULL, set it to the Start Value
    IF @EndValue IS NULL OR TRIM(@EndValue) = ''
    BEGIN
      SET @EndValue = @StartValue;
      SET @LogMessage = 'The End Value was not provided, so it is set to the Start Value: ' + @StartValue + '.';
      SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Status Update', @LogMessage, @MessageLog)
    END

    BEGIN TRY
      BEGIN TRANSACTION
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
           @ModuleId
          ,@ModuleInstanceId
          ,SYSUTCDATETIME()
          ,@StartValue
          ,@EndValue
        );

        SET @SourceControlId = SCOPE_IDENTITY();
      COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
      IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
      SET @SuccessIndicator = 'N';
      SET @SourceControlId = NULL;
      SET @LogMessage = 'Insert transaction processing error';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Process Output', @LogMessage, @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1
      ELSE GOTO EndOfProcedureFailure;
    END CATCH

    SET @SuccessIndicator = 'Y';
    GOTO EndOfProcedure;

/*******************************************************************************
* Start of end state management
*******************************************************************************/

    EndOfProcedureFailure:
      SET @SuccessIndicator = 'N';

      SET @SourceControlId = NULL;

      SET @LogMessage = N'Set Source Control Values process encountered errors.';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
      SET @ReturnCode = -1;

      GOTO EndOfProcedure;

    EndOfProcedureSuccess:

      SET @SuccessIndicator = 'Y';
      SET @LogMessage = N'Set Source Control Values process completed successfully.';
      SET @MessageLog = [omd].[AddLogMessage]('INFO', DEFAULT, DEFAULT, @LogMessage, @MessageLog);
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
/*******************************************************************************
* Common, standardized, Procedure-wrapping error handling
*******************************************************************************/
  BEGIN CATCH
    -- Reset output parameters
    SET @SuccessIndicator = 'N'

    SET @SourceControlId = NULL;

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

    SET @MessageLog = [omd].[AddLogMessage] ('CRITICAL', DEFAULT, N'Error Details', @EventDetail, @MessageLog);

    IF @ThrowOnFailure = 'Y' THROW 50000, @EventDetail, 1;

    RETURN -2;

  END CATCH
END;
