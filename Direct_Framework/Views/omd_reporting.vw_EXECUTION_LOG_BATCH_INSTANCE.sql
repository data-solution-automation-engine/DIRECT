/**
 * @view [omd_reporting].[vw_EXECUTION_LOG_BATCH_INSTANCE]
 * @description Batch instance execution log with status descriptions and durations.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @resultset Columns:
 *   - BATCH_INSTANCE_ID: Batch instance id.
 *   - BATCH_CODE: Batch code.
 *   - EXECUTION_CONTEXT: Context string for the run.
 *   - START_TIMESTAMP: Start time.
 *   - END_TIMESTAMP: End time.
 *   - EXECUTION_TIME: Duration in seconds.
 *   - INTERNAL_PROCESSING_STATUS_DESCRIPTION: Internal processing state.
 *   - NEXT_RUN_STATUS_DESCRIPTION: Next run state.
 *   - EXECUTION_STATUS_CODE: Execution status code.
 *   - EXECUTION_STATUS_DESCRIPTION: Execution status description.
 *
 * @lineage
 * - reads:
 *     table [omd].[BATCH_INSTANCE]
 *     table [omd].[BATCH]
 *     table [omd_metadata].[INTERNAL_PROCESSING_STATUS]
 *     table [omd_metadata].[NEXT_RUN_STATUS]
 *     table [omd_metadata].[EXECUTION_STATUS]
 *
 * @example
 * SELECT TOP 100 * FROM [omd_reporting].[vw_EXECUTION_LOG_BATCH_INSTANCE];
 */
CREATE VIEW [omd_reporting].[vw_EXECUTION_LOG_BATCH_INSTANCE]
AS

SELECT
    BI.BATCH_INSTANCE_ID
  , B.BATCH_CODE
  , BI.EXECUTION_CONTEXT
  , BI.START_TIMESTAMP
  , BI.END_TIMESTAMP
  , DATEDIFF(second, BI.START_TIMESTAMP, BI.END_TIMESTAMP) AS EXECUTION_TIME
  --, CAST (CAST ((BI.END_TIMESTAMP - BI.START_TIMESTAMP) AS TIME) AS NVARCHAR (30)) AS EXECUTION_TIME
  , PIND.INTERNAL_PROCESSING_STATUS_DESCRIPTION
  , NR.NEXT_RUN_STATUS_DESCRIPTION
  , BI.EXECUTION_STATUS_CODE
  , ES.EXECUTION_STATUS_DESCRIPTION
FROM
  [omd].[BATCH_INSTANCE] BI
  INNER JOIN [omd].[BATCH] B ON BI.BATCH_ID = B.BATCH_ID
  INNER JOIN [omd_metadata].[INTERNAL_PROCESSING_STATUS] PIND ON BI.INTERNAL_PROCESSING_CODE = PIND.INTERNAL_PROCESSING_STATUS_CODE
  INNER JOIN [omd_metadata].[NEXT_RUN_STATUS] NR ON BI.NEXT_RUN_STATUS_CODE = NR.NEXT_RUN_STATUS_CODE
  INNER JOIN [omd_metadata].[EXECUTION_STATUS] ES ON BI.EXECUTION_STATUS_CODE = ES.EXECUTION_STATUS_CODE
WHERE
  BATCH_INSTANCE_ID <> 0
