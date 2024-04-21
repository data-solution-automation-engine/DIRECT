CREATE OR ALTER PROCEDURE [omd].[CreateLoadWindow]
  @ModuleInstanceId INT, -- The currently running Module Instance Id
  @LoadWindowParameter VARCHAR(10) = 'DATETIME', -- Can be datetime or identifier, datetime being the default
  @LoadWindowAttributeName VARCHAR(255) = 'INSCRIPTION_TIMESTAMP', -- Name of the attribute used to determine the load window
  @Debug CHAR(1) = 'N',
  @LoadWindowStartDateTime DATETIME2(7) = NULL OUTPUT,
  @LoadWindowEndDateTime DATETIME2(7) = NULL OUTPUT,
  @LoadWindowStartIdentifier NUMERIC(10) = NULL OUTPUT,
  @LoadWindowEndIdentifier NUMERIC(10) = NULL OUTPUT
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
		@LoadWindowStartDateTime datetime2(7),
		@LoadWindowEndDateTime datetime2(7)

  EXEC	[omd].[CreateLoadWindow]
		@ModuleInstanceId = '',
		@LoadWindowParameter = 'DATETTIME',
		@LoadWindowAttributeName = 'LOAD_DATETIME',
		@Debug = N'Y',
		@LoadWindowStartDateTime = @LoadWindowStartDateTime OUTPUT,
		@LoadWindowEndDateTime = @LoadWindowEndDateTime OUTPUT

  SELECT 
        @LoadWindowStartDateTime as N'@LoadWindowStartDateTime',
		@LoadWindowEndDateTime as N'@LoadWindowEndDateTime'
