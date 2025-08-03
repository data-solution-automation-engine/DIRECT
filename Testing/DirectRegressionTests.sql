/*******************************************************************************
  DIRECT v2.1.0 Orchestration Unit Tests
  Run after an empty deployment.
  NOTE: This script deletes the current data in the database,
        Please make sure that is an acceptable effect before running
*******************************************************************************/
SET NOCOUNT ON;

-- organize all tests
DECLARE @Tests TABLE
(
   [TestId]       INT IDENTITY
  ,[Active]       CHAR(1)
)

-- populate test counters
INSERT INTO @Tests ([Active])
SELECT TOP (20) 'Y'
FROM sys.all_objects

-- optionally filter testruns
-- UPDATE @Tests SET Active = 'N' WHERE TestId NOT IN (4)

-- capture rest results
DECLARE @Results TABLE
(
   [TestId]       INT
  ,[Active]       CHAR(1)
  ,[Test]         NVARCHAR(100)
  ,[Description]  NVARCHAR(1000)
  ,[Result]       NVARCHAR(100)
)

DECLARE
  -- Parameters
   @Verbose                         CHAR(1) = 'Y' -- print and show more comprehensive test run information
  ,@Debug                           CHAR(1) = 'Y' -- pass debug to procedures, show max information
  -- Variables
  ,@ModuleId                        INT
  ,@BatchId                         INT
  ,@CurrentModuleInstanceId         INT
  ,@CurrentBatchInstanceId          INT
  ,@CurrentModuleExecutionStatus    NVARCHAR(100)
  ,@CurrentModuleNextRunStatus      NVARCHAR(100)
  ,@CurrentBatchExecutionStatus     NVARCHAR(100)
  ,@CurrentBatchNextRunStatus       NVARCHAR(100)
  ,@CurrentResult                   NVARCHAR(100) = N''
  ,@Count                           INT
  ,@EventDetail                     NVARCHAR(MAX)
  ,@RC                              INT
  ,@SuccessIndicator                CHAR(1)
  ,@MessageLog                      NVARCHAR(MAX)
  ,@Counter                         INT
  ,@TestCounter                     INT = 0
  -- Test Meta
  ,@CurrentTestName                 NVARCHAR(100) = N''
  ,@CurrentTestDescription          NVARCHAR(1000) = N''
  ,@DefaultRunStatus                NVARCHAR(100) = N'Running'
  ,@ModuleCode                      NVARCHAR(500) = N'MyNewModule'
  ,@BatchCode                       NVARCHAR(500) = N'MyNewBatch'

PRINT 'Resetting Environment'
-- Reset the environment
DELETE FROM [omd].[BATCH_HIERARCHY]
DELETE FROM [omd].[SOURCE_CONTROL]
DELETE FROM [omd].[EVENT_LOG]
DELETE FROM [omd].[BATCH_MODULE]
DELETE FROM [omd].[MODULE_INSTANCE]   WHERE [MODULE_INSTANCE_ID] <> 0
DELETE FROM [omd].[MODULE]            WHERE [MODULE_ID] <> 0
DELETE FROM [omd].[BATCH_INSTANCE]    WHERE [BATCH_INSTANCE_ID] <> 0
DELETE FROM [omd].[BATCH]             WHERE [BATCH_ID] <> 0

PRINT 'Reseed identities'
-- reset identity seeds
DBCC CHECKIDENT ('omd.SOURCE_CONTROL', RESEED, 1);
DBCC CHECKIDENT ('omd.EVENT_LOG', RESEED, 1);
DBCC CHECKIDENT ('omd.MODULE_INSTANCE', RESEED, 1);
DBCC CHECKIDENT ('omd.MODULE', RESEED, 1);
DBCC CHECKIDENT ('omd.BATCH_INSTANCE', RESEED, 1);
DBCC CHECKIDENT ('omd.BATCH', RESEED, 1);

/*
-- DEBUG: Display main tables contents

SELECT * FROM [omd].[BATCH_HIERARCHY] ORDER BY 1, 2 DESC
SELECT * FROM [omd].[SOURCE_CONTROL] ORDER BY 1 DESC
SELECT * FROM [omd].[EVENT_LOG] ORDER BY 1 DESC
SELECT * FROM [omd].[BATCH_MODULE] ORDER BY 1, 2 DESC
SELECT * FROM [omd].[MODULE_INSTANCE] ORDER BY 1 DESC
SELECT * FROM [omd].[MODULE] ORDER BY 1 DESC
SELECT * FROM [omd].[BATCH_INSTANCE] ORDER BY 1 DESC
SELECT * FROM [omd].[BATCH] ORDER BY 1 DESC
*/

/* -----------------------------------------------------------------------------
  test fixtures/context
----------------------------------------------------------------------------- */

-- Register test module
PRINT CONCAT('Register test Module ', @ModuleCode)
EXEC @RC = [omd].[RegisterModule]
   @ModuleCode = @ModuleCode
  ,@ModuleAreaCode = 'MAINT'
  ,@Executable = 'SELECT GETDATE() AS [MyNewModule_ExecutionOutput]'
  ,@ModuleDescription = 'Data logistics example'
  ,@Debug = @Debug
  ,@ModuleId = @ModuleId OUTPUT
  ,@SuccessIndicator = @SuccessIndicator OUTPUT
  ,@MessageLog = @MessageLog OUTPUT;

