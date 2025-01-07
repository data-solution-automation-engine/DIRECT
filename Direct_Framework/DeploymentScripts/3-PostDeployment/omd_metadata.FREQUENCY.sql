/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * Reference metadata table FREQUENCY stores frequency information.
 * This table is used to define the frequency of the processing unit.
 * This script is used to insert and update reference data on deployment.
 * Any bespoke frequency added manually to the target will be retained,
 * as long as the keys differ.
 * To maintain a clean CI/CD process, consider using this script to manage
 * all reference data for frequency.
 *
 * [omd_metadata].[FREQUENCY]
 *
 ******************************************************************************/

SET NOCOUNT ON;

DECLARE @tblMerge TABLE(
  [FREQUENCY_CODE]        NVARCHAR (100)  NOT NULL PRIMARY KEY CLUSTERED,
  [FREQUENCY_DESCRIPTION] NVARCHAR (4000) NOT NULL
);

INSERT INTO @tblMerge([FREQUENCY_CODE], [FREQUENCY_DESCRIPTION])
VALUES
  (N'Continuous', N'Continuously running integration processing unit.'),
  (N'Triggered',  N'Event triggered processing unit.'),
  (N'On-demand',  N'On-demand processing unit.'),
  (N'Scheduled',  N'Scheduled processing unit.')

MERGE [omd_metadata].[FREQUENCY] AS TARGET
USING @tblMerge AS src
  ON TARGET.[FREQUENCY_CODE] = src.[FREQUENCY_CODE]

WHEN MATCHED THEN
  UPDATE
  SET [FREQUENCY_DESCRIPTION] = src.[FREQUENCY_DESCRIPTION]

WHEN NOT MATCHED THEN
  INSERT ([FREQUENCY_CODE], [FREQUENCY_DESCRIPTION])
  VALUES ([FREQUENCY_CODE], [FREQUENCY_DESCRIPTION]);

GO
