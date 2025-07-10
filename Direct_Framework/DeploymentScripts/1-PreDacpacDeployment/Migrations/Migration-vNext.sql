/*
  Default migration script for Direct Framework.
  must be executed outside of the dacpac deployment.
  This is a standard named file that is the work in progress migrations required for vNext
  Once a version is finalised, the script will be named after the new version and included in the
  upgrade process for the pre-dacpac deployment.

  This scrip only updates from the current version to the next version.
  Each version that requires an upgrade will have a separate migration script for that version.
  The upgrade scripts will then be applied in sequence from the currently deployed version to the new version.


Warning SQL72015: The type for column ROWS_DELETED in table [omd].[MODULE_INSTANCE] is currently  INT NULL but is being changed to  NUMERIC (38) NULL. Data loss could occur and deployment may fail if the column contains data that is incompatible with type  NUMERIC (38) NULL.
Warning SQL72015: The type for column ROWS_DISCARDED in table [omd].[MODULE_INSTANCE] is currently  INT NULL but is being changed to  NUMERIC (38) NULL. Data loss could occur and deployment may fail if the column contains data that is incompatible with type  NUMERIC (38) NULL.
Warning SQL72015: The type for column ROWS_INPUT in table [omd].[MODULE_INSTANCE] is currently  INT NULL but is being changed to  NUMERIC (38) NULL. Data loss could occur and deployment may fail if the column contains data that is incompatible with type  NUMERIC (38) NULL.
Warning SQL72015: The type for column ROWS_INSERTED in table [omd].[MODULE_INSTANCE] is currently  INT NULL but is being changed to  NUMERIC (38) NULL. Data loss could occur and deployment may fail if the column contains data that is incompatible with type  NUMERIC (38) NULL.
Warning SQL72015: The type for column ROWS_REJECTED in table [omd].[MODULE_INSTANCE] is currently  INT NULL but is being changed to  NUMERIC (38) NULL. Data loss could occur and deployment may fail if the column contains data that is incompatible with type  NUMERIC (38) NULL.
Warning SQL72015: The type for column ROWS_UPDATED in table [omd].[MODULE_INSTANCE] is currently  INT NULL but is being changed to  NUMERIC (38) NULL. Data loss could occur and deployment may fail if the column contains data that is incompatible with type  NUMERIC (38) NULL.
Warning SQL72015: The column [omd_metadata].[EVENT_TYPE].[EVENT_TYPE_CODE_DESCRIPTION] is being dropped, data loss could occur.
Warning SQL72015: The column [omd_metadata].[INTERNAL_PROCESSING_STATUS].[INTERNAL_PROCESSING_STATUS_CODE_DESCRIPTION] is being dropped, data loss could occur.
Warning SQL72015: The column [omd_metadata].[NEXT_RUN_STATUS].[NEXT_RUN_DESCRIPTION] is being dropped, data loss could occur.
Error SQL72014: Core Microsoft SqlClient Data Provider: Msg 50000, Level 16, State 127, Line 16 Rows were detected. The schema update is terminating because data loss might occur.
Error SQL72045: Script execution error.  The executed script:
IF EXISTS (SELECT TOP 1 1
           FROM   [omd].[MODULE_INSTANCE])
    RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127)
        WITH NOWAIT;
*/

PRINT 'Migrating DIRECT Framework from v2.0.0 to vNext'

BEGIN TRY
  BEGIN TRANSACTION
  -- Migration code goes here

  -- Table: [omd].[MODULE_INSTANCE]
  -- migration: expand data types to new larger types for standard row counts
  ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_DELETED] NUMERIC(38) NULL;
  ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_DISCARDED] NUMERIC(38) NULL;
  ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_INPUT] NUMERIC(38) NULL;
  ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_INSERTED] NUMERIC(38) NULL;
  ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_REJECTED] NUMERIC(38) NULL;
  ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_UPDATED] NUMERIC(38) NULL;

  -- Table: [omd_metadata].[INTERNAL_PROCESSING_STATUS]
  -- migration: rename column [INTERNAL_PROCESSING_STATUS_CODE_DESCRIPTION] to [INTERNAL_PROCESSING_STATUS_DESCRIPTION]
  -- to adhere to the combo CODE/DESCRIPTION naming convention

  -- Only rename if the old column exists and the new column does not
IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'omd_metadata'
      AND TABLE_NAME = 'INTERNAL_PROCESSING_STATUS'
      AND COLUMN_NAME = 'INTERNAL_PROCESSING_STATUS_CODE_DESCRIPTION'
)
AND NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'omd_metadata'
      AND TABLE_NAME = 'INTERNAL_PROCESSING_STATUS'
      AND COLUMN_NAME = 'INTERNAL_PROCESSING_STATUS_DESCRIPTION'
)
BEGIN
  -- add a column with the new name
    ALTER TABLE [omd_metadata].[INTERNAL_PROCESSING_STATUS]
    ADD [INTERNAL_PROCESSING_STATUS_DESCRIPTION] NVARCHAR(4000) NULL;

    -- copy data from old column to new column
    UPDATE [omd_metadata].[INTERNAL_PROCESSING_STATUS]
    SET [INTERNAL_PROCESSING_STATUS_DESCRIPTION] = [INTERNAL_PROCESSING_STATUS_CODE_DESCRIPTION];

    -- drop old column
    ALTER TABLE [omd_metadata].[INTERNAL_PROCESSING_STATUS]
    DROP COLUMN [INTERNAL_PROCESSING_STATUS_CODE_DESCRIPTION];
END


  -- Table: [omd_metadata].[EVENT_TYPE]
  -- migration: rename column [EVENT_TYPE_CODE_DESCRIPTION] to [EVENT_TYPE_DESCRIPTION]
  -- to adhere to the combo ICODE/DESCRIPTION naming convention

  IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'omd_metadata'
      AND TABLE_NAME = 'EVENT_TYPE'
      AND COLUMN_NAME = 'EVENT_TYPE_CODE_DESCRIPTION'

      )
      AND NOT EXISTS (
      SELECT 1
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = 'omd_metadata'
        AND TABLE_NAME = 'EVENT_TYPE'
        AND COLUMN_NAME = 'EVENT_TYPE_DESCRIPTION'
      )
      BEGIN
      -- add a column with the new name
      ALTER TABLE [omd_metadata].[EVENT_TYPE]
      ADD [EVENT_TYPE_DESCRIPTION] NVARCHAR(4000) NULL;
      -- copy data from old column to new column
      UPDATE [omd_metadata].[EVENT_TYPE]
      SET [EVENT_TYPE_DESCRIPTION] = [EVENT_TYPE_CODE_DESCRIPTION];
      -- drop old column
      ALTER TABLE [omd_metadata].[EVENT_TYPE]
      DROP COLUMN [EVENT_TYPE_CODE_DESCRIPTION];
      END


  -- Table: [omd_metadata].[NEXT_RUN_STATUS]
  -- migration: rename column [NEXT_RUN_DESCRIPTION] to [NEXT_RUN_STATUS_DESCRIPTION]
  -- to adhere to the CODE/DESCRIPTION naming convention

  IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'omd_metadata'
      AND TABLE_NAME = 'NEXT_RUN_STATUS'
      AND COLUMN_NAME = 'NEXT_RUN_DESCRIPTION'
      )
      AND NOT EXISTS (
      SELECT 1
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = 'omd_metadata'
        AND TABLE_NAME = 'NEXT_RUN_STATUS'
        AND COLUMN_NAME = 'NEXT_RUN_STATUS_DESCRIPTION'
      )
      BEGIN
      -- add a column with the new name
      ALTER TABLE [omd_metadata].[NEXT_RUN_STATUS]
      ADD [NEXT_RUN_STATUS_DESCRIPTION] NVARCHAR(4000) NULL;
      -- copy data from old column to new column
      UPDATE [omd_metadata].[NEXT_RUN_STATUS]
      SET [NEXT_RUN_STATUS_DESCRIPTION] = [NEXT_RUN_DESCRIPTION];
      -- drop old column
      ALTER TABLE [omd_metadata].[NEXT_RUN_STATUS]
      DROP COLUMN [NEXT_RUN_DESCRIPTION];
      END

  -- Set new version as last step
  UPDATE  [omd_metadata].[FRAMEWORK_METADATA]
  SET     [VALUE] = 'vNext'
  WHERE   [CODE] = 'DIRECT_VERSION'

  PRINT 'Migration to vNext Completed'

  COMMIT TRANSACTION

END TRY
BEGIN CATCH

  IF @@TRANCOUNT > 0
  BEGIN
    ROLLBACK TRANSACTION
  END

  PRINT ERROR_MESSAGE()
  PRINT 'Migration failed'

  RETURN

END CATCH
