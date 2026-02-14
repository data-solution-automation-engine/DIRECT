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
  ,@Name = 'test-001-basic-module-execution'
  ,@TestObject = 'DIRECT'
  /* Test procedure */
	,@Debug = 'Y'
  ,@TestCode = '/*
* test-1-basic-module-execution
* Expected outcomes:
* - Module execution is successful
* - EXECUTION_STATUS_CODE = ''Succeeded''
* - INTERNAL_PROCESSING_CODE = ''Proceed''
* - NEXT_RUN_STATUS_CODE = ''Proceed''
* - Executed code is correctly saved in the MODULE_INSTANCE_EXECUTED_CODE table
*/

BEGIN
  

  /* Local */
  DECLARE
     @Issues INT = 0
    ,@ModuleInstanceId                 INT
    ,@ModuleExecutionStatus            NVARCHAR(100)
    ,@ModuleInternalProcessingCode     NVARCHAR(100)
    ,@ModuleNextRunStatus              NVARCHAR(100)
    ,@ModuleExecutedCode               NVARCHAR(MAX)

  BEGIN TRY
    DECLARE @ModuleId INT

	  /* Register the module */
    EXEC [Direct_Framework].[omd].[RegisterModule]
       @ModuleCode = ''test-1-basic-module-execution''
      ,@ModuleAreaCode = ''MAINT''
      ,@Executable = ''SELECT SYSUTCDATETIME()''
      /* Optional parameters */
      ,@ModuleDescription = ''test-1-basic-module-execution''
      ,@Debug = ''N''
      /* Output parameters */
      ,@ModuleId = @ModuleId OUTPUT;

    /* Execute the module */
    EXEC [Direct_Framework].[omd].[RunModule]
       @ModuleCode = ''test-1-basic-module-execution''
      ,@Debug = ''N'';

    /* Review the outcomes */
    SELECT @ModuleInstanceId = MAX(MODULE_INSTANCE_ID)
    FROM [Direct_Framework].omd.MODULE_INSTANCE
    WHERE MODULE_ID = (SELECT MODULE_ID FROM [Direct_Framework].omd.MODULE WHERE MODULE_CODE = ''test-1-basic-module-execution'')

    /* Module execution results */
    SELECT
       @ModuleExecutionStatus = EXECUTION_STATUS_CODE
      ,@ModuleInternalProcessingCode = INTERNAL_PROCESSING_CODE
      ,@ModuleNextRunStatus = NEXT_RUN_STATUS_CODE
    FROM [Direct_Framework].omd.MODULE_INSTANCE
    WHERE MODULE_INSTANCE_ID = @ModuleInstanceId;

    /* Check that the executed code is correctly stored */
    SELECT
        @ModuleExecutedCode = EXECUTED_CODE
    FROM [Direct_Framework].omd.MODULE_INSTANCE_EXECUTED_CODE
    WHERE [CHECKSUM] = (SELECT [EXECUTED_CODE_CHECKSUM] FROM [Direct_Framework].omd.MODULE_INSTANCE WHERE MODULE_INSTANCE_ID = @ModuleInstanceId);

    /* Spool */
        PRINT ''@ModuleExecutionStatus: ''+@ModuleExecutionStatus;
        PRINT ''@ModuleInternalProcessingCode: ''+@ModuleInternalProcessingCode;
        PRINT ''@ModuleNextRunStatus: ''+@ModuleNextRunStatus;
        PRINT ''@ModuleExecutedCode: ''+@ModuleExecutedCode;

    IF @ModuleExecutionStatus = ''Succeeded'' AND
       @ModuleInternalProcessingCode = ''Proceed'' AND
       @ModuleNextRunStatus = ''Proceed'' AND
       @ModuleExecutedCode = ''SELECT SYSUTCDATETIME()''
      BEGIN
        PRINT ''Succeeded''
      END
    ELSE
      BEGIN
        PRINT ''Failed''
        SET @Issues = @Issues + 1;
      END

    SET @TestOutput = CONVERT(VARCHAR(10),@Issues)+'' issues were found.'';

    IF @Issues = 0
    BEGIN
      SET @TestResult = ''Pass''
    END

  END TRY
  BEGIN CATCH
    SET @TestOutput = ERROR_MESSAGE();
    SET @TestResult = ''Fail''
  END CATCH

  SELECT @TestOutput AS [OUTPUT], @TestResult AS [RESULT]
END'

/* Review
  SELECT * FROM [Testing_Framework].[ut].[TEST]
*/

/* Run the test */

EXEC [Testing_Framework].[ut].[RunTest]
   @TestName = 'test-001-basic-module-execution'
  ,@PlanId = NULL
  ,@Debug = 'Y';

/* Review
SELECT * FROM [Testing_Framework].[ut].[TEST]
SELECT * FROM [Testing_Framework].[ut].[TEST_RESULTS]
*/

