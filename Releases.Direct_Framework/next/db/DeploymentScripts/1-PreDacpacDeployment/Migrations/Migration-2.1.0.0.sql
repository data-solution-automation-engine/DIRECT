/*
Version migration script for Direct Framework.
must be executed before and outside of the dacpac deployment.

This script only updates from the current version to the next version.
Each version that requires a non-dacpac upgrade will have a separate
migration script for that version.
The upgrade scripts are applied in sequence from the currently deployed
version to the new version by the upgrade orchestrator script.
*/

PRINT 'Migrating DIRECT Framework from v2.0.0 to v2.1.0';
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
  BEGIN TRANSACTION

/* -------------------------------------------------------------------------- */
    -- Table: [omd].[MODULE_INSTANCE]
    -- Migration: expand data types to new larger types for standard row counts
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_DELETED] BIGINT NULL;
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_DISCARDED] BIGINT NULL;
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_INPUT] BIGINT NULL;
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_INSERTED] BIGINT NULL;
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_REJECTED] BIGINT NULL;
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_UPDATED] BIGINT NULL;

/* -------------------------------------------------------------------------- */
    -- Table: [omd_metadata].[INTERNAL_PROCESSING_STATUS]
    -- Migration: rename column [INTERNAL_PROCESSING_STATUS_CODE_DESCRIPTION] to [INTERNAL_PROCESSING_STATUS_DESCRIPTION]
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
      -- Add new column
      EXEC sp_executesql N' -- DevSkim: ignore DS224000
          ALTER TABLE [omd_metadata].[INTERNAL_PROCESSING_STATUS]
          ADD [INTERNAL_PROCESSING_STATUS_DESCRIPTION] NVARCHAR(4000) NULL;
      ';

      -- Copy data
      EXEC sp_executesql N' -- DevSkim: ignore DS224000
          UPDATE [omd_metadata].[INTERNAL_PROCESSING_STATUS]
          SET [INTERNAL_PROCESSING_STATUS_DESCRIPTION] = [INTERNAL_PROCESSING_STATUS_CODE_DESCRIPTION];
      ';

      -- Drop old column
      EXEC sp_executesql N' -- DevSkim: ignore DS224000
          ALTER TABLE [omd_metadata].[INTERNAL_PROCESSING_STATUS]
          DROP COLUMN [INTERNAL_PROCESSING_STATUS_CODE_DESCRIPTION];
      ';
    END

/* -------------------------------------------------------------------------- */
    -- Table: [omd_metadata].[EVENT_TYPE]
    -- migration: rename column [EVENT_TYPE_CODE_DESCRIPTION] to [EVENT_TYPE_DESCRIPTION]
    -- to adhere to the combo CODE/DESCRIPTION naming convention
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
      -- Add new column
      EXEC sp_executesql N' -- DevSkim: ignore DS224000
          ALTER TABLE [omd_metadata].[EVENT_TYPE]
          ADD [EVENT_TYPE_DESCRIPTION] NVARCHAR(4000) NULL;
      ';

      -- Copy data
      EXEC sp_executesql N' -- DevSkim: ignore DS224000
          UPDATE [omd_metadata].[EVENT_TYPE]
          SET [EVENT_TYPE_DESCRIPTION] = [EVENT_TYPE_CODE_DESCRIPTION];
      ';

      -- Drop old column
      EXEC sp_executesql N' -- DevSkim: ignore DS224000
          ALTER TABLE [omd_metadata].[EVENT_TYPE]
          DROP COLUMN [EVENT_TYPE_CODE_DESCRIPTION];
      ';
    END

/* -------------------------------------------------------------------------- */
    -- Table: [omd_metadata].[NEXT_RUN_STATUS]
    -- Migration: rename column [NEXT_RUN_DESCRIPTION] to [NEXT_RUN_STATUS_DESCRIPTION]
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
      -- Add new column
      EXEC sp_executesql N' -- DevSkim: ignore DS224000
          ALTER TABLE [omd_metadata].[NEXT_RUN_STATUS]
          ADD [NEXT_RUN_STATUS_DESCRIPTION] NVARCHAR(4000) NULL;
      ';

      -- Copy data
      EXEC sp_executesql N' -- DevSkim: ignore DS224000
          UPDATE [omd_metadata].[NEXT_RUN_STATUS]
          SET [NEXT_RUN_STATUS_DESCRIPTION] = [NEXT_RUN_DESCRIPTION];
      ';

      -- Drop old column
      EXEC sp_executesql N' /* DevSkim: ignore DS224000 */
          ALTER TABLE [omd_metadata].[NEXT_RUN_STATUS]
          DROP COLUMN [NEXT_RUN_DESCRIPTION];
      ';
    END

