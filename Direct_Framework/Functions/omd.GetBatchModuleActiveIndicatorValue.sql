/**
 * @function [omd].[GetBatchModuleActiveIndicatorValue]
 * @description
 *   Returns the ACTIVE_INDICATOR flag for a Batch/Module combination.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {INT} @BatchId  [in] (required)
 *   The batch identifier.
 * @param {INT} @ModuleId  [in] (required)
 *   The module identifier.
 *
 * @returns {CHAR(1)} 'Y', 'N', or 'U' when unknown.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     [omd].[BATCH_MODULE]
 *
 * @example

SELECT [omd].[GetBatchModuleActiveIndicatorValue](10, 20);

 */

CREATE FUNCTION [omd].[GetBatchModuleActiveIndicatorValue]
(
  @BatchId INT,
  @ModuleId INT
)
RETURNS CHAR(1) AS

BEGIN
  -- Declare output variable

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
