/*******************************************************************************
 * [omd].[AddLogMessage]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Add a row to the Message Log, by concatenating the input message with
 *   a severity and timestamp as a JSON object in the MessageLog JSON array.
 *
 * Input:
 *   - Severity (e.g. INFO, WARNING, ERROR)
 *   - Timesetamp
 *   - Log Message Key (a key to identify the message)
 *   - Log Message (the message to add to the log)
 *   - Message Log (the existing message log)
 *
 * Returns:
 *   - Message Log (with the new message appended)
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

 *
 ******************************************************************************/

CREATE FUNCTION [omd].[AddLogMessage]
(
  @Severity NVARCHAR(100), -- The severity of the message (e.g. INFO, WARNING, ERROR)
  @Timestamp DATETIME2, -- The timestamp of the message
  @LogMessageKey NVARCHAR(1000), -- The key of the message to add to the Log
  @LogMessage NVARCHAR(MAX), -- The Message to add to the Log
  @MessageLog NVARCHAR(MAX) -- The existing Message Log (Json array of Json objects)
)
RETURNS NVARCHAR(MAX) AS

BEGIN

  IF @LogMessage IS NULL
  BEGIN
    SET @LogMessage = 'N/A'
  END

  IF @MessageLog IS NULL OR TRIM(@MessageLog) = ''
  BEGIN
    SET @MessageLog = '[]'
  END

  DECLARE
    @TimestampString NVARCHAR(MAX),
    @SeverityString NVARCHAR(MAX),
    @LogMessageKeyString NVARCHAR(MAX)

  -- Set parameters to valid values, including defaulting missing ones
  SET @TimestampString  = CAST(STRING_ESCAPE(FORMAT(ISNULL(@Timestamp, SYSUTCDATETIME()), 'yyyy-MM-dd HH:mm:ss.fffffff'), 'json') AS NVARCHAR(MAX));
  SET @SeverityString   = CAST(STRING_ESCAPE(ISNULL(@Severity, 'INFO'), 'json') AS NVARCHAR(MAX));
  SET @LogMessageKey    = CAST(STRING_ESCAPE(ISNULL(@LogMessageKey, ''), 'json') AS NVARCHAR(MAX));
  SET @LogMessage       = CAST(STRING_ESCAPE(ISNULL(@LogMessage, ''), 'json') AS NVARCHAR(MAX));

  -- Declare ouput variable and populate it with the new message log
  DECLARE @NewMessageLog NVARCHAR(MAX) =
  (
  -- New node into the existing Json array
  SELECT
    JSON_QUERY(
      JSON_MODIFY(
        @MessageLog,
        'append $',
        JSON_QUERY(
          CONCAT(
            '{',
              '"severity": "',  @SeverityString,  '",',
              '"timestamp": "', @TimestampString, '",',
              '"key": "',       @LogMessageKey,   '",',
              '"message": "',   @LogMessage,      '"',
            '}'
          )
        )
      )
    )
  )

  -- Return the resulting new message log
  RETURN @NewMessageLog
END
