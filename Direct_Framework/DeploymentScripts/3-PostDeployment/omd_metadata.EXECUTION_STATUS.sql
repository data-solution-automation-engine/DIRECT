/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0

 * Reference metadata table EXECUTION_STATUS stores execution status codes and descriptions.
 * This script is used to insert and update reference data on deployment.
 * Any bespoke execution status codes added manually to the target will be retained,
 * as long as the keys differ.
 * To maintain a clean CI/CD process, consider using this script to manage
 * all reference data for execution status codes.
 *
 * [omd_metadata].[EXECUTION_STATUS]
 *
 ******************************************************************************/

SET NOCOUNT ON;

DECLARE @tblMerge TABLE(
  [EXECUTION_STATUS_CODE]             NVARCHAR (100)  NOT NULL PRIMARY KEY CLUSTERED,
  [EXECUTION_STATUS_DESCRIPTION]      NVARCHAR (4000) NULL
);

INSERT INTO @tblMerge([EXECUTION_STATUS_CODE], [EXECUTION_STATUS_DESCRIPTION])
VALUES
  (N'Aborted',    N'An abort is an attempted execution which led to the instance unable to start. Abort means that the process did not run, but was supposed to. This is typically the result of incorrect configuration or race conditions in the orchestration. The most common reasons for an abort is that another instance of the same Batch or Module is already running. The same logical unit of processing can never run more than once at the same time to maintain data consistency. If this situation is detected the second process will abort before any data is processed. The Module (Instance) was executed from a parent Batch (Instance) but not registered as such in the Batch/Module relationship.'),
  (N'Cancelled',  N'The cancelled (skipped) status code indicates that the instance was attempted to be executed, but that the control framework found that it was not necessary to run the process. This can be due to Modules or Batches being disabled in the framework using the Active Indicator. Disabling processes can be done at Batch, Batch/Module and Module level. Another common scenario is that, when Batches are restarted, earlier successful Modules in that Batch will not be reprocessed. These Module Instances will be skipped / cancelled until the full Batch has completed successfully. This is to prevents data loss.'),
  (N'Executing',  N'The instance is currently running (executing). This is a transient state only, for when the process is actually running. As soon as it is completed this code will be updated to one of the end-state execution codes.'),
  (N'Failed',     N'The instance is no longer running after completing with failures.'),
  (N'Succeeded',  N'The instance is no longer running after successful completion of the process.')

MERGE [omd_metadata].[EXECUTION_STATUS] AS TARGET
USING @tblMerge AS src
  ON  TARGET.[EXECUTION_STATUS_CODE] = src.[EXECUTION_STATUS_CODE]

WHEN MATCHED THEN
  UPDATE
  SET      [EXECUTION_STATUS_DESCRIPTION] = src.[EXECUTION_STATUS_DESCRIPTION]

WHEN NOT MATCHED THEN
  INSERT  ([EXECUTION_STATUS_CODE]
          ,[EXECUTION_STATUS_DESCRIPTION])
  VALUES  ([EXECUTION_STATUS_CODE]
          ,[EXECUTION_STATUS_DESCRIPTION]);

GO
