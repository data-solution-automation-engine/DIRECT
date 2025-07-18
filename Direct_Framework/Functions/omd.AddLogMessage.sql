/*******************************************************************************
 * [omd].[AddLogMessage]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT Framework v2.1.0
 *
 * Purpose:
 *   Add a row to the Message Log, by concatenating the input message with
 *   a severity and timestamp as a JSON object in the MessageLog JSON array.
 *
 * Input:
 *   - Severity - valid severity values are:
 *                DEBUG, INFO, WARNING, ERROR, CRITICAL
 *   - Timestamp - Defaults to the current UTC time if not provided
 *   - Log Message Key (a key to identify the message)
 *                      Defaults to 'Info' if not provided
 *   - Log Message (the message to add to the log)
 *   - Message Log (the existing message log)
 *
 * Returns:
 *   - An updated Message Log (with the new message appended)
 *
 * Notes:
 *   - Any DEFAULT parameter values will be replaced in the function body.
 *   - The function will ensure that the Message Log is a valid JSON array.
 *   - If the incoming Message Log Parameter is NULL or empty or not valid JSON,
 *        it will default to an empty JSON array
 *   - If the Log Message is NULL, it will default to 'N/A'.
 *   - If the Severity is NULL or not valid, it will default to 'INFO'.
 *   - If the Timestamp is NULL, it will default to the current UTC time.
 *   - If the Log Message Key is NULL or empty, it will default to 'Info'.
 *   - The function will escape the input parameters to ensure they are valid JSON.
 *   - The function will return the updated Message Log as a JSON array.
 *   - If the new log entry is not valid JSON, it will inject an error message.
 *
 * Usage:
 *

DECLARE @LogMessage NVARCHAR(MAX);
DECLARE @MessageLog NVARCHAR(MAX);

SET @LogMessage = 'The parsing of ''2319'' as event code failed';
SET @MessageLog =
  [omd].[AddLogMessage]
  ('WARNING', DEFAULT, N'Value Parsing', @LogMessage, @MessageLog)

SELECT @MessageLog;

******************************************************************************/

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
