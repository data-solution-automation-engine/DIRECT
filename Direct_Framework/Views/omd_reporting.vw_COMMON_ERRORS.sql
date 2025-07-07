/*******************************************************************************
 * [omd_reporting].[vw_COMMON_ERRORS]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Report on common errors in the system by aggregating error messages.
 *
 ******************************************************************************/

CREATE VIEW [omd_reporting].[vw_COMMON_ERRORS]
AS

SELECT
   m.MODULE_CODE
  ,m.MODULE_DESCRIPTION
  ,error.ERROR_MSG AS ERROR_MSG
  ,COUNT(*) AS ERROR_COUNT
FROM omd.MODULE m
JOIN (
  SELECT
     mi.MODULE_ID
    ,mi.MODULE_INSTANCE_ID
    ,mi.BATCH_INSTANCE_ID
    ,(
      SELECT EVENT_DETAIL + ''
      FROM [omd].[EVENT_LOG] sub
      WHERE sub.MODULE_INSTANCE_ID = mi.MODULE_INSTANCE_ID
        AND sub.BATCH_INSTANCE_ID = mi.BATCH_INSTANCE_ID
        AND sub.EVENT_TIMESTAMP > dateadd(MONTH, -1, SYSUTCDATETIME())
      FOR XML PATH ('') ) as ERROR_MSG
    FROM omd.MODULE_INSTANCE mi
    WHERE mi.START_TIMESTAMP > dateadd(MONTH, -1, SYSUTCDATETIME())
    GROUP BY mi.MODULE_ID,mi.MODULE_INSTANCE_ID, mi.BATCH_INSTANCE_ID
  ) error
ON error.MODULE_ID = m.MODULE_ID
AND rtrim(ERROR_MSG) <> ''
GROUP BY m.MODULE_CODE, m.MODULE_DESCRIPTION, error.ERROR_MSG
