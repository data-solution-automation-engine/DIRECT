

CREATE FUNCTION [omd].[GetBatchIdByModuleInstanceId]
(
	@ModuleInstanceId INT -- An instance of the module.
)
RETURNS INT AS

-- =============================================
-- Function: Get Batch Id (by Module Instance Id)
-- Description:	Takes the module instance id as input and returns the Batch Id as registered in the framework
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @BatchId INT = 
	(
	  SELECT DISTINCT batchInstance.BATCH_ID
	  FROM omd.MODULE_INSTANCE moduleInstance
	  JOIN omd.BATCH_INSTANCE batchInstance ON moduleInstance.BATCH_INSTANCE_ID = batchInstance.BATCH_INSTANCE_ID
	  WHERE moduleInstance.MODULE_INSTANCE_ID = @ModuleInstanceId
	)

	SET @BatchId = COALESCE(@BatchId,0)

	-- Return the result of the function
	RETURN @BatchId
END