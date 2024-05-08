/*
Process: Register Module to Batch
Purpose: Assigns a Module to be associated with a Batch. Both the Batch and Module must already exist.
Input: 
  - Module Code
  - Batch Code
  - Debug flag Y/N (defaults to N)
Returns:
  - Default Stored Procedure return code (no specific output)
Usage:
	DECLARE @BatchId INT
	EXEC [omd].[AddModuleToBatch]
		 @ModuleCode = 'MyNewModule'
		,@BatchCode = 'MyNewBatch'
		-- Non mandatory
		,@Debug = 'Y'
*/

CREATE PROCEDURE [omd].[AddModuleToBatch]
	@ModuleCode VARCHAR(255), -- Mandatory
	@BatchCode VARCHAR(255), -- Mandatory
	-- Optional
	@InactiveIndicator CHAR(1) = 'N',
	@Debug VARCHAR(1) = 'N'
AS

BEGIN

	DECLARE @ModuleId INT;
	DECLARE @BatchId INT;

	-- Find the Module Id
	BEGIN TRY
		SELECT @ModuleId = MODULE_ID FROM [omd].[MODULE] WHERE MODULE_CODE = @ModuleCode;

		IF @Debug = 'Y'
			BEGIN 
			IF @ModuleId IS NOT NULL
			PRINT 'Module Id '+CONVERT(VARCHAR(10),@ModuleId)+' has been retrieved for Module Code: '+@ModuleCode+'''.';
		ELSE
			BEGIN
				PRINT 'No Module Id has been found for Module Code '''+@ModuleCode+'''.';
				GOTO EndOfProcedureFailure
			END
	END
	END TRY
	BEGIN CATCH
		THROW 50000,'Incorrect Module Code specified.',1
	END CATCH

	-- Find the Batch Id
	BEGIN TRY
		SELECT @BatchId = BATCH_ID FROM [omd].BATCH WHERE BATCH_CODE = @BatchCode;

		IF @Debug = 'Y'
			BEGIN 
			IF @BatchId IS NOT NULL
			PRINT 'Batch Id '+CONVERT(VARCHAR(10),@BatchId)+' has been retrieved for Batch Code: '+@BatchCode+'''.';
		ELSE
			BEGIN
				PRINT 'No Batch Id has been found for Batch Code '''+@BatchCode+'''.';
				GOTO EndOfProcedureFailure
			END
	END
	END TRY
	BEGIN CATCH
		THROW 50000,'Incorrect Batch Code specified.',1
	END CATCH


	/* 
	  Batch - Module Registration.
	*/

	BEGIN TRY

		INSERT INTO [omd].[BATCH_MODULE] (BATCH_ID, MODULE_ID, INACTIVE_INDICATOR)
		SELECT *
		FROM 
		(
		  VALUES (@BatchId, @ModuleId, @InactiveIndicator)
		) AS refData( BATCH_ID, MODULE_ID, INACTIVE_INDICATOR)
		WHERE NOT EXISTS 
		(
		  SELECT NULL
		  FROM [omd].BATCH_MODULE bm
		  WHERE bm.BATCH_ID = refData.BATCH_ID AND bm.MODULE_ID = refData.MODULE_ID
		);

		IF @Debug = 'Y'
			BEGIN
				PRINT 'The Module '''+@BatchCode+''' ('+CONVERT(VARCHAR(10),@ModuleId)+') is associated with Batch '''+@BatchCode+''' ('+CONVERT(VARCHAR(10),@BatchId)+').';
				PRINT 'SELECT * FROM [omd].[BATCH_MODULE] where [BATCH_ID] = '+CONVERT(VARCHAR(10),@BatchId)+' and [MODULE_ID] = '+CONVERT(VARCHAR(10),@ModuleId)+'.';
			END

		GOTO EndOfProcedureSuccess
	END TRY
	BEGIN CATCH
		THROW
	END CATCH

	EndOfProcedureFailure:

	IF @Debug = 'Y'
		BEGIN
			PRINT CHAR(13)+'-- Batch/Module addition process encountered errors.';	
			GOTO EndOfProcedure
		END

	EndOfProcedureSuccess:

	IF @Debug = 'Y'
		BEGIN
			PRINT CHAR(13)+'-- Batch/Module addition process completed succesfully.';	
			GOTO EndOfProcedure
		END

	-- End label
	EndOfProcedure:

END