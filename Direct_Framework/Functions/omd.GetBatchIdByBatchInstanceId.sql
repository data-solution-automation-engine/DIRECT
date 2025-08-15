/**
 * @function [omd].[GetBatchIdByBatchInstanceId]
 * @description
 *   Returns the BATCH_ID for a given BATCH_INSTANCE_ID.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {BIGINT} @BatchInstanceId  [in] (required)
 *   The batch instance identifier.
 *
 * @returns {INT} The batch ID, or NULL if not found.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     [omd].[BATCH_INSTANCE]
 *
 * @example

SELECT [omd].[GetBatchIdByBatchInstanceId](0);

 */

CREATE FUNCTION [omd].[GetBatchIdByBatchInstanceId]
(
  @BatchInstanceId BIGINT -- An instance of the Batch.
)
RETURNS INT AS
BEGIN

  DECLARE @BatchId INT =
  (
    SELECT DISTINCT BatchInstance.BATCH_ID
    FROM omd.BATCH_INSTANCE BatchInstance
    WHERE BatchInstance.BATCH_INSTANCE_ID = @BatchInstanceId
  )

  RETURN @BatchId;

END
