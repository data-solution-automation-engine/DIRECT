/**
 * @function [omd].[GetModuleAreaByModuleId]
 * @description
 *   Returns the AREA_CODE for the given MODULE_ID.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {INT} @ModuleId  [in] (required)
 *   The module identifier.
 *
 * @returns {VARCHAR(255)} The area code, or 'N/A' if not found.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     [omd].[MODULE]
 *
 * @example

SELECT [omd].[GetModuleAreaByModuleId](123);

 */

CREATE FUNCTION [omd].[GetModuleAreaByModuleId]
(
  @ModuleId INT -- The identifier of the Module (PK).
)
RETURNS VARCHAR(255) AS

BEGIN
  -- Declare output variable

  DECLARE @ModuleArea VARCHAR(255) =
  (
    SELECT [module].[AREA_CODE]
    FROM [omd].[MODULE] module
    WHERE MODULE_ID = @ModuleId
  )

  SET @ModuleArea = COALESCE(@ModuleArea,'N/A')

  -- Return the result of the function
  RETURN @ModuleArea

END
