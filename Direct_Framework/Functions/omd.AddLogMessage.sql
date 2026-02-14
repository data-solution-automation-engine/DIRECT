/**
 * @function [omd].[AddLogMessage]
 * @description
 *   Appends a severity/timestamp/key/message JSON entry to a JSON array log.
 *   Ensures valid JSON and injects an error entry when malformed.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {NVARCHAR(100)} @Severity  [in] (required)
 *   One of DEBUG, INFO, WARNING, ERROR, CRITICAL.
 * @param {DATETIME2} @Timestamp  [in] (optional)
 *   Defaults to current UTC time when NULL.
 * @param {NVARCHAR(1000)} @LogMessageKey  [in] (optional)
 *   Message category key; defaults to 'Info' when NULL/empty.
 * @param {NVARCHAR(MAX)} @LogMessage  [in] (required)
 *   The message to append; defaults to 'N/A' when NULL.
 * @param {NVARCHAR(MAX)} @MessageLog  [in] (optional)
 *   The existing JSON array log; defaults to '[]' if NULL/invalid.
 *
 * @returns {NVARCHAR(MAX)} Updated JSON array log.
 *
 * @resultset none
 *
 * @lineage
 * - reads: none
 *
 * @example

DECLARE @LogMessage NVARCHAR(MAX) = N'The parsing of ''2319'' as event code failed';
DECLARE @MessageLog NVARCHAR(MAX);
SET @MessageLog = [omd].[AddLogMessage]('WARNING', DEFAULT, N'Value Parsing', @LogMessage, @MessageLog);
SELECT @MessageLog;

 */

CREATE FUNCTION [omd].[AddLogMessage]
(
  @Severity       NVARCHAR(100), -- The severity of the message
                                 -- (DEBUG, INFO, WARNING, ERROR, CRITICAL)
  @Timestamp      DATETIME2, -- The timestamp of the message (defaults to current UTC time if not provided)
  @LogMessageKey  NVARCHAR(1000), -- The key of the message to add to the Log
  @LogMessage     NVARCHAR(MAX), -- The Message to add to the Log
  @MessageLog     NVARCHAR(MAX) -- The existing Message Log (Json array of Json objects)
)
RETURNS NVARCHAR(MAX) AS
BEGIN

  IF @LogMessage IS NULL
  BEGIN
    SET @LogMessage = 'N/A';
  END

  -- Ensure the MessageLog is a valid JSON array
  IF  @MessageLog IS NULL OR
      TRIM(@MessageLog) = '' OR
      NOT ISJSON(@MessageLog) = 1
  BEGIN
    SET @MessageLog = '[]';
  END

  -- Ensure the input parameters are valid and not NULL
  SET @Severity = UPPER(ISNULL(@Severity, 'INFO'));
  IF  TRIM(@Severity) = '' OR
      @Severity NOT IN ('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL')
  BEGIN
    SET @Severity = 'INFO'; -- Default severity if not provided
  END

  SET @Timestamp = ISNULL(@Timestamp, SYSUTCDATETIME());

  IF @LogMessageKey IS NULL OR TRIM(@LogMessageKey) = ''
  BEGIN
    SET @LogMessageKey = 'Info';
  END

  DECLARE
    @TimestampString NVARCHAR(MAX),
    @SeverityString NVARCHAR(MAX),
    @LogMessageKeyString NVARCHAR(1000)

  -- Set parameters to valid values, including defaulting missing ones
  SET @TimestampString      = CAST(CONVERT(NVARCHAR(27), ISNULL(@Timestamp, SYSUTCDATETIME()), 126) AS NVARCHAR(MAX));
  SET @SeverityString       = @Severity;
  SET @LogMessageKeyString  = CAST(STRING_ESCAPE(@LogMessageKey, 'json') AS NVARCHAR(1000));
  DECLARE @LogMessageEscaped NVARCHAR(MAX);
  SET @LogMessageEscaped = STRING_ESCAPE(@LogMessage, 'json');

  -- Construct the new log entry as a JSON object
  DECLARE @NewLogEntry NVARCHAR(MAX) =
    CONCAT(
      '{',
        '"severity": "',  @SeverityString,      '",',
        '"timestamp": "', @TimestampString,     '",',
        '"key": "',       @LogMessageKeyString, '",',
        '"message": "',   @LogMessageEscaped,   '"',
      '}'
    );

  -- also prepare an error entry if something goes wrong
  DECLARE @ErrorLogEntry NVARCHAR(MAX) = CONCAT(
    '{',
      '"severity": "CRITICAL",',
      '"timestamp": "', @TimestampString, '",',
      '"key": "LogError",',
      '"message": "Failed to append log entry: invalid JSON encountered"',
    '}'
  );

  -- If the new log entry is not valid JSON, inject an error message instead
  IF ISJSON('[' + @NewLogEntry + ']') = 0
  BEGIN
    SET @NewLogEntry = @ErrorLogEntry;
  END

  -- Save the original log
  DECLARE @OriginalMessageLog NVARCHAR(MAX) = @MessageLog;
  DECLARE @NewMessageLog NVARCHAR(MAX);

  -- Append the new log entry to the existing message log JSON array
  SET @NewMessageLog =
    JSON_MODIFY(
      @MessageLog,
      'append $',
      JSON_QUERY(@NewLogEntry)
    );

  -- If the whole new log valid JSON, return it
  IF ISJSON(@NewMessageLog) = 1
  BEGIN
    RETURN @NewMessageLog;
  END

  -- else, if something happened and the full, updated, log is not valid JSON,
  -- surface the error by appending a valid JSON error entry to the original log
  DECLARE @OriginalLogWithError NVARCHAR(MAX) =
    JSON_MODIFY(
      @OriginalMessageLog,
      'append $',
      JSON_QUERY(@ErrorLogEntry)
    );

  RETURN @OriginalLogWithError;

END
