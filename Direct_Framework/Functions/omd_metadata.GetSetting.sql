-- =============================================
-- Function: Get Setting
-- Description: Queries the metadata table to get
-- the setting value for a given code, or null if not found.
-- Parameters:
--  @SettingCode NVARCHAR(100):
--    The code of the setting to retrieve from metadata.
-- =============================================

CREATE FUNCTION [omd_metadata].[GetSetting](@SettingCode NVARCHAR(100))
RETURNS NVARCHAR(4000) AS
BEGIN

  DECLARE @Value NVARCHAR(4000) =
  (
    SELECT TOP 1 md.[VALUE]
    FROM [omd_metadata].[FRAMEWORK_METADATA] md
    WHERE md.[CODE] = @SettingCode
      AND md.[ACTIVE_INDICATOR] = 'Y'
  )

  RETURN @Value

END
