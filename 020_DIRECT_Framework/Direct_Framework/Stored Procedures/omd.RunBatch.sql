
/*
Process: Run Batch
Purpose: Executes an ETL process / query in a DIRECT wrapper.
Input: 
  - Batch Code
  - Query (statement to execute)
  - Debug flag Y/N (default to N)
Returns:
  - Process result (success, failure)
Usage:
    DECLARE @Result VARCHAR(10);
    EXEC [omd].[RunBatch]
      @BatchCode = '<>',
      @Result = @Result OUTPUT;
    PRINT @Result;

	or

    EXEC [omd].[RunBatch]
      @BatchCode = '<>',
*/

CREATE PROCEDURE [omd].[RunBatch]
	-- Add the parameters for the stored procedure here
	@BatchCode VARCHAR(255),
	@Debug VARCHAR(1) = 'N',
	@Result VARCHAR(10) = NULL OUTPUT
AS
BEGIN

  -- Create Batch Instance
  DECLARE @BatchInstanceId INT
  EXEC [omd].[CreateBatchInstance]
    @BatchCode = @BatchCode,
    @Debug = @Debug,
    @BatchInstanceId = @BatchInstanceId OUTPUT;
  
  -- Batch Evaluation
  DECLARE @ProcessIndicator VARCHAR(10);
  EXEC [omd].[BatchEvaluation]
    @BatchInstanceId = @BatchInstanceId,
    @Debug = @Debug,
    @ProcessIndicator = @ProcessIndicator OUTPUT;

    IF @Debug = 'Y'
      PRINT @ProcessIndicator;
  
  IF @ProcessIndicator NOT IN ('Abort','Cancel') -- These are end-states for the process.
    BEGIN TRY

      /*
	    Main block, to run Modules in e.g.

       -- Module 1
	   DECLARE @QueryResult VARCHAR(10);
       EXEC [omd].[RunModule]
         @ModuleCode = '',
	     @Query = '',
         @BatchInstanceId = @BatchInstanceId,
		 @Debug = @Debug,
         @QueryResult = @QueryResult OUTPUT;
       PRINT @QueryResult;

	  */

	  -- End of Module Execution

      IF @Debug = 'Y'
        PRINT 'Success pathway';

      -- Batch Success
      EXEC [omd].[UpdateBatchInstance]
        @BatchInstanceId = @BatchInstanceId,
        @Debug = @Debug,
        @EventCode = 'Success'

	  SET @Result = 'Success';

   END TRY
    BEGIN CATCH
      IF @Debug = 'Y'
        PRINT 'Failure pathway';

      -- Batch Failure
      EXEC [omd].[UpdateBatchInstance]
        @BatchInstanceId = @BatchInstanceId,
        @Debug = @Debug,
        @EventCode = 'Failure';
	  
	  SET @Result = 'Failure';
	  THROW
    END CATCH
  ELSE
    SET @Result = @ProcessIndicator;

END