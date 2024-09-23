/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * [omd].[BATCH]
 *
 ******************************************************************************/

SET NOCOUNT ON;
SET IDENTITY_INSERT [omd].[BATCH] ON;

DECLARE @tblMerge TABLE(
  [BATCH_ID]            INT               NOT NULL,
  [BATCH_CODE]          NVARCHAR (1000)   NOT NULL,
  [BATCH_TYPE]          NVARCHAR (100)    NULL,
  [FREQUENCY_CODE]      NVARCHAR (100)    NOT NULL,
  [BATCH_DESCRIPTION]   NVARCHAR (4000)   NULL,
  [ACTIVE_INDICATOR]    CHAR (1)          NOT NULL
);

INSERT INTO @tblMerge
(
  [BATCH_ID],
  [BATCH_CODE],
  [BATCH_TYPE],
  [FREQUENCY_CODE],
  [BATCH_DESCRIPTION],
  [ACTIVE_INDICATOR]
)
VALUES
  (0, N'Default Batch', N'Maintenance', N'On-demand', N'Placeholder value for disconnected Batch runs', N'Y')

MERGE [omd].[BATCH] AS TARGET
USING @tblMerge AS src
    ON  TARGET.[BATCH_ID] = src.[BATCH_ID]

WHEN MATCHED THEN
    UPDATE
    SET [BATCH_CODE]          = src.[BATCH_CODE],
        [BATCH_TYPE]          = src.[BATCH_TYPE],
        [FREQUENCY_CODE]      = src.[FREQUENCY_CODE],
        [BATCH_DESCRIPTION]   = src.[BATCH_DESCRIPTION],
        [ACTIVE_INDICATOR]    = src.[ACTIVE_INDICATOR]

WHEN NOT MATCHED THEN
    INSERT
    (
      [BATCH_ID],
      [BATCH_CODE],
      [BATCH_TYPE],
      [FREQUENCY_CODE],
      [BATCH_DESCRIPTION],
      [ACTIVE_INDICATOR]
    )
    VALUES
    (
      [BATCH_ID],
      [BATCH_CODE],
      [BATCH_TYPE],
      [FREQUENCY_CODE],
      [BATCH_DESCRIPTION],
      [ACTIVE_INDICATOR]
    );

SET IDENTITY_INSERT [omd].[BATCH] OFF;

GO
