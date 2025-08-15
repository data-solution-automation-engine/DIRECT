/**
 * @view [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_BATCHES]
 * @description Active batches whose most recent run started 60 days ago or more.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @resultset Columns:
 *   - BATCH_CODE: Batch code.
 *   - BATCH_ID: Batch id.
 *   - BATCH_DESCRIPTION: Description.
 *   - MOST_RECENT_BATCH_INSTANCE_ID: Latest batch instance id.
 *   - START_TIMESTAMP: Start timestamp of latest instance.
 *   - END_TIMESTAMP: End timestamp of latest instance.
 *   - EXECUTION_STATUS_CODE: Execution status of latest instance.
 *
 * @lineage
 * - reads:
 *     table [omd].[BATCH]
 *     table [omd].[BATCH_INSTANCE]
 *
 * @example
 * SELECT TOP 100 * FROM [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_BATCHES];
 */
CREATE VIEW [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_BATCHES]

AS

SELECT
  BATCH.BATCH_CODE,
  BATCH.BATCH_ID,
  BATCH.BATCH_DESCRIPTION,
  main.BATCH_INSTANCE_ID AS MOST_RECENT_BATCH_INSTANCE_ID,
  main.START_TIMESTAMP,
  main.END_TIMESTAMP,
  main.EXECUTION_STATUS_CODE
FROM omd.BATCH_INSTANCE main
JOIN omd.BATCH BATCH ON main.BATCH_ID=BATCH.BATCH_ID
JOIN
(
  SELECT
    BATCH_ID,
    MAX(BATCH_INSTANCE_ID) as MAX_BATCH_INSTANCE_ID
  FROM omd.BATCH_INSTANCE
  WHERE BATCH_ID > 0
  GROUP BY BATCH_ID
) maxsub
ON
  main.BATCH_ID = maxsub.BATCH_ID AND
  main.BATCH_INSTANCE_ID = maxsub.MAX_BATCH_INSTANCE_ID
WHERE
  DATEDIFF(dd,START_TIMESTAMP, SYSUTCDATETIME()) >= 60 AND
  ACTIVE_INDICATOR = 'Y'
