/* OMD Table and data creation */

USE [EDW_900_OMD_Framework]

DELETE FROM OMD_MODULE_INSTANCE;
DELETE FROM OMD_MODULE;
DELETE FROM OMD_AREA;  
DELETE FROM OMD_LAYER;
DELETE FROM OMD_BATCH_INSTANCE;
DELETE FROM OMD_BATCH;
DELETE FROM OMD_DATA_STORE;
DELETE FROM OMD_DATA_STORE_TYPE;
DELETE FROM OMD_PARAMETER;
DELETE FROM OMD_EVENT_TYPE;
DELETE FROM OMD_FREQUENCY;
DELETE FROM OMD_MODULE_TYPE;
DELETE FROM OMD_EVENT_TYPE;
DELETE FROM OMD_ERROR_BITMAP;
DELETE FROM OMD_SEVERITY;
DELETE FROM OMD_ERROR_TYPE;
DELETE FROM OMD_PROCESSING_INDICATOR;
DELETE FROM OMD_EXECUTION_STATUS;
DELETE FROM OMD_NEXT_RUN_INDICATOR;
DELETE FROM OMD_VERSION;

-- Version
INSERT INTO [OMD_VERSION]
([VERSION_ID],[COMMENTS] ,[RELEASE_DATE] )
VALUES ('1.3','Stable','2016-03-17')

-- Layer
INSERT OMD_LAYER 
(LAYER_CODE, LAYER_DESCRIPTION)
VALUES
('Staging', 'The Staging Layer'),
('Integration', 'The Integration Layer'),
('Presentation', 'The Presentation Layer')

-- Area
INSERT OMD_AREA
(AREA_CODE, AREA_DESCRIPTION, LAYER_CODE)
VALUES
('STG', 'The Staging Area of the Staging Layer', 'Staging'),
('HSTG', 'The History Area of the Staging Layer', 'Staging'),
('INT', 'The Integration Area', 'Integration'),
('INTPR', 'The Interpretation Area', 'Integration'),
('HELPER', 'The Helper Area', 'Presentation'),
('REP', 'The Reporting Structure Area', 'Presentation')

-- Severity codes
INSERT INTO OMD_SEVERITY
           ([SEVERITY_CODE]
           ,[SEVERITY_DESCRIPTION])
VALUES
('Low','Detected errors and exceptions that have minor impact on the information and ETL management. For instance typos and rounding discrepancies.'),
('Medium','Errors and exceptions that indicate data quality issues which may lead to misinterpretation in reporting, such as erroneous reference to a geographical area.'),
('High','Errors and exceptions that are deemed serious enough to be used in alerts and possibly event handling in the Presentation Layer.')


-- Parameter
INSERT INTO OMD_PARAMETER
([PARAMETER_DESCRIPTION],[PARAMETER_KEY_CODE] ,[PARAMETER_VALUE_CODE])
VALUES
('CDC net change interval','CDC Interval','Daily'),
('The Load Type which can be Disaster Recovery (DR), Normal and Initial Load.','Load Type','Disaster Recovery')

-- Event Type codes
INSERT INTO OMD_EVENT_TYPE
([EVENT_TYPE_CODE],[EVENT_TYPE_DESCRIPTION])
VALUES
('1','Infrastructural error.'),
('2','Internal SSIS error or system generated event.'),
('3','Custom exception handling that has been implemented in ETL (Error Bitmaps).')

-- Frequency
INSERT INTO OMD_FREQUENCY 
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
DELETE FROM OMD_MODULE_TYPE
INSERT INTO OMD_MODULE_TYPE
([MODULE_TYPE_CODE],[MODULE_TYPE_DESCRIPTION])
VALUES
('SSIS','SQL Server Integration Services ETL package')