IF @Verbose = 'Y'
  PRINT CONCAT('Registered new Module: ''', @ModuleCode, '''',
    ', success: ''', @SuccessIndicator, '''',
    ', the Module Id is: ''', @ModuleId, '''.');

-- Register test batch
PRINT CONCAT('Register test Batch ', @ModuleCode)
EXEC @RC = [omd].[RegisterBatch]
   @BatchCode = @BatchCode
  ,@BatchDescription = 'Data logistics workflow'
  ,@Debug = @Debug
  -- Output
  ,@BatchId = @BatchId OUTPUT
  ,@SuccessIndicator = @SuccessIndicator OUTPUT
  ,@MessageLog = @MessageLog OUTPUT;

IF @Verbose = 'Y'
  PRINT CONCAT('Registered new Batch: ''', @BatchCode, '''',
    ', success: ''', @SuccessIndicator, '''',
    ', the Batch Id is: ''', @BatchId, '''.');

-- Register test module to batch relationship
EXEC @RC = [omd].[AddModuleToBatch]
   @ModuleCode        = @ModuleCode
  ,@BatchCode         = @BatchCode
  ,@Debug             = @Debug
  ,@SuccessIndicator  = @SuccessIndicator OUTPUT
  ,@MessageLog        = @MessageLog OUTPUT;

/*******************************************************************************
  basic module execution
*******************************************************************************/
SET @TestCounter = @TestCounter + 1;
SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
SET @CurrentTestDescription = 'basic module execution'
INSERT INTO @Results VALUES(@TestCounter, 'N', @CurrentTestName ,@CurrentTestDescription, 'Not run')

IF EXISTS (SELECT 1 FROM @Tests WHERE TestId = @TestCounter AND Active = 'Y')
BEGIN
  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  UPDATE @Results SET Active = 'Y', Result = 'Running' WHERE TestId = @TestCounter

  -- Run Test Code
  EXEC @RC = [omd].[RunModule]
     @ModuleCode = @ModuleCode
    ,@Debug = @Debug
    ,@SuccessIndicator = @SuccessIndicator OUTPUT
    ,@MessageLog = @MessageLog OUTPUT

  -- Assert Test Results
  SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
  FROM omd.MODULE_INSTANCE

  SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
  FROM omd.MODULE_INSTANCE
  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

  IF @Verbose = 'Y'
    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with status '''+@CurrentModuleExecutionStatus +'''.'

  IF @CurrentModuleExecutionStatus = 'Succeeded' AND @SuccessIndicator = 'Y'
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @Results SET Result = 'Success' WHERE TestId = @TestCounter
  END
  ELSE
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @Results SET Result = 'Failure' WHERE TestId = @TestCounter
  END
END

/*******************************************************************************
  module execution with custom code
*******************************************************************************/
SET @TestCounter = @TestCounter + 1;
SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
SET @CurrentTestDescription = 'module execution with custom code'
INSERT INTO @Results VALUES(@TestCounter, 'N', @CurrentTestName ,@CurrentTestDescription, 'Not run')

IF EXISTS (SELECT 1 FROM @Tests WHERE TestId = @TestCounter AND Active = 'Y')
BEGIN
  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  UPDATE @Results SET Active = 'Y', Result = 'Running' WHERE TestId = @TestCounter

  -- Run Test Code
  EXEC @RC = [omd].[RunModule]
     @ModuleCode = 'MyNewModule'
    ,@Query      = 'SELECT SYSDATETIME() AS [MyNewModule_BespokeExecutionResult]'
    ,@Debug = @Debug
    ,@SuccessIndicator = @SuccessIndicator OUTPUT
    ,@MessageLog = @MessageLog OUTPUT

  SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
  FROM omd.MODULE_INSTANCE

  SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
  FROM omd.MODULE_INSTANCE
  WHERE MODULE_INSTANCE_ID = @CurrentModuleInstanceId;

  IF @CurrentModuleExecutionStatus = 'Succeeded' AND @SuccessIndicator = 'Y'
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @Results SET Result = 'Success' WHERE TestId = @TestCounter
  END
  ELSE
  BEGIN
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @Results SET Result = 'Failure' WHERE TestId = @TestCounter
  END
END

/*******************************************************************************
  module execution with failure and throw
*******************************************************************************/
SET @TestCounter = @TestCounter + 1;
SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
SET @CurrentTestDescription = 'module execution with failure and throw'
INSERT INTO @Results VALUES(@TestCounter, 'N', @CurrentTestName ,@CurrentTestDescription, 'Not run')

IF EXISTS (SELECT 1 FROM @Tests WHERE TestId = @TestCounter AND Active = 'Y')
BEGIN
  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  UPDATE @Results SET Active = 'Y', Result = 'Running' WHERE TestId = @TestCounter

  -- Clean earlier module instances so they don't interfere with this test
  -- in case it has failed elsewhere and a slot is still kept open
  UPDATE omd.MODULE_INSTANCE
  SET END_TIMESTAMP = SYSUTCDATETIME(), EXECUTION_STATUS_CODE = 'Aborted'
  WHERE END_TIMESTAMP IS NULL

  -- make sure setting is correct
  UPDATE [omd_metadata].[FRAMEWORK_METADATA] SET [VALUE] = 'Y' WHERE [CODE] = 'THROW_ON_FAILURE'

  -- get ready to catch the throw
  BEGIN TRY
    -- Run Test Code
    EXEC @RC = [omd].[RunModule]
       @ModuleCode        = 'MyNewModule'
      ,@Query             = 'SELECT 1/0 AS [MyNewModule_FailedExecutionResult]'
      ,@Debug             = @Debug
      ,@SuccessIndicator  = @SuccessIndicator OUTPUT
      ,@MessageLog        = @MessageLog OUTPUT

    SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
    FROM omd.MODULE_INSTANCE

    SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
    FROM omd.MODULE_INSTANCE
    WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

    PRINT @CurrentModuleExecutionStatus + ' - ' + @SuccessIndicator

    -- Execution Status Failed is the expected outcome.
    -- Depending on settings for throw the end result/external outcome is different
    IF @CurrentModuleExecutionStatus = 'Failed' AND @SuccessIndicator = 'N'
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - succeeded'
      UPDATE @Results SET Result = 'Success' WHERE TestId = @TestCounter
    END
    ELSE
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - failed'
      UPDATE @Results SET Result = 'Failure' WHERE TestId = @TestCounter
    END
  END TRY
  BEGIN CATCH
    -- Throw/raise expected here, so interpret as success
    PRINT '  ' + @CurrentTestName + ' - succeeded'
    UPDATE @Results SET Result = 'Success' WHERE TestId = @TestCounter
  END CATCH
END

/*******************************************************************************
  module execution with failure and no throw
*******************************************************************************/

SET @TestCounter = @TestCounter + 1;
SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
SET @CurrentTestDescription = 'module execution with failure and no throw'
INSERT INTO @Results VALUES(@TestCounter, 'N', @CurrentTestName ,@CurrentTestDescription, 'Not run')

IF EXISTS (SELECT 1 FROM @Tests WHERE TestId = @TestCounter AND Active = 'Y')
BEGIN
  BEGIN TRY
    PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
    UPDATE @Results SET Active = 'Y', Result = 'Running' WHERE TestId = @TestCounter

    -- Clean earlier module instances so they don't interfere with this test
    -- in case it has failed elsewhere and a slot is still kept open
    UPDATE omd.MODULE_INSTANCE
    SET END_TIMESTAMP = SYSUTCDATETIME(), EXECUTION_STATUS_CODE = 'Aborted'
    WHERE END_TIMESTAMP IS NULL

    -- Test config
    UPDATE [omd_metadata].[FRAMEWORK_METADATA] SET [VALUE] = 'N' WHERE [CODE] = 'THROW_ON_FAILURE'

    -- Run Test Code
    EXEC @RC = [omd].[RunModule]
       @ModuleCode        = 'MyNewModule'
      ,@Query             = 'SELECT 1/0 AS [MyNewModule_FailedExecutionResult]'
      ,@Debug             = @Debug
      ,@SuccessIndicator  = @SuccessIndicator OUTPUT
      ,@MessageLog        = @MessageLog OUTPUT

      SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
      FROM omd.MODULE_INSTANCE

      SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
      FROM omd.MODULE_INSTANCE
      WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

    PRINT @CurrentModuleExecutionStatus + ' - ' + @SuccessIndicator

    -- Execution Status Failed is the expected outcome.
    -- Depending on settings for throw the end result/external outcome is different
    IF @CurrentModuleExecutionStatus = 'Failed' AND @SuccessIndicator = 'N'
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - succeeded'
      UPDATE @Results SET Result = 'Success' WHERE TestId = @TestCounter
    END
    ELSE
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - failed'
      UPDATE @Results SET Result = 'Failure' WHERE TestId = @TestCounter
    END
  END TRY
  BEGIN CATCH
    -- Throw/raise not expected here, so interpret as complete failure
    PRINT '  ' + @CurrentTestName + ' - failed'
    UPDATE @Results SET Result = 'Failure' WHERE TestId = @TestCounter
  END CATCH
END

-- RESET THROW to Default OOB Setting
UPDATE [omd_metadata].[FRAMEWORK_METADATA] SET [VALUE] = 'Y' WHERE [CODE] = 'THROW_ON_FAILURE'

SELECT * FROM omd.MODULE_INSTANCE ORDER BY 1 DESC

/*******************************************************************************
    04 - Failure logging test
*******************************************************************************/

--IF @RunTest04 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Failure logging test'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  -- Check if the event log is populated.
--  -- There should be 1 error in the log now.
--  SELECT
--    @Count = COUNT(*)
--  FROM
--    omd.EVENT_LOG
--  WHERE MODULE_INSTANCE_ID = @CurrentModuleInstanceId

--  -- Log Test Results
--  IF @Count = 1
--  BEGIN
--    PRINT '  ' + @CurrentTestName + ' - succeeded'
--    UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--  END
--  ELSE
--  BEGIN
--    PRINT '  ' + @CurrentTestName + ' - failed'
--    UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--  END
--  END
--END

--/*******************************************************************************
--    05 - Module Abort test
--*******************************************************************************/
--IF @RunTest05 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Aborting the module because a previous instance is already running'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  SELECT
--    @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--  FROM
--    omd.MODULE_INSTANCE

--  UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'Executing' WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

--  EXEC [omd].[RunModule]
--    @ModuleCode = 'MyNewModule',
--    @Debug = @Debug

--  SELECT
--    @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--  FROM
--    omd.MODULE_INSTANCE
--  SELECT
--    @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

--  IF @Verbose = 'Y'
--  BEGIN
--    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with status '''+@CurrentModuleExecutionStatus +'''.'
--  END

--  -- Log Test Results
--  IF @CurrentModuleExecutionStatus = 'Aborted'
--  BEGIN
--    PRINT '  ' + @CurrentTestName + ' - succeeded'
--    UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--  END
--  ELSE
--  BEGIN
--    PRINT '  ' + @CurrentTestName + ' - failed'
--    UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--  END

--END

--/*******************************************************************************
--    06 - Module rollback test after abort (previous instance failed)
--*******************************************************************************/
--IF @RunTest06 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Rolling back from failure'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  SELECT
--    @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--  FROM
--    omd.MODULE_INSTANCE

--  UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'Failed', NEXT_RUN_STATUS_CODE='Rollback' WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId-1;

--  EXEC [omd].[RunModule]
--    @ModuleCode = 'MyNewModule'
--    ,@Debug = @Debug

--  SELECT
--    @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--  FROM
--    omd.MODULE_INSTANCE
--  SELECT
--    @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;
--  SELECT
--    @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

--  IF @Verbose = 'Y'
--  BEGIN
--    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with execution status '''+@CurrentModuleExecutionStatus +''' and next runs status code ''' +''+@CurrentModuleNextRunStatus +'''' +'.'
--  END

--  -- Log Test Results
--  IF @CurrentModuleExecutionStatus = 'Succeeded' AND @CurrentModuleNextRunStatus = 'Proceed'
--  BEGIN
--    PRINT '  ' + @CurrentTestName + ' - succeeded'
--    UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--  END
--  ELSE
--  BEGIN
--    PRINT '  ' + @CurrentTestName + ' - failed'
--    UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--  END

--END

--/*******************************************************************************
--    07 - Module cancel test
--*******************************************************************************/
--IF @RunTest07 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Module Cancelling'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  SELECT
--    @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--  FROM
--    omd.MODULE_INSTANCE

--  UPDATE omd.MODULE SET ACTIVE_INDICATOR = 'N' WHERE MODULE_ID=@ModuleId;

--  EXEC [omd].[RunModule]
--    @ModuleCode = 'MyNewModule'
--    ,@Debug = @Debug

--  SELECT
--    @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--  FROM
--    omd.MODULE_INSTANCE
--  SELECT
--    @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;
--  SELECT
--    @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

--  IF @Verbose = 'Y'
--  BEGIN
--    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with execution status '''+@CurrentModuleExecutionStatus +''' and next runs status code ''' +''+@CurrentModuleNextRunStatus +'''' +'.'
--  END

--  -- Log Test Results
--  IF @CurrentModuleExecutionStatus = 'Cancelled' AND @CurrentModuleNextRunStatus = 'Proceed'
--  BEGIN
--    PRINT '  ' + @CurrentTestName + ' - succeeded'
--    UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--  END
--  ELSE
--  BEGIN
--    PRINT '  ' + @CurrentTestName + ' - failed'
--    UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--  END

--  -- Clean Up
--  UPDATE omd.MODULE SET ACTIVE_INDICATOR = 'Y' WHERE MODULE_ID = @ModuleId;
--END

--/*******************************************************************************
--    08 - Failure test,
--         failing 3 times in a row and then recover using rollback
--*******************************************************************************/
--IF @RunTest08 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Failing multiple times and rolling back'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  -- Three failures
--  BEGIN TRY
--    EXEC [omd].[RunModule] @ModuleCode = 'MyNewModule', @Query = 'SELECT 1/0'
--  END TRY
--  BEGIN CATCH
--  END CATCH

--  BEGIN TRY
--    EXEC [omd].[RunModule] @ModuleCode = 'MyNewModule', @Query = 'SELECT 1/0'
--  END TRY
--  BEGIN CATCH
--  END CATCH

--  BEGIN TRY
--    EXEC [omd].[RunModule] @ModuleCode = 'MyNewModule', @Query = 'SELECT 1/0'
--  END TRY
--  BEGIN CATCH
--  END CATCH

--  -- Run a default run (expected to do rollback and then succeed) and validate rollback behavior
--  EXEC [omd].[RunModule]
--   @ModuleCode = 'MyNewModule'
--  ,@Debug = @Debug

--  SELECT
--    @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--  FROM
--    omd.MODULE_INSTANCE
--  SELECT
--    @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID = @CurrentModuleInstanceId;
--  SELECT
--    @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID = @CurrentModuleInstanceId;

--  IF @Verbose = 'Y'
--  BEGIN
--    PRINT
--      'The Current Module Instance is ''' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId) + '''' +
--      ' with execution status ''' + @CurrentModuleExecutionStatus + ''' and next runs status code ' +
--      '''' + @CurrentModuleNextRunStatus + '''.'
--  END

