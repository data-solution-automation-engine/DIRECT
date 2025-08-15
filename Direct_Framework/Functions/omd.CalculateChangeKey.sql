/**
 * @function [omd].[CalculateChangeKey]
 * @description
 *   Builds a numeric change key from timestamp, module id and row id.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {DATETIME2} @change_timestamp  [in] (required)
 *   The change event timestamp.
 * @param {INT} @insert_module_id  [in] (required)
 *   The module identifier associated with the change.
 * @param {INT} @insert_row_id  [in] (required)
 *   The row identifier associated with the change.
 *
 * @returns {NUMERIC(38,0)} Deterministic numeric key.
 *
 * @resultset none
 *
 * @lineage
 * - reads: none
 *
 * @example

SELECT [omd].[CalculateChangeKey](SYSUTCDATETIME(), 42, 7);

 */

CREATE FUNCTION [omd].[CalculateChangeKey]
(
    @change_timestamp DATETIME2,
    @insert_module_id INT,
    @insert_row_id INT
)
RETURNS NUMERIC(38, 0) AS
BEGIN

  RETURN (
    SELECT
    convert(NUMERIC(38, 0),
      left(replace(replace(replace(replace(
        convert(CHAR(27), cast(@change_timestamp AS DATETIME2)), '-', ''), ' ', ''), ':', ''), '.', ''), 21)
      + right('0000000000' + convert(VARCHAR(38), @insert_module_id), 10) --,len(2147483647)
      + right('0000000' + convert(VARCHAR(38), @insert_row_id), 7)
    ) AS OMD_CHANGE_KEY
  )
END
