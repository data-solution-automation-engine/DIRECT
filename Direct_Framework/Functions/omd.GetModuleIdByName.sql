/**
 * @function [omd].[GetModuleIdByName]
 * @description
 *   Returns the MODULE_ID for the given MODULE_CODE.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {NVARCHAR(500)} @ModuleCode  [in] (required)
 *   The MODULE_CODE to look up.
 *
 * @returns {INT} The module ID, or NULL if not found.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     [omd].[MODULE]
 *
 * @example

SELECT [omd].[GetModuleIdByName](N'MY_MODULE');

 */

CREATE FUNCTION [omd].[GetModuleIdByName]
(
  @ModuleCode NVARCHAR(500)
)
RETURNS INT AS
BEGIN

  DECLARE @ModuleId INT =
  (
    SELECT m.MODULE_ID
    FROM [omd].[MODULE] m
    WHERE m.MODULE_CODE = @ModuleCode
  )

  RETURN @ModuleId

END
