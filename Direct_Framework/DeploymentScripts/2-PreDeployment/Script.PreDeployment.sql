/*******************************************************************************
 * Pre-Deployment Script Template
 *******************************************************************************
 *
 * This file contains SQL statements that will be prepended to the build script.
 * This is executed by SqlPackage/DacFx before the DACPAC has been deployed
 * to the target database. The results are not included in the state compare.
 *
 * https://github.com/microsoft/DacFx
 * https://aka.ms/sqlpackage-ref
 *
 * Use SQLCMD syntax to include a file in the pre-deployment script.
 * Example:      :r .\myfile.sql
 *
 * Use SQLCMD syntax to reference a variable in the pre-deployment script.
 * Example:      :setvar TableName MyTable
 *               SELECT * FROM [$(TableName)]
 ******************************************************************************/

PRINT 'Pre-Deployment Script Starting'

-- placeholder contents...
PRINT 'Pre-Deployment Script is doing nothing...'
-- Do some setup, migration or prepare work as part of pre-deployment
-- :r .\SomeScriptFile.sql

PRINT 'Pre-Deployment Script Completed'
