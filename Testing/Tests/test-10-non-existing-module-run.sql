/*
* test-10-non-existing-module-run
* Expected outcomes:
* - Module manages a run of a non-existent/unregistered module
* - EXECUTION_STATUS_CODE = ''
* - INTERNAL_PROCESSING_CODE = ''
* - NEXT_RUN_STATUS_CODE = ''
* - Executed code is correctly saved in the MODULE_INSTANCE_EXECUTED_CODE table
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
    ,@ModuleInstanceId                 BIGINT
    ,@ModuleExecutionStatus            NVARCHAR(100)
    ,@ModuleInternalProcessingCode     NVARCHAR(100)
    ,@ModuleNextRunStatus              NVARCHAR(100)
    ,@ModuleExecutedCode               NVARCHAR(MAX)

  BEGIN TRY
    -- TODO
    SET @Issues = 1; -- issue is there is no test code yet

    SET @TestOutput = CONCAT(@Issues, ' issues were found.');

    IF @Issues = 0
    BEGIN
      SET @TestResult = 'Pass'
    END

  END TRY
  BEGIN CATCH
    SET @TestOutput = ERROR_MESSAGE();
    SET @TestResult = 'Fail'
  END CATCH

  SELECT @TestOutput AS [OUTPUT], @TestResult AS [RESULT]
END
