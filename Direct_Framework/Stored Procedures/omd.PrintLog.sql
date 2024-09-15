/*******************************************************************************
 * [omd].[PrintMessageLog]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Pretty Prints a message log
 *
 * Inputs:
 *   - Message Log
 *
 * Output:
 *   - Pretty Printed Log
 *     (note: the output is displayed in the Messages tab/output.
 *     It is not delivered to the client as a result set)
 *
 * Usage:
 *
 *******************************************************************************

DECLARE @MessageLog NVARCHAR(MAX);
SET @MessageLog =
  N'[{"severity":"INFO",' +
  N'"timestamp":"2001-12-26T12:23:18",' +
  N'"key":"Parameter Parsing",' +
  N'"message":"Starting special parameter parsing process"},'+
  N'{"severity":"WARNING",' +
  N'"timestamp":"2001-12-26T12:23:19",' +
  N'"key":"Value Parsing",' +
  N'"message":"The parsing of ''2319'' as event code failed"}]'

EXEC [omd].[PrintMessageLog]
  @MessageLog = @MessageLog

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[PrintMessageLog]
(
  -- Mandatory Parameters
  @MessageLog               NVARCHAR(MAX)
)
AS
BEGIN
  SET NOCOUNT ON;
  SET ANSI_WARNINGS OFF;

  DECLARE @tempTable TABLE
  (
    [Id]        INT IDENTITY(1,1),
    [Severity]  NVARCHAR(100),
    [Timestamp] NVARCHAR(100),
    [Key]       NVARCHAR(1000),
    [Message]   NVARCHAR(MAX)
  )

  INSERT INTO @tempTable ([Severity], [Timestamp], [Key], [Message])
  SELECT [Severity], [Timestamp], [Key], [Message]
  FROM OPENJSON(@MessageLog)
  WITH (
    [Severity]  NVARCHAR(100)   '$.severity',
    [Timestamp] NVARCHAR(100)   '$.timestamp',
    [Key]       NVARCHAR(1000)  '$.key',
    [Message]   NVARCHAR(MAX)   '$.message'
  )

  DECLARE
    @TableLine      NVARCHAR(200) = REPLICATE('-', 170),
    @PrintSeverity  NVARCHAR(100),
    @PrintTimestamp NVARCHAR(100),
    @PrintKey       NVARCHAR(1000),
    @PrintMessage   NVARCHAR(MAX),

    @index          INT = 1,
    @count          INT = (SELECT COUNT(1) FROM @tempTable);

  -- Table Header
  PRINT @TableLine;
  PRINT '| ' +
    LEFT('Severity'   + SPACE(8), 8)      + ' | ' +
    LEFT('Timestamp'  + SPACE(19), 19)    + ' | ' +
    LEFT('Key'        + SPACE(30), 30)    + ' | ' +
    LEFT('Message'    + SPACE(100), 100)  + ' |';
  PRINT @TableLine;

  WHILE @index <= @count
  BEGIN
    SELECT
      @PrintSeverity    = [Severity],
      @PrintTimestamp   = FORMAT(CAST([Timestamp] AS DATETIME2), 'yyyy-MM-dd HH:mm:ss'),
      @PrintKey         = [Key],
      @PrintMessage     = [Message]
    FROM @tempTable
    WHERE Id = @index;

    -- Formatted Table Contents
    PRINT '| ' +
      LEFT(ISNULL(@PrintSeverity,   'NULL') + SPACE(8), 8)      + ' | ' +
      LEFT(ISNULL(@PrintTimestamp,  'NULL') + SPACE(19), 19)    + ' | ' +
      LEFT(ISNULL(@PrintKey,        'NULL') + SPACE(30), 30)    + ' | ' +
      LEFT(ISNULL(@PrintMessage,    'NULL') + SPACE(100), 100)  + ' |';

    IF LEN(@PrintKey) > 30 OR LEN(@PrintMessage) > 100
    BEGIN
      -- Print Formatted Table Contents Line 2 for longer messages
      -- For even longer messages, review the contents of the log directly
      PRINT '| ' +
        SPACE(8) + ' | ' +
        SPACE(19) + ' | ' +
        LEFT(ISNULL(SUBSTRING(@PrintKey, 31, 30) , 'NULL') + SPACE(30), 30) + ' | ' +
        LEFT(ISNULL(SUBSTRING(@PrintMessage, 101, 100), 'NULL') + SPACE(100), 100) + ' |';
    END

    SET @index = @index + 1;

  END;

    -- Table Footer
    PRINT @TableLine;

END
