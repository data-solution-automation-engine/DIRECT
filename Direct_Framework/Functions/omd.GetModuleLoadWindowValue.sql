/**
 * @function [omd].[GetModuleLoadWindowValue]
 * @description
 *   Retrieves the start (1) or end (2) datetime value for a module's latest
 *   source control load window entry.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {INT} @ModuleId  [in] (required)
 *   The module identifier.
 * @param {TINYINT} @start_or_end  [in] (required)
 *   1 for start value, 2 for end value.
 *
 * @returns {NVARCHAR(100)} The start or end value as NVARCHAR, or NULL if none.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     [omd].[SOURCE_CONTROL], [omd].[MODULE_INSTANCE]
 *
 * @example

DECLARE @START_VALUE NVARCHAR(100) =
  [omd].[GetModuleLoadWindowValue]((SELECT MODULE_ID FROM [omd].[MODULE] WHERE MODULE_CODE=N'<module>'), 1);
PRINT @START_VALUE;

 */

CREATE FUNCTION [omd].[GetModuleLoadWindowValue]
(
  @ModuleId INT,
  @start_or_end TINYINT
)
RETURNS NVARCHAR(100) AS
BEGIN

  DECLARE @result NVARCHAR(100) = NULL;

  IF @start_or_end = 1
  BEGIN
    SELECT
      @result = START_VALUE
    FROM
      (
      SELECT
        sct.MODULE_INSTANCE_ID
        ,START_VALUE
        ,END_VALUE
        ,ROW_NUMBER() OVER (PARTITION BY modinst.MODULE_ID ORDER BY INSERT_TIMESTAMP DESC) AS ROW_NR
      FROM
        [omd].[SOURCE_CONTROL] sct
        JOIN [omd].[MODULE_INSTANCE] modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
      WHERE modinst.MODULE_ID = @ModuleId
    ) ranksub
    WHERE ROW_NR=1
  END
  ELSE IF @start_or_end = 2
  BEGIN
    SELECT
      @result = END_VALUE
    FROM
      (
      SELECT
        sct.MODULE_INSTANCE_ID
        ,START_VALUE
        ,END_VALUE
        ,ROW_NUMBER() OVER (PARTITION BY modinst.MODULE_ID ORDER BY INSERT_TIMESTAMP DESC) AS ROW_NR
      FROM
        [omd].[SOURCE_CONTROL] sct
        JOIN [omd].[MODULE_INSTANCE] modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
      WHERE modinst.MODULE_ID = @ModuleId
    ) ranksub
    WHERE ROW_NR=1
  END
  RETURN @result

END
