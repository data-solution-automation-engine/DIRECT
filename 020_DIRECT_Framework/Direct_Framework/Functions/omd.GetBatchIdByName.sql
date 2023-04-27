
CREATE FUNCTION [omd].[GetBatchIdByName]
(
	@BatchCode VARCHAR(255) -- The name of the batch, as identified in the BATCH_CODE attribute in the BATCH table.
)
RETURNS VARCHAR(255) AS

-- =============================================
-- Function: Get Batch Id (by name)
-- Description:	Takes the batch code as input and returns the Batch ID as registered in the framework
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @BatchId INT = 
	(
	  SELECT batch.BATCH_ID
	  FROM omd.BATCH batch 
	  WHERE BATCH_CODE = @BatchCode
	)

	-- SET @BatchId = COALESCE(@BatchId,0)    -- << line removed to catch NULL for incorrect @BatchCode

	-- Return the result of the function
	RETURN @BatchId
END