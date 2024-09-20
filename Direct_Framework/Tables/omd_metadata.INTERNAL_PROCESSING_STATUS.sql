CREATE TABLE [omd_metadata].[INTERNAL_PROCESSING_STATUS] (
  [INTERNAL_PROCESSING_STATUS_CODE]             NVARCHAR (100)   NOT NULL,
  [INTERNAL_PROCESSING_STATUS_CODE_DESCRIPTION] NVARCHAR (4000)  NULL,

  CONSTRAINT [PK_OMD_METADATA_INTERNAL_PROCESSING_STATUS]
    PRIMARY KEY CLUSTERED ([INTERNAL_PROCESSING_STATUS_CODE] ASC)
);