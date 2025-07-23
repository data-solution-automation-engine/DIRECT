# Release Notes

## Release 2.1.0

Changes:

* `BATCH_CODE`, `MODULE_CODE` and `PARAMETER_CODE` has changed data type to `NVARCHAR(500)` to allow indexing.
* SOURCE_CONTROL code has been aligned with the agnostic string format  
  Values are stored as `NVARCHAR(100)` in the table
* Several tables have had their column names updated to adhere to the naming convention
  * tba is called tba
  * and so on
* stored procedures `omd.CreateBatchInstance` and `omd.CreateModuleInstance` now returns the start time inserted into the database as well as the instance id. This can be used in external orchestration scenarios to align the data processing with the batch start timestamp
* `omd.FRAMEWORK_METADATA` column `ACTIVE_INDICATOR` is non-nullable, migration is defaulting any existing null values to `N`
* `omd.FRAMEWORK_METADATA` has some extra helpers, used in the stored procedures:  
  * tba
  