/*
* test-7-module-rollback-test-after-abort-where-previous-instance-failed
* Expected outcomes:
* - If the previous instance failed, the next run triggers rollback
* - EXECUTION_STATUS_CODE (current run) = 'Succeeded'
* - INTERNAL_PROCESSING_CODE (current run) = 'Proceed'
* - NEXT_RUN_STATUS_CODE (current run) = 'Proceed'
* - Previous instance data is removed from the target table during rollback
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
    ,@ModuleCode                       NVARCHAR(200) = 'test-7-module-rollback-test-after-abort-where-previous-instance-failed'
    ,@Executable                       NVARCHAR(MAX) = N'INSERT INTO [Direct_Framework].[omd].[SOURCE_CONTROL]
                                                        (MODULE_ID, MODULE_INSTANCE_ID, START_VALUE, END_VALUE)
                                                      SELECT MODULE_ID, @ModuleInstanceId, ''test-7-start'', ''test-7-end''
                                                      FROM [Direct_Framework].[omd].[MODULE]
                                                      WHERE MODULE_CODE = ''test-7-module-rollback-test-after-abort-where-previous-instance-failed'';'
    ,@OriginalThrowSetting             NVARCHAR(1)
    ,@FirstRunReturnCode               INT
    ,@FirstRunSuccessIndicator         CHAR(1)
    ,@SecondRunReturnCode              INT
    ,@SecondRunSuccessIndicator        CHAR(1)
    ,@FirstModuleInstanceId            BIGINT
    ,@SecondModuleInstanceId           BIGINT
    ,@FirstRunExecutionStatus          NVARCHAR(100)
    ,@FirstRunNextStatus               NVARCHAR(100)
    ,@ModuleId                         INT
    ,@FirstInstanceTargetRows          INT
    ,@SecondInstanceTargetRows         INT;

  BEGIN TRY
    /* Persist current THROW_ON_FAILURE setting and suppress rethrows for the failure setup */
    SELECT @OriginalThrowSetting = [VALUE]
    FROM [Direct_Framework].[omd_metadata].[FRAMEWORK_METADATA]
    WHERE [CODE] = 'THROW_ON_FAILURE';

    IF @OriginalThrowSetting <> 'N'
    BEGIN
      UPDATE [Direct_Framework].[omd_metadata].[FRAMEWORK_METADATA]
      SET [VALUE] = 'N'
      WHERE [CODE] = 'THROW_ON_FAILURE';
    END;

    EXEC [Direct_Framework].[omd].[RegisterModule]
       @ModuleCode = @ModuleCode
      ,@ModuleAreaCode = 'MAINT'
      ,@Executable = @Executable
      ,@ModuleTargetDataObject = 'omd.SOURCE_CONTROL'
      ,@ModuleDescription = 'Regression test 7 - rollback after failure'
      ,@Debug = 'N'
      ,@ModuleId = @ModuleId OUTPUT;

    /* Force a failing execution to create a rollback requirement */
    BEGIN TRY
      EXEC @FirstRunReturnCode = [Direct_Framework].[omd].[RunModule]
         @ModuleCode = @ModuleCode
        ,@Query = 'THROW 50007, ''test-7 forced failure'', 1;'
        ,@SuccessIndicator = @FirstRunSuccessIndicator OUTPUT;
    END TRY
    BEGIN CATCH
      /* THROW_ON_FAILURE forced to N, so an exception means misconfiguration */
      SET @Issues += 1;
    END CATCH;

    SELECT @FirstModuleInstanceId = MAX(MI.MODULE_INSTANCE_ID)
    FROM [Direct_Framework].[omd].[MODULE_INSTANCE] MI
    JOIN [Direct_Framework].[omd].[MODULE] M ON M.MODULE_ID = MI.MODULE_ID
    WHERE M.MODULE_CODE = @ModuleCode;

    SELECT
         @FirstRunExecutionStatus = MI.EXECUTION_STATUS_CODE
        ,@FirstRunNextStatus = MI.NEXT_RUN_STATUS_CODE
    FROM [Direct_Framework].[omd].[MODULE_INSTANCE] MI
    WHERE MI.MODULE_INSTANCE_ID = @FirstModuleInstanceId;

    IF ISNULL(@FirstRunExecutionStatus, '') <> 'Failed'
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@FirstRunNextStatus, '') <> 'Rollback'
    BEGIN
      SET @Issues += 1;
    END;

    IF @FirstModuleInstanceId IS NOT NULL
    BEGIN
      /* Ensure there is rollback work by inserting a target row for the failed instance */
      DELETE FROM [Direct_Framework].[omd].[SOURCE_CONTROL]
      WHERE MODULE_INSTANCE_ID = @FirstModuleInstanceId;

      INSERT INTO [Direct_Framework].[omd].[SOURCE_CONTROL]
        (MODULE_ID, MODULE_INSTANCE_ID, START_VALUE, END_VALUE)
      VALUES
        (@ModuleId, @FirstModuleInstanceId, 'rollback-start', 'rollback-end');

      SELECT @FirstInstanceTargetRows = COUNT(*)
      FROM [Direct_Framework].[omd].[SOURCE_CONTROL]
      WHERE MODULE_INSTANCE_ID = @FirstModuleInstanceId;

      IF ISNULL(@FirstInstanceTargetRows, 0) <> 1
      BEGIN
        SET @Issues += 1;
      END;
    END
    ELSE
    BEGIN
      SET @Issues += 1;
    END;

    /* Restore THROW_ON_FAILURE to its original value before the success run */
    IF @OriginalThrowSetting IS NOT NULL
    BEGIN
      UPDATE [Direct_Framework].[omd_metadata].[FRAMEWORK_METADATA]
      SET [VALUE] = @OriginalThrowSetting
      WHERE [CODE] = 'THROW_ON_FAILURE';
    END;

    EXEC @SecondRunReturnCode = [Direct_Framework].[omd].[RunModule]
       @ModuleCode = @ModuleCode
      ,@SuccessIndicator = @SecondRunSuccessIndicator OUTPUT;

    SELECT @SecondModuleInstanceId = MAX(MI.MODULE_INSTANCE_ID)
    FROM [Direct_Framework].[omd].[MODULE_INSTANCE] MI
    JOIN [Direct_Framework].[omd].[MODULE] M ON M.MODULE_ID = MI.MODULE_ID
    WHERE M.MODULE_CODE = @ModuleCode;

    SELECT
         @ModuleExecutionStatus = MI.EXECUTION_STATUS_CODE
        ,@ModuleInternalProcessingCode = MI.INTERNAL_PROCESSING_CODE
        ,@ModuleNextRunStatus = MI.NEXT_RUN_STATUS_CODE
    FROM [Direct_Framework].[omd].[MODULE_INSTANCE] MI
    WHERE MI.MODULE_INSTANCE_ID = @SecondModuleInstanceId;

    SELECT @ModuleExecutedCode = EC.EXECUTED_CODE
    FROM [Direct_Framework].[omd].[MODULE_INSTANCE_EXECUTED_CODE] EC
    JOIN [Direct_Framework].[omd].[MODULE_INSTANCE] MI
      ON MI.EXECUTED_CODE_CHECKSUM = EC.[CHECKSUM]
    WHERE MI.MODULE_INSTANCE_ID = @SecondModuleInstanceId;

    SELECT @FirstInstanceTargetRows = COUNT(*)
    FROM [Direct_Framework].[omd].[SOURCE_CONTROL]
    WHERE MODULE_INSTANCE_ID = @FirstModuleInstanceId;

    SELECT @SecondInstanceTargetRows = COUNT(*)
    FROM [Direct_Framework].[omd].[SOURCE_CONTROL]
    WHERE MODULE_INSTANCE_ID = @SecondModuleInstanceId;

    IF @SecondModuleInstanceId IS NULL
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleExecutionStatus, '') <> 'Succeeded'
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleInternalProcessingCode, '') <> 'Proceed'
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@ModuleNextRunStatus, '') <> 'Proceed'
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@SecondRunSuccessIndicator, '') <> 'Y'
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@SecondRunReturnCode, -1) <> 0
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@FirstInstanceTargetRows, -1) <> 0
    BEGIN
      SET @Issues += 1;
    END;

    IF ISNULL(@SecondInstanceTargetRows, 0) <> 1
    BEGIN
      SET @Issues += 1;
    END;

    IF CHARINDEX('test-7-start', ISNULL(@ModuleExecutedCode, '')) = 0
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

  BEGIN TRY
    /* Cleanup */
    IF @OriginalThrowSetting IS NOT NULL
    BEGIN
      UPDATE [Direct_Framework].[omd_metadata].[FRAMEWORK_METADATA]
      SET [VALUE] = @OriginalThrowSetting
      WHERE [CODE] = 'THROW_ON_FAILURE';
    END;

    DELETE FROM [Direct_Framework].[omd].[SOURCE_CONTROL]
    WHERE MODULE_INSTANCE_ID IN (@FirstModuleInstanceId, @SecondModuleInstanceId);
  END TRY
  BEGIN CATCH
    SET @TestOutput = CONCAT('Cleanup failure: ', ERROR_MESSAGE());
    SET @TestResult = 'Fail';
  END CATCH;

  SELECT @TestOutput AS [OUTPUT], @TestResult AS [RESULT];
END
