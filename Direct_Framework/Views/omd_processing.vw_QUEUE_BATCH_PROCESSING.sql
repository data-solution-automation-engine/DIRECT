/**
 * @view [omd_processing].[vw_QUEUE_BATCH_PROCESSING]
 * @description Compute processing queue order for active on-demand batches based on last end timestamp.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @resultset Columns:
 *   - BATCH_ID: Batch identifier.
 *   - BATCH_CODE: Batch code.
 *   - END_TIMESTAMP: Last end timestamp or 0001-01-01 if none.
 *   - QUEUE_ORDER: Calculated order using ROW_NUMBER over END_TIMESTAMP.
 *
 * @lineage
 * - reads:
 *     table [omd].[BATCH]
 *     table [omd].[BATCH_INSTANCE]
 *
 * @example
 * SELECT TOP 100 * FROM [omd_processing].[vw_QUEUE_BATCH_PROCESSING];
 */
CREATE VIEW [omd_processing].[vw_QUEUE_BATCH_PROCESSING]
AS

SELECT
  batch.BATCH_ID,
  batch.BATCH_CODE,
  COALESCE(END_TIMESTAMP,'0001-01-01') AS END_TIMESTAMP,
  ROW_NUMBER() OVER(ORDER BY END_TIMESTAMP) QUEUE_ORDER
FROM omd.BATCH batch
LEFT OUTER JOIN omd.BATCH_INSTANCE main ON main.BATCH_ID=batch.BATCH_ID
LEFT JOIN
(
  SELECT batch.BATCH_ID, COALESCE(MAX(BATCH_INSTANCE_ID), 0) MOST_RECENT_EXECUTION_BATCH_ID
  FROM omd.BATCH batch
  LEFT JOIN omd.BATCH_INSTANCE batch_instance ON batch.BATCH_ID = batch_instance.BATCH_ID
  WHERE batch.BATCH_ID <> 0
  GROUP BY batch.BATCH_ID
) most_recent
ON batch.BATCH_ID = most_recent.BATCH_ID AND COALESCE(main.BATCH_INSTANCE_ID, 0) = most_recent.MOST_RECENT_EXECUTION_BATCH_ID
WHERE batch.BATCH_ID <> 0
AND batch.ACTIVE_INDICATOR = 'Y'
AND batch.FREQUENCY_CODE = 'On-demand'
AND (MOST_RECENT_EXECUTION_BATCH_ID IS NOT NULL OR MOST_RECENT_EXECUTION_BATCH_ID = 0)
AND COALESCE(EXECUTION_STATUS_CODE, 'Succeeded') <> 'Executing';
