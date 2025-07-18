-- =============================================
-- Function: GetTimestampString
-- Description: Formats a DATETIME2 value as a string using a format from metadata,
--              or a default format if not found.
-- Parameters:
--  @Timestamp DATETIME2:
--    The timestamp value to format as a string.
-- Returns:
--    NVARCHAR(4000): The formatted timestamp string.
-- =============================================

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
