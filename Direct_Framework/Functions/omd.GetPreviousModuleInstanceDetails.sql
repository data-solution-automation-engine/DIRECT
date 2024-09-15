CREATE FUNCTION [omd].[GetPreviousModuleInstanceDetails]
(
  @ModuleId INT,
  @BatchId INT
)
RETURNS TABLE AS

-- =============================================
-- Function:    GetPreviousModuleInstanceDetails
-- Description: TODO: tba...
-- =============================================

RETURN
(
  SELECT TOP 1
     ISNULL(MAX(LastBatchInstanceID),-1)             AS [LastBatchInstanceID]
    ,ISNULL(MAX(LastModuleInstanceID),-1)            AS [LastModuleInstanceID]
    ,ISNULL(MAX(LastStartTimestamp),'1900-01-01')     AS [LastStartTimestamp]
    ,MAX(LastEndTimestamp)                            AS [LastEndTimestamp]
    ,ISNULL(MAX(LastExecutionStatus),'I')            AS [LastExecutionStatus]
    ,ISNULL(MAX(LastNextRunStatusCode),'Proceed')           AS [LastNextExecutionFlag]
    ,ISNULL(MAX(LastModuleInstanceIDList),'-1')      AS [LastModuleInstanceIDList]
    ,(SELECT ACTIVE_INDICATOR FROM [omd].[MODULE] WHERE MODULE_ID = @ModuleId) AS ActiveIndicator
  FROM
  (
    (
      SELECT
        A.BATCH_INSTANCE_ID       AS [LastBatchInstanceID],
        A.MODULE_INSTANCE_ID      AS [LastModuleInstanceID],
        A.START_TIMESTAMP         AS [LastStartTimestamp],
        A.END_TIMESTAMP           AS [LastEndTimestamp],
        A.EXECUTION_STATUS_CODE   AS [LastExecutionStatus],
        A.NEXT_RUN_STATUS_CODE    AS [LastNextRunStatusCode],
        (
          SELECT Cast(
          '(' +
            STUFF
            (
              (
             SELECT ',' + CAST(MODULE_INSTANCE_ID AS VARCHAR(20))
             FROM [omd].[MODULE_INSTANCE] MI
             LEFT JOIN [omd].[BATCH_INSTANCE] BI
               ON MI.BATCH_INSTANCE_ID = BI.BATCH_INSTANCE_ID
             WHERE MI.MODULE_ID = @ModuleId
               AND ISNULL(BI.BATCH_ID, 0) = @BatchId --only instance from the same batch / 0
               AND MI.MODULE_INSTANCE_ID >
               (
                 -- Find the last successful module run/batch run depending on if it is executed by a batch or not
                 SELECT COALESCE(MAX(MODULE_INSTANCE_ID), 0)
                 FROM omd.MODULE_INSTANCE SUB_MI
                 LEFT JOIN omd.BATCH_INSTANCE SUB_BI
                   ON SUB_MI.BATCH_INSTANCE_ID = SUB_BI.BATCH_INSTANCE_ID
                 WHERE SUB_MI.MODULE_ID = @ModuleId
                   AND COALESCE(SUB_BI.BATCH_ID, 0) = @BatchId --only instance from the same batch / 0
                   AND
                   (
                     (
                       -- last successful module run without a batch
                       @BatchId = 0
                       AND SUB_MI.EXECUTION_STATUS_CODE = N'Succeeded'
                       AND SUB_MI.NEXT_RUN_STATUS_CODE = N'Proceed'
                     )
                     OR
                     (
                       -- last successful batch run
                       @BatchId <> 0
                       AND SUB_BI.EXECUTION_STATUS_CODE = N'Succeeded'
                     )
                   )
                 )
                 AND MI.EXECUTION_STATUS_CODE NOT IN (N'Executing', N'Aborted')
                 FOR XML PATH ('')  -- convert list module id to single variable
                )
             ,1,1,''
           )
          + ')' as varchar(500)
        )
      ) AS [LastModuleInstanceIDList]

      FROM omd.MODULE_INSTANCE A
      WHERE A.MODULE_INSTANCE_ID =
      (
        (
          SELECT MAX(MODULE_INSTANCE_ID)
          FROM [omd].[MODULE_INSTANCE] WMI
          LEFT JOIN [omd].[BATCH_INSTANCE] WBI
            ON WMI.BATCH_INSTANCE_ID = WBI.BATCH_INSTANCE_ID
          WHERE WMI.MODULE_ID = @ModuleId
            AND WMI.EXECUTION_STATUS_CODE NOT IN (N'Executing', N'Aborted')
            AND COALESCE(WBI.BATCH_ID, 0) = @BatchId --only instance from the same batch / 0
        )
      )
    )

    UNION ALL -- return if there is nothing, to give at least a result.

    SELECT NULL, NULL, NULL, NULL, NULL, NULL, NULL

  ) AS sub1
)
