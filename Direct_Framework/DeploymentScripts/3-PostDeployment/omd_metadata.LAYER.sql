/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * Reference metadata table LAYER stores layer information.
 *
 * This script is used to insert and update reference data on deployment.
 * Any bespoke layers added manually to the target will be retained,
 * as long as the keys differ.
 * To maintain a clean CI/CD process, consider using this script to manage
 * all reference data for layers.
 *
 * [omd_metadata].[LAYER]
 *
 ******************************************************************************/

SET NOCOUNT ON;

DECLARE @tblMerge TABLE(
  [LAYER_CODE]             NVARCHAR (100)  NOT NULL PRIMARY KEY CLUSTERED,
  [LAYER_DESCRIPTION]      NVARCHAR (4000) NULL
);

INSERT INTO @tblMerge([LAYER_CODE], [LAYER_DESCRIPTION])
VALUES
  (N'Integration',    N'The Integration Layer'),
  (N'Presentation',   N'The Presentation Layer'),
  (N'Staging',        N'The Staging Layer'),
  (N'Maintenance',    N'Internal Data Solution')

MERGE [omd_metadata].[LAYER] AS TARGET
USING @tblMerge AS src
  ON  TARGET.[LAYER_CODE] = src.[LAYER_CODE]
WHEN MATCHED THEN
  UPDATE
  SET      [LAYER_DESCRIPTION] = src.[LAYER_DESCRIPTION]
WHEN NOT MATCHED THEN
  INSERT  ([LAYER_CODE]
          ,[LAYER_DESCRIPTION])
  VALUES  ([LAYER_CODE]
          ,[LAYER_DESCRIPTION]);

GO
