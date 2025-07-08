-- =============================================
-- Function:    GetPreviousBatchInstanceDetails
-- Description: TODO: tba...
-- =============================================

CREATE FUNCTION [omd].[GetPreviousBatchInstanceDetails]
(
  @BatchId INT
)
RETURNS TABLE AS

RETURN
(
  SELECT
    ISNULL(BI.EXECUTION_STATUS_CODE, 'Succeeded') AS PREVIOUS_EXECUTION_STATUS_CODE,
    ISNULL(BI.NEXT_RUN_STATUS_CODE, 'Proceed') AS PREVIOUS_NEXT_RUN_STATUS
  FROM (SELECT 1 AS dummy) D
  OUTER APPLY (
    SELECT TOP 1
      EXECUTION_STATUS_CODE,
      NEXT_RUN_STATUS_CODE
    FROM omd.BATCH_INSTANCE
    WHERE BATCH_ID = @BatchId
    ORDER BY END_TIMESTAMP DESC
  ) BI
)
