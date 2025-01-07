/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * Reference metadata table NEXT_RUN_STATUS stores next run status codes and descriptions.
 * This script is used to insert and update reference data on deployment.
 * Any bespoke next run status codes added manually to the target will be retained,
 * as long as the keys differ.
 * To maintain a clean CI/CD process, consider using this script to manage
 * all reference data for next run status codes.
 *
 * [omd_metadata].[NEXT_RUN_STATUS]
 *
 ******************************************************************************/

SET NOCOUNT ON;

DECLARE @tblMerge TABLE(
  [NEXT_RUN_STATUS_CODE]             NVARCHAR (100)  NOT NULL PRIMARY KEY CLUSTERED,
  [NEXT_RUN_STATUS_CODE_DESCRIPTION] NVARCHAR (4000) NULL
);

INSERT INTO @tblMerge([NEXT_RUN_STATUS_CODE], [NEXT_RUN_STATUS_CODE_DESCRIPTION])
VALUES
  (N'Cancel',    N'Administrators can manually set this code to for the Next Run Status (i.e. this will not be automatically set by the DIRECT controls) to force a one-off skip of the instance.'),
  (N'Proceed',   N'The `Proceed` code will direct the next run of the Batch/Module to continue processing. This is the default value. Each process step will evaluate the Internal Process Status Code and continue only if it was set to `Proceed`. After the rollback has been completed the `Proceed` value is the code that is required to initiate the main process.'),
  (N'Rollback',  N'When a current (running) Instance fails the Next Run Status for that Instance is updated to `Rollback` to signal the next run to initiate a rollback procedure. At the same time, the Execution Status Code for the current Instance will be set to `Failed`. Administrators can manually change the Next Run Status value for an Instance to `Rollback` if they want to force a rollback when the next run starts.')

MERGE [omd_metadata].[NEXT_RUN_STATUS] AS TARGET
USING @tblMerge AS src
  ON  TARGET.[NEXT_RUN_STATUS_CODE] = src.[NEXT_RUN_STATUS_CODE]
WHEN MATCHED THEN
  UPDATE
  SET      [NEXT_RUN_STATUS_CODE_DESCRIPTION] = src.[NEXT_RUN_STATUS_CODE_DESCRIPTION]
WHEN NOT MATCHED THEN
  INSERT  ([NEXT_RUN_STATUS_CODE]
          ,[NEXT_RUN_STATUS_CODE_DESCRIPTION])
  VALUES  ([NEXT_RUN_STATUS_CODE]
          ,[NEXT_RUN_STATUS_CODE_DESCRIPTION]);

GO
