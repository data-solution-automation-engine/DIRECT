/*
* test-1-basic-module-execution
* Expected outcomes:
* - Module execution is succesfull.
* - EXECUTION_STATUS_CODE = 'Succeeded'
* - INTERNAL_PROCESSING_CODE = 'Proceed'
* - NEXT_RUN_STATUS_CODE = 'Proceed'
*/

BEGIN
  /* Required for testing framework */
  DECLARE
     @TestResult CHAR(4) = 'Fail'
    ,@TestOutput VARCHAR(MAX);

  /* Local */
  DECLARE
     @Issues INT = 0
    ,@CurrentModuleInstanceId                 INT
    ,@CurrentModuleExecutionStatus            NVARCHAR(100)
    ,@CurrentModuleInternalProcessingCode     NVARCHAR(100)
    ,@CurrentModuleNextRunStatus              NVARCHAR(100)

  BEGIN TRY
    DECLARE @ModuleId INT

	  /* Register the module */
    EXEC [Direct_Framework].[omd].[RegisterModule]
       @ModuleCode = 'test-1-basic-module-execution'
      ,@ModuleAreaCode = 'MAINT'
      ,@Executable = 'SELECT SYSUTCDATETIME()'
      /* Optional parameters */
      ,@ModuleDescription = 'test-1-basic-module-execution'
      ,@Debug = 'Y'
      /* Output parameters */
      ,@ModuleId = @ModuleId OUTPUT;

    /* Execute the module */
    EXEC [Direct_Framework].[omd].[RunModule]
       @ModuleCode = 'test-1-basic-module-execution'
      ,@Debug = 'Y';

    /* Review the outcomes */
    SELECT @CurrentModuleInstanceId = MAX(MODULE_INSTANCE_ID)
    FROM [Direct_Framework].omd.MODULE_INSTANCE
    WHERE MODULE_ID = (SELECT MODULE_ID FROM [Direct_Framework].omd.MODULE WHERE MODULE_CODE = 'test-1-basic-module-execution')

    SELECT
       @CurrentModuleExecutionStatus = EXECUTION_STATUS_CODE
      ,@CurrentModuleInternalProcessingCode = INTERNAL_PROCESSING_CODE
      ,@CurrentModuleNextRunStatus = NEXT_RUN_STATUS_CODE
    FROM [Direct_Framework].omd.MODULE_INSTANCE
    WHERE MODULE_INSTANCE_ID = @CurrentModuleInstanceId;

    IF @CurrentModuleExecutionStatus = 'Succeeded' AND
       @
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
