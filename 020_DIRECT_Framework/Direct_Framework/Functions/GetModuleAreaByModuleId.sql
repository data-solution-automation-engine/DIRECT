CREATE FUNCTION omd.GetModuleAreaByModuleId
(
	@ModuleId INT -- The identifier of the Module (PK).
)
RETURNS VARCHAR(255) AS

-- =============================================
-- Function: Get Module Area (by Id)
-- Description:	Takes the module id as input and returns the area code as registered in the framework
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @ModuleArea VARCHAR(255) = 
	(
	  SELECT module.AREA_CODE
	  FROM omd.MODULE module 
	  WHERE MODULE_ID = @ModuleId
	)

	SET @ModuleArea = COALESCE(@ModuleArea,'N/A')

	-- Return the result of the function
	RETURN @ModuleArea
END