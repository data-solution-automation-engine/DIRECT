CREATE FUNCTION [omd].[GetBatchIdByBatchInstanceId]
(
  @BatchInstanceId BIGINT -- An instance of the Batch.
)
RETURNS INT AS

-- =============================================
-- Function: Get Batch Id (by Batch Instance Id)
-- Description: Takes the Batch instance id as input and returns the Batch Id as registered in the framework
-- =============================================

BEGIN

  DECLARE @BatchId INT =
  (
    SELECT DISTINCT BatchInstance.BATCH_ID
    FROM omd.BATCH_INSTANCE BatchInstance
    WHERE BatchInstance.BATCH_INSTANCE_ID = @BatchInstanceId
  )

  RETURN @BatchId;

END
