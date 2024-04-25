CREATE FUNCTION [omd].[GetModuleLoadWindowValue] ( @ModuleId BIGINT, @start_or_end TINYINT)
RETURNS DATETIME2(7) AS 
BEGIN 
    /*
        The GetModuleLoadWindowDateTime retrieves the start or end value as currently available in the source control table.
        The from part of the load window can be selected by providing the parameter value 1, and 2 is for the closing of the window - the end datetime.

        Example usage:

        DECLARE @START_VALUE DATETIME2(7) = [omd].[GetModuleLoadWindowDateTime]((SELECT MODULE_ID FROM [omd].MODULE WHERE MODULE_CODE='<module>'), 1)
        PRINT @START_VALUE

        Load windows can be created via omd.CreateLoadWindow.
    */
    DECLARE @result DATETIME2(7)
 
    IF @start_or_end = 1
    BEGIN
            SELECT @result= START_VALUE
            FROM
            (
                SELECT 
                sct.MODULE_INSTANCE_ID, 
                START_VALUE, 
                END_VALUE,
                ROW_NUMBER() OVER (PARTITION BY modinst.MODULE_ID ORDER BY INSERT_DATETIME DESC) AS ROW_NR 
            FROM omd.SOURCE_CONTROL sct
            JOIN omd.MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
            WHERE modinst.MODULE_ID = @ModuleId
            ) ranksub
            WHERE ROW_NR=1
    END
    ELSE IF @start_or_end = 2
    BEGIN
            SELECT @result= END_VALUE
            FROM
            (
                SELECT 
                sct.MODULE_INSTANCE_ID, 
                START_VALUE, 
                END_VALUE,
                ROW_NUMBER() OVER (PARTITION BY modinst.MODULE_ID ORDER BY INSERT_DATETIME DESC) AS ROW_NR 
            FROM omd.SOURCE_CONTROL sct
            JOIN omd.MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
            WHERE modinst.MODULE_ID = @ModuleId
            ) ranksub
            WHERE ROW_NR=1
    END
    RETURN @result
END