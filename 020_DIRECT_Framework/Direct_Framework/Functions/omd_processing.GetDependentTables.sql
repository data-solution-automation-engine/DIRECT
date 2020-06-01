create function omd_processing.GetDependentTables (
    @schema_name sysname,
    @object_name sysname
    )
/***
Purpose: Returns the underlying tables on which the specified object depends.
       - If the provided object is a table, then will simply reflect that table name.
Notes: - Works recursively where found dependencies which are not a table.
       - As this procedure does not traverse dependencies through packages. Only local tables 
         which are accessed by the query which loads the specified target are returned.
***/
returns @rtnTbl table (
    referenced_schema_name sysname not null,
    referenced_object_name sysname not null
    )
as
begin
-----------------------------------------------------------------------------------------------------------

with allDeps
as (
    select sql_expression_dependencies.referencing_id,
        object_schema_name(sql_expression_dependencies.referencing_id) as referencing_schema_name,
        object_name(sql_expression_dependencies.referencing_id) as referencing_entity_name,
        pre_calc.referenced_schema_name,
        sql_expression_dependencies.referenced_entity_name,
        objects.[type_desc] as referenced_type_desc
    from sys.sql_expression_dependencies
        outer apply (
                select coalesce(sql_expression_dependencies.referenced_database_name, db_name()) as referenced_database_name,
                    coalesce(sql_expression_dependencies.referenced_schema_name, 'dbo') as referenced_schema_name
                ) pre_calc
        inner join sys.objects
            on objects.[object_id] = sql_expression_dependencies.referenced_id
    where pre_calc.referenced_database_name = db_name() /* object dependencies are expected to never be cross-database */
        and object_schema_name(sql_expression_dependencies.referencing_id) not like N'omd%'
        and object_schema_name(sql_expression_dependencies.referencing_id) not in (N'tSQLt')
        and object_schema_name(sql_expression_dependencies.referencing_id) not like N'test%'
        and not exists ( /* excluded table self-dependencies, such as from calculated columns */
                select null
                from sys.objects start_type
                where start_type.[object_id] = sql_expression_dependencies.referencing_id
                    and start_type.[type_desc] in ('USER_TABLE', 'SYNONYM')
                )
    group by sql_expression_dependencies.referencing_id,
        pre_calc.referenced_schema_name,
        sql_expression_dependencies.referenced_entity_name,
        objects.[type_desc]
    )
, recursiveCTE
as  (
        select referencing_schema_name,
            referencing_entity_name,
            referenced_schema_name,
            referenced_entity_name,
            referenced_type_desc
        from allDeps
        where allDeps.referencing_id = object_id(@schema_name + N'.' + @object_name)
    union all
        select recursiveCTE.referencing_schema_name as referencing_schema_name,
            recursiveCTE.referencing_entity_name as referencing_entity_name,
            allDeps.referenced_schema_name,
            allDeps.referenced_entity_name,
            allDeps.referenced_type_desc
        from recursiveCTE
            inner join allDeps
                on allDeps.referencing_schema_name = recursiveCTE.referenced_schema_name
                and allDeps.referencing_entity_name = recursiveCTE.referenced_entity_name
        where recursiveCTE.referenced_type_desc not in ('USER_TABLE', 'SYNONYM')
    )

/* add to returned results table */
insert into @rtnTbl
    select referenced_schema_name as REFERENCED_SCHEMA_NAME,
        referenced_entity_name as REFERENCED_OBJECT_NAME
    from recursiveCTE
    where recursiveCTE.referenced_type_desc in ('USER_TABLE', 'SYNONYM')
union
    select @schema_name as REFERENCED_SCHEMA_NAME,
        @object_name as REFERENCED_OBJECT_NAME
    from sys.tables
    where tables.[object_id] = object_id(@schema_name + N'.' + @object_name)
union
    select @schema_name as REFERENCED_SCHEMA_NAME,
        @object_name as REFERENCED_OBJECT_NAME
    from sys.synonyms
    where synonyms.[object_id] = object_id(@schema_name + N'.' + @object_name)
;

return;
-----------------------------------------------------------------------------------------------------------
end
