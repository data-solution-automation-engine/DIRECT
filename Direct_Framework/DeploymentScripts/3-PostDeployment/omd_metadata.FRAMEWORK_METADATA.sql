/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * Reference metadata table FRAMEWORK_METADATA stores metadata information.
 * This script is used to insert and update reference data on deployment.
 * Any bespoke metadata added manually to the target will be retained,
 * as long as the keys differ.
 * To maintain a clean CI/CD process, consider using this script to manage
 * all reference data for metadata.
 *
 * [omd_metadata].[FRAMEWORK_METADATA]
 *
 ******************************************************************************/

SET NOCOUNT ON;

DECLARE @tblMerge TABLE(
  [CODE]             NVARCHAR (100)  NOT NULL PRIMARY KEY CLUSTERED,
  [VALUE]            NVARCHAR (4000) NULL,
  [GROUP]            NVARCHAR (100)  NOT NULL,
  [DESCRIPTION]      NVARCHAR (4000) NULL,
  [ACTIVE_INDICATOR] CHAR(1)         NOT NULL
);

INSERT INTO @tblMerge([CODE], [VALUE], [GROUP], [DESCRIPTION], [ACTIVE_INDICATOR])
VALUES
  (N'DIRECT_VERSION', N'2.0.0.0', N'SYSTEM_METADATA', N'The current version of the DIRECT Framework and database', 'Y')

MERGE [omd_metadata].[FRAMEWORK_METADATA] AS TARGET
USING @tblMerge AS src
  ON  TARGET.[CODE] = src.[CODE]

WHEN MATCHED THEN
  UPDATE
  SET      [VALUE] = src.[VALUE],
           [GROUP] = src.[GROUP],
           [DESCRIPTION] = src.[DESCRIPTION],
           [ACTIVE_INDICATOR] = src.[ACTIVE_INDICATOR]

WHEN NOT MATCHED THEN
  INSERT  ([CODE]
          ,[VALUE]
          ,[GROUP]
          ,[DESCRIPTION]
          ,[ACTIVE_INDICATOR])
  VALUES  ([CODE]
          ,[VALUE]
          ,[GROUP]
          ,[DESCRIPTION]
          ,[ACTIVE_INDICATOR]);

GO
