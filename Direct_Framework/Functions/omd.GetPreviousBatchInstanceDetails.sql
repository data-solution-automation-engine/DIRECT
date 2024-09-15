CREATE FUNCTION [omd].[GetPreviousBatchInstanceDetails]
(
  @BatchId INT
)
RETURNS TABLE AS

-- =============================================
-- Function:    GetPreviousBatchInstanceDetails
-- Description: TODO: tba...
-- =============================================

RETURN
(
  SELECT
    ISNULL(MAX(A.EXECUTION_STATUS_CODE),'Succeeded') AS PREVIOUS_EXECUTION_STATUS_CODE,
    ISNULL(MAX(A.NEXT_RUN_STATUS_CODE),'Proceed') AS PREVIOUS_NEXT_RUN_STATUS
  FROM
    (
    SELECT
      NEXT_RUN_STATUS_CODE,
      EXECUTION_STATUS_CODE
    FROM omd.BATCH_INSTANCE
    WHERE
      BATCH_ID = @BatchId
      AND
      END_TIMESTAMP =
      (select MAX(END_TIMESTAMP) from omd.BATCH_INSTANCE where BATCH_ID = @BatchId)
    ) A
)
