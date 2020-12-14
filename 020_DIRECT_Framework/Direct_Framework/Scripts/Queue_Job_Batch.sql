USE [msdb]
GO

IF EXISTS (SELECT name FROM msdb.dbo.sysjobs WHERE name='Queue_Batch')
EXEC msdb.dbo.sp_delete_job @job_name='Queue_Batch', @delete_unused_schedule=1

/****** Object:  Job [Queue_Batch]    Script Date: 4/3/2020 8:06:05 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/3/2020 8:06:05 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Queue_Batch', 
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
/****** Object:  Step [Continuous_Integration]    Script Date: 4/3/2020 8:06:06 PM ******/
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
                                @command=N'CREATE PROCEDURE #runningJobs @NUM_JOBS int OUTPUT   AS 
(      
 SELECT @NUM_JOBS = (SELECT COUNT(*) FROM [900_Direct_Framework].omd.MODULE_INSTANCE WHERE EXECUTION_STATUS_CODE=''E'')
)
GO
--Only execute the queue order when the number of executing ETLs is smaller than the maximum concurrency parameters

DECLARE @DEBUG_FLAG INT
DECLARE @MAX_CONCURRENCY INT
DECLARE @NUM_RUNNING_JOBS INT
DECLARE @DELAY_TIME VARCHAR(8)
DECLARE @JOBNAME as VARCHAR(256)
DECLARE @CURRENT_TIME VARCHAR(19)
DECLARE @PRINT_MSG VARCHAR(1000)
DECLARE @SQL_STRING NVARCHAR(4000)
SELECT @MAX_CONCURRENCY = 5
SELECT @DELAY_TIME =''00:00:05'' -- This is the time the queue waits upon detecting concurrency
SELECT @DEBUG_FLAG =0

WHILE 1 = 1
BEGIN
       EXEC  #runningJobs @NUM_RUNNING_JOBS OUTPUT
          SELECT @CURRENT_TIME = (SELECT CAST(SYSDATETIME() AS VARCHAR(19)))
       IF @DEBUG_FLAG =1  PRINT ''Initial @NUM_RUNNING_JOBS= ''+CAST (@NUM_RUNNING_JOBS AS VARCHAR(10))
       IF @DEBUG_FLAG =1  PRINT ''Initial @MAX_CONCURRENCY= ''+CAST (@MAX_CONCURRENCY  AS VARCHAR(10))
          IF @DEBUG_FLAG =1  PRINT ''Initial Log Date/Time = ''+ @CURRENT_TIME
       --Whenever the number of jobs exceeds the parameter, wait for a bit (as per the delay time)
       WHILE (@NUM_RUNNING_JOBS >= @MAX_CONCURRENCY)
       BEGIN
              IF @DEBUG_FLAG =1  
                           SET @PRINT_MSG = ''WAITFOR ''+@DELAY_TIME+'', currently still @NUM_RUNNING_JOBS at ''+CAST (@NUM_RUNNING_JOBS AS VARCHAR(10))
                           RAISERROR (@PRINT_MSG, 0, 1) WITH NOWAIT; -- Raise Error used to flush to the debug window immediately, PRINT has a large delay
              WAITFOR DELAY @DELAY_TIME
              EXEC  #runningJobs @NUM_RUNNING_JOBS OUTPUT
       END
       IF @DEBUG_FLAG =1  PRINT ''After wait @NUM_RUNNING_JOBS= ''+CAST (@NUM_RUNNING_JOBS AS VARCHAR(10))
       IF @DEBUG_FLAG =1  PRINT ''After wait @MAX_CONCURRENCY= ''+CAST (@MAX_CONCURRENCY  AS VARCHAR(10))
          IF @DEBUG_FLAG =1  PRINT ''After wait Log Date/Time = ''+ @CURRENT_TIME
       -- When a spot becomes available, run the next ETL(s) from the queue
       SELECT TOP 1 @JOBNAME  = ETL_PROCESS_NAME
       FROM 
       
       (   -- Select the Batch that hasn''t run the longest (oldest age) 
                 SELECT *
                 FROM [900_Direct_Framework].[omd_processing].[vw_QUEUE_BATCH_PROCESSING]
          ) ETL_QUERY
           ORDER BY END_DATETIME ASC
       
          SET @PRINT_MSG = ''EXECUTING JOB: ''+@JOBNAME

       IF @DEBUG_FLAG =1  RAISERROR (@PRINT_MSG, 0, 1) WITH NOWAIT
          BEGIN TRY
          Declare @execution_id bigint
          EXEC [SSISDB].[catalog].[create_execution] @package_name=@JOBNAME, @execution_id=@execution_id OUTPUT, @folder_name=N''EDW'', @project_name=N''Enterprise_Data_Warehouse'', @use32bitruntime=False, @reference_id=Null
          Select @execution_id
          DECLARE @var0 smallint = 1
          EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id,  @object_type=50, @parameter_name=N''LOGGING_LEVEL'', @parameter_value=@var0
          EXEC [SSISDB].[catalog].[start_execution] @execution_id
       END TRY
          BEGIN CATCH
             SET @JOBNAME = SUBSTRING(@JOBNAME,1,LEN(@JOBNAME)-5)
                SET @SQL_STRING = N''UPDATE [900_Direct_Framework].omd.BATCH SET INACTIVE_INDICATOR=''''Y'''' WHERE BATCH_CODE=''''''+@JOBNAME+''''''''
                SET @PRINT_MSG = ''ERROR EXECUTING JOB: ''+@JOBNAME+''.dtsx. DEACTIVATE QUERY: ''+@SQL_STRING+''''
                RAISERROR (@PRINT_MSG, 0, 1) WITH NOWAIT
                EXECUTE sp_executesql @SQL_STRING
       END CATCH

          --Also functions as delayer
          WAITFOR DELAY ''00:00:05'' -- This is mandatory! Otherwise processes will be spawned too fast! This prevents the same process to be kicked off many times before OMD has had the chance to register
END
DROP PROCEDURE #runningJobs
', 
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