/**
 * @function [omd].[GetPreviousBatchInstanceDetails]
 * @description
 *   Returns previous batch execution status and next-run status for a batch.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {INT} @BatchId  [in] (required)
 *   The batch identifier.
 *
 * @returns {TABLE}
 *   PREVIOUS_EXECUTION_STATUS_CODE NVARCHAR(100),
 *   PREVIOUS_NEXT_RUN_STATUS NVARCHAR(100)
 *
 * @resultset table
 *
 * @lineage
 * - reads:
 *     [omd].[BATCH_INSTANCE]
 *
 * @example

SELECT * FROM [omd].[GetPreviousBatchInstanceDetails](42);

 */

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
