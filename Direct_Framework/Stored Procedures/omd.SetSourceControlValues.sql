/**
 * @procedure [omd].[SetSourceControlValues]
 * @description
 *   Set a Source Control value (Load Window parameter set) for a Module Instance.
 *   The Source Control table can store a start and end value (or only start), and is agnostic to data type and usage.
 *   It can be used for load windows, data quality checks, or any other parameterization.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {BIGINT}        @ModuleInstanceId [in]  (required)
 *   The Module Instance Id to associate with the Source Control entry.
 * @param {NVARCHAR(100)} @StartValue       [in]  (required)
 *   Start value of the parameter window.
 * @param {NVARCHAR(100)} @EndValue         [in]  (optional)
 *   End value of the parameter window.
 * @param {CHAR(1)}       @Debug            [in]  (optional, default='N')
 *   Enables debug logging.
 * @param {BIGINT}        @SourceControlId  [out] (optional)
 *   The identifier of the created Source Control record.
 * @param {CHAR(1)}       @SuccessIndicator [out] (optional)
 *   'Y' if the operation completed successfully; otherwise 'N'.
 * @param {NVARCHAR(MAX)} @MessageLog       [out] (optional)
 *   Structured JSON-format log for diagnostics.
 *
 * @returns {INT} Return code: 0 = success, -1 = failure, -2 = unhandled error.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     function [omd].[GetModuleIdByModuleInstanceId]
 *     function [omd_metadata].[GetFrameworkVersion]
 *     function [omd_metadata].[GetTimestampString]
 *     function [omd_metadata].[GetSettingFlag]
 * - writes:
 *     table [omd].[SOURCE_CONTROL]
 *     procedure [omd].[InsertIntoEventLog]
 * - utilities:
 *     function [omd].[AddLogMessage]
 *     procedure [omd].[PrintMessageLog]
 *
 * @example
 * DECLARE @SourceControlId BIGINT,
 *         @SuccessIndicator CHAR(1),
 *         @MessageLog NVARCHAR(MAX);
 * EXEC [omd].[SetSourceControlValues]
 *   @ModuleInstanceId = 123,
 *   @StartValue = N'2025-01-01T00:00:00Z',
 *   @EndValue   = N'2025-01-31T23:59:59Z',
 *   @Debug = 'Y',
 *   @SourceControlId = @SourceControlId OUTPUT,
 *   @SuccessIndicator = @SuccessIndicator OUTPUT,
 *   @MessageLog = @MessageLog OUTPUT;
 * EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;
 */

CREATE PROCEDURE [omd].[SetSourceControlValues]
(
  -- Mandatory parameters
   @ModuleInstanceId    BIGINT          = NULL
  ,@StartValue          NVARCHAR(100)   = NULL
  -- Optional parameters
  ,@EndValue            NVARCHAR(100)   = NULL
  ,@Debug               CHAR(1)         = 'N'
  -- Output parameters
  ,@SourceControlId     BIGINT          = NULL  OUTPUT
  ,@SuccessIndicator    CHAR(1)         = 'N'   OUTPUT
  ,@MessageLog          NVARCHAR(MAX)   = N''   OUTPUT
)
AS
BEGIN
  BEGIN TRY
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Prepare/clean standard process/output parameters
    SET @Debug = CASE WHEN UPPER(@Debug) = 'Y' THEN 'Y' ELSE 'N' END;
    SET @SuccessIndicator = 'N';
    SET @MessageLog = N'[]';

    -- Prepare/clean process/output parameters
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
    DECLARE @SpName NVARCHAR(300) = CONCAT(QUOTENAME(COALESCE(OBJECT_SCHEMA_NAME(@@PROCID),'Unknown')), N'.',
        QUOTENAME(COALESCE(OBJECT_NAME(@@PROCID), 'Unknown')));

    -- Validate input parameters
    IF (@ModuleInstanceId IS NULL OR @ModuleInstanceId <= 0
        OR @StartValue IS NULL OR TRIM(@StartValue) = '')
    BEGIN
      SET @SuccessIndicator = 'N';
      SET @SourceControlId = NULL;
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, N'x1 Missing required parameters.', @MessageLog);
      IF @ThrowOnFailure = 'Y' THROW 50000, 'Missing required parameters.', 1;
      GOTO EndOfProcedureFailure;
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
      IF @AddLogsToEventLog = 'Y' EXEC [omd].[InsertIntoEventLog] @ModuleInstanceId = 0, @EventDetail = @EventDetail;
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter Error', @LogMessage, @MessageLog);
      SET @SuccessIndicator = 'N';
      IF @ThrowOnFailure = 'Y' THROW 50000, @LogMessage, 1;
      ELSE GOTO EndOfProcedureFailure;
    END

    SET @LogMessage = 'For Module Instance Id ' + CONVERT(NVARCHAR(20), @ModuleInstanceId) + ' the following Module Id was found in omd.MODULE: ' + CONVERT(NVARCHAR(10), @ModuleId) + '.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- If the End Value is NULL, set it to the Start Value
    -- TODO - Rethink that
    --IF @EndValue IS NULL OR TRIM(@EndValue) = ''
    --BEGIN
    --  SET @EndValue = @StartValue;
    --  SET @LogMessage = 'The End Value was not provided, so it is set to the Start Value: ' + @StartValue + '.';
    --  SET @MessageLog = [omd].[AddLogMessage]('DEBUG', DEFAULT, N'Status Update', @LogMessage, @MessageLog)
    --END

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
          ,@StartTimestamp
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
    GOTO EndOfProcedureSuccess;

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
      IF @Debug = 'Y' EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;
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
    IF @AddLogsToEventLog = 'Y'
      BEGIN
      SET @EventDetail =
        CONCAT('Error in ''', @SpName,
        ''' from ''', @ErrorProcedure, ''' at line ''',
        CONVERT(NVARCHAR(10), COALESCE(@ErrorLine,'N/A')), ''': ', CHAR(10),
        COALESCE(@ErrorMessage,'N/A'));
      SET @EventReturnCode = ERROR_NUMBER();

      EXEC [omd].[InsertIntoEventLog]
         @ModuleInstanceId  = @ModuleInstanceId
        ,@EventDetail       = @EventDetail
        ,@EventReturnCode   = @EventReturnCode
        ,@Debug             = @Debug

      SET @MessageLog = [omd].[AddLogMessage] ('CRITICAL', DEFAULT, N'Error Details', @EventDetail, @MessageLog);
    END
    IF @ThrowOnFailure = 'Y' THROW 50000, @EventDetail, 1;

    RETURN -2;

  END CATCH
END;
