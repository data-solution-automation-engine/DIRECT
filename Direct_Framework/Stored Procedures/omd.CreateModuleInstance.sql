/**
 * @procedure [omd].[CreateModuleInstance]
 * @description
 *   Creates/registers a new Module Instance (execution/run) for a Module by code,
 *   optionally linked to a Batch Instance, and captures executed code hash.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {NVARCHAR(500)} @ModuleCode                     [in]  (required)
 *   Module Code as defined in [omd].[MODULE].
 * @param {NVARCHAR(MAX)}  @Query                         [in]  (optional, default=NULL)
 *   Executable text for reference and hashing; NULL allowed.
 * @param {BIGINT}         @BatchInstanceId               [in]  (optional, default=0)
 *   Parent Batch Instance Id if invoked from a Batch; 0 for none.
 * @param {NVARCHAR(4000)} @ExecutionContext              [in]  (optional, default='')
 *   Runtime context (e.g., GUID, SPID) for traceability.
 * @param {CHAR(1)}        @Debug                         [in]  (optional, default='N')
 *   Enables debug logging.
 * @param {BIGINT}         @ModuleInstanceId              [out] (optional)
 *   Newly created Module Instance Id.
 * @param {DATETIME2}      @ModuleInstanceStartTimestamp  [out] (optional)
 *   Start timestamp captured at creation.
 * @param {CHAR(1)}        @SuccessIndicator              [out] (optional)
 *   'Y' if creation succeeded, otherwise 'N'.
 * @param {NVARCHAR(MAX)}  @MessageLog                    [out] (optional)
 *   Structured JSON-format log for diagnostics.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     function [omd].[GetModuleIdByName]
 *     function [omd_metadata].[GetFrameworkVersion]
 * - writes:
 *     table [omd].[MODULE_INSTANCE]
 *     table [omd].[MODULE_INSTANCE_EXECUTED_CODE]
 *     procedure [omd].[InsertIntoEventLog]
 *
 * @example
 *
DECLARE @ModuleInstanceId BIGINT,
        @ModuleInstanceStartTimestamp DATETIME2,
        @SuccessIndicator CHAR(1),
        @MessageLog NVARCHAR(MAX);

EXEC [omd].[CreateModuleInstance]
  @ModuleCode = N'MyModule',
  @Query = N'SELECT 1',
  @BatchInstanceId = 0,
  @ExecutionContext = N'CTX-123',
  @Debug = 'Y',
  @ModuleInstanceId = @ModuleInstanceId OUTPUT,
  @ModuleInstanceStartTimestamp = @ModuleInstanceStartTimestamp OUTPUT,
  @SuccessIndicator = @SuccessIndicator OUTPUT,
  @MessageLog = @MessageLog OUTPUT;

PRINT @ModuleInstanceId;
EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog;
 */

