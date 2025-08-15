/**
 * @function [omd].[GetBatchIdByModuleInstanceId]
 * @description
 *   Returns the BATCH_ID for a given MODULE_INSTANCE_ID.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {BIGINT} @ModuleInstanceId  [in] (required)
 *   The module instance identifier.
 *
 * @returns {INT} The batch ID, or NULL if not found.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     [omd].[MODULE_INSTANCE] JOIN [omd].[BATCH_INSTANCE]
 *
 * @example

SELECT [omd].[GetBatchIdByModuleInstanceId](987654321);

 */

CREATE FUNCTION [omd].[GetBatchIdByModuleInstanceId]
(
  @ModuleInstanceId BIGINT -- An instance of the module.
)
RETURNS INT AS
BEGIN

  DECLARE @BatchId INT =
  (
    SELECT DISTINCT batchInstance.BATCH_ID
    FROM omd.MODULE_INSTANCE moduleInstance
    JOIN omd.BATCH_INSTANCE batchInstance ON moduleInstance.BATCH_INSTANCE_ID = batchInstance.BATCH_INSTANCE_ID
    WHERE moduleInstance.MODULE_INSTANCE_ID = @ModuleInstanceId
  )

  RETURN @BatchId;

END
