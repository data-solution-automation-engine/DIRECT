CREATE VIEW [omd_reporting].[vw_COMMON_ERRORS]
AS

SELECT
  m.MODULE_CODE
  ,m.MODULE_DESCRIPTION
  ,CASE WHEN UPPER(error.ERROR_MSG) LIKE '%TEMPDB%' THEN 'TempDB'
  WHEN error.ERROR_MSG LIKE '%WinSCP%' THEN 'WinSCP'
  WHEN error.ERROR_MSG LIKE '%deadlocked%' THEN 'Dead Lock'
  WHEN error.ERROR_MSG LIKE '%duplicate key%' THEN 'Duplicate Key'

  ELSE REPLACE(error.ERROR_MSG,'&#x0D;','')
  END AS ERROR_MSG
  ,count(*) AS COUNT

from omd.MODULE m
join (
  select mi.MODULE_ID
  ,mi.MODULE_INSTANCE_ID
  ,mi.BATCH_INSTANCE_ID
  ,(
    SELECT EVENT_DETAIL + ''
    from [omd].[EVENT_LOG] sub 
    where sub.MODULE_INSTANCE_ID = mi.MODULE_INSTANCE_ID
      and sub.BATCH_INSTANCE_ID = mi.BATCH_INSTANCE_ID
      and sub.EVENT_TIMESTAMP > dateadd(MONTH, -1, SYSUTCDATETIME())
    for xml path ('') ) as ERROR_MSG
  from omd.MODULE_INSTANCE mi
  WHERE mi.START_TIMESTAMP> dateadd(MONTH, -1, SYSUTCDATETIME())
  group by mi.MODULE_ID,mi.MODULE_INSTANCE_ID, mi.BATCH_INSTANCE_ID
  ) error
on error.MODULE_ID = m.MODULE_ID
and rtrim(ERROR_MSG) <> ''
group by m.MODULE_CODE, m.MODULE_DESCRIPTION, error.ERROR_MSG
--order by 4 desc
