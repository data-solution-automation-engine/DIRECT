CREATE FUNCTION omd.GetModuleIdByName
(
	@ModuleCode VARCHAR(255) -- The name of the module, as identified in the MODULE_CODE attribute in the MODULE table.
)
RETURNS VARCHAR(255) AS

-- =============================================
-- Function: Get Module Id (by name)
-- Description:	Takes the module code as input and returns the Module ID as registered in the framework
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @ModuleId INT = 
	(
	  SELECT module.MODULE_ID
	  FROM omd.MODULE module 
	  WHERE MODULE_CODE = @ModuleCode
	)

	-- Return the result of the function
	RETURN @ModuleId
END