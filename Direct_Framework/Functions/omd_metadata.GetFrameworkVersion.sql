CREATE FUNCTION [omd_metadata].[GetFrameworkVersion]()

RETURNS NVARCHAR(100) AS

-- =============================================
-- Function: Get Framework Version
-- Description: queries the metadata table to get the current version
-- =============================================

BEGIN

  DECLARE @Version NVARCHAR(100) =
  (
    SELECT md.[VALUE]
    FROM [omd_metadata].[FRAMEWORK_METADATA] md
    WHERE md.[CODE] = 'DIRECT_VERSION'
  )

  RETURN @Version

END
