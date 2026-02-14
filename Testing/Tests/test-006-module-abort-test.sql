/*
* test-6-module-abort-test
* Expected outcomes:
* - Module aborts when executed from an unregistered batch relationship
* - EXECUTION_STATUS_CODE = 'Aborted'
* - INTERNAL_PROCESSING_CODE = 'Abort'
* - NEXT_RUN_STATUS_CODE = 'Proceed'
* - ReturnCode/@RC is 0
* - @SuccessIndicator OUT Parameter is 'Y'
*/

BEGIN
  /* Required for testing framework */
  DECLARE
     @TestResult CHAR(4) = 'Fail'
    ,@TestOutput VARCHAR(MAX);

  /* Local */
  DECLARE
     @Issues INT = 0
    ,@ModuleInstanceId             BIGINT
    ,@ModuleExecutionStatus        NVARCHAR(100)
    ,@ModuleInternalCode           NVARCHAR(100)
    ,@ModuleNextRunStatus          NVARCHAR(100)
    ,@ModuleCode                   NVARCHAR(200) = 'test-6-module-abort-test'
    ,@BatchCode                    NVARCHAR(200) = 'test-6-module-abort-test-batch'
    ,@RunModuleReturnCode          INT
    ,@RunModuleSuccessIndicator    CHAR(1)
    ,@BatchInstanceId              BIGINT
    ,@ModuleInstanceBatchId        BIGINT;

  BEGIN TRY
    DECLARE @ModuleId INT;

    EXEC [Direct_Framework].[omd].[RegisterModule]
       @ModuleCode = @ModuleCode
      ,@ModuleAreaCode = 'MAINT'
      ,@Executable = 'SELECT 1;'
      ,@ModuleDescription = 'Regression test 6 - abort scenario'
      ,@Debug = 'N'
      ,@ModuleId = @ModuleId OUTPUT;

    DECLARE @BatchId INT;

    EXEC [Direct_Framework].[omd].[RegisterBatch]
       @BatchCode = @BatchCode
      ,@BatchType = 'TEST'
      ,@BatchDescription = 'Regression test 6 batch'
      ,@Debug = 'N'
      ,@BatchId = @BatchId OUTPUT;

    EXEC [Direct_Framework].[omd].[CreateBatchInstance]
       @BatchCode = @BatchCode
      ,@Debug = 'N'
      ,@BatchInstanceId = @BatchInstanceId OUTPUT;

    EXEC @RunModuleReturnCode = [Direct_Framework].[omd].[RunModule]
       @ModuleCode = @ModuleCode
      ,@BatchInstanceId = @BatchInstanceId
      ,@SuccessIndicator = @RunModuleSuccessIndicator OUTPUT
      ,@MessageLog = NULL;

    IF @RunModuleReturnCode <> 0 OR @RunModuleSuccessIndicator <> 'Y'
    BEGIN
      SET @Issues += 1;
    END;

    SELECT TOP (1)
         @ModuleInstanceId   = MI.MODULE_INSTANCE_ID
        ,@ModuleExecutionStatus = MI.EXECUTION_STATUS_CODE
        ,@ModuleInternalCode = MI.INTERNAL_PROCESSING_CODE
        ,@ModuleNextRunStatus = MI.NEXT_RUN_STATUS_CODE
        ,@ModuleInstanceBatchId = MI.BATCH_INSTANCE_ID
    FROM [Direct_Framework].[omd].[MODULE_INSTANCE] MI
    JOIN [Direct_Framework].[omd].[MODULE] M ON M.MODULE_ID = MI.MODULE_ID
    WHERE M.MODULE_CODE = @ModuleCode
    ORDER BY MI.MODULE_INSTANCE_ID DESC;

    IF @ModuleInstanceId IS NULL
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleExecutionStatus, '') <> 'Aborted'
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleInternalCode, '') <> 'Abort'
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleNextRunStatus, '') <> 'Proceed'
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleInstanceBatchId, 0) <> @BatchInstanceId
    BEGIN
      SET @Issues += 1;
    END;

    IF @ModuleInstanceId IS NOT NULL
    BEGIN
      DECLARE @ExecutedCodeCount INT;

      SELECT @ExecutedCodeCount = COUNT(*)
      FROM [Direct_Framework].[omd].[MODULE_INSTANCE_EXECUTED_CODE]
      WHERE MODULE_INSTANCE_ID = @ModuleInstanceId
        AND EXECUTED_CODE = 'SELECT 1;';

      IF ISNULL(@ExecutedCodeCount, 0) <> 1
      BEGIN
        SET @Issues += 1;
      END;
    END;

    SET @TestOutput = CONCAT(@Issues, ' issues were found.');

    IF @Issues = 0
    SET @TestResult = 'Pass'
    ELSE SET @TestResult = 'Fail';

  END TRY
  BEGIN CATCH
    SET @TestOutput = ERROR_MESSAGE();
    SET @TestResult = 'Fail';
  END CATCH;

  SELECT @TestOutput AS [OUTPUT], @TestResult AS [RESULT];
END
