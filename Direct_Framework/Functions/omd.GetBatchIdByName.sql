CREATE FUNCTION [omd].[GetBatchIdByName]
(
  @BatchCode NVARCHAR(1000) -- The name of the batch, as identified in the BATCH_CODE attribute in the BATCH table.
)
RETURNS INT AS

-- =============================================
-- Function: Get Batch Id (by code/name)
-- Description: Takes the batch code as input and returns the Batch ID as registered in the framework
-- =============================================

BEGIN

  DECLARE @BatchId INT =
  (
    SELECT b.BATCH_ID
    FROM [omd].[BATCH] b
    WHERE b.BATCH_CODE = @BatchCode
  )

  RETURN @BatchId

END
