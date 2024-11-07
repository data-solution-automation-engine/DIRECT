/*******************************************************************************
 * [omd].[EndDating]
 *******************************************************************************
 *
 * https://github.com/data-solution-automation-engine/DIRECT
 *
 * DIRECT model v2.0
 *
 * Purpose:
 *   End Dating
 *
 * Inputs:
 *   - Data Object Name
 *   - Data Object Schema
 *   - Key Array (list of keys to end-date against)
 *   - Current Record Indicator Column Name (if available)
 *   - Inscripion Record Id Column Name (defaulted to INSCRIPTION_RECORD_ID)
 *   - Expiry Date Column Name (defaulted to INSCRIPTION_TIMESTAMP)
 *   - Effective Date Column Name (defaulted to INSCRIPTION_BEFORE_TIMESTAMP)
 *   - Debug Flag (Y/N, defaults to N)
 *
 * Outputs:
 *   - Success Indicator (Y/N)
 *   - Message Log
 *
 * Usage:
 *
 *******************************************************************************

TBA

 *******************************************************************************
 *
 ******************************************************************************/

CREATE PROCEDURE [omd].[END_DATING]
(
  -- Mandatory parameters
  @DataObjectName                   VARCHAR(MAX)
 ,@DataObjectSchema                 VARCHAR(MAX)
 ,@KeyArray                         VARCHAR(MAX)  = NULL
 ,@ModuleInstanceId                 INT           = 0
  -- Optional parameters
 ,@CurrentRecordIndicatorColumnName VARCHAR(50)   = 'CURRENT_RECORD_INDICATOR'
 ,@InscriptionRecordIdColumnName    VARCHAR(50)   = 'INSCRIPTION_RECORD_ID'
 ,@ExpiryDateColumnName             VARCHAR(50)   = 'INSCRIPTION_TIMESTAMP'
 ,@EffectiveDateColumnName          VARCHAR(50)   = 'INSCRIPTION_BEFORE_TIMESTAMP'
 ,@Debug                            CHAR(1)       = 'N',
  -- Output parameters
  @SuccessIndicator                 CHAR(1)       = NULL OUTPUT,
  @MessageLog                       NVARCHAR(MAX) = NULL OUTPUT
)
AS
BEGIN TRY
SET NOCOUNT ON

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
  SET @LogMessage = @DataObjectName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @DataObjectName', @LogMessage, @MessageLog)
  SET @LogMessage = @DataObjectSchema;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @DataObjectSchema', @LogMessage, @MessageLog)
  SET @LogMessage = @KeyArray;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @KeyArray', @LogMessage, @MessageLog)
  SET @LogMessage = @ModuleInstanceId;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ModuleInstanceId', @LogMessage, @MessageLog)
  SET @LogMessage = @CurrentRecordIndicatorColumnName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @CurrentRecordIndicatorColumnName', @LogMessage, @MessageLog)
  SET @LogMessage = @InscriptionRecordIdColumnName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @InscriptionRecordIdColumnName', @LogMessage, @MessageLog)
  SET @LogMessage = @ExpiryDateColumnName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @ExpiryDateColumnName', @LogMessage, @MessageLog)
  SET @LogMessage = @EffectiveDateColumnName;
  SET @MessageLog = [omd].[AddLogMessage](DEFAULT, DEFAULT, N'Parameter @EffectiveDateColumnName', @LogMessage, @MessageLog)

  -- Process variables
  DECLARE @EventDetail VARCHAR(4000);
  DECLARE @EventReturnCode INT;
  SET @SuccessIndicator = 'N' -- Ensure the process starts as not successful, so that is updated accordingly when it is.

/*******************************************************************************
 * Start of main process
 ******************************************************************************/

-- !! NOT FINISHED YET !!

DECLARE
   @DataObjectName VARCHAR(MAX)                         = ''
  ,@DataObjectSchema VARCHAR(MAX)                       = ''
  ,@KeyArray VARCHAR(MAX)                               = ''
  ,@ModuleInstanceId INT                                = 0
  ,@CurrentRecordIndicatorColumnName VARCHAR(50)        = 'CURRENT_RECORD_INDICATOR'
  ,@InscriptionRecordIdColumnName VARCHAR(50)           = 'INSCRIPTION_RECORD_ID'
  ,@EffectiveDateColumnName VARCHAR(50)                 = 'INSCRIPTION_TIMESTAMP'
  ,@ExpiryDateColumnName VARCHAR(50)                    = 'INSCRIPTION_BEFORE_TIMESTAMP'
  ,@DirectUpdateModuleInstanceIdColumnName VARCHAR(50)  = 'MODULE_INSTANCE_UPDATE_ID'

    -- Process variables
  DECLARE @EventDetail NVARCHAR(4000);
  DECLARE @EventReturnCode INT;

-- The resulting query
DECLARE @Query AS VARCHAR(MAX);

-- Management of (composite) key(s)
DECLARE @IndividualKey VARCHAR(MAX) = '';
DECLARE @KeySelectStatement VARCHAR(MAX) = '';

  DECLARE db_cursor CURSOR FOR
  SELECT VALUE FROM STRING_SPLIT(@KeyArray, ',')

  OPEN db_cursor
  FETCH NEXT FROM db_cursor INTO @IndividualKey

  WHILE @@FETCH_STATUS = 0
  BEGIN
      SET @IndividualKey = TRIM(@IndividualKey);

    SET @KeySelectStatement = @KeySelectStatement+@IndividualKey+','

    FETCH NEXT FROM db_cursor INTO @IndividualKey
  END

  CLOSE db_cursor
  DEALLOCATE db_cursor

  SET @Query =
N'UPDATE main
SET
 main.'+@CurrentRecordIndicatorColumnName+' = ''N''
FROM '+@DataObjectSchema+'.'+@DataObjectName+' main
WHERE NOT EXISTS
(
  /*
     Find all the records where they are not the most recent,
     but still have current_record_indicator=''Y''
  */
  SELECT
     sub.'+@KeySelectStatement+'
    ,sub.'+@EffectiveDateColumnName+'
  FROM '+@DataObjectSchema+'.'+@DataObjectName+' sub
  JOIN
  (
  SELECT CustomerId, MAX('+@EffectiveDateColumnName+') AS MAX_'+@EffectiveDateColumnName+'
  FROM '+@DataObjectSchema+'.'+@DataObjectName+'
  GROUP BY CustomerId
  ) maxsub ON sub.CustomerId=maxsub.CustomerId
      AND sub.'+@EffectiveDateColumnName+' <> maxsub.MAX_'+@EffectiveDateColumnName+'
  WHERE '+@CurrentRecordIndicatorColumnName+'=''Y''
)'

  PRINT @Query
  --EXECUTE sp_executesql  @Query

  /*Example

  UPDATE main
  SET main.CURRENT_RECORD_INDICATOR='N'
  FROM [dbo].[PSA_PROFILER_CUSTOMER_PERSONAL] main
  WHERE NOT EXISTS
  (
    /* Find all the records where they are not the most recent, but still have current_record_indicator='Y' */
    SELECT sub.CustomerId, sub.INSCRIPTION_TIMESTAMP
    FROM [dbo].[PSA_PROFILER_CUSTOMER_PERSONAL] sub
    JOIN
    (
    SELECT CustomerId, MAX(INSCRIPTION_TIMESTAMP) AS MAX_TIMESTAMP
    FROM [dbo].[PSA_PROFILER_CUSTOMER_PERSONAL]
    GROUP BY CustomerId
    ) maxsub ON sub.CustomerId=maxsub.CustomerId
        AND sub.INSCRIPTION_TIMESTAMP <> maxsub.MAX_TIMESTAMP
    WHERE CURRENT_RECORD_INDICATOR='Y'
  )
  */

  -- End of procedure label
  EndOfProcedure:

  SET @SuccessIndicator = 'Y'
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
    @EventReturnCode   = @EventReturnCode,
    @ModuleInstanceId  = @ModuleInstanceId;

  THROW
END CATCH
