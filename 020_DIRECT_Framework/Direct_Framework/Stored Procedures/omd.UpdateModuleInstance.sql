/*
Process: Update Module Instance status
Purpose: Sets the various Module Instance status codes based on input events.
Input: 
  - Module Instance Id
  - Event Code (Process, Abort, Cancel, Rollback, Success or Failure)
  - Debug flag Y/N (default to N)
Returns:
  - Default Stored Procudure return code (no specific output)
Usage:
   EXEC [omd].[UpdateModuleInstance]
      @ModuleInstanceId = <>,
	  @EventCode = '<>'
*/

CREATE PROCEDURE [omd].[UpdateModuleInstance]
	@ModuleInstanceId INT,
	@EventCode VARCHAR(10) = 'None',
	@RowCountSelect INT  = 0,
	@RowCountInsert INT  = 0,
	@Debug VARCHAR(1) = 'Y'
AS

BEGIN	
	-- Abort event
	-- This is an end-state event (no further processing)
  IF @EventCode = 'Abort'
  BEGIN
	BEGIN TRY
	  IF @Debug='Y'
	    PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+'.';

	  UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'A', PROCESSING_INDICATOR = 'A', NEXT_RUN_INDICATOR = 'P', END_DATETIME = SYSDATETIME() WHERE MODULE_INSTANCE_ID = @ModuleInstanceId
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
	      PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'C', PROCESSING_INDICATOR = 'C', NEXT_RUN_INDICATOR = 'P', END_DATETIME = SYSDATETIME() WHERE MODULE_INSTANCE_ID = @ModuleInstanceId
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
	      PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+' and row count '+CONVERT(VARCHAR(10),@RowCountInsert)+'.';

		UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'S', NEXT_RUN_INDICATOR = 'P', END_DATETIME=GETDATE(), ROWS_INPUT = @RowCountSelect, ROWS_INSERTED = @RowCountInsert WHERE  MODULE_INSTANCE_ID = @ModuleInstanceId
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
	      PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'F', NEXT_RUN_INDICATOR = 'R', END_DATETIME=GETDATE() WHERE  MODULE_INSTANCE_ID = @ModuleInstanceId
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
	      PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.MODULE_INSTANCE set PROCESSING_INDICATOR = 'R' WHERE MODULE_INSTANCE_ID = @ModuleInstanceId
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
	      PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.MODULE_INSTANCE set PROCESSING_INDICATOR = 'P' WHERE MODULE_INSTANCE_ID = @ModuleInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Exception handling
  IF @EventCode NOT IN ('Proceed', 'Cancel', 'Abort', 'Rollback', 'Success', 'Failure')
    THROW 50000,'Incorrect Event Code specified. The available options are Proceed, Cancel, Abort, Success, Failure and Rollback',1

END