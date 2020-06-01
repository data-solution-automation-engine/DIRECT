create function omd_processing.NextModuleInQueue (
    @loop_started datetime
    )
/***
Purpose: Provide the next to run from an ordered list of packages to be processed. So that will process the 'oldest' first.
         Avoids attempting to process when already running.
         Avoids processing when already processing another module which writes to the same destination.
         Avoids processing a module until all dependencies have been processed.
         Packages not registered in OMD will not be included.
         It is required to filter this view by the start date (@loop_started) in order to correctly handle dependency ordering.
***/
returns table
as return
-----------------------------------------------------------------------------------------------------------

/* based on dependencies determine the next package which should be started */
with cteModules
as  (
    select 
        MODULE.MODULE_ID,
        MODULE.MODULE_CODE,
        MODULE.DATA_OBJECT_TARGET,
        case when processing.MODULE_CODE is null then 'N' else 'Y' end as is_executing,
        coalesce(latest_instance.END_DATETIME, '1900-01-01') as END_DATETIME
    from omd.MODULE
        left join omd_processing.vw_CURRENT_PROCESSING processing on processing.MODULE_CODE = omd.MODULE.MODULE_CODE
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
            ) latest_instance
            on latest_instance.MODULE_ID = MODULE.MODULE_ID
    where MODULE.INACTIVE_INDICATOR = 'N'
        and MODULE.MODULE_ID != 0
    )

/* return results (via output params) */
select top 1 MODULE_CODE as module_code
from (
    select 
        MODULE_ID,
        MODULE_CODE,
        END_DATETIME,
        row_number() over (order by END_DATETIME asc, MODULE_CODE asc) as QUEUE_ORDER
    from cteModules
    where cteModules.is_executing = 'N' /* module is not executing */
        --and not exists ( /* check for dependencies which have not yet started, or still executing */
        --            select null
        --            from omd_processing.PACKAGE_LOCAL_DEPENDENCIES_VW has_dependency
        --                inner join cteModules dependency_status
        --                    on dependency_status.MODULE_CODE = has_dependency.MODULE_CODE_DEPENDANT_ON
        --                    and (dependency_status.END_DATETIME < @loop_started
        --                        or dependency_status.is_executing = 'Y')
		      --      where has_dependency.MODULE_CODE = cteModules.MODULE_CODE
        --            )
        and not exists ( /* check execution of other modules writing to the same target */
                    select null
                    from cteModules same_target
                    where same_target.is_executing = 'Y'
                      and same_target.DATA_OBJECT_TARGET = cteModules.DATA_OBJECT_TARGET
                    )
    ) results
where END_DATETIME < @loop_started /* run through exactly once only, schedule to restart regularly if required */
order by QUEUE_ORDER asc;
