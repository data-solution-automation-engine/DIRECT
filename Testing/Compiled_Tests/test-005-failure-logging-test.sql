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
  ,@Name = 'test-005-failure-logging-test'
  ,@TestObject = 'DIRECT'
  /* Test procedure */
	,@Debug = 'Y'
  ,@TestCode = '/*
* test-5-failure-logging-test
* Expected outcomes:
* - Module failure produces one or more entries in omd.EVENT_LOG
* - EXECUTION_STATUS_CODE = ''Failed''
* - INTERNAL_PROCESSING_CODE = ''Proceed''
* - NEXT_RUN_STATUS_CODE = ''Rollback''
* - ReturnCode/@RC is -2
* - @SuccessIndicator OUT Parameter is ''N''
* - Executed code is correctly saved in the MODULE_INSTANCE_EXECUTED_CODE table
*/

BEGIN
  

  /* Local */
  DECLARE
     @Issues INT = 0
    ,@ModuleInstanceId             BIGINT
    ,@ModuleExecutionStatus        NVARCHAR(100)
    ,@ModuleInternalCode           NVARCHAR(100)
    ,@ModuleNextRunStatus          NVARCHAR(100)
    ,@ModuleExecutedCode           NVARCHAR(MAX)
    ,@ModuleCode                   NVARCHAR(200) = ''test-5-failure-logging-test''
    ,@Executable                   NVARCHAR(MAX) = ''THROW 50005, ''''test-5 failure'''', 1;''
    ,@OriginalThrowSetting         NVARCHAR(1)
    ,@RunModuleReturnCode          INT = NULL
    ,@RunModuleSuccessIndicator    CHAR(1) = NULL
    ,@RunModuleMessageLog          NVARCHAR(MAX)
    ,@EventEntries                 INT = 0;

  BEGIN TRY
    SELECT @OriginalThrowSetting = [VALUE]
    FROM [Direct_Framework].[omd_metadata].[FRAMEWORK_METADATA]
    WHERE [CODE] = ''THROW_ON_FAILURE'';

    IF @OriginalThrowSetting <> ''N''
    BEGIN
      UPDATE [Direct_Framework].[omd_metadata].[FRAMEWORK_METADATA]
      SET [VALUE] = ''N''
      WHERE [CODE] = ''THROW_ON_FAILURE'';
    END;

    DECLARE @ModuleId INT;

    EXEC [Direct_Framework].[omd].[RegisterModule]
       @ModuleCode = @ModuleCode
      ,@ModuleAreaCode = ''MAINT''
      ,@Executable = @Executable
      ,@ModuleDescription = ''Regression test 5 - failure logging''
      ,@Debug = ''N''
      ,@ModuleId = @ModuleId OUTPUT;

    EXEC @RunModuleReturnCode = [Direct_Framework].[omd].[RunModule]
       @ModuleCode = @ModuleCode
      ,@SuccessIndicator = @RunModuleSuccessIndicator OUTPUT
      ,@MessageLog = @RunModuleMessageLog OUTPUT;

    IF @RunModuleSuccessIndicator <> ''N''
    BEGIN
      SET @Issues += 1;
    END;

    IF @RunModuleReturnCode <> -2
    BEGIN
      SET @Issues += 1;
    END;

    SELECT TOP (1)
         @ModuleInstanceId   = MI.MODULE_INSTANCE_ID
        ,@ModuleExecutionStatus = MI.EXECUTION_STATUS_CODE
        ,@ModuleInternalCode = MI.INTERNAL_PROCESSING_CODE
        ,@ModuleNextRunStatus = MI.NEXT_RUN_STATUS_CODE
    FROM [Direct_Framework].[omd].[MODULE_INSTANCE] MI
    JOIN [Direct_Framework].[omd].[MODULE] M ON M.MODULE_ID = MI.MODULE_ID
    WHERE M.MODULE_CODE = @ModuleCode
    ORDER BY MI.MODULE_INSTANCE_ID DESC;

    SELECT @ModuleExecutedCode = EC.EXECUTED_CODE
    FROM [Direct_Framework].[omd].[MODULE_INSTANCE_EXECUTED_CODE] EC
    JOIN [Direct_Framework].[omd].[MODULE_INSTANCE] MI
      ON MI.EXECUTED_CODE_CHECKSUM = EC.[CHECKSUM]
    WHERE MI.MODULE_INSTANCE_ID = @ModuleInstanceId;

    SELECT @EventEntries = COUNT(*)
    FROM [Direct_Framework].[omd].[EVENT_LOG]
    WHERE MODULE_INSTANCE_ID = @ModuleInstanceId;

    IF @ModuleInstanceId IS NULL
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleExecutionStatus, '''') <> ''Failed''
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleInternalCode, '''') <> ''Proceed''
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleNextRunStatus, '''') <> ''Rollback''
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(LTRIM(RTRIM(@ModuleExecutedCode)), '''') <> @Executable
    BEGIN
      SET @Issues += 1;
    END;

    IF @EventEntries = 0
    BEGIN
      SET @Issues += 1;
    END;

    SET @TestOutput = CONCAT(@Issues, '' issues were found.'');

    IF @Issues = 0
    SET @TestResult = ''Pass''
    ELSE SET @TestResult = ''Fail'';

  END TRY
  BEGIN CATCH
    SET @TestOutput = ERROR_MESSAGE();
    SET @TestResult = ''Fail'';
  END CATCH;

  BEGIN TRY
    IF @OriginalThrowSetting IS NOT NULL
    BEGIN
      UPDATE [Direct_Framework].[omd_metadata].[FRAMEWORK_METADATA]
      SET [VALUE] = @OriginalThrowSetting
      WHERE [CODE] = ''THROW_ON_FAILURE'';
    END;
  END TRY
  BEGIN CATCH
    SET @TestOutput = CONCAT(''Cleanup failure: '', ERROR_MESSAGE());
    SET @TestResult = ''Fail'';
  END CATCH;

  SELECT @TestOutput AS [OUTPUT], @TestResult AS [RESULT];
END'

/* Review
  SELECT * FROM [Testing_Framework].[ut].[TEST]
*/

/* Run the test */

EXEC [Testing_Framework].[ut].[RunTest]
   @TestName = 'test-005-failure-logging-test'
  ,@PlanId = NULL
  ,@Debug = 'Y';

/* Review
SELECT * FROM [Testing_Framework].[ut].[TEST]
SELECT * FROM [Testing_Framework].[ut].[TEST_RESULTS]
*/