/* -------------------------------------------------------------------------- */
    -- Table omd_metadata.AREA, predefined area code Maintenance
    -- Pre-upgrade standard code = 'Maintenance'
    -- Post-upgrade standard code = 'MAINT'
    -- This is to adhere to the code naming convention in the table

    -- AREA_CODE is a FK column in [omd].[MODULE] table, so must be updated there as well
    -- Disable the constraint temporarily to allow the updates
    ALTER TABLE [omd].[MODULE] NOCHECK CONSTRAINT [FK_OMD_MODULE_OMD_METADATA_AREA];

    IF EXISTS (
      SELECT 1
      FROM [omd].[MODULE]
      WHERE [AREA_CODE] = 'Maintenance'
    )
    BEGIN
      UPDATE [omd].[MODULE]
      SET [AREA_CODE] = 'MAINT'
      WHERE [AREA_CODE] = 'Maintenance';
    END

    IF EXISTS (
      SELECT 1
      FROM [omd_metadata].[AREA]
      WHERE [AREA_CODE] = 'Maintenance'
    )
    BEGIN
      UPDATE [omd_metadata].[AREA]
      SET [AREA_CODE] = 'MAINT'
      WHERE [AREA_CODE] = 'Maintenance';
    END

    -- reenable the constraint
    ALTER TABLE [omd].[MODULE] WITH CHECK CHECK CONSTRAINT [FK_OMD_MODULE_OMD_METADATA_AREA];

/* -------------------------------------------------------------------------- */
    -- Table: [omd_metadata].[FRAMEWORK_METADATA]
    -- Migration: set column [ACTIVE_INDICATOR] to NOT NULL
    -- and populate existing NULL values with 'N'
    IF EXISTS (
      SELECT 1
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = 'omd_metadata'
        AND TABLE_NAME = 'FRAMEWORK_METADATA'
        AND COLUMN_NAME = 'ACTIVE_INDICATOR'
        AND IS_NULLABLE = 'YES'
    )
    BEGIN
      -- Populate any existing NULL values in ACTIVE_INDICATOR with 'N'
      UPDATE [omd_metadata].[FRAMEWORK_METADATA]
      SET [ACTIVE_INDICATOR] = 'N'
      WHERE [ACTIVE_INDICATOR] IS NULL;

      -- Alter column to set it as NOT NULL
      ALTER TABLE [omd_metadata].[FRAMEWORK_METADATA]
      ALTER COLUMN [ACTIVE_INDICATOR] CHAR(1) NOT NULL;
    END

/* -------------------------------------------------------------------------- */
    -- Migrate all main code columns from 1000 to 500 characters
    -- some, or all, code columns are, or might be, used in indexes,
    -- which have a hard limit on size
    -- migration fails if any existing values are longer than 500 characters
    -- these would need to be managed/migrated before the upgrade runs
    -- also migrate unique index name IX_OMD_MODULE_MODULE_CODE to IX_OMD_MODULE

    -- Check if there are any keys that would need to be truncated/renamed
    IF EXISTS (
      SELECT 1
      FROM [omd].[BATCH] b
      WHERE LEN(b.BATCH_CODE) > 500
    )
    BEGIN
      PRINT 'ERROR: There are BATCH_CODE values longer than 500 characters.';
      PRINT 'Please adjust these to adhere to the new max length';
      THROW 50000, 'Migration failed due to BATCH_CODE values longer than 500 characters.', 1;
    END

    IF EXISTS (
      SELECT 1
      FROM [omd].[MODULE] m
      WHERE LEN(m.MODULE_CODE) > 500
    )
    BEGIN
      PRINT 'ERROR: There are MODULE_CODE values longer than 500 characters.';
      PRINT 'Please adjust these to adhere to the new max length';
      THROW 50001, 'Migration failed due to MODULE_CODE values longer than 500 characters.', 1;
    END

    IF EXISTS (
      SELECT 1
      FROM [omd].[PARAMETER] p
      WHERE LEN(p.PARAMETER_KEY_CODE) > 500
    )
    BEGIN
      PRINT 'ERROR: There are PARAMETER_KEY_CODE values longer than 500 characters.';
      PRINT 'Please adjust these to adhere to the new max length';
      THROW 50002, 'Migration failed due to PARAMETER_KEY_CODE values longer than 500 characters.', 1;
    END

    -- If all checks pass, alter the columns to the new size

    -- disable or drop any dependent objects or constraints.
-- 1) Drop the UNIQUE constraint (this also drops the backing unique index)
IF EXISTS (
  SELECT 1
  FROM sys.key_constraints
  WHERE [name] = N'IX_OMD_BATCH'
  AND parent_object_id = OBJECT_ID(N'omd.BATCH') )
