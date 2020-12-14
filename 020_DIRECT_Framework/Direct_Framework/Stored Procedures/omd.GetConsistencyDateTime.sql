/*
Process: Get Consistenct Date/Time
Input: 
  - Table list (comma separated array)
  - Load Window Attribute (optional)
  - Measurement Date/Time (optional)
  - Debug flag Y/N
Returns:
  - Consistency Date/Time
Usage:
    DECLARE @ConsistencyDateTime DATETIME2(7)
    EXEC [omd].[GetConsistencyDateTime]
      @TableList ='HUB_CUSTOMER, SAT_CUSTOMER, SAT_CUSTOMER_ADDITIONAL_DETAILS',
	  @LoadWindowAttributeName = 'LOAD_DATETIME',
	  @Debug = 'Y',
	  @ConsistencyDateTime = @ConsistencyDateTime OUTPUT
    PRINT @ConsistencyDateTime;

Intent:
   For a given point in time, data will be consistent up to the lowest load window end-date of the most-recently successfully completed ETL execution instances involved in loading the target tables.
*/

CREATE PROCEDURE [omd].[GetConsistencyDateTime]
	@TableList VARCHAR(MAX),
	@MeasurementDateTime DATETIME2(7) = NULL,
	@LoadWindowAttributeName VARCHAR(255) = 'LOAD_DATETIME',
	@Debug VARCHAR(1) = 'N',
	@ConsistencyDateTime DATETIME2(7) = NULL OUTPUT
AS

