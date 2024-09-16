/* 
  This example combines the registration, and possible reset, for a Module in DIRECT with the execution of specific code to be executed.
*/

/* 
  Parameters 
*/

DECLARE @Reset CHAR(1) = 'N';
DECLARE @ModuleCode VARCHAR(255) = 'DataLogisticsExample';
DECLARE @ModuleDescription VARCHAR(4000) =  'Data logistics Example';
DECLARE @ModuleType VARCHAR(255) = 'SQL';
DECLARE @ModuleSourceDataObject VARCHAR(255) = 'N/A';
DECLARE @ModuleTargetDataObject VARCHAR(255) = 'N/A';
DECLARE @ModuleAreaCode VARCHAR(255) = 'INT';
DECLARE @ModuleFrequency VARCHAR(255) = 'Continuous';
DECLARE @ModuleInactiveIndicator VARCHAR(255) = 'N';

DECLARE @Module_Id INT;
SELECT @Module_Id = module_id FROM [900_Direct_Framework].[omd].module WHERE module_code = @ModuleCode;

/* 
  Module Registration block.
  This is often a separate, independent step.
*/

INSERT INTO [900_Direct_Framework].[omd].MODULE (MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPE, DATA_OBJECT_SOURCE, DATA_OBJECT_TARGET, AREA_CODE, FREQUENCY_CODE, INACTIVE_INDICATOR)
SELECT *
FROM 
(
  VALUES (@ModuleCode, @ModuleDescription, @ModuleType, @ModuleSourceDataObject, @ModuleTargetDataObject,@ModuleAreaCode, @ModuleFrequency, @ModuleInactiveIndicator)    
) AS refData( MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPE, DATA_OBJECT_SOURCE, DATA_OBJECT_TARGET, AREA_CODE, FREQUENCY_CODE, INACTIVE_INDICATOR)
WHERE NOT EXISTS 
(
  SELECT NULL
  FROM [900_Direct_Framework].[omd].MODULE module
  WHERE module.MODULE_CODE = refData.MODULE_CODE
);

/*
  Reset block, for debugging and testing purposes.
*/

IF @Reset = 'Y'
  BEGIN TRY
    BEGIN
      DELETE FROM [900_Direct_Framework].[omd].event_log WHERE MODULE_INSTANCE_ID IN (SELECT MODULE_INSTANCE_ID FROM [900_Direct_Framework].[omd].module_instance WHERE MODULE_ID=@Module_id)
      DELETE FROM [900_Direct_Framework].[omd].source_control WHERE MODULE_INSTANCE_ID IN (SELECT MODULE_INSTANCE_ID FROM [900_Direct_Framework].[omd].module_instance WHERE MODULE_ID=@Module_id)
      DELETE FROM [900_Direct_Framework].[omd].module_instance WHERE MODULE_ID=@Module_id
      DELETE FROM [900_Direct_Framework].[omd].batch_module where module_id = @Module_id
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