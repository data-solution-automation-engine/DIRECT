

CREATE FUNCTION [omd].[GetFailedBatchIdList]
(
	@BatchId INT -- The array of previously failed Batch process relative to the input Batch Id.
)
RETURNS VARCHAR(MAX) AS

-- =============================================
-- Function: Get the list (array) of failed Batch Ids.
-- Description:	Takes the batch id as input and returns the failures prior to the Id (from the last previously successful execution).
--              In other words, the failed execution between the last succesful run and the current one.
-- =============================================

BEGIN

  DECLARE @BatchIdArray VARCHAR(MAX);

  SELECT @BatchIdArray = CAST('(' + STUFF
  (
      (SELECT ',' + CAST(BATCH_INSTANCE_ID AS VARCHAR(20))
      FROM omd.BATCH_INSTANCE 
      WHERE  BATCH_ID = @BatchId
      AND 
  	(
         BATCH_INSTANCE_ID > (SELECT MAX(BATCH_INSTANCE_ID) FROM omd.BATCH_INSTANCE WHERE BATCH_ID = @BatchId AND (EXECUTION_STATUS_CODE='S' AND NEXT_RUN_INDICATOR = 'P'))
        OR 
  	  (SELECT COUNT(BATCH_INSTANCE_ID) FROM omd.BATCH_INSTANCE WHERE BATCH_ID = @BatchId AND (EXECUTION_STATUS_CODE='S' AND NEXT_RUN_INDICATOR = 'P')) = 0
      )
      AND EXECUTION_STATUS_CODE<>'E'
      ORDER BY BATCH_INSTANCE_ID 
      FOR XML PATH ('')
      ),1,1,''
  ) + ')' AS VARCHAR(MAX))

  RETURN @BatchIdArray;
END