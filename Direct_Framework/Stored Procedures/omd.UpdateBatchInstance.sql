CREATE PROCEDURE [omd].[UpdateBatchInstance]
(
  -- Mandatory parameters
  @BatchInstanceId        BIGINT,
  -- Optional parameters
  @EventCode              NVARCHAR(100) = N'None',
  @Debug                  CHAR(1)       = 'N',
    -- Output parameters
  @SuccessIndicator       CHAR(1)       = 'N' OUTPUT,
  @MessageLog             NVARCHAR(MAX) = NULL OUTPUT
)
AS
BEGIN TRY
  SET NOCOUNT ON;
  SET ANSI_WARNINGS OFF; -- Suppress NULL elimination warning within SET operation.

/*******************************************************************************
 * [omd].[UpdateBatchInstance]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Update the status of a Batch Instance based on the input event code.
 *
 * Inputs:
 *   - Batch Instance Id
 *   - Event Code (Process, Abort, Cancel, Rollback, Success, or Failure)
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

DECLARE @BatchInstanceId INT

EXEC [omd].[UpdateBatchInstance]
  @BatchInstanceId = <>,
  @EventCode = '<>'
  -- Output parameters
  @BatchInstanceId = @BatchInstanceId OUTPUT;

PRINT @BatchInstanceId;

 *******************************************************************************
 *
 ******************************************************************************/

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
  SET @LogMessage = @BatchInstanceId;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchInstanceId', @LogMessage, @MessageLog)
  SET @LogMessage = @EventCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @EventCode', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail NVARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  -- Exception handling
  IF @EventCode NOT IN ('Proceed', 'Cancel', 'Abort', 'Rollback', 'Success', 'Failure')
  BEGIN
    ;THROW 50000, 'Incorrect Event Code specified. The available options are Proceed, Cancel, Abort, Success, Failure, and Rollback', 1
  END
  -- Abort event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Abort'
  BEGIN
    SET @LogMessage = 'Setting the Batch Instance ' + CONVERT(NVARCHAR(20), @BatchInstanceId) + ' to ' + @EventCode + '.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    UPDATE [omd].[BATCH_INSTANCE]
    SET
      EXECUTION_STATUS_CODE     = 'Aborted',
      INTERNAL_PROCESSING_CODE  = 'Abort',
      NEXT_RUN_STATUS_CODE      = 'Proceed',
      END_TIMESTAMP             = SYSUTCDATETIME()
    WHERE BATCH_INSTANCE_ID = @BatchInstanceId

    GOTO EndOfProcedure

  END

  -- Skip / Cancel event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Cancel'
  BEGIN
    SET @LogMessage = 'Setting the Batch Instance ' + CONVERT(NVARCHAR(20), @BatchInstanceId) + ' to ' + @EventCode+'.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    UPDATE [omd].[BATCH_INSTANCE]
    SET
      EXECUTION_STATUS_CODE     = N'Cancelled',
      INTERNAL_PROCESSING_CODE  = N'Cancel',
      NEXT_RUN_STATUS_CODE      = N'Proceed',
      END_TIMESTAMP             = SYSUTCDATETIME()
    WHERE BATCH_INSTANCE_ID = @BatchInstanceId

    GOTO EndOfProcedure

  END

  -- Success event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Success'
  BEGIN
    SET @LogMessage = 'Setting the Batch Instance ' + CONVERT(NVARCHAR(20), @BatchInstanceId) + ' to ' + @EventCode + '.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    UPDATE [omd].[BATCH_INSTANCE]
    SET
      EXECUTION_STATUS_CODE   = 'Succeeded',
      NEXT_RUN_STATUS_CODE    = 'Proceed',
      END_TIMESTAMP           = SYSUTCDATETIME()
    WHERE BATCH_INSTANCE_ID = @BatchInstanceId

    GOTO EndOfProcedure

  END

  -- Failure event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Failure'
  BEGIN
    SET @LogMessage = 'Setting the Batch Instance ' + CONVERT(NVARCHAR(20), @BatchInstanceId) + ' to ' + @EventCode + '.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Note that the default behaviour is that Next Run Indicator at Batch level is 'Proceed'.
    -- This will only skip/cancel already succesfully completed Modules when a failed Batch is rerun.

    UPDATE [omd].[BATCH_INSTANCE]
    SET
      EXECUTION_STATUS_CODE   = 'Failed',
      NEXT_RUN_STATUS_CODE    = 'Proceed',
      END_TIMESTAMP           = SYSUTCDATETIME()
    WHERE  BATCH_INSTANCE_ID = @BatchInstanceId

    GOTO EndOfProcedure

  END

  -- Rollback event
  IF @EventCode = 'Rollback'
  BEGIN
    SET @LogMessage = 'Setting the Batch Instance ' + CONVERT(NVARCHAR(20), @BatchInstanceId) + ' to ' + @EventCode + '.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    UPDATE [omd].[BATCH_INSTANCE]
    SET
      INTERNAL_PROCESSING_CODE = 'Rollback'
    WHERE BATCH_INSTANCE_ID = @BatchInstanceId

    GOTO EndOfProcedure

  END

  -- Proceed event
  IF @EventCode = 'Proceed'
  BEGIN
    SET @LogMessage = 'Setting the Batch Instance ' + CONVERT(NVARCHAR(20), @BatchInstanceId) + ' to ' + @EventCode + '.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    UPDATE [omd].[BATCH_INSTANCE]
    SET INTERNAL_PROCESSING_CODE = 'Proceed'
    WHERE BATCH_INSTANCE_ID = @BatchInstanceId

    GOTO EndOfProcedure

  END

  -- End of procedure label
  EndOfProcedure:

  SET @SuccessIndicator = 'Y'

  SET @EndTimestamp = SYSUTCDATETIME();
  SET @EndTimestampString = FORMAT(@EndTimestamp, 'yyyy-MM-dd HH:mm:ss.fffffff');
  SET @LogMessage = @EndTimestampString;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'End Timestamp', @LogMessage, @MessageLog)
  SET @LogMessage = DATEDIFF(SECOND, @StartTimestamp, @EndTimestamp);
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Elapsed Time (s)', @LogMessage, @MessageLog)

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
