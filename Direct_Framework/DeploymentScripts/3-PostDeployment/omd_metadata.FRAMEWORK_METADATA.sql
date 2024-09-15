/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * [omd_metadata].[FRAMEWORK_METADATA]
 *
 ******************************************************************************/

SET NOCOUNT ON;

INSERT INTO [omd_metadata].[FRAMEWORK_METADATA]
SELECT *
FROM (
  /* [CODE], [VALUE], [GROUP], [DESCRIPTION], [ACTIVE_INDICATOR] */
  VALUES
  (
    N'DIRECT_VERSION', N'2.0.0.0', N'SYSTEM_METADATA',
    N'The current version of the DIRECT Framework and database', 'Y'
  )
) AS refData
(
  [CODE], [VALUE], [GROUP], [DESCRIPTION], [ACTIVE_INDICATOR]
)
WHERE NOT EXISTS (
  SELECT NULL
  FROM [omd_metadata].[FRAMEWORK_METADATA] m
  WHERE m.[CODE] = refData.[CODE]
);

GO
