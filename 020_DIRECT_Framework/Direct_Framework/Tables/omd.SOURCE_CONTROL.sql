﻿CREATE TABLE [omd].[SOURCE_CONTROL] (
    [MODULE_SOURCE_CONTROL_ID]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [MODULE_ID]                 INT           NOT NULL,
    [MODULE_INSTANCE_ID]        INT           NOT NULL,
    [INSERT_DATETIME]           DATETIME2 (7) NULL,
    [START_VALUE]               DATETIME2 (7) NULL,
    [END_VALUE]                 DATETIME2 (7) NULL,
    CONSTRAINT PK_SOURCE_CONTROL PRIMARY KEY CLUSTERED ([MODULE_SOURCE_CONTROL_ID] ASC),
    CONSTRAINT FK_MODULE_INSTANCE_SOURCE_CONTROL FOREIGN KEY ([MODULE_INSTANCE_ID]) REFERENCES [omd].[MODULE_INSTANCE] ([MODULE_INSTANCE_ID])
);

