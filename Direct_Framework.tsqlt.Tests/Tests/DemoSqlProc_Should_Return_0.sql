CREATE PROCEDURE [omd_Tests].[Test omd_GetBatch returns 0 on Default Batch]
AS
BEGIN
    -- isolate underlying tables
    EXEC tSQLt.FakeTable @TableName = 'omd.Batch';

    -- run the proc under test
    -- add the output parameters as well here
    DECLARE @rc INT;
    EXEC @rc = [omd].[GetBatch] @BatchCode = 'DefaultBatch';

    -- assert successful execution
    -- the procedure should return 0 on success
    -- and the output parameters should return the expected values
    EXEC tSQLt.AssertEquals @Expected = 0, @Actual = @rc;
END;
GO
