/*
Process: Register Batch
Purpose: Creates (registers) a new Batch, if it doesn't yet exist by name (Batch Code)
Input: 
  - Batch Code
  - Area Code
  - Debug flag Y/N (defaults to N)
Returns:
  - Batch Id
Usage:
	DECLARE @BatchId INT
	EXEC [omd].[RegisterBatch]
		 @BatchCode = 'MyNewBatch'
		-- Non mandatory
		,@BatchDescription = 'Data logistics Workflow'
		,@Debug = 'Y'
		-- Output
		,@BatchId = @BatchId OUTPUT;
	PRINT 'The Batch Id is: '+CONVERT(VARCHAR(10),@BatchId)+'.';
*/

CREATE PROCEDURE [omd].[RegisterBatch]
	@BatchCode VARCHAR(255), -- Mandatory
	@BatchDescription VARCHAR(MAX),
	@BatchFrequency VARCHAR(255) = 'Continuous', -- Be able to run at any time by default
	@BatchInactiveIndicator CHAR(1) = 'N',
	@Debug VARCHAR(1) = 'N',
	@BatchId INT = NULL OUTPUT -- Return the Batch Id as output
AS

BEGIN

	/* 
	  Batch Registration.
	*/
	BEGIN TRY
		INSERT INTO [omd].[BATCH] (BATCH_CODE, BATCH_DESCRIPTION, FREQUENCY_CODE, INACTIVE_INDICATOR)
		SELECT *
		FROM 
		(
		  VALUES (@BatchCode, @BatchDescription, @BatchFrequency, @BatchInactiveIndicator)
		) AS refData( BATCH_CODE, BATCH_DESCRIPTION, FREQUENCY_CODE, INACTIVE_INDICATOR)
		WHERE NOT EXISTS 
		(
		  SELECT NULL
		  FROM [omd].BATCH batch
		  WHERE batch.BATCH_CODE = refData.BATCH_CODE
		);
	END TRY
	BEGIN CATCH
		THROW
	END CATCH

	SET @BatchId = SCOPE_IDENTITY();

	IF @Debug = 'Y'
	BEGIN 
		IF @BatchId IS NOT NULL
			PRINT 'A new Batch Id '+CONVERT(VARCHAR(10),@BatchId)+' has been created for Batch Code: '+@BatchCode+'''.';
		ELSE
			BEGIN
				SELECT @BatchId = BATCH_ID FROM [omd].[BATCH] WHERE BATCH_CODE = @BatchCode;
				PRINT 'The Batch '''+@BatchCode+''' already exists in [omd].[BATCH] with Batch Id '''+CONVERT(VARCHAR(10),@BatchId)+'''.';
				PRINT 'SELECT * FROM [omd].[BATCH] where [BATCH_CODE] = '''+@BatchCode+'''.';
			END
	END
END