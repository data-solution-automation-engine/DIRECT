/**
 * @view [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_MODULES]
 * @description Active modules whose most recent run started 60 days ago or more.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @resultset Columns:
 *   - MODULE_CODE: Module code.
 *   - MODULE_ID: Module id.
 *   - MODULE_DESCRIPTION: Description.
 *   - MOST_RECENT_MODULE_INSTANCE_ID: Latest module instance id.
 *   - START_TIMESTAMP: Start timestamp of latest instance.
 *   - END_TIMESTAMP: End timestamp of latest instance.
 *   - EXECUTION_STATUS_CODE: Execution status of latest instance.
 *
 * @lineage
 * - reads:
 *     table [omd].[MODULE]
 *     table [omd].[MODULE_INSTANCE]
 *
 * @example
 * SELECT TOP 100 * FROM [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_MODULES];
 */
CREATE VIEW [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_MODULES]

AS

SELECT
  module.MODULE_CODE,
  module.MODULE_ID,
  module.MODULE_DESCRIPTION,
  main.MODULE_INSTANCE_ID AS MOST_RECENT_MODULE_INSTANCE_ID,
  main.START_TIMESTAMP,
  main.END_TIMESTAMP,
  main.EXECUTION_STATUS_CODE
FROM [omd].[MODULE_INSTANCE] main
JOIN [omd].[MODULE] module ON main.MODULE_ID = module.MODULE_ID
JOIN
(
  SELECT MODULE_ID, MAX(MODULE_INSTANCE_ID) as MAX_MODULE_INSTANCE_ID
  FROM omd.MODULE_INSTANCE
  WHERE MODULE_ID > 0
  GROUP BY MODULE_ID
) maxsub
ON
  main.MODULE_ID = maxsub.MODULE_ID
  AND
  main.MODULE_INSTANCE_ID = maxsub.MAX_MODULE_INSTANCE_ID

WHERE
  DATEDIFF(dd, START_TIMESTAMP, SYSUTCDATETIME()) >= 60
  AND
  module.ACTIVE_INDICATOR = 'Y'
