/*******************************************************************************
 * [omd].[CreateModuleInstance]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Create/Register a new Module Instance/Execution/Run of a Module,
 *   by Module Code and Batch Execution Id.
 *
 * Inputs:
 *   - Module Code, the name of the Module, as identified in the MODULE_CODE attribute in the MODULE table
 *   - Query, the executable that was passed down from the Module, for reference
 *   - Batch Instance Id, the Batch Instance Id, if the Module is run from a Batch
 *   - Execution Context Is (e.g. GUID, SPID)
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Module Instance Id
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

DECLARE @ModuleInstanceId BIGINT

EXEC [omd].[CreateModuleInstance]
  -- Mandatory parameters
  -- The name of the Module, as identified in the MODULE_CODE attribute in the MODULE table.
  @ModuleCode = N'<Module Code / Name>',
  -- The query that was passed down from the Module, for reference
  @Query = N'<Query from Module>',
  -- The Batch Instance Id, if the Module is run from a Batch.
  @BatchInstanceId = <Batch Instance Id>,
  -- Optional parameters
  @Debug = 'Y',
  @ExecutionRuntimeId = N'<GUID, SPID>',
  -- Output parameters
  @ModuleInstanceId = @ModuleInstanceId OUTPUT;


PRINT @ModuleInstanceId;

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[CreateModuleInstance]
(
  -- Mandatory parameters
  @ModuleCode           NVARCHAR(1000),
  @Query                NVARCHAR(MAX),
  -- Optional parameters
  @BatchInstanceId      BIGINT          = 0,
  @ExecutionContext     NVARCHAR(1000)  = N'',
  @Debug                CHAR(1)         = 'N',
  -- Output parameters
  @ModuleInstanceId     BIGINT          = NULL OUTPUT,
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
  SET @LogMessage = @ModuleCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleCode', @LogMessage, @MessageLog)
  SET @LogMessage = COALESCE(@Query, '');
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @Query', @LogMessage, @MessageLog)
  SET @LogMessage = @BatchInstanceId;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchInstanceId', @LogMessage, @MessageLog)
  SET @LogMessage = @ExecutionContext;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ExecutionContext', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

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
    EXEC [omd].[InsertIntoEventLog] @EventDetail = @LogMessage;
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, 'Parameter Error', @LogMessage, @MessageLog);

    -- TODO: THROW OR GOTO HERE?
    THROW 50000, @LogMessage, 1;

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
      @Query IS NULL OR @Query = ''
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
    SYSUTCDATETIME(),     -- Start Datetime (UTC)
    'Executing',          -- Execution Status Code
    'Proceed',            -- Next Run Indicator
    'Abort',              -- Processing Indicator
    @BatchInstanceId,     -- Batch Instance Id
    @ExecutionContext,    -- Runtime Module Execution System Id or similar
    0,
    0,
    0,
    0,
    0,
    0,
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

    SET @LogMessage = N'A technical error was encountered';
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

     -- Logging
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

  SET @SuccessIndicator = 'N'

  SET @LogMessage = N'' + @SpName + ' ended in failure.';
  SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)

  GOTO EndOfProcedure

  SuccessEndOfProcedure:

  SET @SuccessIndicator = 'Y'

  SET @LogMessage = N'' + @SpName + ' completed succesfully.';
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

  THROW
END CATCH
