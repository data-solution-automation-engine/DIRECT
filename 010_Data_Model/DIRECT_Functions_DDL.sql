


GO
/****** Object:  StoredProcedure [omd].[UpdateModuleInstance]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP PROCEDURE IF EXISTS [omd].[UpdateModuleInstance]
GO
/****** Object:  StoredProcedure [omd].[UpdateBatchInstance]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP PROCEDURE IF EXISTS [omd].[UpdateBatchInstance]
GO
/****** Object:  StoredProcedure [omd].[TableCondensing]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP PROCEDURE IF EXISTS [omd].[TableCondensing]
GO
/****** Object:  StoredProcedure [omd].[RunModule]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP PROCEDURE IF EXISTS [omd].[RunModule]
GO
/****** Object:  StoredProcedure [omd].[RunBatch]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP PROCEDURE IF EXISTS [omd].[RunBatch]
GO
/****** Object:  StoredProcedure [omd].[ModuleEvaluation]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP PROCEDURE IF EXISTS [omd].[ModuleEvaluation]
GO
/****** Object:  StoredProcedure [omd].[CreateModuleInstance]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP PROCEDURE IF EXISTS [omd].[CreateModuleInstance]
GO
/****** Object:  StoredProcedure [omd].[CreateBatchInstance]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP PROCEDURE IF EXISTS [omd].[CreateBatchInstance]
GO
/****** Object:  StoredProcedure [omd].[BatchEvaluation]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP PROCEDURE IF EXISTS [omd].[BatchEvaluation]
GO
/****** Object:  View [omd_reporting].[vw_MODULE_FAILURES]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_MODULE_FAILURES]
GO
/****** Object:  View [omd_reporting].[vw_EXECUTION_LOG_MODULE_INSTANCE]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_EXECUTION_LOG_MODULE_INSTANCE]
GO
/****** Object:  View [omd_reporting].[vw_EXECUTION_LOG_BATCH_INSTANCE]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_EXECUTION_LOG_BATCH_INSTANCE]
GO
/****** Object:  View [omd_reporting].[vw_EXECUTION_EVENT_LOG]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_EXECUTION_EVENT_LOG]
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_TABLE_CONSISTENCY]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_EXCEPTIONS_TABLE_CONSISTENCY]
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_MODULES]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_MODULES]
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_BATCHES]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_BATCHES]
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_MODULE]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_EXCEPTIONS_MODULE]
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_LONG_RUNNING_PROCESSES]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_EXCEPTIONS_LONG_RUNNING_PROCESSES]
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_DISABLED_PROCESSES]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_EXCEPTIONS_DISABLED_PROCESSES]
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_BATCH]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_EXCEPTIONS_BATCH]
GO
/****** Object:  View [omd_reporting].[vw_CUMULATIVE_LOAD_TIME]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_CUMULATIVE_LOAD_TIME]
GO
/****** Object:  View [omd_reporting].[vw_COMMON_ERRORS]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_reporting].[vw_COMMON_ERRORS]
GO
/****** Object:  View [omd_processing].[vw_QUEUE_MODULE_PROCESSING]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_processing].[vw_QUEUE_MODULE_PROCESSING]
GO
/****** Object:  View [omd_processing].[vw_QUEUE_BATCH_PROCESSING]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP VIEW IF EXISTS [omd_processing].[vw_QUEUE_BATCH_PROCESSING]
GO
/****** Object:  UserDefinedFunction [omd].[GetPreviousModuleInstanceDetails]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetPreviousModuleInstanceDetails]
GO
/****** Object:  UserDefinedFunction [omd].[GetPreviousBatchInstanceDetails]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetPreviousBatchInstanceDetails]
GO
/****** Object:  UserDefinedFunction [omd_processing].[GetDependentTables]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd_processing].[GetDependentTables]
GO
/****** Object:  UserDefinedFunction [omd].[GetModuleIdByName]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetModuleIdByName]
GO
/****** Object:  UserDefinedFunction [omd].[GetModuleIdByModuleInstanceId]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetModuleIdByModuleInstanceId]
GO
/****** Object:  UserDefinedFunction [omd].[GetLoadWindowModuleInstance]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetLoadWindowModuleInstance]
GO
/****** Object:  UserDefinedFunction [omd].[GetLoadWindowDateTimes]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetLoadWindowDateTimes]
GO
/****** Object:  UserDefinedFunction [omd].[GetFailedBatchIdList]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetFailedBatchIdList]
GO
/****** Object:  UserDefinedFunction [omd].[GetDependency]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetDependency]
GO
/****** Object:  UserDefinedFunction [omd].[GetConsistencyDateTime]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetConsistencyDateTime]
GO
/****** Object:  UserDefinedFunction [omd].[GetBatchModuleActiveIndicatorValue]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetBatchModuleActiveIndicatorValue]
GO
/****** Object:  UserDefinedFunction [omd].[GetBatchIdByName]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetBatchIdByName]
GO
/****** Object:  UserDefinedFunction [omd].[GetBatchIdByModuleInstanceId]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetBatchIdByModuleInstanceId]
GO
/****** Object:  UserDefinedFunction [omd].[GetBatchIdByBatchInstanceId]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[GetBatchIdByBatchInstanceId]
GO
/****** Object:  UserDefinedFunction [omd].[CalculateChangeKey]    Script Date: 2020-07-20 10:01:38 AM ******/
DROP FUNCTION IF EXISTS [omd].[CalculateChangeKey]
GO


DROP SCHEMA IF EXISTS [omd_processing];
GO

IF NOT EXISTS (SELECT * FROM sys.schemas s WHERE s.name='omd_processing')
EXEC ('CREATE SCHEMA [omd_processing]');
GO

DROP SCHEMA IF EXISTS [omd_reporting];
GO

IF NOT EXISTS (SELECT * FROM sys.schemas s WHERE s.name='omd_reporting')
EXEC ('CREATE SCHEMA [omd_reporting]');
GO

/****** Object:  StoredProcedure [omd].[UpdateBatchInstance]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Process: Update Batch Instance status
Purpose: Sets the various Batch Instance status codes based on input events.
Input: 
  - Batch Instance Id
  - Event Code (Process, Abort, Cancel, Rollback, Success or Failure)
  - Debug flag Y/N (default to N)
Returns:
  - Default Stored Procudure return code (no specific output)
Usage:
   EXEC [omd].[UpdateBatchInstance]
      @BatchInstanceId = <>,
	  @EventCode = '<>'
*/

CREATE PROCEDURE [omd].[UpdateBatchInstance]
	@BatchInstanceId INT,
	@EventCode VARCHAR(10) = 'None',
	@Debug VARCHAR(1) = 'Y'
AS

BEGIN	
	-- Abort event
	-- This is an end-state event (no further processing)
  IF @EventCode = 'Abort'
  BEGIN
	BEGIN TRY
	  IF @Debug='Y'
	    PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

	  UPDATE omd.BATCH_INSTANCE SET EXECUTION_STATUS_CODE = 'A', PROCESSING_INDICATOR = 'A', NEXT_RUN_INDICATOR = 'P', END_DATETIME = SYSDATETIME() WHERE BATCH_INSTANCE_ID = @BatchInstanceId
	END TRY
	BEGIN CATCH
	  THROW
	END CATCH
  END

  -- Skip / Cancel event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Cancel'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.BATCH_INSTANCE SET EXECUTION_STATUS_CODE = 'C', PROCESSING_INDICATOR = 'C', NEXT_RUN_INDICATOR = 'P', END_DATETIME = SYSDATETIME() WHERE BATCH_INSTANCE_ID = @BatchInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Success event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Success'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.BATCH_INSTANCE SET EXECUTION_STATUS_CODE = 'S', NEXT_RUN_INDICATOR = 'P', END_DATETIME=GETDATE() WHERE  BATCH_INSTANCE_ID = @BatchInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Failure event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Failure'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

        -- Note that the default behaviour is that Next Run Indicator at Batch level is 'P'.
		-- This will only skip/cancel already succesfully completed Modules when a failed Batch is rerun.
		UPDATE omd.BATCH_INSTANCE SET EXECUTION_STATUS_CODE = 'F', NEXT_RUN_INDICATOR = 'P', END_DATETIME=GETDATE() WHERE  BATCH_INSTANCE_ID = @BatchInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Rollback event
  IF @EventCode = 'Rollback'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.BATCH_INSTANCE SET PROCESSING_INDICATOR = 'R' WHERE BATCH_INSTANCE_ID = @BatchInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Proceed event
  IF @EventCode = 'Proceed'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Batch Instance '+CONVERT(VARCHAR(10),@BatchInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.BATCH_INSTANCE SET PROCESSING_INDICATOR = 'P' WHERE BATCH_INSTANCE_ID = @BatchInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Exception handling
  IF @EventCode NOT IN ('Proceed', 'Cancel', 'Abort', 'Rollback', 'Success', 'Failure')
    THROW 50000,'Incorrect Event Code specified. The available options are Proceed, Cancel, Abort, Success, Failure and Rollback',1

END
GO

/****** Object:  StoredProcedure [omd].[UpdateModuleInstance]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Process: Update Module Instance status
Purpose: Sets the various Module Instance status codes based on input events.
Input: 
  - Module Instance Id
  - Event Code (Process, Abort, Cancel, Rollback, Success or Failure)
  - Debug flag Y/N (default to N)
Returns:
  - Default Stored Procudure return code (no specific output)
Usage:
   EXEC [omd].[UpdateModuleInstance]
      @ModuleInstanceId = <>,
	  @EventCode = '<>'
*/

CREATE PROCEDURE [omd].[UpdateModuleInstance]
	@ModuleInstanceId INT,
	@EventCode VARCHAR(10) = 'None',
	@Debug VARCHAR(1) = 'Y'
AS

BEGIN	
	-- Abort event
	-- This is an end-state event (no further processing)
  IF @EventCode = 'Abort'
  BEGIN
	BEGIN TRY
	  IF @Debug='Y'
	    PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+'.';

	  UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'A', PROCESSING_INDICATOR = 'A', NEXT_RUN_INDICATOR = 'P', END_DATETIME = SYSDATETIME() WHERE MODULE_INSTANCE_ID = @ModuleInstanceId
	END TRY
	BEGIN CATCH
	  THROW
	END CATCH
  END

  -- Skip / Cancel event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Cancel'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'C', PROCESSING_INDICATOR = 'C', NEXT_RUN_INDICATOR = 'P', END_DATETIME = SYSDATETIME() WHERE MODULE_INSTANCE_ID = @ModuleInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Success event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Success'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'S', NEXT_RUN_INDICATOR = 'P', END_DATETIME=GETDATE() WHERE  MODULE_INSTANCE_ID = @ModuleInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Failure event
  -- This is an end-state event (no further processing)
  IF @EventCode = 'Failure'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.MODULE_INSTANCE SET EXECUTION_STATUS_CODE = 'F', NEXT_RUN_INDICATOR = 'R', END_DATETIME=GETDATE() WHERE  MODULE_INSTANCE_ID = @ModuleInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Rollback event
  IF @EventCode = 'Rollback'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.MODULE_INSTANCE set PROCESSING_INDICATOR = 'R' WHERE MODULE_INSTANCE_ID = @ModuleInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Proceed event
  IF @EventCode = 'Proceed'
	BEGIN
	  BEGIN TRY
	    IF @Debug='Y'
	      PRINT 'Setting Module Instance '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' to '+@EventCode+'.';

		UPDATE omd.MODULE_INSTANCE set PROCESSING_INDICATOR = 'P' WHERE MODULE_INSTANCE_ID = @ModuleInstanceId
	  END TRY
	  BEGIN CATCH
		THROW
	  END CATCH
    END

  -- Exception handling
  IF @EventCode NOT IN ('Proceed', 'Cancel', 'Abort', 'Rollback', 'Success', 'Failure')
    THROW 50000,'Incorrect Event Code specified. The available options are Proceed, Cancel, Abort, Success, Failure and Rollback',1

END
GO

