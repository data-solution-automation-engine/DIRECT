/*
* test-3-module-execution-with-failure-and-throw
* Expected outcomes:
* - Module throws/raises a SQL error
* - Module execution fails
* - EXECUTION_STATUS_CODE = ''
* - INTERNAL_PROCESSING_CODE = ''
* - NEXT_RUN_STATUS_CODE = ''
* - Executed code is correctly saved in the MODULE_INSTANCE_EXECUTED_CODE table
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

    SET @Issues = 1;
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
