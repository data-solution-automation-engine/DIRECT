CREATE VIEW [omd_reporting].[vw_EXCEPTIONS_TABLE_CONSISTENCY] AS
WITH TableCheckCTE AS
(
SELECT
                a.TABLE_CATALOG,
                a.TABLE_SCHEMA,
                a.TABLE_NAME,
                b.COLUMN_NAME,
                b.ORDINAL_POSITION
FROM INFORMATION_SCHEMA.TABLES a 
JOIN  INFORMATION_SCHEMA.COLUMNS b ON a.TABLE_NAME=b.TABLE_NAME
WHERE TABLE_TYPE='BASE TABLE' AND a.TABLE_SCHEMA <> 'omd'
), Attribute_Detection AS
(
SELECT 
                TABLE_CATALOG,
                TABLE_NAME,
                TABLE_SCHEMA,
                COLUMN_NAME,
                CASE WHEN COLUMN_NAME = 'OMD_INSERT_MODULE_INSTANCE_ID' THEN 1 ELSE 0 END AS HAS_OMD_INSERT_MODULE_INSTANCE_ID,
                CASE WHEN COLUMN_NAME = 'OMD_INSERT_DATETIME' THEN 1 ELSE 0 END AS HAS_OMD_INSERT_DATETIME,
                CASE WHEN COLUMN_NAME = 'OMD_EVENT_DATETIME' THEN 1 ELSE 0 END AS HAS_OMD_EVENT_DATETIME,
                CASE WHEN COLUMN_NAME = 'OMD_RECORD_SOURCE' THEN 1 ELSE 0 END AS HAS_OMD_RECORD_SOURCE,
                CASE WHEN COLUMN_NAME = 'OMD_SOURCE_ROW_ID' THEN 1 ELSE 0 END AS HAS_OMD_SOURCE_ROW_ID,
                CASE WHEN COLUMN_NAME = 'OMD_CDC_OPERATION' THEN 1 ELSE 0 END AS HAS_OMD_CDC_OPERATION,
                CASE WHEN COLUMN_NAME = 'OMD_HASH_FULL_RECORD' THEN 1 ELSE 0 END AS HAS_OMD_HASH_FULL_RECORD,
                CASE WHEN COLUMN_NAME = 'OMD_CURRENT_RECORD_INDICATOR' THEN 1 ELSE 0 END AS HAS_OMD_CURRENT_RECORD_INDICATOR,
    CASE WHEN COLUMN_NAME = 'OMD_CHANGE_DATETIME' THEN 1 ELSE 0 END AS HAS_OMD_CHANGE_DATETIME,
                CASE WHEN COLUMN_NAME = 'OMD_CHANGE_KEY' THEN 1 ELSE 0 END AS HAS_OMD_CHANGE_KEY
FROM TableCheckCTE
), SingleRowAttributeEvaluation AS
(
SELECT 
                TABLE_CATALOG, 
                TABLE_NAME, 
                TABLE_SCHEMA,
                SUM(HAS_OMD_INSERT_MODULE_INSTANCE_ID) AS HAS_OMD_INSERT_MODULE_INSTANCE_ID,
                SUM(HAS_OMD_INSERT_DATETIME) AS HAS_OMD_INSERT_DATETIME,
                SUM(HAS_OMD_EVENT_DATETIME) AS HAS_OMD_EVENT_DATETIME,
                SUM(HAS_OMD_RECORD_SOURCE) AS HAS_OMD_RECORD_SOURCE,
                SUM(HAS_OMD_SOURCE_ROW_ID) AS HAS_OMD_SOURCE_ROW_ID,
                SUM(HAS_OMD_CDC_OPERATION) AS HAS_OMD_CDC_OPERATION,
                SUM(HAS_OMD_HASH_FULL_RECORD) AS HAS_OMD_HASH_FULL_RECORD,
                SUM(HAS_OMD_CURRENT_RECORD_INDICATOR) AS HAS_OMD_CURRENT_RECORD_INDICATOR,
                SUM(HAS_OMD_CHANGE_DATETIME) AS HAS_OMD_CHANGE_DATETIME,
                SUM(HAS_OMD_CHANGE_KEY) AS HAS_OMD_CHANGE_KEY
FROM Attribute_Detection 
GROUP BY
                TABLE_CATALOG,
                TABLE_NAME,
                TABLE_SCHEMA
), ErrorEvaluation AS
(
SELECT
                TABLE_CATALOG, 
                TABLE_NAME, 
                TABLE_SCHEMA,
                CASE WHEN HAS_OMD_INSERT_MODULE_INSTANCE_ID = 0 THEN 'No change date/time attribute is defined.' ELSE '' END AS ERROR_OMD_INSERT_MODULE_INSTANCE_ID,
                CASE WHEN HAS_OMD_INSERT_DATETIME = 0 THEN 'No insert datetime attribute is defined.' ELSE '' END AS ERROR_OMD_INSERT_DATETIME,
                CASE WHEN HAS_OMD_EVENT_DATETIME = 0 THEN 'No event date/time attribute is defined.' ELSE '' END AS ERROR_OMD_EVENT_DATETIME,
                CASE WHEN HAS_OMD_RECORD_SOURCE = 0 THEN 'No record source attribute is defined.' ELSE '' END AS ERROR_OMD_RECORD_SOURCE,
                CASE WHEN HAS_OMD_SOURCE_ROW_ID = 0 THEN 'No source row ID attribute is defined.' ELSE '' END AS ERROR_OMD_SOURCE_ROW_ID,
                CASE WHEN HAS_OMD_CDC_OPERATION = 0 THEN 'No cdc operation attribute is defined.' ELSE '' END AS ERROR_OMD_CDC_OPERATION,
                CASE WHEN HAS_OMD_HASH_FULL_RECORD = 0 THEN 'No full row hash attribute is defined.' ELSE '' END AS ERROR_HASH_FULL_RECORD,
                CASE WHEN HAS_OMD_CURRENT_RECORD_INDICATOR = 0 THEN 'No current record indicator attribute is defined.' ELSE '' END AS ERROR_CURRENT_RECORD_INDICATOR,
                CASE WHEN HAS_OMD_CHANGE_DATETIME = 0 THEN 'No change date/time attribute is defined.' ELSE '' END AS ERROR_OMD_CHANGE_DATETIME,
                CASE WHEN HAS_OMD_CHANGE_KEY = 0 THEN 'No change key attribute is defined.' ELSE '' END AS ERROR_OMD_CHANGE_KEY
                                
FROM SingleRowAttributeEvaluation
), SingleErrorEvaluation AS
(
SELECT 
                TABLE_CATALOG, 
                TABLE_NAME, 
                TABLE_SCHEMA,
                LTRIM(RTRIM(
                                ERROR_OMD_INSERT_MODULE_INSTANCE_ID + ' ' + 
                                ERROR_OMD_INSERT_DATETIME + ' ' +
                                ERROR_OMD_EVENT_DATETIME + ' ' +
                                ERROR_OMD_RECORD_SOURCE + ' ' +
                                ERROR_OMD_SOURCE_ROW_ID + ' ' +
                                ERROR_OMD_CDC_OPERATION + ' ' +
                                ERROR_HASH_FULL_RECORD + ' ' +
                                ERROR_CURRENT_RECORD_INDICATOR + ' ' +
                                ERROR_OMD_CHANGE_KEY + ' ' + 
                                ERROR_OMD_CHANGE_DATETIME + ' ' 
                )) AS ERROR_TOTAL
FROM ErrorEvaluation
)
SELECT * FROM SingleErrorEvaluation
WHERE ERROR_TOTAL!=''
