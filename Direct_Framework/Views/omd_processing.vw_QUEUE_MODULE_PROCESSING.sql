CREATE VIEW [omd_processing].[vw_QUEUE_MODULE_PROCESSING]
AS

SELECT
   MODULE_ID
  ,MODULE_CODE
  ,END_TIMESTAMP
  ,ROW_NUMBER() OVER( ORDER BY END_TIMESTAMP) QUEUE_ORDER
FROM (
  SELECT
       MODULE.MODULE_ID,
       MODULE.MODULE_CODE,
       COALESCE(END_TIMESTAMP,'1900-01-01') AS END_TIMESTAMP,
       COALESCE(EXECUTION_STATUS_CODE,'Succeeded') AS EXECUTION_STATUS_CODE,
       ROW_NUMBER() OVER(PARTITION BY MODULE.DATA_OBJECT_TARGET ORDER BY CASE COALESCE(EXECUTION_STATUS_CODE,'Succeeded') WHEN 'Executing' THEN 1 ELSE 2 END, END_TIMESTAMP) BY_DATA_STORE
  FROM omd.MODULE MODULE
    LEFT JOIN omd.MODULE_INSTANCE main
        ON main.MODULE_ID=MODULE.MODULE_ID
    LEFT JOIN (
        SELECT MODULE.MODULE_ID, COALESCE(MAX(MODULE_INSTANCE_ID),0) MOST_RECENT_EXECUTION_MODULE_ID
        FROM omd.MODULE MODULE
          LEFT JOIN omd.MODULE_INSTANCE MODULE_instance
              ON MODULE.MODULE_ID=MODULE_instance.MODULE_ID
        WHERE MODULE.MODULE_ID<>0
        GROUP BY MODULE.MODULE_ID
        ) most_recent
        ON MODULE.MODULE_ID = most_recent.MODULE_ID AND COALESCE(main.MODULE_INSTANCE_ID,0) = most_recent.MOST_RECENT_EXECUTION_MODULE_ID
  WHERE MODULE.ACTIVE_INDICATOR = 'Y'
    AND MODULE.AREA_CODE = 'INT'
    AND MODULE.FREQUENCY_CODE = 'On-demand'
    AND MODULE.MODULE_ID <> 0
    AND (MOST_RECENT_EXECUTION_MODULE_ID IS NOT NULL OR MOST_RECENT_EXECUTION_MODULE_ID=0)
  ) as sq
WHERE BY_DATA_STORE = 1
  AND EXECUTION_STATUS_CODE <> 'Executing'