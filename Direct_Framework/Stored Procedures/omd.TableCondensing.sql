/*******************************************************************************
 * [omd].[TableCondensing]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Condenses tables in SQL Server by removing duplicate subsequent
 *   rows in a timeline.
 *
 * Inputs:
 *   - Database Name
 *   - Schema Name
 *   - Table Name
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

TBA

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[TableCondensing]
(
  -- Mandatory parameters
  @DatabaseName             NVARCHAR(1000),
  @SchemaName               NVARCHAR(1000),
  @Table                    NVARCHAR(1000),
  -- Optional parameters
  @Debug                    CHAR(1) = 'N',
  -- Output parameters
  @SuccessIndicator         CHAR(1)        = 'N' OUTPUT,
  @MessageLog               NVARCHAR(MAX)  = NULL OUTPUT
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
  SET @LogMessage = @DatabaseName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @DatabaseName', @LogMessage, @MessageLog)
  SET @LogMessage = @SchemaName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @SchemaName', @LogMessage, @MessageLog)
  SET @LogMessage = @Table;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @Table', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  -- Local procedure variables
  DECLARE @ColumnList VARCHAR(MAX)
  DECLARE @KeyList VARCHAR(MAX);

  -- Create a list of columns that need to be taken into evaluation for condensing (checksum)
  SELECT @ColumnList =
    ''''+
    STUFF
    (
      (
        SELECT DISTINCT ', ' + COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE
          TABLE_NAME = @Table AND
          TABLE_SCHEMA = @SchemaName AND
          COLUMN_NAME NOT IN
          (
            'OMD_EVENT_DATETIME',
            'OMD_INSERT_DATETIME',
            'OMD_INSERT_MODULE_INSTANCE_ID',
            'OMD_SOURCE_ROW_ID',
            'OMD_HASH_FULL_RECORD',
            'OMD_CHANGE_KEY',
            'OMD_CHANGE_DATETIME'
          )
        FOR XML PATH('')
      ),
      1,
      1,
      ''
    )
    + ''''

  SELECT @ColumnList = LTRIM(RTRIM(@ColumnList));

  IF @Debug = 'Y'
  BEGIN
    PRINT 'Column list = ' + @ColumnList
  END

  -- Create a list of keys for use in the window functions and joins
  SELECT @KeyList =
    ''''+
    STUFF
    (
      (
        SELECT DISTINCT ', ' + COLUMN_NAME
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
        INNER JOIN
          INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KU
          ON TC.CONSTRAINT_TYPE = 'PRIMARY KEY' AND
            TC.CONSTRAINT_NAME = KU.CONSTRAINT_NAME AND
            KU.TABLE_NAME=@Table
        WHERE COLUMN_NAME NOT LIKE 'OMD_%'
        FOR XML PATH('')
      ),
      1,
      1,
      ''
    )
    + ''''

  SELECT @KeyList = REPLACE(LTRIM(RTRIM(@KeyList)),'''','');

  IF @Debug = 'Y'
  BEGIN
    PRINT 'Key list = ' + @KeyList;
  END

  -- Translating back
  DECLARE @HashSnippet VARCHAR(MAX);
  SET @HashSnippet = '';

  DECLARE @ColumnName VARCHAR(MAX);

  DECLARE column_cursor CURSOR FOR

  WITH cteSplits(starting_position, end_position)
  AS
  (
    SELECT CAST(1 AS BIGINT), CHARINDEX(',', @ColumnList)
    UNION ALL
    SELECT end_position + 1, charindex(',', @ColumnList, end_position + 1)
    FROM cteSplits
    WHERE end_position > 0 -- Another delimiter was found
  ),
  table_names
  AS
  (
    SELECT LTRIM(RTRIM(REPLACE(DATA_STORE_CODE,'''',''))) AS COLUMN_NAME
    FROM
    (
      SELECT
      DISTINCT DATA_STORE_CODE = substring
      (
          @ColumnList, starting_position,
          CASE WHEN end_position = 0
          THEN len(@ColumnList)
          ELSE end_position - starting_position
          END
      ) FROM cteSplits
    ) RemoveTrim
  )

  SELECT COLUMN_NAME
  FROM table_names

  OPEN column_cursor

    FETCH NEXT FROM column_cursor
    INTO @ColumnName

    WHILE @@FETCH_STATUS = 0
    BEGIN

      SET @HashSnippet = @HashSnippet + '    COALESCE(CONVERT(NVARCHAR(100), ' + @ColumnName + '),''!$-'') + ''#$%'' +' + CHAR(10);

      FETCH NEXT FROM column_cursor INTO @ColumnName

    END
  CLOSE column_cursor
  DEALLOCATE column_cursor

  SET @HashSnippet = LEFT(@HashSnippet,DATALENGTH(@HashSnippet)-2)+CHAR(10);

  IF @Debug = 'Y'
  BEGIN
    PRINT @HashSnippet
  END

  -- Build the dynamic SQL
  DECLARE @FinalQuery NVARCHAR(MAX);

  SET @FinalQuery = 'WITH CondensingCTE AS' + CHAR(10);
  SET @FinalQuery = @FinalQuery + '(' + CHAR(10);
  SET @FinalQuery = @FinalQuery + 'SELECT' + CHAR(10);
  SET @FinalQuery = @FinalQuery + '  HASHBYTES(''MD5'',' + CHAR(10);
  SET @FinalQuery = @FinalQuery + @HashSnippet;
  SET @FinalQuery = @FinalQuery + '  ) AS FULL_ROW_CHECKSUM,' + CHAR(10);
  SET @FinalQuery = @FinalQuery + '  *' + CHAR(10);
  SET @FinalQuery = @FinalQuery + 'FROM ' + @DatabaseName + '.' + @SchemaName + '.' + @Table+CHAR(10);
  SET @FinalQuery = @FinalQuery + '), Subselect AS' + CHAR(10);
  SET @FinalQuery = @FinalQuery + '(' + CHAR(10);
  SET @FinalQuery = @FinalQuery + 'SELECT' + CHAR(10);
  SET @FinalQuery = @FinalQuery + '  OMD_CHANGE_KEY,' + CHAR(10);
  SET @FinalQuery = @FinalQuery + '  FULL_ROW_CHECKSUM,' + CHAR(10);
  SET @FinalQuery = @FinalQuery + '  LAG(FULL_ROW_CHECKSUM) OVER (PARTITION BY ' + @KeyList + ' ORDER BY OMD_CHANGE_KEY) AS NEXT_FULL_ROW_CHECKSUM' + CHAR(10);
  SET @FinalQuery = @FinalQuery + 'FROM CondensingCTE' + CHAR(10);
  SET @FinalQuery = @FinalQuery + ')' + CHAR(10);
  SET @FinalQuery = @FinalQuery + 'DELETE FROM Subselect' + CHAR(10);
  SET @FinalQuery = @FinalQuery + 'WHERE FULL_ROW_CHECKSUM = NEXT_FULL_ROW_CHECKSUM' + CHAR(10);

  -- Spool the resulting query
  IF @Debug = 'Y'
  BEGIN
    PRINT @FinalQuery
  END

  EXECUTE sp_executesql @FinalQuery;

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
