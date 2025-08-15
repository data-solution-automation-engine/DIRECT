/**
 * @function [omd_metadata].[GetSetting]
 * @description
 *   Returns the setting value for a given code from the metadata table, or NULL if not found.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {NVARCHAR(100)} @SettingCode  [in] (required)
 *   The metadata setting code to retrieve.
 *
 * @returns {NVARCHAR(4000)} The setting value as a string, or NULL if not found.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     table [omd_metadata].[FRAMEWORK_METADATA]
 *
 * @example

DECLARE @Value NVARCHAR(4000);
SET @Value = [omd_metadata].[GetSetting](N'MY_SETTING_CODE');

PRINT(CONCAT('Setting Value: ', COALESCE(@Value, 'NULL')));

 */

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
