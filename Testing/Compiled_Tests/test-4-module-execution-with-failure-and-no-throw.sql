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
  ,@Name = 'test-4-module-execution-with-failure-and-no-throw'
  ,@TestObject = 'DIRECT'
  /* Test procedure */
	,@Debug = 'Y'
  ,@TestCode = '/*
* test-4-module-execution-with-failure-and-no-throw
* Expected outcomes:
* - Module does not throw/raise a SQL error
* - Module execution fails
* - EXECUTION_STATUS_CODE = ''''
* - INTERNAL_PROCESSING_CODE = ''''
* - NEXT_RUN_STATUS_CODE = ''''
* - Executed code is correctly saved in the MODULE_INSTANCE_EXECUTED_CODE table
* - ReturnCode/@RC is -1
* - @SuccessIndicator OUT Parameter is ''N''
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

  BEGIN TRY
    -- TODO
    SET @Issues = 1; -- issue is there is no test code yet

    SET @TestOutput = CONCAT(@Issues, '' issues were found.'');

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
   @TestName = 'test-4-module-execution-with-failure-and-no-throw'
  ,@PlanId = NULL
  ,@Debug = 'Y';

/* Review
SELECT * FROM [Testing_Framework].[ut].[TEST]
SELECT * FROM [Testing_Framework].[ut].[TEST_RESULTS]
*/

