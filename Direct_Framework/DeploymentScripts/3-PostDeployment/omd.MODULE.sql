/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * [omd].[MODULE]
 *
 ******************************************************************************/

SET NOCOUNT ON;
SET IDENTITY_INSERT [omd].[MODULE] ON;

DECLARE @tblMerge TABLE(
  [MODULE_ID]           INT             NOT NULL,
  [MODULE_CODE]         NVARCHAR (1000) NOT NULL,
  [MODULE_DESCRIPTION]  NVARCHAR (4000) NOT NULL,
  [MODULE_TYPE]         NVARCHAR (100)  NOT NULL,
  [DATA_OBJECT_SOURCE]  NVARCHAR (1000) NOT NULL,
  [DATA_OBJECT_TARGET]  NVARCHAR (1000) NOT NULL,
  [AREA_CODE]           NVARCHAR (100)  NOT NULL,
  [FREQUENCY_CODE]      NVARCHAR (100)  NOT NULL,
  [ACTIVE_INDICATOR]    CHAR (1)        NOT NULL,
  [EXECUTABLE]          NVARCHAR (MAX)  NOT NULL
);

INSERT INTO @tblMerge
(
  [MODULE_ID],
  [MODULE_CODE],
  [MODULE_DESCRIPTION],
  [MODULE_TYPE],
  [DATA_OBJECT_SOURCE],
  [DATA_OBJECT_TARGET],
  [AREA_CODE],
  [FREQUENCY_CODE],
  [ACTIVE_INDICATOR],
  [EXECUTABLE]
)
VALUES
(
  0,
  N'Default Module',
  N'Placeholder value for disconnected Module runs',
  N'DataLogistics',
  N'N/A',
  N'N/A',
  N'Maintenance',
  N'On-demand',
  'Y',
  N'SELECT NULL'
)

MERGE [omd].[MODULE] AS TARGET
USING @tblMerge AS src
    ON  TARGET.[MODULE_ID] = src.[MODULE_ID]

WHEN MATCHED THEN
    UPDATE
    SET
  [MODULE_CODE]         = src.[MODULE_CODE],
  [MODULE_DESCRIPTION]  = src.[MODULE_DESCRIPTION],
  [MODULE_TYPE]         = src.[MODULE_TYPE],
  [DATA_OBJECT_SOURCE]  = src.[DATA_OBJECT_SOURCE],
  [DATA_OBJECT_TARGET]  = src.[DATA_OBJECT_TARGET],
  [AREA_CODE]           = src.[AREA_CODE],
  [FREQUENCY_CODE]      = src.[FREQUENCY_CODE],
  [ACTIVE_INDICATOR]    = src.[ACTIVE_INDICATOR],
  [EXECUTABLE]          = src.[EXECUTABLE]

WHEN NOT MATCHED THEN
INSERT
(
  [MODULE_ID],
  [MODULE_CODE],
  [MODULE_DESCRIPTION],
  [MODULE_TYPE],
  [DATA_OBJECT_SOURCE],
  [DATA_OBJECT_TARGET],
  [AREA_CODE],
  [FREQUENCY_CODE],
  [ACTIVE_INDICATOR],
  [EXECUTABLE]
)
VALUES
(
  [MODULE_ID],
  [MODULE_CODE],
  [MODULE_DESCRIPTION],
  [MODULE_TYPE],
  [DATA_OBJECT_SOURCE],
  [DATA_OBJECT_TARGET],
  [AREA_CODE],
  [FREQUENCY_CODE],
  [ACTIVE_INDICATOR],
  [EXECUTABLE]
);

SET IDENTITY_INSERT [omd].[MODULE] OFF;

GO
