CREATE TABLE [omd_metadata].[FREQUENCY] (
  [FREQUENCY_CODE]        NVARCHAR (100)  NOT NULL,
  [FREQUENCY_DESCRIPTION] NVARCHAR (4000) NULL,

  CONSTRAINT [PK_OMD_METADATA_FREQUENCY]
    PRIMARY KEY CLUSTERED ([FREQUENCY_CODE] ASC)
);
