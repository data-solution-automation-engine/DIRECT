/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * [omd].[BATCH_INSTANCE]
 *
 ******************************************************************************/

SET NOCOUNT ON;
SET IDENTITY_INSERT [omd].[BATCH_INSTANCE] ON;

DECLARE @tblMerge TABLE(
   [BATCH_INSTANCE_ID]         BIGINT           NOT NULL
  ,[BATCH_ID]                  INT              NOT NULL
  ,[PARENT_BATCH_INSTANCE_ID]  BIGINT           NOT NULL
  ,[START_TIMESTAMP]           DATETIME2        NOT NULL
  ,[END_TIMESTAMP]             DATETIME2        NULL
  ,[INTERNAL_PROCESSING_CODE]  NVARCHAR (100)   NOT NULL
  ,[NEXT_RUN_STATUS_CODE]      NVARCHAR (100)   NOT NULL
  ,[EXECUTION_STATUS_CODE]     NVARCHAR (100)   NOT NULL
  ,[EXECUTION_CONTEXT]         NVARCHAR (4000)  NULL
);

INSERT INTO @tblMerge
(
   [BATCH_INSTANCE_ID]
  ,[BATCH_ID]
  ,[PARENT_BATCH_INSTANCE_ID]
  ,[START_TIMESTAMP]
  ,[END_TIMESTAMP]
  ,[INTERNAL_PROCESSING_CODE]
  ,[NEXT_RUN_STATUS_CODE]
  ,[EXECUTION_STATUS_CODE]
  ,[EXECUTION_CONTEXT]
)
VALUES
(
   0                                              -- [BATCH_INSTANCE_ID]
  ,0                                              -- [BATCH_ID]
  ,0                                              -- [PARENT_BATCH_INSTANCE_ID]
  ,CAST(N'0001-01-01T00:00:00.000' AS DATETIME2)  -- [START_TIMESTAMP]
  ,CAST(N'9999-12-31T00:00:00.000' AS DATETIME2)  -- [END_TIMESTAMP]
  ,N'Proceed'                                     -- [INTERNAL_PROCESSING_CODE]
  ,N'Proceed'                                     -- [NEXT_RUN_STATUS_CODE]
  ,N'Succeeded'                                   -- [EXECUTION_STATUS_CODE]
  ,N''                                            -- [EXECUTION_CONTEXT]
)

MERGE [omd].[BATCH_INSTANCE] AS TARGET
USING @tblMerge AS src
  ON  TARGET.[BATCH_INSTANCE_ID] = src.[BATCH_INSTANCE_ID]

WHEN MATCHED THEN
  UPDATE
  SET
     [BATCH_ID]                            = src.[BATCH_ID]
    ,[PARENT_BATCH_INSTANCE_ID]            = src.[PARENT_BATCH_INSTANCE_ID]
    ,[START_TIMESTAMP]                     = src.[START_TIMESTAMP]
    ,[END_TIMESTAMP]                       = src.[END_TIMESTAMP]
    ,[INTERNAL_PROCESSING_CODE]            = src.[INTERNAL_PROCESSING_CODE]
    ,[NEXT_RUN_STATUS_CODE]                = src.[NEXT_RUN_STATUS_CODE]
    ,[EXECUTION_STATUS_CODE]               = src.[EXECUTION_STATUS_CODE]
    ,[EXECUTION_CONTEXT]                   = src.[EXECUTION_CONTEXT]

WHEN NOT MATCHED THEN
  INSERT
  (
     [BATCH_INSTANCE_ID]
    ,[BATCH_ID]
    ,[PARENT_BATCH_INSTANCE_ID]
    ,[START_TIMESTAMP]
    ,[END_TIMESTAMP]
    ,[INTERNAL_PROCESSING_CODE]
    ,[NEXT_RUN_STATUS_CODE]
    ,[EXECUTION_STATUS_CODE]
    ,[EXECUTION_CONTEXT]
  )
  VALUES
  (
     [BATCH_INSTANCE_ID]
    ,[BATCH_ID]
    ,[PARENT_BATCH_INSTANCE_ID]
    ,[START_TIMESTAMP]
    ,[END_TIMESTAMP]
    ,[INTERNAL_PROCESSING_CODE]
    ,[NEXT_RUN_STATUS_CODE]
    ,[EXECUTION_STATUS_CODE]
    ,[EXECUTION_CONTEXT]
  );

SET IDENTITY_INSERT [omd].[BATCH_INSTANCE] OFF;

GO
