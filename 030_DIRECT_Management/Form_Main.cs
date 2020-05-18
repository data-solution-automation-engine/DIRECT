using Microsoft.SqlServer.Management.Common;
using Microsoft.SqlServer.Management.Smo;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Windows.Forms;

namespace DIRECT_Manager
{


    public partial class FormMain : Form
    {
        public FormMain()
        {
            InitializeComponent();

            // Create the target (output) paths, if they don't exist already. Load the configuration file, or create a new template one if it doesn't exist.
            InitializePath();

            richTextBoxInformation.Text = "Application initialised - Data Integration Runtime Execution Control Tool (DIRECT) Management. \r\n\r\n";

            try
            {
                InitialiseConnections(GlobalVariables.ConfigurationPath + GlobalVariables.ConfigfileName);
            }
            catch (Exception ex)
            {
                richTextBoxInformation.Text += "Errors occured trying to load the configuration file, the message is " + ex + ". No default values were loaded. \r\n\r\n";
            }


            //InitialiseSourceTargetPaths();

            //Programmatically enable checkboxes
            checkBoxGenerateStg.Checked = true;
            checkBoxGenerateHstg.Checked = true;
            checkBoxGenerateBatches.Checked = true;
            checkBoxGenerateDataStore.Checked = true;
            checkBoxGenerateEndDating.Checked = true;
            checkBoxGenerateInt.Checked = true;
            checkBoxGenerateModules.Checked = true;
            checkBoxGenerateBatchModule.Checked = true;
            checkBoxIfExists.Checked = true;
            checkBoxGenerateDataStoreModule.Checked = true;
            radioButtonETLGenerationMetadata.Checked = true;

            //Run inital form content - if possible
            PopulateCheckbox();

            //Populate the content on the re-initialisation page - if possible
            PopulateReinitialisationCheckbox();
        }


        private void ButtonGenerateMetadata(object sender, EventArgs e)
        {
            if (checkedListBoxStagingTables.CheckedItems.Count != 0)
            {
                richTextBoxInformation.Clear();

                // Initial SQL and creation of output content (stringbuilder)
                var insertIntoStatement = new StringBuilder();
                var metadataDatabaseName = textBoxGenerationMetadataDatabaseName;

                insertIntoStatement.AppendLine("/* Run the following in ETL control framework database */");
                insertIntoStatement.AppendLine("USE ["+textBoxDirectDatabase.Text+"];");
                insertIntoStatement.AppendLine();

                // Add the initial delete statements
                if (checkBoxAddDelete.Checked)
                {
                    AddDeletes(insertIntoStatement);
                }

                // Module statements
                if (checkBoxGenerateModules.Checked)
                {
                    if (checkBoxGenerateStg.Checked == false && checkBoxGenerateHstg.Checked == false && checkBoxGenerateInt.Checked == false && checkBoxGenerateEndDating.Checked == false)
                    {
                        richTextBoxInformation.Text = "No valid selection was made to generate outputs!";
                    }
                    else
                    {
                        AddModuleContent(insertIntoStatement);
                    }
                }

                // Batch statements
                if (checkBoxGenerateBatches.Checked)
                {
                    if (checkBoxGenerateStg.Checked == false && checkBoxGenerateHstg.Checked == false && checkBoxGenerateInt.Checked == false && checkBoxGenerateEndDating.Checked == false)
                    {
                        richTextBoxInformation.Text = "No valid selection was made to generate outputs!";
                    }
                    else
                    {
                        AddBatchContent(insertIntoStatement);
                    }
                }

                // Batch / Module statements
                if (checkBoxGenerateBatchModule.Checked)
                {
                    if (checkBoxGenerateStg.Checked == false && checkBoxGenerateHstg.Checked == false && checkBoxGenerateInt.Checked == false && checkBoxGenerateEndDating.Checked == false)
                    {
                        richTextBoxInformation.Text = "No valid selection was made to generate outputs!";
                    }
                    else
                    {
                        AddBatchModuleContent(insertIntoStatement);
                    }
                }

                // Data Store statements
                if (checkBoxGenerateDataStore.Checked)
                {
                    if (checkBoxGenerateStg.Checked == false && checkBoxGenerateHstg.Checked == false && checkBoxGenerateInt.Checked == false && checkBoxGenerateEndDating.Checked == false)
                    {
                        richTextBoxInformation.Text = "No valid selection was made to generate outputs!";
                    }
                    else
                    {
                        AddDataStoreContent(insertIntoStatement);
                    }
                }

                // Module / Data Store statements
                if (checkBoxGenerateDataStoreModule.Checked)
                {
                    if (checkBoxGenerateStg.Checked == false && checkBoxGenerateHstg.Checked == false && checkBoxGenerateInt.Checked == false && checkBoxGenerateEndDating.Checked == false)
                    {
                        richTextBoxInformation.Text = "No valid selection was made to generate outputs!";
                    }
                    else
                    {
                        AddModuleDataStoreContent(insertIntoStatement);
                    }
                }

                //Output
                DebuggingTextbox.Text = insertIntoStatement.ToString();

                //if (checkBoxInitial.Checked)
                //{
                //    GenerateInitialMetadata();
                //}
            } else
            {
                MessageBox.Show("No Staging Area tables were selected to process...");
            }

            this.MainTabControl.SelectedTab = tabPageOutput;
        }

        private void AddModuleContent(StringBuilder insertIntoStatement)
        {
            #region Staging Area
            // Adding the Staging Area if required
            if (checkBoxGenerateStg.Checked)
            {
                insertIntoStatement.AppendLine();
                insertIntoStatement.AppendLine("--");
                insertIntoStatement.AppendLine("-- Staging Area Modules ");
                insertIntoStatement.AppendLine("-- Generated at " + DateTime.Now);
                insertIntoStatement.AppendLine("--");

                if (checkedListBoxStagingTables.CheckedItems.Count != 0)
                {
                    for (int x = 0; x <= checkedListBoxStagingTables.CheckedItems.Count - 1; x++)
                    {
                        // Generate Staging Area
                        var stagingTableName = checkedListBoxStagingTables.CheckedItems[x].ToString();
                        stagingTableName = stagingTableName.Replace("_VW", "");

                        insertIntoStatement.AppendLine();
                        insertIntoStatement.AppendLine("--");
                        insertIntoStatement.AppendLine("-- " + stagingTableName);
                        insertIntoStatement.AppendLine("--");
                        insertIntoStatement.AppendLine();

                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM MODULE WHERE MODULE_CODE='m_100_" + stagingTableName + "')");
                        }
                        insertIntoStatement.AppendLine("INSERT INTO [OMODULE] ([AREA_CODE], [MODULE_CODE], [MODULE_DESCRIPTION], [MODULE_TYPE_CODE], [FREQUENCY_CODE])");
                        insertIntoStatement.AppendLine("VALUES ('STG','m_100_" + stagingTableName +
                                                       "','Source to Staging ETL for " +
                                                       stagingTableName + "', 'SSIS', 'Queue')");
                    }
                }
                else
                {
                    richTextBoxInformation.Text =
                        "There was no metadata available to generate STG and HSTG Modules and Batches. Please check the metadata schema or the database connection.";
                }
            }
            #endregion
            
