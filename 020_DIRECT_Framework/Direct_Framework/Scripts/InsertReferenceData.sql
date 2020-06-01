/*
  Reference data
  DIRECT model revision 21
*/

set nocount on;

/* Layer */
insert into omd.LAYER
select *
from (
		/* LAYER_CODE, LAYER_DESCRIPTION */
    values (N'Integration', N'The Integration Layer')
         , (N'Presentation', N'The Presentation Layer')
         , (N'Staging', N'The Staging Layer')
	     , (N'Maintenance', N'Internal Data Solution')
    ) as refData(LAYER_CODE, LAYER_DESCRIPTION)
where not exists (
        select null
        from omd.LAYER
        where LAYER.LAYER_CODE = refData.LAYER_CODE
        );

/* Area */
insert into omd.AREA
select *
from (
          /* AREA_CODE, LAYER_CODE, AREA_DESCRIPTION */
    values (N'HELPER', N'Presentation', N'The Helper Area')
         , (N'PSA', N'Staging', N'The Persistent Staging Area')
         , (N'INT', N'Integration', N'The Integration Area')
         , (N'INTPR', N'Integration', N'The Interpretation Area')
         , (N'PRES', N'Presentation', N'The Presentation Area')
         , (N'STG', N'Staging', N'The Staging Area of the Staging Layer')
         , (N'SYNC', N'Staging', N'Syncronising of the production History Area of the Staging Layer for build and test')
         , (N'Maintenance', N'Maintenance', N'Internal Data Solution')
    ) as refData(AREA_CODE, LAYER_CODE, AREA_DESCRIPTION)
where not exists (
        select null
        from omd.AREA
        where omd.AREA.AREA_CODE = refData.AREA_CODE
        );

/* Execution Status */
insert into omd.EXECUTION_STATUS
select *
from (
          /* EXECUTION_STATUS_CODE, EXECUTION_STATUS_DESCRIPTION */
    values (N'A', N'Aborted')
         , (N'C', N'Cancelled / skipped')
         , (N'E', N'Executing')
         , (N'F', N'Failure')
         , (N'S', N'Succes')
    ) as refData(EXECUTION_STATUS_CODE, EXECUTION_STATUS_DESCRIPTION)
where not exists (
        select null
        from omd.EXECUTION_STATUS
        where omd.EXECUTION_STATUS.EXECUTION_STATUS_CODE = refData.EXECUTION_STATUS_CODE
        );

/* Next Run Indicator */
insert into omd.NEXT_RUN_INDICATOR
select *
from (
          /* NEXT_RUN_INDICATOR, NEXT_RUN_INDICATOR_DESCRIPTION */
    values (N'C', N'Cancelled / skipped. Administrators can manually set this code to for the Next Run Indicator.')
        , (N'P', N'Proceed. The next run of the Batch/Module to set to continue processing.')
        , (N'R', N'Rollback . Upon failure the Next Run Indicator is updated to ‘R’ to signal a rollback.')
    ) as refData(NEXT_RUN_INDICATOR, NEXT_RUN_INDICATOR_DESCRIPTION)
where not exists (
        select null
        from omd.NEXT_RUN_INDICATOR
        where omd.NEXT_RUN_INDICATOR.NEXT_RUN_INDICATOR = refData.NEXT_RUN_INDICATOR
        );

/* Processing Indicator */
insert into omd.PROCESSING_INDICATOR
select *
from (
          /* PROCESSING_INDICATOR, PROCESSING_INDICATOR_DESCRIPTION */
    values (N'A', N'Abort. This indicates that the Batch/Module is already running.')
         , (N'C', N'Cancel / skip. The process has determined that it is not necessary to run this ETL process.')
         , (N'P', N'Proceed. The Instance can continue on to the next step of the processing.')
         , (N'R', N'Rollback. During rollback processing the Processor Indicator is set to R.')
    ) as refData(PROCESSING_INDICATOR, PROCESSING_INDICATOR_DESCRIPTION)
where not exists (
        select null
        from omd.PROCESSING_INDICATOR
        where omd.PROCESSING_INDICATOR.PROCESSING_INDICATOR = refData.PROCESSING_INDICATOR
        );

