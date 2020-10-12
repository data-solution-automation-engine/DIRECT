/*
Process: Create Module Instance
Input: 
  - Module Code
  - Batch Instance Id
  - Execution runtime Is (e.g. GUID, SPID)
  - Debug flag Y/N
Returns:
  - Module Instance Id
Usage:
    DECLARE @ModuleInstanceId INT
    EXEC [omd].[CreateModuleInstance]
      @ModuleCode = N'<Module Code / Name>',
      @ModuleInstanceId = @ModuleInstanceId OUTPUT;
    PRINT @ModuleInstanceId;
*/

CREATE PROCEDURE [omd].[CreateModuleInstance]
	@ModuleCode VARCHAR(255), -- The name of the Module, as identified in the MODULE_CODE attribute in the MODULE table.
	@Debug VARCHAR(1) = 'N',
	@ExecutionRuntimeId VARCHAR(255) = 'N/A',
	@BatchInstanceId INT = 0, -- The Batch Instance Id, if the Module is run from a Batch.
	@ModuleInstanceId INT = NULL OUTPUT
AS
BEGIN

  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;

  DECLARE @ModuleId INT;
  SELECT @ModuleId = omd.GetModuleIdByName(@ModuleCode);

  -- Exception handling
  -- The Module Id cannot be NULL
  IF @ModuleId IS NULL
  BEGIN
    SET @EventDetail = 'The Module Id was not found for Module Code '''+@ModuleCode+'''';  
    EXEC [omd].[InsertIntoEventLog]
  	  @EventDetail = @EventDetail;
  END

  IF @Debug = 'Y'
    PRINT 'For Module Code '+@ModuleCode+' the following Module Id was found in omd.MODULE: '+CONVERT(VARCHAR(10),@ModuleId);

  BEGIN TRY
    INSERT INTO omd.MODULE_INSTANCE 
    (
      MODULE_ID, 
      START_DATETIME, 
      EXECUTION_STATUS_CODE, 
      NEXT_RUN_INDICATOR, 
      PROCESSING_INDICATOR, 
      BATCH_INSTANCE_ID, 
      MODULE_EXECUTION_SYSTEM_ID, 
      ROWS_INPUT, 
      ROWS_INSERTED, 
      ROWS_UPDATED, 
      ROWS_DELETED, 
      ROWS_DISCARDED,
      ROWS_REJECTED
    ) 
    VALUES
    (
      @ModuleId,			-- Module ID
      SYSDATETIME(), -- Start Datetime
      'E',					-- Execution Status Code
      'P',					-- Next Run Indicator
      'A',					-- Processing Indicator
      @BatchInstanceId,		-- Batch Instance Id
      @ExecutionRuntimeId,  -- Module Execution System Id 
      0,
      0,
      0,
      0,
      0,
      0
    );

	SET @ModuleInstanceId = SCOPE_IDENTITY();

	IF @Debug = 'Y'
      PRINT 'A new Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' has been created for Module Code: '+@ModuleCode;

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