CREATE TABLE [omd_metadata].[LAYER] (
  [LAYER_CODE]        NVARCHAR (100)  NOT NULL,
  [LAYER_DESCRIPTION] NVARCHAR (4000) NULL,

  CONSTRAINT [PK_OMD_METADATA_LAYER]
    PRIMARY KEY CLUSTERED ([LAYER_CODE] ASC)
);
