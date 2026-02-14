/**
 * @function [omd].[GetFailedBatchIdList]
 * @description
 *   Returns a parenthesized, comma-separated list of batch instance IDs that
 *   failed between the last successful run and the current one for a batch.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {INT} @BatchId  [in] (required)
 *   The batch identifier to analyze.
 *
 * @returns {VARCHAR(MAX)} E.g., '(1001,1002,1003)'; may be NULL.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     [omd].[BATCH_INSTANCE]
 *
 * @example

SELECT [omd].[GetFailedBatchIdList](101);

 */

CREATE FUNCTION [omd].[GetFailedBatchIdList]
(
  @BatchId INT -- The array of previously failed Batch process relative to the input Batch Id.
)
RETURNS VARCHAR(MAX) AS
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
