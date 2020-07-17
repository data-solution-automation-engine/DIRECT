

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [omd].[GetPreviousBatchInstanceDetails]
(	
	@BatchId INT
)
RETURNS TABLE 
AS
RETURN 
(        
  SELECT 
    ISNULL(MAX(A.EXECUTION_STATUS_CODE),'S') AS PREVIOUS_EXECUTION_STATUS_CODE,
	ISNULL(MAX(A.NEXT_RUN_INDICATOR),'P') AS PREVIOUS_NEXT_RUN_INDICATOR
  FROM
    (
    SELECT 
        NEXT_RUN_INDICATOR, 
        EXECUTION_STATUS_CODE
    FROM omd.BATCH_INSTANCE 
    WHERE BATCH_ID =  @BatchId AND END_DATETIME = (select MAX(END_DATETIME) from omd.BATCH_INSTANCE where BATCH_ID = @BatchId)
    )A               
)