/****** Object:  UserDefinedFunction [omd].[CalculateChangeKey]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [omd].[CalculateChangeKey](
    @change_datetime datetime2,
    @insert_module_id int,
    @insert_row_id int
)
returns numeric(38,0)
begin return (
---------------------------------------------------------------------------------------------------------

    select convert(numeric(38,0),
            left(replace(replace(replace(replace(convert(char(27), cast(@change_datetime as datetime2(7))), '-', ''), ' ', ''), ':', ''), '.', ''), 21)
            + right('0000000000' + convert(varchar(38), @insert_module_id), 10)   --,len(2147483647)
            + right('0000000' + convert(varchar(38), @insert_row_id), 7)) as OMD_CHANGE_KEY

---------------------------------------------------------------------------------------------------------
) end
GO
/****** Object:  UserDefinedFunction [omd].[GetBatchIdByBatchInstanceId]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [omd].[GetBatchIdByBatchInstanceId]
(
	@BatchInstanceId INT -- An instance of the Batch.
)
RETURNS INT AS

-- =============================================
-- Function: Get Batch Id (by Batch Instance Id)
-- Description:	Takes the Batch instance id as input and returns the Batch Id as registered in the framework
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @BatchId INT = 
	(
	  SELECT DISTINCT BatchInstance.Batch_ID
	  FROM omd.BATCH_INSTANCE BatchInstance
	  WHERE BatchInstance.BATCH_INSTANCE_ID = @BatchInstanceId
	)

	SET @BatchId = COALESCE(@BatchId,0)

	-- Return the result of the function
	RETURN @BatchId
END
GO
/****** Object:  UserDefinedFunction [omd].[GetBatchIdByModuleInstanceId]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [omd].[GetBatchIdByModuleInstanceId]
(
	@ModuleInstanceId INT -- An instance of the module.
)
RETURNS INT AS

-- =============================================
-- Function: Get Batch Id (by Module Instance Id)
-- Description:	Takes the module instance id as input and returns the Batch Id as registered in the framework
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @BatchId INT = 
	(
	  SELECT DISTINCT batchInstance.BATCH_ID
	  FROM omd.MODULE_INSTANCE moduleInstance
	  JOIN omd.BATCH_INSTANCE batchInstance ON moduleInstance.BATCH_INSTANCE_ID = batchInstance.BATCH_INSTANCE_ID
	  WHERE moduleInstance.MODULE_INSTANCE_ID = @ModuleInstanceId
	)

	SET @BatchId = COALESCE(@BatchId,0)

	-- Return the result of the function
	RETURN @BatchId
END
GO
/****** Object:  UserDefinedFunction [omd].[GetBatchIdByName]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [omd].[GetBatchIdByName]
(
	@BatchCode VARCHAR(255) -- The name of the batch, as identified in the BATCH_CODE attribute in the BATCH table.
)
RETURNS VARCHAR(255) AS

-- =============================================
-- Function: Get Batch Id (by name)
-- Description:	Takes the batch code as input and returns the Batch ID as registered in the framework
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @BatchId INT = 
	(
	  SELECT batch.Batch_ID
	  FROM omd.BATCH batch 
	  WHERE BATCH_CODE = @BatchCode
	)

	SET @BatchId = COALESCE(@BatchId,0)

	-- Return the result of the function
	RETURN @BatchId
END
GO
/****** Object:  UserDefinedFunction [omd].[GetBatchModuleActiveIndicatorValue]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [omd].[GetBatchModuleActiveIndicatorValue]
(
	@ModuleId INT,
	@BatchId INT
)
RETURNS VARCHAR(1) AS

-- =============================================
-- Function: Get the Batch/Module active/inactive flag.
-- Description:	Retrieve the Inactive Indicator (flag) for a Batch / Module combination.
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @InactiveIndicator VARCHAR(1)
	
	SET @InactiveIndicator = 
	(
      SELECT
        MIN(INACTIVE_INDICATOR)
      FROM
      (
        SELECT INACTIVE_INDICATOR
        FROM omd.BATCH_MODULE
        WHERE BATCH_ID = @BatchId AND MODULE_ID = @ModuleId
      	UNION
      	-- Return if there is nothing, to give at least a result row for further processing
        SELECT null
      ) sub
	)

	-- Return the result of the function
	RETURN @InactiveIndicator
END
GO
/****** Object:  UserDefinedFunction [omd].[GetConsistencyDateTime]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [omd].[GetConsistencyDateTime] ( @Table_List VARCHAR(MAX), @MeasurementDate datetime2(7))
RETURNS DATETIME2(7) AS 
BEGIN 

-- Input variables
--DECLARE @MeasurementDate DATETIME2(7) = GETDATE();
--DECLARE @Table_List VARCHAR(MAX) ='';
-- Output variables
DECLARE @Output DATETIME2(7);
-- Local variables
DECLARE @EligibleWindowsCount int = 0;
DECLARE @MaxDateTime DATETIME2(7);

-- Remove spaces and quotes
SET @Table_List = REPLACE(@Table_List,' ','');
SET @Table_List = REPLACE(@Table_List,'''','');

-- Splitting the Table_List variable array into rows
-- Would fail if passed a list of more than 100 tables
WITH cteSplits(starting_position, end_position)
AS     
(
    SELECT CAST(1 AS BIGINT), CHARINDEX(',', @Table_List)
    UNION ALL
    SELECT end_position + 1, charindex(',', @Table_List, end_position + 1)
    FROM cteSplits
    WHERE end_position > 0 -- Another delimiter was found
)
, table_names
AS     
(
SELECT DISTINCT DATA_STORE_CODE = substring(@Table_List, starting_position, CASE WHEN end_position = 0 
																				   THEN len(@Table_List)
																				   ELSE end_position - starting_position 
																				 END) 
FROM cteSplits
),
---- Calculate the output now the individual tables are available
ConsistencyCTE AS
(
SELECT * 
FROM (
	SELECT
		   sct.MODULE_INSTANCE_ID,
		   modinst.MODULE_ID,
		   modinst.EXECUTION_STATUS_CODE,
		   sct.INTERVAL_START_DATETIME,
		   sct.INTERVAL_END_DATETIME,
		   CASE	
			 WHEN sct.INTERVAL_START_DATETIME = sct.INTERVAL_END_DATETIME THEN 0
			 ELSE 1
		   END as CHANGE_DELTA_INDICATOR,
		   ROW_NUMBER() OVER (PARTITION BY COALESCE(modinst.MODULE_ID,0) ORDER BY modinst.MODULE_INSTANCE_ID DESC) AS ROW_ORDER
	FROM omd.MODULE_INSTANCE modinst
	JOIN omd.SOURCE_CONTROL sct ON modinst.MODULE_INSTANCE_ID = sct.MODULE_INSTANCE_ID
	JOIN omd.MODULE module ON modinst.MODULE_ID = module.MODULE_ID
	WHERE 1=1
	  AND module.INACTIVE_INDICATOR='N'
	  AND modinst.EXECUTION_STATUS_CODE = 'S'
	  AND sct.INTERVAL_END_DATETIME <= @MeasurementDate
	 -- AND modinst.MODULE_ID IN
	 -- (                   
		--SELECT omd.MODULE_DATA_STORE.MODULE_ID
		--FROM dbo.OMD_DATA_STORE
		--	INNER JOIN table_names ON LTRIM(table_names.DATA_STORE_CODE) = OMD_DATA_STORE.DATA_STORE_CODE
		--	INNER JOIN dbo.OMD_MODULE_DATA_STORE ON OMD_MODULE_DATA_STORE.DATA_STORE_ID = OMD_DATA_STORE.DATA_STORE_ID
	 --  )
	) sub
	WHERE ROW_ORDER=1
), ELIGIBLE_WINDOWS AS
(
	SELECT 
		SUM(CHANGE_DELTA_INDICATOR) AS ELIGIBILITY_COUNT, 
		MAX(INTERVAL_END_DATETIME) AS MAX_END_DATETIME,
		MAX(MODULE_INSTANCE_ID) AS MAX_MODULE_INSTANCE_ID		
	FROM ConsistencyCTE
)
SELECT @Output = 
	MIN
	(CASE 
		WHEN ELIGIBILITY_COUNT = 0 THEN MAX_END_DATETIME
		WHEN ELIGIBILITY_COUNT != 0 AND CHANGE_DELTA_INDICATOR = 1 THEN INTERVAL_END_DATETIME
	END)
	--MIN(CASE 
	--	WHEN ELIGIBILITY_COUNT = 0 THEN MAX_MODULE_INSTANCE_ID
	--	WHEN ELIGIBILITY_COUNT != 0 AND CHANGE_DELTA_INDICATOR = 1 THEN MODULE_INSTANCE_ID
	--END) AS CONSISTENCY_MODULE_INSTANCE_ID
FROM ConsistencyCTE 
CROSS JOIN ELIGIBLE_WINDOWS
-- If the eligibility count is 0 then MAX(INTERVAL_END_DATETIME)
-- If the eligbility count != 0 then remove all rows where START_DATETIME=END_DATETIME and select the MIN(INTERVAL_END_DATETIME) from this result


RETURN @Output;
END;
GO
/****** Object:  UserDefinedFunction [omd].[GetDependency]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [omd].[GetDependency] (@SchemaName VARCHAR(128), @Table VARCHAR(128))
RETURNS VARCHAR(MAX) AS 
BEGIN 

DECLARE @Output VARCHAR(MAX)

SELECT @Output =
''''+
stuff
(
	(
		SELECT DISTINCT ', ' + referenced_entity_name
		FROM sys.sql_expression_dependencies  t2
		WHERE referencing_id = OBJECT_ID(N''+@SchemaName+'.'+@Table+'')
        FOR XML PATH('')
	),
	1,
	1,
	''
)
+ ''''
SELECT @Output = LTRIM(RTRIM(@Output));

RETURN @Output;

END
GO
/****** Object:  UserDefinedFunction [omd].[GetFailedBatchIdList]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [omd].[GetFailedBatchIdList]
(
	@BatchId INT -- The array of previously failed Batch process relative to the input Batch Id.
)
RETURNS VARCHAR(MAX) AS

-- =============================================
-- Function: Get the list (array) of failed Batch Ids.
-- Description:	Takes the batch id as input and returns the failures prior to the Id (from the last previously successful execution).
--              In other words, the failed execution between the last succesful run and the current one.
-- =============================================

BEGIN

  DECLARE @BatchIdArray VARCHAR(MAX);

  SELECT @BatchIdArray = CAST('(' + STUFF
  (
      (SELECT ',' + CAST(BATCH_INSTANCE_ID AS VARCHAR(20))
      FROM omd.BATCH_INSTANCE 
      WHERE  BATCH_ID = @BatchId
      AND 
  	(
         BATCH_INSTANCE_ID > (SELECT MAX(BATCH_INSTANCE_ID) FROM omd.BATCH_INSTANCE WHERE BATCH_ID = @BatchId AND (EXECUTION_STATUS_CODE='S' AND NEXT_RUN_INDICATOR = 'P'))
        OR 
  	  (SELECT COUNT(BATCH_INSTANCE_ID) FROM omd.BATCH_INSTANCE WHERE BATCH_ID = @BatchId AND (EXECUTION_STATUS_CODE='S' AND NEXT_RUN_INDICATOR = 'P')) = 0
      )
      AND EXECUTION_STATUS_CODE<>'E'
      ORDER BY BATCH_INSTANCE_ID 
      FOR XML PATH ('')
      ),1,1,''
  ) + ')' AS VARCHAR(MAX))

  RETURN @BatchIdArray;
END

GO
/****** Object:  UserDefinedFunction [omd].[GetLoadWindowDateTimes]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [omd].[GetLoadWindowDateTimes] ( @module_code VARCHAR(255), @start_or_end tinyint)
RETURNS DATETIME2(7) AS 
BEGIN 
       DECLARE @result DATETIME2(7)
 
       IF @start_or_end = 1  
       BEGIN
              SELECT @result= INTERVAL_START_DATETIME
              FROM
              (
                 SELECT 
                 sct.MODULE_INSTANCE_ID, 
                 INTERVAL_START_DATETIME, 
                 INTERVAL_END_DATETIME,
                 ROW_NUMBER() OVER (PARTITION BY MODULE_ID ORDER BY INSERT_DATETIME DESC) AS ROW_NR 
              FROM omd.SOURCE_CONTROL sct
              JOIN omd.MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
              WHERE MODULE_ID = (SELECT MODULE_ID FROM omd.MODULE WHERE MODULE_CODE=@module_code)
              ) ranksub
              WHERE ROW_NR=1
       END
       ELSE IF @start_or_end = 2
       BEGIN
              SELECT @result= INTERVAL_END_DATETIME
              FROM
              (
                 SELECT 
                 sct.MODULE_INSTANCE_ID, 
                 INTERVAL_START_DATETIME, 
                 INTERVAL_END_DATETIME,
                 ROW_NUMBER() OVER (PARTITION BY MODULE_ID ORDER BY INSERT_DATETIME DESC) AS ROW_NR 
              FROM omd.SOURCE_CONTROL sct
              JOIN omd.MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
              WHERE MODULE_ID = (SELECT MODULE_ID FROM omd.MODULE WHERE MODULE_CODE = @module_code)
              ) ranksub
              WHERE ROW_NR=1
       END
       return @result
END
GO
/****** Object:  UserDefinedFunction [omd].[GetLoadWindowModuleInstance]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [omd].[GetLoadWindowModuleInstance] ( @module_code VARCHAR(255), @start_or_end tinyint)
RETURNS BIGINT AS 
BEGIN 
       DECLARE @result BIGINT
 
       IF @start_or_end = 1  
       BEGIN
              SELECT @result = ranksub.INTERVAL_START_IDENTIFIER
              FROM
              (
                 SELECT 
                 sct.MODULE_INSTANCE_ID, 
                 sct.INTERVAL_START_IDENTIFIER, 
                 sct.INTERVAL_END_IDENTIFIER,
                 ROW_NUMBER() OVER (PARTITION BY MODULE_ID ORDER BY INSERT_DATETIME DESC) AS ROW_NR 
              FROM omd.SOURCE_CONTROL sct
              JOIN omd.MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
              WHERE MODULE_ID = (SELECT MODULE_ID FROM omd.MODULE module WHERE module.MODULE_CODE=@module_code)
              ) ranksub
              WHERE ROW_NR=1
       END
       ELSE IF @start_or_end = 2
       BEGIN
              SELECT @result= INTERVAL_END_IDENTIFIER
              FROM
              (
                 SELECT 
                   sct.MODULE_INSTANCE_ID, 
                   sct.INTERVAL_START_IDENTIFIER, 
                   sct.INTERVAL_END_IDENTIFIER,
                   ROW_NUMBER() OVER (PARTITION BY modinst.MODULE_ID ORDER BY sct.INSERT_DATETIME DESC) AS ROW_NR 
                 FROM omd.SOURCE_CONTROL sct
                 JOIN omd.MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID = modinst.MODULE_INSTANCE_ID
                 WHERE MODULE_ID=(SELECT MODULE_ID FROM omd.MODULE module WHERE module.MODULE_CODE = @module_code)
              ) ranksub
              WHERE ROW_NR=1
       END
       return @result
END
GO
/****** Object:  UserDefinedFunction [omd].[GetModuleIdByModuleInstanceId]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [omd].[GetModuleIdByModuleInstanceId]
(
	@ModuleInstanceId INT -- An instance of the module.
)
RETURNS INT AS

-- =============================================
-- Function: Get Module Id (by Module Instance Id)
-- Description:	Takes the module instance id as input and returns the Module Id as registered in the framework
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @ModuleId INT = 
	(
	  SELECT DISTINCT moduleInstance.MODULE_ID
	  FROM omd.MODULE_INSTANCE moduleInstance
	  WHERE moduleInstance.MODULE_INSTANCE_ID = @ModuleInstanceId
	)

	SET @ModuleId = COALESCE(@ModuleId,0)

	-- Return the result of the function
	RETURN @ModuleId
END
GO
/****** Object:  UserDefinedFunction [omd].[GetModuleIdByName]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [omd].[GetModuleIdByName]
(
	@ModuleCode VARCHAR(255) -- The name of the module, as identified in the MODULE_CODE attribute in the MODULE table.
)
RETURNS VARCHAR(255) AS

-- =============================================
-- Function: Get Module Id (by name)
-- Description:	Takes the module code as input and returns the Module ID as registered in the framework
-- =============================================

BEGIN
	-- Declare ouput variable

	DECLARE @ModuleId INT = 
	(
	  SELECT module.MODULE_ID
	  FROM omd.MODULE module 
	  WHERE MODULE_CODE = @ModuleCode
	)

	SET @ModuleId = COALESCE(@ModuleId,0)

	-- Return the result of the function
	RETURN @ModuleId
END
GO
/****** Object:  UserDefinedFunction [omd_processing].[GetDependentTables]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [omd_processing].[GetDependentTables] (
    @schema_name sysname,
    @object_name sysname
    )
/***
Purpose: Returns the underlying tables on which the specified object depends.
       - If the provided object is a table, then will simply reflect that table name.
Notes: - Works recursively where found dependencies which are not a table.
       - As this procedure does not traverse dependencies through packages. Only local tables 
         which are accessed by the query which loads the specified target are returned.
***/
returns @rtnTbl table (
    referenced_schema_name sysname not null,
    referenced_object_name sysname not null
    )
