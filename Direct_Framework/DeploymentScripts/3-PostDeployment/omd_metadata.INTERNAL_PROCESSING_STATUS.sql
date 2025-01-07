/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * Reference metadata table INTERNAL_PROCESSING_STATUS stores internal processing status codes and descriptions.
 *
 * This script is used to insert and update reference data on deployment.
 * Any bespoke internal processing status codes added manually to the target will be retained,
 * as long as the keys differ.
 * To maintain a clean CI/CD process, consider using this script to manage
 * all reference data for internal processing status codes.
 *
 * [omd_metadata].[INTERNAL_PROCESSING_STATUS]
 *
 ******************************************************************************/

SET NOCOUNT ON;

DECLARE @tblMerge TABLE(
  [INTERNAL_PROCESSING_STATUS_CODE]             NVARCHAR (100)  NOT NULL PRIMARY KEY CLUSTERED,
  [INTERNAL_PROCESSING_STATUS_DESCRIPTION]      NVARCHAR (4000) NULL
);

INSERT INTO @tblMerge([INTERNAL_PROCESSING_STATUS_CODE], [INTERNAL_PROCESSING_STATUS_DESCRIPTION])
VALUES
  (N'Abort',     N'This exception case indicates that the instance in question was executed, but that another instance of the same Batch or Module is already running (see also the equivalent Execution Status Code for additional detail). This is one of the checks performed before the regular process (Module and/or Batch) can continue. If this situation occurs, all processing should stop; no data should be processed. The process will use the Internal Processing Status `Abort` to trigger the Module/Batch `Abort` event which sets the Execution Status Code to `Cancelled`, ending the process gracefully.'),
  (N'Cancel',    N'The instance evaluation has determined that it is not necessary to run this process (see also the equivalent Execution Status Code for additional detail). As with Abort, if the Internal Process Status code is `Cancel` then all further processing should stop after the Execution Status Code has also been updated to `Cancel`.'),
  (N'Proceed',   N'The instance can continue on to the next processing. This is the default internal processing value; each process step will evaluate the Internal Process Status code and continue only if it is set to `Proceed`. After the pre-processing has been completed the `Proceed` value is the flag that is required to initiate the main process.'),
  (N'Rollback',  N'The `Rollback` code is only temporarily set during rollback execution in the Module Evaluation event. This is essentially for debugging purposes. After the rollback is completed the Internal Processing Status will be set to `Proceed` again to enable the continuation of the process.');

MERGE [omd_metadata].[INTERNAL_PROCESSING_STATUS] AS TARGET
USING @tblMerge AS src
  ON  TARGET.[INTERNAL_PROCESSING_STATUS_CODE] = src.[INTERNAL_PROCESSING_STATUS_CODE]
WHEN MATCHED THEN
  UPDATE
  SET      [INTERNAL_PROCESSING_STATUS_DESCRIPTION] = src.[INTERNAL_PROCESSING_STATUS_DESCRIPTION]
WHEN NOT MATCHED THEN
  INSERT  ([INTERNAL_PROCESSING_STATUS_CODE]
          ,[INTERNAL_PROCESSING_STATUS_DESCRIPTION])
  VALUES  ([INTERNAL_PROCESSING_STATUS_CODE]
          ,[INTERNAL_PROCESSING_STATUS_DESCRIPTION]);

GO
