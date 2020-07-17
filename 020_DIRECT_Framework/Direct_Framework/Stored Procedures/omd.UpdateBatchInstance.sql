
/*
Process: Update Batch Instance status
Purpose: Sets the various Batch Instance status codes based on input events.
Input: 
  - Batch Instance Id
  - Event Code (Process, Abort, Cancel, Rollback, Success or Failure)
  - Debug flag Y/N (default to N)
Returns:
  - Default Stored Procudure return code (no specific output)
Usage:
   EXEC [omd].[UpdateBatchInstance]
      @BatchInstanceId = <>,
	  @EventCode = '<>'
*/

CREATE PROCEDURE [omd].[UpdateBatchInstance]
	@BatchInstanceId INT,
	@EventCode VARCHAR(10) = 'None',
	@Debug VARCHAR(1) = 'Y'
AS

BEGIN	
	-- Abort event
	-- This is an end-state event (no further processing)
  IF @EventCode = 'Abort'
  BEGIN
	BEGIN TRY
	  IF @Debug='Y'
	    PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

	  UPDATE omd.BATCH_INSTANCE SET EXECUTION_STATUS_CODE = 'A', PROCESSING_INDICATOR = 'A', NEXT_RUN_INDICATOR = 'P', END_DATETIME = SYSDATETIME() WHERE BATCH_INSTANCE_ID = @BatchInstanceId
	END TRY
	BEGIN CATCH
	  THROW
	END CATCH
  END

  -- Skip / Cancel event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Cancel'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.BATCH_INSTANCE SET EXECUTION_STATUS_CODE = 'C', PROCESSING_INDICATOR = 'C', NEXT_RUN_INDICATOR = 'P', END_DATETIME = SYSDATETIME() WHERE BATCH_INSTANCE_ID = @BatchInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Success event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Success'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.BATCH_INSTANCE SET EXECUTION_STATUS_CODE = 'S', NEXT_RUN_INDICATOR = 'P', END_DATETIME=GETDATE() WHERE  BATCH_INSTANCE_ID = @BatchInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Failure event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Failure'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

        -- Note that the default behaviour is that Next Run Indicator at Batch level is 'P'.
		-- This will only skip/cancel already succesfully completed Modules when a failed Batch is rerun.
		UPDATE omd.BATCH_INSTANCE SET EXECUTION_STATUS_CODE = 'F', NEXT_RUN_INDICATOR = 'P', END_DATETIME=GETDATE() WHERE  BATCH_INSTANCE_ID = @BatchInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Rollback event
  IF @EventCode = 'Rollback'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.BATCH_INSTANCE SET PROCESSING_INDICATOR = 'R' WHERE BATCH_INSTANCE_ID = @BatchInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Proceed event
  IF @EventCode = 'Proceed'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.BATCH_INSTANCE SET PROCESSING_INDICATOR = 'P' WHERE BATCH_INSTANCE_ID = @BatchInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Exception handling
  IF @EventCode NOT IN ('Proceed', 'Cancel', 'Abort', 'Rollback', 'Success', 'Failure')
    THROW 50000,'Incorrect Event Code specified. The available options are Proceed, Cancel, Abort, Success, Failure and Rollback',1

END