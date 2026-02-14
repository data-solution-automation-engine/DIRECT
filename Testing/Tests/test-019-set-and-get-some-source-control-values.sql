/*
* test-19-set-and-get-some-source-control-values
* Expected outcomes:
* - Framework allows and correctly sets and gets source control values
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
    SET @TestResult = 'Pass'
    ELSE SET @TestResult = 'Fail';

  END TRY
  BEGIN CATCH
    SET @TestOutput = ERROR_MESSAGE();
    SET @TestResult = 'Fail'
  END CATCH

  SELECT @TestOutput AS [OUTPUT], @TestResult AS [RESULT]
END
