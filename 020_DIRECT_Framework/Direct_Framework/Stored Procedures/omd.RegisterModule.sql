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
	@ModuleDescription VARCHAR(MAX) = '',
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
    IF @Debug = 'Y' 
		PRINT 'Registering Module for '+@ModuleCode+'.';

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


	IF @ModuleId IS NOT NULL
		BEGIN
			IF @Debug = 'Y'
				PRINT 'A new Module Id '+CONVERT(VARCHAR(10),@ModuleId)+' has been created for Module Code: '+@ModuleCode+'''.';
		END
	ELSE
		BEGIN
			-- Get the Module Id
			SELECT @ModuleId = MODULE_ID FROM [omd].[MODULE] WHERE MODULE_CODE = @ModuleCode;

			IF @Debug = 'Y'
				BEGIN
					PRINT 'The Module '''+@ModuleCode+''' already exists in [omd].[MODULE] with Module Id '''+CONVERT(VARCHAR(10),@ModuleId)+'''.';
					PRINT 'SELECT * FROM [omd].[MODULE] where [MODULE_CODE] = '''+@ModuleCode+'''.';
				END

			-- Evaluate the incoming values to see if the Module requires to be updated.
		    DECLARE @NewChecksum BINARY(20) = HASHBYTES('SHA1', 
												@ModuleDescription+'!'+
												@ModuleType+'!'+
												@ModuleSourceDataObject+'!'+
												@ModuleTargetDataObject+'!'+
												@ModuleAreaCode+'!'+
												@ModuleFrequency+'!'+
												@Executable);

			IF @Debug = 'Y'
				PRINT 'The incoming module checksum is '+CONVERT(VARCHAR(40),@NewChecksum)+'.';

			-- Evaluate the existing values to see if the Module requires to be updated.
			DECLARE @ExistingChecksum BINARY(20);
			SELECT @ExistingChecksum = HASHBYTES('SHA1', 
												COALESCE([MODULE_DESCRIPTION],'N/A')+'!'+
												COALESCE([MODULE_TYPE],'N/A')+'!'+
												COALESCE([DATA_OBJECT_SOURCE],'N/A')+'!'+
												COALESCE([DATA_OBJECT_TARGET],'N/A')+'!'+
												COALESCE([AREA_CODE],'N/A')+'!'+
												COALESCE([FREQUENCY_CODE],'N/A')+'!'+
												COALESCE([EXECUTABLE],'N/A'))
									   FROM [omd].[MODULE] WHERE [MODULE_CODE] = @ModuleCode;

			IF @Debug = 'Y'
				PRINT 'The previous/existing module checksum is '+CONVERT(VARCHAR(40),@ExistingChecksum)+'.';

			-- Update the existing Module with new values, if they are different.
			IF @NewChecksum != @ExistingChecksum
				BEGIN TRY
					IF @Debug = 'Y'
						PRINT concat('The checksums are different, and module ''', @ModuleCode, ''' with Module Id '''+CONVERT(VARCHAR(10),@ModuleId)+''' will be updated.');		

					UPDATE [omd].[MODULE] SET
						[MODULE_DESCRIPTION] = @ModuleDescription,
						[MODULE_TYPE] = @ModuleType,
						[DATA_OBJECT_SOURCE] = @ModuleSourceDataObject,
						[DATA_OBJECT_TARGET] = @ModuleTargetDataObject,
						[AREA_CODE] = @ModuleAreaCode,
						[FREQUENCY_CODE] = @ModuleFrequency,
						[EXECUTABLE] = @Executable
					WHERE [MODULE_ID] = @ModuleId;

					IF @Debug = 'Y'
						PRINT concat('The module ''', @ModuleCode, ''' has been updated.');		
				END TRY
				BEGIN CATCH
					IF @Debug = 'Y'
						PRINT concat('Error. The update for module ''', @ModuleCode, ''' failed.');
					THROW
				END CATCH
		END
END