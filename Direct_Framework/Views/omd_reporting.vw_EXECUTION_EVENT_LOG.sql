CREATE VIEW [omd_reporting].[vw_EXECUTION_EVENT_LOG]

AS

SELECT
  EL.EVENT_ID
  , EL.BATCH_INSTANCE_ID
  , B.BATCH_CODE
  , EL.MODULE_INSTANCE_ID
  , M.MODULE_CODE
  , ET.EVENT_TYPE_CODE_DESCRIPTION
  , EL.EVENT_TIMESTAMP
  , EL.EVENT_RETURN_CODE
  , EL.EVENT_DETAIL
FROM
  omd.EVENT_LOG EL
  INNER JOIN [omd_metadata].[EVENT_TYPE] ET ON EL.EVENT_TYPE_CODE = ET.EVENT_TYPE_CODE
  INNER JOIN [omd].[BATCH_INSTANCE] BI ON EL.BATCH_INSTANCE_ID = BI.BATCH_INSTANCE_ID
  INNER JOIN [omd].[BATCH] B ON BI.BATCH_ID = B.BATCH_ID
  INNER JOIN [omd].[MODULE_INSTANCE] MI ON EL.MODULE_INSTANCE_ID = MI.MODULE_INSTANCE_ID
  INNER JOIN [omd].[MODULE] M ON MI.MODULE_ID = M.MODULE_ID
WHERE
  EVENT_ID <> 0
