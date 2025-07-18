-- =============================================
-- Function: Get Framework Version
-- Description: queries the metadata table to get the current version
-- =============================================

CREATE FUNCTION [omd_metadata].[GetFrameworkVersion]()
RETURNS NVARCHAR(4000) AS
BEGIN

  DECLARE @Version NVARCHAR(4000) =
  (
    SELECT TOP 1 md.[VALUE]
    FROM [omd_metadata].[FRAMEWORK_METADATA] md
    WHERE md.[CODE] = 'DIRECT_VERSION'
  )

  RETURN @Version

END
