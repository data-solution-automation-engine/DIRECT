/**
 * @procedure [omd].[InsertIntoEventLog]
 * @description
 *   Inserts a single event log entry capturing failures or other noteworthy events.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {BIGINT}         @ModuleInstanceId  [in]  (optional, default=0)
 *   Module Instance Id; 0 when not applicable.
 * @param {NVARCHAR(4000)} @EventDetail       [in]  (required)
 *   Event/error detail message (truncated to 4000 for insert).
 * @param {BIGINT}         @BatchInstanceId   [in]  (optional, default=0)
 *   Batch Instance Id; 0 when not applicable.
 * @param {DATETIME2}      @EventTimestamp    [in]  (optional, default=NULL)
 *   Event timestamp; defaults to SYSUTCDATETIME() when NULL.
 * @param {NVARCHAR(100)}  @EventTypeCode     [in]  (optional, default='2')
 *   Event type classification (see [omd].[EVENT_TYPE]).
 * @param {NVARCHAR(100)}  @EventReturnCode   [in]  (optional, default='N/A')
 *   Error/return code where applicable.
 * @param {NUMERIC(20,0)}  @ErrorBitmap       [in]  (optional, default=0)
 *   Optional error bitmask for categorization.
 * @param {CHAR(1)}        @Debug             [in]  (optional, default='N')
 *   Enables debug logging.
 * @param {CHAR(1)}        @SuccessIndicator  [out] (optional)
 *   'Y' if insert succeeded, otherwise 'N'.
 * @param {NVARCHAR(MAX)}  @MessageLog        [out] (optional)
 *   Structured JSON-format log for diagnostics.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     function [omd_metadata].[GetFrameworkVersion]
 * - writes:
 *     table [omd].[EVENT_LOG]
 *
 * @example
 *
EXEC [omd].[InsertIntoEventLog]
  @ModuleInstanceId = 123,
  @EventDetail = N'Unexpected error occurred while processing',
  @EventTypeCode = N'2';
 */

