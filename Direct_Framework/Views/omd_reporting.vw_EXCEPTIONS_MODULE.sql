CREATE VIEW omd_reporting.vw_EXCEPTIONS_MODULE

AS

-- Exception check Module level
SELECT
    module.MODULE_CODE,
    main.EXECUTION_STATUS_CODE,
    main.BATCH_INSTANCE_ID,
    batch.BATCH_CODE,
    main.MODULE_INSTANCE_ID AS MOST_RECENT_MODULE_INSTANCE_ID,
    main.MODULE_ID,
    main.START_TIMESTAMP,
    main.END_TIMESTAMP
FROM omd.MODULE_INSTANCE main
    JOIN omd.MODULE module
        ON main.MODULE_ID=module.MODULE_ID
    JOIN (
            SELECT MODULE_ID, MAX(MODULE_INSTANCE_ID) as MAX_MODULE_INSTANCE_ID
            FROM omd.MODULE_INSTANCE
            WHERE MODULE_ID>0
            GROUP BY MODULE_ID
        ) maxsub
        ON main.MODULE_ID = maxsub.MODULE_ID
        AND main.MODULE_INSTANCE_ID = maxsub.MAX_MODULE_INSTANCE_ID
    JOIN omd.BATCH_INSTANCE
        ON main.BATCH_INSTANCE_ID = omd.BATCH_INSTANCE.BATCH_INSTANCE_ID
    JOIN omd.BATCH batch
        ON omd.BATCH_INSTANCE.BATCH_ID = batch.BATCH_ID
WHERE main.EXECUTION_STATUS_CODE <> 'Succeeded'
    AND module.ACTIVE_INDICATOR = 'Y'