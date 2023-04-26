--CREATE PROCEDURE [omd].[END_DATING]
--  @DataObjectName VARCHAR(MAX)
-- ,@DataObjectSchema VARCHAR(MAX)
-- ,@KeyArray VARCHAR(MAX) = NULL
-- ,@ModuleInstanceId INT = 0
-- ,@CurrentRecordIndicatorColumnName VARCHAR(50) = 'CURRENT_RECORD_INDICATOR'
-- ,@InscriptionRecordIdColumnName VARCHAR(50) = 'INSCRIPTION_RECORD_ID'
-- ,@ExpiryDateColumnName VARCHAR(50) = 'INSCRIPTION_TIMESTAMP'
-- ,@EffectiveDateColumnName VARCHAR(50) = 'INSCRIPTION_BEFORE_TIMESTAMP'
--AS

--NOT FINISHED YET

DECLARE
  @DataObjectName VARCHAR(MAX) = 'PSA_PROFILER_CUSTOMER_PERSONAL'
 ,@DataObjectSchema VARCHAR(MAX) = 'dbo'
 ,@KeyArray VARCHAR(MAX) = 'CustomerId, Yolo'
 ,@ModuleInstanceId INT = 0
 ,@CurrentRecordIndicatorColumnName VARCHAR(50) = 'CURRENT_RECORD_INDICATOR'
 ,@InscriptionRecordIdColumnName VARCHAR(50) = 'INSCRIPTION_RECORD_ID'
 ,@EffectiveDateColumnName VARCHAR(50) = 'INSCRIPTION_TIMESTAMP'
 ,@ExpiryDateColumnName VARCHAR(50) = 'INSCRIPTION_BEFORE_TIMESTAMP'
 ,@DirectUpdateModuleInstanceIdColumnName VARCHAR(50) = 'MODULE_INSTANCE_UPDATE_ID'

-- The resulting query
DECLARE @Query AS VARCHAR(MAX);

-- Management of (composite) key(s)
DECLARE @IndividualKey VARCHAR(MAX) = '';
DECLARE @KeySelectStatement VARCHAR(MAX) = '';

BEGIN
	DECLARE db_cursor CURSOR FOR 
	SELECT VALUE FROM STRING_SPLIT(@KeyArray, ',')

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @IndividualKey  

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
	    SET @IndividualKey = TRIM(@IndividualKey);

		SET @KeySelectStatement = @KeySelectStatement+@IndividualKey+','

		FETCH NEXT FROM db_cursor INTO @IndividualKey  
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor

	SET @Query =
N'UPDATE main
SET 
 main.'+@CurrentRecordIndicatorColumnName+' = ''N''
FROM '+@DataObjectSchema+'.'+@DataObjectName+' main
WHERE NOT EXISTS
(
	/* Find all the records where they are not the most recent, but still have current_record_indicator=''Y'' */
	SELECT 
	   sub.'+@KeySelectStatement+'
	  ,sub.'+@EffectiveDateColumnName+'
	FROM '+@DataObjectSchema+'.'+@DataObjectName+' sub
	JOIN 
	(
	SELECT CustomerId, MAX('+@EffectiveDateColumnName+') AS MAX_'+@EffectiveDateColumnName+' 
	FROM '+@DataObjectSchema+'.'+@DataObjectName+'
	GROUP BY CustomerId
	) maxsub ON sub.CustomerId=maxsub.CustomerId 
			AND sub.'+@EffectiveDateColumnName+'!=maxsub.MAX_'+@EffectiveDateColumnName+'
	WHERE '+@CurrentRecordIndicatorColumnName+'=''Y''
)'

	PRINT @Query
	--EXECUTE sp_executesql  @Query  

	/*Example

	UPDATE main
	SET main.CURRENT_RECORD_INDICATOR='N'
	FROM [dbo].[PSA_PROFILER_CUSTOMER_PERSONAL] main
	WHERE NOT EXISTS
	(
		/* Find all the records where they are not the most recent, but still have current_record_indicator='Y' */
		SELECT sub.CustomerId, sub.INSCRIPTION_TIMESTAMP
		FROM [dbo].[PSA_PROFILER_CUSTOMER_PERSONAL] sub
		JOIN 
		(
		SELECT CustomerId, MAX(INSCRIPTION_TIMESTAMP) AS MAX_TIMESTAMP 
		FROM [dbo].[PSA_PROFILER_CUSTOMER_PERSONAL]
		GROUP BY CustomerId
		) maxsub ON sub.CustomerId=maxsub.CustomerId 
				AND sub.INSCRIPTION_TIMESTAMP!=maxsub.MAX_TIMESTAMP
		WHERE CURRENT_RECORD_INDICATOR='Y'
	)
	*/

END





