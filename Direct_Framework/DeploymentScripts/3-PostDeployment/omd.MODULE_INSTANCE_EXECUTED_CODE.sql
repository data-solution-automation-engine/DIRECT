/*******************************************************************************
 * https://github.com/data-solution-automation-engine/DIRECT
 * Reference data insert and update script
 * DIRECT Framework v2.0
 *
 * [omd].[MODULE_INSTANCE_EXECUTED_CODE]
 *
 ******************************************************************************/

SET NOCOUNT ON;

DECLARE @tblMerge TABLE
(
  [CHECKSUM]      VARBINARY(64) NOT NULL,
  [EXECUTED_CODE] NVARCHAR(MAX) NOT NULL
);

INSERT INTO @tblMerge
(
  [CHECKSUM],
  [EXECUTED_CODE]
)
VALUES
(
  -- special 0-hash key placeholder for null or empty code
  CONVERT(VARBINARY(64), REPLICATE(0x00, 64)),  -- [CHECKSUM],
  N''                                           -- [EXECUTED_CODE]
)

MERGE [omd].[MODULE_INSTANCE_EXECUTED_CODE] AS TARGET
USING @tblMerge AS src
  ON TARGET.[CHECKSUM] = src.[CHECKSUM]

WHEN MATCHED THEN
  UPDATE
  SET
    [EXECUTED_CODE] = src.[EXECUTED_CODE]

WHEN NOT MATCHED THEN
  INSERT
  (
    [CHECKSUM], [EXECUTED_CODE]
  )
  VALUES
  (
    [CHECKSUM], [EXECUTED_CODE]
  );

GO
