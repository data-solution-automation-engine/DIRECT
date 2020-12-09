CREATE FUNCTION [omd].[GetConsistencyDateTime] ( @Table_List VARCHAR(MAX), @MeasurementDate datetime2(7))
RETURNS DATETIME2(7) AS 
BEGIN 

-- Input variables, for debugging only and commented out
--DECLARE @MeasurementDate DATETIME2(7) = GETDATE();
--DECLARE @Table_List VARCHAR(MAX) ='';

-- Output variables
DECLARE @Output DATETIME2(7);

-- Local variables
DECLARE @EligibleWindowsCount int = 0;
DECLARE @MaxDateTime DATETIME2(7);

-- Remove spaces and quotes
SET @Table_List = REPLACE(@Table_List,' ','');
SET @Table_List = REPLACE(@Table_List,'''','');

-- Splitting the Table_List variable array into rows
-- Would fail if passed a list of more than 100 tables
WITH cteSplits(starting_position, end_position)
AS     
(
    SELECT CAST(1 AS BIGINT), CHARINDEX(',', @Table_List)
    UNION ALL
    SELECT end_position + 1, charindex(',', @Table_List, end_position + 1)
    FROM cteSplits
    WHERE end_position > 0 -- Another delimiter was found
)
, table_names
AS     
(
SELECT DISTINCT DATA_STORE_CODE = substring(@Table_List, 
											starting_position, 
											CASE WHEN end_position = 0 
												 THEN len(@Table_List)
												 ELSE end_position - starting_position 
											END) 
FROM cteSplits
),
---- Calculate the output now the individual tables are available
ConsistencyCTE AS
(
SELECT * 
FROM (
	SELECT
		   sct.MODULE_INSTANCE_ID,
		   modinst.MODULE_ID,
		   module.MODULE_CODE,
		   module.DATA_OBJECT_TARGET,
		   modinst.EXECUTION_STATUS_CODE,
		   sct.INTERVAL_START_DATETIME,
		   sct.INTERVAL_END_DATETIME,
		   CASE	
			 WHEN sct.INTERVAL_START_DATETIME = sct.INTERVAL_END_DATETIME THEN 0
			 ELSE 1
		   END as CHANGE_DELTA_INDICATOR,
		   ROW_NUMBER() OVER (PARTITION BY COALESCE(modinst.MODULE_ID,0) ORDER BY modinst.MODULE_INSTANCE_ID DESC) AS ROW_ORDER
	FROM omd.MODULE_INSTANCE modinst
	JOIN omd.SOURCE_CONTROL sct ON modinst.MODULE_INSTANCE_ID = sct.MODULE_INSTANCE_ID
	JOIN omd.MODULE module ON modinst.MODULE_ID = module.MODULE_ID
	JOIN -- Only join modules that relate to the intended target tables.
	  (                   
		SELECT MODULE_ID
		FROM omd.MODULE
		INNER JOIN table_names ON LTRIM(table_names.DATA_STORE_CODE) = omd.MODULE.DATA_OBJECT_TARGET
	  ) module_tables
	  ON modinst.MODULE_ID = module_tables.MODULE_ID
	WHERE 1=1
	  AND module.INACTIVE_INDICATOR='N'
	  AND modinst.EXECUTION_STATUS_CODE = 'S'
	  AND sct.INTERVAL_END_DATETIME <= @MeasurementDate
	) sub
	WHERE ROW_ORDER=1
)
, ELIGIBLE_WINDOWS AS
(
	SELECT 
		SUM(CHANGE_DELTA_INDICATOR) AS ELIGIBILITY_COUNT, 
		(SELECT COUNT (DISTINCT DATA_OBJECT_TARGET) FROM ConsistencyCTE) AS MODULE_TABLE_COUNT,
		MAX(INTERVAL_END_DATETIME) AS MAX_END_DATETIME,
		MAX(MODULE_INSTANCE_ID) AS MAX_MODULE_INSTANCE_ID,
		(SELECT COUNT(*) FROM table_names) AS TABLE_COUNT
	FROM ConsistencyCTE
)
SELECT 
     @Output = MIN
	(CASE 
	    WHEN MODULE_TABLE_COUNT < TABLE_COUNT THEN NULL -- Not all tables have been hit with records yet, only relevant when starting from scratch / drop everything.
		WHEN ELIGIBILITY_COUNT = 0 THEN MAX_END_DATETIME -- If the eligibility count is 0 then MAX(INTERVAL_END_DATETIME), because there are no changes at all to be detected.
		WHEN ELIGIBILITY_COUNT != 0 AND CHANGE_DELTA_INDICATOR = 1 THEN INTERVAL_END_DATETIME-- If the eligbility count != 0 then remove all rows where START_DATETIME=END_DATETIME and select the MIN(INTERVAL_END_DATETIME) from this result
	END)
FROM ConsistencyCTE 
CROSS JOIN ELIGIBLE_WINDOWS


RETURN @Output;

END;