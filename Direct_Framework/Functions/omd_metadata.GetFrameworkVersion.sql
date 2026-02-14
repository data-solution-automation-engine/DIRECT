/**
 * @function [omd_metadata].[GetFrameworkVersion]
 * @description
 *   Returns the current DIRECT Framework version from the metadata table.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @returns {NVARCHAR(4000)} The current framework version as a string.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     table [omd_metadata].[Framework_Metadata]
 *
 * @example

DECLARE @Version NVARCHAR(4000);
SET @Version = [omd_metadata].[GetFrameworkVersion]();

PRINT(CONCAT('Current Version: ', @Version));

 */

CREATE FUNCTION [omd_metadata].[GetFrameworkVersion]()
RETURNS NVARCHAR(4000) AS
BEGIN

  DECLARE @Version NVARCHAR(4000) =
  (
    SELECT TOP 1 md.[VALUE]
    FROM [omd_metadata].[FRAMEWORK_METADATA] md
    WHERE md.[CODE] = 'DIRECT_VERSION'
  )

  RETURN @Version

END
