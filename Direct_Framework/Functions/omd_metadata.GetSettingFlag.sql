/**
 * @function [omd_metadata].[GetSettingFlag]
 * @description
 *   Returns a 'Y'/'N' flag from the metadata table for the given setting code.
 *   If the stored value equals 'Y' (case-insensitive), returns 'Y'; otherwise 'N'.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {NVARCHAR(100)} @SettingCode  [in] (required)
 *   The metadata setting code for which to retrieve a flag.
 *
 * @returns {CHAR(1)} 'Y' or 'N'.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     table [omd_metadata].[FRAMEWORK_METADATA]
 *
 * @example

SELECT [omd_metadata].[GetSettingFlag](N'FEATURE_TOGGLE');

 */

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
