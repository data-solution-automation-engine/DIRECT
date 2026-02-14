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
  ,@Name = <<TEST-NAME>>
  ,@TestObject = 'DIRECT'
  /* Test procedure */
	,@Debug = 'Y'
  ,@TestCode = <<TEST-CODE>>

/* Review
  SELECT * FROM [Testing_Framework].[ut].[TEST]
*/

/* Run the test */

EXEC [Testing_Framework].[ut].[RunTest]
   @TestName = <<TEST-NAME>>
  ,@PlanId = NULL
  ,@Debug = 'Y';

/* Review
SELECT * FROM [Testing_Framework].[ut].[TEST]
SELECT * FROM [Testing_Framework].[ut].[TEST_RESULTS]
*/
