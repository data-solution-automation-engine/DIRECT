/*******************************************************************************
  DIRECT v2 Orchestration Unit Tests
  Run after an empty deployment.
  NOTE: This script deletes the current data in the database,
        Please make sure that is an acceptable effect before running
*******************************************************************************/

-- results
DECLARE @ResultTable TABLE
(
  [Test]          NVARCHAR(100),
  [Description]   NVARCHAR(1000),
  [Result]        NVARCHAR(100)
)

-- Parameters
DECLARE @Verbose  CHAR(1) = 'Y'
DECLARE @Debug    CHAR(1) = 'Y'

-- Variables
DECLARE @ModuleId                       INT;
DECLARE @CurrentModuleInstanceId        INT;
DECLARE @CurrentBatchInstanceId         INT;
DECLARE @CurrentModuleExecutionStatus   NVARCHAR(100);
DECLARE @CurrentModuleNextRunStatus     NVARCHAR(100);
DECLARE @CurrentBatchExecutionStatus    NVARCHAR(100);
DECLARE @CurrentBatchNextRunStatus      NVARCHAR(100);
DECLARE @Count                          INT;
DECLARE @EventDetail                    NVARCHAR(MAX);
DECLARE @SuccessIndicator               CHAR(1);
DECLARE @MessageLog                     NVARCHAR(MAX);
DECLARE @Counter                        INT;

-- Meta
DECLARE
  @CurrentTestName NVARCHAR(100) = N'',
  @CurrentTestDescription NVARCHAR(1000) = N'',
  @DefaultRunStatus NVARCHAR(100) = N'Running'

SET NOCOUNT ON;

-- Test Control
DECLARE
  @RunTest01 CHAR(1) = 'Y',
  @RunTest02 CHAR(1) = 'Y',
  @RunTest03 CHAR(1) = 'Y',
  @RunTest04 CHAR(1) = 'Y',
  @RunTest05 CHAR(1) = 'Y',
  @RunTest06 CHAR(1) = 'Y',
  @RunTest07 CHAR(1) = 'Y',
  @RunTest08 CHAR(1) = 'Y',
  @RunTest09 CHAR(1) = 'Y',
  @RunTest10 CHAR(1) = 'Y',
  @RunTest11 CHAR(1) = 'Y',
  @RunTest12 CHAR(1) = 'Y',
  @RunTest13 CHAR(1) = 'Y',
  @RunTest14 CHAR(1) = 'Y',
  @RunTest15 CHAR(1) = 'Y',
  @RunTest16 CHAR(1) = 'Y'

-- Reset the environment (for multiple runs)
DELETE FROM [omd].[BATCH_HIERARCHY]
DELETE FROM [omd].[SOURCE_CONTROL]
DELETE FROM [omd].[EVENT_LOG]
DELETE FROM [omd].[BATCH_MODULE]
DELETE FROM [omd].[MODULE_INSTANCE]   WHERE [MODULE_INSTANCE_ID] <> 0
DELETE FROM [omd].[MODULE]            WHERE [MODULE_ID] <> 0
DELETE FROM [omd].[BATCH_INSTANCE]    WHERE [BATCH_INSTANCE_ID] <> 0
DELETE FROM [omd].[BATCH]             WHERE [BATCH_ID] <> 0

-- Test Table Contents
/*
SELECT * FROM [omd].[BATCH_HIERARCHY]
SELECT * FROM [omd].[SOURCE_CONTROL]
SELECT * FROM [omd].[EVENT_LOG]
SELECT * FROM [omd].[BATCH_MODULE]
SELECT * FROM [omd].[MODULE_INSTANCE]
SELECT * FROM [omd].[MODULE]
SELECT * FROM [omd].[BATCH_INSTANCE]
SELECT * FROM [omd].[BATCH]
*/
-- Register test module
EXEC [omd].[RegisterModule]
   @ModuleCode = 'MyNewModule'
  ,@ModuleAreaCode = 'Maintenance'
  ,@Executable = 'SELECT GETDATE()'
  ,@ModuleDescription = 'Data logistics Example'
  ,@Debug = @Debug
  ,@ModuleId = @ModuleId OUTPUT

