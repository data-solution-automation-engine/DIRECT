/*
Process: Create a new entry in the Event Log
Purpose: Inserts a log entry capturing failures or other noteworthy events.
Input: 
  - Module Instance Id
  - Event Details
  Optional:
  - Event Datetime (defaults to SYSDATETIME if not set)
  - Batch Instance Id
  - Event Type Code (1,2,3 etc. see omd.EVENT_TYPE table contents for options)
  - Error Return Code
  - Error Bitmap
  - Debug flag Y/N (default to N)
Returns:
  - Default Stored Procudure return code (no specific output)
Usage:
   EXEC [omd].[InsertIntoEventLog]
      @ModuleInstanceId = <>,
	  @EventCode = '<>'
*/

CREATE PROCEDURE [omd].[InsertIntoEventLog]
	@ModuleInstanceId INT = 0,
	@EventDetail VARCHAR(4000),
	@BatchInstanceId INT = 0,
	@EventDateTime DATETIME = NULL,
	@EventTypeCode VARCHAR(10) = '2',
	@EventReturnCode VARCHAR(1000) = 'N/A',
	@ErrorBitmap NUMERIC(20,0) = 0,
	@Debug VARCHAR(1) = 'Y'
AS

BEGIN

  -- Handling the Event Date Time
  IF @EventDateTime IS NULL
    SET @EventDateTime = SYSDATETIME();

  BEGIN
	BEGIN TRY
	  IF @Debug='Y'
	  BEGIN
	    PRINT 'Inserting record in Event Log for Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' with message '+@EventDetail+'.';
      END

	  INSERT INTO [omd].[EVENT_LOG]
      ( 
         [MODULE_INSTANCE_ID]
	    ,[BATCH_INSTANCE_ID]
        ,[EVENT_TYPE_CODE]
        ,[EVENT_DATETIME]
        ,[EVENT_RETURN_CODE_DETAILS]
        ,[EVENT_DETAIL]
        ,[ERROR_BITMAP]
	 )
     VALUES
     (
	   COALESCE(@ModuleInstanceId,0),
	   COALESCE(@BatchInstanceId,0),
	   @EventTypeCode,
	   @EventDateTime,
	   @EventReturnCode,
	   @EventDetail,
	   @ErrorBitmap
	)

	END TRY
	BEGIN CATCH
	  THROW
	END CATCH
  END

END