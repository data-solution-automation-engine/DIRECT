
/**
 * @function [omd].[GetModuleIdByModuleInstanceId]
 * @description
 *   Returns the MODULE_ID for a given MODULE_INSTANCE_ID.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {BIGINT} @ModuleInstanceId  [in] (required)
 *   The module instance identifier.
 *
 * @returns {INT} The module ID, or NULL if not found.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     [omd].[MODULE_INSTANCE]
 *
 * @example

SELECT [omd].[GetModuleIdByModuleInstanceId](123456789);

 */

CREATE FUNCTION [omd].[GetModuleIdByModuleInstanceId]
(
  @ModuleInstanceId BIGINT -- An instance of the module.
)
RETURNS INT AS
BEGIN

  -- Declare output variable
  DECLARE @ModuleId INT =
  (
    SELECT DISTINCT mi.MODULE_ID
    FROM [omd].[MODULE_INSTANCE] mi
    WHERE mi.MODULE_INSTANCE_ID = @ModuleInstanceId
  )

  -- SET @ModuleId = COALESCE(@ModuleId,0)  -- << line removed to catch NULL for incorrect @ModuleInstanceId

  -- Return the result of the function
  RETURN @ModuleId

END
