/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * [omd_metadata].[AREA]
 *
 ******************************************************************************/
SET NOCOUNT ON;

INSERT INTO [omd_metadata].[AREA]
SELECT [AREA_CODE], [LAYER_CODE], [AREA_DESCRIPTION]
FROM (
  /* AREA_CODE, LAYER_CODE, AREA_DESCRIPTION */
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
 ) AS refData(AREA_CODE, LAYER_CODE, AREA_DESCRIPTION)
WHERE NOT EXISTS (
  SELECT NULL
  FROM [omd_metadata].[AREA] a
  WHERE a.AREA_CODE = refData.AREA_CODE
  );

GO
