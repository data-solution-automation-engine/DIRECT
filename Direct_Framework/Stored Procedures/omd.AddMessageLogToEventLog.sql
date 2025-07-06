/*******************************************************************************
 * [omd].[AddMessageLogToEventLog]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Adds a message log entry to the event log for auditing or tracking purposes.
 *
 * Inputs:
 *   - Message Log
 *
 * Output:
 *   - Returns 0 on success; logs the provided message to the event log.
 *
 * Usage:
 *
 ******************************************************************************

tba

 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[AddMessageLogToEventLog]
(
  -- Mandatory Parameters
  @MessageLog               NVARCHAR(MAX)
)
AS
BEGIN
  SET NOCOUNT ON;

  -- Validate input
  IF @MessageLog IS NULL OR LTRIM(RTRIM(@MessageLog)) = ''
  BEGIN
    RETURN 0; -- No message to log, return immediately
  END

  ELSE
  BEGIN
    -- Log the messages to the event log
    INSERT INTO [omd].[EventLog] ([Message], [CreatedDate])
    VALUES (@MessageLog, SYSDATETIME());
  END

  RETURN 0;
END
