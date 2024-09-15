PRINT 'Migrating DIRECT Framework to 2.0.0.0'

BEGIN TRY
  BEGIN TRANSACTION
  -- Migration code goes here

  -- Placeholder...

  -- Set new version as last step
  UPDATE  [omd_metadata].[FRAMEWORK_METADATA]
  SET     [VALUE] = '2.0.0.0'
  WHERE   [CODE] = 'DIRECT_VERSION'

  PRINT 'Migration to 2.0.0.0 Completed'

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
