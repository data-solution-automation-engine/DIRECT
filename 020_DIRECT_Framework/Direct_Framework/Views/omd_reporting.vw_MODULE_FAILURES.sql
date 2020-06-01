CREATE VIEW [omd_reporting].[vw_MODULE_FAILURES] AS

select     --TOP 40
           m.MODULE_CODE
          ,m.MODULE_DESCRIPTION
          ,AVG(datediff(MINUTE,mi.START_DATETIME,mi.END_DATETIME)) as AVG_EXEC_MIN
          ,SUM(case when mi.EXECUTION_STATUS_CODE = 'F' then 1 else 0 end) as COUNT_ERRORS
from      omd.MODULE m
JOIN      omd.MODULE_INSTANCE mi
ON            m.MODULE_ID = mi.MODULE_ID
WHERE         mi.START_DATETIME > dateadd(MONTH,-3,getdate())
group by      m.MODULE_CODE, m.MODULE_DESCRIPTION
HAVING        SUM(case when mi.EXECUTION_STATUS_CODE = 'F' then 1 else 0 end) >0
