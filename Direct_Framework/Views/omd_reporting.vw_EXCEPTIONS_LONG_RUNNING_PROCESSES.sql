/**
 * @view [omd_reporting].[vw_EXCEPTIONS_LONG_RUNNING_PROCESSES]
 * @description Long-running executing batch and module instances beyond thresholds (4h modules, 8h batches).
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @resultset Columns:
 *   - MODULE_CODE/BATCH_CODE: Code by section.
 *   - EXECUTION_STATUS_CODE: Should be 'Executing'.
 *   - BATCH_INSTANCE_ID: Associated batch instance id.
 *   - MODULE_INSTANCE_ID: Module instance id or 'N/A' for batches.
 *   - MODULE_ID: Module id or 'N/A' for batches.
 *   - START_TIMESTAMP: Start time.
 *   - END_TIMESTAMP: End time.
 *   - HOURS_DIFFERENCE: Hours since start to now or end.
 *
 * @lineage
 * - reads:
 *     table [omd].[MODULE]
 *     table [omd].[MODULE_INSTANCE]
 *     table [omd].[BATCH]
 *     table [omd].[BATCH_INSTANCE]
 *
 * @example
 * SELECT TOP 100 * FROM [omd_reporting].[vw_EXCEPTIONS_LONG_RUNNING_PROCESSES];
 */
CREATE VIEW [omd_reporting].[vw_EXCEPTIONS_LONG_RUNNING_PROCESSES]

AS

-- Module level
SELECT
  module.MODULE_CODE,
  main.EXECUTION_STATUS_CODE,
  main.BATCH_INSTANCE_ID,
  CONVERT(NVARCHAR(20), main.MODULE_INSTANCE_ID) AS MODULE_INSTANCE_ID,
  CONVERT(NVARCHAR(10), main.MODULE_ID) AS MODULE_ID,
  main.START_TIMESTAMP,
  main.END_TIMESTAMP,
  DATEDIFF(HOUR, main.START_TIMESTAMP, COALESCE(END_TIMESTAMP, SYSUTCDATETIME())) AS HOURS_DIFFERENCE
FROM omd.MODULE_INSTANCE main
JOIN omd.MODULE module ON main.MODULE_ID = module.MODULE_ID
WHERE main.EXECUTION_STATUS_CODE = 'Executing'
AND DATEDIFF(HOUR, main.START_TIMESTAMP, COALESCE(END_TIMESTAMP, SYSUTCDATETIME())) >= 4

UNION

-- Batch level
SELECT
  batch.BATCH_CODE,
  main.EXECUTION_STATUS_CODE,
  main.BATCH_INSTANCE_ID,
  'N/A' AS MODULE_INSTANCE_ID,
  'N/A' AS MODULE_ID,
  main.START_TIMESTAMP,
  main.END_TIMESTAMP,
DATEDIFF(HOUR,main.START_TIMESTAMP, COALESCE(main.END_TIMESTAMP, SYSUTCDATETIME())) AS HOURS_DIFFERENCE
FROM omd.BATCH_INSTANCE main
INNER JOIN omd.BATCH batch ON main.BATCH_ID = batch.BATCH_ID
WHERE main.EXECUTION_STATUS_CODE = 'Executing'
AND DATEDIFF(HOUR, main.START_TIMESTAMP, COALESCE(END_TIMESTAMP, SYSUTCDATETIME())) >= 8
