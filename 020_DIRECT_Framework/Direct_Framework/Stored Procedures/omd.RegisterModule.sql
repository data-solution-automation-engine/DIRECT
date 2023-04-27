/*
Process: Register Module
Purpose: Creates (registers) a new Module, if it doesn't yet exist by name (Module Code)
Input: 
  - Module Code
  - Area Code
  - Debug flag Y/N (defaults to N)
Returns:
  - Module Id
Usage:
	DECLARE @ModuleId INT
	EXEC [omd].[RegisterModule]
		 @ModuleCode = 'MyNewModule'
		,@ModuleAreaCode = 'Maintenance'
		,@Executable = 'SELECT GETDATE()'
		-- Non mandatory
		,@ModuleDescription = 'Data logistics Example'
		,@Debug = 'Y'
		-- Output
		,@ModuleId = @ModuleId OUTPUT;
	PRINT 'The Module Id is: '+CONVERT(VARCHAR(10),@ModuleId)+'.';
*/

CREATE PROCEDURE [omd].[RegisterModule]
	@ModuleCode VARCHAR(255), -- Mandatory
	@ModuleDescription VARCHAR(MAX),
	@ModuleType VARCHAR(255) = 'SQL',
	@ModuleSourceDataObject VARCHAR(255) = 'NA',
	@ModuleTargetDataObject VARCHAR(255) = 'NA',
	@ModuleAreaCode VARCHAR(255), -- Mandatory
	@ModuleFrequency VARCHAR(255) = 'Continuous', -- Be able to run at any time by default
	@ModuleInactiveIndicator CHAR(1) = 'N',
	@Debug VARCHAR(1) = 'N',
	@Executable VARCHAR(MAX), -- Mandatory
	@ModuleId INT = NULL OUTPUT -- Return the Module Id as output
AS

BEGIN

	/* 
	  Module Registration.
	*/
	BEGIN TRY
		INSERT INTO [omd].MODULE (MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPE, DATA_OBJECT_SOURCE, DATA_OBJECT_TARGET, AREA_CODE, FREQUENCY_CODE, INACTIVE_INDICATOR, [EXECUTABLE])
		SELECT *
		FROM 
		(
		  VALUES (@ModuleCode, @ModuleDescription, @ModuleType, @ModuleSourceDataObject, @ModuleTargetDataObject,@ModuleAreaCode, @ModuleFrequency, @ModuleInactiveIndicator, @Executable)
		) AS refData( MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPE, DATA_OBJECT_SOURCE, DATA_OBJECT_TARGET, AREA_CODE, FREQUENCY_CODE, INACTIVE_INDICATOR, [EXECUTABLE])
		WHERE NOT EXISTS 
		(
		  SELECT NULL
		  FROM [omd].MODULE module
		  WHERE module.MODULE_CODE = refData.MODULE_CODE
		);
	END TRY
	BEGIN CATCH
		THROW
	END CATCH

	SET @ModuleId = SCOPE_IDENTITY();

	IF @Debug = 'Y'
	BEGIN 
		IF @ModuleId IS NOT NULL
			PRINT 'A new Module Id '+CONVERT(VARCHAR(10),@ModuleId)+' has been created for Module Code: '+@ModuleCode+'''.';
		ELSE
			BEGIN
				SELECT @ModuleId = MODULE_ID FROM [omd].[MODULE] WHERE MODULE_CODE = @ModuleCode;
				PRINT 'The Module '''+@ModuleCode+''' already exists in [omd].[MODULE] with Module Id '''+CONVERT(VARCHAR(10),@ModuleId)+'''.';
				PRINT 'SELECT * FROM [omd].[MODULE] where [MODULE_CODE] = '''+@ModuleCode+'''.';
			END
	END
END