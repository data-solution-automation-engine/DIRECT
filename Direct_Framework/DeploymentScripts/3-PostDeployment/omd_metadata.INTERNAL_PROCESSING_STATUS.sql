/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * [omd_metadata].[INTERNAL_PROCESSING_STATUS]
 *
 ******************************************************************************/

SET NOCOUNT ON;

INSERT INTO [omd_metadata].[INTERNAL_PROCESSING_STATUS]
SELECT *
FROM (
 /* INTERNAL_PROCESSING_STATUS_CODE, INTERNAL_INTERNAL_PROCESSING_STATUS_DESCRIPTION */
 VALUES
 (N'Abort',     N'This exception case indicates that the instance in question was executed, but that another instance of the same Batch or Module is already running (see also the equivalent Execution Status Code for additional detail). This is one of the checks performed before the regular process (Module and/or Batch) can continue. If this situation occurs, all processing should stop; no data should be processed. The process will use the Internal Processing Status `Abort` to trigger the Module/Batch `Abort` event which sets the Execution Status Code to `Cancelled`, ending the process gracefully.'),
 (N'Cancel',    N'The instance evaluation has determined that it is not necessary to run this process (see also the equivalent Execution Status Code for additional detail). As with Abort, if the Internal Process Status code is `Cancel` then all further processing should stop after the Execution Status Code has also been updated to `Cancel`.'),
 (N'Proceed',   N'The instance can continue on to the next processing. This is the default internal processing value; each process step will evaluate the Internal Process Status code and continue only if it is set to `Proceed`. After the pre-processing has been completed the `Proceed` value is the flag that is required to initiate the main process.'),
 (N'Rollback',  N'The `Rollback` code is only temporarily set during rollback execution in the Module Evaluation event. This is essentially for debugging purposes. After the rollback is completed the Internal Processing Status will be set to `Proceed` again to enable the continuation of the process.')
 ) AS refData(INTERNAL_PROCESSING_STATUS_CODE, INTERNAL_PROCESSING_STATUS_DESCRIPTION)
WHERE NOT EXISTS (
  SELECT NULL
  FROM [omd_metadata].[INTERNAL_PROCESSING_STATUS] pin
  WHERE pin.INTERNAL_PROCESSING_STATUS_CODE = refData.INTERNAL_PROCESSING_STATUS_CODE
  );

GO
