/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * [omd_metadata].[LAYER]
 *
 ******************************************************************************/

SET NOCOUNT ON;

INSERT INTO [omd_metadata].[LAYER]
SELECT *
FROM
(
 /* LAYER_CODE, in  */
  VALUES
    (N'Integration',    N'The Integration Layer'),
    (N'Presentation',   N'The Presentation Layer'),
    (N'Staging',        N'The Staging Layer'),
    (N'Maintenance',    N'Internal Data Solution')
) AS refData(LAYER_CODE, LAYER_DESCRIPTION)
WHERE NOT EXISTS (
  SELECT NULL
  FROM [omd_metadata].[LAYER] l
  WHERE l.LAYER_CODE = refData.LAYER_CODE
);

GO
