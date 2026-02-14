/**
 * @function [omd].[GetBatchIdByName]
 * @description
 *   Returns the BATCH_ID for the given BATCH_CODE.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {NVARCHAR(500)} @BatchCode  [in] (required)
 *   The BATCH_CODE to look up.
 *
 * @returns {INT} The batch ID, or NULL if not found.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     [omd].[BATCH]
 *
 * @example

SELECT [omd].[GetBatchIdByName](N'MY_BATCH');

 */

CREATE FUNCTION [omd].[GetBatchIdByName]
(
  @BatchCode NVARCHAR(500)
)
RETURNS INT AS
BEGIN

  DECLARE @BatchId INT =
  (
    SELECT b.BATCH_ID
    FROM [omd].[BATCH] b
    WHERE b.BATCH_CODE = @BatchCode
  )

  RETURN @BatchId;

END
