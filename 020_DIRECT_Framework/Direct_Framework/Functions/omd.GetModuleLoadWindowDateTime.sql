CREATE FUNCTION [omd].[GetModuleLoadWindowDateTime] ( @ModuleId INT, @start_or_end tinyint)
RETURNS DATETIME2(7) AS 
BEGIN 
       DECLARE @result DATETIME2(7)
 
       IF @start_or_end = 1  
       BEGIN
              SELECT @result= INTERVAL_START_DATETIME
              FROM
              (
                 SELECT 
                 sct.MODULE_INSTANCE_ID, 
                 INTERVAL_START_DATETIME, 
                 INTERVAL_END_DATETIME,
                 ROW_NUMBER() OVER (PARTITION BY MODULE_ID ORDER BY INSERT_DATETIME DESC) AS ROW_NR 
              FROM omd.SOURCE_CONTROL sct
              JOIN omd.MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
              WHERE MODULE_ID = @ModuleId
              ) ranksub
              WHERE ROW_NR=1
       END
       ELSE IF @start_or_end = 2
       BEGIN
              SELECT @result= INTERVAL_END_DATETIME
              FROM
              (
                 SELECT 
                 sct.MODULE_INSTANCE_ID, 
                 INTERVAL_START_DATETIME, 
                 INTERVAL_END_DATETIME,
                 ROW_NUMBER() OVER (PARTITION BY MODULE_ID ORDER BY INSERT_DATETIME DESC) AS ROW_NR 
              FROM omd.SOURCE_CONTROL sct
              JOIN omd.MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
              WHERE MODULE_ID = @ModuleId
              ) ranksub
              WHERE ROW_NR=1
       END
       return @result
END