/*******************************************************************************
 * [omd].[GetConsistencyTimestamp]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Get a Consistency Timestamp
 *   For a given point in time, data will be consistent up to the lowest load
 *   window end-date of the most-recently successfully completed process
 *   execution instances involved in loading the target tables.
 *
 * Inputs:
 *   - Table list (comma separated array)
 *   - Measurement Date/Time (optional)
 *   - Load Window Attribute (optional)
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Consistency Date/Time
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

DECLARE @ConsistencyTimestamp DATETIME2;

EXEC [omd].[GetConsistencyTimestamp]
  @TableList ='HUB_CUSTOMER, SAT_CUSTOMER, SAT_CUSTOMER_ADDITIONAL_DETAILS',
  @LoadWindowAttributeName = 'LOAD_DATETIME',
  @Debug = 'Y',
  @ConsistencyTimestamp = @ConsistencyTimestamp OUTPUT;

PRINT @ConsistencyDateTime;

 *******************************************************************************
 *
 *******************************************************************************/

CREATE PROCEDURE [omd].[GetConsistencyTimestamp]
(
  -- Mandatory parameters
  @TableList                VARCHAR(MAX),
  -- Optional parameters
  @MeasurementDateTime      DATETIME2(7)  = NULL,
  @LoadWindowAttributeName  VARCHAR(255)  = 'LOAD_DATETIME',
  @Debug                    CHAR(1)       = 'N',
  -- Output parameters
  @ConsistencyDateTime      DATETIME2(7)  = NULL OUTPUT,
  @SuccessIndicator         CHAR(1)       = 'N' OUTPUT,
  @MessageLog               NVARCHAR(MAX) = N'' OUTPUT
)

