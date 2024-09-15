CREATE FUNCTION [omd_processing].[GetDependentTables]
(
  @schema_name sysname,
  @object_name sysname
)

RETURNS @rtnTbl TABLE
(
  referenced_schema_name sysname NOT NULL,
  referenced_object_name sysname NOT NULL
)

-- =============================================
-- Function:    Returns the underlying tables on which the specified object depends.
--              - If the provided object is a table, then will simply reflect that table name.
-- Description: - Works recursively where found dependencies which are not a table.
--              - As this procedure does not traverse dependencies through packages. Only local tables
--                which are accessed by the query which loads the specified target are returned.
-- =============================================

AS

BEGIN
-----------------------------------------------------------------------------------------------------------
  WITH allDeps
  AS
  (
    SELECT
      sql_expression_dependencies.referencing_id,
      object_schema_name(sql_expression_dependencies.referencing_id) AS referencing_schema_name,
      object_name(sql_expression_dependencies.referencing_id) AS referencing_entity_name,
      pre_calc.referenced_schema_name,
      sql_expression_dependencies.referenced_entity_name,
      objects.[type_desc] AS referenced_type_desc
    FROM sys.sql_expression_dependencies
    OUTER APPLY
    (
      SELECT
        coalesce(sql_expression_dependencies.referenced_database_name, db_name()) AS referenced_database_name,
        coalesce (sql_expression_dependencies.referenced_schema_name, 'dbo') AS referenced_schema_name
    ) pre_calc
    INNER JOIN sys.objects ON objects.[object_id] = sql_expression_dependencies.referenced_id
    WHERE pre_calc.referenced_database_name = db_name() /* object dependencies are expected to never be cross-database */
    AND object_schema_name(sql_expression_dependencies.referencing_id) NOT LIKE N'omd%'
    AND object_schema_name(sql_expression_dependencies.referencing_id) NOT IN (N'tSQLt')
    AND object_schema_name(sql_expression_dependencies.referencing_id) NOT LIKE N'test%'
    AND NOT EXISTS
    (
      /* excluded table self-dependencies, such as from calculated columns */
      SELECT NULL
      FROM sys.objects start_type
      WHERE start_type.[object_id] = sql_expression_dependencies.referencing_id
        AND start_type.[type_desc] IN ('USER_TABLE', 'SYNONYM')
    )
    GROUP BY
      sql_expression_dependencies.referencing_id,
      pre_calc.referenced_schema_name,
      sql_expression_dependencies.referenced_entity_name,
      objects.[type_desc]
  ),
  recursiveCTE
  AS
  (
    SELECT referencing_schema_name, referencing_entity_name, referenced_schema_name, referenced_entity_name, referenced_type_desc
    FROM allDeps
    WHERE allDeps.referencing_id = object_id(@schema_name + N'.' + @object_name)
    UNION ALL
    SELECT
      recursiveCTE.referencing_schema_name AS referencing_schema_name,
      recursiveCTE.referencing_entity_name AS referencing_entity_name,
      allDeps.referenced_schema_name,
      allDeps.referenced_entity_name,
      allDeps.referenced_type_desc
    FROM recursiveCTE
    INNER JOIN allDeps
      ON allDeps.referencing_schema_name = recursiveCTE.referenced_schema_name
      AND allDeps.referencing_entity_name = recursiveCTE.referenced_entity_name
    WHERE recursiveCTE.referenced_type_desc NOT IN ('USER_TABLE', 'SYNONYM')
  )

  /* add to returned results table */
  INSERT INTO @rtnTbl
  SELECT
    referenced_schema_name AS REFERENCED_SCHEMA_NAME,
    referenced_entity_name AS REFERENCED_OBJECT_NAME
  FROM recursiveCTE
  WHERE recursiveCTE.referenced_type_desc IN ('USER_TABLE', 'SYNONYM')

  UNION

  SELECT @schema_name AS REFERENCED_SCHEMA_NAME, @object_name AS REFERENCED_OBJECT_NAME
  FROM sys.tables
  WHERE tables.[object_id] = object_id(@schema_name + N'.' + @object_name)

  UNION

  SELECT @schema_name AS REFERENCED_SCHEMA_NAME, @object_name AS REFERENCED_OBJECT_NAME
  FROM sys.synonyms
  WHERE synonyms.[object_id] = object_id(@schema_name + N'.' + @object_name);

  RETURN;
  -----------------------------------------------------------------------------------------------------------
END
