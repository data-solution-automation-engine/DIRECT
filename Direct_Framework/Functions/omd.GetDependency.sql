CREATE FUNCTION [dbo].[GetDependency]
(
  @SchemaName VARCHAR(128),
  @Table VARCHAR(128),
  @UseFullyQualifiedName CHAR(1) = 'Y'
)
RETURNS VARCHAR(MAX) AS

-- =============================================
-- Function: Get Dependency
-- Description: TODO: tba...
-- =============================================

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
