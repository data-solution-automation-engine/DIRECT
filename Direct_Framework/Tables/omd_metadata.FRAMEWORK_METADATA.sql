CREATE TABLE [omd_metadata].[FRAMEWORK_METADATA] (
  [CODE]              NVARCHAR (100)          NOT NULL,
  [VALUE]             NVARCHAR (4000)         NOT NULL,
  [GROUP]             NVARCHAR (100)          NULL,
  [DESCRIPTION]       NVARCHAR (4000)         NULL,
  [ACTIVE_INDICATOR]  CHAR (1)
    CONSTRAINT [DF_OMD_METADATA_FRAMEWORK_METADATA_ACTIVE_INDICATOR]
    DEFAULT ('Y')                             NULL,

  CONSTRAINT [PK_OMD_FRAMEWORK_METADATA]
    PRIMARY KEY ([CODE] ASC)
);