CREATE PROCEDURE [omd].[InsertIntoEventLog]
(
  -- Mandatory parameters
   @ModuleInstanceId   BIGINT          = 0
  ,@EventDetail        NVARCHAR(4000)  = N''
  -- Optional parameters
  ,@BatchInstanceId    BIGINT          = 0
  ,@EventTimestamp     DATETIME2       = NULL
  ,@EventTypeCode      NVARCHAR(100)   = '2'
  ,@EventReturnCode    NVARCHAR(100)   = 'N/A'
  ,@ErrorBitmap        NUMERIC(20,0)   = 0
  ,@Debug              CHAR(1)         = 'N'
   -- Output parameters
  ,@SuccessIndicator   CHAR(1)         = 'N' OUTPUT
  ,@MessageLog         NVARCHAR(MAX)   = N'' OUTPUT
)
AS
BEGIN
  BEGIN TRY
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Default output logging setup
    DECLARE @SpName NVARCHAR(100) = N'[' + OBJECT_SCHEMA_NAME(@@PROCID) + '].[' + OBJECT_NAME(@@PROCID) + ']';
    DECLARE @DirectVersion NVARCHAR(100) = [omd_metadata].[GetFrameworkVersion]();
    DECLARE @StartTimestamp DATETIME2 = SYSUTCDATETIME();
    DECLARE @StartTimestampString NVARCHAR(20) = FORMAT(@StartTimestamp, 'yyyy-MM-dd HH:mm:ss.fffffff');
    DECLARE @EndTimestamp DATETIME2 = NULL;
    DECLARE @EndTimestampString NVARCHAR(20) = N'';
    DECLARE @LogMessage NVARCHAR(MAX);
    DECLARE @EventTimestampString NVARCHAR(33) = N'';

    SET @EventTimestamp = COALESCE(@EventTimestamp, SYSUTCDATETIME());
    SET @EventTimestampString = CONVERT(NVARCHAR(33), @EventTimestamp, 126);

    -- clean parameters
    SET @ModuleInstanceId = COALESCE(@ModuleInstanceId, 0);
    SET @BatchInstanceId = COALESCE(@BatchInstanceId, 0);
    SET @EventDetail = COALESCE(@EventDetail, N'');
    SET @EventTypeCode = COALESCE(@EventTypeCode, N'2');
    SET @SuccessIndicator = 'N';
    SET @MessageLog = N'';

    -- Log standard metadata
    SET @LogMessage = @SpName;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Procedure', @LogMessage, @MessageLog)
    SET @LogMessage = @DirectVersion;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Version',@LogMessage, @MessageLog)
    SET @LogMessage = @StartTimestampString;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Start Timestamp', @LogMessage, @MessageLog)

    -- Log parameters
    SET @LogMessage = @ModuleInstanceId;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleInstanceId', @LogMessage, @MessageLog);
    SET @LogMessage = @EventDetail;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @EventDetail', @LogMessage, @MessageLog);
    SET @LogMessage = @BatchInstanceId;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchInstanceId', @LogMessage, @MessageLog);
    SET @LogMessage = @EventTimestampString;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @EventTimestamp', @LogMessage, @MessageLog);
    SET @LogMessage = @EventTypeCode;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @EventTypeCode', @LogMessage, @MessageLog);
    SET @LogMessage = @EventReturnCode;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @EventReturnCode', @LogMessage, @MessageLog);
    SET @LogMessage = @ErrorBitmap;
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ErrorBitmap', @LogMessage, @MessageLog);

  /*******************************************************************************
   * Start of main process
   ******************************************************************************/

   -- Validate input parameters
   -- if neither module instance, batch instance and event detail are set, then exit
   -- TODO...

   -- else log what we have to make sure its not lost, however might be harder to make use of

    SET @LogMessage = 'Inserting record in Event Log for Module Instance Id ''' + CONVERT(NVARCHAR(20), COALESCE(@ModuleInstanceId, 0)) + ''''
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
    SET @LogMessage = 'Batch Instance Id ''' + CONVERT(NVARCHAR(20), COALESCE(@BatchInstanceId, 0)) + ''''
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
    SET @LogMessage = 'Message: ' + @EventDetail
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    INSERT INTO [omd].[EVENT_LOG]
    (
       [MODULE_INSTANCE_ID]
      ,[BATCH_INSTANCE_ID]
      ,[EVENT_TYPE_CODE]
      ,[EVENT_TIMESTAMP]
      ,[EVENT_RETURN_CODE]
      ,[EVENT_DETAIL]
      ,[ERROR_BITMAP]
    )
    VALUES
    (
       @ModuleInstanceId
      ,@BatchInstanceId
      ,@EventTypeCode
      ,@EventTimestamp
      ,@EventReturnCode
      ,@EventDetail
      ,@ErrorBitmap
    )

    -- End of procedure label
    EndOfProcedure:

    SET @SuccessIndicator = 'Y'

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
    END;

    RETURN 0;

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
      PRINT 'Error in '''       + @SpName + '''';
      PRINT 'Error Message: '   + @ErrorMessage;
      PRINT 'Error Severity: '  + CONVERT(NVARCHAR(10), @ErrorSeverity);
      PRINT 'Error State: '     + CONVERT(NVARCHAR(10), @ErrorState);
      PRINT 'Error Procedure: ' + @ErrorProcedure;
      PRINT 'Error Line: '      + CONVERT(NVARCHAR(10), @ErrorLine);
      PRINT 'Error Number: '    + CONVERT(NVARCHAR(10), @ErrorNumber);
      PRINT 'SuccessIndicator: '+ @SuccessIndicator;

      -- Spool message log
      EXEC [omd].[PrintMessageLog] @MessageLog;

    END;

    RETURN -2;

  END CATCH
END
