/*******************************************************************************
 * Post-Deployment Script
 *******************************************************************************
 *
 * This file contains SQL statements that will be appended to the build script.
 * This is executed by SqlPackage/DacFx after the DACPAC has been deployed
 * to the target database.
 *
 * https://github.com/microsoft/DacFx
 * https://aka.ms/sqlpackage-ref
 *
 * Use SQLCMD syntax to include a file in the post-deployment script.
 * Example:      :r .\myfile.sql
 *
 * Use SQLCMD syntax to reference a variable in the post-deployment script.
 * Example:      :setvar TableName MyTable
 *               SELECT * FROM [$(TableName)]
 ******************************************************************************/

PRINT 'Post-Deployment Script Starting'

-- Reference data for metadata tables, run in dependency order
:r .\omd_metadata.LAYER.sql
:r .\omd_metadata.AREA.sql
:r .\omd_metadata.EVENT_TYPE.sql
:r .\omd_metadata.EXECUTION_STATUS.sql
:r .\omd_metadata.NEXT_RUN_STATUS.sql
:r .\omd_metadata.INTERNAL_PROCESSING_STATUS.sql
:r .\omd_metadata.FREQUENCY.sql
:r .\omd_metadata.FRAMEWORK_METADATA.sql

-- Base operational placeholders, run in dependency order
:r .\omd.BATCH.sql
:r .\omd.BATCH_INSTANCE.sql
:r .\omd.MODULE.sql
:r .\omd.MODULE_INSTANCE.sql
:r .\omd.MODULE_INSTANCE_EXECUTED_CODE.sql

-- Orchestration Process Queuing
-- Traditional on-premises SQL server/Local SQL Server instance, or Azure Managed Instance deployments only:
-- :r .\Queue_Job_Batch.sql
-- :r .\Queue_Job_Module.sql

PRINT 'Post-Deployment Script Completed'
