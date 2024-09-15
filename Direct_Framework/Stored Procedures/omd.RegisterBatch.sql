/*******************************************************************************
 * [omd].[RegisterBatch]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   Creates (registers) a new Batch by name (Batch Code)
 *   Updates any existing Batch if the checksums are different.
 *
 * Inputs:
 *   - Batch Code
 *   - Batch Type
 *   - Batch Frequency
 *   - Batch Active Indicator
 *   - Batch Description
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Batch Id
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

DECLARE
  @BatchId          INT,
  @SuccessIndicator CHAR(1),
  @MessageLog       NVARCHAR(MAX);

EXEC [omd].[RegisterBatch]
  -- Mandatory parameters
  @BatchCode            = 'MyNewBatch',
  -- Optional parameters
  @BatchType            = 'Data Object Load Orchestrator',
  @BatchFrequency       = 'On-demand',
  @BatchActiveIndicator = 'Y',
  @BatchDescription     = 'Data logistics Workflow',
  @Debug                = 'Y',
  -- Output parameters
  @BatchId              = @BatchId OUTPUT,
  @SuccessIndicator     = @SuccessIndicator OUTPUT,
  @MessageLog           = @MessageLog OUTPUT;

  PRINT 'The Batch Id is: ''' + CONVERT(NVARCHAR(10), @BatchId) + '''.';

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[RegisterBatch]
(
  -- Mandatory parameters
  @BatchCode              NVARCHAR(1000),
  -- Optional parameters
  @BatchType              NVARCHAR(100)  = NULL,
  @BatchFrequency         NVARCHAR(100)  = 'On-demand',
  @BatchActiveIndicator   CHAR(1)        = 'Y',
  @BatchDescription       NVARCHAR(4000) = NULL,
  @Debug                  CHAR(1)        = 'N',
  -- Output parameters
  @BatchId                INT            = NULL OUTPUT,
  @SuccessIndicator       CHAR(1)        = 'N' OUTPUT,
  @MessageLog             NVARCHAR(MAX)  = NULL OUTPUT
)
AS
BEGIN TRY
  SET NOCOUNT ON;
  SET ANSI_WARNINGS OFF; -- Suppress NULL elimination warning within SET operation.

  -- Default output logging setup
  DECLARE @SpName NVARCHAR(100) = N'[' + OBJECT_SCHEMA_NAME(@@PROCID) + '].[' + OBJECT_NAME(@@PROCID) + ']';
  DECLARE @DirectVersion NVARCHAR(10) = [omd_metadata].[GetFrameworkVersion]();
  DECLARE @StartTimestamp DATETIME = SYSUTCDATETIME();
  DECLARE @StartTimestampString NVARCHAR(20) = FORMAT(@StartTimestamp, 'yyyy-MM-dd HH:mm:ss.fffffff');
  DECLARE @EndTimestamp DATETIME = NULL;
  DECLARE @EndTimestampString NVARCHAR(20) = N'';
  DECLARE @LogMessage NVARCHAR(MAX);

  -- Log standard metadata
  SET @LogMessage = @SpName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Procedure', @LogMessage, @MessageLog)
  SET @LogMessage = @DirectVersion;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Version',@LogMessage, @MessageLog)
  SET @LogMessage = @StartTimestampString;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Start Timestamp', @LogMessage, @MessageLog)

  -- Log parameters
  SET @LogMessage = @BatchCode;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchCode', @LogMessage, @MessageLog)
  SET @LogMessage = @BatchType;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchType', @LogMessage, @MessageLog)
  SET @LogMessage = @BatchFrequency;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchFrequency', @LogMessage, @MessageLog)
  SET @LogMessage = @BatchActiveIndicator;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchActiveIndicator', @LogMessage, @MessageLog)
  SET @LogMessage = @BatchDescription;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @BatchDescription', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail NVARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

  SET @LogMessage = 'Registering Batch for ''' + @BatchCode + '''.'
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)


  INSERT INTO [omd].[BATCH] ([BATCH_CODE], [BATCH_TYPE], [FREQUENCY_CODE], [ACTIVE_INDICATOR], [BATCH_DESCRIPTION])
  SELECT *
  FROM
  (
    VALUES (@BatchCode, @BatchType, @BatchFrequency, @BatchActiveIndicator, @BatchDescription)
  ) AS refData ([BATCH_CODE], [BATCH_TYPE], [FREQUENCY_CODE], [ACTIVE_INDICATOR], [BATCH_DESCRIPTION])
  WHERE NOT EXISTS
  (
    SELECT NULL
    FROM [omd].[BATCH] b
    WHERE b.[BATCH_CODE] = refData.[BATCH_CODE]
  );

  SET @BatchId = SCOPE_IDENTITY();

  IF @BatchId IS NOT NULL
  BEGIN

    SET @LogMessage = 'A new Batch Id ''' + CONVERT(NVARCHAR(10), @BatchId) + ''' has been created for Batch Code ''' + @BatchCode + '''.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

    SET @SuccessIndicator = 'Y'
  END
  ELSE
  BEGIN
    -- Get the existing Batch's Id
    SELECT @BatchId = [BATCH_ID] FROM [omd].[BATCH] WHERE [BATCH_CODE] = @BatchCode;

    SET @LogMessage = 'The Batch ''' + @BatchCode + ''' already exists in [omd].[BATCH] with Batch Id ''' + CONVERT(NVARCHAR(10), @BatchId) + '''.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)
    SET @LogMessage =  'SELECT * FROM [omd].[BATCH] where [BATCH_CODE] = ''' + @BatchCode + '''.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

    -- Evaluate the incoming values to see if the Batch should be updated.
    -- Note that the active indicator is excluded here, to allow it to be managed separately.
    DECLARE @NewChecksum BINARY(20) =
    HASHBYTES('SHA1',
      @BatchType             + '!' +
      @BatchFrequency        + '!' +
      @BatchDescription
    );


    SET @LogMessage = 'The incoming attribute checksum is ''' + CONVERT(VARCHAR(40), @NewChecksum, 2) + '''.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

    -- Evaluate the existing values to see if the Module requires to be updated.
    DECLARE @ExistingChecksum BINARY(20);
    SELECT @ExistingChecksum =
    HASHBYTES('SHA1',
      COALESCE([BATCH_TYPE],        'N/A') + '!' +
      COALESCE([FREQUENCY_CODE],    'N/A') + '!' +
      COALESCE([BATCH_DESCRIPTION], 'N/A'))
    FROM [omd].[BATCH] WHERE [BATCH_CODE] = @BatchCode;

    SET @LogMessage = 'The existing attribute checksum is ''' + CONVERT(VARCHAR(40), @ExistingChecksum, 2) + '''.'
    SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

    -- Update the existing Batch with new values, if they are different.
    IF @NewChecksum <> @ExistingChecksum
    BEGIN

      SET @LogMessage = CONCAT('The checksums are different, and Batch ''',@BatchCode, ''' with Batch Id ''' + CONVERT(NVARCHAR(10), @BatchId)+''' will be updated.')
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

      UPDATE [omd].[BATCH]
      SET
        [BATCH_TYPE] = @BatchType,
        [FREQUENCY_CODE] = @BatchFrequency,
        [BATCH_DESCRIPTION] = @BatchDescription
      WHERE [BATCH_ID] = @BatchId;

      SET @LogMessage = CONCAT('The Batch ''', @BatchCode, ''' has been updated with the new attribute values.')
      SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, DEFAULT, @LogMessage, @MessageLog)

      SET @SuccessIndicator = 'Y';
    END
  END

  -- End of procedure label
  EndOfProcedure:

  SET @EndTimestamp = SYSUTCDATETIME();
  SET @EndTimestampString = FORMAT(@EndTimestamp, 'yyyy-MM-dd HH:mm:ss.fffffff');
  SET @LogMessage = @EndTimestampString;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'End Timestamp', @LogMessage, @MessageLog)
  SET @LogMessage = DATEDIFF(SECOND, @StartTimestamp, @EndTimestamp);
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Elapsed Time (s)', @LogMessage, @MessageLog)
  SET @LogMessage = @SuccessIndicator;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @SuccessIndicator', @LogMessage, @MessageLog)

  IF @Debug = 'Y'
  BEGIN
    EXEC [omd].[PrintMessageLog] @MessageLog;
  END

END TRY
BEGIN CATCH
  -- SP-wide error handler and logging
  SET @SuccessIndicator = 'N'
  SET @LogMessage = @SuccessIndicator;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @SuccessIndicator', @LogMessage, @MessageLog)

  DECLARE @ErrorMessage NVARCHAR(4000);
  DECLARE @ErrorSeverity INT;
  DECLARE @ErrorState INT;
  DECLARE @ErrorProcedure NVARCHAR(128);
  DECLARE @ErrorNumber INT;
  DECLARE @ErrorLine INT;

  SELECT
    @ErrorMessage   = COALESCE(ERROR_MESSAGE(),     'No Message'    ),
    @ErrorSeverity  = COALESCE(ERROR_SEVERITY(),    -1              ),
    @ErrorState     = COALESCE(ERROR_STATE(),       -1              ),
    @ErrorProcedure = COALESCE(ERROR_PROCEDURE(),   'No Procedure'  ),
    @ErrorLine      = COALESCE(ERROR_LINE(),        -1              ),
    @ErrorNumber    = COALESCE(ERROR_NUMBER(),      -1              );

  IF @Debug = 'Y'
  BEGIN
    PRINT 'Error in '''       + @SpName + ''''
    PRINT 'Error Message: '   + @ErrorMessage
    PRINT 'Error Severity: '  + CONVERT(NVARCHAR(10), @ErrorSeverity)
    PRINT 'Error State: '     + CONVERT(NVARCHAR(10), @ErrorState)
    PRINT 'Error Procedure: ' + @ErrorProcedure
    PRINT 'Error Line: '      + CONVERT(NVARCHAR(10), @ErrorLine)
    PRINT 'Error Number: '    + CONVERT(NVARCHAR(10), @ErrorNumber)
    PRINT 'SuccessIndicator: '+ @SuccessIndicator

    -- Spool message log
    EXEC [omd].[PrintMessageLog] @MessageLog;

  END

  SET @EventDetail = 'Error in ''' + COALESCE(@SpName,'N/A') + ''' from ''' + COALESCE(@ErrorProcedure,'N/A') + ''' at line ''' + CONVERT(NVARCHAR(10), COALESCE(@ErrorLine,'N/A')) + ''': '+ CHAR(10) + COALESCE(@ErrorMessage,'N/A');
  SET @EventReturnCode = ERROR_NUMBER();

  EXEC [omd].[InsertIntoEventLog]
    @EventDetail       = @EventDetail,
    @EventReturnCode   = @EventReturnCode;

  THROW
END CATCH