*/

  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;

  -- Local variables (Module Id and source Data Object)
  DECLARE @ModuleId BIGINT = [omd].[GetModuleIdByModuleInstanceId](@ModuleInstanceId);

  -- Exception handling
  -- The Module Id cannot be NULL
  IF @ModuleId IS NULL
      BEGIN
        SET @EventDetail = 'The Module Id was not found for Module Instance Id '''+CONVERT(VARCHAR(10),@ModuleInstanceId)+'''';
        EXEC [omd].[InsertIntoEventLog]
  	      @EventDetail = @EventDetail;

        THROW 50000,@EventDetail,1;
      END

    -- Debug spooling only.
    IF @Debug = 'Y'
        BEGIN
          PRINT 'For Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' the Load Window Parameter is '+@LoadWindowParameter+'.';
	    END

  -- Exception handling
  IF @LoadWindowParameter NOT IN ('DATETIME', 'IDENTIFIER')
      BEGIN
        SET @EventDetail = 'Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' was called using Load Window Paramter '+@LoadWindowParameter+' but only ''DATETIME'' or ''IDENTIFIER'' are allowed options.';
        EXEC [omd].[InsertIntoEventLog]
	        @ModuleInstanceId = @ModuleInstanceId,
  	        @EventDetail = @EventDetail;

	    THROW 50000,@EventDetail,1;
       END

  IF @LoadWindowParameter IN ('IDENTIFIER') AND @LoadWindowAttributeName = 'N/A'
    BEGIN
	  SET @EventDetail = 'Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' was called using Load Window Paramter '+@LoadWindowParameter+' but does not have an attribute specified.';
      EXEC [omd].[InsertIntoEventLog]
	    @ModuleInstanceId = @ModuleInstanceId,
  	    @EventDetail = @EventDetail;

	  THROW 50000,@EventDetail,1;
    END

  DECLARE @SourceDataObject VARCHAR(255); 
  SELECT @SourceDataObject = DATA_OBJECT_SOURCE FROM omd.MODULE WHERE MODULE_ID = @ModuleId; 

  IF @Debug = 'Y'
    BEGIN
      PRINT 'For Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' the following Module Id was found in omd.MODULE: '+CONVERT(VARCHAR(10),@ModuleId)+'.';
	  PRINT 'For Module Id '+CONVERT(VARCHAR(10),@ModuleId)+' the Source Data Object is '+@SourceDataObject+'.';
	END

  DECLARE @PreviousModuleInstanceOutcome VARCHAR(MAX);
  DECLARE @SqlStatement VARCHAR(MAX);

  -- Exception handling
  IF @ModuleId = NULL OR @ModuleId = 0 
    THROW 50000,'The Module Id could not be retrieved based on the Module Instance Id.',1

  --SELECT @PreviousModuleInstanceOutcome =
  --    COALESCE 
  --    (
  --      (
		-- SELECT TOP 1
  --        NEXT_RUN_INDICATOR
  --       FROM omd.MODULE_INSTANCE main
  --       WHERE
  --           main.MODULE_ID = @ModuleId
  --       AND main.MODULE_INSTANCE_ID != @ModuleInstanceId
  --       ORDER BY main.MODULE_INSTANCE_ID DESC
	 --   )
  --     , 'S') -- If there is no Module Instance Id, the process will resolve to succeeded.

  -- NOTE 2020-10-20, removed check for previous failed instances to set loadwindow as the loadwindow is removed upon rerunning a failed
  -- This is part of the rollback process in Module Evaluation.

  IF @Debug = 'Y'
      PRINT 'The previous Module Instance Id was evaluated as: '+@PreviousModuleInstanceOutcome+'.';

  -- If the most recent run prior to the active Instance Id (now) is not failed, continue.
  --IF @PreviousModuleInstanceOutcome = 'R'
  --  BEGIN
  --    IF @Debug = 'Y'
  --      PRINT 'The previous Module Instance was a failure, so no new load window is set until this is resolved - end of procedure.';
	 -- GOTO EndOfProcedure
  --  END
  --ELSE
  BEGIN
    BEGIN TRY
    
      DECLARE @LoadWindowEndDateTimeSql VARCHAR(MAX);
	  IF @LoadWindowParameter = 'DATETIME'
          BEGIN

            IF @LoadWindowEndDateTime IS NOT NULL
                BEGIN
                    IF @Debug='Y'
                        BEGIN
                            PRINT 'A load window end parameter was provided: '+CONVERT(VARCHAR(100),@LoadWindowEndDateTime);
                        END
                    
                    SET @LoadWindowEndDateTimeSql = ''''+CONVERT(VARCHAR(100),@LoadWindowEndDateTime)+'''';

                END
            ELSE
                BEGIN
                    IF @Debug='Y'
                        BEGIN
                            PRINT 'No load window end parameter was provided, so the maximum date will be retrieved from the source data object.';
                        END

                    SET @LoadWindowEndDateTimeSql = 
                        'SELECT COALESCE(MAX('+@LoadWindowAttributeName+'),''1900-01-01'') FROM '+@SourceDataObject+' sdo
JOIN omd.MODULE_INSTANCE modinst ON sdo.omd_module_instance_id = modinst.MODULE_INSTANCE_ID
WHERE modinst.EXECUTION_STATUS_CODE=''S''';
                END

	        SET @SqlStatement = '
          INSERT INTO omd.[SOURCE_CONTROL]
          (
             [MODULE_INSTANCE_ID]
            ,[INSERT_DATETIME]
            ,[INTERVAL_START_DATETIME]
            ,[INTERVAL_END_DATETIME]
            ,[INTERVAL_START_IDENTIFIER]
            ,[INTERVAL_END_IDENTIFIER]
          )
          VALUES
          (
             '+CONVERT(VARCHAR(10),@ModuleInstanceId)+'
            ,SYSDATETIME()
            ,(  
               SELECT CONVERT(varchar,ISNULL(MAX(INTERVAL_END_DATETIME),''1900-01-01''),121) AS INTERVAL_START_DATETIME
               FROM omd.SOURCE_CONTROL A
               JOIN omd.MODULE_INSTANCE B ON (A.MODULE_INSTANCE_ID = B.MODULE_INSTANCE_ID)
               WHERE B.MODULE_ID = '+CONVERT(VARCHAR(10),@ModuleId)+'
             ) -- Maps to INTERVAL_START_DATETIME which is the last datetime of the previous window.
           , (
               '+@LoadWindowEndDateTimeSql+'
             ) -- Maps to INTERVAL_END_DATETIME
           ,NULL --INTERVAL_START_IDENTIFIER
           ,NULL --INTERVAL_END_IDENTIFIER
          )'
          END

	  IF @LoadWindowParameter = 'IDENTIFIER'
          BEGIN
	        SET @SqlStatement = '
          INSERT INTO omd.[SOURCE_CONTROL]
          (
             [MODULE_INSTANCE_ID]
            ,[INSERT_DATETIME]
            ,[INTERVAL_START_DATETIME]
            ,[INTERVAL_END_DATETIME]
            ,[INTERVAL_START_IDENTIFIER]
            ,[INTERVAL_END_IDENTIFIER]
          )
          VALUES
          (
            '+CONVERT(VARCHAR(10),@ModuleInstanceId)+'
           ,SYSDATETIME()
           ,NULL --INTERVAL_START_DATETIME
           ,NULL --INTERVAL_END_DATETIME
	       ,(  
               SELECT ISNULL(MAX(INTERVAL_END_IDENTIFIER),''0'') AS INTERVAL_END_IDENTIFIER
               FROM omd.SOURCE_CONTROL A
               JOIN omd.MODULE_INSTANCE B ON (A.MODULE_INSTANCE_ID = B.MODULE_INSTANCE_ID)
               WHERE B.MODULE_ID = '+CONVERT(VARCHAR(10),@ModuleId)+'
             ) -- Maps to INTERVAL_START_IDENTIFIER
           , (
               SELECT COALESCE(MAX('+@LoadWindowAttributeName+'),''0'')
               FROM '+@SourceDataObject+' sdo
               --JOIN omd.MODULE_INSTANCE modinst ON sdo.omd_module_instance_id = modinst.MODULE_INSTANCE_ID
               --WHERE modinst.EXECUTION_STATUS_CODE=''S''
             ) -- Maps to INTERVAL_END_IDENTIFIER
          )'
          END

      IF @Debug='Y'
        PRINT 'Load Window SQL statement is: '+@SqlStatement;
      
      EXEC (@SqlStatement);
    
	  -- Retrieve values for return.
	  IF @LoadWindowParameter = 'DATETIME'
	    BEGIN
	      SELECT @LoadWindowStartDateTime = [omd].[GetModuleLoadWindowDateTime](@ModuleId,1);
	      SELECT @LoadWindowEndDateTime = [omd].[GetModuleLoadWindowDateTime](@ModuleId,2);
		END

	  IF @LoadWindowParameter = 'IDENTIFIER'
	    BEGIN
	      SELECT @LoadWindowStartIdentifier = [omd].[GetModuleLoadWindowIdentifier](@ModuleId,1);
	      SELECT @LoadWindowEndIdentifier = [omd].[GetModuleLoadWindowIdentifier](@ModuleId,2);
		END

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
  END

    EndOfProcedure:
   -- End label
END
