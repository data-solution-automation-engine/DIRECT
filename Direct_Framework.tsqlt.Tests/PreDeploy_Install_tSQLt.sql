/*
   Installs the latest tSQLt framework.
   ─────────────────────────────────────
   1. Download tSQLt ##Latest.zip from https://tsqlt.org/download/
   2. Unzip and copy the file tSQLt.class.sql next to this script.
   3. The script below calls it only if not already installed.
*/

-- TODO: Dont include the tSQLt code in the repository. Rework to get it on test run.
;IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'tSQLt')
BEGIN
    -- :r .\tSQLt.class.sql   -- SQLCMD include
    select 'test' as test
END
GO
