/*
Process: Create Batch Instance
Input: 
  - Batch Code
  - Execution runtime Is (e.g. GUID, SPID)
  - Debug flag Y/N
Returns:
  - Batch Instance Id
Usage:
    DECLARE @BatchInstanceId INT
    EXEC [omd].[CreateBatchInstance]
      @BatchCode = N'<Batch Code / Name>',
      @BatchInstanceId = @BatchInstanceId OUTPUT;
    PRINT @BatchInstanceId;
*/

CREATE PROCEDURE [omd].[CreateBatchInstance]
	@BatchCode VARCHAR(255), -- The name of the Batch, as identified in the BATCH_CODE attribute in the BATCH table.
	@Debug VARCHAR(1) = 'N',
	@ExecutionRuntimeId VARCHAR(255) = 'N/A',
	@BatchInstanceId INT = NULL OUTPUT
AS
BEGIN

  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;

  DECLARE @BatchId INT;
  SELECT @BatchId = omd.GetBatchIdByName(@BatchCode);

  IF @Debug = 'Y'
    PRINT 'For Batch Code '+@BatchCode+' the following Batch Id was found in omd.BATCH: '+CONVERT(VARCHAR(10),@BatchId);

  BEGIN TRY

    INSERT INTO omd.BATCH_INSTANCE 
	(
      BATCH_ID,  
      START_DATETIME, 
      EXECUTION_STATUS_CODE, 
      NEXT_RUN_INDICATOR, 
      PROCESSING_INDICATOR,
      BATCH_EXECUTION_SYSTEM_ID
	)
    VALUES
	(
      @BatchId,
      SYSDATETIME(),        -- Start Datetime
      'E',					-- Execution Status Code
      'P',					-- Next Run Indicator
      'A',					-- Processing Indicator
      @ExecutionRuntimeId
    )
                

	SET @BatchInstanceId = SCOPE_IDENTITY();

	IF @Debug = 'Y'
      PRINT 'A new Batch Instance Id '+CONVERT(VARCHAR(10),@BatchInstanceId)+' has been created for Batch Code: '+@BatchCode;

  END TRY
  BEGIN CATCH

    -- Logging
	SET @EventDetail = ERROR_MESSAGE();
	SET @EventReturnCode = ERROR_NUMBER();
	   
	EXEC [omd].[InsertIntoEventLog]
	  @BatchInstanceId = @BatchInstanceId,
	  @EventDetail = @EventDetail,
	  @EventReturnCode = @EventReturnCode;

	THROW
  END CATCH
  
END