as
begin
-----------------------------------------------------------------------------------------------------------

with allDeps
as (
    select sql_expression_dependencies.referencing_id,
        object_schema_name(sql_expression_dependencies.referencing_id) as referencing_schema_name,
        object_name(sql_expression_dependencies.referencing_id) as referencing_entity_name,
        pre_calc.referenced_schema_name,
        sql_expression_dependencies.referenced_entity_name,
        objects.[type_desc] as referenced_type_desc
    from sys.sql_expression_dependencies
        outer apply (
                select coalesce(sql_expression_dependencies.referenced_database_name, db_name()) as referenced_database_name,
                    coalesce(sql_expression_dependencies.referenced_schema_name, 'dbo') as referenced_schema_name
                ) pre_calc
        inner join sys.objects
            on objects.[object_id] = sql_expression_dependencies.referenced_id
    where pre_calc.referenced_database_name = db_name() /* object dependencies are expected to never be cross-database */
        and object_schema_name(sql_expression_dependencies.referencing_id) not like N'omd%'
        and object_schema_name(sql_expression_dependencies.referencing_id) not in (N'tSQLt')
        and object_schema_name(sql_expression_dependencies.referencing_id) not like N'test%'
        and not exists ( /* excluded table self-dependencies, such as from calculated columns */
                select null
                from sys.objects start_type
                where start_type.[object_id] = sql_expression_dependencies.referencing_id
                    and start_type.[type_desc] in ('USER_TABLE', 'SYNONYM')
                )
    group by sql_expression_dependencies.referencing_id,
        pre_calc.referenced_schema_name,
        sql_expression_dependencies.referenced_entity_name,
        objects.[type_desc]
    )
, recursiveCTE
as  (
        select referencing_schema_name,
            referencing_entity_name,
            referenced_schema_name,
            referenced_entity_name,
            referenced_type_desc
        from allDeps
        where allDeps.referencing_id = object_id(@schema_name + N'.' + @object_name)
    union all
        select recursiveCTE.referencing_schema_name as referencing_schema_name,
            recursiveCTE.referencing_entity_name as referencing_entity_name,
            allDeps.referenced_schema_name,
            allDeps.referenced_entity_name,
            allDeps.referenced_type_desc
        from recursiveCTE
            inner join allDeps
                on allDeps.referencing_schema_name = recursiveCTE.referenced_schema_name
                and allDeps.referencing_entity_name = recursiveCTE.referenced_entity_name
        where recursiveCTE.referenced_type_desc not in ('USER_TABLE', 'SYNONYM')
    )

/* add to returned results table */
insert into @rtnTbl
    select referenced_schema_name as REFERENCED_SCHEMA_NAME,
        referenced_entity_name as REFERENCED_OBJECT_NAME
    from recursiveCTE
    where recursiveCTE.referenced_type_desc in ('USER_TABLE', 'SYNONYM')
union
    select @schema_name as REFERENCED_SCHEMA_NAME,
        @object_name as REFERENCED_OBJECT_NAME
    from sys.tables
    where tables.[object_id] = object_id(@schema_name + N'.' + @object_name)
union
    select @schema_name as REFERENCED_SCHEMA_NAME,
        @object_name as REFERENCED_OBJECT_NAME
    from sys.synonyms
    where synonyms.[object_id] = object_id(@schema_name + N'.' + @object_name)
;

return;
-----------------------------------------------------------------------------------------------------------
end
GO
/****** Object:  UserDefinedFunction [omd].[GetPreviousBatchInstanceDetails]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [omd].[GetPreviousBatchInstanceDetails]
(	
	@BatchId INT
)
RETURNS TABLE 
AS
RETURN 
(        
  SELECT 
    ISNULL(MAX(A.EXECUTION_STATUS_CODE),'S') AS PREVIOUS_EXECUTION_STATUS_CODE,
	ISNULL(MAX(A.NEXT_RUN_INDICATOR),'P') AS PREVIOUS_NEXT_RUN_INDICATOR
  FROM
    (
    SELECT 
        NEXT_RUN_INDICATOR, 
        EXECUTION_STATUS_CODE
    FROM omd.BATCH_INSTANCE 
    WHERE BATCH_ID =  @BatchId AND END_DATETIME = (select MAX(END_DATETIME) from omd.BATCH_INSTANCE where BATCH_ID = @BatchId)
    )A               
)
GO
/****** Object:  UserDefinedFunction [omd].[GetPreviousModuleInstanceDetails]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [omd].[GetPreviousModuleInstanceDetails]
(	
	@ModuleId INT,
	@BatchId INT
)
RETURNS TABLE 
AS
RETURN 
(
	--DECLARE @MODULE_ID INT = 2
	--DECLARE @BATCH_ID INT = 0 -- zero 0 if it is not executed by a batch
                    
	SELECT 
	  IsNull(Max(LastBatchInstanceID),-1)             AS 'LastBatchInstanceID'
	 ,IsNull(Max(LastModuleInstanceID),-1)            AS 'LastModuleInstanceID'
	 ,IsNull(Max(LastStartDateTime),'1900-01-01')     AS 'LastStartTime'
	 ,Max(LastEndDateTime)                            AS 'LastEndTime'
	 ,IsNull(Max(LastExecutionStatus),'I')            AS 'LastExecutionStatus'
	 ,IsNull(Max(LastNextRunIndicator),'P')           AS 'LastNextExecutionFlag'
	 ,ISNULL(Max(LastModuleInstanceIDList),'-1')      AS 'LastModuleInstanceIDList'
	 ,(SELECT INACTIVE_INDICATOR FROM omd.MODULE WHERE MODULE_ID = @ModuleId) AS InactiveIndicator
	FROM
	(
			(
                        
		SELECT 
						A.BATCH_INSTANCE_ID        AS 'LastBatchInstanceID', 
						A.MODULE_INSTANCE_ID       AS 'LastModuleInstanceID', 
						A.START_DATETIME           AS 'LastStartDateTime',
						A.END_DATETIME             AS 'LastEndDateTime',
						A.EXECUTION_STATUS_CODE    AS 'LastExecutionStatus', 
						A.NEXT_RUN_INDICATOR       AS 'LastNextRunIndicator',
						(SELECT Cast(
						'(' + 
				STUFF
				(
											(
					Select ',' + CAST(MODULE_INSTANCE_ID AS VARCHAR(20))
					From  omd.MODULE_INSTANCE MI
						LEFT JOIN omd.BATCH_INSTANCE BI
					ON MI.BATCH_INSTANCE_ID = BI.BATCH_INSTANCE_ID
					Where MI.MODULE_ID = @ModuleId
						AND ISNULL(BI.BATCH_ID, 0) = @BatchId --only instance from the same batch / 0
					AND MI.MODULE_INSTANCE_ID >
					(
					-- Find the last successful module run/batch run depending on if it is executed by a batch or not
					SELECT ISNULL(MAX(MODULE_INSTANCE_ID),0) 
						FROM omd.MODULE_INSTANCE SUB_MI
						LEFT JOIN omd.BATCH_INSTANCE SUB_BI
						ON SUB_MI.BATCH_INSTANCE_ID = SUB_BI.BATCH_INSTANCE_ID
						WHERE SUB_MI.MODULE_ID=@ModuleId                     
						AND ISNULL(SUB_BI.BATCH_ID, 0) = @BatchId --only instance from the same batch / 0
						AND 
						(
						(
						--last successful module run without a batch
						@BatchId = 0
						AND SUB_MI.EXECUTION_STATUS_CODE='S' 
						AND SUB_MI.NEXT_RUN_INDICATOR = 'P'
					)
					OR
					(
						--last successful batch run
						@BatchId <> 0
						AND SUB_BI.EXECUTION_STATUS_CODE='S' 
					) 
						)
					)
				AND MI.EXECUTION_STATUS_CODE<>'E'
				FOR XML PATH ('')  -- convert list module id to single variable
				)
				,1,1,''
										) 
				+ ')' as varchar(500)
				)
			) AS 'LastModuleInstanceIDList'
                    
					FROM omd.MODULE_INSTANCE A
                    
					WHERE A.MODULE_INSTANCE_ID = 
						(
							(
			select max(MODULE_INSTANCE_ID) 
								from omd.MODULE_INSTANCE WMI
				LEFT JOIN omd.BATCH_INSTANCE WBI
				ON WMI.BATCH_INSTANCE_ID = WBI.BATCH_INSTANCE_ID
								where WMI.MODULE_ID = @ModuleId
					AND WMI.EXECUTION_STATUS_CODE <> 'E'
				AND ISNULL(WBI.BATCH_ID, 0) = @BatchId --only instance from the same batch / 0
			)                
						)
			)
                           
		UNION ALL -- return if there is nothing, to give at least a result.
                           
		SELECT Null, Null, Null, Null, Null, Null,Null
	) as sub1
     
)
GO
/****** Object:  View [omd_processing].[vw_QUEUE_BATCH_PROCESSING]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [omd_processing].[vw_QUEUE_BATCH_PROCESSING] AS
SELECT 
       batch.BATCH_ID, 
       batch.BATCH_CODE+'.dtsx' AS ETL_PROCESS_NAME, 
       COALESCE(END_DATETIME,'1900-01-01') AS END_DATETIME,
       ROW_NUMBER() OVER( ORDER BY END_DATETIME) QUEUE_ORDER
FROM omd.BATCH batch 
LEFT OUTER JOIN omd.BATCH_INSTANCE main ON main.BATCH_ID=batch.BATCH_ID
LEFT JOIN 
(
       SELECT batch.BATCH_ID, COALESCE(MAX(BATCH_INSTANCE_ID),0) MOST_RECENT_EXECUTION_BATCH_ID 
       FROM omd.BATCH batch
       LEFT JOIN omd.BATCH_INSTANCE batch_instance ON batch.BATCH_ID=batch_instance.BATCH_ID
       WHERE batch.BATCH_ID<>0
       GROUP BY batch.BATCH_ID
) most_recent
ON batch.BATCH_ID = most_recent.BATCH_ID AND COALESCE(main.BATCH_INSTANCE_ID,0) = most_recent.MOST_RECENT_EXECUTION_BATCH_ID 
WHERE batch.BATCH_ID<>0
AND batch.INACTIVE_INDICATOR='N'
AND batch.FREQUENCY_CODE='Queue'
AND (MOST_RECENT_EXECUTION_BATCH_ID IS NOT NULL OR MOST_RECENT_EXECUTION_BATCH_ID=0)
AND NOT EXISTS (SELECT null FROM SSISDB.catalog.executions WHERE executions.end_time IS NULL and executions.package_name = batch.BATCH_CODE + '.dtsx' COLLATE DATABASE_DEFAULT)
AND COALESCE(EXECUTION_STATUS_CODE,'S')!='E';
GO
/****** Object:  View [omd_processing].[vw_QUEUE_MODULE_PROCESSING]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/* Created separately due to reliance on SSISDB */

CREATE VIEW [omd_processing].[vw_QUEUE_MODULE_PROCESSING]
AS

SELECT MODULE_ID, 
	ETL_PROCESS_NAME, 
	END_DATETIME,
	ROW_NUMBER() OVER( ORDER BY END_DATETIME) QUEUE_ORDER
