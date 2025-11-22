/* Testing Framework - DIRECT regression tests */

/* Register a new test template */

DECLARE @TemplateId INT;
EXEC [Testing_Framework].[ut].[RegisterTestTemplate]
    @TemplateName = 'DIRECT Regression Tests',
    @TemplateNotes = 'Ensuring that DIRECT operation continues to meet expectations.',
    @Debug = 'Y',
    @TemplateId = @TemplateId OUTPUT;
PRINT concat('The Test Template Id is: ', @TemplateId, '.');

/*
  Register a test for this template.
  The test (code) must report back if the test has passed or failed.
*/

DECLARE @TestId INT;
EXEC [Testing_Framework].[ut].[RegisterTest]
  /* Mandatory */
   @TemplateId = @TemplateId
  ,@Name = 'test-021-batch-execution-with-end-batch-call'
  ,@TestObject = 'DIRECT'
  /* Test procedure */
	,@Debug = 'Y'
  ,@TestCode = '/*
* test-21-batch-execution-with-end-batch-call
* Expected outcomes:
* - Batch registers and creates an instance successfully
* - [omd].[EndBatchInstance] updates status codes per Success mapping
* - End timestamp is populated once and not overwritten by a Proceed event
* - Subsequent Proceed call keeps success status but refreshes internal processing code only
*/

