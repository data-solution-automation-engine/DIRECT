/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * Reference metadata table EVENT_TYPE stores event type codes and descriptions.
 * This script is used to insert and update reference data on deployment.
 * Any bespoke event types added manually to the target will be retained,
 * as long as the keys differ.
 * To maintain a clean CI/CD process, consider using this script to manage
 * all reference data for event types.
 *
 * [omd_metadata].[EVENT_TYPE]
 *
 ******************************************************************************/

SET NOCOUNT ON;

DECLARE @tblMerge TABLE(
  [EVENT_TYPE_CODE]             NVARCHAR (100)  NOT NULL PRIMARY KEY CLUSTERED,
  [EVENT_TYPE_CODE_DESCRIPTION] NVARCHAR (4000) NULL
);

INSERT INTO @tblMerge([EVENT_TYPE_CODE], [EVENT_TYPE_CODE_DESCRIPTION])
VALUES
 (N'1', N'Infrastructure error.'),
 (N'2', N'Internal data integration process error or system generated event.'),
 (N'3', N'Custom exception handling that has been implemented in code (Error Bitmaps).')

MERGE [omd_metadata].[EVENT_TYPE] AS TARGET
USING @tblMerge AS src
    ON  TARGET.[EVENT_TYPE_CODE] = src.[EVENT_TYPE_CODE]

WHEN MATCHED THEN
    UPDATE
    SET    [EVENT_TYPE_CODE_DESCRIPTION] = src.[EVENT_TYPE_CODE_DESCRIPTION]

WHEN NOT MATCHED THEN
    INSERT  ([EVENT_TYPE_CODE]
            ,[EVENT_TYPE_CODE_DESCRIPTION])
    VALUES  ([EVENT_TYPE_CODE]
            ,[EVENT_TYPE_CODE_DESCRIPTION]);

GO
