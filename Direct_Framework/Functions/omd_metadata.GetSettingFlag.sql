-- =============================================
-- Function: Get Setting Flag
-- Description: Queries the metadata table to get
-- a setting flag-type value for a given code.
-- Returns 'Y' if the stored value is 'y'/'Y' else 'N'.
-- Parameters:
--  @SettingCode NVARCHAR(100):
--    The code of the setting flag to retrieve from metadata.
-- =============================================

CREATE FUNCTION [omd_metadata].[GetSettingFlag](@SettingCode NVARCHAR(100))
RETURNS CHAR(1) AS
BEGIN

  DECLARE @Value NVARCHAR(4000) =
  (
    SELECT TOP 1 md.[VALUE]
    FROM [omd_metadata].[FRAMEWORK_METADATA] md
    WHERE md.[CODE] = @SettingCode
      AND md.[ACTIVE_INDICATOR] = 'Y'
  )
  DECLARE @Flag CHAR(1) = CASE WHEN UPPER(@Value) = 'Y' THEN 'Y' ELSE 'N' END;
  RETURN @Flag

END