/* Event Type */
insert into omd.EVENT_TYPE
select *
from (
          /* EVENT_TYPE_CODE, EVENT_TYPE_DESCRIPTION */
    values (N'1', N'Infrastructural error.')
         , (N'2', N'Internal data integration process error or system generated event.')
         , (N'3', N'Custom exception handling that has been implemented in ETL (Error Bitmaps).')
    ) as refData(EVENT_TYPE_CODE, EVENT_TYPE_DESCRIPTION)
where not exists (
        select null
        from omd.EVENT_TYPE
        where omd.EVENT_TYPE.EVENT_TYPE_CODE = refData.EVENT_TYPE_CODE
        );

/* Batch */
set identity_insert omd.BATCH on;
insert into omd.BATCH (BATCH_ID, BATCH_CODE, FREQUENCY_CODE, BATCH_DESCRIPTION, INACTIVE_INDICATOR)
select *
from (
          /* BATCH_ID, BATCH_CODE, FREQUENCY_CODE, BATCH_DESCRIPTION, INACTIVE_INDICATOR */
    values (0, N'Default Batch', N'Continuous', N'Placeholder value for dummy Batch runs', N'N')
    ) as refData(BATCH_ID, BATCH_CODE, FREQUENCY_CODE, BATCH_DESCRIPTION, INACTIVE_INDICATOR)
where not exists (
        select null
        from omd.BATCH
        where omd.BATCH.BATCH_ID = refData.BATCH_ID
        );
set identity_insert omd.BATCH off;

/* Batch Instance */
set identity_insert omd.BATCH_INSTANCE on;
insert into omd.BATCH_INSTANCE (BATCH_INSTANCE_ID, BATCH_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, BATCH_EXECUTION_SYSTEM_ID)
select *
from (
          /* BATCH_INSTANCE_ID, BATCH_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, BATCH_EXECUTION_SYSTEM_ID */
    values (0, 0, CAST(N'1900-01-01T00:00:00.000' AS DateTime), CAST(N'2018-10-17T15:07:44.843' AS DateTime), N'P', N'P', N'S', N'N/A')
    ) as refData(BATCH_INSTANCE_ID, BATCH_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, BATCH_EXECUTION_SYSTEM_ID)
where not exists (
        select null
        from omd.BATCH_INSTANCE
        where omd.BATCH_INSTANCE.BATCH_INSTANCE_ID = refData.BATCH_INSTANCE_ID
        );
set identity_insert omd.BATCH_INSTANCE off;

/* Module */
set identity_insert omd.MODULE on;
insert into omd.MODULE (MODULE_ID, MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPE, DATA_OBJECT_SOURCE, DATA_OBJECT_TARGET, AREA_CODE, FREQUENCY_CODE, INACTIVE_INDICATOR)
select *
from (
    values (0, 'Default Module', 'Placeholder value for dummy Module runs', 'ETL', 'N/A', 'N/A', 'Maintenance', 'Continuous', 'N')
    ) as refData(MODULE_ID, MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPEE, DATA_OBJECT_SOURCE, DATA_OBJECT_TARGET, AREA_CODE, FREQUENCY_CODE, INACTIVE_INDICATOR)
where not exists (
        select null
        from omd.MODULE
        where omd.MODULE.MODULE_ID = refData.MODULE_ID
        );
set identity_insert omd.MODULE off;

/* Module Instance */
set identity_insert omd.MODULE_INSTANCE on;
insert into omd.MODULE_INSTANCE (MODULE_INSTANCE_ID, MODULE_ID, BATCH_INSTANCE_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, MODULE_EXECUTION_SYSTEM_ID, ROWS_INPUT, ROWS_INSERTED, ROWS_UPDATED, ROWS_DELETED, ROWS_DISCARDED, ROWS_REJECTED)
select *
from (
      values (0, 0, 0,'1900-01-01', '9999-12-31', 'P', 'P', 'S', 'N/A',0,0,0,0,0,0)
    ) as refData(MODULE_INSTANCE_ID, MODULE_ID, BATCH_INSTANCE_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, MODULE_EXECUTION_SYSTEM_ID, ROWS_INPUT, ROWS_INSERTED, ROWS_UPDATED, ROWS_DELETED, ROWS_DISCARDED, ROWS_REJECTED)
where not exists (
        select null
        from omd.MODULE_INSTANCE
        where omd.MODULE_INSTANCE.MODULE_INSTANCE_ID = refData.MODULE_INSTANCE_ID
        );
set identity_insert omd.MODULE_INSTANCE off;