            #region History Area
            // History area Modules
            if (checkBoxGenerateHstg.Checked)
            {
                insertIntoStatement.AppendLine();
                insertIntoStatement.AppendLine("--");
                insertIntoStatement.AppendLine("-- History Area Modules ");
                insertIntoStatement.AppendLine("-- Generated at " + DateTime.Now);
                insertIntoStatement.AppendLine("--");

                if (checkedListBoxStagingTables.CheckedItems.Count != 0)
                {
                    for (int x = 0; x <= checkedListBoxStagingTables.CheckedItems.Count - 1; x++)
                    {
                        var stagingTableName = checkedListBoxStagingTables.CheckedItems[x].ToString();
                        stagingTableName = stagingTableName.Replace("_VW", "");

                        insertIntoStatement.AppendLine();
                        insertIntoStatement.AppendLine("--");
                        insertIntoStatement.AppendLine("-- H" + stagingTableName);
                        insertIntoStatement.AppendLine("--");
                        insertIntoStatement.AppendLine();

                        // Generate History Area Tables
                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM MODULE WHERE MODULE_CODE='m_150_H" + stagingTableName + "')");
                        }
                        insertIntoStatement.AppendLine(
                            "INSERT INTO [MODULE] ([AREA_CODE],[MODULE_CODE],[MODULE_DESCRIPTION],[MODULE_TYPE_CODE],[FREQUENCY_CODE])");
                        insertIntoStatement.AppendLine("VALUES ('HSTG','m_150_H" + stagingTableName +
                                                       "','Staging to History Staging ETL for H" + stagingTableName +
                                                       "', 'SSIS', 'Queue')");
                    }
                }
                else
                {
                    richTextBoxInformation.Text =
                        "There was no metadata available to generate STG and HSTG Modules and Batches. Please check the metadata schema or the database connection.";
                }
            }
            #endregion

            if (radioButtonETLGenerationMetadata.Checked)
            {
                # region Integration Layer content

                // Integration Layer Content
                if (checkBoxGenerateInt.Checked)
                {
                    var whereClauseStatement = GetWhereClauseStatement();

                    // Header for INT
                    insertIntoStatement.AppendLine();
                    insertIntoStatement.AppendLine("--");
                    insertIntoStatement.AppendLine("-- Integration Layer Modules ");
                    insertIntoStatement.AppendLine("-- Generated at " + DateTime.Now);
                    insertIntoStatement.AppendLine("--");
                    insertIntoStatement.AppendLine();

                    // Metadata selection
                    var queryIntMetadata = new StringBuilder();

                    queryIntMetadata.AppendLine("SELECT ");
                    queryIntMetadata.AppendLine("	INTEGRATION_AREA_TABLE, ");
                    queryIntMetadata.AppendLine("	SUBSTRING([STAGING_AREA_TABLE],5,LEN([STAGING_AREA_TABLE])) AS [STAGING_AREA_TABLE],");
                    queryIntMetadata.AppendLine("	SUBSTRING(INTEGRATION_AREA_TABLE,1,CHARINDEX('_',INTEGRATION_AREA_TABLE)-1) AS CATEGORY,");
                    queryIntMetadata.AppendLine("	SATELLITE_TYPE,");
                    queryIntMetadata.AppendLine("	ROW_NUMBER() OVER (ORDER BY INTEGRATION_AREA_TABLE, [STAGING_AREA_TABLE] ASC) AS ROW_NR, TOTAL_NR");
                    queryIntMetadata.AppendLine("FROM ");
                    queryIntMetadata.AppendLine("	(");
                    queryIntMetadata.AppendLine("		SELECT DISTINCT");
                    queryIntMetadata.AppendLine("			INTEGRATION_AREA_TABLE, STAGING_AREA_TABLE");
                    queryIntMetadata.AppendLine("		FROM [MD_TABLE_MAPPING] spec");
                    queryIntMetadata.AppendLine("		WHERE INTEGRATION_AREA_TABLE NOT LIKE '%_END_DATES%'");
                    queryIntMetadata.AppendLine("AND VERSION_ID=0");    
                    queryIntMetadata.AppendLine("	) distinctsub");
                    queryIntMetadata.AppendLine("JOIN ");
                    queryIntMetadata.AppendLine("	(");
                    queryIntMetadata.AppendLine("		SELECT COUNT(*) as TOTAL_NR");
                    queryIntMetadata.AppendLine("		FROM");
                    queryIntMetadata.AppendLine("			(");
                    queryIntMetadata.AppendLine("				SELECT DISTINCT INTEGRATION_AREA_TABLE, [STAGING_AREA_TABLE]");
                    queryIntMetadata.AppendLine("				FROM [MD_TABLE_MAPPING]");
                    queryIntMetadata.AppendLine("               WHERE VERSION_ID=0");    
                    queryIntMetadata.AppendLine("				AND INTEGRATION_AREA_TABLE NOT LIKE '%_END_DATES%'");
                    queryIntMetadata.AppendLine("			) totals");
                    queryIntMetadata.AppendLine("	) totalsub");
                    queryIntMetadata.AppendLine("ON 1=1");
                    queryIntMetadata.AppendLine("LEFT OUTER JOIN ");
                    queryIntMetadata.AppendLine("	(SELECT ");
                    queryIntMetadata.AppendLine("		SATELLITE_TABLE_NAME,");
                    queryIntMetadata.AppendLine("		SATELLITE_TYPE");
                    queryIntMetadata.AppendLine("	 FROM GEN_SAT WHERE SUBSTRING(SATELLITE_TABLE_NAME,1,4)='LSAT'");
                    queryIntMetadata.AppendLine("	) satsub");
                    queryIntMetadata.AppendLine("ON satsub.SATELLITE_TABLE_NAME=INTEGRATION_AREA_TABLE");
                    queryIntMetadata.AppendLine("WHERE " + whereClauseStatement);

                    //if (checkBoxVerboseDebugging.Checked)
                    //{
                    //    DebuggingTextbox.Text = queryIntMetadata.ToString();
                    //}

                    var connDirect = new SqlConnection { ConnectionString = textBoxGenerationMetadataConnection.Text };

                    try
                    {
                        connDirect.Open();
                    }
                    catch (Exception exception)
                    {
                        richTextBoxInformation.Text =
                            "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                            exception.Message;
                    }

                    var tables = GetDataTable(ref connDirect, queryIntMetadata.ToString());

                    if (tables.Rows.Count == 0)
                    {
                        richTextBoxInformation.Text =
                            "There was no metadata available to generate STG and HSTG Modules and Batches. Please check the metadata schema or the database connection.";
                    }

                    foreach (DataRow row in tables.Rows)
                    {
                        var targetTableName = (string)row["STAGING_AREA_TABLE"];
                        var Category = (string)row["CATEGORY"];

                        string intSatelliteType;

                        try
                        {
                            intSatelliteType = (string)row["SATELLITE_TYPE"];
                        }
                        catch
                        {
                            intSatelliteType = "";
                        }

                        var intTable = (string)row["INTEGRATION_AREA_TABLE"];

                        if (Category == "LSAT" && checkBoxGenerateInt.Checked)
                        {
                            if (intSatelliteType == "Link Satellite - Without Attributes")
                            {
                                if (checkBoxIfExists.Checked)
                                {
                                    insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM MODULE WHERE MODULE_CODE = 'm_200_" + intTable + "_With_Driving_Key')");
                                }
                                insertIntoStatement.AppendLine(
                                    "INSERT INTO [MODULE] ([AREA_CODE],[MODULE_CODE],[MODULE_DESCRIPTION],[MODULE_TYPE_CODE],[FREQUENCY_CODE])");
                                insertIntoStatement.AppendLine("VALUES ('INT','m_200_" + intTable +
                                                               "_With_Driving_Key','Driving-key based Link Satellite table sourced from " +
                                                               targetTableName + "', 'SSIS', 'Queue')");
                            }
                            else //Normal LSATs
                            {
                                if (checkBoxIfExists.Checked)
                                {
                                    insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM MODULE WHERE MODULE_CODE='m_200_" + intTable + "_" +
                                                                   targetTableName +
                                                                   "')");
                                }
                                insertIntoStatement.AppendLine(
                                    "INSERT INTO [MODULE] ([AREA_CODE],[MODULE_CODE],[MODULE_DESCRIPTION],[MODULE_TYPE_CODE],[FREQUENCY_CODE])");
                                insertIntoStatement.AppendLine("VALUES ('INT','m_200_" + intTable + "_" + targetTableName +
                                                               "','Driving-key based Link Satellite table sourced from " +
                                                               targetTableName + "', 'SSIS', 'Queue')");
                            }
                        }
                        else
                        {
                            if (checkBoxIfExists.Checked)
                            {
                                insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM MODULE WHERE MODULE_CODE='m_200_" + intTable + "_" +
                                                               targetTableName + "')");
                            }
                            insertIntoStatement.AppendLine("INSERT INTO [MODULE] ([AREA_CODE],[MODULE_CODE],[MODULE_DESCRIPTION],[MODULE_TYPE_CODE],[FREQUENCY_CODE])");
                            insertIntoStatement.AppendLine("VALUES ('INT','m_200_" + intTable + "_" + targetTableName +
                                                           "','Integration Layer ETL sourced from " + targetTableName + "', 'SSIS','Queue')");
                        }
                        insertIntoStatement.AppendLine();
                    }
                }
                # endregion

                #region End Dating
                if (checkBoxGenerateEndDating.Checked)
                {
                    var whereClauseStatement = GetWhereClauseStatement();

                    // Header for INT
                    insertIntoStatement.AppendLine("--");
                    insertIntoStatement.AppendLine("-- Integration Layer End-Dating Modules ");
                    insertIntoStatement.AppendLine("-- Generated at " + DateTime.Now);
                    insertIntoStatement.AppendLine("--");
                    insertIntoStatement.AppendLine();

                    // Metadata selection
                    var queryIntMetadata = new StringBuilder();

                    queryIntMetadata.AppendLine("SELECT DISTINCT STAGING_AREA_TABLE, INTEGRATION_AREA_TABLE");
                    queryIntMetadata.AppendLine("FROM [MD_TABLE_MAPPING] spec");
                    queryIntMetadata.AppendLine(                        "WHERE SUBSTRING(INTEGRATION_AREA_TABLE,1,CHARINDEX('_',INTEGRATION_AREA_TABLE)-1) IN ('SAT','LSAT')");
                    queryIntMetadata.AppendLine("AND INTEGRATION_AREA_TABLE NOT LIKE '%_END_DATES%'");
                    queryIntMetadata.AppendLine("AND VERSION_ID=0");
                    queryIntMetadata.AppendLine("AND " + whereClauseStatement);

                    //if (checkBoxVerboseDebugging.Checked)
                    //{
                    //    DebuggingTextbox.Text = queryIntMetadata.ToString();
                    //}

                    var connDirect = new SqlConnection { ConnectionString = textBoxGenerationMetadataConnection.Text };

                    try
                    {
                        connDirect.Open();
                    }
                    catch (Exception exception)
                    {
                        richTextBoxInformation.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                                 exception.Message;
                    }

                    var tables = GetDataTable(ref connDirect, queryIntMetadata.ToString());

                    if (tables.Rows.Count == 0)
                    {
                        richTextBoxInformation.Text =
                            "There was no metadata available to generate STG and HSTG Modules and Batches. Please check the metadata schema or the database connection.";
                    }

                    foreach (DataRow row in tables.Rows)
                    {
                        var intTableName = (string)row["INTEGRATION_AREA_TABLE"];

                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM MODULE WHERE MODULE_CODE='m_200_" + intTableName + "_END_DATES')");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [MODULE] ([AREA_CODE],[MODULE_CODE],[MODULE_DESCRIPTION],[MODULE_TYPE_CODE],[FREQUENCY_CODE])");
                        insertIntoStatement.AppendLine("VALUES ('INT','m_200_" + intTableName + "_END_DATES','End-dating logic for the table " + intTableName + "', 'SSIS', 'Queue')");
                        insertIntoStatement.AppendLine();
                    }
                }
                #endregion
            }
        }

        private void AddBatchContent(StringBuilder insertIntoStatement)
        {
            var whereClauseStatement = GetWhereClauseStatement();


            // Header for INT
            insertIntoStatement.AppendLine("--");
            insertIntoStatement.AppendLine("-- Batches ");
            insertIntoStatement.AppendLine("-- Generated at " + DateTime.Now);
            insertIntoStatement.AppendLine("--");
            insertIntoStatement.AppendLine();

            // Metadata selection
            var queryIntMetadata = new StringBuilder();

            if (radioButtonETLGenerationMetadata.Checked)
            {
                queryIntMetadata.AppendLine("SELECT DISTINCT SUBSTRING([STAGING_AREA_TABLE],5,LEN([STAGING_AREA_TABLE])) AS [STAGING_AREA_TABLE]");
                queryIntMetadata.AppendLine("FROM [MD_TABLE_MAPPING] spec");
                queryIntMetadata.AppendLine("WHERE [STAGING_AREA_TABLE]!='N/A'");
                queryIntMetadata.AppendLine("AND VERSION_ID=0");                
                queryIntMetadata.AppendLine("AND " + whereClauseStatement);
            }
            else
            {
                queryIntMetadata.AppendLine("  SELECT ");
                queryIntMetadata.AppendLine("     DISTINCT SUBSTRING([TABLE_NAME],5,LEN([TABLE_NAME])) AS [STAGING_AREA_TABLE] ");
                queryIntMetadata.AppendLine("  FROM EDW_100_Staging_Area.INFORMATION_SCHEMA.TABLES ");
                queryIntMetadata.AppendLine("  WHERE TABLE_TYPE='BASE TABLE'");
                queryIntMetadata.AppendLine("  AND " + whereClauseStatement);
            }


            //if (checkBoxVerboseDebugging.Checked)
            //{
            //    DebuggingTextbox.Text += queryIntMetadata.ToString();
            //}

            var connDirect = new SqlConnection { ConnectionString = textBoxGenerationMetadataConnection.Text };

            try
            {
                connDirect.Open();
            }
            catch (Exception exception)
            {
                richTextBoxInformation.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                            exception.Message;
            }

            var tables = GetDataTable(ref connDirect, queryIntMetadata.ToString());

            if (tables.Rows.Count == 0)
            {
                richTextBoxInformation.Text =
                    "There was no metadata available to generate STG and HSTG Modules and Batches. Please check the metadata schema or the database connection.";
            }

            foreach (DataRow row in tables.Rows)
            {
                var stagingTableName = (string)row["STAGING_AREA_TABLE"];
                var stagingBatchName = stagingTableName.Replace("_VW", "");

                if (checkBoxIfExists.Checked)
                {
                        insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT BATCH_CODE FROM BATCH WHERE BATCH_CODE='b_EDW_STG_INT_" + stagingBatchName + "')");
                }

                insertIntoStatement.AppendLine("INSERT INTO [BATCH] ([FREQUENCY_CODE],[BATCH_CODE],[BATCH_DESCRIPTION])");
                insertIntoStatement.AppendLine("VALUES ('Queue','b_EDW_STG_INT_" + stagingBatchName + "','Source to Integration Area processing for " + stagingBatchName + "')");
                insertIntoStatement.AppendLine();
            }
        }

        private void AddDataStoreContent(StringBuilder insertIntoStatement)
        {
            var whereClauseStatement = GetWhereClauseStatement();

            // Header for Data Stores
            insertIntoStatement.AppendLine("--");
            insertIntoStatement.AppendLine("-- Data Stores ");
            insertIntoStatement.AppendLine("-- Generated at " + DateTime.Now);
            insertIntoStatement.AppendLine("--");
            insertIntoStatement.AppendLine();

            // Metadata selection
            var queryDataStoreMetadata = new StringBuilder();

            if (checkBoxGenerateStg.Checked==false && checkBoxGenerateHstg.Checked==false && checkBoxGenerateInt.Checked==false && checkBoxGenerateEndDating.Checked==false)
            {
                richTextBoxInformation.Text = "No valid selection was made to generate outputs!";
            }
            else 
            {
                if (radioButtonETLGenerationMetadata.Checked)
                {
                    queryDataStoreMetadata.AppendLine("WITH MyCTE AS ");
                    queryDataStoreMetadata.AppendLine("(");
                    queryDataStoreMetadata.AppendLine("SELECT ");
                    queryDataStoreMetadata.AppendLine("	'STG_'+SUBSTRING([STAGING_AREA_TABLE],5,LEN([STAGING_AREA_TABLE])) AS [STAGING_AREA_TABLE],");
                    queryDataStoreMetadata.AppendLine("	INTEGRATION_AREA_TABLE AS DATA_STORE");
                    queryDataStoreMetadata.AppendLine("FROM [MD_TABLE_MAPPING] spec");
                    queryDataStoreMetadata.AppendLine("WHERE INTEGRATION_AREA_TABLE NOT LIKE '%_END_DATES%'");
                    queryDataStoreMetadata.AppendLine("AND VERSION_ID=0");    
                    queryDataStoreMetadata.AppendLine("), SUPERSET AS ");
                    queryDataStoreMetadata.AppendLine("( ");
                    queryDataStoreMetadata.AppendLine("SELECT ");
                    queryDataStoreMetadata.AppendLine("	STAGING_AREA_TABLE, ");
                    queryDataStoreMetadata.AppendLine("	DATA_STORE ");
                    queryDataStoreMetadata.AppendLine("FROM ");
                    queryDataStoreMetadata.AppendLine("( ");
                    queryDataStoreMetadata.AppendLine("SELECT ");
                    queryDataStoreMetadata.AppendLine("	STAGING_AREA_TABLE,");
                    queryDataStoreMetadata.AppendLine("	DATA_STORE");
                    queryDataStoreMetadata.AppendLine("FROM MyCTE");
                    queryDataStoreMetadata.AppendLine("UNION -- Deduplicates");
                    queryDataStoreMetadata.AppendLine("SELECT ");
                    queryDataStoreMetadata.AppendLine("	STAGING_AREA_TABLE,");
                    queryDataStoreMetadata.AppendLine("	STAGING_AREA_TABLE AS DATA_STORE");
                    queryDataStoreMetadata.AppendLine("FROM MyCTE");
                    queryDataStoreMetadata.AppendLine("UNION -- Deduplicates");
                    queryDataStoreMetadata.AppendLine("SELECT ");
                    queryDataStoreMetadata.AppendLine("	STAGING_AREA_TABLE,");
                    queryDataStoreMetadata.AppendLine("	'H'+STAGING_AREA_TABLE AS DATA_STORE");
                    queryDataStoreMetadata.AppendLine("FROM MyCTE");
                    queryDataStoreMetadata.AppendLine(") sub");
                    queryDataStoreMetadata.AppendLine("WHERE " + whereClauseStatement);
                    queryDataStoreMetadata.AppendLine(")");
                    queryDataStoreMetadata.AppendLine("SELECT ");
                    queryDataStoreMetadata.AppendLine(" DISTINCT DATA_STORE ");
                    queryDataStoreMetadata.AppendLine("FROM SUPERSET ");
                    queryDataStoreMetadata.AppendLine("WHERE ");
                    queryDataStoreMetadata.AppendLine("(");

                    if (checkBoxGenerateStg.Checked)
                    {
                        queryDataStoreMetadata.AppendLine("SUBSTRING(DATA_STORE,1,4)='STG_' OR");
                    }

                    if (checkBoxGenerateHstg.Checked)
                    {
                        queryDataStoreMetadata.AppendLine("SUBSTRING(DATA_STORE,1,5)='HSTG_' OR");
                    }

                    if (checkBoxGenerateEndDating.Checked)
                    {
                        queryDataStoreMetadata.AppendLine("(SUBSTRING(DATA_STORE,1,4) IN ('SAT_') OR (SUBSTRING(DATA_STORE,1,5)='LSAT_')) OR");
                    }

                    if (checkBoxGenerateInt.Checked)
                    {
                        queryDataStoreMetadata.AppendLine("(SUBSTRING(DATA_STORE,1,4) IN ('HUB_', 'LNK_', 'SAT_') OR (SUBSTRING(DATA_STORE,1,5)='LSAT_'))");
                    }

                   // var test = queryDataStoreMetadata.ToString().TrimEnd().Substring(queryDataStoreMetadata.Length - 4);
                    if (queryDataStoreMetadata.ToString().TrimEnd().Substring(queryDataStoreMetadata.Length - 4) == "OR")
                    {
                        //queryDataStoreMetadata.ToString().TrimEnd().Substring(0, queryDataStoreMetadata.Length - 4);
                        queryDataStoreMetadata.Remove(queryDataStoreMetadata.Length - 4, 4);
                    }

                    
                    queryDataStoreMetadata.AppendLine(")");
                    queryDataStoreMetadata.AppendLine("ORDER BY 1");
                }
                else if (radioButtonETLGenerationMetadata.Checked==false && (checkBoxGenerateStg.Checked==true || checkBoxGenerateHstg.Checked==true))
                {
                    //Staging Area selection
                    queryDataStoreMetadata.AppendLine("WITH MyCTE AS ");
                    queryDataStoreMetadata.AppendLine("(");
                    queryDataStoreMetadata.AppendLine("  SELECT ");
                    queryDataStoreMetadata.AppendLine("    TABLE_NAME AS STAGING_AREA_TABLE  ");
                    queryDataStoreMetadata.AppendLine("  FROM EDW_100_Staging_Area.INFORMATION_SCHEMA.TABLES ");
                    queryDataStoreMetadata.AppendLine("  WHERE TABLE_TYPE='BASE TABLE'");
                    queryDataStoreMetadata.AppendLine("  AND " + whereClauseStatement);
                    queryDataStoreMetadata.AppendLine(")");
                    // STG
                    if (checkBoxGenerateStg.Checked)
                    {
                        queryDataStoreMetadata.AppendLine("SELECT ");
                        queryDataStoreMetadata.AppendLine("  STAGING_AREA_TABLE AS DATA_STORE ");
                        queryDataStoreMetadata.AppendLine("FROM MyCTE");
                    }
                    // HSTG
                    if (checkBoxGenerateHstg.Checked)
                    {
                        if (checkBoxGenerateStg.Checked)
                        {
                            queryDataStoreMetadata.AppendLine("UNION -- Deduplicates");
                        }
                        queryDataStoreMetadata.AppendLine("SELECT ");
                        queryDataStoreMetadata.AppendLine("	'H'+STAGING_AREA_TABLE AS DATA_STORE");
                        queryDataStoreMetadata.AppendLine("FROM MyCTE");
                    }
                }
                else
                {
                    richTextBoxInformation.Text = "No valid selection was made to generate outputs!";
                }

                //if (checkBoxVerboseDebugging.Checked)
                //{
                //    DebuggingTextbox.Text += queryDataStoreMetadata.ToString();
                //}
            }


            var connDirect = new SqlConnection { ConnectionString = textBoxGenerationMetadataConnection.Text };

            try
            {
                connDirect.Open();
            }
            catch (Exception exception)
            {
                richTextBoxInformation.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                            exception.Message;
            }

            if (queryDataStoreMetadata.Length > 0)
            {
                var tables = GetDataTable(ref connDirect, queryDataStoreMetadata.ToString());

                if (tables.Rows.Count == 0)
                {
                    richTextBoxInformation.Text = "There was no metadata available to generate Data Stores. Please check the metadata schema or the database connection.";
                }

                foreach (DataRow row in tables.Rows)
                {
                    var dataStoreName = (string)row["DATA_STORE"];
                    dataStoreName = dataStoreName.Replace("_VW", "");

                    if (checkBoxIfExists.Checked)
                    {
                        insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [DATA_STORE_CODE] FROM [DATA_STORE] WHERE [DATA_STORE_CODE]='" + dataStoreName + "')");
                    }

                    insertIntoStatement.AppendLine("INSERT INTO [DATA_STORE] ([DATA_STORE_CODE],[DATA_STORE_TYPE_CODE],[DATA_STORE_DESCRIPTION],[ALLOW_TRUNCATE_INDICATOR])");
                    insertIntoStatement.AppendLine("VALUES ('" + dataStoreName + "','Table','', 'Y')");
                    insertIntoStatement.AppendLine();

                }
            }
        }

        private void AddModuleDataStoreContent(StringBuilder insertIntoStatement)
        {
            var whereClauseStatement = GetWhereClauseStatement();

            // Header for Data Stores
            insertIntoStatement.AppendLine("--");
            insertIntoStatement.AppendLine("-- Module / Data Store relationships ");
            insertIntoStatement.AppendLine("-- Generated at " + DateTime.Now);
            insertIntoStatement.AppendLine("--");
            insertIntoStatement.AppendLine();

            // Metadata selection
            var queryDataStoreMetadata = new StringBuilder();

            if (radioButtonETLGenerationMetadata.Checked)
            {
                queryDataStoreMetadata.AppendLine("WITH MyCTE AS ");
                queryDataStoreMetadata.AppendLine("( ");
                queryDataStoreMetadata.AppendLine("SELECT ");
                queryDataStoreMetadata.AppendLine("	'STG_'+SUBSTRING([STAGING_AREA_TABLE],5,LEN([STAGING_AREA_TABLE])) AS [STAGING_AREA_TABLE],");
                queryDataStoreMetadata.AppendLine("	INTEGRATION_AREA_TABLE AS DATA_STORE");
                queryDataStoreMetadata.AppendLine("FROM [MD_TABLE_MAPPING] spec");
                queryDataStoreMetadata.AppendLine("WHERE INTEGRATION_AREA_TABLE NOT LIKE '%_END_DATES%'");
                queryDataStoreMetadata.AppendLine("AND VERSION_ID=0");    
                queryDataStoreMetadata.AppendLine("), LinkSatellites AS ");
                queryDataStoreMetadata.AppendLine("(");
                queryDataStoreMetadata.AppendLine("SELECT ");
                queryDataStoreMetadata.AppendLine("	SATELLITE_TABLE_NAME,");
                queryDataStoreMetadata.AppendLine("	SATELLITE_TYPE");
                queryDataStoreMetadata.AppendLine("FROM GEN_SAT WHERE SUBSTRING(SATELLITE_TABLE_NAME,1,4)='LSAT' OR SUBSTRING(SATELLITE_TABLE_NAME,1,3)='SAT'");
                queryDataStoreMetadata.AppendLine(")");
                queryDataStoreMetadata.AppendLine("SELECT ");
                queryDataStoreMetadata.AppendLine("	STAGING_AREA_TABLE, ");
                queryDataStoreMetadata.AppendLine("	DATA_STORE,");
                queryDataStoreMetadata.AppendLine("	CATEGORY,");
                queryDataStoreMetadata.AppendLine("	CASE");
                queryDataStoreMetadata.AppendLine("		WHEN CATEGORY = 'STG' THEN 'm_100_'+STAGING_AREA_TABLE");
                queryDataStoreMetadata.AppendLine("		WHEN CATEGORY = 'HSTG' THEN 'm_150_H'+STAGING_AREA_TABLE");
                queryDataStoreMetadata.AppendLine("		WHEN CATEGORY = 'INT' AND (SATELLITE_TYPE IS NULL OR SATELLITE_TYPE='Normal') THEN 'm_200_'+DATA_STORE+'_'+SUBSTRING([STAGING_AREA_TABLE],5,LEN([STAGING_AREA_TABLE]))");
                queryDataStoreMetadata.AppendLine("		WHEN CATEGORY = 'INT' AND SATELLITE_TYPE = 'Link Satellite' THEN 'm_200_'+DATA_STORE+'_'+SUBSTRING([STAGING_AREA_TABLE],5,LEN([STAGING_AREA_TABLE]))");
                queryDataStoreMetadata.AppendLine("		WHEN CATEGORY = 'INT' AND SATELLITE_TYPE = 'Link Satellite - Without Attributes' THEN 'm_200_'+DATA_STORE+'_With_Driving_Key'");
                queryDataStoreMetadata.AppendLine("		ELSE 'Unknown'");
                queryDataStoreMetadata.AppendLine("	END AS MODULE_CODE,");
                queryDataStoreMetadata.AppendLine("	SATELLITE_TYPE");
                queryDataStoreMetadata.AppendLine("FROM ");
                queryDataStoreMetadata.AppendLine("( ");
                queryDataStoreMetadata.AppendLine("SELECT ");
                queryDataStoreMetadata.AppendLine("	STAGING_AREA_TABLE,");
                queryDataStoreMetadata.AppendLine("	DATA_STORE,");
                queryDataStoreMetadata.AppendLine("	'INT' AS CATEGORY");
                queryDataStoreMetadata.AppendLine("FROM MyCTE");
                queryDataStoreMetadata.AppendLine("UNION -- Deduplicates");
                queryDataStoreMetadata.AppendLine("SELECT ");
                queryDataStoreMetadata.AppendLine("	STAGING_AREA_TABLE,");
                queryDataStoreMetadata.AppendLine("	STAGING_AREA_TABLE AS DATA_STORE,");
                queryDataStoreMetadata.AppendLine("	'STG' AS CATEGORY");
                queryDataStoreMetadata.AppendLine("FROM MyCTE");
                queryDataStoreMetadata.AppendLine("UNION -- Deduplicates");
                queryDataStoreMetadata.AppendLine("SELECT ");
                queryDataStoreMetadata.AppendLine("	STAGING_AREA_TABLE,");
                queryDataStoreMetadata.AppendLine("	'H'+STAGING_AREA_TABLE AS DATA_STORE,");
                queryDataStoreMetadata.AppendLine("	'HSTG' AS CATEGORY");
                queryDataStoreMetadata.AppendLine("FROM MyCTE");
                queryDataStoreMetadata.AppendLine(") sub");
                queryDataStoreMetadata.AppendLine("LEFT OUTER JOIN LinkSatellites");
                queryDataStoreMetadata.AppendLine("	ON LinkSatellites.SATELLITE_TABLE_NAME=sub.DATA_STORE");
                queryDataStoreMetadata.AppendLine("WHERE " + whereClauseStatement);
                queryDataStoreMetadata.AppendLine("ORDER BY 1");
            }
            else
            {
                whereClauseStatement.Replace("STAGING_AREA_TABLE", "TABLE_NAME");

                queryDataStoreMetadata.AppendLine("SELECT DISTINCT ");
                queryDataStoreMetadata.AppendLine("TABLE_NAME AS STAGING_AREA_TABLE,");
                queryDataStoreMetadata.AppendLine("TABLE_NAME AS DATA_STORE,");
                queryDataStoreMetadata.AppendLine("'STG' AS CATEGORY,");
                queryDataStoreMetadata.AppendLine("'m_100_'+TABLE_NAME AS MODULE_CODE,");
                queryDataStoreMetadata.AppendLine("NULL AS SATELLITE_TYPE,");
                queryDataStoreMetadata.AppendLine("'b_EDW_STG_INT_'+SUBSTRING(TABLE_NAME,5,LEN(TABLE_NAME)) as BATCH_CODE ");
                queryDataStoreMetadata.AppendLine("FROM EDW_100_Staging_Area.INFORMATION_SCHEMA.TABLES ");
                queryDataStoreMetadata.AppendLine("WHERE " + whereClauseStatement);
                queryDataStoreMetadata.AppendLine(" AND TABLE_TYPE='BASE TABLE' AND TABLE_NAME NOT LIKE '%__LANDING'");
                queryDataStoreMetadata.AppendLine("UNION ");
                queryDataStoreMetadata.AppendLine("SELECT DISTINCT ");
                queryDataStoreMetadata.AppendLine("TABLE_NAME AS STAGING_AREA_TABLE,");
                queryDataStoreMetadata.AppendLine("'H'+TABLE_NAME AS DATA_STORE,");
                queryDataStoreMetadata.AppendLine("'HSTG' AS CATEGORY,");
                queryDataStoreMetadata.AppendLine("'m_150_H'+TABLE_NAME AS MODULE_CODE,");
                queryDataStoreMetadata.AppendLine("NULL AS SATELLITE_TYPE,");
                queryDataStoreMetadata.AppendLine("'b_EDW_STG_INT_'+SUBSTRING(TABLE_NAME,5,LEN(TABLE_NAME)) as BATCH_CODE ");
                queryDataStoreMetadata.AppendLine("FROM EDW_100_Staging_Area.INFORMATION_SCHEMA.TABLES ");
                queryDataStoreMetadata.AppendLine("WHERE " + whereClauseStatement);
                queryDataStoreMetadata.AppendLine(" AND TABLE_TYPE='BASE TABLE' AND TABLE_NAME NOT LIKE '%__LANDING'");
            }


            //if (checkBoxVerboseDebugging.Checked)
            //{
            //    DebuggingTextbox.Text += queryDataStoreMetadata.ToString();
            //}

            var connDirect = new SqlConnection { ConnectionString = textBoxGenerationMetadataConnection.Text };

            try
            {
                connDirect.Open();
            }
            catch (Exception exception)
            {
                richTextBoxInformation.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                            exception.Message;
            }

            var tables = GetDataTable(ref connDirect, queryDataStoreMetadata.ToString());

            if (tables.Rows.Count == 0)
            {
                richTextBoxInformation.Text = "There was no metadata available to generate Module / Data Stores relationships. Please check the metadata schema or the database connection.";
            }

            // STG
            if (checkBoxGenerateStg.Checked)
            {
                foreach (DataRow row in tables.Rows)
                {
                    var dataStoreName = (string)row["DATA_STORE"];
                    dataStoreName = dataStoreName.Replace("_VW", "");

                    var moduleName = (string)row["MODULE_CODE"];
                    moduleName = moduleName.Replace("_VW", "");

                    var category = (string)row["CATEGORY"];

                    if (category == "STG")
                    {
                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [DATA_STORE_ID] FROM [MODULE_DATA_STORE] WHERE MODULE_ID=(SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='" + moduleName + "') AND DATA_STORE_ID=(SELECT DATA_STORE_ID FROM DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [MODULE_DATA_STORE]  ([MODULE_ID], [DATA_STORE_ID], [RELATIONSHIP_TYPE])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT DATA_STORE_ID FROM DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'),'Target'");
                        insertIntoStatement.AppendLine(")");
                        insertIntoStatement.AppendLine();
                    }
                }
            }

            // HSTG
            if (checkBoxGenerateHstg.Checked)
            {
                foreach (DataRow row in tables.Rows)
                {
                    var dataStoreName = (string)row["DATA_STORE"];
                    dataStoreName = dataStoreName.Replace("_VW", "");

                    var moduleName = (string)row["MODULE_CODE"];
                    moduleName = moduleName.Replace("_VW", "");

                    var category = (string)row["CATEGORY"];

                    if (category == "HSTG")
                    {
                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [DATA_STORE_ID] FROM [MODULE_DATA_STORE] WHERE MODULE_ID=(SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='" + moduleName + "') AND DATA_STORE_ID=(SELECT DATA_STORE_ID FROM DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [MODULE_DATA_STORE]  ([MODULE_ID], [DATA_STORE_ID], [RELATIONSHIP_TYPE])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT DATA_STORE_ID FROM DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'),'Target'");
                        insertIntoStatement.AppendLine(")");
                        insertIntoStatement.AppendLine();
                    }
                }
            }

            // INT
            if (checkBoxGenerateInt.Checked)
            {
                foreach (DataRow row in tables.Rows)
                {
                    var dataStoreName = (string)row["DATA_STORE"];
                    var moduleName = (string)row["MODULE_CODE"];
                    var category = (string)row["CATEGORY"];

                    if (category == "INT")
                    {
                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [DATA_STORE_ID] FROM [MODULE_DATA_STORE] WHERE MODULE_ID=(SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='" + moduleName + "') AND DATA_STORE_ID=(SELECT DATA_STORE_ID FROM OMD_DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [MODULE_DATA_STORE]  ([MODULE_ID], [DATA_STORE_ID], [RELATIONSHIP_TYPE])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT DATA_STORE_ID FROM DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'),'Target'");
                        insertIntoStatement.AppendLine(")");
                        insertIntoStatement.AppendLine();
                    }
                }
            }

            // Add end dating only for Sats and Lsats
            if (checkBoxGenerateEndDating.Checked)
            {
                foreach (DataRow row in tables.Rows)
                {
                    var satelliteType = "";

                    if (row["SATELLITE_TYPE"] != DBNull.Value)
                    {
                        satelliteType = (string)row["SATELLITE_TYPE"];
                    }

                    var dataStoreName = (string)row["DATA_STORE"];

                    if ("".Equals(satelliteType))
                    {
                    }
                    else
                    {
                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine(
                                "IF NOT EXISTS (SELECT [MODULE_ID], [DATA_STORE_ID] FROM [MODULE_DATA_STORE] WHERE MODULE_ID=" +
                                "(SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='m_200_" + dataStoreName + "_END_DATES" +
                                "') AND DATA_STORE_ID=(SELECT DATA_STORE_ID FROM DATA_STORE WHERE DATA_STORE_CODE='" +
                                dataStoreName + "'))");
                        }

                        insertIntoStatement.AppendLine(
                            "INSERT INTO [MODULE_DATA_STORE]  ([MODULE_ID], [DATA_STORE_ID], [RELATIONSHIP_TYPE])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine(
                            "(SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='m_200_" + dataStoreName + "_END_DATES" +
                            "'),(SELECT DATA_STORE_ID FROM DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName +
                            "'),'Target'");
                        insertIntoStatement.AppendLine(")");
                        insertIntoStatement.AppendLine();
                    }
                }
            }
        }

        private void AddBatchModuleContent(StringBuilder insertIntoStatement)
        {
            var whereClauseStatement = GetWhereClauseStatement();

            // Header for Batch / Module relationships
            insertIntoStatement.AppendLine("--");
            insertIntoStatement.AppendLine("-- Batch / Module relationships ");
            insertIntoStatement.AppendLine("-- Generated at " + DateTime.Now);
            insertIntoStatement.AppendLine("--");
            insertIntoStatement.AppendLine();

            // Metadata selection
            var queryModuleBatchMetadata = new StringBuilder();

            if (radioButtonETLGenerationMetadata.Checked)
            {
                queryModuleBatchMetadata.AppendLine("WITH MyCTE AS ");
                queryModuleBatchMetadata.AppendLine("( ");
                queryModuleBatchMetadata.AppendLine("SELECT ");
                queryModuleBatchMetadata.AppendLine("	'STG_'+SUBSTRING([STAGING_AREA_TABLE],5,LEN([STAGING_AREA_TABLE])) AS [STAGING_AREA_TABLE],");
                queryModuleBatchMetadata.AppendLine("	INTEGRATION_AREA_TABLE AS DATA_STORE");
                queryModuleBatchMetadata.AppendLine("FROM [MD_TABLE_MAPPING] spec");
                queryModuleBatchMetadata.AppendLine("WHERE INTEGRATION_AREA_TABLE NOT LIKE '%_END_DATES%'");
                queryModuleBatchMetadata.AppendLine("AND VERSION_ID=0");    
                queryModuleBatchMetadata.AppendLine("), LinkSatellites AS ");
                queryModuleBatchMetadata.AppendLine("(");
                queryModuleBatchMetadata.AppendLine("SELECT ");
                queryModuleBatchMetadata.AppendLine("	SATELLITE_TABLE_NAME,");
                queryModuleBatchMetadata.AppendLine("	SATELLITE_TYPE");
                queryModuleBatchMetadata.AppendLine("FROM GEN_SAT WHERE SUBSTRING(SATELLITE_TABLE_NAME,1,4)='LSAT' OR SUBSTRING(SATELLITE_TABLE_NAME,1,3)='SAT'");
                queryModuleBatchMetadata.AppendLine(")");
                queryModuleBatchMetadata.AppendLine("SELECT ");
                queryModuleBatchMetadata.AppendLine("	STAGING_AREA_TABLE, ");
                queryModuleBatchMetadata.AppendLine("	DATA_STORE,");
                queryModuleBatchMetadata.AppendLine("	CATEGORY,");
                queryModuleBatchMetadata.AppendLine("	CASE");
                queryModuleBatchMetadata.AppendLine("		WHEN CATEGORY = 'STG' THEN 'm_100_'+STAGING_AREA_TABLE");
                queryModuleBatchMetadata.AppendLine("		WHEN CATEGORY = 'HSTG' THEN 'm_150_H'+STAGING_AREA_TABLE");
                queryModuleBatchMetadata.AppendLine("		WHEN CATEGORY = 'INT' AND (SATELLITE_TYPE IS NULL OR SATELLITE_TYPE='Normal') THEN 'm_200_'+DATA_STORE+'_'+SUBSTRING([STAGING_AREA_TABLE],5,LEN([STAGING_AREA_TABLE]))");
                queryModuleBatchMetadata.AppendLine("		WHEN CATEGORY = 'INT' AND SATELLITE_TYPE = 'Link Satellite' THEN 'm_200_'+DATA_STORE+'_'+SUBSTRING([STAGING_AREA_TABLE],5,LEN([STAGING_AREA_TABLE]))");
                queryModuleBatchMetadata.AppendLine("		WHEN CATEGORY = 'INT' AND SATELLITE_TYPE = 'Link Satellite - Without Attributes' THEN 'm_200_'+DATA_STORE+'_With_Driving_Key'");
                queryModuleBatchMetadata.AppendLine("		ELSE 'Unknown'");
                queryModuleBatchMetadata.AppendLine("	END AS MODULE_CODE,");
                queryModuleBatchMetadata.AppendLine("	SATELLITE_TYPE,");
                queryModuleBatchMetadata.AppendLine("	'b_EDW_STG_INT_'+SUBSTRING(STAGING_AREA_TABLE,5,LEN(STAGING_AREA_TABLE)) as BATCH_CODE ");
                queryModuleBatchMetadata.AppendLine("FROM ");
                queryModuleBatchMetadata.AppendLine("( ");
                queryModuleBatchMetadata.AppendLine("SELECT ");
                queryModuleBatchMetadata.AppendLine("	STAGING_AREA_TABLE,");
                queryModuleBatchMetadata.AppendLine("	DATA_STORE,");
                queryModuleBatchMetadata.AppendLine("	'INT' AS CATEGORY");
                queryModuleBatchMetadata.AppendLine("FROM MyCTE");
                queryModuleBatchMetadata.AppendLine("UNION -- Deduplicates");
                queryModuleBatchMetadata.AppendLine("SELECT ");
                queryModuleBatchMetadata.AppendLine("	STAGING_AREA_TABLE,");
                queryModuleBatchMetadata.AppendLine("	STAGING_AREA_TABLE AS DATA_STORE,");
                queryModuleBatchMetadata.AppendLine("	'STG' AS CATEGORY");
                queryModuleBatchMetadata.AppendLine("FROM MyCTE");
                queryModuleBatchMetadata.AppendLine("UNION -- Deduplicates");
                queryModuleBatchMetadata.AppendLine("SELECT ");
                queryModuleBatchMetadata.AppendLine("	STAGING_AREA_TABLE,");
                queryModuleBatchMetadata.AppendLine("	'H'+STAGING_AREA_TABLE AS DATA_STORE,");
                queryModuleBatchMetadata.AppendLine("	'HSTG' AS CATEGORY");
                queryModuleBatchMetadata.AppendLine("FROM MyCTE");
                queryModuleBatchMetadata.AppendLine(") sub");
                queryModuleBatchMetadata.AppendLine("LEFT OUTER JOIN LinkSatellites");
                queryModuleBatchMetadata.AppendLine("	ON LinkSatellites.SATELLITE_TABLE_NAME=sub.DATA_STORE");
                queryModuleBatchMetadata.AppendLine("WHERE " + whereClauseStatement);
                queryModuleBatchMetadata.AppendLine("ORDER BY 1");
            }
            else
            {
                whereClauseStatement.Replace("STAGING_AREA_TABLE", "TABLE_NAME");

                queryModuleBatchMetadata.AppendLine("SELECT DISTINCT ");
                queryModuleBatchMetadata.AppendLine("TABLE_NAME AS STAGING_AREA_TABLE,");
                queryModuleBatchMetadata.AppendLine("TABLE_NAME AS DATA_STORE,");
                queryModuleBatchMetadata.AppendLine("'STG' AS CATEGORY,");
                queryModuleBatchMetadata.AppendLine("'m_100_'+TABLE_NAME AS MODULE_CODE,");
                queryModuleBatchMetadata.AppendLine("NULL AS SATELLITE_TYPE,");
                queryModuleBatchMetadata.AppendLine("'b_EDW_STG_INT_'+SUBSTRING(TABLE_NAME,5,LEN(TABLE_NAME)) as BATCH_CODE ");
                queryModuleBatchMetadata.AppendLine("FROM EDW_100_Staging_Area.INFORMATION_SCHEMA.TABLES ");
                queryModuleBatchMetadata.AppendLine("WHERE " + whereClauseStatement);
                queryModuleBatchMetadata.AppendLine(" AND TABLE_TYPE='BASE TABLE' AND TABLE_NAME NOT LIKE '%__LANDING'");
                queryModuleBatchMetadata.AppendLine("UNION ");
                queryModuleBatchMetadata.AppendLine("SELECT DISTINCT ");
                queryModuleBatchMetadata.AppendLine("TABLE_NAME AS STAGING_AREA_TABLE,");
                queryModuleBatchMetadata.AppendLine("'H'+TABLE_NAME AS DATA_STORE,");
                queryModuleBatchMetadata.AppendLine("'HSTG' AS CATEGORY,");
                queryModuleBatchMetadata.AppendLine("'m_150_H'+TABLE_NAME AS MODULE_CODE,");
                queryModuleBatchMetadata.AppendLine("NULL AS SATELLITE_TYPE,");
                queryModuleBatchMetadata.AppendLine("'b_EDW_STG_INT_'+SUBSTRING(TABLE_NAME,5,LEN(TABLE_NAME)) as BATCH_CODE ");
                queryModuleBatchMetadata.AppendLine("FROM EDW_100_Staging_Area.INFORMATION_SCHEMA.TABLES ");
                queryModuleBatchMetadata.AppendLine("WHERE " + whereClauseStatement);
                queryModuleBatchMetadata.AppendLine(" AND TABLE_TYPE='BASE TABLE' AND TABLE_NAME NOT LIKE '%__LANDING'");
            }

            //if (checkBoxVerboseDebugging.Checked)
            //{
            //    DebuggingTextbox.Text += queryModuleBatchMetadata.ToString();
            //}

            var connDirect = new SqlConnection { ConnectionString = textBoxGenerationMetadataConnection.Text };

            try
            {
                connDirect.Open();
            }
            catch (Exception exception)
            {
                richTextBoxInformation.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                            exception.Message;
            }

            var tables = GetDataTable(ref connDirect, queryModuleBatchMetadata.ToString());

            if (tables.Rows.Count == 0)
            {
                richTextBoxInformation.Text = "There was no metadata available to generate Module / Data Stores relationships. Please check the metadata schema or the database connection.";
            }

            // STG generation
            if (checkBoxGenerateStg.Checked)
            {
                foreach (DataRow row in tables.Rows)
                {
                    var moduleName = (string)row["MODULE_CODE"];
                    moduleName = moduleName.Replace("_VW", "");

                    var batchName = (string)row["BATCH_CODE"];
                    var category = (string)row["CATEGORY"];
                    batchName = batchName.Replace("_VW", "");

                    if (category == "STG")
                    {
                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [BATCH_ID] FROM [BATCH_MODULE] WHERE MODULE_ID=(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "') AND BATCH_ID=(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [BATCH_MODULE]  ([MODULE_ID], [BATCH_ID], [INACTIVE_INDICATOR])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT BATCH_ID FROM BATCH WHERE BATCH_CODE='" + batchName + "'),'N'");
                        insertIntoStatement.AppendLine(")");
                        insertIntoStatement.AppendLine();
                    }
                }
            }

            // HSTG generation
            if (checkBoxGenerateHstg.Checked)
            {
                foreach (DataRow row in tables.Rows)
                {
                    var moduleName = (string)row["MODULE_CODE"];
                    moduleName = moduleName.Replace("_VW", "");

                    var batchName = (string)row["BATCH_CODE"];
                    var category = (string)row["CATEGORY"];
                    batchName = batchName.Replace("_VW", "");

                    if (category == "HSTG")
                    {
                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [BATCH_ID] FROM [BATCH_MODULE] WHERE MODULE_ID=(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "') AND BATCH_ID=(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [BATCH_MODULE]  ([MODULE_ID], [BATCH_ID], [INACTIVE_INDICATOR])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT BATCH_ID FROM BATCH WHERE BATCH_CODE='" + batchName + "'),'N'");
                        insertIntoStatement.AppendLine(")");
                        insertIntoStatement.AppendLine();
                    }
                }
            }

            // INT generation
            if (checkBoxGenerateInt.Checked)
            {
                foreach (DataRow row in tables.Rows)
                {
                    var moduleName = (string)row["MODULE_CODE"];
                    var batchName = (string)row["BATCH_CODE"];
                    var category = (string)row["CATEGORY"];
                    batchName = batchName.Replace("_VW", "");

                    if (category == "INT")
                    {
                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [BATCH_ID] FROM [BATCH_MODULE] WHERE MODULE_ID=(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "') AND BATCH_ID=(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [BATCH_MODULE]  ([MODULE_ID], [BATCH_ID], [INACTIVE_INDICATOR])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT BATCH_ID FROM BATCH WHERE BATCH_CODE='" + batchName + "'),'N'");
                        insertIntoStatement.AppendLine(")");
                        insertIntoStatement.AppendLine();
                    }
                }
            }

            // Add end dating only for Sats and Lsats
            foreach (DataRow row in tables.Rows)
            {
                if (checkBoxGenerateEndDating.Checked)
                {
                    var satelliteType = "";

                    if (row["SATELLITE_TYPE"] != DBNull.Value)
                    {
                        satelliteType = (string)row["SATELLITE_TYPE"];
                    }

                    var dataStoreName = (string)row["DATA_STORE"];
                    var batchName = (string)row["BATCH_CODE"];
                    batchName = batchName.Replace("_VW", "");
                    var moduleName = (string)row["MODULE_CODE"];

                    if ("".Equals(satelliteType))
                    {
                    }
                    else
                    {
                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [BATCH_ID] FROM [BATCH_MODULE] WHERE MODULE_ID=(SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='m_200_" + dataStoreName + "_END_DATES" + "') AND BATCH_ID=(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [BATCH_MODULE]  ([MODULE_ID], [BATCH_ID], [INACTIVE_INDICATOR])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("(SELECT MODULE_ID FROM MODULE WHERE MODULE_CODE='m_200_" + dataStoreName + "_END_DATES" +"'),(SELECT BATCH_ID FROM BATCH WHERE BATCH_CODE='" + batchName +
                            "'),'N'");
                        insertIntoStatement.AppendLine(")");
                        insertIntoStatement.AppendLine();
                    }
                }
            }
        }

  
        private StringBuilder GetWhereClauseStatement()
        {
            // Create where clause
            var whereClauseStatement = new StringBuilder();

            if (radioButtonETLGenerationMetadata.Checked)
            {
                whereClauseStatement.AppendLine(" STAGING_AREA_TABLE IN (");
            }
            else
            {
                whereClauseStatement.AppendLine(" TABLE_NAME IN (");
            }

            if (checkedListBoxStagingTables.CheckedItems.Count != 0)
            {
                for (int x = 0; x <= checkedListBoxStagingTables.CheckedItems.Count - 1; x++)
                {
                    var stagingTableName = checkedListBoxStagingTables.CheckedItems[x].ToString();
                    whereClauseStatement.AppendLine("'" + stagingTableName + "',");
                }
            }
            whereClauseStatement.Remove(whereClauseStatement.Length - 3, 3);
            whereClauseStatement.AppendLine(")");
            return whereClauseStatement;
        }

        private void AddDeletes(StringBuilder insertIntoStatement)
        {
            insertIntoStatement.AppendLine("DELETE FROM EVENT_LOG;");
            insertIntoStatement.AppendLine("DELETE FROM SOURCE_CONTROL;");
            insertIntoStatement.AppendLine("DELETE FROM MODULE_INSTANCE;");
            insertIntoStatement.AppendLine("DELETE FROM BATCH_INSTANCE;");
            insertIntoStatement.AppendLine("DELETE FROM MODULE_DATA_STORE;");
            insertIntoStatement.AppendLine("DELETE FROM BATCH_MODULE;");
            insertIntoStatement.AppendLine("DELETE FROM MODULE_PARAMETER;");
            insertIntoStatement.AppendLine("DELETE FROM MODULE;");
            insertIntoStatement.AppendLine("DELETE FROM BATCH;");
            insertIntoStatement.AppendLine("DELETE FROM RECORD_SOURCE;");
            insertIntoStatement.AppendLine("DELETE FROM DATA_STORE_COLUMN;");
            insertIntoStatement.AppendLine("DELETE FROM DATA_STORE_FILE;");
            insertIntoStatement.AppendLine("DELETE FROM DATA_STORE;");
            insertIntoStatement.AppendLine();
        }

        private void GenerateInitialMetadata()
        {
            /* Register record source */
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "--Initial DIRECT values\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "INSERT INTO [RECORD_SOURCE]\r\n";
            DebuggingTextbox.Text += "([RECORD_SOURCE_CODE],[RECORD_SOURCE_DESCRIPTION])\r\n";
            DebuggingTextbox.Text += "VALUES\r\n";
            DebuggingTextbox.Text += "('Data Warehouse','Data Warehouse'),\r\n";
            DebuggingTextbox.Text += "('ACURITY','ETL Framework demo system'),\r\n";
            DebuggingTextbox.Text += "('XYZ','Reference data')\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "-- Placeholder values for referential integrity\r\n";
            DebuggingTextbox.Text += "-- Batch\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT BATCH ON\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "INSERT BATCH(BATCH_ID, FREQUENCY_CODE, BATCH_CODE, BATCH_DESCRIPTION, INACTIVE_INDICATOR)\r\n";
            DebuggingTextbox.Text += "VALUES (0, 'Continuous', 'Default Batch', 'Placeholder value for dummy Batch runs', 'N')\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT BATCH OFF\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "-- Module\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT MODULE ON\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "INSERT MODULE(MODULE_ID, AREA_CODE, MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPE_CODE, INACTIVE_INDICATOR)\r\n";
            DebuggingTextbox.Text += "VALUES (0, 'STG', 'Default Module', 'Placeholder value for dummy Module runs', 'SSIS', 'N')\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT MODULE OFF\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "-- Batch Instance\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT BATCH_INSTANCE ON\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "INSERT BATCH_INSTANCE(BATCH_INSTANCE_ID, BATCH_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, BATCH_EXECUTION_SYSTEM_ID)\r\n";
            DebuggingTextbox.Text += "VALUES (0, 0, '1900-01-01', '9999-12-31', 'P', 'P', 'S', 'N/A')\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT BATCH_INSTANCE OFF\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "-- Module Instance\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT MODULE_INSTANCE ON\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "INSERT MODULE_INSTANCE(MODULE_INSTANCE_ID, MODULE_ID, BATCH_INSTANCE_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, MODULE_EXECUTION_SYSTEM_ID, ROWS_INPUT, ROWS_INSERTED, ROWS_UPDATED, ROWS_DELETED, ROWS_DISCARDED, ROWS_REJECTED)\r\n";
            DebuggingTextbox.Text += "VALUES (0, 0, 0,'1900-01-01', '9999-12-31', 'P', 'P', 'S', 'N/A',0,0,0,0,0,0)\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT MODULE_INSTANCE OFF\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "--End of script\r\n";

        }

        public DataTable GetDataTable(ref SqlConnection sqlConnection, string sql)
        {
            // Pass the connection to a command object
            var sqlCommand = new SqlCommand(sql, sqlConnection);
            var sqlDataAdapter = new SqlDataAdapter { SelectCommand = sqlCommand };

            var dataTable = new DataTable();

            // Adds or refreshes rows in the DataSet to match those in the data source

            try
            {
                sqlDataAdapter.Fill(dataTable);
            }

            catch (Exception exception)
            {
                MessageBox.Show(@"SQL error: " + exception.Message + "\r\n\r\n The executed query was: " + sql +
                                "\r\n\r\n The connection used was " + sqlConnection.ConnectionString, "An issue has been encountered", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return null;
            }
            return dataTable;
        }

        private void InitialiseSourceTargetPaths()
        {
            var targetPath = textBoxOutputPath.Text;

            try
            {
                if (!Directory.Exists(targetPath))
                {
                    Directory.CreateDirectory(targetPath);
                }
                else
                {
                    richTextBoxInformation.Text += "\r\nThe required target directory " + targetPath + " is present.";
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("The " + targetPath + " is not present and cannot be created. The error message is " + ex, "An issue has been encountered", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }

        }

        static class GlobalVariables
        {
            private static readonly string ConfigurationLocalPath = Application.StartupPath + @"\Configuration\";
            private const string FileLocalName = "DIRECT_Management_configuration.txt";


            public static string ConfigurationPath
            {
                get { return ConfigurationLocalPath; }
            }

            public static string ConfigfileName
            {
                get { return FileLocalName; }
            }
        }

        private void InitializePath()
        {
            var configurationPath = Application.StartupPath + @"\Configuration\";
            var outputPath = Application.StartupPath + @"\Output\";

            try
            {
                if (!Directory.Exists(configurationPath))
                {
                    Directory.CreateDirectory(configurationPath);
                }

                if (!Directory.Exists(outputPath))
                {
                    Directory.CreateDirectory(outputPath);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error creation default directory at " + configurationPath +" the message is "+ex, "An issue has been encountered", MessageBoxButtons.OK,MessageBoxIcon.Error);
            }

            try
            {
                if (!Directory.Exists(outputPath))
                {
                    Directory.CreateDirectory(outputPath);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error creation default directory at " + outputPath + " the message is " + ex, "An issue has been encountered", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }

            try
            {
                if (!File.Exists(GlobalVariables.ConfigurationPath + GlobalVariables.ConfigfileName))
                {
                    var initialConfigurationFile = new StringBuilder();

                    initialConfigurationFile.AppendLine("/* ETL Metadata Management Configuration Settings */");
                    initialConfigurationFile.AppendLine("/* Roelant Vos - 2018 */");
                    initialConfigurationFile.AppendLine(@"targetPath|C:\Files\TestOutput\");
                    initialConfigurationFile.AppendLine(@"connectionStringGenerationMetadata|Provider=SQLNCLI11;Server=.;Initial Catalog=EDW_900_Metadata;User ID=sa; Password=K3kobus2");
                    initialConfigurationFile.AppendLine(@"GenerationMetaDataDatabaseName|EDW_900_Metadata");
                    initialConfigurationFile.AppendLine(@"connectionStringDirect|Provider=SQLNCLI11;Server=.;Initial Catalog=EDW_900_Metadata; User ID=sa; Password=K3kobus2");
                    initialConfigurationFile.AppendLine(@"DirectDatabaseName|PDV_RV2");
                    initialConfigurationFile.AppendLine(@"connectionStringSTG|Provider=SQLNCLI11;Server=.;Initial Catalog=EDW_100_Staging_Area;User ID=sa; Password=K3kobus2");
                    initialConfigurationFile.AppendLine(@"STGDatabaseName|EDW_100_Staging_Area");
                    initialConfigurationFile.AppendLine(@"connectionStringPSA|Provider=SQLNCLI11;Server=.;Initial Catalog=EDW_150_Persistent_Staging_Area;User ID=sa; Password=K3kobus2");
                    initialConfigurationFile.AppendLine(@"PSADatabaseName|EDW_150_Persistent_Staging_Area");                
                    initialConfigurationFile.AppendLine("/* End of file */");

                    using (var outfile = new StreamWriter(GlobalVariables.ConfigurationPath + GlobalVariables.ConfigfileName))
                    {
                        outfile.Write(initialConfigurationFile.ToString());
                        outfile.Close();
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "An error occurred while creation the default Configuration File. The error message is " + ex, "An issue has been encountered", MessageBoxButtons.OK,MessageBoxIcon.Error);
            }
        }

        private void InitialiseConnections(string chosenFile)
        {
            var configList = new Dictionary<string, string>();
            var fs = new FileStream(chosenFile, FileMode.Open, FileAccess.Read);
            var sr = new StreamReader(fs);

            try
            {
                string textline;
                while ((textline = sr.ReadLine()) != null)
                {
                    if (textline.IndexOf(@"/*", StringComparison.Ordinal) == -1)
                    {
                        var line = textline.Split('|');
                        configList.Add(line[0], line[1]);
                    }
                }

                sr.Close();
                fs.Close();

                // Output Path
                textBoxOutputPath.Text = configList["targetPath"];

                // Generation Metadata                 
                textBoxGenerationMetadataConnection.Text = configList["connectionStringGenerationMetadata"].ToString().Replace("Provider=SQLNCLI11;", ""); ;
                textBoxGenerationMetadataDatabaseName.Text = configList["GenerationMetaDataDatabaseName"];

                // DIRECT Metadata
                textBoxDirectConnection.Text = configList["connectionStringDirect"].ToString().Replace("Provider=SQLNCLI11;", "");
                textBoxDirectDatabase.Text = configList["DirectDatabaseName"];

                // Staging Area Metadata
                textBoxSTGConnection.Text = configList["connectionStringSTG"].ToString().Replace("Provider=SQLNCLI11;", "");
                textBoxSTGDatabase.Text = configList["STGDatabaseName"];

                // Persistent Staging Metadata
                textBoxPSAConnection.Text = configList["connectionStringPSA"].ToString().Replace("Provider=SQLNCLI11;", "");
                textBoxPSADatabase.Text = configList["PSADatabaseName"];

                // Reporting back to the user
                richTextBoxInformation.Text += "The default values were loaded. \r\n\r\n";
                richTextBoxInformation.Text += @"The file " + chosenFile + " was uploaded successfully. \r\n";
            }
            catch (Exception ex)
            {
                richTextBoxInformation.Text += ("\r\n\r\nAn error occured while interpreting the configuration file. The original error is: '" + ex.Message + "'");
            }

        }

        private void openOutputDirectoryToolStripMenuItem_Click(object sender, EventArgs e)
        {
            try
            {
                Process.Start(textBoxOutputPath.Text);
            }
            catch (Exception ex)
            {
                DebuggingTextbox.Text = "An error has occured while attempting to open the output directory. The error message is: "+ex;
            }
        }

        private void openConfigurationFileToolStripMenuItem_Click(object sender, EventArgs e)
        {
            var configurationPath = Application.StartupPath + @"\Configuration\";
            var theDialog = new OpenFileDialog
            {
                Title = @"Open Configuration File",
                Filter = @"Text files|*.txt",
                InitialDirectory = @""+configurationPath+""
            };

            if (theDialog.ShowDialog() != DialogResult.OK) return;
            try
            {
                var myStream = theDialog.OpenFile();

                using (myStream)
                {
                    DebuggingTextbox.Clear();
                    var chosenFile = theDialog.FileName;
                    InitialiseConnections(chosenFile);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error: Could not read file from disk. Original error: " + ex.Message, "An issues has been encountered", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void exitToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }
      
        private void CloseAboutForm(object sender, FormClosedEventArgs e)
        {
            _myAboutForm = null;
        }

        private void aboutToolStripMenuItem_Click(object sender, EventArgs e)
        {
            var t = new System.Threading.Thread(ThreadProcAbout);
            t.Start();
        }

        private void helpToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            MessageBox.Show("This feature is yet to be implemented.", "Upcoming!", MessageBoxButtons.OK,
                MessageBoxIcon.Exclamation);
        }

        private FormAbout _myAboutForm;
        public void ThreadProcAbout()
        {
            if (_myAboutForm == null)
            {
                _myAboutForm = new FormAbout(this);
                _myAboutForm.Show();

                Application.Run();
            }

            else
            {
                if (_myAboutForm.InvokeRequired)
                {
                    // Thread Error
                    _myAboutForm.Invoke((MethodInvoker)(() => _myAboutForm.Close()));
                    _myAboutForm.FormClosed += CloseAboutForm;

                    _myAboutForm = new FormAbout(this);
                    _myAboutForm.Show();
                    Application.Run();
                }
                else
                {
                    // No invoke required - same thread
                    _myAboutForm.FormClosed += CloseAboutForm;

                    _myAboutForm = new FormAbout(this);
                    _myAboutForm.Show();
                    Application.Run();
                }
            }
        }

        private void saveConfigurationFileToolStripMenuItem_Click(object sender, EventArgs e)
        {
            // Create a file backup
            try
            {
                if (File.Exists(GlobalVariables.ConfigurationPath + GlobalVariables.ConfigfileName))
                {
                    var shortDatetime = DateTime.Now.ToString("yyyyMMddHHmmss");
                    var targetFilePathName = GlobalVariables.ConfigurationPath +
                                             string.Concat("Backup_"+shortDatetime+"_",GlobalVariables.ConfigfileName);

                    File.Copy(GlobalVariables.ConfigurationPath + GlobalVariables.ConfigfileName,targetFilePathName);
                    richTextBoxInformation.Text="A backup of the current configuration was made at "+targetFilePathName;
                }
                else
                {
                    InitializePath();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("An error has occured while creating a file backup. The error message is " + ex, "An issue has been encountered",MessageBoxButtons.OK, MessageBoxIcon.Error);
            }

            // Update the configuration file
            try
            {
                var configurationFile = new StringBuilder();

                configurationFile.AppendLine("/* ETL Process Control Management Configuration Settings */");
                configurationFile.AppendLine("/* Saved at "+DateTime.Now+" */");

                configurationFile.AppendLine("targetPath|" + textBoxOutputPath.Text + "");
                configurationFile.AppendLine("connectionStringMetadata|" + textBoxGenerationMetadataConnection.Text + "");
                configurationFile.AppendLine("MetaDataDatabaseName|" + textBoxGenerationMetadataDatabaseName.Text + "");

                configurationFile.AppendLine("/* End of file */");



                using (var outfile = new StreamWriter(GlobalVariables.ConfigurationPath + GlobalVariables.ConfigfileName))
                {
                    outfile.Write(configurationFile.ToString());
                    outfile.Close();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("An error occured saving the Configuration File. The error message is " + ex, "An issue has been encountered", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void DebuggingTextbox_LinkClicked(object sender, LinkClickedEventArgs e)
        {
            var linkText = e.LinkText.Replace((char)160, ' ');
            Process.Start(linkText);
        }
        
        private void FormMain_Load(object sender, EventArgs e)
        {

        }

        private void ButtonPopulateMetadata (object sender, EventArgs e)
        {
            PopulateCheckbox();
        }

        private void PopulateCheckbox()
        {
            // Clear the existing checkboxes
            checkedListBoxStagingTables.Items.Clear();

            // Query the metadata for the STG and HSTG tables
            var queryMetadata = new StringBuilder();

            if (radioButtonETLGenerationMetadata.Checked)
            {
                queryMetadata.AppendLine("SELECT DISTINCT STAGING_AREA_TABLE");
                queryMetadata.AppendLine("FROM [MD_TABLE_MAPPING] spec");
                queryMetadata.AppendLine("WHERE STAGING_AREA_TABLE!='N/A'");
                queryMetadata.AppendLine("AND VERSION_ID=0");    
                queryMetadata.AppendLine("AND STAGING_AREA_TABLE LIKE '%" + textBoxFilterCriterion.Text + "%'");
            }
            else
            {
                queryMetadata.AppendLine("SELECT TABLE_NAME AS STAGING_AREA_TABLE");
                queryMetadata.AppendLine("FROM EDW_100_Staging_Area.INFORMATION_SCHEMA.TABLES spec");
                queryMetadata.AppendLine("WHERE TABLE_NAME!='N/A' ");
                queryMetadata.AppendLine("AND TABLE_TYPE='BASE TABLE' ");
                queryMetadata.AppendLine("AND TABLE_NAME NOT LIKE '%_LANDING' ");
                queryMetadata.AppendLine("AND TABLE_NAME LIKE '%" + textBoxFilterCriterion.Text + "%'");
                queryMetadata.AppendLine("ORDER BY STAGING_AREA_TABLE ");
            }

            //if (checkBoxVerboseDebugging.Checked)
            //{
            //    DebuggingTextbox.Text = queryMetadata.ToString();
            //}

            var connDirect = new SqlConnection {ConnectionString = textBoxGenerationMetadataConnection.Text};

            try
            {
                connDirect.Open();
            }
            catch (Exception exception)
            {
                richTextBoxInformation.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                         exception.Message;
            }

            try
            {
                var tables = GetDataTable(ref connDirect, queryMetadata.ToString());

                if (tables != null)
                {
                    if (tables.Rows.Count == 0)
                    {
                        richTextBoxInformation.Text =
                            "There was no metadata available to generate the base (Staging Area) tables. Please check the metadata schema or the database connection.";
                    }

                    foreach (DataRow row in tables.Rows)
                    {
                        var targetTableName = (string) row["STAGING_AREA_TABLE"];
                        checkedListBoxStagingTables.Items.Add(targetTableName);
                    }
                }
            }
            catch (Exception)
            {
                MessageBox.Show("There is no database connection! Please check the details in the information pane.","An issue has been encountered", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void PopulateReinitialisationCheckbox()
        {
            // Clear the existing checkboxes
            checkedListboxReinistalisation.Items.Clear();

            // Query the metadata for the STG and HSTG tables
            var queryMetadata = new StringBuilder();

            if (radioButtonSTG.Checked)
            {
                queryMetadata.AppendLine("SELECT TABLE_NAME AS TABLE_NAME");
                queryMetadata.AppendLine("FROM " + textBoxSTGDatabase.Text + ".INFORMATION_SCHEMA.TABLES spec");
                queryMetadata.AppendLine("WHERE TABLE_NAME!='N/A' ");
                queryMetadata.AppendLine("AND TABLE_TYPE='BASE TABLE' ");
                queryMetadata.AppendLine("AND TABLE_NAME NOT LIKE '%_LANDING' ");
                queryMetadata.AppendLine("AND TABLE_NAME LIKE '%" + textBoxReinitialisationFilterCriterion.Text + "%'");
                queryMetadata.AppendLine("ORDER BY TABLE_NAME ");
            }
            else //It's a PSA selection
            {
                queryMetadata.AppendLine("SELECT MODULE_CODE AS TABLE_NAME");
                queryMetadata.AppendLine("FROM SOURCE_CONTROL sct");
                queryMetadata.AppendLine("JOIN MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID=modinst.MODULE_INSTANCE_ID");
                queryMetadata.AppendLine("JOIN MODULE module ON modinst.MODULE_ID = module.MODULE_ID");
                queryMetadata.AppendLine("WHERE MODULE_CODE LIKE '" + textBoxDataVaultPrefix .Text+ "%'");
                queryMetadata.AppendLine("AND MODULE_CODE LIKE '%" + textBoxReinitialisationFilterCriterion.Text + "%'");
                queryMetadata.AppendLine("ORDER BY MODULE_CODE ");
            }

            //if (checkBoxVerboseDebugging.Checked)
            //{
            //    DebuggingTextbox.Text = queryMetadata.ToString();
            //}

            var conn = new SqlConnection();
            if (radioButtonSTG.Checked)
            {
                conn.ConnectionString = textBoxSTGConnection.Text;
            }
            else
            {
                conn.ConnectionString = textBoxDirectConnection.Text;
            }

            try
            {
                conn.Open();
            }
            catch (Exception exception)
            {
                richTextBoxInformation.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " + exception.Message;
            }

            try
            {
                var tables = GetDataTable(ref conn, queryMetadata.ToString());

                if (tables != null)
                {
                    if (tables.Rows.Count == 0)
                    {
                        richTextBoxInformation.Text =
                            "There was no metadata available to generate the base tables. Please check the database connection.";
                    }

                    foreach (DataRow row in tables.Rows)
                    {
                        checkedListboxReinistalisation.Items.Add((string) row["TABLE_NAME"]);
                    }
                }
            }
            catch (Exception)
            {
                MessageBox.Show("There is no database connection! Please check the details in the information pane.", "An issue has been encountered", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void checkBoxSelectAll_CheckedChanged(object sender, EventArgs e)
        {
            //MessageBox.Show(checkBoxSelectAll.Checked.ToString());
            for (int x = 0; x <= checkedListBoxStagingTables.Items.Count - 1; x++)
            {
                if (checkBoxSelectAllMain.Checked)
                {
                    checkedListBoxStagingTables.SetItemChecked(x, true);
                }
                else
                {
                    checkedListBoxStagingTables.SetItemChecked(x, false);
                }
            }
        }

        private void radioButtonETLGenerationMetadata_CheckedChanged(object sender, EventArgs e)
        {
            if (radioButtonETLGenerationMetadata.Checked)
            {
                checkBoxGenerateInt.Enabled = true;
                checkBoxGenerateInt.Checked = true;
                checkBoxGenerateEndDating.Enabled = true;
                checkBoxGenerateEndDating.Checked = true;
            }
            else
            {
                checkBoxGenerateInt.Enabled = false;
                checkBoxGenerateInt.Checked = false;
                checkBoxGenerateEndDating.Enabled = false;
                checkBoxGenerateEndDating.Checked = false;
            }

            PopulateCheckbox();
        }

        private void textBoxFilterCriterion_TextChanged(object sender, EventArgs e)
        {
            PopulateCheckbox();
        }

        private void label1_Click(object sender, EventArgs e)
        {

        }

        private void textBoxOutputPath_TextChanged(object sender, EventArgs e)
        {

        }

        private void exitToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        private void openConfigurationFileToolStripMenuItem1_Click(object sender, EventArgs e)
        {

        }

        private void openOutputDirectoryToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            try
            {
                Process.Start(textBoxOutputPath.Text);
            }
            catch (Exception ex)
            {
                richTextBoxInformation.Text ="An error has occured while attempting to open the output directory. The error message is: "+ex;
            }
        }

        private void checkedListBox1_SelectedIndexChanged(object sender, EventArgs e)
        {

        }

        private void radioButtonSTG_CheckedChanged(object sender, EventArgs e)
        {
            PopulateReinitialisationCheckbox();
        }

        private void textBoxReinitialisationFilterCriterion_TextChanged(object sender, EventArgs e)
        {
            PopulateReinitialisationCheckbox();
        }

        private void checkBox1_CheckedChanged(object sender, EventArgs e)
        {
            for (int x = 0; x <= checkedListboxReinistalisation.Items.Count - 1; x++)
            {
                if (checkBoxSelectAllReinistialisation.Checked)
                {
                    checkedListboxReinistalisation.SetItemChecked(x, true);
                }
                else
                {
                    checkedListboxReinistalisation.SetItemChecked(x, false);
                }
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            if (checkedListboxReinistalisation.CheckedItems.Count != 0)
            {
                richTextBoxInformation.Clear();
                DebuggingTextbox.Clear();

                // Initial SQL and creation of output content (stringbuilder)
                var sqlStatement = new StringBuilder();

                string targetDatabaseName = "";
                string sourceDatabaseName = "";
                var conn = new SqlConnection();

                if (radioButtonSTG.Checked)
                {
                    targetDatabaseName = textBoxSTGDatabase.Text; // Target is STG
                    sourceDatabaseName = textBoxPSADatabase.Text; // Source is PSA
                    conn.ConnectionString = textBoxSTGConnection.Text;
                }
                else // It's a PSA source
                {
                    targetDatabaseName = textBoxDirectDatabase.Text; // Source and target both DIRECT
                    sourceDatabaseName = textBoxDirectDatabase.Text;
                    conn.ConnectionString = textBoxDirectConnection.Text;
                }

                // Cycle through selected items (tables) and prepare statement
                for (int x = 0; x <= checkedListboxReinistalisation.CheckedItems.Count - 1; x++)
                {
                    var targetTableName = checkedListboxReinistalisation.CheckedItems[x].ToString();
                    var sourceTableName = "";

                    //Convert to just a day
                    var truncationDate = dateTimePickerReinitialisation.Value.ToString("yyyy-MM-dd");

                    if (radioButtonSTG.Checked)
                    {
                        sourceTableName = 'H'+targetTableName; // Source is the PSA
                    }
                    else // It's a PSA source
                    {
                        sourceTableName = targetTableName; // Source and target are the same (PSA)
                    }

                    richTextBoxInformation.Text += "Working on " + targetTableName + ".";

                    if (radioButtonSTG.Checked)
                    {
                        conn = generateSTGReinitialisationQuery(truncationDate, sqlStatement, targetDatabaseName, sourceDatabaseName, conn, targetTableName, sourceTableName);
                    }
                    else // It's a PSA source
                    {
                        conn = generatePSAReinitialisationQuery(truncationDate, sqlStatement, targetDatabaseName, sourceDatabaseName, conn, targetTableName, sourceTableName);
                    }

                
                    int returnValue = 0;
                    if (checkBoxExecuteReinitialisation.Checked)
                    {
                        using (var connectionVersion = new SqlConnection(conn.ConnectionString))
                        {
                            var commandVersion = new SqlCommand(sqlStatement.ToString(), connectionVersion);

                            try
                            {
                                connectionVersion.Open();
                                commandVersion.ExecuteNonQuery();
                            }
                            catch
                            {
                                richTextBoxInformation.Text += "The generated query could not be executed against the database. The attempted query was " + sqlStatement + ".\r\n";
                            }
                        }
                    }


                    richTextBoxInformation.Text += " Completed, processed "+returnValue+" row(s).\r\n";

                    DebuggingTextbox.Text += sqlStatement.ToString();

                    sqlStatement.Clear();
                }

                //Redirect to the output

                this.MainTabControl.SelectedTab = tabPageOutput;
            }
            else
            {
                MessageBox.Show("No tables were selected to re-initialise...");
            }
        }

        private SqlConnection generateSTGReinitialisationQuery(string truncationDate, StringBuilder sqlStatement, string targetDatabaseName, string sourceDatabaseName, SqlConnection conn, string targetTableName, string sourceTableName)
        {
            // Query the attribute metadata to create the customer insert and select statements for each table
            var queryAttributeMetadata = new StringBuilder();

            queryAttributeMetadata.AppendLine("SELECT COLUMN_NAME");
            queryAttributeMetadata.AppendLine("FROM " + textBoxSTGDatabase.Text + ".INFORMATION_SCHEMA.COLUMNS");
            queryAttributeMetadata.AppendLine("WHERE TABLE_NAME = '" + targetTableName + "' ");
            //queryAttributeMetadata.AppendLine("AND SUBSTRING(COLUMN_NAME,1,3)<>'OMD' ");

            sqlStatement.AppendLine("/* Run the following in the " + targetDatabaseName + " database */");
            sqlStatement.AppendLine("USE [" + targetDatabaseName + "];");
            sqlStatement.AppendLine();

            if (truncationDate=="1900-01-01")
            {
                // This indicates the full set. Run a truncate or it will take forever.
                sqlStatement.AppendLine("TRUNCATE TABLE [" + targetDatabaseName + "].[dbo]. [" + targetTableName + "];");
            }
            else
            {
                // Run a delete for a selection.
                sqlStatement.AppendLine("DELETE FROM [" + targetDatabaseName + "].[dbo]. [" + targetTableName + "] WHERE INSERT_DATETIME>='" + truncationDate + "';");
            }

            sqlStatement.AppendLine("SET IDENTITY_INSERT [" + targetDatabaseName + "].[dbo].[" + targetTableName + "] ON;");
            sqlStatement.AppendLine("INSERT INTO [" + targetDatabaseName + "].[dbo].[" + targetTableName + "]");
            sqlStatement.AppendLine("(");
            sqlStatement.AppendLine("  [INSERT_MODULE_INSTANCE_ID],");
            sqlStatement.AppendLine("  [INSERT_DATETIME],");
            sqlStatement.AppendLine("  [RECORD_SOURCE],");
            sqlStatement.AppendLine("  [CDC_OPERATION],");
            sqlStatement.AppendLine("  [HASH_FULL_RECORD],");
            sqlStatement.AppendLine("  [EVENT_DATETIME],");
            sqlStatement.AppendLine("  [SOURCE_ROW_ID],");

            try
            {
                // Attribute selection (queried from data dictionary / catalog)
                var attributeDataTable = GetDataTable(ref conn, queryAttributeMetadata.ToString());

                foreach (DataRow row in attributeDataTable.Rows)
                {
                    sqlStatement.AppendLine("  [" + (string)row["COLUMN_NAME"] + "],");
                }
            }
            catch
            {
                richTextBoxInformation.Text += "Issues have occurred querying the metadata for " + targetTableName + ". The attempted query was " + queryAttributeMetadata.ToString() + ".\r\n";
            }

            sqlStatement.Remove(sqlStatement.Length - 3, 3);
            sqlStatement.AppendLine();
            sqlStatement.AppendLine(")");

            sqlStatement.AppendLine("SELECT");
            sqlStatement.AppendLine("  [INSERT_MODULE_INSTANCE_ID],");
            sqlStatement.AppendLine("  [INSERT_DATETIME],");
            sqlStatement.AppendLine("  [RECORD_SOURCE],");
            sqlStatement.AppendLine("  [CDC_OPERATION],");
            sqlStatement.AppendLine("  [HASH_FULL_RECORD],");
            sqlStatement.AppendLine("  [EVENT_DATETIME],");
            sqlStatement.AppendLine("  [SOURCE_ROW_ID],");

            try
            {
                // Attribute selection (queried from data dictionary / catalog)
                var attributeDataTable = GetDataTable(ref conn, queryAttributeMetadata.ToString());

                foreach (DataRow row in attributeDataTable.Rows)
                {
                    sqlStatement.AppendLine("  [" + (string)row["COLUMN_NAME"] + "],");
                }
            }
            catch
            {
                richTextBoxInformation.Text += "Issues have occurred querying the metadata for " + targetTableName + ". The attempted query was " + queryAttributeMetadata.ToString() + ".\r\n";
            }

            sqlStatement.Remove(sqlStatement.Length - 3, 3);
            sqlStatement.AppendLine();

            sqlStatement.AppendLine("FROM [" + sourceDatabaseName + "].[dbo].[" + sourceTableName + "]");

            if (truncationDate != "1900-01-01")
            {
                // Add the WHERE clause for PSA selection
                sqlStatement.AppendLine("WHERE INSERT_DATETIME>='" + truncationDate + "'");
            }
            sqlStatement.Remove(sqlStatement.Length - 2, 2);
            sqlStatement.Append(";");
            sqlStatement.AppendLine();

            sqlStatement.AppendLine("SET IDENTITY_INSERT [" + targetDatabaseName + "].[dbo]. [" + targetTableName + "] OFF;");

            sqlStatement.AppendLine();
            sqlStatement.AppendLine("GO");
            sqlStatement.AppendLine();
            return conn;
        }

        private SqlConnection generatePSAReinitialisationQuery(string truncationDate, StringBuilder sqlStatement, string targetDatabaseName, string sourceDatabaseName, SqlConnection conn, string targetTableName, string sourceTableName)
        {

            // Delete the load window where the selected date falls in. You can't just delete greater than the date, you need to detect what the closest lower range is and delete from there.
            sqlStatement.AppendLine("/* Run the following in the " + targetDatabaseName + " database */");
            sqlStatement.AppendLine("USE [" + targetDatabaseName + "];");
            sqlStatement.AppendLine();

            sqlStatement.AppendLine("DELETE sct");
            sqlStatement.AppendLine("FROM SOURCE_CONTROL sct");
            sqlStatement.AppendLine("JOIN MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID=modinst.MODULE_INSTANCE_ID");
            sqlStatement.AppendLine("JOIN MODULE module ON modinst.MODULE_ID = module.MODULE_ID");
            sqlStatement.AppendLine("WHERE MODULE_CODE = '" + targetTableName + "'");
            sqlStatement.AppendLine("AND MODULE_SOURCE_CONTROL_ID >= ");
            sqlStatement.AppendLine("(");
            sqlStatement.AppendLine("	SELECT MODULE_SOURCE_CONTROL_ID");
            sqlStatement.AppendLine("	FROM SOURCE_CONTROL sct");
            sqlStatement.AppendLine("	JOIN MODULE_INSTANCE modinst ON sct.MODULE_INSTANCE_ID=modinst.MODULE_INSTANCE_ID");
            sqlStatement.AppendLine("	JOIN MODULE module ON modinst.MODULE_ID = module.MODULE_ID");
            sqlStatement.AppendLine("	WHERE MODULE_CODE = '" + targetTableName + "'");
            sqlStatement.AppendLine("	AND '" + truncationDate + "' BETWEEN INTERVAL_START_DATETIME AND INTERVAL_END_DATETIME");
            sqlStatement.AppendLine(")");
 
            sqlStatement.AppendLine();
            sqlStatement.AppendLine("GO");
            sqlStatement.AppendLine();

            return conn;
        }

        private void checkBoxSelectAllReinistialisation_CheckedChanged(object sender, EventArgs e)
        {
            //MessageBox.Show(checkBoxSelectAll.Checked.ToString());
            for (int x = 0; x <= checkedListboxReinistalisation.Items.Count - 1; x++)
            {
                if (checkBoxSelectAllReinistialisation.Checked)
                {
                    checkedListboxReinistalisation.SetItemChecked(x, true);
                }
                else
                {
                    checkedListboxReinistalisation.SetItemChecked(x, false);
                }
            }
        }

        private void groupBox12_Enter(object sender, EventArgs e)
        {

        }

        private void button3_Click(object sender, EventArgs e)
        {
            PopulateReinitialisationCheckbox();
        }

        private void openConfigurationDirectoryToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Process.Start(Application.StartupPath + @"\Configuration\");
        }

        private void saveConfigurationFileToolStripMenuItem_Click_1(object sender, EventArgs e)
        {

        }
    }
}
