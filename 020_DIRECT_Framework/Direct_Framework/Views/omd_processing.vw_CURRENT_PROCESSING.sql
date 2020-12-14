create view omd_processing.vw_CURRENT_PROCESSING
/***
Purpose: List packages currently running. Either from the project and folder in the SSIS 
         catalog associated with loading this database, or by the OMD execution status.
         Created separately due to reliance on SSISDB.
***/
as

select coalesce(check_ssis.MODULE_CODE, check_omd.MODULE_CODE) as MODULE_CODE,
    check_ssis.SSIS_execution_status,
    check_ssis.start_time as SSIS_start_time,
    check_omd.EXECUTION_STATUS_CODE as OMD_execution_status,
    check_omd.START_DATETIME as OMD_start_time
from    (
        select MODULE.MODULE_CODE,
            current_instance.EXECUTION_STATUS_CODE,
            current_instance.START_DATETIME
        from omd.MODULE
            left join   (
                select MODULE_INSTANCE.*
                from omd.MODULE_INSTANCE
                    inner join ( /* filter to last instance of each module */
                            select agg.MODULE_ID,
                                max(agg.MODULE_INSTANCE_ID) as MODULE_INSTANCE_ID
                            from omd.MODULE_INSTANCE agg
                            group by agg.MODULE_ID
                            ) prev_instances
                        on prev_instances.MODULE_ID = MODULE_INSTANCE.MODULE_ID
                        and prev_instances.MODULE_INSTANCE_ID = MODULE_INSTANCE.MODULE_INSTANCE_ID
                ) current_instance
                on current_instance.MODULE_ID = MODULE.MODULE_ID
        where current_instance.EXECUTION_STATUS_CODE = 'E' /* executing according to OMD */
        ) check_omd
    /* full outer join includes packages from SSIS folder running without OMD registration */
    full join   (
            select replace(executions.package_name collate database_default, N'.dtsx', N'') as MODULE_CODE,
                coalesce(case executions.[status]
                            when 1 then 'Created Execution'
                            when 2 then 'Running'
                            when 3 then 'Cancelled'
                            when 4 then 'Failed'
                            when 5 then 'Pending Exectution'
                            when 6 then 'Unexpected Termination'
                            when 7 then 'Succeeded'
                            when 8 then 'Stopping'
                            when 9 then 'Completed'
                            end, 'package execution not found') as SSIS_execution_status,
                executions.start_time
            from [$(SSISDB)].[catalog].executions
                --inner join omd.ENVIRONMENT
                --    on ENVIRONMENT.FOLDER_NAME collate database_default = executions.folder_name
                --    and ENVIRONMENT.PROJECT_NAME collate database_default = executions.project_name
            where executions.end_time is null
            ) check_ssis
        on check_ssis.MODULE_CODE = check_omd.MODULE_CODE;
