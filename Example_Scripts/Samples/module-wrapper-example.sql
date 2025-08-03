/*
  This example combines the registration, and possible reset, for a Module in DIRECT with the execution of specific code to be executed.
*/

/*
  Parameters
*/

DECLARE @Reset CHAR(1) = 'Y';
DECLARE @ModuleCode VARCHAR(255) = 'DataLogisticsExample';
DECLARE @ModuleDescription VARCHAR(255) =  'Data logistics Example';
DECLARE @ModuleType VARCHAR(255) = 'SQL';
DECLARE @ModuleSourceDataObject VARCHAR(255) = 'N/A';
DECLARE @ModuleTargetDataObject VARCHAR(255) = 'N/A';
DECLARE @ModuleAreaCode VARCHAR(255) = 'INT';
DECLARE @ModuleFrequency VARCHAR(255) = 'Continuous';
DECLARE @ModuleActiveIndicator VARCHAR(255) = 'Y';

DECLARE @Module_Id INT;
SELECT @Module_Id = MODULE_ID FROM [Direct_Framework].[omd].[MODULE] WHERE MODULE_CODE = @ModuleCode;

/*
  Module Registration.
  This is often a separate, independent step.
*/

INSERT INTO [Direct_Framework].[omd].MODULE (MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPE, DATA_OBJECT_SOURCE, DATA_OBJECT_TARGET, AREA_CODE, FREQUENCY_CODE, ACTIVE_INDICATOR)
SELECT *
FROM
(
  VALUES (@ModuleCode, @ModuleDescription, @ModuleType, @ModuleSourceDataObject, @ModuleTargetDataObject,@ModuleAreaCode, @ModuleFrequency, @ModuleActiveIndicator)
) AS refData( MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPE, DATA_OBJECT_SOURCE, DATA_OBJECT_TARGET, AREA_CODE, FREQUENCY_CODE, INACTIVE_INDICATOR)
WHERE NOT EXISTS
(
  SELECT NULL
  FROM [Direct_Framework].[omd].MODULE module
  WHERE module.MODULE_CODE = refData.MODULE_CODE
);

/*
  Reset block, for debugging and testing purposes.
*/

IF @Reset = 'Y'
  BEGIN TRY
    BEGIN
      DELETE FROM [Direct_Framework].[omd].[EVENT_LOG] WHERE MODULE_INSTANCE_ID IN (SELECT MODULE_INSTANCE_ID FROM [Direct_Framework].[omd].[MODULE_INSTANCE] WHERE MODULE_ID = @Module_id)
      DELETE FROM [Direct_Framework].[omd].[SOURCE_CONTROL] WHERE MODULE_INSTANCE_ID IN (SELECT MODULE_INSTANCE_ID FROM [Direct_Framework].[omd].[MODULE_INSTANCE] WHERE MODULE_ID = @Module_id)
      DELETE FROM [Direct_Framework].[omd].[MODULE_INSTANCE] WHERE MODULE_ID = @Module_id
      DELETE FROM [Direct_Framework].[omd].[BATCH_MODULE] where MODULE_ID = @Module_id
    END
  END TRY

  BEGIN CATCH
    THROW
  END CATCH

/*
  Start a new Module Instance.
*/

BEGIN

  EXEC [omd].[RunModule]
    @ModuleCode = @ModuleCode,
	  @Debug = 'Y',
	  @Query = 'SELECT GETDATE()'

END
GO

/* Control block for reviewing the tests
SELECT * FROM omd.MODULE
SELECT * FROM omd.MODULE_INSTANCE
SELECT * FROM omd.MODULE_INSTANCE_EXECUTED_CODE WHERE CHECKSUM='0xB776F34A647256234B172290D258C16E837CB980E4017898265A1B62806840D9BADF77AC518DC6CA1D33862ED9681F22CAA2BF45EB3DA97F8E346A5E75EDCEF6'
*/
