/*******************************************************************************
 * [omd].[Queue_Job_Module]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT Framework v2.0 Stored Procedures
 *
 *******************************************************************************
 * !! THIS IS A MSDB-BASED PROCESS,                 !!
 * !! IT ONLY WORKS ON ON-PREMISES TYPE SQL SERVERS !!
 *******************************************************************************
 *
 * Process:
 *   TODO: tba
 *
 * Purpose:
 *   TODO: tba
 *
 * Input:
 *   - TODO: tba
 *
 * Returns:
 *   - TODO: tba
 *
 * Usage:

TODO: tba

 *
 ******************************************************************************/

USE [msdb]
GO

IF EXISTS (SELECT name FROM msdb.dbo.sysjobs WHERE name='Queue_Module')
BEGIN
  EXEC msdb.dbo.sp_delete_job @job_name='Queue_Module', @delete_unused_schedule=1
END

BEGIN TRANSACTION
  DECLARE @ReturnCode INT
  SELECT @ReturnCode = 0

  IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
  BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
  END

  DECLARE @jobId BINARY(16)
  EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Queue_Module',
    @enabled=1,
    @notify_level_eventlog=0,
    @notify_level_email=0,
    @notify_level_netsend=0,
    @notify_level_page=0,
    @delete_level=0,
    @description=N'No description available.',
    @category_name=N'[Uncategorized (Local)]',
    @owner_login_name=N'sa', @job_id = @jobId OUTPUT

  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

  EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Continuous_Integration',
    @step_id=1,
    @cmdexec_success_code=0,
    @on_success_action=1,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N'TSQL',
    @command=N'/*
  Create a temporary in-memory stored procedure that can be used to return the number of currently running processes as per the control framework.
*/
CREATE OR ALTER PROCEDURE #runningJobs
 @NUMBER_OF_RUNNING_PROCESSES INT OUTPUT
AS
(
 SELECT @NUMBER_OF_RUNNING_PROCESSES = (SELECT COUNT(*) FROM [Direct_Framework].omd.MODULE_INSTANCE WHERE EXECUTION_STATUS_CODE=''Executing'')
)
GO

DECLARE @DEBUG_FLAG INT = 1; -- Debug is enabled by default
DECLARE @MAX_CONCURRENCY INT = 2 -- Determines how many processes can be run in parallel / concurrent
DECLARE @NUMBER_OF_RUNNING_PROCESSES INT = 0;
DECLARE @NUMBER_OF_QUEUED_PROCESSES INT = 0;
DECLARE @DELAY_TIME VARCHAR(8) = ''00:00:05'' -- This is the time the queue waits upon detecting concurrency
DECLARE @PROCESS_NAME as VARCHAR(256);
DECLARE @CURRENT_TIMESTAMP VARCHAR(19);
DECLARE @PRINT_MESSAGE VARCHAR(1000);
DECLARE @SQL_STRING NVARCHAR(4000);
DECLARE @ModuleInstanceIdColumnName NVARCHAR(256) = ''AUDIT_TRAIL_ID'';