CREATE PROCEDURE [omd].[CreateModuleInstance]
(
   /* Required parameters */
   @ModuleCode                    NVARCHAR(500)   = NULL
   /* Optional parameters */
  ,@Query                         NVARCHAR(MAX)   = NULL
  ,@BatchInstanceId               BIGINT          = 0
  ,@ExecutionContext              NVARCHAR(4000)  = N''
  ,@Debug                         CHAR(1)         = 'N'
   /* Output parameters */
  ,@ModuleInstanceId              BIGINT          = NULL OUTPUT
  ,@ModuleInstanceStartTimestamp  DATETIME2       = NULL OUTPUT
  ,@SuccessIndicator              CHAR(1)         = 'N' OUTPUT
  ,@MessageLog                    NVARCHAR(MAX)   = N'' OUTPUT
)
AS
BEGIN
  BEGIN TRY
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @utcNow DATETIME2 = SYSUTCDATETIME();
    DECLARE @@utcNowDisplayString NVARCHAR(20) = FORMAT(@utcNow, 'yyyy-MM-dd HH:mm:ss');
    SET @ModuleInstanceStartTimestamp = @utcNow;

    -- Default output logging setup
    DECLARE @SpName NVARCHAR(100) = N'[' + OBJECT_SCHEMA_NAME(@@PROCID) + '].[' + OBJECT_NAME(@@PROCID) + ']';
    DECLARE @DirectVersion NVARCHAR(4000) = [omd_metadata].[GetFrameworkVersion]();
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
    SET @LogMessage = COALESCE(@Query, '');
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @Query', @LogMessage, @MessageLog)
    SET @LogMessage = @BatchInstanceId;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchInstanceId', @LogMessage, @MessageLog)
    SET @LogMessage = @ExecutionContext;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ExecutionContext', @LogMessage, @MessageLog)

    -- Process variables
    DECLARE @EventDetail NVARCHAR(4000);
    DECLARE @EventReturnCode NVARCHAR(100);

  /*******************************************************************************
   * Start of main process
   ******************************************************************************/

    DECLARE @ModuleId INT;
    SELECT @ModuleId = [omd].[GetModuleIdByName](@ModuleCode);

    -- Exception handling
    -- The Module Id cannot be NULL
    IF @ModuleId IS NULL
    BEGIN
      SET @LogMessage = 'The Module Id was not found for Module Code ''' + @ModuleCode + '''';
      Set @EventDetail = LEFT(@LogMessage, 4000);
      EXEC [omd].[InsertIntoEventLog] @EventDetail = @EventDetail;
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter Error', @LogMessage, @MessageLog);

      GOTO FailureEndOfProcedure
    END
    ELSE
      SET @LogMessage = 'For Module Code ''' + @ModuleCode + ''' the following Module Id was found in [omd].[MODULE] ''' + CONVERT(NVARCHAR(10), @ModuleId) + '''.';
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

    BEGIN TRY

    -- Create a new module instance record.
    -- Include hash of the Query for tracking in the Executed Code table.
    -- Use placeholder hash for empty or null queries.
    DECLARE @QueryHash VARBINARY(64) =
    CASE
      WHEN
        @Query IS NULL OR TRIM(@Query) = ''
      THEN
        CONVERT(VARBINARY(64), REPLICATE(0x00, 64))
      ELSE
        HASHBYTES('SHA2_512', @Query)
    END

    INSERT INTO [omd].[MODULE_INSTANCE]
    (
      MODULE_ID,
      START_TIMESTAMP,
      EXECUTION_STATUS_CODE,
      NEXT_RUN_STATUS_CODE,
      INTERNAL_PROCESSING_CODE,
      BATCH_INSTANCE_ID,
      EXECUTION_CONTEXT,
      ROWS_INPUT,
      ROWS_INSERTED,
      ROWS_UPDATED,
      ROWS_DELETED,
      ROWS_DISCARDED,
      ROWS_REJECTED,
      EXECUTED_CODE_CHECKSUM
    )
    VALUES
    (
      @ModuleId,            -- Module ID
      @utcNow,              -- Start Datetime (UTC)
      'Executing',          -- Execution Status Code
      'Proceed',            -- Next Run Indicator
      'Abort',              -- Processing Indicator
      @BatchInstanceId,     -- Batch Instance Id
      @ExecutionContext,    -- Runtime Module Execution System Id or similar
      CAST(0 AS BIGINT),
      CAST(0 AS BIGINT),
      CAST(0 AS BIGINT),
      CAST(0 AS BIGINT),
      CAST(0 AS BIGINT),
      CAST(0 AS BIGINT),
      @QueryHash
    );

    SET @ModuleInstanceId = SCOPE_IDENTITY();

    INSERT INTO [omd].[MODULE_INSTANCE_EXECUTED_CODE]
    (
      [CHECKSUM], [EXECUTED_CODE]
    )
    SELECT
      [CHECKSUM], [EXECUTED_CODE]
    FROM
    (VALUES
      (@QueryHash, @Query)
    ) AS refData
    ([CHECKSUM], [EXECUTED_CODE])
    WHERE NOT EXISTS
    (
      SELECT NULL
      FROM [omd].[MODULE_INSTANCE_EXECUTED_CODE] m
      WHERE m.[CHECKSUM] = @QueryHash
    );

    GOTO SuccessEndOfProcedure

    END TRY
    BEGIN CATCH

      SET @SuccessIndicator = 'N';
      SET @ModuleInstanceId = NULL;
      SET @ModuleInstanceStartTimestamp = NULL;

      SET @LogMessage = N'A technical error was encountered';
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

      SET @EventDetail      = COALESCE(ERROR_MESSAGE(), 'None');
      SET @EventReturnCode  = COALESCE(ERROR_NUMBER(), -1);

      SET @LogMessage = @EventDetail;
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, 'Error Message', @LogMessage, @MessageLog)

      SET @LogMessage = @EventReturnCode;
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, 'Error Return Code', @LogMessage, @MessageLog)


      EXEC [omd].[InsertIntoEventLog]
        @ModuleInstanceId = @ModuleInstanceId,
        @EventDetail      = @EventDetail,
        @EventReturnCode  = @EventReturnCode;

      THROW

    END CATCH

    FailureEndOfProcedure:

      SET @SuccessIndicator = 'N';
      SET @ModuleInstanceId = NULL;
      SET @ModuleInstanceStartTimestamp = NULL;

      SET @LogMessage = N'' + @SpName + ' ended in failure.';
      SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

      GOTO EndOfProcedure

    SuccessEndOfProcedure:

      SET @SuccessIndicator = 'Y'

      SET @LogMessage = N'' + @SpName + ' completed successfully.';
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
      -- Spool message log
      EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog
    END
  END TRY
  BEGIN CATCH
    -- SP-wide error handler and logging
    SET @SuccessIndicator = 'N';
    SET @ModuleInstanceId = NULL;
    SET @ModuleInstanceStartTimestamp = NULL;

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
      PRINT 'Error in: '''      + @SpName + ''''
      PRINT 'Error Message: '   + @ErrorMessage
      PRINT 'Error Severity: '  + CONVERT(NVARCHAR(10), @ErrorSeverity)
      PRINT 'Error State: '     + CONVERT(NVARCHAR(10), @ErrorState)
      PRINT 'Error Procedure: ' + @ErrorProcedure
      PRINT 'Error Line: '      + CONVERT(NVARCHAR(10), @ErrorLine)
      PRINT 'Error Number: '    + CONVERT(NVARCHAR(10), @ErrorNumber)
      PRINT 'SuccessIndicator: '+ @SuccessIndicator

      -- Spool message log
      EXEC [omd].[PrintMessageLog] @MessageLog = @MessageLog

    END

    SET @EventDetail = 'Error in ''' + COALESCE(@SpName,'N/A') + ''' from ''' + COALESCE(@ErrorProcedure,'N/A') + ''' at line ''' + CONVERT(NVARCHAR(10), COALESCE(@ErrorLine,'N/A')) + ''': '+ CHAR(10) + COALESCE(@ErrorMessage,'N/A');
    SET @EventReturnCode = ERROR_NUMBER();

    EXEC [omd].[InsertIntoEventLog]
      @EventDetail       = @EventDetail,
      @EventReturnCode   = @EventReturnCode,
      @ModuleInstanceId  = @ModuleInstanceId;

  END CATCH
END