FROM (
	SELECT 
		   MODULE.MODULE_ID, 
		   MODULE.MODULE_CODE,
		   MODULE.MODULE_CODE+'.dtsx' AS ETL_PROCESS_NAME, 
		   COALESCE(END_DATETIME,'1900-01-01') AS END_DATETIME,
		   COALESCE(EXECUTION_STATUS_CODE,'S') AS EXECUTION_STATUS_CODE,
		   ROW_NUMBER() OVER(PARTITION BY MODULE.DATA_OBJECT_TARGET ORDER BY CASE COALESCE(EXECUTION_STATUS_CODE,'S') WHEN 'E' THEN 1 ELSE 2 END, END_DATETIME) BY_DATA_STORE
	FROM omd.MODULE MODULE
		LEFT JOIN omd.MODULE_INSTANCE main
				ON main.MODULE_ID=MODULE.MODULE_ID
		LEFT JOIN (
				SELECT MODULE.MODULE_ID, COALESCE(MAX(MODULE_INSTANCE_ID),0) MOST_RECENT_EXECUTION_MODULE_ID 
				FROM omd.MODULE MODULE
					LEFT JOIN omd.MODULE_INSTANCE MODULE_instance
							ON MODULE.MODULE_ID=MODULE_instance.MODULE_ID
				WHERE MODULE.MODULE_ID<>0
				GROUP BY MODULE.MODULE_ID
				) most_recent
				ON MODULE.MODULE_ID = most_recent.MODULE_ID AND COALESCE(main.MODULE_INSTANCE_ID,0) = most_recent.MOST_RECENT_EXECUTION_MODULE_ID 
	WHERE MODULE.INACTIVE_INDICATOR = 'N'
		AND MODULE.AREA_CODE = 'INT'
		AND MODULE.FREQUENCY_CODE = 'Queue'
		AND MODULE.MODULE_ID <> 0
		AND (MOST_RECENT_EXECUTION_MODULE_ID IS NOT NULL OR MOST_RECENT_EXECUTION_MODULE_ID=0)
	) as sq
WHERE BY_DATA_STORE = 1
	AND EXECUTION_STATUS_CODE != 'E'
	AND NOT EXISTS (SELECT package_name FROM SSISDB.[catalog].executions jobs WHERE end_time IS NULL and jobs.package_name = MODULE_CODE + '.dtsx' COLLATE DATABASE_DEFAULT)
GO
/****** Object:  View [omd_reporting].[vw_COMMON_ERRORS]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_COMMON_ERRORS] AS
select                    m.MODULE_CODE
                                                ,m.MODULE_DESCRIPTION
                                                ,CASE WHEN UPPER(error.ERROR_MSG) LIKE '%TEMPDB%' THEN 'TempDB'
                                                                  WHEN error.ERROR_MSG LIKE '%WinSCP%' THEN 'WinSCP'
                                                                  WHEN error.ERROR_MSG LIKE '%deadlocked%' THEN 'Dead Lock'
                                                                  WHEN error.ERROR_MSG LIKE '%duplicate key%' THEN 'Duplicate Key'

                                                                  ELSE REPLACE(error.ERROR_MSG,'&#x0D;','')
                                                END AS ERROR_MSG
                                                ,count(*) AS COUNT
from                      omd.MODULE m
join                        (
                                                                select                    mi.MODULE_ID
                                                                                                                ,mi.MODULE_INSTANCE_ID
                                                                                                                ,mi.BATCH_INSTANCE_ID
                                                                                                                ,(             SELECT EVENT_DETAIL+''
                                                                                                                                from omd.EVENT_LOG sub 
                                                                                                                                where sub.MODULE_INSTANCE_ID = mi.MODULE_INSTANCE_ID
                                                                                                                                and          sub.BATCH_INSTANCE_ID = mi.BATCH_INSTANCE_ID
                                                                                                                                and          sub.EVENT_DATETIME> dateadd(MONTH,-1,getdate())
                                                                                                                                for xml path ('') ) as ERROR_MSG
                                                                from                      omd.MODULE_INSTANCE mi
                                                                WHERE                 mi.START_DATETIME> dateadd(MONTH,-1,getdate())
                                                                group by              mi.MODULE_ID,mi.MODULE_INSTANCE_ID, mi.BATCH_INSTANCE_ID
                                                ) error
on                                           error.MODULE_ID = m.MODULE_ID
and                                        rtrim(ERROR_MSG) <> ''
group by m.MODULE_CODE, m.MODULE_DESCRIPTION, error.ERROR_MSG
--order by 4 desc
GO
/****** Object:  View [omd_reporting].[vw_CUMULATIVE_LOAD_TIME]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [omd_reporting].[vw_CUMULATIVE_LOAD_TIME]
/***
Purpose: List accumulated load times for all modules. Handles if a table 
         has been reloaded.
***/
as

with pre_formatting
as  (
    select MODULE.MODULE_CODE,
        count(*) as instances_run,
        sum(datediff(second, MODULE_INSTANCE.START_DATETIME, coalesce(MODULE_INSTANCE.END_DATETIME, getdate()))) as duration_sec,
        sum(cast(MODULE_INSTANCE.ROWS_INSERTED as bigint)) as rows_transferred
    from omd.MODULE
    inner join omd.MODULE_INSTANCE on omd.MODULE_INSTANCE.MODULE_ID = omd.MODULE.MODULE_ID
    inner join (
                select 
                    MODULE_INSTANCE.MODULE_ID
                  , max(SOURCE_CONTROL.MODULE_INSTANCE_ID) as MODULE_INSTANCE_ID
                from omd.SOURCE_CONTROL
                inner join omd.MODULE_INSTANCE on omd.MODULE_INSTANCE.MODULE_INSTANCE_ID = omd.SOURCE_CONTROL.MODULE_INSTANCE_ID
                where omd.SOURCE_CONTROL.INTERVAL_START_DATETIME = '1900-01-01 00:00:00.0000000'
                group by MODULE_INSTANCE.MODULE_ID
                ) last_reloaded
            on last_reloaded.MODULE_ID = MODULE_INSTANCE.MODULE_ID
            and last_reloaded.MODULE_INSTANCE_ID <= MODULE_INSTANCE.MODULE_INSTANCE_ID
    group by omd.MODULE.MODULE_CODE
    )

select
    MODULE_CODE,
    instances_run,
    duration_sec,
    isnull(cast(nullif(datepart(day, dateadd(second, duration_sec, 0)), 1) - 1 as varchar(10)) + ' days ', '')
        +  convert(varchar(30), dateadd(second, duration_sec, 0), 108) as duration,
    rows_transferred
from pre_formatting;
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_BATCH]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_EXCEPTIONS_BATCH] AS 

SELECT
    batch.BATCH_CODE,
    main.EXECUTION_STATUS_CODE,
    main.BATCH_INSTANCE_ID AS MOST_RECENT_BATCH_INSTANCE_ID,
    main.START_DATETIME,
    main.END_DATETIME
FROM omd.BATCH_INSTANCE main
JOIN omd.BATCH batch ON main.BATCH_ID=batch.BATCH_ID
JOIN
    (
        SELECT BATCH_ID, MAX(BATCH_INSTANCE_ID) as MAX_BATCH_INSTANCE_ID
        FROM omd.BATCH_INSTANCE
        WHERE BATCH_ID>0
        GROUP BY BATCH_ID
    ) maxsub
ON  main.BATCH_ID = maxsub.BATCH_ID
AND main.BATCH_INSTANCE_ID=maxsub.MAX_BATCH_INSTANCE_ID
WHERE main.EXECUTION_STATUS_CODE<>'S' AND batch.INACTIVE_INDICATOR='N'
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_DISABLED_PROCESSES]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_EXCEPTIONS_DISABLED_PROCESSES] AS
--Show which modules haven't run in the last 60 days
SELECT
    MODULE_ID,
    MODULE_CODE,
    'Module' AS CLASSIFICATION,
    FREQUENCY_CODE,
    MODULE_DESCRIPTION AS ADDITIONAL_INFORMATION
FROM omd.MODULE WHERE INACTIVE_INDICATOR='Y'
UNION ALL
SELECT
    BATCH_ID,
    BATCH_CODE,
    'Batch' AS CLASSIFICATION,
    FREQUENCY_CODE,
    BATCH_DESCRIPTION AS ADDITIONAL_INFORMATION
FROM omd.BATCH WHERE INACTIVE_INDICATOR='Y'
  UNION ALL
