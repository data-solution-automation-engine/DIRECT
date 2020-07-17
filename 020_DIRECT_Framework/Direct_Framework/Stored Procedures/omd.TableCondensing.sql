CREATE PROCEDURE [omd].[TableCondensing]
                @DatabaseName VARCHAR(100),
                @SchemaName VARCHAR(100),
                @Table VARCHAR(100)                
AS

BEGIN

DECLARE @ColumnList VARCHAR(MAX)
DECLARE @KeyList VARCHAR(MAX);

-- Create a list of columns that need to be taken into evaluation for condensing (checksum)
SELECT @ColumnList =
''''+
stuff
(
                (
                                SELECT DISTINCT ', ' + COLUMN_NAME
                                FROM INFORMATION_SCHEMA.COLUMNS 
                                                WHERE TABLE_NAME = @Table AND TABLE_SCHEMA = @SchemaName
                                AND COLUMN_NAME NOT IN
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
--PRINT 'Column list = '+@ColumnList


-- Create a list of keys for use in the window functions and joins
SELECT @KeyList =
''''+
stuff
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
--PRINT 'Key list = '+@KeyList;


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
)
, table_names
AS     
(
SELECT LTRIM(RTRIM(REPLACE(DATA_STORE_CODE,'''',''))) AS COLUMN_NAME 
FROM 
    (
                SELECT 
                DISTINCT DATA_STORE_CODE = substring(@ColumnList, starting_position, 
                                                                                                                                                                CASE WHEN end_position = 0 
                                                                                                                                                                THEN len(@ColumnList)
                                                                                                                                                                ELSE end_position - starting_position 
                                                                                                                                                                END) FROM cteSplits
                ) RemoveTrim
)
SELECT COLUMN_NAME
FROM table_names

OPEN column_cursor

FETCH NEXT FROM column_cursor
INTO @ColumnName

WHILE @@FETCH_STATUS = 0
BEGIN

                SET @HashSnippet = @HashSnippet + '    COALESCE(CONVERT(NVARCHAR(100), '+@ColumnName+'),''!$-'') + ''#$%'' +' + CHAR(13);

FETCH NEXT FROM column_cursor INTO @ColumnName

END
CLOSE column_cursor
DEALLOCATE column_cursor

SET @HashSnippet = LEFT(@HashSnippet,DATALENGTH(@HashSnippet)-2)+CHAR(13);
--PRINT @HashSnippet


-- Build the dynamic SQL
DECLARE @FinalQuery NVARCHAR(MAX);

SET @FinalQuery = 'WITH CondensingCTE AS'+CHAR(13);
SET @FinalQuery = @FinalQuery + '('+CHAR(13);
SET @FinalQuery = @FinalQuery + 'SELECT'+CHAR(13);
SET @FinalQuery = @FinalQuery + '  HASHBYTES(''MD5'','+CHAR(13);
SET @FinalQuery = @FinalQuery + @HashSnippet;
SET @FinalQuery = @FinalQuery + '  ) AS FULL_ROW_CHECKSUM,'+CHAR(13);
SET @FinalQuery = @FinalQuery + '  *'+CHAR(13);
SET @FinalQuery = @FinalQuery + 'FROM '+@DatabaseName+'.'+@SchemaName+'.'+@Table+CHAR(13);
SET @FinalQuery = @FinalQuery + '), Subselect AS'+CHAR(13);
SET @FinalQuery = @FinalQuery + '('+CHAR(13);
SET @FinalQuery = @FinalQuery + 'SELECT'+CHAR(13);
SET @FinalQuery = @FinalQuery + '  OMD_CHANGE_KEY,'+CHAR(13);
SET @FinalQuery = @FinalQuery + '  FULL_ROW_CHECKSUM,'+CHAR(13);
SET @FinalQuery = @FinalQuery + '  LAG(FULL_ROW_CHECKSUM) OVER (PARTITION BY '+@KeyList+' ORDER BY OMD_CHANGE_KEY) AS NEXT_FULL_ROW_CHECKSUM'+CHAR(13);
SET @FinalQuery = @FinalQuery + 'FROM CondensingCTE'+CHAR(13);
SET @FinalQuery = @FinalQuery + ')'+CHAR(13);
SET @FinalQuery = @FinalQuery + 'DELETE FROM Subselect'+CHAR(13);
SET @FinalQuery = @FinalQuery + 'WHERE FULL_ROW_CHECKSUM=NEXT_FULL_ROW_CHECKSUM'+CHAR(13);

-- Spool the results
--PRINT @FinalQuery
EXECUTE sp_executesql @FinalQuery;

END
