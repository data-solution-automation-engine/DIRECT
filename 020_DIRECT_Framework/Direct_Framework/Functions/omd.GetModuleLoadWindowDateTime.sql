CREATE FUNCTION [omd].[GetModuleLoadWindowDateTime] ( @ModuleId BIGINT, @start_or_end TINYINT)
RETURNS DATETIME2(7) AS 
BEGIN 
    /*
        The GetModuleLoadWindowDateTime retrieves the start or end value as currently available in the source control table.
        The from part of the load window can be selected by providing the parameter value 1, and 2 is for the closing of the window - the end datetime.

        Example usage:

        DECLARE @INTERVAL_START_DATETIME DATETIME2(7) = [omd].[GetModuleLoadWindowDateTime]((SELECT MODULE_ID FROM [omd].MODULE WHERE MODULE_CODE='<module>'), 1)
        PRINT @INTERVAL_START_DATETIME

        Load windows can be created via omd.CreateLoadWindow.
    */
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
    RETURN @result
END