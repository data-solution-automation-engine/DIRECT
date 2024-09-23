CREATE FUNCTION [omd].[CalculateChangeKey]
(
    @change_timestamp DATETIME2,
    @insert_module_id INT,
    @insert_row_id INT
)
RETURNS NUMERIC(38, 0) AS
BEGIN

-- =============================================
-- Function: Calculate Change Key
-- Description: TODO: tba...
-- =============================================

  RETURN (
  ------------------------------------------------------------------------------
  SELECT
    convert(NUMERIC(38, 0),
        left(replace(replace(replace(replace(
            convert(CHAR(27), cast(@change_timestamp AS DATETIME2)), '-', ''), ' ', ''), ':', ''), '.', ''), 21)
        + right('0000000000' + convert(VARCHAR(38), @insert_module_id), 10) --,len(2147483647)
        + right('0000000' + convert(VARCHAR(38), @insert_row_id), 7)
     ) AS OMD_CHANGE_KEY
  ------------------------------------------------------------------------------
  )
END
