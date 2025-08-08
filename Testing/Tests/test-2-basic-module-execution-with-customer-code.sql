/*
* test-2-basic-module-execution-with-custom-code
* Expected outcomes:
* - Module execution is successful
* - EXECUTION_STATUS_CODE = 'Succeeded'
* - INTERNAL_PROCESSING_CODE = 'Proceed'
* - NEXT_RUN_STATUS_CODE = 'Proceed'
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
    ,@ModuleInstanceId                 INT
    ,@ModuleExecutionStatus            NVARCHAR(100)
    ,@ModuleInternalProcessingCode     NVARCHAR(100)
    ,@ModuleNextRunStatus              NVARCHAR(100)
    ,@ModuleExecutedCode               NVARCHAR(MAX)

  BEGIN TRY
    DECLARE @ModuleId INT

	  /* Register the module */
    EXEC [Direct_Framework].[omd].[RegisterModule]
       @ModuleCode = 'test-2-basic-module-execution-with-custom-code'
      ,@ModuleAreaCode = 'MAINT'
      ,@Executable = 'SELECT SYSUTCDATETIME()'
      /* Optional parameters */
      ,@ModuleDescription = 'test-2-basic-module-execution-with-custom-code'
      ,@Debug = 'N'
      /* Output parameters */
      ,@ModuleId = @ModuleId OUTPUT;

    /* Execute the module */
    EXEC [Direct_Framework].[omd].[RunModule]
       @ModuleCode = 'test-2-basic-module-execution-with-custom-code'
      ,@Query = 'SELECT 1 AS [ExecutionResult]'
      ,@Debug = 'N';

    /* Review the outcomes */
    SELECT @ModuleInstanceId = MAX(MODULE_INSTANCE_ID)
    FROM [Direct_Framework].omd.MODULE_INSTANCE
    WHERE MODULE_ID = (SELECT MODULE_ID FROM [Direct_Framework].omd.MODULE WHERE MODULE_CODE = 'test-2-basic-module-execution-with-custom-code')

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
        PRINT '@ModuleExecutionStatus: '+@ModuleExecutionStatus;
        PRINT '@ModuleInternalProcessingCode: '+@ModuleInternalProcessingCode;
        PRINT '@ModuleNextRunStatus: '+@ModuleNextRunStatus;
        PRINT '@ModuleExecutedCode: '+@ModuleExecutedCode;

    IF @ModuleExecutionStatus = 'Succeeded' AND
       @ModuleInternalProcessingCode = 'Proceed' AND
       @ModuleNextRunStatus = 'Proceed' AND
       @ModuleExecutedCode = 'SELECT 1 AS [ExecutionResult]'
      BEGIN
        PRINT 'Succeeded'
      END
    ELSE
      BEGIN
        PRINT 'Failed'
        SET @Issues = @Issues + 1;
      END

    SET @TestOutput = CONVERT(VARCHAR(10),@Issues)+' issues were found.';

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
