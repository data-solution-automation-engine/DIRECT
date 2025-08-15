/**
 * @function [dbo].[GetDependency]
 * @description
 *   Returns a string of referenced objects for the given table/view.
 *   Optionally uses fully-qualified names.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @param {VARCHAR(128)} @SchemaName  [in] (required)
 *   The schema of the object.
 * @param {VARCHAR(128)} @Table  [in] (required)
 *   The name of the object.
 * @param {CHAR(1)} @UseFullyQualifiedName  [in] (optional, default='Y')
 *   Whether to return fully-qualified object names.
 *
 * @returns {VARCHAR(MAX)} A quoted, comma-separated list of dependencies.
 *
 * @resultset none
 *
 * @lineage
 * - reads:
 *     sys.sql_expression_dependencies
 *
 * @example

SELECT [dbo].[GetDependency](N'dbo', N'MyView', 'Y');

 */

CREATE FUNCTION [dbo].[GetDependency]
(
  @SchemaName VARCHAR(128),
  @Table VARCHAR(128),
  @UseFullyQualifiedName CHAR(1) = 'Y'
)
RETURNS VARCHAR(MAX) AS
BEGIN

  DECLARE @Output VARCHAR(MAX)

  IF @UseFullyQualifiedName = 'Y'
    BEGIN
      SELECT @Output =
      ''''+
      stuff
      (
        (
          SELECT DISTINCT ', ' + '[' + referenced_database_name+'].'+ '[' + referenced_schema_name+'].'  + '[' + referenced_entity_name + ']'
          FROM sys.sql_expression_dependencies  t2
          WHERE referencing_id = OBJECT_ID(N''+@SchemaName+'.'+@Table+'')
          FOR XML PATH('')
        ),
        1,
        1,
        ''
      )
      + ''''
    END
  ELSE
    BEGIN
      SELECT @Output =
      ''''+
      stuff
      (
      (
        SELECT DISTINCT ', ' + referenced_entity_name
        FROM sys.sql_expression_dependencies  t2
        WHERE referencing_id = OBJECT_ID(N''+@SchemaName+'.'+@Table+'')
        FOR XML PATH('')
      ),
      1,
      1,
      ''
      )
      + ''''
    END

  SELECT @Output = LTRIM(RTRIM(@Output));

  RETURN @Output;

END