BEGIN
  

  /* Local */
  DECLARE
     @Issues INT = 0
    ,@BatchInstanceId                 BIGINT
    ,@BatchExecutionStatus            NVARCHAR(100)
    ,@BatchInternalProcessingCode     NVARCHAR(100)
    ,@BatchNextRunStatus              NVARCHAR(100)
    ,@BatchEndTimestampSuccess        DATETIME2
    ,@BatchEndTimestampProceed        DATETIME2;

  BEGIN TRY
    DECLARE
       @BatchId INT
      ,@BatchCode NVARCHAR(200) = ''test-21-batch-execution-with-end-batch-call''
      ,@RegisterSuccessIndicator CHAR(1)
      ,@RegisterMessageLog NVARCHAR(MAX)
      ,@CreateBatchReturnCode INT
      ,@BatchInstanceStart DATETIME2
      ,@CreateSuccessIndicator CHAR(1)
      ,@CreateMessageLog NVARCHAR(MAX)
      ,@ReturnCode INT
      ,@SuccessIndicator CHAR(1)
      ,@MessageLog NVARCHAR(MAX)
      ,@ReturnCode2 INT
      ,@SuccessIndicator2 CHAR(1)
      ,@MessageLog2 NVARCHAR(MAX);

    /* Register the batch */
    EXEC [Direct_Framework].[omd].[RegisterBatch]
       @BatchCode = @BatchCode
      ,@BatchType = ''TEST''
      ,@BatchDescription = @BatchCode
      ,@Debug = ''N''
      ,@BatchId = @BatchId OUTPUT
      ,@SuccessIndicator = @RegisterSuccessIndicator OUTPUT
      ,@MessageLog = @RegisterMessageLog OUTPUT;

    IF @RegisterSuccessIndicator <> ''Y'' OR @BatchId IS NULL
    BEGIN
      SET @Issues += 1;
      PRINT ''RegisterBatch did not succeed.'';
      GOTO FinishTest;
    END;

    /* Create a batch instance */
    EXEC @CreateBatchReturnCode = [Direct_Framework].[omd].[CreateBatchInstance]
       @BatchCode = @BatchCode
      ,@Debug = ''N''
      ,@BatchInstanceId = @BatchInstanceId OUTPUT
      ,@BatchInstanceStartTimestamp = @BatchInstanceStart OUTPUT
      ,@SuccessIndicator = @CreateSuccessIndicator OUTPUT
      ,@MessageLog = @CreateMessageLog OUTPUT;

    IF @CreateBatchReturnCode <> 0 OR @CreateSuccessIndicator <> ''Y'' OR @BatchInstanceId IS NULL
    BEGIN
      SET @Issues += 1;
      PRINT ''CreateBatchInstance did not succeed.'';
      GOTO FinishTest;
    END;

    /* Force known starting values */
    UPDATE [Direct_Framework].[omd].[BATCH_INSTANCE]
    SET
       EXECUTION_STATUS_CODE = ''Executing''
      ,INTERNAL_PROCESSING_CODE = ''Abort''
      ,NEXT_RUN_STATUS_CODE = ''Rollback''
      ,END_TIMESTAMP = NULL
    WHERE BATCH_INSTANCE_ID = @BatchInstanceId;

    /* First call: Success event to finalize batch */
    EXEC @ReturnCode = [Direct_Framework].[omd].[EndBatchInstance]
       @BatchInstanceId = @BatchInstanceId
      ,@EventCode = ''Success''
      ,@Debug = ''N''
      ,@SuccessIndicator = @SuccessIndicator OUTPUT
      ,@MessageLog = @MessageLog OUTPUT;

    IF @ReturnCode <> 0 OR @SuccessIndicator <> ''Y''
    BEGIN
      SET @Issues += 1;
      PRINT ''EndBatchInstance (Success) call failed.'';
    END;

    SELECT
       @BatchExecutionStatus = EXECUTION_STATUS_CODE
      ,@BatchInternalProcessingCode = INTERNAL_PROCESSING_CODE
      ,@BatchNextRunStatus = NEXT_RUN_STATUS_CODE
      ,@BatchEndTimestampSuccess = END_TIMESTAMP
    FROM [Direct_Framework].[omd].[BATCH_INSTANCE]
    WHERE BATCH_INSTANCE_ID = @BatchInstanceId;

    PRINT CONCAT(''@BatchExecutionStatus: '', COALESCE(@BatchExecutionStatus, ''NULL''));
    PRINT CONCAT(''@BatchInternalProcessingCode: '', COALESCE(@BatchInternalProcessingCode, ''NULL''));
    PRINT CONCAT(''@BatchNextRunStatus: '', COALESCE(@BatchNextRunStatus, ''NULL''));

    IF NOT (
         @BatchExecutionStatus = ''Succeeded''
      AND @BatchInternalProcessingCode = ''Proceed''
      AND @BatchNextRunStatus = ''Proceed'')
    BEGIN
      SET @Issues += 1;
      PRINT ''Success event did not set expected status codes.'';
    END;

    IF @BatchEndTimestampSuccess IS NULL
    BEGIN
      SET @Issues += 1;
      PRINT ''End timestamp was not populated for Success event.'';
    END;

    /* Second call: Proceed should leave success status intact */
    EXEC @ReturnCode2 = [Direct_Framework].[omd].[EndBatchInstance]
       @BatchInstanceId = @BatchInstanceId
      ,@EventCode = ''Proceed''
      ,@Debug = ''N''
      ,@SuccessIndicator = @SuccessIndicator2 OUTPUT
      ,@MessageLog = @MessageLog2 OUTPUT;

    IF @ReturnCode2 <> 0 OR @SuccessIndicator2 <> ''Y''
    BEGIN
      SET @Issues += 1;
      PRINT ''EndBatchInstance (Proceed) call failed.'';
    END;

    SELECT
       @BatchExecutionStatus = EXECUTION_STATUS_CODE
      ,@BatchInternalProcessingCode = INTERNAL_PROCESSING_CODE
      ,@BatchNextRunStatus = NEXT_RUN_STATUS_CODE
      ,@BatchEndTimestampProceed = END_TIMESTAMP
    FROM [Direct_Framework].[omd].[BATCH_INSTANCE]
    WHERE BATCH_INSTANCE_ID = @BatchInstanceId;

    IF NOT (
         @BatchExecutionStatus = ''Succeeded''
      AND @BatchInternalProcessingCode = ''Proceed''
      AND @BatchNextRunStatus = ''Proceed'')
    BEGIN
      SET @Issues += 1;
      PRINT ''Proceed event altered expected success status codes.'';
    END;

    IF @BatchEndTimestampProceed IS NULL
    BEGIN
      SET @Issues += 1;
      PRINT ''End timestamp became NULL after Proceed event.'';
    END;

    IF @BatchEndTimestampSuccess <> @BatchEndTimestampProceed
    BEGIN
      SET @Issues += 1;
      PRINT ''Proceed event overwrote the original end timestamp.'';
    END;

FinishTest:
    SET @TestOutput = CONCAT(@Issues, '' issues were found.'');

    IF @Issues = 0
      SET @TestResult = ''Pass''
    ELSE
      SET @TestResult = ''Fail'';

  END TRY
  BEGIN CATCH
    SET @TestOutput = ERROR_MESSAGE();
    SET @TestResult = ''Fail'';
  END CATCH

  SELECT @TestOutput AS [OUTPUT], @TestResult AS [RESULT];
END'

/* Review
  SELECT * FROM [Testing_Framework].[ut].[TEST]
*/

/* Run the test */

EXEC [Testing_Framework].[ut].[RunTest]
   @TestName = 'test-021-batch-execution-with-end-batch-call'
  ,@PlanId = NULL
  ,@Debug = 'Y';

/* Review
SELECT * FROM [Testing_Framework].[ut].[TEST]
SELECT * FROM [Testing_Framework].[ut].[TEST_RESULTS]
*/