WHILE 1 = 1
BEGIN
  --Only execute the queue order when the number of executing processes is smaller than the maximum concurrency parameters
  EXEC  #runningJobs @NUMBER_OF_RUNNING_PROCESSES OUTPUT

  SELECT @CURRENT_TIMESTAMP = (SELECT CAST(SYSUTCDATETIME() AS NVARCHAR(19)))
  SELECT @NUMBER_OF_QUEUED_PROCESSES = (SELECT COUNT(*) AS NUMBER_OF_QUEUED_PROCESSED FROM [Direct_Framework].[omd_processing].[vw_QUEUE_MODULE_PROCESSING])

  IF @DEBUG_FLAG = 1  PRINT ''@NUMBER_OF_RUNNING_PROCESSES= ''+CAST (@NUMBER_OF_RUNNING_PROCESSES AS VARCHAR(10))
  IF @DEBUG_FLAG = 1  PRINT ''@MAX_CONCURRENCY= ''+CAST (@MAX_CONCURRENCY AS VARCHAR(10))
  IF @DEBUG_FLAG = 1  PRINT ''@CURRENT_TIMESTAMP = ''+ @CURRENT_TIMESTAMP
  IF @DEBUG_FLAG = 1  PRINT ''@NUMBER_OF_QUEUED_PROCESSES = ''+ +CAST (@NUMBER_OF_QUEUED_PROCESSES AS VARCHAR(10))

  --Whenever the number of jobs exceeds the parameter, wait for a bit (as per the delay time)
  WHILE (@NUMBER_OF_RUNNING_PROCESSES >= @MAX_CONCURRENCY)
  BEGIN
    IF @DEBUG_FLAG =1
    BEGIN
      SET @PRINT_MESSAGE = ''WAITFOR ''+@DELAY_TIME+'', currently still @NUMBER_OF_RUNNING_PROCESSES at ''+CAST (@NUMBER_OF_RUNNING_PROCESSES AS VARCHAR(10))
      RAISERROR (@PRINT_MESSAGE, 0, 1) WITH NOWAIT; -- Raise Error used to flush to the debug window immediately, PRINT has a large delay
    END

    WAITFOR DELAY @DELAY_TIME -- Perform the wait / delay.
    EXEC  #runningJobs @NUMBER_OF_RUNNING_PROCESSES OUTPUT -- Check again if the next process is good to g.
  END

  IF @DEBUG_FLAG =1  PRINT ''After wait @NUMBER_OF_RUNNING_PROCESSES= ''+CAST (@NUMBER_OF_RUNNING_PROCESSES AS VARCHAR(10))
  IF @DEBUG_FLAG =1  PRINT ''After wait @MAX_CONCURRENCY= ''+CAST (@MAX_CONCURRENCY  AS VARCHAR(10))
  IF @DEBUG_FLAG =1  PRINT ''After wait @CURRENT_TIMESTAMP = ''+ @CURRENT_TIMESTAMP

  -- When a spot becomes available, run the process from the queue
  SELECT TOP 1 @PROCESS_NAME  = MODULE_CODE
  FROM
  (
    -- Select the Module that has not run the longest (oldest age)
    SELECT MODULE_CODE, END_TIMESTAMP
    FROM [Direct_Framework].[omd_processing].[vw_QUEUE_MODULE_PROCESSING]
  ) moduleQueue
  ORDER BY END_TIMESTAMP ASC

  IF @PROCESS_NAME IS NULL
    BEGIN
      SET @PRINT_MESSAGE = ''No process was selected / available from the queue'';
    END
    ELSE
    BEGIN

      SET @PRINT_MESSAGE = ''Running process: ''+@PROCESS_NAME

      IF @DEBUG_FLAG =1 RAISERROR (@PRINT_MESSAGE, 0, 1) WITH NOWAIT
      BEGIN TRY
        EXEC [Direct_Framework].[omd].[RunModule] @ModuleCode = @PROCESS_NAME, @ModuleInstanceIdColumnName = @ModuleInstanceIdColumnName
      END TRY
      BEGIN CATCH
        SET @PROCESS_NAME = SUBSTRING(@PROCESS_NAME,1,LEN(@PROCESS_NAME)-5)
        SET @SQL_STRING = N''UPDATE [Direct_Framework].omd.MODULE SET ACTIVE_INDICATOR=''''N'''' WHERE MODULE_CODE=''''''+@PROCESS_NAME+''''''''
        SET @PRINT_MESSAGE = ''ERROR EXECUTING JOB: ''+@PROCESS_NAME+'' DEACTIVATE QUERY: ''+@SQL_STRING+''''
        RAISERROR (@PRINT_MESSAGE, 0, 1) WITH NOWAIT
        EXECUTE sp_executesql @SQL_STRING
      END CATCH
    END

  --Also functions as delayer
  -- This is mandatory! Otherwise processes will be spawned too fast! This prevents the same process to be kicked off many times before OMD has had the chance to register
  WAITFOR DELAY ''00:00:05''
END

DROP PROCEDURE #runningJobs',
    @database_name=N'master',
    @output_file_name=N'D:\Logs\Job_Master',
    @flags=2

    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION
GOTO EndSave

QuitWithRollback:
  IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

EndSave:

GO
