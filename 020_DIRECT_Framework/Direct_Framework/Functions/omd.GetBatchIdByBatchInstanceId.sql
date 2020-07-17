

CREATE FUNCTION [omd].[GetBatchIdByBatchInstanceId]
(
	@BatchInstanceId INT -- An instance of the Batch.
)
RETURNS INT AS

-- =============================================
-- Function: Get Batch Id (by Batch Instance Id)
-- Description:	Takes the Batch instance id as input and returns the Batch Id as registered in the framework
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @BatchId INT = 
	(
	  SELECT DISTINCT BatchInstance.Batch_ID
	  FROM omd.BATCH_INSTANCE BatchInstance
	  WHERE BatchInstance.BATCH_INSTANCE_ID = @BatchInstanceId
	)

	SET @BatchId = COALESCE(@BatchId,0)

	-- Return the result of the function
	RETURN @BatchId
END