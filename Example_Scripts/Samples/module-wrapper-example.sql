/*
  This example combines the registration for a Module in DIRECT with the
  execution of sample code.
*/

/*
  Parameters.
*/

DECLARE @Reset CHAR(1) = 'N';
DECLARE @Debug CHAR(1) = 'Y';
DECLARE @ModuleId BIGINT;

/*
  Module Registration.
  This is often a separate, independent step.
*/



EXEC [omd].[RegisterModule]
  @ModuleCode = 'MyNewModule',
  @ModuleAreaCode = 'MAINT',
  @Executable = 'SELECT SYSUTCDATETIME()',
  -- Optional parameters
  @ModuleDescription = 'Data logistics Example',
  @Debug = 'Y',
  -- Output parameters
  @ModuleId = @ModuleId OUTPUT;

PRINT 'The new Modules Id is: ''' + CONVERT(NVARCHAR(10), @ModuleId) + '''.';

/*
  Execute the newly created Module.
*/

EXEC [omd].[RunModule]
  @ModuleCode = 'MyNewModule',
  @Debug = 'Y'
 ;

/*
  Reset block, for debugging and testing purposes.
*/

IF @Reset = 'Y'
  BEGIN TRY
    BEGIN
      DELETE FROM [Direct_Framework].[omd].[EVENT_LOG] WHERE MODULE_INSTANCE_ID IN (SELECT MODULE_INSTANCE_ID FROM [Direct_Framework].[omd].[MODULE_INSTANCE] WHERE MODULE_ID = @ModuleId)
      DELETE FROM [Direct_Framework].[omd].[SOURCE_CONTROL] WHERE MODULE_INSTANCE_ID IN (SELECT MODULE_INSTANCE_ID FROM [Direct_Framework].[omd].[MODULE_INSTANCE] WHERE MODULE_ID = @ModuleId)
      DELETE FROM [Direct_Framework].[omd].[MODULE_INSTANCE] WHERE MODULE_ID = @ModuleId
      DELETE FROM [Direct_Framework].[omd].[BATCH_MODULE] WHERE MODULE_ID = @ModuleId
      DELETE FROM [Direct_Framework].[omd].[MODULE] WHERE MODULE_ID = @ModuleId
    END
  END TRY

  BEGIN CATCH
    THROW
  END CATCH

/* Control block for reviewing the tests
SELECT * FROM omd.MODULE
SELECT * FROM omd.MODULE_INSTANCE
SELECT * FROM omd.MODULE_INSTANCE_EXECUTED_CODE
*/