IF @Verbose = 'Y'
  PRINT 'The Module Id is: '+CONVERT(VARCHAR(10),@ModuleId)+'.';

DECLARE @BatchId INT
EXEC [omd].[RegisterBatch]
   @BatchCode = 'MyNewBatch'
  ,@BatchDescription = 'Data logistics Workflow'
  ,@Debug = @Debug
  -- Output
  ,@BatchId = @BatchId OUTPUT;

IF @Verbose = 'Y'
BEGIN
  PRINT 'The Batch Id is: ' + CONVERT(VARCHAR(10),@BatchId) + '.';
END

EXEC [omd].[AddModuleToBatch]
   @ModuleCode = 'MyNewModule'
  ,@BatchCode = 'MyNewBatch'
  ,@Debug = @Debug

/*******************************************************************************
    01 - Basic test
*******************************************************************************/
IF @RunTest01 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 01'
  SET @CurrentTestDescription = 'basic module execution'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  EXEC [omd].[RunModule]
   @ModuleCode = 'MyNewModule'
  ,@Debug = @Debug

  SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
  SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

  IF @Verbose = 'Y'
  BEGIN
    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with status '''+@CurrentModuleExecutionStatus +'''.'
  END

  IF @CurrentModuleExecutionStatus = 'Succeeded'
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
  END
  ELSE
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
  END

END

/*******************************************************************************
    02 - Custom code execution test
*******************************************************************************/
IF @RunTest02 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 02'
  SET @CurrentTestDescription = 'module execution with custom code'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  EXEC [omd].[RunModule]
  @ModuleCode = 'MyNewModule',
  @Debug      = @Debug,
  @Query      = 'SELECT SYSDATETIME()'

  SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
  SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

  IF @CurrentModuleExecutionStatus = 'Succeeded'
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
  END
  ELSE
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
  END

END

/*******************************************************************************
    03 - Module failure test
*******************************************************************************/
IF @RunTest03 = 'Y'
BEGIN
  BEGIN TRY
    SET @CurrentTestName = 'TEST 03'
    SET @CurrentTestDescription = 'module execution with failure'

    PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
    INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

    EXEC [omd].[RunModule]
    @ModuleCode   = 'MyNewModule',
    @Debug        = @Debug,
    @Query        = 'SELECT 1/0'

    SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
    SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

    -- Log Test Results
    IF @CurrentModuleExecutionStatus = 'Failed'
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - succeeded'
      UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
    END
    ELSE
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - failed'
      UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
    END

  END TRY
  BEGIN CATCH
    SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
    SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

    -- Log Test Results
    IF @CurrentModuleExecutionStatus = 'Failed'
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - succeeded'
      UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
    END
    ELSE
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - failed'
      UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
    END

  END CATCH

/*******************************************************************************
    03a - Failure logging test
*******************************************************************************/
  SET @CurrentTestName = 'TEST 03a'
  SET @CurrentTestDescription = 'Failure logging test'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  -- Check if the event log is populated.
  -- There should be 1 error in the log now.
  SELECT @Count = COUNT(*) FROM omd.EVENT_LOG WHERE MODULE_INSTANCE_ID = @CurrentModuleInstanceId

  -- Log Test Results
  IF @Count = 1
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
  END
  ELSE
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
  END

END

/*******************************************************************************
    04 - Module Abort test
*******************************************************************************/
IF @RunTest04 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 04'
  SET @CurrentTestDescription = 'Aborting the module because a previous instance is already running'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE

  UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'Executing' WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

  EXEC [omd].[RunModule]
    @ModuleCode = 'MyNewModule',
    @Debug = @Debug

  SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
  SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

  IF @Verbose = 'Y'
  BEGIN
    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with status '''+@CurrentModuleExecutionStatus +'''.'
  END

  -- Log Test Results
  IF @CurrentModuleExecutionStatus = 'Aborted'
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
  END
  ELSE
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
  END

END

/*******************************************************************************
    05 - Module rollback test after abort (previous instance failed)
*******************************************************************************/
IF @RunTest05 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 05'
  SET @CurrentTestDescription = 'Rolling back from failure'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE

  UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'Failed', NEXT_RUN_STATUS_CODE='Rollback' WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId-1;

  EXEC [omd].[RunModule]
    @ModuleCode = 'MyNewModule'
    ,@Debug = @Debug

  SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
  SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;
  SELECT @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

  IF @Verbose = 'Y'
  BEGIN
    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with execution status '''+@CurrentModuleExecutionStatus +''' and next runs status code ''' +''+@CurrentModuleNextRunStatus +'''' +'.'
  END

  -- Log Test Results
  IF @CurrentModuleExecutionStatus = 'Succeeded' AND @CurrentModuleNextRunStatus = 'Proceed'
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
  END
  ELSE
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
  END

END

/*******************************************************************************
    06 - Module cancel test
*******************************************************************************/
IF @RunTest06 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 06'
  SET @CurrentTestDescription = 'Module Cancelling'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE

  UPDATE omd.MODULE SET ACTIVE_INDICATOR = 'N' WHERE MODULE_ID=@ModuleId;

  EXEC [omd].[RunModule]
    @ModuleCode = 'MyNewModule'
    ,@Debug = @Debug

  SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
  SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;
  SELECT @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

  IF @Verbose = 'Y'
  BEGIN
    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with execution status '''+@CurrentModuleExecutionStatus +''' and next runs status code ''' +''+@CurrentModuleNextRunStatus +'''' +'.'
  END

  -- Log Test Results
  IF @CurrentModuleExecutionStatus = 'Cancelled' AND @CurrentModuleNextRunStatus = 'Proceed'
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
  END
  ELSE
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
  END

-- Clean Up
  UPDATE omd.MODULE SET ACTIVE_INDICATOR = 'Y' WHERE MODULE_ID = @ModuleId;
END

/*******************************************************************************
    07 - Failure test,
         failing 3 times in a row and then recover using rollback
*******************************************************************************/
IF @RunTest07 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 07'
  SET @CurrentTestDescription = 'Failing multiple times and rolling back'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  -- Three failures
  BEGIN TRY
    EXEC [omd].[RunModule] @ModuleCode = 'MyNewModule', @Query = 'SELECT 1/0'
  END TRY
  BEGIN CATCH
  END CATCH

  BEGIN TRY
    EXEC [omd].[RunModule] @ModuleCode = 'MyNewModule', @Query = 'SELECT 1/0'
  END TRY
  BEGIN CATCH
  END CATCH

  BEGIN TRY
    EXEC [omd].[RunModule] @ModuleCode = 'MyNewModule', @Query = 'SELECT 1/0'
  END TRY
  BEGIN CATCH
  END CATCH

  -- Run a default run (expected to do rollback and then succeed) and validate rollback behavior
  EXEC [omd].[RunModule]
   @ModuleCode = 'MyNewModule'
  ,@Debug = @Debug

  SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
  SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID = @CurrentModuleInstanceId;
  SELECT @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID = @CurrentModuleInstanceId;

  IF @Verbose = 'Y'
  BEGIN
    PRINT
      'The Current Module Instance is ''' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId) + '''' +
      ' with execution status ''' + @CurrentModuleExecutionStatus + ''' and next runs status code ' +
      '''' + @CurrentModuleNextRunStatus + '''.'
  END

  -- Log Test Results
  IF @CurrentModuleExecutionStatus = 'Succeeded' AND @CurrentModuleNextRunStatus = 'Proceed'
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
  END
  ELSE
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
  END

END

/*******************************************************************************
    08 - Non-existing Module run
*******************************************************************************/
IF @RunTest08 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 08'
  SET @CurrentTestDescription = 'Running a Module Code that does not exist'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  DECLARE @NonExistingModuleName NVARCHAR(1000) = 'MyNonExistingModule'

  BEGIN TRY
    EXEC [omd].[RunModule]
      @ModuleCode = @NonExistingModuleName
     ,@Debug = @Debug
  END TRY
  BEGIN CATCH

    -- Get the latest valid error log (disregarding system error logging)
    SELECT @EventDetail = EVENT_DETAIL
    FROM [omd].[EVENT_LOG]
    WHERE EVENT_ID = (
      SELECT MAX(EVENT_ID)
      FROM [omd].[EVENT_LOG]
      WHERE [EVENT_RETURN_CODE] = 'N/A' -- filter out later technical logs of the error
    )

    -- Log Test Results
    IF @EventDetail = 'The Module Id was not found for Module Code ''' + @NonExistingModuleName + ''''
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - succeeded'
      UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
    END
    ELSE
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - failed'
      UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
    END

    END CATCH
END

/*******************************************************************************
    09 - Batch run with single Module
*******************************************************************************/
IF @RunTest09 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 09'
  SET @CurrentTestDescription = 'Running a Batch with one Module'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  BEGIN TRY

    EXEC [omd].[RunBatch]
      @BatchCode = 'MyNewBatch'
     ,@Debug = @Debug

    SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
    SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;
    SELECT @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

    SELECT @CurrentBatchInstanceId = MAX(BATCH_INSTANCE_ID) FROM omd.BATCH_INSTANCE
    SELECT @CurrentBatchExecutionStatus = EXECUTION_STATUS_CODE FROM omd.BATCH_INSTANCE WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;
    SELECT @CurrentBatchNextRunStatus = NEXT_RUN_STATUS_CODE FROM omd.BATCH_INSTANCE WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;

    IF @Verbose = 'Y'
    BEGIN
      PRINT 'The Current Module Instance is ' + CONVERT(NVARCHAR(10), @CurrentModuleInstanceId) + ' with execution status '''+@CurrentModuleExecutionStatus +''' and next runs status code ''' +''+@CurrentModuleNextRunStatus +'''' +'.'
      PRINT 'The Current Batch Instance is ' + CONVERT(NVARCHAR(10), @CurrentBatchInstanceId) + ' with execution status '''+@CurrentBatchExecutionStatus +''' and next runs status code ''' +''+@CurrentBatchNextRunStatus +'''' +'.'
    END

    -- Log Test Results
    IF (
      @CurrentModuleExecutionStatus = 'Succeeded' AND
      @CurrentModuleNextRunStatus = 'Proceed' AND
      @CurrentBatchExecutionStatus = 'Succeeded' AND
      @CurrentBatchNextRunStatus = 'Proceed')
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - succeeded'
      UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
    END
    ELSE
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - failed'
      UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
    END
  END TRY
  BEGIN CATCH
    PRINT '  ' + @CurrentTestName + ' - failed with technical error'
    UPDATE @ResultTable SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
  END CATCH
END

/*******************************************************************************
    10 - Batch run with two modules Module, failing the 2nd.
*******************************************************************************/
IF @RunTest10 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 10'
  SET @CurrentTestDescription = 'Running a Batch with two Modules, failing the second'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  BEGIN TRY

    -- Register test module
    EXEC [omd].[RegisterModule]
       @ModuleCode = 'MySecondModule'
      ,@ModuleAreaCode = 'Maintenance'
      ,@Executable = 'SELECT 1/0'
      ,@ModuleDescription = 'Data logistics Example'
      --,@Debug = 'Y'

    EXEC [omd].[AddModuleToBatch]
       @ModuleCode = 'MySecondModule'
      ,@BatchCode = 'MyNewBatch'
      --,@Debug = 'Y'

    EXEC [omd].[RunBatch]
      @BatchCode = 'MyNewBatch'
      ,@Debug = @Debug

  END TRY
  BEGIN CATCH
      SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
      SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;
      SELECT @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

      SELECT @CurrentBatchInstanceId = MAX(BATCH_INSTANCE_ID) FROM omd.BATCH_INSTANCE
      SELECT @CurrentBatchExecutionStatus = EXECUTION_STATUS_CODE FROM omd.BATCH_INSTANCE WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;
      SELECT @CurrentBatchNextRunStatus = NEXT_RUN_STATUS_CODE FROM omd.BATCH_INSTANCE WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;

      IF @Verbose = 'Y'
      BEGIN
        PRINT 'The Current Module Instance is ' + CONVERT(NVARCHAR(10), @CurrentModuleInstanceId) + ' with execution status '''+@CurrentModuleExecutionStatus + ''' and next runs status code ''' + ''+@CurrentModuleNextRunStatus + '''' + '.'
        PRINT 'The Current Batch Instance is ' + CONVERT(NVARCHAR(10), @CurrentBatchInstanceId) + ' with execution status '''+@CurrentBatchExecutionStatus + ''' and next runs status code ''' + '' + @CurrentBatchNextRunStatus + '''' + '.'
      END

      -- Log Test Results
      IF (
        @CurrentModuleExecutionStatus = 'Failed' AND
        @CurrentModuleNextRunStatus = 'Rollback' AND
        @CurrentBatchExecutionStatus = 'Failed' AND
        @CurrentBatchNextRunStatus = 'Proceed')
      BEGIN
        PRINT '  ' + @CurrentTestName + ' - succeeded'
        UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
      END
      ELSE
      BEGIN
        PRINT '  ' + @CurrentTestName + ' - failed'
        UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
      END

  END CATCH
END

/*******************************************************************************
    11 - Batch run with two modules Module of which one failed,
         cancelling 1st and reloading 2nd.
*******************************************************************************/
IF @RunTest11 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 11'
  SET @CurrentTestDescription = 'Running a Batch with two Modules where the 2nd failed on the previous run'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  BEGIN TRY
    -- 'Fixing' the broken module
    EXEC [omd].[RegisterModule]
      @ModuleCode = 'MySecondModule'
     ,@ModuleAreaCode = 'Maintenance'
     ,@Executable = 'SELECT GETDATE()'
     ,@ModuleDescription = 'Data logistics Example'
     ,@Debug = @Debug

    EXEC [omd].[RunBatch]
        @BatchCode = 'MyNewBatch'
       ,@Debug = @Debug

      SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
      SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;
      SELECT @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

      SELECT @CurrentBatchInstanceId = MAX(BATCH_INSTANCE_ID) FROM omd.BATCH_INSTANCE
      SELECT @CurrentBatchExecutionStatus = EXECUTION_STATUS_CODE FROM omd.BATCH_INSTANCE WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;
      SELECT @CurrentBatchNextRunStatus = NEXT_RUN_STATUS_CODE FROM omd.BATCH_INSTANCE WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;

      IF @Verbose = 'Y'
      BEGIN
        PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with execution status '''+@CurrentModuleExecutionStatus +''' and next runs status code ''' +''+@CurrentModuleNextRunStatus +'''' +'.'
        PRINT 'The Current Batch Instance is ' + CONVERT(VARCHAR(10),@CurrentBatchInstanceId)+' with execution status '''+@CurrentBatchExecutionStatus +''' and next runs status code ''' +''+@CurrentBatchNextRunStatus +'''' +'.'
      END

      -- Log Test Results
      IF (
        @CurrentModuleExecutionStatus = 'Succeeded' AND
        @CurrentModuleNextRunStatus = 'Proceed' AND
        @CurrentBatchExecutionStatus = 'Succeeded' AND
        @CurrentBatchNextRunStatus = 'Proceed')
      BEGIN
        PRINT '  ' + @CurrentTestName + ' - succeeded'
        UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
      END
      ELSE
      BEGIN
        PRINT '  ' + @CurrentTestName + ' - failed'
        UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
    END


  END TRY
  BEGIN CATCH
    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
    UPDATE @ResultTable SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
  END CATCH
END

/*******************************************************************************
    12 - Add Batch to Parent Batch
*******************************************************************************/
IF @RunTest12 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 12'
  SET @CurrentTestDescription = 'Adding a Batch to the Parent Batch'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  BEGIN TRY
    EXEC [omd].[RegisterBatch]
         @BatchCode = 'MainBatch'
        ,@BatchDescription = 'Data logistics Workflow'
        ,@Debug = @Debug

    EXEC [omd].[AddBatchToParentBatch]
         @BatchCode         = 'MyNewBatch' -- Child
        ,@ParentBatchCode   = 'MainBatch' -- Parent
        ,@Debug             = @Debug
        ,@SuccessIndicator = @SuccessIndicator OUTPUT
        ,@MessageLog       = @MessageLog OUTPUT;

      SELECT @Counter = COUNT(PARENT_BATCH_ID) FROM omd.BATCH_HIERARCHY

      -- Log Test Results
      IF (@Counter=1)
      BEGIN
        PRINT '  ' + @CurrentTestName + ' - succeeded'
        UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
      END
      ELSE
      BEGIN
        PRINT '  ' + @CurrentTestName + ' - failed'
        UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
    END
  END TRY
  BEGIN CATCH
    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
    UPDATE @ResultTable SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
  END CATCH
END

/*******************************************************************************
    13 - Running a Parent Batch
*******************************************************************************/
IF @RunTest13 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 13'
  SET @CurrentTestDescription = 'Running a parent batch'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  BEGIN TRY
        EXEC [omd].[RunBatch]
        @BatchCode = 'MainBatch'
       ,@Debug = @Debug

      SELECT @CurrentBatchInstanceId = MAX(BATCH_INSTANCE_ID) FROM omd.BATCH_INSTANCE
      SELECT @CurrentBatchExecutionStatus = EXECUTION_STATUS_CODE FROM omd.BATCH_INSTANCE WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;
      SELECT @CurrentBatchNextRunStatus = NEXT_RUN_STATUS_CODE FROM omd.BATCH_INSTANCE WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;

      IF @Verbose = 'Y'
      BEGIN
          PRINT 'The Current Batch Instance is ' + CONVERT(VARCHAR(10),@CurrentBatchInstanceId)+' with execution status '''+@CurrentBatchExecutionStatus +''' and next runs status code ''' +''+@CurrentBatchNextRunStatus +'''' +'.'
      END

      -- Log Test Results
      IF (@CurrentBatchExecutionStatus = 'Succeeded' AND @CurrentBatchNextRunStatus = 'Proceed')
      BEGIN
        PRINT '  ' + @CurrentTestName + ' - succeeded'
        UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
      END
      ELSE
      BEGIN
        PRINT '  ' + @CurrentTestName + ' - failed'
        UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
    END
  END TRY
  BEGIN CATCH
    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
    UPDATE @ResultTable SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
  END CATCH
END

/*******************************************************************************
    14 - Attempting to run a disabled Module stand-alone
*******************************************************************************/
IF @RunTest14 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 14'
  SET @CurrentTestDescription = 'Attempting to run a disabled Module stand-alone'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  BEGIN TRY

    UPDATE omd.MODULE SET ACTIVE_INDICATOR = 'N' WHERE MODULE_CODE='MyNewModule'

    EXEC [omd].[RunModule]
     @ModuleCode = 'MyNewModule'
    ,@Debug = @Debug

    SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
    SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

    IF @Verbose = 'Y'
    BEGIN
    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with status '''+@CurrentModuleExecutionStatus +'''.'
    END

    IF @CurrentModuleExecutionStatus = 'Cancelled'
    BEGIN
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
    END
    ELSE
    BEGIN
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
    END

    UPDATE omd.MODULE SET ACTIVE_INDICATOR = 'Y' WHERE MODULE_CODE='MyNewModule'
 END TRY
  BEGIN CATCH
    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
    UPDATE @ResultTable SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
  END CATCH
END

/*******************************************************************************
    15 - Attempting to run a disabled Module from a Batch
*******************************************************************************/
IF @RunTest15 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 15'
  SET @CurrentTestDescription = 'Attempting to run a disabled Module from a Batch'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  BEGIN TRY

    UPDATE omd.BATCH_MODULE SET ACTIVE_INDICATOR = 'N' WHERE MODULE_ID = (SELECT MODULE_ID FROM omd.MODULE WHERE MODULE_CODE='MySecondModule')

      EXEC [omd].[RunBatch]
        @BatchCode = 'MyNewBatch'
       ,@Debug = @Debug

    SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID) FROM omd.MODULE_INSTANCE
    SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE FROM omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

    IF @Verbose = 'Y'
    BEGIN
    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with status '''+@CurrentModuleExecutionStatus +'''.'
    END

    IF @CurrentModuleExecutionStatus = 'Cancelled'
    BEGIN
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
    END
    ELSE
    BEGIN
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
    END

    UPDATE omd.MODULE SET ACTIVE_INDICATOR = 'Y' WHERE MODULE_CODE='MyNewModule'
 END TRY
  BEGIN CATCH
    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
    UPDATE @ResultTable SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
  END CATCH
END

/*******************************************************************************
    16 - Attempting to run a disabled Batch
*******************************************************************************/
IF @RunTest16 = 'Y'
BEGIN
  SET @CurrentTestName = 'TEST 16'
  SET @CurrentTestDescription = 'Attempting to run a disabled Batch'

  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  INSERT INTO @ResultTable VALUES(@CurrentTestName, @CurrentTestDescription, @DefaultRunStatus)

  BEGIN TRY

    UPDATE omd.BATCH SET ACTIVE_INDICATOR = 'N' WHERE BATCH_CODE = 'MyNewBatch'

      EXEC [omd].[RunBatch]
        @BatchCode = 'MyNewBatch'
       ,@Debug = @Debug

      SELECT @CurrentBatchInstanceId = MAX(BATCH_INSTANCE_ID) FROM omd.BATCH_INSTANCE
      SELECT @CurrentBatchExecutionStatus = EXECUTION_STATUS_CODE FROM omd.BATCH_INSTANCE WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;
      SELECT @CurrentBatchNextRunStatus = NEXT_RUN_STATUS_CODE FROM omd.BATCH_INSTANCE WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;

      IF @Verbose = 'Y'
      BEGIN
          PRINT 'The Current Batch Instance is ' + CONVERT(VARCHAR(10),@CurrentBatchInstanceId)+' with execution status '''+@CurrentBatchExecutionStatus +''' and next runs status code ''' +''+@CurrentBatchNextRunStatus +'''' +'.'
      END

      -- Log Test Results
      IF (@CurrentBatchExecutionStatus = 'Cancelled')
      BEGIN
        PRINT '  ' + @CurrentTestName + ' - succeeded'
        UPDATE @ResultTable SET Result = 'Success' WHERE Test = @CurrentTestName
      END
      ELSE
      BEGIN
        PRINT '  ' + @CurrentTestName + ' - failed'
        UPDATE @ResultTable SET Result = 'Failure' WHERE Test = @CurrentTestName
    END

    UPDATE omd.BATCH SET ACTIVE_INDICATOR = 'Y' WHERE BATCH_CODE = 'MyNewBatch'
 END TRY
  BEGIN CATCH
    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
    UPDATE @ResultTable SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
  END CATCH
END

-- Display Results, optionally filter by success etc...
SELECT * FROM @ResultTable ORDER BY Test


/*******************************************************************************
-- Debug and verification only
SELECT * FROM [omd].[MODULE]
SELECT * FROM [omd].[MODULE_INSTANCE] ORDER BY 1 DESC

SELECT * FROM [omd].[BATCH]
SELECT * FROM [omd].[BATCH_INSTANCE] ORDER BY 1 DESC

SELECT * FROM [omd].[BATCH_MODULE] WHERE BATCH_ID = (SELECT BATCH_ID FROM omd.BATCH WHERE BATCH_CODE = 'MyNewBatch')

SELECT * FROM [omd].[MODULE_INSTANCE_EXECUTED_CODE]
SELECT * FROM [omd].EVENT_LOG

EXEC [omd].[RunModule]
     @ModuleCode = 'Bla'
    ,@Debug='Y'

********************************************/
