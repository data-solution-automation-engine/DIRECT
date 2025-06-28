/*******************************************************************************
 * [omd].[RunModule]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   !! THIS IS AN IN-ENGINE EXECUTION PROCEDURE !!
 *   Run a module code in-engine
 *   It will execute a data logistics process / query in a DIRECT wrapper
 *   in the local database context of the DIRECT database.
 *
 * Inputs:
 *   - Module Code
 *   - Query, an input query, which can be custom or calling a procedure. This will override the executable defined for the Module
 *   - Batch Instance Id, if the Module is run from a Batch
 *   - Module Instance Column Name, used as override when the solution use another column name for the module instance Id
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

DECLARE @SuccessIndicator VARCHAR(10);
EXEC [omd].[RunModule]
  @ModuleCode = '<>',
  @Query = '<>'
  @SuccessIndicator = @SuccessIndicator OUTPUT;
PRINT @SuccessIndicator;

or

EXEC [omd].[RunModule]
  @ModuleCode = '<>',
  @Debug = 'Y'
  @Query = '<>';

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[RunModule]
(
  -- Mandatory parameters
  @ModuleCode                   NVARCHAR(1000),
  -- Optional parameters
  @Query                        NVARCHAR(MAX)   = NULL,
  @BatchInstanceId              BIGINT          = 0,
  @ModuleInstanceIdColumnName   NVARCHAR(1000)  = 'MODULE_INSTANCE_ID',
  @Debug                        CHAR(1)         = 'N',
  -- Output parameters
  @ModuleInstanceId             BIGINT          = NULL OUTPUT,
  @SuccessIndicator             CHAR(1)         = 'N' OUTPUT,
  @MessageLog                   NVARCHAR(MAX)   = N'' OUTPUT
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
  SET @LogMessage = @ModuleCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleCode', @LogMessage, @MessageLog)
  SET @LogMessage = COALESCE(@Query, '');
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @Query', @LogMessage, @MessageLog)
  SET @LogMessage = @BatchInstanceId;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchInstanceId', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleInstanceIdColumnName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleInstanceIdColumnName', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  -- Check if the Module Code is NULL and trigger a soft error.
  IF @ModuleCode IS NULL
  BEGIN
    SET @LogMessage = 'The Module Code provided is NULL, the process will fail gracefully.'
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    SET @SuccessIndicator = 'N'
    GOTO EndOfProcedure;
  END

  -- Retrieve the code to execute, if not overridden by the @query parameter.
  IF @Query IS NULL
  BEGIN
    SELECT @Query = [EXECUTABLE] FROM [omd].[MODULE] WHERE MODULE_CODE = @ModuleCode;

    SET @LogMessage = 'The executable code retrieved is: ''' + COALESCE(@Query, '') + '''.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
  END
  ELSE
  BEGIN
    SET @LogMessage = 'An executable code override parameter has been provided: ''' + COALESCE(@Query, '') + '''.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
  END

  -- Create Module Instance
  EXEC [omd].[CreateModuleInstance]
    @ModuleCode         = @ModuleCode,
    @Query              = @Query,
    @Debug              = @Debug,
    @BatchInstanceId    = @BatchInstanceId, -- The Batch Instance Id, if the Module is run from a Batch.
    @ModuleInstanceId   = @ModuleInstanceId OUTPUT;

  -- Make sure that a valid module instance was created
  IF @ModuleInstanceId IS NULL
  BEGIN
    -- If not, raise a soft error.
    SET @SuccessIndicator = 'N'
    GOTO EndOfProcedure;
  END

  -- Module Evaluation
  DECLARE @InternalProcessingStatusCode VARCHAR(10);

  EXEC [omd].[ModuleEvaluation]
    @ModuleInstanceId               = @ModuleInstanceId,
    @Debug                          = @Debug,
    @ModuleInstanceIdColumnName     = @ModuleInstanceIdColumnName,
    @InternalProcessingStatusCode   = @InternalProcessingStatusCode OUTPUT;

    SET @LogMessage = 'The Processing Status Code is: '+@InternalProcessingStatusCode
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  IF @InternalProcessingStatusCode NOT IN ('Abort','Cancel') -- These are end-states for the process.
  BEGIN
    -- Replace placeholder variable(s)
    SET @Query = REPLACE(@Query,'@ModuleInstanceId', @ModuleInstanceId)

    -- Run the code
    DECLARE @RowCount NUMERIC(38)
    EXEC(@Query);
    SET @RowCount = @@ROWCOUNT;

    SET @LogMessage = 'The returned row count is '  + CONVERT(NVARCHAR(20),@RowCount)
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Wrap up
    SET @LogMessage = 'Success pathway'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Module Success
    EXEC [omd].[UpdateModuleInstance]
      @ModuleInstanceId = @ModuleInstanceId,
      @RowCountInsert   = @RowCount,
      @Debug            = @Debug,
      @EventCode        = 'Success'

    SET @SuccessIndicator = 'Y'
  END
  ELSE
  BEGIN
    -- Nothing is done because the internal processing code is either Abort or Cancel.
    -- The process completes succesfully.
    SET @SuccessIndicator = 'Y'
    SET @LogMessage = 'Nothing is done, the process reported Abort or Cancel.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
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

  -- Report Module Failure
  EXEC [omd].[UpdateModuleInstance]
    @ModuleInstanceId = @ModuleInstanceId,
    @RowCountInsert   = @RowCount,
    @Debug            = @Debug,
    @EventCode        = 'Failure';

  DECLARE @ErrorMessage NVARCHAR(4000);
  DECLARE @ErrorSeverity INT;
  DECLARE @ErrorState INT;
  DECLARE @ErrorProcedure NVARCHAR(128);
  DECLARE @ErrorNumber INT;
  DECLARE @ErrorLine INT;

  SELECT
    @ErrorMessage   = COALESCE(ERROR_MESSAGE(),'No Message'),
    @ErrorSeverity  = COALESCE(ERROR_SEVERITY(), -1),
    @ErrorState     = COALESCE(ERROR_STATE(), -1),
    @ErrorProcedure = COALESCE(ERROR_PROCEDURE(), 'No Procedure'),
    @ErrorLine      = COALESCE(ERROR_LINE(), -1),
    @ErrorNumber    = COALESCE(ERROR_NUMBER(), -1);

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
    @ModuleInstanceId  = @ModuleInstanceId,
    @EventDetail       = @EventDetail,
    @EventReturnCode   = @EventReturnCode,
    @BatchInstanceId   = @BatchInstanceId;

  THROW
END CATCH
