/* 
	DIRECT process control default data 
    https://github.com/RoelantVos/DIRECT/
*/

--USE [<sample source database name>]

--GO

--DELETE FROM [MODULE_INSTANCE];
--DELETE FROM [MODULE];
--DELETE FROM [AREA];
--DELETE FROM [LAYER];
--DELETE FROM [BATCH_INSTANCE];
--DELETE FROM [BATCH];
--DELETE FROM [DATA_STORE];
--DELETE FROM [DATA_STORE_TYPE];
--DELETE FROM [PARAMETER];
--DELETE FROM [EVENT_TYPE];
--DELETE FROM [FREQUENCY];
--DELETE FROM [MODULE_TYPE];
--DELETE FROM [EVENT_TYPE];
--DELETE FROM [ERROR_BITMAP];
--DELETE FROM [SEVERITY];
--DELETE FROM [ERROR_TYPE];
--DELETE FROM [PROCESSING_INDICATOR];
--DELETE FROM [EXECUTION_STATUS];
--DELETE FROM [NEXT_RUN_INDICATOR];
--DELETE FROM [VERSION];

-- Version
INSERT INTO [VERSION]
([VERSION_ID],[COMMENTS] ,[RELEASE_DATE] )
VALUES ('1.5','Stable','2018-02-04')

-- Layer
INSERT LAYER 
(LAYER_CODE, LAYER_DESCRIPTION)
VALUES
('Staging', 'The Staging Layer'),
('Integration', 'The Integration Layer'),
('Presentation', 'The Presentation Layer')

-- Area
INSERT AREA
(AREA_CODE, AREA_DESCRIPTION, LAYER_CODE)
VALUES
('STG', 'The Staging Area', 'Staging'),
('HSTG', 'The Persistent Staging Area', 'Staging'),
('INT', 'The Integration Area', 'Integration'),
('PRES', 'The Presentation / Marts Area', 'Presentation')

-- Severity codes
INSERT INTO SEVERITY
           ([SEVERITY_CODE]
           ,[SEVERITY_DESCRIPTION])
VALUES
('Low','Detected errors and exceptions that have minor impact on the information and ETL management. For instance typos and rounding discrepancies.'),
('Medium','Errors and exceptions that indicate data quality issues which may lead to misinterpretation in reporting, such as erroneous reference to a geographical area.'),
('High','Errors and exceptions that are deemed serious enough to be used in alerts and possibly event handling in the Presentation Layer.')


-- Parameter
INSERT INTO PARAMETER
([PARAMETER_DESCRIPTION],[PARAMETER_KEY_CODE] ,[PARAMETER_VALUE_CODE])
VALUES
('CDC net change interval','CDC Interval','Daily'),
('The Load Type which can be Disaster Recovery (DR), Normal and Initial Load.','Load Type','Disaster Recovery')

-- Event Type codes
INSERT INTO EVENT_TYPE
([EVENT_TYPE_CODE],[EVENT_TYPE_DESCRIPTION])
VALUES
('1','Infrastructural error.'),
('2','Internal SSIS error or system generated event.'),
('3','Custom exception handling that has been implemented in ETL (Error Bitmaps).')

-- Frequency
INSERT INTO FREQUENCY 
(FREQUENCY_CODE, FREQUENCY_DESCRIPTION)
VALUES
('Adhoc', 'Only runs on an Ad-Hoc basis'),
('Monthly', 'Batches and Modules will be run once a month'),
('Fortnightly', 'Batches and Modules will be run once every two weeks'),
('Weekly', 'Batches and Modules will be run once a week'),
('Daily', 'Batches and Modules will be run once a day'),
('Hourly', 'Batches and Modules are run every hour'),
('Continuous', 'Batches and Modules as often as possible (near-realtime)')

-- Module Type
DELETE FROM MODULE_TYPE
INSERT INTO MODULE_TYPE
([MODULE_TYPE_CODE],[MODULE_TYPE_DESCRIPTION])
VALUES
('SSIS','SQL Server Integration Services ETL package')

-- Error Type codes
INSERT INTO ERROR_TYPE
([ERROR_TYPE_CODE],[ERROR_TYPE_DESCRIPTION])
VALUES
('1','Placeholder.'),
('2','Placeholder.'), 
('3','Data Warehouse defined Error Bitmap.')

