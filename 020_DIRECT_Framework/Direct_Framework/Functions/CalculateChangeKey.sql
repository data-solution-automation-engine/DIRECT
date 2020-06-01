create function omd.CalculateChangeKey(
    @change_datetime datetime2,
    @insert_module_id int,
    @insert_row_id int
)
returns numeric(38,0)
begin return (
---------------------------------------------------------------------------------------------------------

    select convert(numeric(38,0),
            left(replace(replace(replace(replace(convert(char(27), cast(@change_datetime as datetime2(7))), '-', ''), ' ', ''), ':', ''), '.', ''), 21)
            + right('0000000000' + convert(varchar(38), @insert_module_id), 10)   --,len(2147483647)
            + right('0000000' + convert(varchar(38), @insert_row_id), 7)) as OMD_CHANGE_KEY

---------------------------------------------------------------------------------------------------------
) end