BEGIN

  -- Input variables, for debugging only and commented out
  --DECLARE @TableList VARCHAR(MAX) ='HUB_CUSTOMER, SAT_CUSTOMER, SAT_CUSTOMER_ADDITIONAL_DETAILS'
  --DECLARE @MeasurementDateTime DATETIME2(7) = GETDATE();
  --DECLARE @Debug  CHAR(1) = 'Y';
  --DECLARE @ConsistencyDateTime DATETIME2(7);
  -- End of debug block

  IF @MeasurementDateTime IS NULL
    SET @MeasurementDateTime = GETDATE();

  DECLARE @NumberOfExpectedTargetTables INT; -- This is the number of tables expected to be loading, based on the input table array (table list). 
  DECLARE @NumberOfActualTargetTables INT; -- This is the number of tables found in the load window / module instance list. It needs to be the same as the expected target tables.
  -- If the number of actual target tables is lower than the expected target tables, some of the targets have never been loaded and the process should default to NULL.
  -- This can happen when the whole system is truncated, or started anew.

  DECLARE @ChangeModuleCount INT; -- The number of changes, as per changes in the load window. This is the sum of the delta change indicator.
  -- If there are no changes, the max load window can be used as it wouldn't have changed.

  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;

  IF @Debug = 'Y'
  BEGIN
    PRINT 'Measurement date /time is '+CONVERT(VARCHAR(20),@MeasurementDateTime);
    PRINT 'Consistency date time algorithm started for input table array:';
	PRINT @TableList
  END

  DECLARE @TableNames TABLE
  (
    TABLE_NAME VARCHAR(MAX)
  );


  -- Region table name interpretation
  BEGIN TRY
    -- Remove spaces and quotes
    SET @TableList = REPLACE(@TableList,' ','');
	SET @TableList = REPLACE(@TableList,'''','');
   
    -- Splitting the Table_List variable array into rows
	-- Would fail if passed a list of more than 100 tables
	WITH cteSplits(starting_position, end_position)
	AS     
	(
	  SELECT CAST(1 AS BIGINT), CHARINDEX(',', @TableList)
	  UNION ALL
	  SELECT end_position + 1, charindex(',', @TableList, end_position + 1)
	  FROM cteSplits
	  WHERE end_position > 0 -- Another delimiter was found
	)
	, table_names
	AS     
	(
	  SELECT DISTINCT DATA_STORE_CODE = substring
	                                             (
	                                              @TableList, 
	   										      starting_position, 
	 											  CASE WHEN end_position = 0 
	 											 	   THEN len(@TableList)
	 											 	   ELSE end_position - starting_position 
	 											  END
												 ) 
    FROM cteSplits
	)
	INSERT @TableNames 
    SELECT * FROM table_names
   
	IF @Debug = 'Y'
    BEGIN	  
	  PRINT 'The following rows are found interpreting the table array.'
	  DECLARE @xmltmp xml = (SELECT * FROM @TableNames FOR XML PATH(''))
	  PRINT CONVERT(NVARCHAR(MAX), @xmltmp)
    END
   
  END TRY
  BEGIN CATCH
    -- Logging
	SET @EventDetail = 'Error occurred when transposing table array. The error is.'+ERROR_MESSAGE();  
	THROW 50000,@EventDetail,1;
  END CATCH
  -- End of table interpretation


  -- Load window interpretation 
  IF @Debug='Y'
    PRINT 'Commencing load window retrieval';

  DECLARE @LoadWindows TABLE
  (
    INTERVAL_END_DATETIME_ORDER INT,
	MODULE_CODE VARCHAR(256),
	INTERVAL_START_DATETIME DATETIME2(7),
	INTERVAL_END_DATETIME DATETIME2(7),
	DATA_OBJECT_SOURCE VARCHAR(256),
	DATA_OBJECT_TARGET VARCHAR(256),
	EXECUTION_STATUS_CODE CHAR(1),
    CHANGE_DELTA_INDICATOR INT,
	MODULE_INSTANCE_ID INT,
	MODULE_ID INT,
	CHANGE_FOR_LOGICAL_SOURCE_GROUP CHAR(1)
  );

  BEGIN TRY

    WITH LoadWindowCte
	AS 
	(
    SELECT
	  ROW_NUMBER() OVER (PARTITION BY DATA_OBJECT_SOURCE ORDER BY DATA_OBJECT_SOURCE, INTERVAL_END_DATETIME) as INTERVAL_END_DATETIME_ORDER, 
	  MODULE_CODE,
	  INTERVAL_START_DATETIME,
	  INTERVAL_END_DATETIME,
	  DATA_OBJECT_SOURCE,
	  DATA_OBJECT_TARGET,
	  EXECUTION_STATUS_CODE,
      CHANGE_DELTA_INDICATOR,
      MODULE_INSTANCE_ID,
	  MODULE_ID
	FROM (
      SELECT
	    module.MODULE_CODE,
	    sct.INTERVAL_START_DATETIME,
	    sct.INTERVAL_END_DATETIME,
	    module.DATA_OBJECT_SOURCE,
	    module.DATA_OBJECT_TARGET,
	    modinst.EXECUTION_STATUS_CODE,
	    CASE	
	      WHEN sct.INTERVAL_START_DATETIME = sct.INTERVAL_END_DATETIME THEN 0
	      ELSE 1
	    END as CHANGE_DELTA_INDICATOR,
	    ROW_NUMBER() OVER (PARTITION BY COALESCE(modinst.MODULE_ID,0) ORDER BY modinst.MODULE_INSTANCE_ID DESC) AS ROW_ORDER,
		sct.MODULE_INSTANCE_ID,
	    modinst.MODULE_ID
	  FROM omd.MODULE_INSTANCE modinst
	  JOIN omd.SOURCE_CONTROL sct ON modinst.MODULE_INSTANCE_ID = sct.MODULE_INSTANCE_ID
	  JOIN omd.MODULE module ON modinst.MODULE_ID = module.MODULE_ID
	  JOIN -- Only join modules that relate to the intended target tables.
	  (                   
		SELECT MODULE_ID
		FROM omd.MODULE
		INNER JOIN @TableNames table_names ON LTRIM(table_names.TABLE_NAME) = omd.MODULE.DATA_OBJECT_TARGET
	  ) module_tables
	  ON modinst.MODULE_ID = module_tables.MODULE_ID
	  WHERE 1=1
	    AND module.INACTIVE_INDICATOR='N'
	    AND modinst.EXECUTION_STATUS_CODE = 'S'
	    AND sct.INTERVAL_END_DATETIME <= @MeasurementDateTime
    ) sub
    WHERE ROW_ORDER=1
	)
	, ChangesPerLogicalSource AS
	(
		SELECT DATA_OBJECT_SOURCE, CASE WHEN SUM(CHANGE_DELTA_INDICATOR) >0 THEN 'Y' ELSE 'N' END AS CHANGE_FOR_LOGICAL_SOURCE_GROUP FROM LoadWindowCte GROUP BY DATA_OBJECT_SOURCE
	)
	INSERT @LoadWindows 
    SELECT 
	  INTERVAL_END_DATETIME_ORDER, 
	  MODULE_CODE,
	  INTERVAL_START_DATETIME,
	  INTERVAL_END_DATETIME,
	  LoadWindowCte.DATA_OBJECT_SOURCE,
	  DATA_OBJECT_TARGET,
	  EXECUTION_STATUS_CODE,
      CHANGE_DELTA_INDICATOR,
      MODULE_INSTANCE_ID,
	  MODULE_ID,
	  CHANGE_FOR_LOGICAL_SOURCE_GROUP
	FROM LoadWindowCte JOIN ChangesPerLogicalSource ON LoadWindowCte.DATA_OBJECT_SOURCE = ChangesPerLogicalSource.DATA_OBJECT_SOURCE


	-- What this captures is the availeble load windows for the incoming modules.
	-- If there is a change (delta change indicator) this means that within a functional group (e.g. per source) there is a change and everything must wait to catch-up (within the context of this source).
	-- The interval end datetime order shows the lowest end-datetime per functional group / source and should be selected usually.
	-- The exception to manage is when other sources are reported up-to-date (no delta change indicators). In this case we must check if there are any waiting records in the PSA.

    IF @Debug = 'Y'
    BEGIN	  
	  PRINT 'The following rows are found interpreting the table array.'
	  DECLARE @xmltmp2 xml = (SELECT * FROM @LoadWindows FOR XML PATH(''))
	  PRINT CONVERT(NVARCHAR(MAX), @xmltmp2)
    END

  END TRY
  BEGIN CATCH
    -- Logging
	SET @EventDetail = 'Error occurred when retrieving the associated load windows. The error is.'+ERROR_MESSAGE();  
	THROW 50000,@EventDetail,1;
  END CATCH
  -- End of load window interpretation


  -- Begin of initialisation interpretation.
  -- This means that at least every target table has to be associated with loading processes into it, otherwise the system is still powering up.
  SELECT @NumberOfExpectedTargetTables = COUNT(TABLE_NAME) FROM @TableNames
  SELECT @NumberOfActualTargetTables = COUNT(DISTINCT DATA_OBJECT_TARGET) FROM @LoadWindows

  IF @Debug = 'Y'
    BEGIN
      PRINT 'The number of expected target tables is: '+CONVERT(VARCHAR(10),@NumberOfExpectedTargetTables);
	  PRINT 'The number of expected target tables is: '+CONVERT(VARCHAR(10),@NumberOfActualTargetTables);
	END

  IF @NumberOfActualTargetTables < @NumberOfExpectedTargetTables
  BEGIN
    IF @Debug = 'Y'
      PRINT 'Difference in actual and expected target table, the Consistency Date/Time is defaulted to NULL';

	SET @ConsistencyDateTime = NULL;
    GOTO EndOfProcedure
  END
  -- End of initialisation interpretation


  -- Begin of up-to-date interpretation.
  -- This means that every process has an 'up-to-date' record, meaning the start- and end date/times for the load windows are the same. A closing record.
  SELECT @ChangeModuleCount = SUM(CHANGE_DELTA_INDICATOR) FROM @LoadWindows

  IF @Debug = 'Y'
    PRINT 'The number deltas (updated load windows) is: '+CONVERT(VARCHAR(10),@ChangeModuleCount);

  IF @ChangeModuleCount = 0
  BEGIN
    PRINT 'There are no changed load windows for any of the corresponding modules, so everything is up to date. The max load window can be used.';
	SELECT @ConsistencyDateTime = MAX(INTERVAL_END_DATETIME) FROM @LoadWindows
    GOTO EndOfProcedure
  END
  -- End of up-to-date interpretation

 
  -- Beginning of load window evaluation.
  IF @Debug = 'Y'
    BEGIN
      PRINT 'Commencing load window evaluation. The lowest load window end date/time denominator is used for further validation. This is the local load window end datetime.'+CHAR(13);
	END

  BEGIN TRY

    --SELECT * FROM @LoadWindows WHERE INTERVAL_END_DATETIME_ORDER=1
	
	DECLARE @ConsistencyDateTimeTable TABLE
    (
      DATA_OBJECT_SOURCE VARCHAR(256),
	  UP_TO_DATE_INDICATOR CHAR(1),
	  CONSISTENCY_DATETIME DATETIME2(7)
    );

    DECLARE @localDataObjectSource VARCHAR(256);
    DECLARE @localIntervalEndDatetime DATETIME2(7);
    DECLARE @localChangeForLogicalGroup CHAR(1);
	DECLARE @localSqlStatement NVARCHAR(MAX);

    DECLARE datetime_cursor CURSOR FOR 
    SELECT
      DATA_OBJECT_SOURCE, 
	  INTERVAL_END_DATETIME, 
  	  CHANGE_FOR_LOGICAL_SOURCE_GROUP
    FROM @LoadWindows 
    WHERE INTERVAL_END_DATETIME_ORDER=1	
  
    OPEN datetime_cursor  
    FETCH NEXT FROM datetime_cursor INTO @localDataObjectSource, @localIntervalEndDatetime, @localChangeForLogicalGroup
  
    WHILE @@FETCH_STATUS = 0  
    BEGIN  

	  IF @Debug = 'Y'
        BEGIN
          PRINT CHAR(13)+'Working on '+@localDataObjectSource+' with change for logical group change indicator '+@localChangeForLogicalGroup+' an local load window end datetime '+CONVERT(VARCHAR(20),@LocalIntervalEndDatetime);
	    END
  
      IF @localChangeForLogicalGroup = 'Y'
	    BEGIN
		   INSERT INTO @ConsistencyDateTimeTable VALUES (@localDataObjectSource, 'N',  @LocalIntervalEndDatetime) 

		   IF @Debug = 'Y'
             PRINT 'There is a change related to this logical group, so the miminum value will be saved for comparison with the other logical groups.';
	    END

      -- If the logical group is up to date, e.g. there are no changes then lookups to the sources are required to assert if there are any outstanding rows.
	  IF @localChangeForLogicalGroup = 'N'
	    BEGIN
		  DECLARE @localSourceMaxDateTime DATETIME2(7);
		  SET @localSqlStatement = 'SELECT @localSourceMaxDateTime=COALESCE(MAX(LOAD_DATETIME),''1900-01-01'')' +
		                           'FROM '+@localDataObjectSource+' sdo '+
								   'JOIN omd.MODULE_INSTANCE modinst ON sdo.module_instance_id=modinst.MODULE_INSTANCE_ID '+
                                   'WHERE 1=1 '+
								   '--AND modinst.EXECUTION_STATUS_CODE=''S'' ' +
								   'AND LOAD_DATETIME <= '''+CONVERT(VARCHAR(100),@MeasurementDateTime)+''''

		  -- Commented out EXECUTION_STATUS_CODE line because uncommitted rows should also be evaluated to prevent gaps in the load windows.
		  -- Otherwise, status changes made to 'S' later on may be left out of the selection.

	      IF @Debug = 'Y'
            PRINT @localSqlStatement;

		  EXECUTE sp_executesql @localSqlStatement, N'@localSourceMaxDateTime DATETIME2(7) OUTPUT',@localSourceMaxDateTime=@localSourceMaxDateTime OUTPUT

		  IF @Debug = 'Y'
		    PRINT 'High water mark (localSourceMaxDateTime) in source table is: '+CONVERT(VARCHAR(20),@localSourceMaxDateTime);

		  IF @localSourceMaxDateTime <= @localIntervalEndDatetime -- This table/mapping is up to date, and the results are not necessary to be considered.
		    BEGIN
			  INSERT INTO @ConsistencyDateTimeTable VALUES (@localDataObjectSource, 'Y',  @LocalIntervalEndDatetime) 

			  IF @Debug = 'Y'
			  BEGIN
			    PRINT 'The high water mark (localSourceMaxDateTime) is the same as the load window. This source/target mapping is up to date.';
				PRINT 'The results can be eliminated from the algorithm, but is the consistency date/time is updated if null.';
			  END

			END
		  ELSE -- E.g. the values in the source are exceeding the load windows for the target
		    BEGIN
			  INSERT INTO @ConsistencyDateTimeTable VALUES (@localDataObjectSource, 'N',  @LocalIntervalEndDatetime) 
			  IF @Debug = 'Y'
			    PRINT 'The high water mark (localSourceMaxDateTime) higher than the load window. There is a lag that needs to be managed.';
			END	  
		END

  	  FETCH NEXT FROM datetime_cursor INTO @localDataObjectSource, @localIntervalEndDatetime, @localChangeForLogicalGroup
    END 

    CLOSE datetime_cursor  
    DEALLOCATE datetime_cursor

  END TRY
  BEGIN CATCH
      -- Logging
	SET @EventDetail = 'The error is: '+ERROR_MESSAGE();  
	THROW 50000,@EventDetail,1;
  END CATCH
  -- End load window evaluation.

  
  -- Final step calculate the consistency date/time using the condensed results for each logical group
  BEGIN TRY
    --SELECT * FROM @ConsistencyDateTimeTable
    SELECT @ConsistencyDateTime = MIN(CONSISTENCY_DATETIME) FROM @ConsistencyDateTimeTable WHERE UP_TO_DATE_INDICATOR='N'
  END TRY
  BEGIN CATCH
    -- Logging
	SET @EventDetail = ERROR_MESSAGE();  
	THROW 50000,@EventDetail,1;
  END CATCH
  -- End of table interpretation


  EndOfProcedure:
  -- End label

  IF @Debug = 'Y'
  BEGIN
    PRINT 'End of procedure GetConsistencyDateTime';
	PRINT 'Consistency date/time is '+COALESCE(CONVERT(VARCHAR(20),@ConsistencyDateTime),'NULL');
  END

  
END