--  -- Log Test Results
--  IF @CurrentModuleExecutionStatus = 'Succeeded' AND @CurrentModuleNextRunStatus = 'Proceed'
--  BEGIN
--    PRINT '  ' + @CurrentTestName + ' - succeeded'
--    UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--  END
--  ELSE
--  BEGIN
--    PRINT '  ' + @CurrentTestName + ' - failed'
--    UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--  END

--END

--/*******************************************************************************
--    09 - Non-existing Module run
--*******************************************************************************/
--IF @RunTest08 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Running a Module Code that does not exist'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  DECLARE @NonExistingModuleName NVARCHAR(1000) = 'MyNonExistingModule'

--  BEGIN TRY
--    EXEC [omd].[RunModule]
--      @ModuleCode = @NonExistingModuleName
--     ,@Debug = @Debug
--  END TRY
--  BEGIN CATCH

--    -- Get the latest valid error log (disregarding system error logging)
--    SELECT
--    @EventDetail = EVENT_DETAIL
--  FROM
--    [omd].[EVENT_LOG]
--  WHERE EVENT_ID = (
--      SELECT
--    MAX(EVENT_ID)
--  FROM
--    [omd].[EVENT_LOG]
--  WHERE [EVENT_RETURN_CODE] = 'N/A' -- filter out later technical logs of the error
--    )