ALTER TABLE [omd].[BATCH] DROP CONSTRAINT [IX_OMD_BATCH];

IF EXISTS (
  SELECT 1
  FROM sys.key_constraints
  WHERE [name] = N'IX_OMD_MODULE_MODULE_CODE'
  AND parent_object_id = OBJECT_ID(N'omd.MODULE') )
ALTER TABLE [omd].[MODULE] DROP CONSTRAINT [IX_OMD_MODULE_MODULE_CODE];

--    DROP INDEX IF EXISTS [IX_OMD_BATCH_BATCH_CODE] ON [omd].[BATCH];
--    DROP INDEX IF EXISTS [IX_OMD_MODULE_MODULE_CODE] ON [omd].[MODULE];

    ALTER TABLE [omd].[BATCH] ALTER COLUMN [BATCH_CODE] NVARCHAR(500) NOT NULL;
    ALTER TABLE [omd].[MODULE] ALTER COLUMN [MODULE_CODE] NVARCHAR(500) NOT NULL;
    ALTER TABLE [omd].[PARAMETER] ALTER COLUMN [PARAMETER_KEY_CODE] NVARCHAR(500) NOT NULL;

    -- Recreate any dependent objects or constraints after altering the columns
    -- CREATE INDEX [IX_OMD_BATCH_BATCH_CODE] ON [omd].[BATCH] ([BATCH_CODE]);
    -- CREATE INDEX [IX_OMD_MODULE_MODULE_CODE] ON [omd].[MODULE] ([MODULE_CODE]);
    IF NOT EXISTS (
      SELECT 1
      FROM sys.key_constraints
      WHERE [name] = N'IX_OMD_BATCH'
        AND parent_object_id = OBJECT_ID(N'omd.BATCH')
    )
    BEGIN
      CREATE UNIQUE NONCLUSTERED INDEX [IX_OMD_BATCH]
      ON [omd].[BATCH] ([BATCH_CODE] ASC);
    END

    IF NOT EXISTS (
      SELECT 1
      FROM sys.key_constraints
      WHERE [name] = N'IX_OMD_MODULE'
        AND parent_object_id = OBJECT_ID(N'omd.MODULE')
    )
    BEGIN
      CREATE UNIQUE NONCLUSTERED INDEX [IX_OMD_MODULE]
      ON [omd].[MODULE] ([MODULE_CODE] ASC);
    END

/* -------------------------------------------------------------------------- */
    /*
      Rename the [omd].[SOURCE_CONTROL] primary key from
      [MODULE_SOURCE_CONTROL_ID] to [SOURCE_CONTROL_ID]
    */

/* -------------------------------------------------------------------------- */
    -- Set new Direct Framework version as last step
    IF EXISTS (
      SELECT 1
      FROM [omd_metadata].[FRAMEWORK_METADATA]
      WHERE [CODE] = 'DIRECT_VERSION'
    )
    BEGIN
      UPDATE  [omd_metadata].[FRAMEWORK_METADATA]
      SET     [VALUE] = '2.1.0'
      WHERE   [CODE] = 'DIRECT_VERSION'
    END
    ELSE
    BEGIN
      PRINT 'Warning - metadata version not found in [omd_metadata].[FRAMEWORK_METADATA]. Adding new entry.';
      INSERT INTO [omd_metadata].[FRAMEWORK_METADATA] ([CODE], [VALUE])
      VALUES ('DIRECT_VERSION', '2.1.0')
    END

/* -------------------------------------------------------------------------- */
  -- commit or rollback based on transaction state
  -- if state is 0 then there is nothing to commit or rollback
  IF XACT_STATE() = 1
    COMMIT TRANSACTION
  ELSE IF XACT_STATE() = -1
    ROLLBACK TRANSACTION

  -- migration committed successfully
  PRINT 'Migration to version 2.1.0 completed'
END TRY
BEGIN CATCH
/* -------------------------------------------------------------------------- */
  -- Always rollback an open transaction if an error occurs,
  -- even if it might be considered committable here
  IF XACT_STATE() <> 0
    ROLLBACK TRANSACTION;

  PRINT 'Error ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) +
        ', Severity ' + CAST(ERROR_SEVERITY() AS NVARCHAR(10)) +
        ', State ' + CAST(ERROR_STATE() AS NVARCHAR(10)) +
        ': ' + ERROR_MESSAGE();

  PRINT 'ERROR: Pre-DACPAC Migration to version 2.1.0 failed';
  THROW; -- Rethrow the original error with full context
END CATCH
