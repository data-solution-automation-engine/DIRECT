/*
Default migration script for Direct Framework.
must be executed before and outside of the dacpac deployment.
This is a standard named file that is the work in progress migrations required for vNext
Once a version is finalized, the script will be named after the new version and included in the
upgrade process for the pre-dacpac deployment.

This script only updates from the current version to the next version.
Each version that requires an upgrade will have a separate migration script for that version.
The upgrade scripts will then be applied in sequence from the currently deployed version to the new version.
*/

PRINT 'Migrating DIRECT Framework from v2.0.0 to v2.1.0';

BEGIN TRY
  BEGIN TRANSACTION

    -- Table: [omd].[MODULE_INSTANCE]
    -- Migration: expand data types to new larger types for standard row counts
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_DELETED] BIGINT NULL;
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_DISCARDED] BIGINT NULL;
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_INPUT] BIGINT NULL;
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_INSERTED] BIGINT NULL;
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_REJECTED] BIGINT NULL;
    ALTER TABLE [omd].[MODULE_INSTANCE] ALTER COLUMN [ROWS_UPDATED] BIGINT NULL;

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
      EXEC sp_executesql N' -- DevSkim: ignore DS224000
          ALTER TABLE [omd_metadata].[NEXT_RUN_STATUS]
          DROP COLUMN [NEXT_RUN_DESCRIPTION];
      ';
    END

    -- Table omd_metadata.AREA, predefined area code Maintenance
    -- Pre-upgrade standard code = 'Maintenance'
    -- Post-upgrade standard code = 'MAINT'
    -- This is to adhere to the code naming convention in the table
    IF EXISTS (
      SELECT 1
      FROM [omd_metadata].[AREA]
      WHERE [CODE] = 'Maintenance'
    )
    BEGIN
      UPDATE [omd_metadata].[AREA]
      SET [CODE] = 'MAINT'
      WHERE [CODE] = 'Maintenance';
    END


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
  -- commit or rollback based on transaction state
  IF XACT_STATE() = 1
    COMMIT TRANSACTION
  ELSE IF XACT_STATE() = -1
    ROLLBACK TRANSACTION
  -- migration committed successfully
  PRINT 'Migration to version 2.1.0 completed'
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0
  BEGIN
    PRINT 'Error ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) +
          ', Severity ' + CAST(ERROR_SEVERITY() AS NVARCHAR(10)) +
          ', State ' + CAST(ERROR_STATE() AS NVARCHAR(10)) +
          ': ' + ERROR_MESSAGE();
    ROLLBACK TRANSACTION;
  END
  PRINT 'Migration to version 2.1.0 failed';
  THROW; -- Rethrows the original error with full context
END CATCH
