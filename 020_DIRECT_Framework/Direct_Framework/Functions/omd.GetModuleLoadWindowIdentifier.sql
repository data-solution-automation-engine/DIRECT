CREATE FUNCTION [omd].[GetModuleLoadWindowIdentifier] (@ModuleId INT, @start_or_end tinyint)
RETURNS BIGINT AS 
BEGIN 
       DECLARE @result BIGINT
 
       IF @start_or_end = 1  
       BEGIN
              SELECT @result = ranksub.INTERVAL_START_IDENTIFIER
              FROM
              (
                 SELECT 
                 sct.MODULE_INSTANCE_ID, 
                 sct.INTERVAL_START_IDENTIFIER, 
                 sct.INTERVAL_END_IDENTIFIER,
                 ROW_NUMBER() OVER (PARTITION BY MODULE_ID ORDER BY INSERT_DATETIME DESC) AS ROW_NR 
              FROM omd.SOURCE_CONTROL sct
              JOIN omd.MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
              WHERE MODULE_ID = @ModuleId
              ) ranksub
              WHERE ROW_NR=1
       END
       ELSE IF @start_or_end = 2
       BEGIN
              SELECT @result= INTERVAL_END_IDENTIFIER
              FROM
              (
                 SELECT 
                   sct.MODULE_INSTANCE_ID, 
                   sct.INTERVAL_START_IDENTIFIER, 
                   sct.INTERVAL_END_IDENTIFIER,
                   ROW_NUMBER() OVER (PARTITION BY modinst.MODULE_ID ORDER BY sct.INSERT_DATETIME DESC) AS ROW_NR 
                 FROM omd.SOURCE_CONTROL sct
                 JOIN omd.MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
                 WHERE MODULE_ID = @ModuleId
              ) ranksub
              WHERE ROW_NR=1
       END
       return @result
END
 
