/*******************************************************************************
 * [omd_reporting].[vw_CUMULATIVE_LOAD_TIME]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT Framework v2.0 reporting views
 *
 * Purpose:
 *   List accumulated load times for all modules.
 *   Handles if a table has been reloaded.
 *
 ******************************************************************************/

CREATE VIEW [omd_reporting].[vw_CUMULATIVE_LOAD_TIME]
AS

WITH PRE_FORMATTING
AS (
  SELECT
    m.MODULE_CODE,
    COUNT(*) AS INSTANCES_RUN,
    SUM(DATEDIFF(SECOND, mi.START_TIMESTAMP, COALESCE(mi.END_TIMESTAMP, SYSUTCDATETIME()))) AS DURATION_SEC,
    SUM(CAST(mi.ROWS_INSERTED AS BIGINT)) AS ROWS_TRANSFERRED
  FROM [omd].[MODULE] m
    INNER JOIN [omd].[MODULE_INSTANCE] mi ON m.[MODULE_ID] = mi.[MODULE_ID]
  WHERE m.MODULE_ID != 0 -- Default module is excluded
  GROUP BY m.[MODULE_CODE]
 )

SELECT
  [MODULE_CODE],
  [INSTANCES_RUN],
  DURATION_SEC,
  ISNULL(CAST(NULLIF(DATEPART(DAY, DATEADD(SECOND, DURATION_SEC, 0)), 1) - 1 AS NVARCHAR(10)) +
    ' days ', '') +
    CONVERT(VARCHAR(30), DATEADD(SECOND, DURATION_SEC, 0), 108) AS [DURATION],
  ROWS_TRANSFERRED
FROM PRE_FORMATTING;
