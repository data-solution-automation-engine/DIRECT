CREATE TABLE [omd_metadata].[AREA] (
  [AREA_CODE]        NVARCHAR (100)  NOT NULL,
  [LAYER_CODE]       NVARCHAR (100)  NOT NULL,
  [AREA_DESCRIPTION] NVARCHAR (4000) NULL,

  CONSTRAINT [PK_OMD_METADATA_AREA]
    PRIMARY KEY CLUSTERED ([AREA_CODE] ASC),

  CONSTRAINT [FK_OMD_METADATA_AREA_OMD_METADATA_LAYER]
    FOREIGN KEY ([LAYER_CODE])
    REFERENCES [omd_metadata].[LAYER] ([LAYER_CODE])
);
