-- =============================================
-- Function: Get Module Id (by name)
-- Description: Takes the module code as input and returns the Module ID as registered in the framework
-- =============================================

CREATE FUNCTION [omd].[GetModuleIdByName]
(
  @ModuleCode NVARCHAR(1000) -- The name of the module, as identified in the MODULE_CODE attribute in the MODULE table.
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
