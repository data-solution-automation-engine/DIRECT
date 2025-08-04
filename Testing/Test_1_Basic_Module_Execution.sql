/*
Testing Framework
DIRECT regression tests
*/

-- Step 1: register a new test template.

DECLARE @TemplateId INT;
EXEC [Testing_Framework].[ut].[RegisterTestTemplate]
    @TemplateName = 'DIRECT Regression Tests',
    @TemplateNotes = 'Ensuring that DIRECT operation meets expectations.',
    @Debug = 'Y',
    @TemplateId = @TemplateId OUTPUT;
PRINT concat('The Test Template Id is: ', @TemplateId, '.');

-- Step 2: register a test for this template.
-- The test (code) must report back if the test has passed or failed.

DECLARE @TestId INT;
EXEC [Testing_Framework].[ut].[RegisterTest]
    -- Mandatory
    @TemplateId = @TemplateId,
    @Name = 'Test_1_Basic_Module_Execution',
    -- Test procedure
	  @Debug='Y',
    @TestCode =
'BEGIN
	/* Framework required */
	--DECLARE @TestResult VARCHAR(10) = ''Fail'';
	--DECLARE @TestOutput VARCHAR(MAX);
	/* Local */
	DECLARE @Issues INT = 0;

  BEGIN TRY
    DECLARE @ModuleId INT

    EXEC [Direct_Framework].[omd].[RegisterModule]
      @ModuleCode = ''MyNewModule'',
      @ModuleAreaCode = ''MAINT'',
      @Executable = ''SELECT SYSUTCDATETIME()'',
      -- Optional parameters
      @ModuleDescription = ''Data logistics Example'',
      @Debug = ''Y'',
      -- Output parameters
      @ModuleId = @ModuleId OUTPUT;

    EXEC [Direct_Framework].[omd].[RunModule]
      @ModuleCode = ''MyNewModule'',
      @Debug = ''Y'';

    SET @TestOutput = CONVERT(VARCHAR(10),@Issues)+'' issues were found.'';

		IF @Issues = 0
		BEGIN
			SET @TestResult=''Pass''
		END
	END TRY
	BEGIN CATCH
		SET @TestOutput = ERROR_MESSAGE();
		SET @TestResult=''Fail''
	END CATCH

	SELECT @TestOutput AS [OUTPUT], @TestResult AS [RESULT]
END',
    @TestObject = 'omd.MODULE',
    -- Output
    @TestId = @TestId OUTPUT;
PRINT concat('The Test Id is: ', @TestId, '.');

/* Review
SELECT * FROM [Testing_Framework].[ut].[TEST]
*/

-- Step 3: run the test

EXEC [Testing_Framework].[ut].[RunTest]
    @TestName = 'Test_1_Basic_Module_Execution',
    @PlanId = NULL,
    @Debug = 'Y';

/* Review
SELECT * FROM [Testing_Framework].[ut].[TEST_RESULTS]
*/
