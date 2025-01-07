/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * Reference metadata table AREA stores areas and layers information.
 *
 * This script is used to insert and update reference data on deployment.
 * Any bespoke event types added manually to the target will be retained,
 * as long as the keys differ.
 *
 * To maintain a clean CI/CD process, consider using this script to manage
 * all reference data for event types.
 *
 * [omd_metadata].[AREA]
 *
 ******************************************************************************/

SET NOCOUNT ON;

DECLARE @tblMerge TABLE(
  [AREA_CODE]             NVARCHAR (100)  NOT NULL PRIMARY KEY CLUSTERED,
  [LAYER_CODE]            NVARCHAR (100)  NOT NULL,
  [AREA_DESCRIPTION]      NVARCHAR (4000) NULL
);

INSERT INTO @tblMerge([AREA_CODE], [LAYER_CODE], [AREA_DESCRIPTION])
VALUES
  (N'HELPER',       N'Presentation',  N'The Helper Area'),
  (N'INT',          N'Integration',   N'The Base Integration Area'),
  (N'INTPR',        N'Integration',   N'The Derived Integration Area'),
  (N'LND',          N'Staging',       N'The Landing Area of the Staging Layer'),
  (N'Maintenance',  N'Maintenance',   N'Internal Data Solution'),
  (N'PRES',         N'Presentation',  N'The Access Area'),
  (N'PSA',          N'Staging',       N'The Persistent Staging Area'),
  (N'STG',          N'Staging',       N'The Staging Area of the Staging Layer'),
  (N'SYNC',         N'Staging',       N'Synchronization of the production History Area of the Staging Layer for build and test')

 MERGE [omd_metadata].[AREA] AS TARGET
  USING @tblMerge AS src
      ON  TARGET.[AREA_CODE] = src.[AREA_CODE]

  WHEN MATCHED THEN
      UPDATE
      SET      [LAYER_CODE] = src.[LAYER_CODE],
               [AREA_DESCRIPTION] = src.[AREA_DESCRIPTION]

  WHEN NOT MATCHED THEN
      INSERT  ([AREA_CODE]
              ,[LAYER_CODE]
              ,[AREA_DESCRIPTION])
      VALUES  ([AREA_CODE]
              ,[LAYER_CODE]
              ,[AREA_DESCRIPTION]);

GO
