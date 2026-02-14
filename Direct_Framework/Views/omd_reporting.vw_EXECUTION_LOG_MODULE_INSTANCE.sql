/**
 * @view [omd_reporting].[vw_EXECUTION_LOG_MODULE_INSTANCE]
 * @description Module instance execution log with status descriptions, durations and row counts.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @resultset Columns:
 *   - MODULE_INSTANCE_ID: Module instance id.
 *   - EXECUTION_CONTEXT: Context string for the run.
 *   - BATCH_INSTANCE_ID: Associated batch instance id.
 *   - MODULE_CODE: Module code.
 *   - START_TIMESTAMP: Start time.
 *   - END_TIMESTAMP: End time.
 *   - EXECUTION_TIME: Duration in seconds.
 *   - INTERNAL_PROCESSING_STATUS_DESCRIPTION: Internal processing state.
 *   - NEXT_RUN_STATUS_DESCRIPTION: Next run state.
 *   - EXECUTION_STATUS_CODE: Execution status code.
 *   - EXECUTION_STATUS_DESCRIPTION: Execution status description.
 *   - ROWS_INPUT/INSERTED/UPDATED/DELETED/DISCARDED/REJECTED: Row counts by category.
 *
 * @lineage
 * - reads:
 *     table [omd].[MODULE_INSTANCE]
 *     table [omd].[MODULE]
 *     table [omd_metadata].[INTERNAL_PROCESSING_STATUS]
 *     table [omd_metadata].[NEXT_RUN_STATUS]
 *     table [omd_metadata].[EXECUTION_STATUS]
 *
 * @example
 * SELECT TOP 100 * FROM [omd_reporting].[vw_EXECUTION_LOG_MODULE_INSTANCE];
 */
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
  , PIND.INTERNAL_PROCESSING_STATUS_DESCRIPTION
  , NR.NEXT_RUN_STATUS_DESCRIPTION
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
