/**
 * @function [omd].[GetBatchCodeById]
 * @description
 *   Returns the BATCH_CODE for the given BATCH_ID.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {INT} @BatchId  [in] (required)
 *   The BATCH_ID to look up the code for.
 *
 * @returns {NVARCHAR(500)} The batch code, or NULL if not found.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     [omd].[BATCH]
 *
 * @example

SELECT [omd].[GetBatchCodeById](123);

 */

CREATE FUNCTION [omd].[GetBatchCodeById]
(
  @BatchId INT
)
RETURNS NVARCHAR(500) AS
BEGIN

  DECLARE @BatchCode NVARCHAR(500) =
  (
    SELECT b.BATCH_CODE
    FROM [omd].[BATCH] b
    WHERE b.BATCH_ID = @BatchId
  )

  RETURN @BatchCode;

END
