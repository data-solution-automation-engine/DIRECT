/*
Process: Run Module
Purpose: Executes an ETL process / query in a DIRECT wrapper.
Input: 
  - Module Code
  - Query (statement to execute)
  - Debug flag Y/N (default to N)
Returns:
  - Process result (success, failure)
Usage:
    DECLARE @QueryResult VARCHAR(10);
    EXEC [omd].[RunModule]
      @ModuleCode = '<>',
	  @Query = '<>'
      @QueryResult = @QueryResult OUTPUT;
    PRINT @QueryResult;

	or

    EXEC [omd].[RunModule]
      @ModuleCode = '<>',
	  @Query = '<>';
*/

CREATE PROCEDURE omd.RunModule
	-- Add the parameters for the stored procedure here
	@ModuleCode VARCHAR(255),
	@Query VARCHAR(MAX),
    @BatchInstanceId INT = 0, -- The Batch Instance Id, if the Module is run from a Batch.
	@Debug VARCHAR(1) = 'N',
	@QueryResult VARCHAR(10) = NULL OUTPUT
AS
BEGIN

  -- Create Module Instance
  DECLARE @ModuleInstanceId INT
  EXEC [omd].[CreateModuleInstance]
    @ModuleCode = @ModuleCode,
    @Debug = @Debug,
    @BatchInstanceId = @BatchInstanceId, -- The Batch Instance Id, if the Module is run from a Batch.
    @ModuleInstanceId = @ModuleInstanceId OUTPUT;
  
  -- Module Evaluation
  DECLARE @ProcessIndicator VARCHAR(10);
  EXEC [omd].[ModuleEvaluation]
    @ModuleInstanceId = @ModuleInstanceId,
    @Debug = @Debug,
    @ProcessIndicator = @ProcessIndicator OUTPUT;

    IF @Debug = 'Y'
      PRINT @ProcessIndicator;
  
  IF @ProcessIndicator NOT IN ('Abort','Cancel') -- These are end-states for the process.
    BEGIN TRY
      /*
	    Main ETL block
	  */

      EXEC(@Query);

      IF @Debug = 'Y'
        PRINT 'Success pathway';

      -- Module Success
      EXEC [omd].[UpdateModuleInstance]
        @ModuleInstanceId = @ModuleInstanceId,
        @Debug = @Debug,
        @EventCode = 'Success'

	  SET @QueryResult = 'Success';

   END TRY
    BEGIN CATCH
      IF @Debug = 'Y'
        PRINT 'Failure pathway';

      -- Module Failure
      EXEC [omd].[UpdateModuleInstance]
        @ModuleInstanceId = @ModuleInstanceId,
        @Debug = @Debug,
        @EventCode = 'Failure';
	  
	  SET @QueryResult = 'Failure';

	   -- Logging
	   DECLARE @EventDetail VARCHAR(4000) = ERROR_MESSAGE(),
               @EventReturnCode int = ERROR_NUMBER();

	  EXEC [omd].[InsertIntoEventLog]
	    @ModuleInstanceId = @ModuleInstanceId,
		@EventDetail = @EventDetail,
		@EventReturnCode = @EventReturnCode;

	  THROW
    END CATCH
  ELSE
    SET @QueryResult = @ProcessIndicator;

END