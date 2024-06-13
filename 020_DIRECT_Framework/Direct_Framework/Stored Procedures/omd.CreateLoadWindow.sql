CREATE PROCEDURE [omd].[CreateLoadWindow]
  @ModuleInstanceId INT, -- The currently involved Module Instance Id
  @LoadWindowAttributeName VARCHAR(255) = 'INSCRIPTION_TIMESTAMP', -- Name of the attribute used to determine the load window
  @ModuleInstanceIdColumnName VARCHAR(255) = 'MODULE_INSTANCE_ID',
  @Debug CHAR(1) = 'N',
  @StartValue VARCHAR(MAX) = NULL OUTPUT, -- Can be datetime or identifier, datetime, whatever...
  @EndValue VARCHAR(MAX) = NULL OUTPUT
AS
BEGIN

/*
Process: Create Load Window
Input: 
  - Module Instance Id
  - Load Window Paramter (datetime or identifier)
  - Debug flag Y/N
Returns:
  - Load Window Start Date/Time or Identifier
  - Load Window End Date/Time or Identifier
Usage:
  DECLARE
		@StartValue datetime2(7),
		@EndValue datetime2(7)

  EXEC	[omd].[CreateLoadWindow]
		@ModuleInstanceId = '',
		@Debug = N'Y',
		@StartValue = @StartValue OUTPUT,
		@EndValue = @EndValue OUTPUT

  SELECT 
		@StartValue as N'@StartValue',
		@EndValue as N'@EndValue'
*/

  IF @Debug = 'Y'
	BEGIN
	  PRINT 'Start of the Create Load Window process (omd.CreateLoadWindow).'
	END

  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;

  -- Local variables (Module Id and source Data Object)
  DECLARE @ModuleId BIGINT = [omd].[GetModuleIdByModuleInstanceId](@ModuleInstanceId);

  -- Exception handling
  IF @ModuleId IS NULL
	-- The Module Id cannot be NULL
	BEGIN
	  SET @EventDetail = 'The Module Id was not found for Module Instance Id '''+CONVERT(VARCHAR(10),@ModuleInstanceId)+'''';
	  EXEC [omd].[InsertIntoEventLog] @EventDetail = @EventDetail;

	  THROW 50000,@EventDetail,1;
	END

  -- Figure out what the source is.
  DECLARE @SourceDataObject VARCHAR(255); 
  SELECT @SourceDataObject = DATA_OBJECT_SOURCE FROM omd.MODULE WHERE MODULE_ID = @ModuleId; 

  IF @Debug = 'Y'
	BEGIN
	  PRINT 'For Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' the following Module Id was found in omd.MODULE: '+CONVERT(VARCHAR(10),@ModuleId)+'.';
	  PRINT 'For Module Id '+CONVERT(VARCHAR(10),@ModuleId)+' the Source Data Object is '+@SourceDataObject+'.';
	END

  -- Exception handling
  IF @ModuleId = NULL OR @ModuleId = 0 
	THROW 50000,'The Module Id could not be retrieved based on the Module Instance Id.',1

  BEGIN TRY
	-- Parse the start value as input, or revert to default.
	DECLARE @StartValueSql VARCHAR(MAX);
	BEGIN
		IF @StartValue IS NOT NULL
			BEGIN
				IF @Debug='Y'
					BEGIN
						PRINT 'A load window start value was provided: '+CONVERT(VARCHAR(100),@StartValue);
					END
					
					SET @StartValueSql = ''''+CONVERT(VARCHAR(100),@StartValue)+'''';
			END
		ELSE
			BEGIN
				SET @StartValueSql = 
'SELECT
	MAX(END_VALUE) AS NEW_START_VALUE
FROM 
(
	SELECT 
	 ROW_NUMBER() OVER (PARTITION BY A.MODULE_ID ORDER BY INSERT_DATETIME DESC) AS RN
	,END_VALUE
	FROM omd.SOURCE_CONTROL A
	JOIN omd.MODULE_INSTANCE B ON (A.MODULE_INSTANCE_ID = B.MODULE_INSTANCE_ID)
	WHERE B.MODULE_ID = '+CONVERT(VARCHAR(10),@ModuleId)+'
	-- Default value
	UNION 
	SELECT 1,''1900-01-01''
) sub
WHERE RN=1';

				IF @Debug='Y'
					BEGIN
						PRINT 'No load window start value was provided, so the most recent value will be retrieved from the source control table for the source data object.';
						PRINT 'The following code will be used to determin the start value: '+CHAR(13)+@StartValueSql;
					END
			END
	END

	-- Parse the end value as input, or revert to default.
	DECLARE @EndValueSql VARCHAR(MAX);
	BEGIN
		IF @EndValue IS NOT NULL
			BEGIN
				IF @Debug='Y'
					BEGIN
						PRINT 'A load window end value was provided: '+CONVERT(VARCHAR(100),@EndValue);
					END
					
					SET @EndValueSql = ''''+CONVERT(VARCHAR(100),@EndValue)+'''';
			END
		ELSE
			BEGIN
				SET @EndValueSql = 
'SELECT COALESCE(MAX('+@LoadWindowAttributeName+'),''1900-01-01'') AS END_VALUE
FROM '+@SourceDataObject+' sdo
JOIN omd.MODULE_INSTANCE modinst ON sdo.'+@ModuleInstanceIdColumnName+' = modinst.MODULE_INSTANCE_ID
WHERE modinst.EXECUTION_STATUS_CODE=''S''';

				IF @Debug='Y'
					BEGIN
						PRINT 'No load window end value was provided, so the maximum date will be retrieved directly from the source data object.';
						PRINT 'The following code will be used to determin the end value: '+CHAR(13)+@EndValueSql;
					END
			END
	END
	
	DECLARE @SqlStatement VARCHAR(MAX);
	SET @SqlStatement = '
		  INSERT INTO omd.[SOURCE_CONTROL]
		  (
			 [MODULE_ID]
			,[MODULE_INSTANCE_ID]
			,[INSERT_DATETIME]
			,[START_VALUE]
			,[END_VALUE]
		  )
		  VALUES
		  (
			 '+CONVERT(VARCHAR(10),@ModuleId)+'
			,'+CONVERT(VARCHAR(10),@ModuleInstanceId)+'
			,SYSDATETIME()
			,(  
			   '+@StartValueSql+'
			 ) -- Interval Start Value
		   , (
			   '+@EndValueSql+'
			 ) -- Interval End Value
		  )'

	IF @Debug='Y'
	  PRINT 'Load Window SQL statement is: '+@SqlStatement;

	EXEC (@SqlStatement);
	
	-- Retrieve values for return.
	SELECT @StartValue = [omd].[GetModuleLoadWindowValue](@ModuleId,1);
	SELECT @EndValue = [omd].[GetModuleLoadWindowValue](@ModuleId,2);

  END TRY 
  BEGIN CATCH
	  -- Logging
	   SET @EventDetail = ERROR_MESSAGE();
	   SET @EventReturnCode = ERROR_NUMBER();
	   
	   EXEC [omd].[InsertIntoEventLog]
		 @ModuleInstanceId = @ModuleInstanceId,
		 @EventDetail = @EventDetail,
		 @EventReturnCode = @EventReturnCode;

	  THROW
  END CATCH

  EndOfProcedure:
  -- End label
END