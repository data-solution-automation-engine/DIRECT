

CREATE FUNCTION [omd].[GetDependency] (@SchemaName VARCHAR(128), @Table VARCHAR(128))
RETURNS VARCHAR(MAX) AS 
BEGIN 

DECLARE @Output VARCHAR(MAX)

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
SELECT @Output = LTRIM(RTRIM(@Output));

RETURN @Output;

END

