CREATE FUNCTION [omd].[GetBatchIdByModuleInstanceId]
(
  @ModuleInstanceId BIGINT -- An instance of the module.
)
RETURNS INT AS

-- =============================================
-- Function: Get Batch Id (by Module Instance Id)
-- Description: Takes the module instance id as input and returns the Batch Id as registered in the framework
-- =============================================

BEGIN

  DECLARE @BatchId INT =
  (
    SELECT DISTINCT batchInstance.BATCH_ID
    FROM omd.MODULE_INSTANCE moduleInstance
    JOIN omd.BATCH_INSTANCE batchInstance ON moduleInstance.BATCH_INSTANCE_ID = batchInstance.BATCH_INSTANCE_ID
    WHERE moduleInstance.MODULE_INSTANCE_ID = @ModuleInstanceId
  )

  RETURN @BatchId;

END
