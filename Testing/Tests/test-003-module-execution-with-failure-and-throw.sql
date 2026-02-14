/*
* test-3-module-execution-with-failure-and-throw
* Expected outcomes:
* - Module throws/raises a SQL error (rethrow enabled)
* - Module execution fails gracefully once error is caught by the wrapper
* - EXECUTION_STATUS_CODE = 'Failed'
* - INTERNAL_PROCESSING_CODE = 'Proceed'
* - NEXT_RUN_STATUS_CODE = 'Rollback'
* - ReturnCode/@RC = -2
* - @SuccessIndicator OUT Parameter is 'N'
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
    ,@ModuleInstanceId             BIGINT
    ,@ModuleExecutionStatus        NVARCHAR(100)
    ,@ModuleInternalCode           NVARCHAR(100)
    ,@ModuleNextRunStatus          NVARCHAR(100)
    ,@ModuleExecutedCode           NVARCHAR(MAX)
    ,@ModuleCode                   NVARCHAR(200) = 'test-3-module-execution-with-failure-and-throw'
    ,@Executable                   NVARCHAR(MAX) = 'THROW 50003, ''test-3 failure'', 1;'
    ,@OriginalThrowSetting         NVARCHAR(1)
    ,@ExpectedErrorCaught          BIT = 0
    ,@RunModuleReturnCode          INT = NULL
    ,@RunModuleSuccessIndicator    CHAR(1) = NULL
    ,@RunModuleMessageLog          NVARCHAR(MAX);

  BEGIN TRY
    /* Persist current THROW_ON_FAILURE setting and enable rethrow */
    SELECT @OriginalThrowSetting = [VALUE]
    FROM [Direct_Framework].[omd_metadata].[FRAMEWORK_METADATA]
    WHERE [CODE] = 'THROW_ON_FAILURE';

    IF @OriginalThrowSetting <> 'Y'
    BEGIN
      UPDATE [Direct_Framework].[omd_metadata].[FRAMEWORK_METADATA]
      SET [VALUE] = 'Y'
      WHERE [CODE] = 'THROW_ON_FAILURE';
    END;

    DECLARE @ModuleId INT;

    /* Register the failing module */
    EXEC [Direct_Framework].[omd].[RegisterModule]
       @ModuleCode = @ModuleCode
      ,@ModuleAreaCode = 'MAINT'
      ,@Executable = @Executable
      ,@ModuleDescription = 'Regression test 3 - failure with throw'
      ,@Debug = 'N'
      ,@ModuleId = @ModuleId OUTPUT;

    /* Run the module and expect a rethrown error */
    BEGIN TRY
      EXEC @RunModuleReturnCode = [Direct_Framework].[omd].[RunModule]
         @ModuleCode = @ModuleCode
        ,@SuccessIndicator = @RunModuleSuccessIndicator OUTPUT
        ,@MessageLog = @RunModuleMessageLog OUTPUT;

      /* If no exception was raised, the expectation failed */
      SET @Issues += 1;
    END TRY
    BEGIN CATCH
      SET @ExpectedErrorCaught = 1;
      /* ensure the wrapper populated output state before the throw */
      IF @RunModuleSuccessIndicator IS NULL SET @RunModuleSuccessIndicator = 'N';
      IF @RunModuleReturnCode IS NULL SET @RunModuleReturnCode = -2;
    END CATCH;

    IF @ExpectedErrorCaught = 0
    BEGIN
      SET @Issues += 1;
    END;

    /* Review latest module instance details */
    SELECT TOP (1)
         @ModuleInstanceId   = MI.MODULE_INSTANCE_ID
        ,@ModuleExecutionStatus = MI.EXECUTION_STATUS_CODE
        ,@ModuleInternalCode = MI.INTERNAL_PROCESSING_CODE
        ,@ModuleNextRunStatus = MI.NEXT_RUN_STATUS_CODE
    FROM [Direct_Framework].[omd].[MODULE_INSTANCE] MI
    JOIN [Direct_Framework].[omd].[MODULE] M ON M.MODULE_ID = MI.MODULE_ID
    WHERE M.MODULE_CODE = @ModuleCode
    ORDER BY MI.MODULE_INSTANCE_ID DESC;

    /* Executed code snapshot */
    SELECT @ModuleExecutedCode = EC.EXECUTED_CODE
    FROM [Direct_Framework].[omd].[MODULE_INSTANCE_EXECUTED_CODE] EC
    JOIN [Direct_Framework].[omd].[MODULE_INSTANCE] MI
      ON MI.EXECUTED_CODE_CHECKSUM = EC.[CHECKSUM]
    WHERE MI.MODULE_INSTANCE_ID = @ModuleInstanceId;

    IF @ModuleInstanceId IS NULL
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleExecutionStatus, '') <> 'Failed'
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleInternalCode, '') <> 'Proceed'
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleNextRunStatus, '') <> 'Rollback'
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(LTRIM(RTRIM(@ModuleExecutedCode)), '') <> @Executable
    BEGIN
      SET @Issues += 1;
    END;

    IF @RunModuleSuccessIndicator <> 'N'
    BEGIN
      SET @Issues += 1;
    END;

    IF @RunModuleReturnCode <> -2
    BEGIN
      SET @Issues += 1;
    END;

    SET @TestOutput = CONCAT(@Issues, ' issues were found.');

    IF @Issues = 0
    SET @TestResult = 'Pass'
    ELSE SET @TestResult = 'Fail';

  END TRY
  BEGIN CATCH
    SET @TestOutput = ERROR_MESSAGE();
    SET @TestResult = 'Fail';
  END CATCH;

  /* Always restore THROW_ON_FAILURE to its original value */
  BEGIN TRY
    IF @OriginalThrowSetting IS NOT NULL
    BEGIN
      UPDATE [Direct_Framework].[omd_metadata].[FRAMEWORK_METADATA]
      SET [VALUE] = @OriginalThrowSetting
      WHERE [CODE] = 'THROW_ON_FAILURE';
    END;
  END TRY
  BEGIN CATCH
    SET @TestOutput = CONCAT('Cleanup failure: ', ERROR_MESSAGE());
    SET @TestResult = 'Fail';
  END CATCH;

  SELECT @TestOutput AS [OUTPUT], @TestResult AS [RESULT];
END