--    -- Log Test Results
--    IF @EventDetail = 'The Module Id was not found for Module Code ''' + @NonExistingModuleName + ''''
--    BEGIN
--    PRINT '  ' + @CurrentTestName + ' - succeeded'
--    UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--  END
--    ELSE
--    BEGIN
--    PRINT '  ' + @CurrentTestName + ' - failed'
--    UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--  END

--    END CATCH
--END

--/*******************************************************************************
--    10 - Batch run with single Module
--*******************************************************************************/
--IF @RunTest10 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Running a Batch with one Module'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  BEGIN TRY

--    EXEC [omd].[RunBatch]
--      @BatchCode = 'MyNewBatch'
--     ,@Debug = @Debug

--    SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--    FROM omd.MODULE_INSTANCE
--    SELECT @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
--    FROM omd.MODULE_INSTANCE
--    WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;
--    SELECT
--    @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

--    SELECT
--    @CurrentBatchInstanceId = MAX(BATCH_INSTANCE_ID)
--  FROM
--    omd.BATCH_INSTANCE
--    SELECT
--    @CurrentBatchExecutionStatus = EXECUTION_STATUS_CODE
--  FROM
--    omd.BATCH_INSTANCE
--  WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;
--    SELECT
--    @CurrentBatchNextRunStatus = NEXT_RUN_STATUS_CODE
--  FROM
--    omd.BATCH_INSTANCE
--  WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;

--    IF @Verbose = 'Y'
--    BEGIN
--    PRINT 'The Current Module Instance is ' + CONVERT(NVARCHAR(10), @CurrentModuleInstanceId) + ' with execution status '''+@CurrentModuleExecutionStatus +''' and next runs status code ''' +''+@CurrentModuleNextRunStatus +'''' +'.'
--    PRINT 'The Current Batch Instance is ' + CONVERT(NVARCHAR(10), @CurrentBatchInstanceId) + ' with execution status '''+@CurrentBatchExecutionStatus +''' and next runs status code ''' +''+@CurrentBatchNextRunStatus +'''' +'.'
--  END

--    -- Log Test Results
--    IF (
--      @CurrentModuleExecutionStatus = 'Succeeded' AND
--    @CurrentModuleNextRunStatus = 'Proceed' AND
--    @CurrentBatchExecutionStatus = 'Succeeded' AND
--    @CurrentBatchNextRunStatus = 'Proceed')
--    BEGIN
--    PRINT '  ' + @CurrentTestName + ' - succeeded'
--    UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--  END
--    ELSE
--    BEGIN
--    PRINT '  ' + @CurrentTestName + ' - failed'
--    UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--  END
--  END TRY
--  BEGIN CATCH
--    PRINT '  ' + @CurrentTestName + ' - failed with technical error'
--    UPDATE @Results SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
--  END CATCH
--END

--/*******************************************************************************
--TEST - Batch run with two modules Module, failing the 2nd.
--*******************************************************************************/
--IF @RunTest11 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Running a Batch with two Modules, failing the second'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  BEGIN TRY

--    -- Register test module
--    EXEC [omd].[RegisterModule]
--       @ModuleCode = 'MySecondModule'
--      ,@ModuleAreaCode = 'MAINT'
--      ,@Executable = 'SELECT 1/0'
--      ,@ModuleDescription = 'Data logistics Example'
--      --,@Debug = 'Y'

--    EXEC [omd].[AddModuleToBatch]
--       @ModuleCode = 'MySecondModule'
--      ,@BatchCode = 'MyNewBatch'
--      --,@Debug = 'Y'

--    EXEC [omd].[RunBatch]
--      @BatchCode = 'MyNewBatch'
--      ,@Debug = @Debug

--  END TRY
--  BEGIN CATCH
--      SELECT
--    @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--  FROM
--    omd.MODULE_INSTANCE
--      SELECT
--    @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;
--      SELECT
--    @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

--      SELECT
--    @CurrentBatchInstanceId = MAX(BATCH_INSTANCE_ID)
--  FROM
--    omd.BATCH_INSTANCE
--      SELECT
--    @CurrentBatchExecutionStatus = EXECUTION_STATUS_CODE
--  FROM
--    omd.BATCH_INSTANCE
--  WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;
--      SELECT
--    @CurrentBatchNextRunStatus = NEXT_RUN_STATUS_CODE
--  FROM
--    omd.BATCH_INSTANCE
--  WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;

--      IF @Verbose = 'Y'
--      BEGIN
--    PRINT 'The Current Module Instance is ' + CONVERT(NVARCHAR(10), @CurrentModuleInstanceId) + ' with execution status '''+@CurrentModuleExecutionStatus + ''' and next runs status code ''' + ''+@CurrentModuleNextRunStatus + '''' + '.'
--    PRINT 'The Current Batch Instance is ' + CONVERT(NVARCHAR(10), @CurrentBatchInstanceId) + ' with execution status '''+@CurrentBatchExecutionStatus + ''' and next runs status code ''' + '' + @CurrentBatchNextRunStatus + '''' + '.'
--  END

--      -- Log Test Results
--      IF (
--        @CurrentModuleExecutionStatus = 'Failed' AND
--    @CurrentModuleNextRunStatus = 'Rollback' AND
--    @CurrentBatchExecutionStatus = 'Failed' AND
--    @CurrentBatchNextRunStatus = 'Proceed')
--      BEGIN
--    PRINT '  ' + @CurrentTestName + ' - succeeded'
--    UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--  END
--      ELSE
--      BEGIN
--    PRINT '  ' + @CurrentTestName + ' - failed'
--    UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--  END

--  END CATCH
--END

--/*******************************************************************************
--TEST - Batch run with two modules Module of which one failed,
--       cancelling 1st and reloading 2nd.
--*******************************************************************************/
--IF @RunTest12 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Running a Batch with two Modules where the 2nd failed on the previous run'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  BEGIN TRY
--    -- 'Fixing' the broken module
--    EXEC [omd].[RegisterModule]
--      @ModuleCode = 'MySecondModule'
--     ,@ModuleAreaCode = 'MAINT'
--     ,@Executable = 'SELECT GETDATE()'
--     ,@ModuleDescription = 'Data logistics Example'
--     ,@Debug = @Debug

--    EXEC [omd].[RunBatch]
--        @BatchCode = 'MyNewBatch'
--       ,@Debug = @Debug

--      SELECT
--    @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--  FROM
--    omd.MODULE_INSTANCE
--      SELECT
--    @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;
--      SELECT
--    @CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

--      SELECT
--    @CurrentBatchInstanceId = MAX(BATCH_INSTANCE_ID)
--  FROM
--    omd.BATCH_INSTANCE
--      SELECT
--    @CurrentBatchExecutionStatus = EXECUTION_STATUS_CODE
--  FROM
--    omd.BATCH_INSTANCE
--  WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;
--      SELECT
--    @CurrentBatchNextRunStatus = NEXT_RUN_STATUS_CODE
--  FROM
--    omd.BATCH_INSTANCE
--  WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;

--      IF @Verbose = 'Y'
--      BEGIN
--    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with execution status '''+@CurrentModuleExecutionStatus +''' and next runs status code ''' +''+@CurrentModuleNextRunStatus +'''' +'.'
--    PRINT 'The Current Batch Instance is ' + CONVERT(VARCHAR(10),@CurrentBatchInstanceId)+' with execution status '''+@CurrentBatchExecutionStatus +''' and next runs status code ''' +''+@CurrentBatchNextRunStatus +'''' +'.'
--  END

--      -- Log Test Results
--      IF (
--        @CurrentModuleExecutionStatus = 'Succeeded' AND
--    @CurrentModuleNextRunStatus = 'Proceed' AND
--    @CurrentBatchExecutionStatus = 'Succeeded' AND
--    @CurrentBatchNextRunStatus = 'Proceed')
--      BEGIN
--    PRINT '  ' + @CurrentTestName + ' - succeeded'
--    UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--  END
--      ELSE
--      BEGIN
--    PRINT '  ' + @CurrentTestName + ' - failed'
--    UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--  END


--  END TRY
--  BEGIN CATCH
--    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
--    UPDATE @Results SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
--  END CATCH
--END

/*******************************************************************************
TEST - Add Batch to Parent Batch
*******************************************************************************/

SET @TestCounter = @TestCounter + 1;
SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
SET @CurrentTestDescription = 'Adding a Batch to a Parent Batch'
INSERT INTO @Results VALUES(@TestCounter, 'N', @CurrentTestName ,@CurrentTestDescription, 'Not run')

IF EXISTS (SELECT 1 FROM @Tests WHERE TestId = @TestCounter AND Active = 'Y')
BEGIN
  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  UPDATE @Results SET Active = 'Y', Result = 'Running' WHERE TestId = @TestCounter

  -- Run Test Code
  BEGIN TRY
    EXEC @RC = [omd].[RegisterBatch]
       @BatchCode = 'MyNewParentBatch'
      ,@BatchDescription = 'Data logistics workflow'
      ,@Debug = @Debug
      ,@SuccessIndicator  = @SuccessIndicator OUTPUT
      ,@MessageLog        = @MessageLog OUTPUT;

    EXEC @RC = [omd].[AddBatchToParentBatch]
       @BatchCode         = 'MyNewBatch' -- Child
      ,@ParentBatchCode   = 'MyNewParentBatch' -- Parent
      ,@Debug             = @Debug
      ,@SuccessIndicator  = @SuccessIndicator OUTPUT
      ,@MessageLog        = @MessageLog OUTPUT;

    -- Collect test outcomes
    SELECT @Counter = COUNT([PARENT_BATCH_ID])
    FROM [omd].[BATCH_HIERARCHY]

    SELECT COUNT([PARENT_BATCH_ID])
    FROM [omd].[BATCH_HIERARCHY]

    SELECT @CurrentTestName, @CurrentTestDescription, @Counter, @CurrentModuleExecutionStatus, @SuccessIndicator

    -- Assert test results and log
    IF @Counter = 1 AND @SuccessIndicator = 'Y'
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - succeeded'
      UPDATE @Results SET Result = 'Success' WHERE TestId = @TestCounter
    END
    ELSE
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - failed'
      UPDATE @Results SET Result = 'Failure' WHERE TestId = @TestCounter
    END
  END TRY
  BEGIN CATCH
    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
    UPDATE @Results SET Result = 'Technical Failure' WHERE TestId = @TestCounter
  END CATCH
END

/*******************************************************************************
  TEST - Running a Parent Batch
*******************************************************************************/
SET @TestCounter = @TestCounter + 1;
SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
SET @CurrentTestDescription = 'Running a parent batch'
INSERT INTO @Results VALUES(@TestCounter, 'N', @CurrentTestName ,@CurrentTestDescription, 'Not run')

IF EXISTS (SELECT 1 FROM @Tests WHERE TestId = @TestCounter AND Active = 'Y')
BEGIN
  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  UPDATE @Results SET Active = 'Y', Result = 'Running' WHERE TestId = @TestCounter

  BEGIN TRY
    -- Run Test Code
    EXEC @RC = [omd].[RunBatch]
       @BatchCode         = 'MyNewParentBatch'
      ,@Debug             = @Debug
      ,@Result            = @CurrentResult OUTPUT
      ,@SuccessIndicator  = @SuccessIndicator OUTPUT
      ,@MessageLog        = @MessageLog OUTPUT;

    -- Collect test outcomes
    SELECT @CurrentBatchInstanceId = MAX(BATCH_INSTANCE_ID)
    FROM omd.BATCH_INSTANCE

    SELECT @CurrentBatchExecutionStatus = EXECUTION_STATUS_CODE
    FROM omd.BATCH_INSTANCE
    WHERE BATCH_INSTANCE_ID = @CurrentBatchInstanceId;

    SELECT @CurrentBatchNextRunStatus = NEXT_RUN_STATUS_CODE
    FROM omd.BATCH_INSTANCE
    WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;

    SELECT @CurrentResult AS [@CurrentResult]
    IF @Verbose = 'Y'
    BEGIN
      SELECT @CurrentTestName, @CurrentTestDescription, @CurrentResult, @CurrentBatchInstanceId,
        @CurrentBatchInstanceId, @CurrentBatchNextRunStatus, @SuccessIndicator

      PRINT CONCAT(
        @CurrentTestName, ' ', @CurrentTestDescription,
        ' The current Batch Instance is: ''', @CurrentBatchInstanceId, '''',
        ' with execution status: ''', @CurrentBatchExecutionStatus, '''',
        ' and next run status code: ''', @CurrentBatchNextRunStatus, '''.')
    END

    -- Assert test results and log
    IF @CurrentBatchExecutionStatus = 'Succeeded' AND @CurrentResult = 'Success' AND @CurrentBatchNextRunStatus = 'Proceed' AND @SuccessIndicator = 'Y'
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - succeeded'
      UPDATE @Results SET Result = 'Success' WHERE TestId = @TestCounter
    END
    ELSE
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - failed'
      UPDATE @Results SET Result = 'Failure' WHERE TestId = @TestCounter
    END
  END TRY
  BEGIN CATCH
    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
    UPDATE @Results SET Result = 'Technical Failure' WHERE TestId = @TestCounter
  END CATCH
END

/*******************************************************************************
TEST - Attempting to run a disabled Module stand-alone
*******************************************************************************/
SET @TestCounter = @TestCounter + 1;
SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
SET @CurrentTestDescription = 'Attempting to run a disabled Module stand-alone'
INSERT INTO @Results VALUES(@TestCounter, 'N', @CurrentTestName ,@CurrentTestDescription, 'Not run')

IF EXISTS (SELECT 1 FROM @Tests WHERE TestId = @TestCounter AND Active = 'Y')
BEGIN
  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
  UPDATE @Results SET Active = 'Y', Result = 'Running' WHERE TestId = @TestCounter

  -- Clean earlier module instances so they don't interfere with this test
  -- in case it has failed elsewhere and a slot is still kept open
  UPDATE omd.MODULE_INSTANCE
  SET END_TIMESTAMP = SYSUTCDATETIME(), EXECUTION_STATUS_CODE = 'Aborted'
  WHERE END_TIMESTAMP IS NULL

  BEGIN TRY
    -- Test Config
    UPDATE [omd].[MODULE] SET [ACTIVE_INDICATOR] = 'N' WHERE [MODULE_CODE] = @ModuleCode

    -- Run Test Code
    EXEC @RC = [omd].[RunModule]
       @ModuleCode        = @ModuleCode
      ,@Debug             = @Debug
      ,@SuccessIndicator  = @SuccessIndicator OUTPUT
      ,@MessageLog        = @MessageLog OUTPUT;

    -- Collect test outcomes
    SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
    FROM omd.MODULE_INSTANCE

    SELECT @CurrentModuleExecutionStatus = [EXECUTION_STATUS_CODE],
      @CurrentModuleNextRunStatus = [NEXT_RUN_STATUS_CODE]
    FROM [omd].[MODULE_INSTANCE]
    WHERE MODULE_INSTANCE_ID = @CurrentModuleInstanceId;

    IF @Verbose = 'Y'
    BEGIN
      SELECT
        @CurrentTestName [CurrentTestName],
        @CurrentTestDescription [CurrentTestDescription],
        @SuccessIndicator [SuccessIndicator],
        @CurrentModuleInstanceId [CurrentModuleInstanceId],
        @CurrentModuleExecutionStatus [CurrentModuleExecutionStatus],
        @CurrentModuleNextRunStatus [CurrentModuleNextRunStatus]

      PRINT CONCAT(
        @CurrentTestName, ' ', @CurrentTestDescription,
        ' The current Module Instance is: ''', @CurrentModuleInstanceId, '''',
        ' with execution status: ''', @CurrentModuleExecutionStatus, '''',
        ' and next run status code: ''', @CurrentModuleNextRunStatus, '''.')
    END

    -- Assert test results and log, module cancelled is expected when running a disabled module
    IF @CurrentModuleExecutionStatus = 'Cancelled' AND @SuccessIndicator = 'Y'
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - succeeded'
      UPDATE @Results SET Result = 'Success' WHERE TestId = @TestCounter
    END
    ELSE
    BEGIN
      PRINT '  ' + @CurrentTestName + ' - failed'
      UPDATE @Results SET Result = 'Failure' WHERE TestId = @TestCounter
    END
  END TRY
  BEGIN CATCH
    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
    UPDATE @Results SET Result = 'Technical Failure' WHERE TestId = @TestCounter
  END CATCH
END

/*******************************************************************************
  TEST - Attempting to run a disabled Module from a Batch
*******************************************************************************/

--IF @RunTest16 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Attempting to run a disabled Module from a Batch'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  BEGIN TRY

--    UPDATE omd.BATCH_MODULE SET ACTIVE_INDICATOR = 'N' WHERE MODULE_ID = (SELECT
--    MODULE_ID
--  FROM
--    omd.MODULE
--  WHERE MODULE_CODE='MySecondModule')

--      EXEC [omd].[RunBatch]
--        @BatchCode = 'MyNewBatch'
--       ,@Debug = @Debug

--    SELECT
--    @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--  FROM
--    omd.MODULE_INSTANCE
--    SELECT
--    @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
--  FROM
--    omd.MODULE_INSTANCE
--  WHERE MODULE_INSTANCE_ID=@CurrentModuleInstanceId;

--    IF @Verbose = 'Y'
--    BEGIN
--    PRINT 'The Current Module Instance is ' + CONVERT(VARCHAR(10),@CurrentModuleInstanceId)+' with status '''+@CurrentModuleExecutionStatus +'''.'
--  END

--    IF @CurrentModuleExecutionStatus = 'Cancelled'
--    BEGIN
--    PRINT '  ' + @CurrentTestName + ' - succeeded'
--    UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--  END
--    ELSE
--    BEGIN
--    PRINT '  ' + @CurrentTestName + ' - failed'
--    UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--  END

--    UPDATE omd.MODULE SET ACTIVE_INDICATOR = 'Y' WHERE MODULE_CODE='MyNewModule'
-- END TRY
--  BEGIN CATCH
--    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
--    UPDATE @Results SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
--  END CATCH
--END

/*******************************************************************************
TEST - Attempting to run a disabled Batch
*******************************************************************************/

--IF @RunTest17 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Attempting to run a disabled Batch'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  BEGIN TRY

--    UPDATE omd.BATCH SET ACTIVE_INDICATOR = 'N' WHERE BATCH_CODE = 'MyNewBatch'

--      EXEC [omd].[RunBatch]
--        @BatchCode = 'MyNewBatch'
--       ,@Debug = @Debug

--      SELECT
--    @CurrentBatchInstanceId = MAX(BATCH_INSTANCE_ID)
--  FROM
--    omd.BATCH_INSTANCE
--      SELECT
--    @CurrentBatchExecutionStatus = EXECUTION_STATUS_CODE
--  FROM
--    omd.BATCH_INSTANCE
--  WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;
--      SELECT
--    @CurrentBatchNextRunStatus = NEXT_RUN_STATUS_CODE
--  FROM
--    omd.BATCH_INSTANCE
--  WHERE BATCH_INSTANCE_ID=@CurrentBatchInstanceId;

--      IF @Verbose = 'Y'
--      BEGIN
--    PRINT 'The Current Batch Instance is ' + CONVERT(VARCHAR(10),@CurrentBatchInstanceId)+' with execution status '''+@CurrentBatchExecutionStatus +''' and next runs status code ''' +''+@CurrentBatchNextRunStatus +'''' +'.'
--  END

--      -- Log Test Results
--      IF (@CurrentBatchExecutionStatus = 'Cancelled')
--      BEGIN
--    PRINT '  ' + @CurrentTestName + ' - succeeded'
--    UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--  END
--      ELSE
--      BEGIN
--    PRINT '  ' + @CurrentTestName + ' - failed'
--    UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--  END

--    UPDATE omd.BATCH SET ACTIVE_INDICATOR = 'Y' WHERE BATCH_CODE = 'MyNewBatch'
-- END TRY
--  BEGIN CATCH
--    PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
--    UPDATE @Results SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
--  END CATCH
--END

/*******************************************************************************
TEST - Set and Get some source control values
*******************************************************************************/

--IF @RunTest18 = 'Y'
--BEGIN
--  SET @CurrentTestName = CONCAT('TEST ', FORMAT(@TestCounter, '000'))
--  SET @TestCounter = @TestCounter + 1;
--  SET @CurrentTestDescription = 'Attempting to Set and Get source control values'

--  PRINT CHAR(10) + @CurrentTestName + ' - ' + @CurrentTestDescription
--  INSERT INTO @Results
--  VALUES(@CurrentTestName ,@CurrentTestDescription ,@DefaultRunStatus)

--  BEGIN TRY

--    SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
--    FROM omd.MODULE_INSTANCE

--    DECLARE @SourceControlId BIGINT,
--      @SetStartValue NVARCHAR(100),
--      @SetEndValue NVARCHAR(100),
--      @GetStartValue NVARCHAR(100),
--      @GetEndValue NVARCHAR(100);

--      EXEC [omd].[SetSourceControlValues]
--         @ModuleInstanceId = @CurrentModuleInstanceId
--        ,@StartValue = '2025-01-02 12:34:56'
--        ,@EndValue = NULL
--        ,@Debug = @Debug
--        ,@SuccessIndicator = @SuccessIndicator OUTPUT
--        ,@SourceControlId = @SourceControlId OUTPUT
--        ,@MessageLog = @MessageLog OUTPUT

--      SELECT @SetStartValue = START_VALUE, @SetEndValue = END_VALUE
--      FROM omd.SOURCE_CONTROL
--      WHERE SOURCE_CONTROL_ID = @SourceControlId

--      -- SELECT * FROM omd.SOURCE_CONTROL
--      IF @Verbose = 'Y'
--      BEGIN
--        PRINT 'The Current Start Value is ' + @SetStartValue + ', End Value is ' + @SetEndValue + '.'
--      END

--      -- Get the values through the Get SP
--      EXEC [omd].[GetSourceControlValues]
--         @ModuleInstanceId = @CurrentModuleInstanceId
--        ,@Debug = @Debug
--        ,@SuccessIndicator = @SuccessIndicator OUTPUT
--        ,@SourceControlId = @SourceControlId OUTPUT
--        ,@StartValue = @GetStartValue OUTPUT 
--        ,@EndValue = @GetEndValue OUTPUT 
--        ,@MessageLog = @MessageLog OUTPUT

--    IF @Verbose = 'Y'
--      BEGIN
--        PRINT 'The Get returned Start Value is ' + @GetStartValue + ', End Value is ' + @GetEndValue + '.'
--        --PRINT 'The Get returned inputs SuccessIndicator: ' + @SuccessIndicator + ', MessageLog ' + @MessageLog + '.'
--      END

--      -- Log Test Results
--      IF @SetStartValue = '2025-01-02 12:34:56' AND @SetEndValue = '2025-01-02 12:34:56'
--      AND @GetStartValue = @SetStartValue AND @GetEndValue = @SetStartValue
--      BEGIN
--        PRINT '  ' + @CurrentTestName + ' - succeeded'
--        UPDATE @Results SET Result = 'Success' WHERE Test = @CurrentTestName
--        END
--      ELSE
--      BEGIN
--        PRINT '  ' + @CurrentTestName + ' - failed'
--        UPDATE @Results SET Result = 'Failure' WHERE Test = @CurrentTestName
--      END

--    END TRY
--    BEGIN CATCH
--      PRINT '  ' + @CurrentTestName + ' - unexpected technical error'
--      UPDATE @Results SET Result = 'Technical Failure' WHERE Test = @CurrentTestName
--    END CATCH
--  END

-- Update any tests that failed to even report back
UPDATE @Results SET Result = 'Failed to Report Completion' WHERE Result = 'Running'

-- Display Results, optionally filter by success etc...
SELECT
  *
FROM
  @Results
ORDER BY TestId


--/*******************************************************************************
---- Debug and verification only
--SELECT * FROM [omd].[MODULE]
--SELECT * FROM [omd].[MODULE_INSTANCE] ORDER BY 1 DESC

--SELECT * FROM [omd].[BATCH]
--SELECT * FROM [omd].[BATCH_INSTANCE] ORDER BY 1 DESC

--SELECT * FROM [omd].[BATCH_MODULE] WHERE BATCH_ID = (SELECT BATCH_ID FROM omd.BATCH WHERE BATCH_CODE = 'MyNewBatch')

--SELECT * FROM [omd].[MODULE_INSTANCE_EXECUTED_CODE]
--SELECT * FROM [omd].EVENT_LOG

--********************************************/
