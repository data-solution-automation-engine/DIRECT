
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION omd.GetPreviousModuleInstanceDetails
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