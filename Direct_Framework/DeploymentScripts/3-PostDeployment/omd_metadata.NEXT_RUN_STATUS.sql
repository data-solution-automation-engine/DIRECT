/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * [omd_metadata].[NEXT_RUN_STATUS]
 *
 ******************************************************************************/

SET NOCOUNT ON;

INSERT INTO [omd_metadata].[NEXT_RUN_STATUS]
SELECT *
FROM (
 /* NEXT_RUN_STATUS_CODE, NEXT_RUN_STATUS_CODE_DESCRIPTION */
 VALUES
 (N'Cancel',    N'Administrators can manually set this code to for the Next Run Status (i.e. this will not be automatically set by the DIRECT controls) to force a one-off skip of the instance.'),
 (N'Proceed',   N'The `Proceed` code will direct the next run of the Batch/Module to continue processing. This is the default value. Each process step will evaluate the Internal Process Status Code and continue only if it was set to `Proceed`. After the rollback has been completed the `Proceed` value is the code that is required to initiate the main process.'),
 (N'Rollback',  N'When a current (running) Instance fails the Next Run Status for that Instance is updated to `Rollback` to signal the next run to initiate a rollback procedure. At the same time, the Execution Status Code for the current Instance will be set to `Failed`. Administrators can manually change the Next Run Status value for an Instance to `Rollback` if they want to force a rollback when the next run starts.')
 ) AS refData(NEXT_RUN_STATUS_CODE, NEXT_RUN_STATUS_CODE_DESCRIPTION)
WHERE NOT EXISTS (
  SELECT NULL
  FROM [omd_metadata].[NEXT_RUN_STATUS] nri
  WHERE nri.NEXT_RUN_STATUS_CODE = refData.NEXT_RUN_STATUS_CODE
  );

GO