SELECT
    batchmod.MODULE_ID,
    module.MODULE_CODE,
    'Module, disabled at Batch/Module level' AS CLASSIFICATION,
    'Not applicable' AS FREQUENCY_CODE,
    'Disabled within Batch '''+batch.BATCH_CODE+''' with Batch ID '+CONVERT(VARCHAR(100),batchmod.BATCH_ID )
FROM omd.BATCH_MODULE batchmod
JOIN omd.MODULE module ON batchmod.MODULE_ID=module.MODULE_ID
JOIN omd.BATCH batch ON batchmod.BATCH_ID=batch.BATCH_ID
WHERE batchmod.INACTIVE_INDICATOR='Y'
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_LONG_RUNNING_PROCESSES]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_EXCEPTIONS_LONG_RUNNING_PROCESSES] AS
-- Module level
SELECT
    module.MODULE_CODE,
    main.EXECUTION_STATUS_CODE,
    main.BATCH_INSTANCE_ID,
    CONVERT(VARCHAR(100),main.MODULE_INSTANCE_ID) AS MODULE_INSTANCE_ID,
    CONVERT(VARCHAR(100),main.MODULE_ID) AS MODULE_ID,
    main.START_DATETIME,
    main.END_DATETIME,
                DATEDIFF(HOUR,main.START_DATETIME, COALESCE(END_DATETIME,GETDATE())) AS HOURS_DIFFERENCE
FROM omd.MODULE_INSTANCE main
JOIN omd.MODULE module ON main.MODULE_ID=module.MODULE_ID
WHERE main.EXECUTION_STATUS_CODE='E'
AND DATEDIFF(HOUR,main.START_DATETIME, COALESCE(END_DATETIME,GETDATE()))>=4
UNION
-- Batch level
SELECT
    batch.BATCH_CODE,
    main.EXECUTION_STATUS_CODE,
    main.BATCH_INSTANCE_ID,
                'N/A' AS MODULE_INSTANCE_ID,
                'N/A' AS MODULE_ID,
                main.START_DATETIME,
    main.END_DATETIME,
                DATEDIFF(HOUR,main.START_DATETIME, COALESCE(END_DATETIME,GETDATE())) AS HOURS_DIFFERENCE
FROM omd.BATCH_INSTANCE main
JOIN omd.BATCH batch ON main.BATCH_ID=batch.BATCH_ID
WHERE main.EXECUTION_STATUS_CODE='E'
AND DATEDIFF(HOUR,main.START_DATETIME, COALESCE(END_DATETIME,GETDATE()))>=8
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_MODULE]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_EXCEPTIONS_MODULE] AS

-- Exception check Module level
SELECT
    module.MODULE_CODE,
    main.EXECUTION_STATUS_CODE,
    main.BATCH_INSTANCE_ID,
    batch.BATCH_CODE,
    main.MODULE_INSTANCE_ID AS MOST_RECENT_MODULE_INSTANCE_ID,
    main.MODULE_ID,
    main.START_DATETIME,
    main.END_DATETIME
FROM omd.MODULE_INSTANCE main
    JOIN omd.MODULE module
        ON main.MODULE_ID=module.MODULE_ID
    JOIN (
            SELECT MODULE_ID, MAX(MODULE_INSTANCE_ID) as MAX_MODULE_INSTANCE_ID
            FROM omd.MODULE_INSTANCE
            WHERE MODULE_ID>0
            GROUP BY MODULE_ID
        ) maxsub
        ON main.MODULE_ID=maxsub.MODULE_ID
        AND main.MODULE_INSTANCE_ID=maxsub.MAX_MODULE_INSTANCE_ID
    JOIN omd.BATCH_INSTANCE
        ON main.BATCH_INSTANCE_ID=omd.BATCH_INSTANCE.BATCH_INSTANCE_ID
    JOIN omd.BATCH batch
        ON omd.BATCH_INSTANCE.BATCH_ID=batch.BATCH_ID
WHERE main.EXECUTION_STATUS_CODE<>'S'
    AND module.INACTIVE_INDICATOR='N'
--  AND MODULE_CODE NOT LIKE '%\_E5\_%' ESCAPE '\'
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_BATCHES]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_BATCHES] AS
SELECT
    BATCH.BATCH_CODE,
    BATCH.BATCH_ID,
    BATCH.BATCH_DESCRIPTION,
    main.BATCH_INSTANCE_ID AS MOST_RECENT_BATCH_INSTANCE_ID,
    main.START_DATETIME,
    main.END_DATETIME,
    main.EXECUTION_STATUS_CODE
FROM omd.BATCH_INSTANCE main
JOIN omd.BATCH BATCH ON main.BATCH_ID=BATCH.BATCH_ID
JOIN
    (
        SELECT BATCH_ID, MAX(BATCH_INSTANCE_ID) as MAX_BATCH_INSTANCE_ID
        FROM omd.BATCH_INSTANCE
        WHERE BATCH_ID>0
        GROUP BY BATCH_ID
    ) maxsub
ON main.BATCH_ID=maxsub.BATCH_ID
AND main.BATCH_INSTANCE_ID=maxsub.MAX_BATCH_INSTANCE_ID
WHERE DATEDIFF(dd,START_DATETIME, GETDATE())>=60
AND INACTIVE_INDICATOR='N'
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_MODULES]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_EXCEPTIONS_NON_RUNNING_MODULES] AS
SELECT
    module.MODULE_CODE,
    module.MODULE_ID,
    module.MODULE_DESCRIPTION,
    main.MODULE_INSTANCE_ID AS MOST_RECENT_MODULE_INSTANCE_ID,
    main.START_DATETIME,
    main.END_DATETIME,
    main.EXECUTION_STATUS_CODE
FROM omd.MODULE_INSTANCE main
JOIN omd.MODULE module ON main.MODULE_ID=module.MODULE_ID
JOIN
    (
        SELECT MODULE_ID, MAX(MODULE_INSTANCE_ID) as MAX_MODULE_INSTANCE_ID
        FROM omd.MODULE_INSTANCE
        WHERE MODULE_ID>0
        GROUP BY MODULE_ID
    ) maxsub
ON main.MODULE_ID=maxsub.MODULE_ID
AND main.MODULE_INSTANCE_ID=maxsub.MAX_MODULE_INSTANCE_ID
WHERE DATEDIFF(dd,START_DATETIME, GETDATE())>=60
AND INACTIVE_INDICATOR='N'
GO
/****** Object:  View [omd_reporting].[vw_EXCEPTIONS_TABLE_CONSISTENCY]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_EXCEPTIONS_TABLE_CONSISTENCY] AS
WITH TableCheckCTE AS
(
SELECT
                a.TABLE_CATALOG,
                a.TABLE_SCHEMA,
                a.TABLE_NAME,
                b.COLUMN_NAME,
                b.ORDINAL_POSITION
FROM INFORMATION_SCHEMA.TABLES a 
JOIN  INFORMATION_SCHEMA.COLUMNS b ON a.TABLE_NAME=b.TABLE_NAME
WHERE TABLE_TYPE='BASE TABLE' AND a.TABLE_SCHEMA <> 'omd'
), Attribute_Detection AS
(
SELECT 
                TABLE_CATALOG,
                TABLE_NAME,
                TABLE_SCHEMA,
                COLUMN_NAME,
                CASE WHEN COLUMN_NAME = 'OMD_INSERT_MODULE_INSTANCE_ID' THEN 1 ELSE 0 END AS HAS_OMD_INSERT_MODULE_INSTANCE_ID,
                CASE WHEN COLUMN_NAME = 'OMD_INSERT_DATETIME' THEN 1 ELSE 0 END AS HAS_OMD_INSERT_DATETIME,
                CASE WHEN COLUMN_NAME = 'OMD_EVENT_DATETIME' THEN 1 ELSE 0 END AS HAS_OMD_EVENT_DATETIME,
                CASE WHEN COLUMN_NAME = 'OMD_RECORD_SOURCE' THEN 1 ELSE 0 END AS HAS_OMD_RECORD_SOURCE,
                CASE WHEN COLUMN_NAME = 'OMD_SOURCE_ROW_ID' THEN 1 ELSE 0 END AS HAS_OMD_SOURCE_ROW_ID,
                CASE WHEN COLUMN_NAME = 'OMD_CDC_OPERATION' THEN 1 ELSE 0 END AS HAS_OMD_CDC_OPERATION,
                CASE WHEN COLUMN_NAME = 'OMD_HASH_FULL_RECORD' THEN 1 ELSE 0 END AS HAS_OMD_HASH_FULL_RECORD,
                CASE WHEN COLUMN_NAME = 'OMD_CURRENT_RECORD_INDICATOR' THEN 1 ELSE 0 END AS HAS_OMD_CURRENT_RECORD_INDICATOR,
    CASE WHEN COLUMN_NAME = 'OMD_CHANGE_DATETIME' THEN 1 ELSE 0 END AS HAS_OMD_CHANGE_DATETIME,
                CASE WHEN COLUMN_NAME = 'OMD_CHANGE_KEY' THEN 1 ELSE 0 END AS HAS_OMD_CHANGE_KEY
FROM TableCheckCTE
), SingleRowAttributeEvaluation AS
(
SELECT 
                TABLE_CATALOG, 
                TABLE_NAME, 
                TABLE_SCHEMA,
                SUM(HAS_OMD_INSERT_MODULE_INSTANCE_ID) AS HAS_OMD_INSERT_MODULE_INSTANCE_ID,
                SUM(HAS_OMD_INSERT_DATETIME) AS HAS_OMD_INSERT_DATETIME,
                SUM(HAS_OMD_EVENT_DATETIME) AS HAS_OMD_EVENT_DATETIME,
                SUM(HAS_OMD_RECORD_SOURCE) AS HAS_OMD_RECORD_SOURCE,
                SUM(HAS_OMD_SOURCE_ROW_ID) AS HAS_OMD_SOURCE_ROW_ID,
                SUM(HAS_OMD_CDC_OPERATION) AS HAS_OMD_CDC_OPERATION,
                SUM(HAS_OMD_HASH_FULL_RECORD) AS HAS_OMD_HASH_FULL_RECORD,
                SUM(HAS_OMD_CURRENT_RECORD_INDICATOR) AS HAS_OMD_CURRENT_RECORD_INDICATOR,
                SUM(HAS_OMD_CHANGE_DATETIME) AS HAS_OMD_CHANGE_DATETIME,
                SUM(HAS_OMD_CHANGE_KEY) AS HAS_OMD_CHANGE_KEY
FROM Attribute_Detection 
GROUP BY
                TABLE_CATALOG,
                TABLE_NAME,
                TABLE_SCHEMA
), ErrorEvaluation AS
(
SELECT
                TABLE_CATALOG, 
                TABLE_NAME, 
                TABLE_SCHEMA,
                CASE WHEN HAS_OMD_INSERT_MODULE_INSTANCE_ID = 0 THEN 'No change date/time attribute is defined.' ELSE '' END AS ERROR_OMD_INSERT_MODULE_INSTANCE_ID,
                CASE WHEN HAS_OMD_INSERT_DATETIME = 0 THEN 'No insert datetime attribute is defined.' ELSE '' END AS ERROR_OMD_INSERT_DATETIME,
                CASE WHEN HAS_OMD_EVENT_DATETIME = 0 THEN 'No event date/time attribute is defined.' ELSE '' END AS ERROR_OMD_EVENT_DATETIME,
                CASE WHEN HAS_OMD_RECORD_SOURCE = 0 THEN 'No record source attribute is defined.' ELSE '' END AS ERROR_OMD_RECORD_SOURCE,
                CASE WHEN HAS_OMD_SOURCE_ROW_ID = 0 THEN 'No source row ID attribute is defined.' ELSE '' END AS ERROR_OMD_SOURCE_ROW_ID,
                CASE WHEN HAS_OMD_CDC_OPERATION = 0 THEN 'No cdc operation attribute is defined.' ELSE '' END AS ERROR_OMD_CDC_OPERATION,
                CASE WHEN HAS_OMD_HASH_FULL_RECORD = 0 THEN 'No full row hash attribute is defined.' ELSE '' END AS ERROR_HASH_FULL_RECORD,
                CASE WHEN HAS_OMD_CURRENT_RECORD_INDICATOR = 0 THEN 'No current record indicator attribute is defined.' ELSE '' END AS ERROR_CURRENT_RECORD_INDICATOR,
                CASE WHEN HAS_OMD_CHANGE_DATETIME = 0 THEN 'No change date/time attribute is defined.' ELSE '' END AS ERROR_OMD_CHANGE_DATETIME,
                CASE WHEN HAS_OMD_CHANGE_KEY = 0 THEN 'No change key attribute is defined.' ELSE '' END AS ERROR_OMD_CHANGE_KEY
                                
FROM SingleRowAttributeEvaluation
), SingleErrorEvaluation AS
(
SELECT 
                TABLE_CATALOG, 
                TABLE_NAME, 
                TABLE_SCHEMA,
                LTRIM(RTRIM(
                                ERROR_OMD_INSERT_MODULE_INSTANCE_ID + ' ' + 
                                ERROR_OMD_INSERT_DATETIME + ' ' +
                                ERROR_OMD_EVENT_DATETIME + ' ' +
                                ERROR_OMD_RECORD_SOURCE + ' ' +
                                ERROR_OMD_SOURCE_ROW_ID + ' ' +
                                ERROR_OMD_CDC_OPERATION + ' ' +
                                ERROR_HASH_FULL_RECORD + ' ' +
                                ERROR_CURRENT_RECORD_INDICATOR + ' ' +
                                ERROR_OMD_CHANGE_KEY + ' ' + 
                                ERROR_OMD_CHANGE_DATETIME + ' ' 
                )) AS ERROR_TOTAL
FROM ErrorEvaluation
)
SELECT * FROM SingleErrorEvaluation
WHERE ERROR_TOTAL!=''
GO
/****** Object:  View [omd_reporting].[vw_EXECUTION_EVENT_LOG]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_EXECUTION_EVENT_LOG]
AS

SELECT
	EL.EVENT_ID
	, EL.BATCH_INSTANCE_ID
	, B.BATCH_CODE
	, EL.MODULE_INSTANCE_ID
	, M.MODULE_CODE
	, ET.EVENT_TYPE_DESCRIPTION
	, EL.EVENT_DATETIME
	, EL.EVENT_RETURN_CODE_DETAILS
	, EL.EVENT_DETAIL
FROM
	omd.EVENT_LOG EL
		INNER JOIN omd.EVENT_TYPE ET ON EL.EVENT_TYPE_CODE = ET.EVENT_TYPE_CODE
		INNER JOIN omd.BATCH_INSTANCE BI ON EL.BATCH_INSTANCE_ID = BI.BATCH_INSTANCE_ID
		INNER JOIN omd.BATCH B ON BI.BATCH_ID = B.BATCH_ID
		INNER JOIN omd.MODULE_INSTANCE MI ON EL.MODULE_INSTANCE_ID = MI.MODULE_INSTANCE_ID
		INNER JOIN omd.MODULE M ON MI.MODULE_ID = M.MODULE_ID
WHERE
	EVENT_ID <> 0
GO
/****** Object:  View [omd_reporting].[vw_EXECUTION_LOG_BATCH_INSTANCE]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_EXECUTION_LOG_BATCH_INSTANCE]
AS

SELECT	
	  BI.BATCH_INSTANCE_ID
	, B.BATCH_CODE
	, BI.BATCH_EXECUTION_SYSTEM_ID
	, BI.START_DATETIME
	, BI.END_DATETIME
	, CAST (CAST ((BI.END_DATETIME - BI.START_DATETIME) AS TIME) AS VARCHAR (30)) AS EXECUTION_TIME
	, PIND.PROCESSING_INDICATOR_DESCRIPTION
	, NR.NEXT_RUN_INDICATOR_DESCRIPTION
	, BI.EXECUTION_STATUS_CODE
	, ES.EXECUTION_STATUS_DESCRIPTION 
FROM
	       omd.BATCH_INSTANCE BI
INNER JOIN omd.BATCH B ON BI.BATCH_ID = B.BATCH_ID
INNER JOIN omd.PROCESSING_INDICATOR PIND ON BI.PROCESSING_INDICATOR = PIND.PROCESSING_INDICATOR
INNER JOIN omd.NEXT_RUN_INDICATOR NR ON BI.NEXT_RUN_INDICATOR = NR.NEXT_RUN_INDICATOR
INNER JOIN omd.EXECUTION_STATUS ES ON BI.EXECUTION_STATUS_CODE = ES.EXECUTION_STATUS_CODE
WHERE
	BATCH_INSTANCE_ID <> 0
GO
/****** Object:  View [omd_reporting].[vw_EXECUTION_LOG_MODULE_INSTANCE]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_EXECUTION_LOG_MODULE_INSTANCE]
AS

SELECT
	  MI.MODULE_INSTANCE_ID
	, MI.MODULE_EXECUTION_SYSTEM_ID
	, MI.BATCH_INSTANCE_ID
	, M.MODULE_CODE
	, MI.START_DATETIME
	, MI.END_DATETIME
	, CAST (CAST ((MI.END_DATETIME - MI.START_DATETIME) AS TIME) AS VARCHAR (30)) AS EXECUTION_TIME
	, PIND.PROCESSING_INDICATOR_DESCRIPTION
	, NR.NEXT_RUN_INDICATOR_DESCRIPTION
	, MI.EXECUTION_STATUS_CODE
	, ES.EXECUTION_STATUS_DESCRIPTION
	, MI.ROWS_INPUT
	, MI.ROWS_INSERTED
	, MI.ROWS_UPDATED
	, MI.ROWS_DELETED
	, MI.ROWS_DISCARDED
	, MI.ROWS_REJECTED
FROM
	omd.MODULE_INSTANCE MI
		INNER JOIN omd.MODULE M ON MI.MODULE_ID = M.MODULE_ID
		INNER JOIN omd.PROCESSING_INDICATOR PIND ON MI.PROCESSING_INDICATOR = PIND.PROCESSING_INDICATOR
		INNER JOIN omd.NEXT_RUN_INDICATOR NR ON MI.NEXT_RUN_INDICATOR = NR.NEXT_RUN_INDICATOR
		INNER JOIN omd.EXECUTION_STATUS ES ON MI.EXECUTION_STATUS_CODE = ES.EXECUTION_STATUS_CODE
WHERE MODULE_INSTANCE_ID <> 0
GO
/****** Object:  View [omd_reporting].[vw_MODULE_FAILURES]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [omd_reporting].[vw_MODULE_FAILURES] AS

select     --TOP 40
           m.MODULE_CODE
          ,m.MODULE_DESCRIPTION
          ,AVG(datediff(MINUTE,mi.START_DATETIME,mi.END_DATETIME)) as AVG_EXEC_MIN
          ,SUM(case when mi.EXECUTION_STATUS_CODE = 'F' then 1 else 0 end) as COUNT_ERRORS
from      omd.MODULE m
JOIN      omd.MODULE_INSTANCE mi
ON            m.MODULE_ID = mi.MODULE_ID
WHERE         mi.START_DATETIME > dateadd(MONTH,-3,getdate())
group by      m.MODULE_CODE, m.MODULE_DESCRIPTION
HAVING        SUM(case when mi.EXECUTION_STATUS_CODE = 'F' then 1 else 0 end) >0
GO
/****** Object:  StoredProcedure [omd].[BatchEvaluation]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Process: Batch Evaluation
Purpose: Checks if the Batch Instance is able to proceed, based on the state of all Batch Instances related to the particular Batch.
Input: 
  - Batch Instance Id
  - Debug flag Y/N (default to N)
Returns:
  - ProcessIndicator
Usage:
    DECLARE @ProcessIndicator VARCHAR(10);
    EXEC [omd].[BatchEvaluation]
      @BatchInstanceId = <Id>,
      @ProcessIndicator = @ProcessIndicator OUTPUT;
    PRINT @ProcessIndicator;
*/

CREATE   PROCEDURE [omd].[BatchEvaluation]
	@BatchInstanceId INT, -- The Batch Instance Id
	@Debug VARCHAR(1) = 'N',
	@ProcessIndicator VARCHAR(10) = NULL OUTPUT
AS

BEGIN
  SET NOCOUNT ON;

  DECLARE @BatchId INT;
  DECLARE @ActiveInstanceCount INT;

  IF @Debug = 'Y'
    PRINT '-- Beginning of Batch Evaluation for Batch Instance Id '+CONVERT(VARCHAR(10),@BatchInstanceId);

  SELECT @BatchId = omd.GetBatchIdByBatchInstanceId(@BatchInstanceId);

  IF @Debug = 'Y'
    PRINT 'For Batch Instance Id '+CONVERT(VARCHAR(10),@BatchInstanceId)+' the Batch Id '+CONVERT(VARCHAR(10),@BatchId)+' was found in omd.BATCH.';

  /* 
    Region: Check for multiple active Batch Instances
	Multiple active instances indicate corruption in the DIRECT repository.
  */

  IF @Debug = 'Y'
    PRINT CHAR(13)+'-- Beginning of active instance checks.';
       
  -- Check if there are no additional running instances other than the current Batch Instance. The count should be 0.
  SELECT @ActiveInstanceCount = COUNT(*)
  FROM omd.BATCH_INSTANCE 
  WHERE EXECUTION_STATUS_CODE = 'E' 
    AND BATCH_ID = @BatchId and BATCH_INSTANCE_ID < @BatchInstanceId            

  IF @Debug = 'Y'
  BEGIN
    PRINT 'The number of active Batch Instances is '+COALESCE(CONVERT(VARCHAR(10),@ActiveInstanceCount),'0')+'.';
  END

  IF @ActiveInstanceCount = 0
    BEGIN
	  -- Continue,  there is no other active instance for this Batch.
	  IF @Debug = 'Y'
	    PRINT 'Either there are no other active instance for the Batch (except this one), so the evaluation can continue.'
     
	 -- Go to the next step in the process.
	  GOTO BatchInactiveEvaluation
	END
  ELSE -- There are already multiple running instances for the same Batch, the process must be aborted.
	BEGIN
	  IF @Debug = 'Y'
	    PRINT 'There are multiple running instances for the same Batch, the process must be aborted (abort and go to end of procedure).'

	  -- Call the Abort event.
	  EXEC [omd].[UpdateBatchInstance]
		@BatchInstanceId = @BatchInstanceId,
		@EventCode = N'Abort',
		@Debug = @Debug

      SET @ProcessIndicator = 'Abort';
	  GOTO EndOfProcedure
	  -- End
	END

  BatchInactiveEvaluation:
  /* 
    Region: Batch active check.
	In case the Batch is has an INACTIVE_INDICATOR='N' the pcoess can be cancelled / skipped as the Batch is not supposed to run.
  */
  DECLARE @BatchInactiveIndicator VARCHAR(1);

  IF @Debug='Y'
    PRINT CHAR(13)+'-- Start of Batch Inactive evalation step.';
	
  SELECT @BatchInactiveIndicator = INACTIVE_INDICATOR
  FROM omd.BATCH
  WHERE BATCH_ID= @BatchId                

  IF @BatchInactiveIndicator = 'N' -- The Batch is enabled, so the process can continue.
    BEGIN

	  IF @Debug='Y'
        PRINT 'The Batch is enabled (Inactive Indicator is set to '+@BatchInactiveIndicator+'), so the process can continue.';

	  GOTO RollBackEvaluation -- Go to the next process step after this section.
    END
  ELSE -- Batch has something else than 'N' and should be skipped / cancelled.
    BEGIN 
      IF @Debug='Y'
      	PRINT 'The Batch is disabled (Inactive Indicator is set to '+@BatchInactiveIndicator+'), so the process must cancel / skip.';
              
      -- Call the Cancel (skip) event.
      EXEC [omd].[UpdateBatchInstance]
        @BatchInstanceId = @BatchInstanceId,
      	@EventCode = N'Cancel',
        @Debug = @Debug
      
      SET @ProcessIndicator = 'Cancel';
      GOTO EndOfProcedure 
    END


  /* 
    Region: rollback.
	Any erroneous previous instances must be rolled-back before processing can continue.
  */
  RollBackEvaluation:

  IF @Debug='Y'
	PRINT CHAR(13)+'-- Start of rollback evaluation process step.';

  DECLARE @LastExecutionStatusCode VARCHAR(1);
  DECLARE @LastNextRunIndicator VARCHAR(1);

  -- Get the Next Run Indicator and Execution Status Code from the previous Batch Instance.
  DECLARE @PreviousBatchInstanceTable TABLE
  (
    LastExecutionStatusCode VARCHAR(1),
    LastNextRunIndicator VARCHAR(1)
  );

  INSERT @PreviousBatchInstanceTable 
  SELECT * FROM [omd].[GetPreviousBatchInstanceDetails](@BatchId)

  SELECT @LastExecutionStatusCode = LastExecutionStatusCode FROM @PreviousBatchInstanceTable;
  IF @Debug='Y'
    PRINT 'The previous Batch Instance Execution Status Code is '+@LastExecutionStatusCode;

  SELECT @LastNextRunIndicator = LastNextRunIndicator FROM @PreviousBatchInstanceTable;
  IF @Debug='Y'
    PRINT 'The previous Batch Instance Next Run Indicator is '+@LastNextRunIndicator;

  -- Proceed
  -- The execution can proceed if the previous run for the Batch (the previous Batch Instance) was without failure, was not set to rerun and was not cancelled.
  IF ( (@LastExecutionStatusCode != 'F') AND (@LastNextRunIndicator NOT IN ('C','R')) ) 
    BEGIN
	  IF @Debug='Y'
	    PRINT 'The last Execution Flag is '+@LastExecutionStatusCode+' and last Next Run Indicator is '+@LastNextRunIndicator+'. The process can proceed (no rollback is required).';

	  IF @Debug='Y'
		PRINT 'The Batch Instance will be set to proceed';

	  EXEC [omd].[UpdateBatchInstance]
	    @BatchInstanceId = @BatchInstanceId,
		@EventCode = N'Proceed',
	    @Debug = @Debug

	   SET @ProcessIndicator = 'Proceed';
	   GOTO EndOfProcedure
    END

  -- Proceed with RollBack.
  -- If the previous Batch Instance has failed and the previous next run indicator is not set to skip OR the previous next run indicator is set to rerun the rollback step must be initiatied.
  IF ( (@LastExecutionStatusCode = 'F' AND @LastNextRunIndicator != 'C') OR @LastNextRunIndicator = 'R' ) 
    BEGIN
	  IF @Debug='Y'
	    PRINT 'The last Execution Flag is '+@LastExecutionStatusCode+' and last Next Run Indicator is '+@LastNextRunIndicator+'. The process must initiate a rollback.';

	  IF @Debug='Y'
		PRINT 'The Batch Instance will be set to rollback.';

     -- NOTE the below status update on the Batch Instance will always trigger a full rollback, whereas partial rollback is the default.
	      
	 -- EXEC [omd].[UpdateBatchInstance]
	 --   @BatchInstanceId = @BatchInstanceId,
		--@EventCode = N'Rollback',
	 --   @Debug = @Debug

	  SET @ProcessIndicator = 'Rollback';
	  GOTO CallRollback
    END


  /*
    Region: execution of rollback.
	Call the rollback procedure for the current Batch.
	Technically, this is disabling any Modules that were part of earlier failed Batches, as the rollback itself happens at Module level.
  */

  CallRollback:
  
  IF @Debug='Y'
	PRINT CHAR(13)+'-- Start of rollback evaluation process step.';

  DECLARE @SqlStatement VARCHAR(MAX);

  DECLARE @FailedBatchIdArray VARCHAR(MAX) = omd.[GetFailedBatchIdList](@BatchId);

  IF @Debug='Y'
	PRINT 'The array of earlier failed Batch Instances is '+@FailedBatchIdArray+'.';

  IF @LastNextRunIndicator = 'R' -- Full rollback for all Modules in the Batch.
    BEGIN  
      BEGIN TRY

	    SET @SqlStatement = 'UPDATE omd.MODULE_INSTANCE SET NEXT_RUN_INDICATOR = ''R'' WHERE BATCH_INSTANCE_ID IN '+@FailedBatchIdArray;

		IF @Debug='Y'
		  PRINT 'Rollback SQL statement (full) is: '+@SqlStatement;

		EXEC (@SqlStatement);

        -- After rollback is completed, the process is allowed to continue.
        IF @Debug='Y'
          PRINT 'The Module Instance will be set to proceed';

	    EXEC [omd].[UpdateBatchInstance]
	      @BatchInstanceId = @BatchInstanceId,
	      @EventCode = N'Proceed',
	     @Debug = @Debug

	    SET @ProcessIndicator = 'Proceed';
        GOTO EndOfProcedure

     END TRY
	 BEGIN CATCH
		-- Module Failure
       EXEC [omd].[UpdateBatchInstance]
	      @BatchInstanceId = @BatchInstanceId,
		  @Debug = @Debug,
		  @EventCode = 'Failure';
	    SET @ProcessIndicator = 'Failure';
	   THROW
	 END CATCH
  END

  IF @LastNextRunIndicator = 'P' -- Partial rollback - skip previously succesfull Modules in the Batch.
    BEGIN  
      BEGIN TRY

	    SET @SqlStatement = 'UPDATE omd.MODULE_INSTANCE SET NEXT_RUN_INDICATOR = ''C'' WHERE EXECUTION_STATUS_CODE!=''F'' AND BATCH_INSTANCE_ID IN '+@FailedBatchIdArray;

		IF @Debug='Y'
		  PRINT 'Rollback SQL statement (partial) is: '+@SqlStatement;

		EXEC (@SqlStatement);

        -- After rollback is completed, the process is allowed to continue.
        IF @Debug='Y'
          PRINT 'The Module Instance will be set to proceed';

	    EXEC [omd].[UpdateBatchInstance]
	      @BatchInstanceId = @BatchInstanceId,
	      @EventCode = N'Proceed',
	     @Debug = @Debug

	    SET @ProcessIndicator = 'Proceed';
        GOTO EndOfProcedure

     END TRY
	 BEGIN CATCH
		-- Module Failure
       EXEC [omd].[UpdateBatchInstance]
	      @BatchInstanceId = @BatchInstanceId,
		  @Debug = @Debug,
		  @EventCode = 'Failure';
	    SET @ProcessIndicator = 'Failure';
	   THROW
	 END CATCH
  END

  -- All branches completed

  -- The procedure should not be able to end in this part.
  -- Batch Failure
  EXEC [omd].[UpdateBatchInstance]
    @BatchInstanceId = @BatchInstanceId,
    @Debug = @Debug,
    @EventCode = 'Failure';

  SET @ProcessIndicator = 'Failure';

  RAISERROR('Incorrect Batch Evaluation path encountered (post-rollback).',1,1)

  /*
    Region: end of processing, final step.
  */

  EndOfProcedure:
   -- End label

  IF @Debug = 'Y'
  BEGIN
     BEGIN TRY
       PRINT 'Batch Instance Id '+CONVERT(VARCHAR(10),@BatchInstanceId)+' was processed';
       PRINT 'The result (processing indicator) is '+@ProcessIndicator;  
       PRINT CHAR(13)+'-- Completed.';
	 END TRY
	 BEGIN CATCH
	   THROW
	 END CATCH
  END

END



GO
/****** Object:  StoredProcedure [omd].[CreateBatchInstance]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Process: Create Batch Instance
Input: 
  - Batch Code
  - Execution runtime Is (e.g. GUID, SPID)
  - Debug flag Y/N
Returns:
  - Batch Instance Id
Usage:
    DECLARE @BatchInstanceId INT
    EXEC [omd].[CreateBatchInstance]
      @BatchCode = N'<Batch Code / Name>',
      @BatchInstanceId = @BatchInstanceId OUTPUT;
    PRINT @BatchInstanceId;
*/

CREATE PROCEDURE [omd].[CreateBatchInstance]
	@BatchCode VARCHAR(255), -- The name of the module, as identified in the BATCH_CODE attribute in the BATCH table.
	@Debug VARCHAR(1) = 'N',
	@ExecutionRuntimeId VARCHAR(255) = 'N/A',
	@BatchInstanceId INT = NULL OUTPUT
AS
BEGIN

  DECLARE @BatchId INT;
  SELECT @BatchId = omd.GetBatchIdByName(@BatchCode);

  IF @Debug = 'Y'
    PRINT 'For Batch Code '+@BatchCode+' the following Batch Id was found in omd.BATCH: '+CONVERT(VARCHAR(10),@BatchId);

  BEGIN TRY

    INSERT INTO omd.BATCH_INSTANCE 
	(
      BATCH_ID,  
      START_DATETIME, 
      EXECUTION_STATUS_CODE, 
      NEXT_RUN_INDICATOR, 
      PROCESSING_INDICATOR,
      BATCH_EXECUTION_SYSTEM_ID
	)
    VALUES
	(
      @BatchId,
      SYSDATETIME(),        -- Start Datetime
      'E',					-- Execution Status Code
      'P',					-- Next Run Indicator
      'A',					-- Processing Indicator
      @ExecutionRuntimeId
    )
                

	SET @BatchInstanceId = SCOPE_IDENTITY();

	IF @Debug = 'Y'
      PRINT 'A new Batch Instance Id '+CONVERT(VARCHAR(10),@BatchInstanceId)+' has been created for Batch Code: '+@BatchCode;

  END TRY
  BEGIN CATCH
	THROW
  END CATCH
  
END
GO
/****** Object:  StoredProcedure [omd].[CreateModuleInstance]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Process: Create Module Instance
Input: 
  - Module Code
  - Batch Instance Id
  - Execution runtime Is (e.g. GUID, SPID)
  - Debug flag Y/N
Returns:
  - Module Instance Id
Usage:
    DECLARE @ModuleInstanceId INT
    EXEC [omd].[CreateModuleInstance]
      @ModuleCode = N'<Module Code / Name>',
      @ModuleInstanceId = @ModuleInstanceId OUTPUT;
    PRINT @ModuleInstanceId;
*/

CREATE PROCEDURE [omd].[CreateModuleInstance]
	@ModuleCode VARCHAR(255), -- The name of the module, as identified in the MODULE_CODE attribute in the MODULE table.
	@Debug VARCHAR(1) = 'N',
	@ExecutionRuntimeId VARCHAR(255) = 'N/A',
	@BatchInstanceId INT = 0, -- The Batch Instance Id, if the Module is run from a Batch.
	@ModuleInstanceId INT = NULL OUTPUT
AS
BEGIN

  DECLARE @ModuleId INT;
  SELECT @ModuleId = omd.GetModuleIdByName(@ModuleCode);

  IF @Debug = 'Y'
    PRINT 'For Module Code '+@ModuleCode+' the following Module Id was found in omd.MODULE: '+CONVERT(VARCHAR(10),@ModuleId);

  BEGIN TRY
    INSERT INTO omd.MODULE_INSTANCE 
    (
      MODULE_ID, 
      START_DATETIME, 
      EXECUTION_STATUS_CODE, 
      NEXT_RUN_INDICATOR, 
      PROCESSING_INDICATOR, 
      BATCH_INSTANCE_ID, 
      MODULE_EXECUTION_SYSTEM_ID, 
      ROWS_INPUT, 
      ROWS_INSERTED, 
      ROWS_UPDATED, 
      ROWS_DELETED, 
      ROWS_DISCARDED,
      ROWS_REJECTED
    ) 
    VALUES
    (
      @ModuleId,			-- Module ID
      SYSDATETIME(), -- Start Datetime
      'E',					-- Execution Status Code
      'P',					-- Next Run Indicator
      'A',					-- Processing Indicator
      @BatchInstanceId,		-- Batch Instance Id
      @ExecutionRuntimeId,  -- Module Execution System Id 
      0,
      0,
      0,
      0,
      0,
      0
    );

	SET @ModuleInstanceId = SCOPE_IDENTITY();

	IF @Debug = 'Y'
      PRINT 'A new Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' has been created for Module Code: '+@ModuleCode;

  END TRY
  BEGIN CATCH
	THROW
  END CATCH
  
END
GO
/****** Object:  StoredProcedure [omd].[ModuleEvaluation]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Process: Module Evaluation
Purpose: Checks if the Module Instance is able to proceed, based on the state of all Module Instances for the particular Module.
Input: 
  - Module Instance Id
  - Debug flag Y/N (default to N)
Returns:
  - ProcessIndicator
Usage:
    DECLARE @ProcessIndicator VARCHAR(10);
    EXEC [omd].[ModuleEvaluation]
      @ModuleInstanceId = <Id>,
      @ProcessIndicator = @ProcessIndicator OUTPUT;
    PRINT @ProcessIndicator;
*/

CREATE PROCEDURE [omd].[ModuleEvaluation]
	@ModuleInstanceId INT, -- The Batch Instance Id, if the Module is run from a Batch.
	@Debug VARCHAR(1) = 'N',
	@ProcessIndicator VARCHAR(10) = NULL OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @ModuleId INT;
  DECLARE @BatchId INT;
  DECLARE @MinimumActiveModuleInstance INT;
  DECLARE @ActiveModuleInstanceCount INT;
  DECLARE @BatchModuleInactiveIndicator VARCHAR(1);

  IF @Debug = 'Y'
    PRINT '-- Beginning of Module Evaluation for Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId);

  SELECT @ModuleId = omd.GetModuleIdByModuleInstanceId(@ModuleInstanceId);

  IF @Debug = 'Y'
    PRINT 'For Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' the Module Id '+CONVERT(VARCHAR(10),@ModuleId)+' was found in omd.MODULE.';

  /* 
    Region: Check for multiple active Module Instances
	Multiple active instances indicate corruption in the DIRECT repository.
  */
  IF @Debug = 'Y'
    PRINT CHAR(13)+'-- Beginning of active instance checks.';

  -- Check for the lowest instance of the Module Instances since the process must continue if it's the first of the started instances for the particular Module.  
  SELECT @MinimumActiveModuleInstance =
    MIN(MODULE_INSTANCE_ID)  
  FROM omd.MODULE_INSTANCE
  WHERE EXECUTION_STATUS_CODE = 'E' 
    AND MODULE_ID = @ModuleId
  GROUP BY MODULE_ID
        
  -- Check if there are no additional running instances other than the current Module Instance. The count should be 1.
  SELECT @ActiveModuleInstanceCount = 
    COUNT(*)
  FROM omd.MODULE_INSTANCE
  WHERE EXECUTION_STATUS_CODE = 'E' 
     AND MODULE_ID = @ModuleId
     AND MODULE_INSTANCE_ID != @ModuleInstanceId
  GROUP BY MODULE_ID

  IF @Debug = 'Y'
  BEGIN
    PRINT 'The number of active Module Instances is '+COALESCE(CONVERT(VARCHAR(10),@ActiveModuleInstanceCount),'0')+'.';
    PRINT 'The minimum active Module Instance Id is '+COALESCE(CONVERT(VARCHAR(10),@MinimumActiveModuleInstance),'0')+'.';
  END

  IF (@ActiveModuleInstanceCount IS NULL) OR (@ActiveModuleInstanceCount IS NOT NULL AND @MinimumActiveModuleInstance = @ModuleInstanceId)
    BEGIN
	  -- Continue, either there is only 1 active instance for the Module (this one) OR this instance is the first of many running instances and this one should be allowed to continue.
	  IF @Debug = 'Y'
	    PRINT 'Either there is only 1 active instance for the Module (this one) OR this instance is the first (MIN) of many running instances and should be allowed to continue.'
     
	 -- Go to the next step in the process.
	  GOTO BatchModuleEvaluation
	END
  ELSE -- There are already multiple running instances for the same Module, the process must be aborted.
	BEGIN
	  IF @Debug = 'Y'
	    PRINT 'There are already multiple running instances for the same Module, the process must be aborted. (abort and go to end of procedure).'

	  -- Call the Abort event.
	  EXEC [omd].[UpdateModuleInstance]
		@ModuleInstanceId = @ModuleInstanceId,
		@EventCode = N'Abort',
		@Debug = @Debug

      SET @ProcessIndicator = 'Abort';
	  GOTO EndOfProcedure
	  -- End
	END

  BatchModuleEvaluation:
  /* 
    Region: Batch/Module relationship validation.
	In case the Module is called from a parent Batch this task verifies if the administration is done properly
	and if the Module is disabled as part of the Batch configuration (BATCH_MODULE).

	If the current instance is started from a Batch (Batch Instance <> 0) then the Batch / Module flag must be set to INACTIVE_INDICATOR='N'
	If the current instance has a Batch Instance Id (or Batch Id) of 0 then this step can be skipped, as the Module was not started by a Batch.
  */

  SELECT @BatchId = omd.GetBatchIdByModuleInstanceId(@ModuleInstanceId);
  IF @Debug='Y'
    PRINT CHAR(13)+'-- Start of Batch / Module relationship evalation step.';
	PRINT 'The Batch Id found is '+CONVERT(VARCHAR(10),@BatchId);
	
  IF @BatchId = 0 -- The Module was run stand-alone (not from a Batch).
    BEGIN
	  -- The Module Instance was not started from a Batch, so processing can skip this step and continue.
	  IF @Debug='Y'
        PRINT 'The Module Instance was not started from a Batch (0), so processing can skip this step and continue to Rollback Evaluation.';

	  GOTO RollBackEvaluation -- Go to the next process step after this section.
    END
  ELSE -- Batch Id has a value, so the Module was run from a Batch.
    BEGIN
	  -- The Module Instance was started by a Batch, so we must check if the Module is allowed to run.
	  SELECT @BatchModuleInactiveIndicator = omd.[GetBatchModuleActiveIndicatorValue](@BatchId,@ModuleId)
	  
	  IF @Debug='Y'
		PRINT 'The Batch / Module inactive flag value is '+@BatchModuleInactiveIndicator;

      IF (@BatchModuleInactiveIndicator='Y') -- Skip
      BEGIN
	  	IF @Debug='Y'
		  PRINT 'The Module Instance will be skipped / cancelled';

	    -- If the inactive indicator at Batch/Module level is set to 'Y' the process is disabled in the framework.
	    -- In this case, the Module must be skipped / cancelled (was attempted to be run, but not allowed).
	   
	    -- Call the Cancel (skip) event.
	    EXEC [omd].[UpdateModuleInstance]
	  	  @ModuleInstanceId = @ModuleInstanceId,
		  @EventCode = N'Cancel',
	      @Debug = @Debug

		SET @ProcessIndicator = 'Cancel';
	    GOTO EndOfProcedure
      END

	  IF (@BatchModuleInactiveIndicator = NULL) -- Abort
      BEGIN
	  	IF @Debug='Y'
		  PRINT 'The Module Instance will be aborted.';

	    -- If the inactive indicator at Batch/Module level is NULL then there is an error in the framework registration / setup.
	    -- In this case, the Module must be aborted. The module was attempted to be run form a Batch it is not registered for).
	  
	    -- Call the Abort event.
	    EXEC [omd].[UpdateModuleInstance]
		  @ModuleInstanceId = @ModuleInstanceId,
		  @EventCode = N'Abort',
		  @Debug = @Debug

		SET @ProcessIndicator = 'Abort';
	    GOTO EndOfProcedure
      END

	  -- The procedure should not be able to end in this part.
	  RAISERROR('Incorrect Module Evaluation path encountered.',1,1)

	END


  RollBackEvaluation:
  /* 
    Region: rollback.
	Any erroneous previous instances must be rolled-back before processing can continue.
  */

  IF @Debug='Y'
	PRINT CHAR(13)+'-- Start of rollback evaluation process step.';

  DECLARE @PreviousModuleInstanceTable TABLE
  (
    LastBatchInstanceID INT,
    LastModuleInstanceID INT ,
    LastStartTime DATETIME2(7),
    LastEndTime DATETIME2(7),
    LastExecutionStatus VARCHAR(1),
    LastNextExecutionFlag VARCHAR(1),
    LastModuleInstanceIDList VARCHAR(MAX),
    InactiveIndicator VARCHAR(1)
  );

  INSERT @PreviousModuleInstanceTable 
  SELECT * FROM [omd].[GetPreviousModuleInstanceDetails](@ModuleId,@BatchId)

  -- If the previously completed Module Instance (for the same Module) is set to skip OR the module is set to inactive the run must be cancelled.
  IF ((SELECT LastNextExecutionFlag FROM @PreviousModuleInstanceTable) = 'C') OR ((SELECT InactiveIndicator FROM @PreviousModuleInstanceTable) = 'Y')
    BEGIN
	  IF @Debug='Y'
	    PRINT 'The last Execution Flag is ''C'' OR the Inactive Indicator at Module level is ''Y''. The process will be skipped / cancelled.';

	  IF @Debug='Y'
	    PRINT 'The Module Instance will be skipped / cancelled';

	  -- Call the Cancel (skip) event.
	  EXEC [omd].[UpdateModuleInstance]
	    @ModuleInstanceId = @ModuleInstanceId,
		@EventCode = N'Cancel',
	    @Debug = @Debug

	  SET @ProcessIndicator = 'Cancel';
	  GOTO EndOfProcedure
   END

  -- Proceed with success 
  -- If the previous run for the module (the previous Module Instance) was completed successfully and the Module is not disabled, the process can report 'proceed' for
  -- any code execution in the body (e.g. the ETL itself).
  IF ((SELECT LastNextExecutionFlag FROM @PreviousModuleInstanceTable) = 'P') AND ((SELECT InactiveIndicator FROM @PreviousModuleInstanceTable) != 'Y')
    BEGIN
	  IF @Debug='Y'
	    PRINT 'The last Execution Flag is ''P'' AND the Inactive Indicator at Module level is not ''Y''. The process can proceed (no rollback is required).';

	  IF @Debug='Y'
		PRINT 'The Module Instance will be set to proceed';

	  EXEC [omd].[UpdateModuleInstance]
	    @ModuleInstanceId = @ModuleInstanceId,
		@EventCode = N'Proceed',
	    @Debug = @Debug

	   SET @ProcessIndicator = 'Proceed';
	   GOTO EndOfProcedure
    END

  -- Proceed with RollBack.
  -- If the previous Module Instance is set to Rollback, this will trigger the current Module instance to do so before proceeding.
  IF ((SELECT LastNextExecutionFlag FROM @PreviousModuleInstanceTable) = 'R') AND ((SELECT InactiveIndicator FROM @PreviousModuleInstanceTable) != 'Y')
    BEGIN
	  IF @Debug='Y'
	    PRINT 'The last Execution Flag is ''R'' AND the Inactive Indicator at Module level is not ''Y''. The process should perform a rollback.';

	  IF @Debug='Y'
		PRINT 'The Module Instance will be set to rollback';

	  EXEC [omd].[UpdateModuleInstance]
	    @ModuleInstanceId = @ModuleInstanceId,
		@EventCode = N'Rollback',
	    @Debug = @Debug

	  SET @ProcessIndicator = 'Rollback';
	  GOTO CallRollback
    END

  /*
    Region: execution of rollback.
  */

  CallRollback:
  
  IF @Debug='Y'
	PRINT CHAR(13)+'-- Start of rollback evaluation process step.';

  BEGIN TRY
      -- Call the rollback procedure for the current Module.
	  -- Technically, this is rolling back of the previous Module Instance.
      -- This has to happen in the same transaction block to prevent process setting to commence before rollback ends.

	BEGIN -- Rollback
	  DECLARE @ModuleInstanceIdList VARCHAR(MAX);
	  SET @ModuleInstanceIdList = (SELECT LastModuleInstanceIDList FROM @PreviousModuleInstanceTable);

	  IF @Debug='Y'
	    PRINT 'Input variables are Module '+CONVERT(VARCHAR(10),@ModuleId)+' with Previous Module Instance Id list '+@ModuleInstanceIdList+'.';

	  DECLARE @SqlStatement VARCHAR(MAX);
	  --DECLARE @AreaCode VARCHAR(10);
	  --SELECT @AreaCode = AREA_CODE FROM omd.MODULE WHERE MODULE_ID=@ModuleId;
	  DECLARE @TableCode VARCHAR(255);
	  SELECT @TableCode = DATA_OBJECT_TARGET FROM omd.MODULE WHERE MODULE_ID=@ModuleId; 

	  IF @Debug='Y'
	  BEGIN
		--PRINT 'The Area Code for Module '+CONVERT(VARCHAR(10),@ModuleId)+' is '+@AreaCode+'.';
		PRINT 'The Table Code (DATA_OBJECT_TARGET) for Module '+CONVERT(VARCHAR(10),@ModuleId)+' is '+@TableCode+'.';
	  END

	  -- Rollback
	  BEGIN
	    BEGIN TRY
		  IF @Debug='Y'
		  PRINT 'Rollback.';

		  SET @SqlStatement = 'DELETE FROM '+@TableCode+' WHERE ETL_INSERT_RUN_ID IN '+@ModuleInstanceIdList;

		  IF @Debug='Y'
		    PRINT 'Rollback SQL statement is: '+@SqlStatement;

		  EXEC (@SqlStatement);

		  SET @SqlStatement = 'DELETE FROM omd.SOURCE_CONTROL WHERE MODULE_INSTANCE_ID IN '+@ModuleInstanceIdList;

		  IF @Debug='Y'
		    PRINT 'Source Control Rollback SQL statement is: '+@SqlStatement;

		  EXEC (@SqlStatement);

		  -- Not implemented expiry date reset. Insert only!
		  --UPDATE <Table Code> SET EXPIRY_DATETIME = '9999-12-31', CURRENT_RECORD_INDICATOR = 'Y' WHERE MODULE_INSTANCE_ID IN <List>;

	    END TRY
	    BEGIN CATCH
		  -- Module Failure
		  EXEC [omd].[UpdateModuleInstance]
			@ModuleInstanceId = @ModuleInstanceId,
			@Debug = @Debug,
			@EventCode = 'Failure';
	      SET @ProcessIndicator = 'Failure';
		  THROW
	    END CATCH
	  END

	END -- End of Rollback


    -- After rollback is completed, the process is allowed to continue.
    IF @Debug='Y'
      PRINT 'The Module Instance will be set to proceed';

    EXEC [omd].[UpdateModuleInstance]
	   @ModuleInstanceId = @ModuleInstanceId,
	   @EventCode = N'Proceed',
	   @Debug = @Debug

	SET @ProcessIndicator = 'Proceed';
    GOTO EndOfProcedure
  END TRY
  BEGIN CATCH
      -- Module Failure
    EXEC [omd].[UpdateModuleInstance]
         @ModuleInstanceId = @ModuleInstanceId,
      @Debug = @Debug,
      @EventCode = 'Failure';
	SET @ProcessIndicator = 'Failure';
    THROW
  END CATCH
  -- All branches completed

  -- The procedure should not be able to end in this part.
  -- Module Failure
  EXEC [omd].[UpdateModuleInstance]
    @ModuleInstanceId = @ModuleInstanceId,
    @Debug = @Debug,
    @EventCode = 'Failure';
  SET @ProcessIndicator = 'Failure';

  RAISERROR('Incorrect Module Evaluation path encountered (post-rollback).',1,1)

  /*
    Region: end of processing, final step.
  */

  EndOfProcedure:
   -- End label

  IF @Debug = 'Y'
  BEGIN
     BEGIN TRY
       PRINT 'Module Instance Id '+CONVERT(VARCHAR(10),@ModuleInstanceId)+' was processed';
       PRINT 'The result (processing indicator) is '+@ProcessIndicator;  
       PRINT CHAR(13)+'-- Completed.';
	 END TRY
	 BEGIN CATCH
	   THROW
	 END CATCH
  END
END
GO
/****** Object:  StoredProcedure [omd].[RunBatch]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Process: Run Batch
Purpose: Executes an ETL process / query in a DIRECT wrapper.
Input: 
  - Batch Code
  - Query (statement to execute)
  - Debug flag Y/N (default to N)
Returns:
  - Process result (success, failure)
Usage:
    DECLARE @Result VARCHAR(10);
    EXEC [omd].[RunBatch]
      @BatchCode = '<>',
      @Result = @Result OUTPUT;
    PRINT @Result;

	or

    EXEC [omd].[RunBatch]
      @BatchCode = '<>',
*/

CREATE PROCEDURE [omd].[RunBatch]
	-- Add the parameters for the stored procedure here
	@BatchCode VARCHAR(255),
	@Debug VARCHAR(1) = 'N',
	@Result VARCHAR(10) = NULL OUTPUT
AS
BEGIN

  -- Create Batch Instance
  DECLARE @BatchInstanceId INT
  EXEC [omd].[CreateBatchInstance]
    @BatchCode = @BatchCode,
    @Debug = @Debug,
    @BatchInstanceId = @BatchInstanceId OUTPUT;
  
  -- Batch Evaluation
  DECLARE @ProcessIndicator VARCHAR(10);
  EXEC [omd].[BatchEvaluation]
    @BatchInstanceId = @BatchInstanceId,
    @Debug = @Debug,
    @ProcessIndicator = @ProcessIndicator OUTPUT;

    IF @Debug = 'Y'
      PRINT @ProcessIndicator;
  
  IF @ProcessIndicator NOT IN ('Abort','Cancel') -- These are end-states for the process.
    BEGIN TRY

      /*
	    Main block, to run Modules in e.g.

       -- Module 1
	   DECLARE @QueryResult VARCHAR(10);
       EXEC [omd].[RunModule]
         @ModuleCode = '',
	     @Query = '',
		 @Debug = @Debug,
         @QueryResult = @QueryResult OUTPUT;
       PRINT @QueryResult;

	  */

	  -- End of Module Execution

      IF @Debug = 'Y'
        PRINT 'Success pathway';

      -- Batch Success
      EXEC [omd].[UpdateBatchInstance]
        @BatchInstanceId = @BatchInstanceId,
        @Debug = @Debug,
        @EventCode = 'Success'

	  SET @Result = 'Success';

   END TRY
    BEGIN CATCH
      IF @Debug = 'Y'
        PRINT 'Failure pathway';

      -- Batch Failure
      EXEC [omd].[UpdateBatchInstance]
        @BatchInstanceId = @BatchInstanceId,
        @Debug = @Debug,
        @EventCode = 'Failure';
	  
	  SET @Result = 'Failure';
	  THROW
    END CATCH
  ELSE
    SET @Result = @ProcessIndicator;

END
GO
/****** Object:  StoredProcedure [omd].[RunModule]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

CREATE PROCEDURE [omd].[RunModule]
	-- Add the parameters for the stored procedure here
	@ModuleCode VARCHAR(255),
	@Query VARCHAR(MAX),
	@Debug VARCHAR(1) = 'N',
	@QueryResult VARCHAR(10) = NULL OUTPUT
AS
BEGIN

  -- Create Module Instance
  DECLARE @ModuleInstanceId INT
  EXEC [omd].[CreateModuleInstance]
    @ModuleCode = @ModuleCode,
    @Debug = @Debug,
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
	  THROW
    END CATCH
  ELSE
    SET @QueryResult = @ProcessIndicator;

END
GO
/****** Object:  StoredProcedure [omd].[TableCondensing]    Script Date: 2020-07-20 10:01:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [omd].[TableCondensing]
                @DatabaseName VARCHAR(100),
                @SchemaName VARCHAR(100),
                @Table VARCHAR(100)                
AS

BEGIN

DECLARE @ColumnList VARCHAR(MAX)
DECLARE @KeyList VARCHAR(MAX);

-- Create a list of columns that need to be taken into evaluation for condensing (checksum)
SELECT @ColumnList =
''''+
stuff
(
                (
                                SELECT DISTINCT ', ' + COLUMN_NAME
                                FROM INFORMATION_SCHEMA.COLUMNS 
                                                WHERE TABLE_NAME = @Table AND TABLE_SCHEMA = @SchemaName
                                AND COLUMN_NAME NOT IN
                                (
                                'OMD_EVENT_DATETIME',
                                'OMD_INSERT_DATETIME',
                                'OMD_INSERT_MODULE_INSTANCE_ID',
                                'OMD_SOURCE_ROW_ID',
                                'OMD_HASH_FULL_RECORD',
                                'OMD_CHANGE_KEY',
                                'OMD_CHANGE_DATETIME'
                                )
        FOR XML PATH('')
                ),
                1,
                1,
                ''
)
+ ''''
SELECT @ColumnList = LTRIM(RTRIM(@ColumnList));
--PRINT 'Column list = '+@ColumnList


-- Create a list of keys for use in the window functions and joins
SELECT @KeyList =
''''+
stuff
(
                (
                                SELECT DISTINCT ', ' + COLUMN_NAME
                                FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
                                INNER JOIN
                                                INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KU
                                                                  ON TC.CONSTRAINT_TYPE = 'PRIMARY KEY' AND
                                                                                TC.CONSTRAINT_NAME = KU.CONSTRAINT_NAME AND 
                                                                                 KU.TABLE_NAME=@Table 
                                WHERE COLUMN_NAME NOT LIKE 'OMD_%'
                                FOR XML PATH('')
                ),
                1,
                1,
                ''
)
+ ''''

SELECT @KeyList = REPLACE(LTRIM(RTRIM(@KeyList)),'''','');
--PRINT 'Key list = '+@KeyList;


