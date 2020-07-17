
CREATE FUNCTION [omd].[GetModuleIdByModuleInstanceId]
(
	@ModuleInstanceId INT -- An instance of the module.
)
RETURNS INT AS

-- =============================================
-- Function: Get Module Id (by Module Instance Id)
-- Description:	Takes the module instance id as input and returns the Module Id as registered in the framework
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @ModuleId INT = 
	(
	  SELECT DISTINCT moduleInstance.MODULE_ID
	  FROM omd.MODULE_INSTANCE moduleInstance
	  WHERE moduleInstance.MODULE_INSTANCE_ID = @ModuleInstanceId
	)

	SET @ModuleId = COALESCE(@ModuleId,0)

	-- Return the result of the function
	RETURN @ModuleId
END