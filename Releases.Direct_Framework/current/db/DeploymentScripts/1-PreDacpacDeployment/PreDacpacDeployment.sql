/*******************************************************************************
 * Pre-Dacpac Deployment Script
 *******************************************************************************
 *
 * Used for migrations that need to be run before the dacpac is deployed
 * This script is executed by the pipeline before the call to deploy the dacpac
 * For non-Dacpac deployments/non-pipeline processes, this script can be run
 * manually, or as part of a separate deployment script
 * To allow easy execution of a dependency chain, this script should be
 * idempotent and use the database versioning to determine what steps to run
 * Currently it is a sqlcmd mode script that calls other scripts for each
 * required upgrade step
 * Version control in the metadata table tracks the current version of the
 * database, which is/should be used to determine which migration scripts to
 * run, if and when needed...
 ******************************************************************************/

 -- The DACPAC version/The current version of the code being deployed
 -- If a migration is required this should include the migration code from the
 -- previous version to this/the current version
DECLARE @CurrentVersion NVARCHAR(10) = '2.0.0.0'

-- placeholder contents...
PRINT 'Pre-Dacpac Deployment Script Starting'
PRINT 'Current Version: ' + @CurrentVersion

-- Check that we are connected to an existing database and can run queries
-- this should gracefully deal with deploying a new instance of the database
-- For a pipeline, this would possibly be a previous step that then decides to run this
-- A dacpac deployment can create a target database in Azure SQL db, but that
-- process is not the better option. Make sure to create the database in a more
-- controlled manner, and then deploy the dacpac to it.

-- Check if a main table exists, and assume it is initial deployment if not

IF NOT EXISTS (
  SELECT NULL
  FROM INFORMATION_SCHEMA.TABLES
  WHERE
    TABLE_SCHEMA = 'omd'
    AND TABLE_NAME = 'BATCH'
)
BEGIN
  PRINT '''[omd].[BATCH]'' table does not exist, script assumes this is an initial deploy'
  PRINT 'Skipping script execution'

  GOTO EndOfProcedure
END

PRINT '''[omd].[BATCH]'' table exists, script assumes this is an incremental deploy'

-- Check that the version function is available
IF EXISTS (
  SELECT NULL
  FROM INFORMATION_SCHEMA.ROUTINES
  WHERE
    SPECIFIC_SCHEMA = 'omd_metadata'
    AND SPECIFIC_NAME = 'GetFrameworkVersion'
    AND ROUTINE_TYPE = 'FUNCTION'
)
BEGIN

  PRINT '''[omd_metadata].[GetFrameworkVersion]'' function exists, script assumes this is an incremental deploy on v2+'

  -- If all is ok, get the current version of the database
  DECLARE @DirectVersion NVARCHAR(10) = [omd_metadata].[GetFrameworkVersion]();

  IF @DirectVersion IS NULL
  BEGIN
    PRINT 'version function exists but is not returning a value, script assumes corruption'
    PRINT 'Aborting pre-processing.'

    GOTO EndOfProcedureFailure

  END
  ELSE
  BEGIN
    PRINT 'Target database DIRECT Framework version is ' + @DirectVersion
  END

  -- Run through each migration script in order, if needed
  -- do proper semantic versioning comparison here...

  IF @DirectVersion > @CurrentVersion
  BEGIN
    PRINT 'Database is already at a higher version ' + @CurrentVersion
    PRINT 'this script is an older version than the current database'
    PRINT 'Downgrading throught this script is not possible'
    PRINT 'Aborting pre-processing'

    GOTO EndOfProcedure

  END

  IF @DirectVersion = @CurrentVersion
  BEGIN
    PRINT 'Database is already at version ' + @CurrentVersion
    PRINT 'No pre-dacpac migration required'
    PRINT 'Aborting pre-processing'

    GOTO EndOfProcedure

  END

  IF @DirectVersion < @CurrentVersion

  BEGIN
    PRINT 'Database is at version ' + @DirectVersion
    PRINT 'Migration required to version ' + @CurrentVersion

    -- sequence through the migrations as needed
    -- this is an example
    -- point migrations should be rolled up to higher versions when available

    IF @DirectVersion = '1.9.0.0'
    BEGIN
      PRINT 'Running migration 1.9.0.0 to version 1.9.1.0'
      :r ./Migrations/Migration-1.9.1.0.sql
      -- Check that upgrade was successful
    END

    SET @DirectVersion = [omd_metadata].[GetFrameworkVersion]();

    IF @DirectVersion = '1.9.1.0'
    BEGIN
      PRINT 'Running migration 1.9.1.0 to version 1.9.2.0'
      :r ./Migrations/Migration-1.9.2.0.sql
      -- Check that upgrade was successful
    END

    SET @DirectVersion = [omd_metadata].[GetFrameworkVersion]();

    IF @DirectVersion = '1.9.2.0'
    BEGIN
      PRINT 'Running migration 1.9.2.0 to version 2.0.0.0'
      :r ./Migrations/Migration-2.0.0.0.sql
      -- Check that upgrade was successful
    END

  END

  GOTO EndOfProcedureSuccess

END
ELSE
BEGIN
  PRINT 'Metadata table or framerwork version function not found'
  PRINT 'Assume this is an incremental deploy on v1 or a non-DIRECT database'
  PRINT 'Automated upgrades from v1 currently not supported'
  PRINT 'Please add the required migration code to the GitHub repo'
  PRINT 'Aborting pre-processing'

  GOTO EndOfProcedureFailure

END

-- Error/Failure
EndOfProcedureFailure:

  PRINT 'Pre-Dacpac Deployment Script aborted'

  GOTO EndOfProcedure

-- Success
EndOfProcedureSuccess:

    PRINT 'Pre-Dacpac Deployment Script completed'

    GOTO EndOfProcedure

-- End
EndOfProcedure:
