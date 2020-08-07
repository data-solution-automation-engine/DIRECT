/*
Process: Create Load Window
Input: 
  - Module Code OR Module Id (Id is chosen if both provided)
  - Debug flag Y/N
Returns:
  - Load Window Start Date/Time
  - Load Window End Date/Time
Usage:
  <>
*/

CREATE PROCEDURE [omd].[CreateLoadWindow]
	@ModuleCode VARCHAR(255) = 'N/A', -- The name of the Module, as identified in the MODULE_CODE attribute in the MODULE table.
    @ModuleId INT = 0, -- The Module Id, based on the name (see above)
	@Debug VARCHAR(1) = 'N',
	@LoadWindowStartDateTime INT = NULL OUTPUT,
    @LoadWindowEndDateTime INT = NULL OUTPUT
AS
BEGIN

  -- Local variables
  DECLARE @ModuleInstanceId INT;

  -- Exception handling
  IF @ModuleCode = 'N/A' AND @ModuleId = 0 
    THROW 50000,'Either the Module Code or the Module Id should be provided, but not both.',1

  If @ModuleCode != 'N/A'
  BEGIN 
    SELECT @ModuleId = omd.GetModuleIdByName(@ModuleCode);

    IF @Debug = 'Y'
      PRINT 'For Module Code '+@ModuleCode+' the following Module Id was found in omd.MODULE: '+CONVERT(VARCHAR(10),@ModuleId);
  END



  -- Set new load window using Module Id
  BEGIN TRY

  IF 
    ( 
      SELECT 
        COALESCE 
        (
          (SELECT TOP 1
            NEXT_RUN_INDICATOR
          FROM omd.MODULE_INSTANCE main
          WHERE
              main.MODULE_ID=
          AND main.MODULE_INSTANCE_ID <> >
          ORDER BY main.MODULE_INSTANCE_ID DESC)
         , 'S') -- If there is no Module Instance Id 
    ) != 'R'

    INSERT INTO omd.[SOURCE_CONTROL]
    (
       [MODULE_INSTANCE_ID]
      ,[INSERT_DATETIME]
      ,[INTERVAL_START_DATETIME]
      ,[INTERVAL_END_DATETIME]
      ,[INTERVAL_START_IDENTIFIER]
      ,[INTERVAL_END_IDENTIFIER]
    )
    VALUES
    (
       @ModuleInstanceId
      ,SYSDATETIME()
      ,(  
         SELECT CONVERT(varchar,ISNULL(MAX(INTERVAL_END_DATETIME),'1900-01-01'),121) AS INTERVAL_START_DATETIME
         FROM omd.SOURCE_CONTROL A
         JOIN omd.MODULE_INSTANCE B ON (A.MODULE_INSTANCE_ID=B.MODULE_INSTANCE_ID)
         WHERE B.MODULE_ID = ?
       ) -- Maps to INTERVAL_START_DATETIME which is the last datetime of the previous window.
    , (
        SELECT COALESCE(MAX(OMD_INSERT_DATETIME),'1900-01-01')
        FROM [150_Persistent_Staging_Area].[dbo].[HSTG_PROFILER_CUSTOMER_PERSONAL] hstg
  JOIN omd.MODULE_INSTANCE modinst ON  hstg.OMD_INSERT_MODULE_INSTANCE_ID=modinst.MODULE_INSTANCE_ID
  WHERE EXECUTION_STATUS_CODE='S'
   ) -- Maps to INTERVAL_END_DATETIME
 ,NULL --INTERVAL_START_IDENTIFIER
 ,NULL --INTERVAL_END_IDENTIFIER
 )
                 


	IF @Debug = 'Y'
      PRINT 'A new Batch Instance Id '+CONVERT(VARCHAR(10),@BatchInstanceId)+' has been created for Batch Code: '+@BatchCode;

  END TRY
  BEGIN CATCH
	THROW
  END CATCH
  
END