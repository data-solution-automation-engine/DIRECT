CREATE FUNCTION [omd].[GetFailedBatchIdList]
(
  @BatchId INT -- The array of previously failed Batch process relative to the input Batch Id.
)
RETURNS VARCHAR(MAX) AS

-- =============================================
-- Function: Get the list (array) of failed Batch Ids.
-- Description: Takes the Batch Id as input and returns the failures prior to the current run (from the last previously successful execution).
--              In other words, the failed execution between the last succesful run and the current one.
-- =============================================

BEGIN

  DECLARE @BatchIdArray VARCHAR(MAX);

  SELECT @BatchIdArray =
    CAST('(' +
      STUFF(
      (
        SELECT ',' + CAST(BATCH_INSTANCE_ID AS VARCHAR(20))
        FROM [omd].[BATCH_INSTANCE]
        WHERE  BATCH_ID = @BatchId
        AND
        (
          BATCH_INSTANCE_ID >
          (
            SELECT MAX(BATCH_INSTANCE_ID)
            FROM [omd].[BATCH_INSTANCE]
            WHERE
              BATCH_ID = @BatchId
              AND
              (EXECUTION_STATUS_CODE = N'Succeeded' AND NEXT_RUN_STATUS_CODE = N'Proceed')
          )
          OR
          (
            SELECT COUNT(BATCH_INSTANCE_ID)
            FROM [omd].[BATCH_INSTANCE]
            WHERE BATCH_ID = @BatchId
              AND (EXECUTION_STATUS_CODE = N'Succeeded' AND NEXT_RUN_STATUS_CODE = N'Proceed')
          ) = 0
        )
        AND EXECUTION_STATUS_CODE <> N'Executing'
        ORDER BY BATCH_INSTANCE_ID
        FOR XML PATH ('')
        ),1,1,''
      ) + ')' AS VARCHAR(MAX)
    )

  RETURN @BatchIdArray;
END
