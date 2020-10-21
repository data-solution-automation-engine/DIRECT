CREATE FUNCTION [omd].[GetBatchModuleActiveIndicatorValue]
(
	@BatchId INT,
	@ModuleId INT
)
RETURNS VARCHAR(3) AS

-- =============================================
-- Function: Get the Batch/Module active/inactive flag.
-- Description:	Retrieve the Inactive Indicator (flag) for a Batch / Module combination.
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @InactiveIndicator VARCHAR(3)
	
	SET @InactiveIndicator = 
	(
      SELECT
        MIN(INACTIVE_INDICATOR)
      FROM
      (
        SELECT INACTIVE_INDICATOR
        FROM omd.BATCH_MODULE
        WHERE BATCH_ID = @BatchId AND MODULE_ID = @ModuleId
      	UNION
      	-- Return if there is nothing, to give at least a result row for further processing
        SELECT 'N/A'
      ) sub
	)

	-- Return the result of the function
	RETURN @InactiveIndicator
END