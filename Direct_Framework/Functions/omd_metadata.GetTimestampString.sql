/**
 * @function [omd_metadata].[GetTimestampString]
 * @description
 *   Formats a DATETIME2 value as a string using a format stored in metadata,
 *   or a default format when not found.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {DATETIME2} @Timestamp  [in] (required)
 *   The timestamp to format.
 *
 * @returns {NVARCHAR(100)} The formatted timestamp string.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     table [omd_metadata].[FRAMEWORK_METADATA]
 *
 * @example

DECLARE @s NVARCHAR(100);
SET @s = [omd_metadata].[GetTimestampString](SYSUTCDATETIME());
PRINT(@s);

 */

CREATE FUNCTION [omd_metadata].[GetTimestampString](@Timestamp DATETIME2)
RETURNS NVARCHAR(100) AS
BEGIN

  DECLARE @FormatString NVARCHAR(4000) =
  (
    SELECT TOP 1 md.[VALUE]
    FROM [omd_metadata].[FRAMEWORK_METADATA] md
    WHERE md.[CODE] = 'DISPLAY_TIMESTAMP_FORMAT'
      AND md.[ACTIVE_INDICATOR] = 'Y'
  )
  IF @FormatString IS NULL OR TRIM(@FormatString) = ''
  BEGIN
    SET @FormatString =
      N'yyyy-MM-dd HH:mm:ss'; -- Default format if not found
  END

  DECLARE @TimestampString NVARCHAR(100);

  -- Attempt to format the timestamp using the specified format string
  SET @TimestampString = FORMAT(@Timestamp, @FormatString);

  IF @TimestampString IS NULL OR TRIM(@TimestampString) = ''
    -- If formatting returns nothing, return a default string representation
    SET @TimestampString = FORMAT(@Timestamp, N'yyyy-MM-dd HH:mm:ss');

  RETURN @TimestampString;

END