AS
BEGIN TRY

  -- Default output logging setup
  DECLARE @SpName NVARCHAR(100) = N'[' + OBJECT_SCHEMA_NAME(@@PROCID) + '].[' + OBJECT_NAME(@@PROCID) + ']';
  DECLARE @DirectVersion NVARCHAR(10) = [omd_metadata].[GetFrameworkVersion]();
  DECLARE @StartTimestamp DATETIME = SYSUTCDATETIME();
  DECLARE @StartTimestampString NVARCHAR(20) = FORMAT(@StartTimestamp, 'yyyy-MM-dd HH:mm:ss.fffffff');
  DECLARE @EndTimestamp DATETIME = NULL;
  DECLARE @EndTimestampString NVARCHAR(20) = N'';
  DECLARE @LogMessage NVARCHAR(MAX);

  -- Log standard metadata
  SET @LogMessage = @SpName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Procedure', @LogMessage, @MessageLog)
  SET @LogMessage = @DirectVersion;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Version',@LogMessage, @MessageLog)
  SET @LogMessage = @StartTimestampString;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Start Timestamp', @LogMessage, @MessageLog)

  -- Log parameters
  SET @LogMessage = @TableList;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @TableList', @LogMessage, @MessageLog)
  SET @LogMessage = @MeasurementDateTime;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @MeasurementDateTime', @LogMessage, @MessageLog)
  SET @LogMessage = @LoadWindowAttributeName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @LoadWindowAttributeName', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

 -- Input variables, for debugging only and commented out
 --DECLARE @TableList VARCHAR(MAX) ='HUB_CUSTOMER, SAT_CUSTOMER, SAT_CUSTOMER_ADDITIONAL_DETAILS'
 --DECLARE @MeasurementDateTime DATETIME2(7) = SYSUTCDATETIME();
 --DECLARE @Debug  CHAR(1) = 'Y';
 --DECLARE @ConsistencyDateTime DATETIME2(7);
 -- End of debug block

 IF @MeasurementDateTime IS NULL
  SET @MeasurementDateTime = SYSUTCDATETIME();

 DECLARE @NumberOfExpectedTargetTables INT;-- This is the number of tables expected to be loading, based on the input table array (table list).
 DECLARE @NumberOfActualTargetTables INT;-- This is the number of tables found in the load window / module instance list. It needs to be the same as the expected target tables.
  -- If the number of actual target tables is lower than the expected target tables, some of the targets have never been loaded and the process should default to NULL.
  -- This can happen when the whole system is truncated, or started anew.
 DECLARE @ChangeModuleCount INT;-- The number of changes, as per changes in the load window. This is the sum of the delta change indicator.
  -- If there are no changes, the max load window can be used as it wouldn't have changed.

 IF @Debug = 'Y'
 BEGIN
  PRINT 'Measurement date /time is ' + CONVERT(VARCHAR(20), @MeasurementDateTime);
  PRINT 'Consistency date time algorithm started for input table array:';
  PRINT @TableList
 END

 DECLARE @TableNames TABLE (TABLE_NAME VARCHAR(MAX));

 -- Region table name interpretation
 BEGIN TRY
  -- Remove spaces and quotes
  SET @TableList = REPLACE(@TableList, ' ', '');
  SET @TableList = REPLACE(@TableList, '''', '');

  -- Splitting the Table_List variable array into rows
  -- Would fail if passed a list of more than 100 tables
  WITH cteSplits (starting_position, end_position)
  AS (
   SELECT CAST(1 AS BIGINT), CHARINDEX(',', @TableList)

   UNION ALL

   SELECT end_position + 1, charindex(',', @TableList, end_position + 1)
   FROM cteSplits
   WHERE end_position > 0 -- Another delimiter was found
   ), table_names
  AS (
   SELECT DISTINCT DATA_STORE_CODE = substring(@TableList, starting_position, CASE WHEN end_position = 0 THEN len(@TableList) ELSE end_position - starting_position END)
   FROM cteSplits
   )
  INSERT @TableNames
  SELECT *
  FROM table_names

  IF @Debug = 'Y'
  BEGIN
   PRINT 'The following rows are found interpreting the table array.'

   DECLARE @xmltmp XML = (
     SELECT *
     FROM @TableNames
     FOR XML PATH('')
     )

   PRINT CONVERT(NVARCHAR(MAX), @xmltmp)
  END
 END TRY

 BEGIN CATCH
  -- Logging
  SET @EventDetail = 'Error occurred when transposing table array. The error is.' + ERROR_MESSAGE();

  THROW 50000, @EventDetail, 1;
 END CATCH

 -- End of table interpretation
 -- Load window interpretation
 IF @Debug = 'Y'
  PRINT 'Commencing load window retrieval';

 DECLARE @LoadWindows TABLE (INTERVAL_END_TIMESTAMP_ORDER INT, MODULE_CODE VARCHAR(256), START_VALUE DATETIME2(7), END_VALUE DATETIME2(7), DATA_OBJECT_SOURCE VARCHAR(256), DATA_OBJECT_TARGET VARCHAR(256), EXECUTION_STATUS_CODE CHAR(1), CHANGE_DELTA_INDICATOR INT, MODULE_INSTANCE_ID INT, MODULE_ID INT, CHANGE_FOR_LOGICAL_SOURCE_GROUP CHAR(1));

 BEGIN TRY
  WITH LoadWindowCte
  AS (
   SELECT ROW_NUMBER() OVER (
     PARTITION BY DATA_OBJECT_SOURCE ORDER BY DATA_OBJECT_SOURCE, END_VALUE
     ) AS INTERVAL_END_TIMESTAMP_ORDER, MODULE_CODE, START_VALUE, END_VALUE, DATA_OBJECT_SOURCE, DATA_OBJECT_TARGET, EXECUTION_STATUS_CODE, CHANGE_DELTA_INDICATOR, MODULE_INSTANCE_ID, MODULE_ID
   FROM (
    SELECT module.MODULE_CODE, sct.START_VALUE, sct.END_VALUE, module.DATA_OBJECT_SOURCE, module.DATA_OBJECT_TARGET, modinst.EXECUTION_STATUS_CODE, CASE WHEN sct.START_VALUE = sct.END_VALUE THEN 0 ELSE 1 END AS CHANGE_DELTA_INDICATOR, ROW_NUMBER() OVER (
      PARTITION BY COALESCE(modinst.MODULE_ID, 0) ORDER BY modinst.MODULE_INSTANCE_ID DESC
      ) AS ROW_ORDER, sct.MODULE_INSTANCE_ID, modinst.MODULE_ID
    FROM omd.MODULE_INSTANCE modinst
    JOIN omd.SOURCE_CONTROL sct ON modinst.MODULE_INSTANCE_ID = sct.MODULE_INSTANCE_ID
    JOIN omd.MODULE module ON modinst.MODULE_ID = module.MODULE_ID
    JOIN -- Only join modules that relate to the intended target tables.
     (
     SELECT MODULE_ID
     FROM omd.MODULE
     INNER JOIN @TableNames table_names ON LTRIM(table_names.TABLE_NAME) = omd.MODULE.DATA_OBJECT_TARGET
     ) module_tables ON modinst.MODULE_ID = module_tables.MODULE_ID
    WHERE 1 = 1 AND module.ACTIVE_INDICATOR = 'Y' AND modinst.EXECUTION_STATUS_CODE = 'Succeeded' AND sct.END_VALUE <= @MeasurementDateTime
    ) sub
   WHERE ROW_ORDER = 1
   ), ChangesPerLogicalSource
  AS (
   SELECT DATA_OBJECT_SOURCE, CASE WHEN SUM(CHANGE_DELTA_INDICATOR) > 0 THEN 'Y' ELSE 'N' END AS CHANGE_FOR_LOGICAL_SOURCE_GROUP
   FROM LoadWindowCte cte
   GROUP BY DATA_OBJECT_SOURCE
   )
  INSERT @LoadWindows
  SELECT INTERVAL_END_TIMESTAMP_ORDER, MODULE_CODE, START_VALUE, END_VALUE, LoadWindowCte.DATA_OBJECT_SOURCE, DATA_OBJECT_TARGET, EXECUTION_STATUS_CODE, CHANGE_DELTA_INDICATOR, MODULE_INSTANCE_ID, MODULE_ID, CHANGE_FOR_LOGICAL_SOURCE_GROUP
  FROM LoadWindowCte
  INNER JOIN ChangesPerLogicalSource ON LoadWindowCte.DATA_OBJECT_SOURCE = ChangesPerLogicalSource.DATA_OBJECT_SOURCE

  -- What this captures is the available load windows for the incoming modules.
  -- If there is a change (delta change indicator) this means that within a functional group (e.g. per source) there is a change and everything must wait to catch-up (within the context of this source).
  -- The interval end datetime order shows the lowest end-datetime per functional group / source and should be selected usually.
  -- The exception to manage is when other sources are reported up-to-date (no delta change indicators). In this case we must check if there are any waiting records in the PSA.
  IF @Debug = 'Y'
  BEGIN
   PRINT 'The following rows are found interpreting the table array.'

   DECLARE @xmltmp2 XML = (
     SELECT *
     FROM @LoadWindows
     FOR XML PATH('')
     )

   PRINT CONVERT(NVARCHAR(MAX), @xmltmp2)
  END
 END TRY

 BEGIN CATCH
  -- Logging
  SET @EventDetail = 'Error occurred when retrieving the associated load windows. The error is.' + ERROR_MESSAGE();

  THROW 50000, @EventDetail, 1;
 END CATCH

 -- End of load window interpretation
 -- Begin of initialisation interpretation.
 -- This means that at least every target table has to be associated with loading processes into it, otherwise the system is still powering up.
 SELECT @NumberOfExpectedTargetTables = COUNT(TABLE_NAME)
 FROM @TableNames

 SELECT @NumberOfActualTargetTables = COUNT(DISTINCT DATA_OBJECT_TARGET)
 FROM @LoadWindows

 IF @Debug = 'Y'
 BEGIN
  PRINT 'The number of expected target tables is: ' + CONVERT(VARCHAR(10), @NumberOfExpectedTargetTables);
  PRINT 'The number of expected target tables is: ' + CONVERT(VARCHAR(10), @NumberOfActualTargetTables);
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
 SELECT @ChangeModuleCount = SUM(CHANGE_DELTA_INDICATOR)
 FROM @LoadWindows

 IF @Debug = 'Y'
  PRINT 'The number deltas (updated load windows) is: ' + CONVERT(VARCHAR(10), @ChangeModuleCount);

 IF @ChangeModuleCount = 0
 BEGIN
  PRINT 'There are no changed load windows for any of the corresponding modules, so everything is up to date. The max load window can be used.';

  SELECT @ConsistencyDateTime = MAX(END_VALUE)
  FROM @LoadWindows

  GOTO EndOfProcedure
 END

 -- End of up-to-date interpretation
 -- Beginning of load window evaluation.
 IF @Debug = 'Y'
 BEGIN
  PRINT 'Commencing load window evaluation. The lowest load window end date/time denominator is used for further validation. This is the local load window end datetime.' + CHAR(10);
 END

 BEGIN TRY
  --SELECT * FROM @LoadWindows WHERE INTERVAL_END_TIMESTAMP_ORDER=1
  DECLARE @ConsistencyDateTimeTable TABLE (DATA_OBJECT_SOURCE VARCHAR(256), UP_TO_DATE_INDICATOR CHAR(1), CONSISTENCY_DATETIME DATETIME2(7));
  DECLARE @localDataObjectSource VARCHAR(256);
  DECLARE @localIntervalEndDatetime DATETIME2(7);
  DECLARE @localChangeForLogicalGroup CHAR(1);
  DECLARE @localSqlStatement NVARCHAR(MAX);

  DECLARE datetime_cursor CURSOR
  FOR
  SELECT DATA_OBJECT_SOURCE, END_VALUE, CHANGE_FOR_LOGICAL_SOURCE_GROUP
  FROM @LoadWindows
  WHERE INTERVAL_END_TIMESTAMP_ORDER = 1

  OPEN datetime_cursor

  FETCH NEXT
  FROM datetime_cursor
  INTO @localDataObjectSource, @localIntervalEndDatetime, @localChangeForLogicalGroup

  WHILE @@FETCH_STATUS = 0
  BEGIN
   IF @Debug = 'Y'
   BEGIN
    PRINT CHAR(10) + 'Working on ' + @localDataObjectSource + ' with change for logical group change indicator ' + @localChangeForLogicalGroup + ' an local load window end datetime ' + CONVERT(VARCHAR(20), @localIntervalEndDatetime);
   END

   IF @localChangeForLogicalGroup = 'Y'
   BEGIN
    INSERT INTO @ConsistencyDateTimeTable
    VALUES (@localDataObjectSource, 'N', @localIntervalEndDatetime)

    IF @Debug = 'Y'
     PRINT 'There is a change related to this logical group, so the miminum value will be saved for comparison with the other logical groups.';
   END

   -- If the logical group is up to date, e.g. there are no changes then lookups to the sources are required to assert if there are any outstanding rows.
   IF @localChangeForLogicalGroup = 'N'
   BEGIN
    DECLARE @localSourceMaxDateTime DATETIME2(7);

    SET @localSqlStatement = 'SELECT @localSourceMaxDateTime=COALESCE(MAX(LOAD_DATETIME),''1900-01-01'')' + 'FROM ' + @localDataObjectSource + ' sdo ' + 'JOIN omd.MODULE_INSTANCE modinst ON sdo.module_instance_id=modinst.MODULE_INSTANCE_ID ' + 'WHERE 1=1 ' + '--AND modinst.EXECUTION_STATUS_CODE=''Succeeded ' + 'AND LOAD_DATETIME <= ''' + CONVERT(VARCHAR(100), @MeasurementDateTime) + ''''

    -- Commented out EXECUTION_STATUS_CODE line because uncommitted rows should also be evaluated to prevent gaps in the load windows.
    -- Otherwise, status changes made to 'Succeeded' later on may be left out of the selection.
    IF @Debug = 'Y'
     PRINT @localSqlStatement;

    EXECUTE sp_executesql @localSqlStatement, N'@localSourceMaxDateTime DATETIME2(7) OUTPUT', @localSourceMaxDateTime = @localSourceMaxDateTime OUTPUT

    IF @Debug = 'Y'
     PRINT 'High water mark (localSourceMaxDateTime) in source table is: ' + CONVERT(VARCHAR(20), @localSourceMaxDateTime);

    IF @localSourceMaxDateTime <= @localIntervalEndDatetime -- This table/mapping is up to date, and the results are not necessary to be considered.
    BEGIN
     INSERT INTO @ConsistencyDateTimeTable
     VALUES (@localDataObjectSource, 'Y', @localIntervalEndDatetime)

     IF @Debug = 'Y'
     BEGIN
      PRINT 'The high water mark (localSourceMaxDateTime) is the same as the load window. This source/target mapping is up to date.';
      PRINT 'The results can be eliminated from the algorithm, but is the consistency date/time is updated if null.';
     END
    END
    ELSE -- E.g. the values in the source are exceeding the load windows for the target
    BEGIN
     INSERT INTO @ConsistencyDateTimeTable
     VALUES (@localDataObjectSource, 'N', @localIntervalEndDatetime)

     IF @Debug = 'Y'
      PRINT 'The high water mark (localSourceMaxDateTime) higher than the load window. There is a lag that needs to be managed.';
    END
   END

   FETCH NEXT
   FROM datetime_cursor
   INTO @localDataObjectSource, @localIntervalEndDatetime, @localChangeForLogicalGroup
  END

  CLOSE datetime_cursor

  DEALLOCATE datetime_cursor
 END TRY

 BEGIN CATCH
  -- Logging
  SET @EventDetail = 'The error is: ' + ERROR_MESSAGE();

  THROW 50000, @EventDetail, 1;
 END CATCH

 -- End load window evaluation.
 -- Final step calculate the consistency date/time using the condensed results for each logical group
 BEGIN TRY
  --SELECT * FROM @ConsistencyDateTimeTable
  SELECT @ConsistencyDateTime = MIN(CONSISTENCY_DATETIME)
  FROM @ConsistencyDateTimeTable
  WHERE UP_TO_DATE_INDICATOR = 'N'
 END TRY

 BEGIN CATCH
  -- Logging
  SET @EventDetail = ERROR_MESSAGE();

  THROW 50000, @EventDetail, 1;
 END CATCH

 -- End label
 IF @Debug = 'Y'
 BEGIN
  PRINT 'End of procedure GetConsistencyDateTime';
  PRINT 'Consistency date/time is ' + COALESCE(CONVERT(VARCHAR(20), @ConsistencyDateTime), 'NULL');
 END

  -- End of procedure label
  EndOfProcedure:

  SET @EndTimestamp = SYSUTCDATETIME();
  SET @EndTimestampString = FORMAT(@EndTimestamp, 'yyyy-MM-dd HH:mm:ss.fffffff');
  SET @LogMessage = @EndTimestampString;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'End Timestamp', @LogMessage, @MessageLog)
  SET @LogMessage = DATEDIFF(SECOND, @StartTimestamp, @EndTimestamp);
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Elapsed Time (s)', @LogMessage, @MessageLog)
  SET @LogMessage = @SuccessIndicator;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @SuccessIndicator', @LogMessage, @MessageLog)

  IF @Debug = 'Y'
  BEGIN
    EXEC [omd].[PrintMessageLog] @MessageLog;
  END

END TRY
BEGIN CATCH
  -- SP-wide error handler and logging
  SET @SuccessIndicator = 'N'
  SET @LogMessage = @SuccessIndicator;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @SuccessIndicator', @LogMessage, @MessageLog)

  DECLARE @ErrorMessage NVARCHAR(4000);
  DECLARE @ErrorSeverity INT;
  DECLARE @ErrorState INT;
  DECLARE @ErrorProcedure NVARCHAR(128);
  DECLARE @ErrorNumber INT;
  DECLARE @ErrorLine INT;

  SELECT
    @ErrorMessage   = COALESCE(ERROR_MESSAGE(),     'No Message'    ),
    @ErrorSeverity  = COALESCE(ERROR_SEVERITY(),    -1              ),
    @ErrorState     = COALESCE(ERROR_STATE(),       -1              ),
    @ErrorProcedure = COALESCE(ERROR_PROCEDURE(),   'No Procedure'  ),
    @ErrorLine      = COALESCE(ERROR_LINE(),        -1              ),
    @ErrorNumber    = COALESCE(ERROR_NUMBER(),      -1              );

  IF @Debug = 'Y'
  BEGIN
    PRINT 'Error in '''       + @SpName + ''''
    PRINT 'Error Message: '   + @ErrorMessage
    PRINT 'Error Severity: '  + CONVERT(NVARCHAR(10), @ErrorSeverity)
    PRINT 'Error State: '     + CONVERT(NVARCHAR(10), @ErrorState)
    PRINT 'Error Procedure: ' + @ErrorProcedure
    PRINT 'Error Line: '      + CONVERT(NVARCHAR(10), @ErrorLine)
    PRINT 'Error Number: '    + CONVERT(NVARCHAR(10), @ErrorNumber)
    PRINT 'SuccessIndicator: '+ @SuccessIndicator

    -- Spool message log
    EXEC [omd].[PrintMessageLog] @MessageLog;

  END

  SET @EventDetail = 'Error in ''' + COALESCE(@SpName,'N/A') + ''' from ''' + COALESCE(@ErrorProcedure,'N/A') + ''' at line ''' + CONVERT(NVARCHAR(10), COALESCE(@ErrorLine,'N/A')) + ''': '+ CHAR(10) + COALESCE(@ErrorMessage,'N/A');
  SET @EventReturnCode = ERROR_NUMBER();

  EXEC [omd].[InsertIntoEventLog]
    @EventDetail       = @EventDetail,
    @EventReturnCode   = @EventReturnCode;

  THROW
END CATCH
