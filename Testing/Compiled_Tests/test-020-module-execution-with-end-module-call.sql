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
  ,@Name = 'test-020-module-execution-with-end-module-call'
  ,@TestObject = 'DIRECT'
  /* Test procedure */
	,@Debug = 'Y'
  ,@TestCode = '/*
* test-20-module-execution-with-end-module-call
* Expected outcomes:
* - Module registers and executes successfully
* - [omd].[EndModuleInstance] updates status codes to the Success mapping
* - Positive row counts persist, null parameters with null targets default to 0
* - Negative inputs do not overwrite existing row counts
*/

BEGIN
  

  /* Local */
  DECLARE
     @Issues INT = 0
    ,@ModuleInstanceId                 BIGINT
    ,@ModuleExecutionStatus            NVARCHAR(100)
    ,@ModuleInternalProcessingCode     NVARCHAR(100)
    ,@ModuleNextRunStatus              NVARCHAR(100)
    ,@ModuleExecutedCode               NVARCHAR(MAX)
    ,@RowInputActual                   BIGINT
    ,@RowInsertedActual                BIGINT
    ,@RowUpdatedActual                 BIGINT
    ,@RowDeletedActual                 BIGINT
    ,@RowDiscardedActual               BIGINT
    ,@RowRejectedActual                BIGINT;

  BEGIN TRY
    DECLARE
       @ModuleId INT
      ,@ModuleCode NVARCHAR(128) = ''test-20-module-execution-with-end-module-call''
      ,@ReturnCode INT
      ,@SuccessIndicator CHAR(1)
      ,@MessageLog NVARCHAR(MAX)
      ,@EndTimestamp DATETIME2 = DATEADD(SECOND, 1, SYSUTCDATETIME())
      ,@ExpectedRowCountInput BIGINT = 25
      ,@ExpectedRowCountInserted BIGINT = 10
      ,@ExpectedRowCountUpdated BIGINT = 5
      ,@ExpectedRowCountDeleted BIGINT = 2;

    /* Register the module */
    EXEC [Direct_Framework].[omd].[RegisterModule]
       @ModuleCode = @ModuleCode
      ,@ModuleAreaCode = ''MAINT''
      ,@Executable = ''SELECT 1''
      ,@ModuleDescription = @ModuleCode
      ,@Debug = ''N''
      ,@ModuleId = @ModuleId OUTPUT;

    /* Execute the module */
    EXEC [Direct_Framework].[omd].[RunModule]
       @ModuleCode = @ModuleCode
      ,@Debug = ''N'';

    SELECT @ModuleInstanceId = MAX(MODULE_INSTANCE_ID)
    FROM [Direct_Framework].omd.MODULE_INSTANCE
    WHERE MODULE_ID = @ModuleId;

    IF @ModuleInstanceId IS NULL
    BEGIN
      SET @Issues += 1;
      PRINT ''Failed to capture ModuleInstanceId.'';
      GOTO FinishTest;
    END;

    /* Ensure row count columns start null for defaulting logic */
    UPDATE [Direct_Framework].[omd].[MODULE_INSTANCE]
    SET
       ROWS_INPUT = NULL
      ,ROWS_INSERTED = NULL
      ,ROWS_UPDATED = NULL
      ,ROWS_DELETED = NULL
      ,ROWS_DISCARDED = NULL
      ,ROWS_REJECTED = NULL
    WHERE MODULE_INSTANCE_ID = @ModuleInstanceId;

    /* First call: provide positive counts (discarded/rejected left NULL) */
    EXEC @ReturnCode = [Direct_Framework].[omd].[EndModuleInstance]
       @ModuleInstanceId = @ModuleInstanceId
      ,@EventCode = ''Success''
      ,@RowCountInput = @ExpectedRowCountInput
      ,@RowCountInserted = @ExpectedRowCountInserted
      ,@RowCountUpdated = @ExpectedRowCountUpdated
      ,@RowCountDeleted = @ExpectedRowCountDeleted
      ,@RowCountDiscarded = NULL
      ,@RowCountRejected = NULL
      ,@EndTimestamp = @EndTimestamp
      ,@Debug = ''N''
      ,@SuccessIndicator = @SuccessIndicator OUTPUT
      ,@MessageLog = @MessageLog OUTPUT;

    IF @ReturnCode <> 0 OR @SuccessIndicator <> ''Y''
    BEGIN
      SET @Issues += 1;
      PRINT CONCAT(''EndModuleInstance returned '', @ReturnCode,
        '', success indicator = '', COALESCE(@SuccessIndicator, ''?''));
    END;

    SELECT
       @ModuleExecutionStatus = EXECUTION_STATUS_CODE
      ,@ModuleInternalProcessingCode = INTERNAL_PROCESSING_CODE
      ,@ModuleNextRunStatus = NEXT_RUN_STATUS_CODE
      ,@ModuleExecutedCode = miec.EXECUTED_CODE
      ,@RowInputActual = ROWS_INPUT
      ,@RowInsertedActual = ROWS_INSERTED
      ,@RowUpdatedActual = ROWS_UPDATED
      ,@RowDeletedActual = ROWS_DELETED
      ,@RowDiscardedActual = ROWS_DISCARDED
      ,@RowRejectedActual = ROWS_REJECTED
    FROM [Direct_Framework].omd.MODULE_INSTANCE mi
    LEFT JOIN [Direct_Framework].omd.MODULE_INSTANCE_EXECUTED_CODE miec
      ON miec.[CHECKSUM] = mi.EXECUTED_CODE_CHECKSUM
    WHERE mi.MODULE_INSTANCE_ID = @ModuleInstanceId;

    PRINT CONCAT(''@ModuleExecutionStatus: '', COALESCE(@ModuleExecutionStatus, ''NULL''));
    PRINT CONCAT(''@ModuleInternalProcessingCode: '', COALESCE(@ModuleInternalProcessingCode, ''NULL''));
    PRINT CONCAT(''@ModuleNextRunStatus: '', COALESCE(@ModuleNextRunStatus, ''NULL''));

    IF NOT (
         @ModuleExecutionStatus = ''Succeeded''
      AND @ModuleInternalProcessingCode = ''Proceed''
      AND @ModuleNextRunStatus = ''Proceed'')
    BEGIN
      SET @Issues += 1;
      PRINT ''Status codes were not updated to the Success mapping.'';
    END;

    IF NOT (@RowInputActual = @ExpectedRowCountInput
      AND @RowInsertedActual = @ExpectedRowCountInserted
      AND @RowUpdatedActual = @ExpectedRowCountUpdated
      AND @RowDeletedActual = @ExpectedRowCountDeleted)
    BEGIN
      SET @Issues += 1;
      PRINT ''Positive row counts were not persisted correctly.'';
    END;

    IF NOT (@RowDiscardedActual = 0 AND @RowRejectedActual = 0)
    BEGIN
      SET @Issues += 1;
      PRINT ''Null row counts with null targets were not defaulted to 0.'';
    END;

    /* Second call: attempt to overwrite with negative inputs */
    DECLARE
       @ReturnCode2 INT
      ,@SuccessIndicator2 CHAR(1)
      ,@MessageLog2 NVARCHAR(MAX);

    EXEC @ReturnCode2 = [Direct_Framework].[omd].[EndModuleInstance]
       @ModuleInstanceId = @ModuleInstanceId
      ,@EventCode = ''Proceed''
      ,@RowCountInput = -1
      ,@RowCountInserted = -1
      ,@RowCountUpdated = -1
      ,@RowCountDeleted = -1
      ,@RowCountDiscarded = -1
      ,@RowCountRejected = -1
      ,@Debug = ''N''
      ,@SuccessIndicator = @SuccessIndicator2 OUTPUT
      ,@MessageLog = @MessageLog2 OUTPUT;

    IF @ReturnCode2 <> 0 OR @SuccessIndicator2 <> ''Y''
    BEGIN
      SET @Issues += 1;
      PRINT ''Second EndModuleInstance call did not succeed.'';
    END;

    SELECT
       @RowInputActual = ROWS_INPUT
      ,@RowInsertedActual = ROWS_INSERTED
      ,@RowUpdatedActual = ROWS_UPDATED
      ,@RowDeletedActual = ROWS_DELETED
      ,@RowDiscardedActual = ROWS_DISCARDED
      ,@RowRejectedActual = ROWS_REJECTED
    FROM [Direct_Framework].omd.MODULE_INSTANCE
    WHERE MODULE_INSTANCE_ID = @ModuleInstanceId;

    IF NOT (
         @RowInputActual = @ExpectedRowCountInput
      AND @RowInsertedActual = @ExpectedRowCountInserted
      AND @RowUpdatedActual = @ExpectedRowCountUpdated
      AND @RowDeletedActual = @ExpectedRowCountDeleted
      AND @RowDiscardedActual = 0
      AND @RowRejectedActual = 0)
    BEGIN
      SET @Issues += 1;
      PRINT ''Negative inputs overwrote existing row counts.'';
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
   @TestName = 'test-020-module-execution-with-end-module-call'
  ,@PlanId = NULL
  ,@Debug = 'Y';

/* Review
SELECT * FROM [Testing_Framework].[ut].[TEST]
SELECT * FROM [Testing_Framework].[ut].[TEST_RESULTS]
*/

