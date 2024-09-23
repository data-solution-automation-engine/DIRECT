CREATE FUNCTION [omd].[GetBatchModuleActiveIndicatorValue]
(
  @BatchId INT,
  @ModuleId INT
)
RETURNS CHAR(1) AS

-- =============================================
-- Function: Get the Batch/Module active/inactive flag.
-- Description: Retrieve the Active Indicator (flag)
--              for a Batch / Module combination.
-- =============================================

BEGIN
  -- Declare ouput variable

  DECLARE @ActiveIndicator CHAR(1)

  SET @ActiveIndicator =
  (
    --SELECT
    --  MIN(ACTIVE_INDICATOR)
    --FROM
    --(
      SELECT TOP 1 ACTIVE_INDICATOR
      FROM omd.BATCH_MODULE
      WHERE BATCH_ID = @BatchId AND MODULE_ID = @ModuleId
      --UNION
      ---- Return U for Unknown if there is nothing,
      ---- to give at least a result row for further processing
      --SELECT 'U'
    --) sub
  )

  -- Return the result of the function
  RETURN COALESCE(@ActiveIndicator, 'U')
END
