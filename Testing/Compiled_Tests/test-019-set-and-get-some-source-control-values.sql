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
  ,@Name = 'test-019-set-and-get-some-source-control-values'
  ,@TestObject = 'DIRECT'
  /* Test procedure */
	,@Debug = 'Y'
  ,@TestCode = '/*
* test-19-set-and-get-some-source-control-values
* Expected outcomes:
* - Framework allows and correctly sets and gets source control values
* - ReturnCode/@RC is 0
* - @SuccessIndicator OUT Parameter is ''Y''
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
    SET @TestResult = ''Pass''
    ELSE SET @TestResult = ''Fail'';

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
   @TestName = 'test-019-set-and-get-some-source-control-values'
  ,@PlanId = NULL
  ,@Debug = 'Y';

/* Review
SELECT * FROM [Testing_Framework].[ut].[TEST]
SELECT * FROM [Testing_Framework].[ut].[TEST_RESULTS]
*/

