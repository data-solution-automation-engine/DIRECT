create view omd_reporting.vw_CUMULATIVE_LOAD_TIME
/***
Purpose: List accumulated load times for all modules. Handles if a table 
         has been reloaded.
***/
as

with pre_formatting
as  (
    select MODULE.MODULE_CODE,
        count(*) as instances_run,
        sum(datediff(second, MODULE_INSTANCE.START_DATETIME, coalesce(MODULE_INSTANCE.END_DATETIME, getdate()))) as duration_sec,
        sum(cast(MODULE_INSTANCE.ROWS_INSERTED as bigint)) as rows_transferred
    from omd.MODULE
    inner join omd.MODULE_INSTANCE on omd.MODULE_INSTANCE.MODULE_ID = omd.MODULE.MODULE_ID
    inner join (
                select 
                    MODULE_INSTANCE.MODULE_ID
                  , max(SOURCE_CONTROL.MODULE_INSTANCE_ID) as MODULE_INSTANCE_ID
                from omd.SOURCE_CONTROL
                inner join omd.MODULE_INSTANCE on omd.MODULE_INSTANCE.MODULE_INSTANCE_ID = omd.SOURCE_CONTROL.MODULE_INSTANCE_ID
                where omd.SOURCE_CONTROL.INTERVAL_START_DATETIME = '1900-01-01 00:00:00.0000000'
                group by MODULE_INSTANCE.MODULE_ID
                ) last_reloaded
            on last_reloaded.MODULE_ID = MODULE_INSTANCE.MODULE_ID
            and last_reloaded.MODULE_INSTANCE_ID <= MODULE_INSTANCE.MODULE_INSTANCE_ID
    group by omd.MODULE.MODULE_CODE
    )

select
    MODULE_CODE,
    instances_run,
    duration_sec,
    isnull(cast(nullif(datepart(day, dateadd(second, duration_sec, 0)), 1) - 1 as varchar(10)) + ' days ', '')
        +  convert(varchar(30), dateadd(second, duration_sec, 0), 108) as duration,
    rows_transferred
from pre_formatting;
