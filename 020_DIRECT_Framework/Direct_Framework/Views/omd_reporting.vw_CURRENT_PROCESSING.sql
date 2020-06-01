create view omd_report.CURRENT_PROCESSING_VW
/***
Purpose: List items currently processing according to either the SSIS catalog, or OMD.
***/
as

select CURRENT_PROCESSING_VW.MODULE_CODE,
    CURRENT_PROCESSING_VW.SSIS_execution_status,
    CURRENT_PROCESSING_VW.SSIS_start_time,
    CURRENT_PROCESSING_VW.OMD_execution_status,
    CURRENT_PROCESSING_VW.OMD_start_time,
    MODULE.INACTIVE_INDICATOR as OMD_is_inactive,
    omd.AREA_DATABASE_FN(MODULE.SOURCE_AREA_CODE) + N'.' + MODULE.SOURCE_SCHEMA + N'.' + MODULE.SOURCE_OBJECT as loading_from,    
    db_name() + N'.' + MODULE.TARGET_SCHEMA + N'.' + MODULE.TARGET_OBJECT as loading_to
from omd_process.CURRENT_PROCESSING_VW
    left join omd.MODULE
        on MODULE.MODULE_CODE = CURRENT_PROCESSING_VW.MODULE_CODE;
