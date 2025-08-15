/**
 * @view [omd_reporting].[vw_EXCEPTIONS_DISABLED_PROCESSES]
 * @description Lists disabled modules, batches, and batch-module associations.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @resultset Columns:
 *   - MODULE_ID/BATCH_ID: Identifier depending on classification.
 *   - MODULE_CODE/BATCH_CODE: Code depending on classification.
 *   - CLASSIFICATION: One of 'Module', 'Batch', or 'Module, disabled at Batch/Module level'.
 *   - FREQUENCY_CODE: Frequency code or 'Not applicable'.
 *   - ADDITIONAL_INFORMATION: Free-form info about the disabled entity.
 *
 * @lineage
 * - reads:
 *     table [omd].[MODULE]
 *     table [omd].[BATCH]
 *     table [omd].[BATCH_MODULE]
 *
 * @example

SELECT TOP 100 *
FROM [omd_reporting].[vw_EXCEPTIONS_DISABLED_PROCESSES];

 */

CREATE VIEW omd_reporting.vw_EXCEPTIONS_DISABLED_PROCESSES
AS
  SELECT
    MODULE_ID,
    MODULE_CODE,
    'Module' AS CLASSIFICATION,
    FREQUENCY_CODE,
    MODULE_DESCRIPTION AS ADDITIONAL_INFORMATION
  FROM omd.MODULE WHERE ACTIVE_INDICATOR = 'N'
  UNION ALL
  SELECT
    BATCH_ID,
    BATCH_CODE,
    'Batch' AS CLASSIFICATION,
    FREQUENCY_CODE,
    BATCH_DESCRIPTION AS ADDITIONAL_INFORMATION
  FROM omd.BATCH WHERE ACTIVE_INDICATOR = 'N'
  UNION ALL
  SELECT
    batchmod.MODULE_ID,
    module.MODULE_CODE,
    'Module, disabled at Batch/Module level' AS CLASSIFICATION,
    'Not applicable' AS FREQUENCY_CODE,
    CONCAT('Disabled within Batch ''', batch.BATCH_CODE,
      ''' with Batch ID ', batchmod.BATCH_ID ) AS ADDITIONAL_INFORMATION
  FROM omd.BATCH_MODULE batchmod
  JOIN omd.MODULE module ON batchmod.MODULE_ID=module.MODULE_ID
  JOIN omd.BATCH batch ON batchmod.BATCH_ID=batch.BATCH_ID
  WHERE batchmod.ACTIVE_INDICATOR = 'N'
