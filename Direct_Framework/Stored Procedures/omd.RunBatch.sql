/*******************************************************************************
 * [omd].[RunBatch]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   !! THIS IS AN IN-ENGINE EXECUTION PROCEDURE !!
 *   Run a Batch code in-engine
 *   It will execute a data logistics process / query in a DIRECT wrapper.
 *   in the local database context of the DIRECT database.
 *
 * Inputs:
 *   - Batch Code
 *   - Parent Batch Instance Id (in case when called by a parent batch)
 *   - Module Instance Id Column Name (to pass the alternate name of the audit trail id / module instance to child modules when using RunModule)
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

DECLARE @Result VARCHAR(10);
EXEC [omd].[RunBatch]
  @BatchCode = '<>',
  @Result = @Result OUTPUT;
PRINT @Result;

or

EXEC [omd].[RunBatch] @BatchCode = '<>',

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[RunBatch]
(
  -- Mandatory parameters
  @BatchCode                    NVARCHAR(1000),
  -- Optional parameters
  @ParentBatchInstanceId        BIGINT          = 0,
  @ModuleInstanceIdColumnName   NVARCHAR(1000)  = 'MODULE_INSTANCE_ID',
  @Debug                        CHAR(1)         = 'N',
  -- Output parameters
  @Result                       NVARCHAR(10)    = NULL OUTPUT,
  @SuccessIndicator             CHAR(1)         = 'N' OUTPUT,
  @MessageLog                   NVARCHAR(MAX)   = N'' OUTPUT
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
  SET @LogMessage = @BatchCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchCode', @LogMessage, @MessageLog)
  SET @LogMessage = @ParentBatchInstanceId;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ParentBatchInstanceId', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleInstanceIdColumnName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleInstanceIdColumnName', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail NVARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  -- Check if the Batch Code is NULL and trigger a soft error.
  IF @BatchCode IS NULL
  BEGIN
    SET @LogMessage = 'The Batch Code provided is NULL, the process will fail gracefully.'
    SET @MessageLog = [omd].[AddLogMessage]('ERROR', DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    SET @SuccessIndicator = 'N'
    GOTO EndOfProcedure;
  END

  -- Create Batch Instance
  DECLARE @BatchInstanceId INT

  EXEC [omd].[CreateBatchInstance]
    @BatchCode = @BatchCode,
    @Debug = @Debug,
    @BatchInstanceId = @BatchInstanceId OUTPUT;

  -- Batch Evaluation
  DECLARE @InternalProcessingStatusCode VARCHAR(10);

  EXEC [omd].[BatchEvaluation]
    @BatchInstanceId = @BatchInstanceId,
    @Debug = @Debug,
    @InternalProcessingStatusCode = @InternalProcessingStatusCode OUTPUT;

  SET @LogMessage = 'The Processing Status Code is: '+@InternalProcessingStatusCode
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

  IF @InternalProcessingStatusCode NOT IN ('Abort','Cancel') -- These are end-states for the process.
  BEGIN
    BEGIN TRY

    -- Run all Modules related to the Batch.
    SET @LogMessage = 'Start of Module execution'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    DECLARE @ModuleId INT;
    DECLARE @ModuleCode VARCHAR(255);

    DECLARE Module_Cursor CURSOR FOR
      SELECT bm.MODULE_ID, module.MODULE_CODE
      FROM omd.BATCH_MODULE bm
      JOIN omd.MODULE module on bm.MODULE_ID = module.MODULE_ID
      JOIN omd.BATCH batch on bm.BATCH_ID = batch.BATCH_ID
      WHERE batch.BATCH_CODE=@BatchCode
      --AND bm.ACTIVE_INDICATOR = 'Y'
      ORDER BY bm.[SEQUENCE]

    OPEN Module_Cursor

      FETCH NEXT FROM Module_Cursor INTO
        @ModuleId, @ModuleCode

      WHILE @@FETCH_STATUS = 0
      BEGIN

        SET @LogMessage = 'Running on Module '''+@ModuleCode+''' ('+CONVERT(VARCHAR(10),@ModuleId)+').'
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

        EXEC [omd].[RunModule]
          @ModuleCode = @ModuleCode,
          @BatchInstanceId = @BatchInstanceId,
          @ModuleInstanceIdColumnName = @ModuleInstanceIdColumnName,
          @Debug = @Debug

      FETCH NEXT FROM Module_Cursor INTO
        @ModuleId, @ModuleCode

      END
    CLOSE Module_Cursor
    DEALLOCATE Module_Cursor

    -- End of Module Execution
    SET @LogMessage = 'End of Module execution'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Run all child Batches related to the Batch.
    SET @LogMessage = 'Start of Child Batch execution'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)
    DECLARE @BatchIdParent INT;
    DECLARE @BatchCodeParent VARCHAR(255);
    DECLARE @BatchIdChild INT;
    DECLARE @BatchCodeChild VARCHAR(255);

    DECLARE Batch_Cursor CURSOR FOR
      SELECT
         parent_batch.BATCH_ID
        ,parent_batch.BATCH_CODE
        ,child_batch.BATCH_ID
        ,child_batch.BATCH_CODE
      FROM omd.BATCH_HIERARCHY bh
      JOIN omd.BATCH parent_batch ON bh.PARENT_BATCH_ID = parent_batch.BATCH_ID
      JOIN omd.BATCH child_batch ON bh.BATCH_ID = child_batch.BATCH_ID
      WHERE parent_batch.BATCH_CODE = @BatchCode
        --AND bh.ACTIVE_INDICATOR = 'Y'
        --AND parent_batch.ACTIVE_INDICATOR = 'Y'
        --AND child_batch.ACTIVE_INDICATOR = 'Y'
      ORDER BY bh.[SEQUENCE]

    OPEN Batch_Cursor

      FETCH NEXT FROM Batch_Cursor INTO
        @BatchIdParent, @BatchCodeParent, @BatchIdChild, @BatchCodeChild

      WHILE @@FETCH_STATUS = 0
      BEGIN

        SET @LogMessage = 'Running on Batch '''+@BatchCodeChild+''' ('+CONVERT(VARCHAR(10),@BatchIdChild)+').'
        SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

        EXEC [omd].[RunBatch]
          @BatchCode = @BatchCodeChild,
          @ParentBatchInstanceId = @BatchInstanceId,
          @ModuleInstanceIdColumnName = @ModuleInstanceIdColumnName,
          @Debug = @Debug

      FETCH NEXT FROM Batch_Cursor INTO
        @BatchIdParent, @BatchCodeParent, @BatchIdChild, @BatchCodeChild

      END
    CLOSE Batch_Cursor
    DEALLOCATE Batch_Cursor

    -- End of child Batch Execution
    SET @LogMessage = 'End of Child Batch execution'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    SET @LogMessage = 'Success pathway.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

    -- Batch Success
    EXEC [omd].[UpdateBatchInstance]
        @BatchInstanceId  = @BatchInstanceId,
        @Debug            = @Debug,
        @EventCode        = 'Success'

    SET @Result = 'Success';

    SET @SuccessIndicator = 'Y'
   END TRY
    BEGIN CATCH
      SET @LogMessage = 'Failure pathway.'
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Status Update', @LogMessage, @MessageLog)

      -- Batch Failure
      EXEC [omd].[UpdateBatchInstance]
        @BatchInstanceId  = @BatchInstanceId,
        @Debug            = @Debug,
        @EventCode        = 'Failure';

    SET @Result = 'Failure';

    THROW

    END CATCH
  END
  ELSE
  BEGIN
    SET @Result = @InternalProcessingStatusCode;
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
    @EventReturnCode   = @EventReturnCode,
    @BatchInstanceId   = @BatchInstanceId;

  THROW
END CATCH