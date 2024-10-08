CREATE VIEW [omd_reporting].[vw_EXECUTION_LOG_MODULE_INSTANCE]
AS

SELECT
    MI.MODULE_INSTANCE_ID
  , MI.EXECUTION_CONTEXT
  , MI.BATCH_INSTANCE_ID
  , M.MODULE_CODE
  , MI.START_TIMESTAMP
  , MI.END_TIMESTAMP
  , DATEDIFF(second, MI.START_TIMESTAMP, MI.END_TIMESTAMP) AS EXECUTION_TIME
  , PIND.INTERNAL_PROCESSING_STATUS_CODE_DESCRIPTION
  , NR.NEXT_RUN_DESCRIPTION
  , MI.EXECUTION_STATUS_CODE
  , ES.EXECUTION_STATUS_DESCRIPTION
  , MI.ROWS_INPUT
  , MI.ROWS_INSERTED
  , MI.ROWS_UPDATED
  , MI.ROWS_DELETED
  , MI.ROWS_DISCARDED
  , MI.ROWS_REJECTED
FROM
  [omd].[MODULE_INSTANCE] MI
  INNER JOIN [omd].[MODULE] M ON MI.MODULE_ID = M.MODULE_ID
  INNER JOIN [omd_metadata].INTERNAL_PROCESSING_STATUS PIND ON MI.INTERNAL_PROCESSING_CODE = PIND.INTERNAL_PROCESSING_STATUS_CODE
  INNER JOIN [omd_metadata].NEXT_RUN_STATUS NR ON MI.INTERNAL_PROCESSING_CODE = NR.NEXT_RUN_STATUS_CODE
  INNER JOIN [omd_metadata].EXECUTION_STATUS ES ON MI.EXECUTION_STATUS_CODE = ES.EXECUTION_STATUS_CODE
WHERE MODULE_INSTANCE_ID <> 0
