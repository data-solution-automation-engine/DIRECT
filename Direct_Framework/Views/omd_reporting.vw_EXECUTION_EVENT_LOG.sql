/**
 * @view [omd_reporting].[vw_EXECUTION_EVENT_LOG]
 * @description Flattened event log enriched with batch and module context and event type descriptions.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @resultset Columns:
 *   - EVENT_ID: Event identifier.
 *   - BATCH_INSTANCE_ID: Batch instance id.
 *   - BATCH_CODE: Batch code.
 *   - MODULE_INSTANCE_ID: Module instance id.
 *   - MODULE_CODE: Module code.
 *   - EVENT_TYPE_DESCRIPTION: Event type description.
 *   - EVENT_TIMESTAMP: Event time.
 *   - EVENT_RETURN_CODE: Return code captured with the event.
 *   - EVENT_DETAIL: Event detail text.
 *
 * @lineage
 * - reads:
 *     table [omd].[EVENT_LOG]
 *     table [omd].[BATCH_INSTANCE]
 *     table [omd].[BATCH]
 *     table [omd].[MODULE_INSTANCE]
 *     table [omd].[MODULE]
 *     table [omd_metadata].[EVENT_TYPE]
 *
 * @example
 * SELECT TOP 100 * FROM [omd_reporting].[vw_EXECUTION_EVENT_LOG];
 */
CREATE VIEW [omd_reporting].[vw_EXECUTION_EVENT_LOG]

AS

SELECT
  EL.EVENT_ID
  , EL.BATCH_INSTANCE_ID
  , B.BATCH_CODE
  , EL.MODULE_INSTANCE_ID
  , M.MODULE_CODE
  , ET.EVENT_TYPE_DESCRIPTION
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