-- Translating back
DECLARE @HashSnippet VARCHAR(MAX);
SET @HashSnippet = '';

DECLARE @ColumnName VARCHAR(MAX);

DECLARE column_cursor CURSOR FOR
WITH cteSplits(starting_position, end_position)
AS     
(
    SELECT CAST(1 AS BIGINT), CHARINDEX(',', @ColumnList)
    UNION ALL
    SELECT end_position + 1, charindex(',', @ColumnList, end_position + 1)
    FROM cteSplits
    WHERE end_position > 0 -- Another delimiter was found
)
, table_names
AS     
(
SELECT LTRIM(RTRIM(REPLACE(DATA_STORE_CODE,'''',''))) AS COLUMN_NAME 
FROM 
    (
                SELECT 
                DISTINCT DATA_STORE_CODE = substring(@ColumnList, starting_position, 
                                                                                                                                                                CASE WHEN end_position = 0 
                                                                                                                                                                THEN len(@ColumnList)
                                                                                                                                                                ELSE end_position - starting_position 
                                                                                                                                                                END) FROM cteSplits
                ) RemoveTrim
)
SELECT COLUMN_NAME
FROM table_names

OPEN column_cursor

FETCH NEXT FROM column_cursor
INTO @ColumnName

WHILE @@FETCH_STATUS = 0
BEGIN

                SET @HashSnippet = @HashSnippet + '    COALESCE(CONVERT(NVARCHAR(100), '+@ColumnName+'),''!$-'') + ''#$%'' +' + CHAR(13);

FETCH NEXT FROM column_cursor INTO @ColumnName

END
CLOSE column_cursor
DEALLOCATE column_cursor

SET @HashSnippet = LEFT(@HashSnippet,DATALENGTH(@HashSnippet)-2)+CHAR(13);
--PRINT @HashSnippet


-- Build the dynamic SQL
DECLARE @FinalQuery NVARCHAR(MAX);

SET @FinalQuery = 'WITH CondensingCTE AS'+CHAR(13);
SET @FinalQuery = @FinalQuery + '('+CHAR(13);
SET @FinalQuery = @FinalQuery + 'SELECT'+CHAR(13);
SET @FinalQuery = @FinalQuery + '  HASHBYTES(''MD5'','+CHAR(13);
SET @FinalQuery = @FinalQuery + @HashSnippet;
SET @FinalQuery = @FinalQuery + '  ) AS FULL_ROW_CHECKSUM,'+CHAR(13);
SET @FinalQuery = @FinalQuery + '  *'+CHAR(13);
SET @FinalQuery = @FinalQuery + 'FROM '+@DatabaseName+'.'+@SchemaName+'.'+@Table+CHAR(13);
SET @FinalQuery = @FinalQuery + '), Subselect AS'+CHAR(13);
SET @FinalQuery = @FinalQuery + '('+CHAR(13);
SET @FinalQuery = @FinalQuery + 'SELECT'+CHAR(13);
SET @FinalQuery = @FinalQuery + '  OMD_CHANGE_KEY,'+CHAR(13);
SET @FinalQuery = @FinalQuery + '  FULL_ROW_CHECKSUM,'+CHAR(13);
SET @FinalQuery = @FinalQuery + '  LAG(FULL_ROW_CHECKSUM) OVER (PARTITION BY '+@KeyList+' ORDER BY OMD_CHANGE_KEY) AS NEXT_FULL_ROW_CHECKSUM'+CHAR(13);
SET @FinalQuery = @FinalQuery + 'FROM CondensingCTE'+CHAR(13);
SET @FinalQuery = @FinalQuery + ')'+CHAR(13);
SET @FinalQuery = @FinalQuery + 'DELETE FROM Subselect'+CHAR(13);
SET @FinalQuery = @FinalQuery + 'WHERE FULL_ROW_CHECKSUM=NEXT_FULL_ROW_CHECKSUM'+CHAR(13);

-- Spool the results
--PRINT @FinalQuery
EXECUTE sp_executesql @FinalQuery;

END
GO

