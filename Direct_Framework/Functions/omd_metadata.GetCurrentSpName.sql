-- =============================================
-- Function: GetCurrentSpName
-- Description: Returns the schema-qualified name of the current stored procedure.
-- Parameters: None
-- =============================================

CREATE FUNCTION [omd_metadata].[GetCurrentSpName]()
RETURNS NVARCHAR(261) AS
BEGIN

  RETURN
    QUOTENAME(COALESCE(OBJECT_SCHEMA_NAME(@@PROCID),'Unknown')) +
    N'.' +
    QUOTENAME(COALESCE(OBJECT_NAME(@@PROCID), 'Unknown'))

END
