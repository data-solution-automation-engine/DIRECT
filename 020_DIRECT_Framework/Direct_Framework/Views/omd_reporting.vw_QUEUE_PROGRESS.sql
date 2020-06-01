create view omd_reporting.vw_QUEUE_PROGRESS
/***
Purpose: List accumulated load times for all modules in the last 24 hours.
***/
as

select MODULE.MODULE_CODE
	, MODULE.INACTIVE_INDICATOR as inactive
	, coalesce(SSIS_detail.status_desc, 'package execution not found') as SSIS_status
	, case MODULE_INSTANCE.EXECUTION_STATUS_CODE
            when 'S' then 'Succeeded'
            when 'E' then 'Executing'
            when 'F' then 'Failed'
            when 'A' then 'Aborted'
            else EXECUTION_STATUS_CODE
            end as OMD_status
	, MODULE_INSTANCE.START_DATETIME as start_time
	, case when MODULE_INSTANCE.END_DATETIME is null and EXECUTION_STATUS_CODE != 'E' then ''
        else (
		    select case when datediff(day, MODULE_INSTANCE.START_DATETIME, coalesce(MODULE_INSTANCE.END_DATETIME, getdate())) > 5
						    then 'previously aborted' -- avoid datatype overflow error
					     else (
						      select convert(varchar(30), dateadd(second, time_sec, 0), 108)
						      from	(
								    select datediff(second, MODULE_INSTANCE.START_DATETIME, coalesce(MODULE_INSTANCE.END_DATETIME, getdate())) as time_sec
								    ) sq
						      ) end
		    ) end as instance_duration
	, MODULE_INSTANCE.ROWS_INSERTED as rows_transferred
    , ACCUMULATIVE_LOAD_TIME_VW.rows_transferred as accum_rows_transferred
    , ACCUMULATIVE_LOAD_TIME_VW.duration as accum_load_time
    , ACCUMULATIVE_LOAD_TIME_VW.instances_run
	--, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR
	, MODULE_INSTANCE.MODULE_INSTANCE_ID
    , SSIS_detail.execution_id as SSIS_Id
	, SOURCE_CONTROL.INTERVAL_START_DATETIME
	, SOURCE_CONTROL.INTERVAL_END_DATETIME
	, event_log.EVENT_DETAIL
from omd.MODULE
	left join   (
        select MODULE_INSTANCE.*
        from omd.MODULE_INSTANCE
	        inner join ( /* filter to last instance of each module */
			        select MODULE_INSTANCE.MODULE_INSTANCE_ID
				        , row_number() over (partition by MODULE_INSTANCE.MODULE_ID
										        /* last time something interesting happened */
										        --order by case when (ROWS_INSERTED > 0 or EXECUTION_STATUS_CODE = 'E') then 10000000000 + MODULE_INSTANCE.MODULE_INSTANCE_ID else MODULE_INSTANCE.MODULE_INSTANCE_ID end desc) as rn
										        /* last run */
										        order by MODULE_INSTANCE.MODULE_INSTANCE_ID desc) as rn
			        from omd.MODULE_INSTANCE
			        ) instance_of_interest
		        on instance_of_interest.MODULE_INSTANCE_ID = MODULE_INSTANCE.MODULE_INSTANCE_ID
		        and instance_of_interest.rn = 1
        ) MODULE_INSTANCE
		on MODULE_INSTANCE.MODULE_ID = MODULE.MODULE_ID
	left join (
            select SOURCE_CONTROL.*
            from omd.SOURCE_CONTROL
            ) SOURCE_CONTROL
		on SOURCE_CONTROL.MODULE_INSTANCE_ID = MODULE_INSTANCE.MODULE_INSTANCE_ID
	left join (
			select EVENT_LOG.MODULE_INSTANCE_ID
				, EVENT_LOG.EVENT_DETAIL
				, row_number() over (partition by MODULE_INSTANCE_ID order by EVENT_ID asc) as rn
			from omd.EVENT_LOG
			) event_log
		on event_log.MODULE_INSTANCE_ID = MODULE_INSTANCE.MODULE_INSTANCE_ID
		and event_log.rn = 1
    outer apply (
				select top 1
                    executions.execution_id,
                    case executions.[status]
                    when 1 then 'Created Execution'
                    when 2 then 'Running'
                    when 3 then 'Cancelled'
                    when 4 then 'Failed'
                    when 5 then 'Pending Exectution'
                    when 6 then 'Unexpected Termination'
                    when 7 then 'Succeeded'
                    when 8 then 'Stopping'
                    when 9 then 'Completed'
                    end as status_desc
				from SSISDB.[catalog].executions
				where executions.package_name = MODULE.MODULE_CODE + '.dtsx' collate SQL_Latin1_General_CP1_CI_AS
				order by executions.execution_id desc
				) SSIS_detail
    left join omd_reporting.ACCUMULATIVE_LOAD_TIME_VW
        on ACCUMULATIVE_LOAD_TIME_VW.MODULE_CODE = MODULE.MODULE_CODE;