-- Error Type codes
INSERT INTO OMD_ERROR_TYPE
([ERROR_TYPE_CODE],[ERROR_TYPE_DESCRIPTION])
VALUES
('1','Placeholder.'),
('2','Placeholder.'), 
('3','Data Warehouse defined Error Bitmap.')

-- Error Bitmap
INSERT INTO OMD_ERROR_BITMAP
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
INSERT INTO OMD_PROCESSING_INDICATOR
           ([PROCESSING_INDICATOR]
           ,[PROCESSING_INDICATOR_DESCRIPTION])
VALUES
('A','Abort. This indicates that the Batch/Module is already running.'),
('C','Cancel / skip. The process has determined that it is not necessary to run this ETL process.'),
('P','Proceed. The Instance can continue on to the next step of the processing.'),
('R','Rollback. During rollback processing the Processor Indicator is set to R.')    

-- Execution Status
INSERT INTO OMD_EXECUTION_STATUS
           ([EXECUTION_STATUS_CODE]
           ,[EXECUTION_STATUS_DESCRIPTION])
VALUES
('E','Executing'),
('S','Succes'),
('F','Failure'),
('C','Cancelled / skipped'),
('A','Aborted')

-- Next Run Indicator
INSERT INTO OMD_NEXT_RUN_INDICATOR
           ([NEXT_RUN_INDICATOR]
           ,[NEXT_RUN_INDICATOR_DESCRIPTION])
VALUES
('P','Proceed. The next run of the Batch/Module to set to continue processing.'),
('C','Cancelled / skipped. Administrators can manually set this code to for the Next Run Indicator.'),
('R','Rollback . Upon failure the Next Run Indicator is updated to ‘R’ to signal a rollback.')    

-- Data Store Type
INSERT INTO OMD_DATA_STORE_TYPE
           ([DATA_STORE_TYPE_CODE]
           ,[DATA_STORE_TYPE_DESCRIPTION])
VALUES
('Table','RDBMS (database) table.'),
('Flat File','ASCII text file.')

-- Placeholder values for referential integrity
-- Batch
SET IDENTITY_INSERT OMD_BATCH ON

INSERT OMD_BATCH(BATCH_ID, FREQUENCY_CODE, BATCH_CODE, BATCH_DESCRIPTION, INACTIVE_INDICATOR)
VALUES (0, 'Continuous', 'Default Batch', 'Placeholder value for dummy Batch runs', 'N')

SET IDENTITY_INSERT OMD_BATCH OFF

-- Module
SET IDENTITY_INSERT OMD_MODULE ON

INSERT OMD_MODULE(MODULE_ID, AREA_CODE, MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPE_CODE, INACTIVE_INDICATOR)
VALUES (0, 'STG', 'Default Module', 'Placeholder value for dummy Module runs', 'SSIS', 'N')

SET IDENTITY_INSERT OMD_MODULE OFF

-- Batch Instance
SET IDENTITY_INSERT OMD_BATCH_INSTANCE ON

INSERT OMD_BATCH_INSTANCE(BATCH_INSTANCE_ID, BATCH_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, BATCH_EXECUTION_SYSTEM_ID)
VALUES (0, 0, '1900-01-01', '9999-12-31', 'P', 'P', 'S', 'N/A')

SET IDENTITY_INSERT OMD_BATCH_INSTANCE OFF

-- Module Instance
SET IDENTITY_INSERT OMD_MODULE_INSTANCE ON

INSERT OMD_MODULE_INSTANCE(MODULE_INSTANCE_ID, MODULE_ID, BATCH_INSTANCE_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, MODULE_EXECUTION_SYSTEM_ID, ROWS_INPUT, ROWS_INSERTED, ROWS_UPDATED, ROWS_DELETED, ROWS_DISCARDED, ROWS_REJECTED)
VALUES (0, 0, 0,'1900-01-01', '9999-12-31', 'P', 'P', 'S', 'N/A',0,0,0,0,0,0)

SET IDENTITY_INSERT OMD_MODULE_INSTANCE OFF