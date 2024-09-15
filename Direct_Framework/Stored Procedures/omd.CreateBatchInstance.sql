/*******************************************************************************
 * [omd].[CreateBatchInstance]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 *
 * Purpose:
 *   Create/Register a new Batch Instance/Execution/Run of a Batch, by Batch Code.
 *
 * Inputs:
 *   - Batch Code, the name of the batch (from BATCH_CODE in omd.BATCH)
 *   - Execution runtime Is (e.g. GUID, SPID)
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Batch Instance Id
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

DECLARE @BatchInstanceId BIGINT

EXEC [omd].[CreateBatchInstance]
  -- Mandatory parameters
  @BatchCode = N'<Batch Code / Name>',
  -- Optional parameters
  @Debug = 'Y',
  @ExecutionRuntimeId = N'<GUID, SPID>',
  -- Output parameters
  @BatchInstanceId = @BatchInstanceId OUTPUT;

PRINT @BatchInstanceId;

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[CreateBatchInstance]
(
  -- Mandatory parameters
  @BatchCode              NVARCHAR(1000),
  -- Optional parameters
  @ParentBatchInstanceId  BIGINT          = 0,
  @Debug                  CHAR(1)         = 'N',
  @ExecutionContext       NVARCHAR(4000)  = N'',
  -- Output parameters
  @BatchInstanceId        BIGINT          = NULL OUTPUT,
  @SuccessIndicator       CHAR(1)         = 'N' OUTPUT,
  @MessageLog             NVARCHAR(MAX)   = N'' OUTPUT
)
AS
BEGIN TRY
  SET NOCOUNT ON;

  -- Default output logging
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
  SET @LogMessage = @BatchCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchCode', @LogMessage, @MessageLog)
  SET @LogMessage = @ParentBatchInstanceId;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ParentBatchInstanceId', @LogMessage, @MessageLog)SET @LogMessage = @ExecutionContext;
  SET @LogMessage = @ExecutionContext
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ExecutionContext', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  -- Local procedure variables
  DECLARE @BatchId INT;
  SELECT @BatchId = [omd].[GetBatchIdByName](@BatchCode);

  -- Exception handling
  -- The Batch Id cannot be NULL
  IF @BatchId IS NULL
  BEGIN
    SET @LogMessage = N'The Batch Id was not found for Batch Code ''' + @BatchCode + '''';
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)
    SET @EventDetail = @LogMessage
    EXEC [omd].[InsertIntoEventLog] @EventDetail = @EventDetail;

    GOTO FailureEndOfProcedure

  END

  SET @LogMessage =  N'For Batch Code ''' + @BatchCode + ''' the following Batch Id was found in omd.BATCH: ' + CONVERT(NVARCHAR(10), @BatchId);
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)
  BEGIN TRY

  INSERT INTO omd.BATCH_INSTANCE
  (
    BATCH_ID,
    [PARENT_BATCH_INSTANCE_ID],
    START_TIMESTAMP,
    EXECUTION_STATUS_CODE,
    NEXT_RUN_STATUS_CODE,
    INTERNAL_PROCESSING_CODE,
    EXECUTION_CONTEXT
  )
  VALUES
  (
    @BatchId,
    @ParentBatchInstanceId,
    SYSUTCDATETIME(),   -- Start Timestamp (UTC)
    N'Executing',       -- Execution Status Code
    N'Proceed',         -- Next Run Indicator
    N'Abort',           -- Processing Indicator
    @ExecutionContext   -- Execution Context, runtime information
  )

  SET @BatchInstanceId = SCOPE_IDENTITY();

  SET @LogMessage = 'A new Batch Instance Id ''' + CONVERT(NVARCHAR(10), @BatchInstanceId) + ''' has been created for Batch Code: ' + @BatchCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)
  GOTO SuccessEndOfProcedure

  END TRY

  BEGIN CATCH

  SET @LogMessage = N'A technical error was encountered';
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

  -- Logging
  SET @EventDetail = ERROR_MESSAGE();
  SET @EventReturnCode = ERROR_NUMBER();

  SET @LogMessage = @EventDetail;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, 'Error Message', @LogMessage, @MessageLog)

  SET @LogMessage = @EventReturnCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, 'Error Return Code', @LogMessage, @MessageLog)

  EXEC [omd].[InsertIntoEventLog]
    @BatchInstanceId = @BatchInstanceId,
    @EventDetail = @EventDetail,
    @EventReturnCode = @EventReturnCode;

  THROW

  END CATCH

  FailureEndOfProcedure:

  SET @LogMessage = N'' + @SpName + ' ended in failure.';
  SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, DEFAULT, @LogMessage, @MessageLog)


  GOTO EndOfProcedure

  SuccessEndOfProcedure:

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
    @BatchInstanceId   = @BatchInstanceId;

  THROW
END CATCH