-- Error Bitmap
INSERT INTO ERROR_BITMAP
([ERROR_ID],[SEVERITY_CODE],[ERROR_TYPE_CODE] ,[ERROR_DESCRIPTION])
VALUES
(1,'Low','3','Error Bitmap Placeholder'),
(2,'Low','3','Error Bitmap Placeholder'),
(4,'Low','3','Error Bitmap Placeholder'),
(8,'Low','3','Error Bitmap Placeholder'),
(16,'Low','3','Error Bitmap Placeholder'),
(32,'Low','3','Error Bitmap Placeholder'),
(64,'Low','3','Error Bitmap Placeholder'),
(128,'Low','3','Error Bitmap Placeholder')
 
-- Processing Indicator
INSERT INTO PROCESSING_INDICATOR
           ([PROCESSING_INDICATOR]
           ,[PROCESSING_INDICATOR_DESCRIPTION])
VALUES
('A','Abort. This indicates that the Batch/Module is already running.'),
('C','Cancel / skip. The process has determined that it is not necessary to run this ETL process.'),
('P','Proceed. The Instance can continue on to the next step of the processing.'),
('R','Rollback. During rollback processing the Processor Indicator is set to R.')    

-- Execution Status
INSERT INTO EXECUTION_STATUS
           ([EXECUTION_STATUS_CODE]
           ,[EXECUTION_STATUS_DESCRIPTION])
VALUES
('E','Executing'),
('S','Succes'),
('F','Failure'),
('C','Cancelled / skipped'),
('A','Aborted')

-- Next Run Indicator
INSERT INTO NEXT_RUN_INDICATOR
           ([NEXT_RUN_INDICATOR]
           ,[NEXT_RUN_INDICATOR_DESCRIPTION])
VALUES
('P','Proceed. The next run of the Batch/Module to set to continue processing.'),
('C','Cancelled / skipped. Administrators can manually set this code to for the Next Run Indicator.'),
('R','Rollback . Upon failure the Next Run Indicator is updated to ‘R’ to signal a rollback.')    

-- Data Store Type
INSERT INTO DATA_STORE_TYPE
           ([DATA_STORE_TYPE_CODE]
           ,[DATA_STORE_TYPE_DESCRIPTION])
VALUES
('Table','RDBMS (database) table.'),
('Flat File','ASCII text file.')

-- Placeholder values for referential integrity
-- Batch
SET IDENTITY_INSERT [BATCH] ON

INSERT BATCH(BATCH_ID, FREQUENCY_CODE, BATCH_CODE, BATCH_DESCRIPTION, INACTIVE_INDICATOR)
VALUES (0, 'Continuous', 'Default Batch', 'Placeholder value for dummy Batch runs', 'N')

SET IDENTITY_INSERT [BATCH] OFF

-- Module
SET IDENTITY_INSERT MODULE ON

INSERT MODULE(MODULE_ID, AREA_CODE, MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPE_CODE, FREQUENCY_CODE, INACTIVE_INDICATOR)
VALUES (0, 'STG', 'Default Module', 'Placeholder value for dummy Module runs', 'SSIS', 'Continous', 'N')

SET IDENTITY_INSERT MODULE OFF

-- Batch Instance
SET IDENTITY_INSERT BATCH_INSTANCE ON

INSERT BATCH_INSTANCE(BATCH_INSTANCE_ID, BATCH_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, BATCH_EXECUTION_SYSTEM_ID)
VALUES (0, 0, '1900-01-01', '9999-12-31', 'P', 'P', 'S', 'N/A')

SET IDENTITY_INSERT BATCH_INSTANCE OFF

-- Module Instance
SET IDENTITY_INSERT MODULE_INSTANCE ON

INSERT MODULE_INSTANCE(MODULE_INSTANCE_ID, MODULE_ID, BATCH_INSTANCE_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, MODULE_EXECUTION_SYSTEM_ID, ROWS_INPUT, ROWS_INSERTED, ROWS_UPDATED, ROWS_DELETED, ROWS_DISCARDED, ROWS_REJECTED)
VALUES (0, 0, 0,'1900-01-01', '9999-12-31', 'P', 'P', 'S', 'N/A',0,0,0,0,0,0)

SET IDENTITY_INSERT MODULE_INSTANCE OFF