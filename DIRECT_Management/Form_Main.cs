using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Windows.Forms;

namespace OMD_Manager
{


    public partial class FormMain : Form
    {
        public FormMain()
        {
            InitializeComponent();
            InitializePath();

            richTextBoxOutput.Text = "Application initialised - OMD Management. \r\n\r\n";

            try
            {
                InitialiseConnections(GlobalVariables.ConfigurationPath + GlobalVariables.ConfigfileName);
            }
            catch (Exception ex)
            {
                richTextBoxOutput.Text += "Errors occured trying to load the configuration file, the message is " + ex + ". No default values were loaded. \r\n\r\n";
            }

            InitialiseSourceTargetPaths();

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
        }


        private void ButtonGenerateOmdMetadata(object sender, EventArgs e)
        {
            if (checkedListBoxStagingTables.CheckedItems.Count != 0)
            {
                richTextBoxOutput.Clear();

                // Initial SQL and creation of output content (stringbuilder)
                var insertIntoStatement = new StringBuilder();

                insertIntoStatement.AppendLine("/* Run the following in OMD_Framework database */");
                insertIntoStatement.AppendLine("USE [EDW_900_OMD_Framework];");
                insertIntoStatement.AppendLine();

                // Add the initial delete statements
                if (checkBoxAddDelete.Checked)
                {
                    AddOmdDeletes(insertIntoStatement);
                }

                // Module statements
                if (checkBoxGenerateModules.Checked)
                {
                    if (checkBoxGenerateStg.Checked == false && checkBoxGenerateHstg.Checked == false && checkBoxGenerateInt.Checked == false && checkBoxGenerateEndDating.Checked == false)
                    {
                        richTextBoxOutput.Text = "No valid selection was made to generate outputs!";
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
                        richTextBoxOutput.Text = "No valid selection was made to generate outputs!";
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
                        richTextBoxOutput.Text = "No valid selection was made to generate outputs!";
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
                        richTextBoxOutput.Text = "No valid selection was made to generate outputs!";
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
                        richTextBoxOutput.Text = "No valid selection was made to generate outputs!";
                    }
                    else
                    {
                        AddModuleDataStoreContent(insertIntoStatement);
                    }
                }

                //Output
                DebuggingTextbox.Text = insertIntoStatement.ToString();

                if (checkBoxInitialOMD.Checked)
                {
                    GenerateInitialOmdMetadata();
                }
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
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM OMD_MODULE WHERE MODULE_CODE='m_100_" + stagingTableName + "')");
                        }
                        insertIntoStatement.AppendLine("INSERT INTO [OMD_MODULE] ([AREA_CODE],[MODULE_CODE],[MODULE_DESCRIPTION],[MODULE_TYPE_CODE])");
                        insertIntoStatement.AppendLine("VALUES ('STG','m_100_" + stagingTableName +
                                                       "','Source to Staging ETL for " +
                                                       stagingTableName + "', 'SSIS')");
                    }
                }
                else
                {
                    richTextBoxOutput.Text =
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
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM OMD_MODULE WHERE MODULE_CODE='m_150_H" + stagingTableName + "')");
                        }
                        insertIntoStatement.AppendLine(
                            "INSERT INTO [OMD_MODULE] ([AREA_CODE],[MODULE_CODE],[MODULE_DESCRIPTION],[MODULE_TYPE_CODE])");
                        insertIntoStatement.AppendLine("VALUES ('HSTG','m_150_H" + stagingTableName +
                                                       "','Staging to History Staging ETL for H" + stagingTableName +
                                                       "', 'SSIS')");
                    }
                }
                else
                {
                    richTextBoxOutput.Text =
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

                    if (checkBoxOMDVerboseDebugging.Checked)
                    {
                        DebuggingTextbox.Text = queryIntMetadata.ToString();
                    }

                    var connOmd = new SqlConnection { ConnectionString = textBoxMetadataConnection.Text };

                    try
                    {
                        connOmd.Open();
                    }
                    catch (Exception exception)
                    {
                        richTextBoxOutput.Text =
                            "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                            exception.Message;
                    }

                    var tables = GetDataTable(ref connOmd, queryIntMetadata.ToString());

                    if (tables.Rows.Count == 0)
                    {
                        richTextBoxOutput.Text =
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
                                    insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM OMD_MODULE WHERE MODULE_CODE = 'm_200_" + intTable + "_With_Driving_Key')");
                                }
                                insertIntoStatement.AppendLine(
                                    "INSERT INTO [OMD_MODULE] ([AREA_CODE],[MODULE_CODE],[MODULE_DESCRIPTION],[MODULE_TYPE_CODE])");
                                insertIntoStatement.AppendLine("VALUES ('INT','m_200_" + intTable +
                                                               "_With_Driving_Key','Driving-key based Link Satellite table sourced from " +
                                                               targetTableName + "', 'SSIS')");
                            }
                            else //Normal LSATs
                            {
                                if (checkBoxIfExists.Checked)
                                {
                                    insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM OMD_MODULE WHERE MODULE_CODE='m_200_" + intTable + "_" +
                                                                   targetTableName +
                                                                   "')");
                                }
                                insertIntoStatement.AppendLine(
                                    "INSERT INTO [OMD_MODULE] ([AREA_CODE],[MODULE_CODE],[MODULE_DESCRIPTION],[MODULE_TYPE_CODE])");
                                insertIntoStatement.AppendLine("VALUES ('INT','m_200_" + intTable + "_" + targetTableName +
                                                               "','Driving-key based Link Satellite table sourced from " +
                                                               targetTableName + "', 'SSIS')");
                            }
                        }
                        else
                        {
                            if (checkBoxIfExists.Checked)
                            {
                                insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM OMD_MODULE WHERE MODULE_CODE='m_200_" + intTable + "_" +
                                                               targetTableName + "')");
                            }
                            insertIntoStatement.AppendLine("INSERT INTO [OMD_MODULE] ([AREA_CODE],[MODULE_CODE],[MODULE_DESCRIPTION],[MODULE_TYPE_CODE])");
                            insertIntoStatement.AppendLine("VALUES ('INT','m_200_" + intTable + "_" + targetTableName +
                                                           "','Integration Layer ETL sourced from " + targetTableName + "', 'SSIS')");
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

                    if (checkBoxOMDVerboseDebugging.Checked)
                    {
                        DebuggingTextbox.Text = queryIntMetadata.ToString();
                    }

                    var connOmd = new SqlConnection { ConnectionString = textBoxMetadataConnection.Text };

                    try
                    {
                        connOmd.Open();
                    }
                    catch (Exception exception)
                    {
                        richTextBoxOutput.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                                 exception.Message;
                    }

                    var tables = GetDataTable(ref connOmd, queryIntMetadata.ToString());

                    if (tables.Rows.Count == 0)
                    {
                        richTextBoxOutput.Text =
                            "There was no metadata available to generate STG and HSTG Modules and Batches. Please check the metadata schema or the database connection.";
                    }

                    foreach (DataRow row in tables.Rows)
                    {
                        var intTableName = (string)row["INTEGRATION_AREA_TABLE"];

                        if (checkBoxIfExists.Checked)
                        {
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT MODULE_CODE FROM OMD_MODULE WHERE MODULE_CODE='m_200_" + intTableName + "_END_DATES')");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [OMD_MODULE] ([AREA_CODE],[MODULE_CODE],[MODULE_DESCRIPTION],[MODULE_TYPE_CODE])");
                        insertIntoStatement.AppendLine("VALUES ('INT','m_200_" + intTableName + "_END_DATES','End-dating logic for the table " + intTableName + "', 'SSIS')");
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


            if (checkBoxOMDVerboseDebugging.Checked)
            {
                DebuggingTextbox.Text += queryIntMetadata.ToString();
            }

            var connOmd = new SqlConnection { ConnectionString = textBoxMetadataConnection.Text };

            try
            {
                connOmd.Open();
            }
            catch (Exception exception)
            {
                richTextBoxOutput.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                            exception.Message;
            }

            var tables = GetDataTable(ref connOmd, queryIntMetadata.ToString());

            if (tables.Rows.Count == 0)
            {
                richTextBoxOutput.Text =
                    "There was no metadata available to generate STG and HSTG Modules and Batches. Please check the metadata schema or the database connection.";
            }

            foreach (DataRow row in tables.Rows)
            {
                var stagingTableName = (string)row["STAGING_AREA_TABLE"];
                var stagingBatchName = stagingTableName.Replace("_VW", "");

                if (checkBoxIfExists.Checked)
                {
                        insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT BATCH_CODE FROM OMD_BATCH WHERE BATCH_CODE='b_EDW_STG_INT_" + stagingBatchName + "')");
                }

                insertIntoStatement.AppendLine("INSERT INTO [OMD_BATCH] ([FREQUENCY_CODE],[BATCH_CODE],[BATCH_DESCRIPTION])");
                insertIntoStatement.AppendLine("VALUES ('Continuous','b_EDW_STG_INT_" + stagingBatchName + "','Source to Integration Area processing for " + stagingBatchName + "')");
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
                richTextBoxOutput.Text = "No valid selection was made to generate outputs!";
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
                    richTextBoxOutput.Text = "No valid selection was made to generate outputs!";
                }

                if (checkBoxOMDVerboseDebugging.Checked)
                {
                    DebuggingTextbox.Text += queryDataStoreMetadata.ToString();
                }
            }


            var connOmd = new SqlConnection { ConnectionString = textBoxMetadataConnection.Text };

            try
            {
                connOmd.Open();
            }
            catch (Exception exception)
            {
                richTextBoxOutput.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                            exception.Message;
            }

            if (queryDataStoreMetadata.Length > 0)
            {
                var tables = GetDataTable(ref connOmd, queryDataStoreMetadata.ToString());

                if (tables.Rows.Count == 0)
                {
                    richTextBoxOutput.Text = "There was no metadata available to generate Data Stores. Please check the metadata schema or the database connection.";
                }

                foreach (DataRow row in tables.Rows)
                {
                    var dataStoreName = (string)row["DATA_STORE"];
                    dataStoreName = dataStoreName.Replace("_VW", "");

                    if (checkBoxIfExists.Checked)
                    {
                        insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [DATA_STORE_CODE] FROM [OMD_DATA_STORE] WHERE [DATA_STORE_CODE]='" + dataStoreName + "')");
                    }

                    insertIntoStatement.AppendLine("INSERT INTO [OMD_DATA_STORE] ([DATA_STORE_CODE],[DATA_STORE_TYPE_CODE],[DATA_STORE_DESCRIPTION],[ALLOW_TRUNCATE_INDICATOR])");
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


            if (checkBoxOMDVerboseDebugging.Checked)
            {
                DebuggingTextbox.Text += queryDataStoreMetadata.ToString();
            }

            var connOmd = new SqlConnection { ConnectionString = textBoxMetadataConnection.Text };

            try
            {
                connOmd.Open();
            }
            catch (Exception exception)
            {
                richTextBoxOutput.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                            exception.Message;
            }

            var tables = GetDataTable(ref connOmd, queryDataStoreMetadata.ToString());

            if (tables.Rows.Count == 0)
            {
                richTextBoxOutput.Text = "There was no metadata available to generate Module / Data Stores relationships. Please check the metadata schema or the database connection.";
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
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [DATA_STORE_ID] FROM [OMD_MODULE_DATA_STORE] WHERE MODULE_ID=(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "') AND DATA_STORE_ID=(SELECT DATA_STORE_ID FROM OMD_DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [OMD_MODULE_DATA_STORE]  ([MODULE_ID], [DATA_STORE_ID], [RELATIONSHIP_TYPE])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT DATA_STORE_ID FROM OMD_DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'),'Target'");
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
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [DATA_STORE_ID] FROM [OMD_MODULE_DATA_STORE] WHERE MODULE_ID=(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "') AND DATA_STORE_ID=(SELECT DATA_STORE_ID FROM OMD_DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [OMD_MODULE_DATA_STORE]  ([MODULE_ID], [DATA_STORE_ID], [RELATIONSHIP_TYPE])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT DATA_STORE_ID FROM OMD_DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'),'Target'");
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
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [DATA_STORE_ID] FROM [OMD_MODULE_DATA_STORE] WHERE MODULE_ID=(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "') AND DATA_STORE_ID=(SELECT DATA_STORE_ID FROM OMD_DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [OMD_MODULE_DATA_STORE]  ([MODULE_ID], [DATA_STORE_ID], [RELATIONSHIP_TYPE])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT DATA_STORE_ID FROM OMD_DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName + "'),'Target'");
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
                                "IF NOT EXISTS (SELECT [MODULE_ID], [DATA_STORE_ID] FROM [OMD_MODULE_DATA_STORE] WHERE MODULE_ID=" +
                                "(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='m_200_" + dataStoreName + "_END_DATES" +
                                "') AND DATA_STORE_ID=(SELECT DATA_STORE_ID FROM OMD_DATA_STORE WHERE DATA_STORE_CODE='" +
                                dataStoreName + "'))");
                        }

                        insertIntoStatement.AppendLine(
                            "INSERT INTO [OMD_MODULE_DATA_STORE]  ([MODULE_ID], [DATA_STORE_ID], [RELATIONSHIP_TYPE])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine(
                            "(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='m_200_" + dataStoreName + "_END_DATES" +
                            "'),(SELECT DATA_STORE_ID FROM OMD_DATA_STORE WHERE DATA_STORE_CODE='" + dataStoreName +
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

            if (checkBoxOMDVerboseDebugging.Checked)
            {
                DebuggingTextbox.Text += queryModuleBatchMetadata.ToString();
            }

            var connOmd = new SqlConnection { ConnectionString = textBoxMetadataConnection.Text };

            try
            {
                connOmd.Open();
            }
            catch (Exception exception)
            {
                richTextBoxOutput.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                            exception.Message;
            }

            var tables = GetDataTable(ref connOmd, queryModuleBatchMetadata.ToString());

            if (tables.Rows.Count == 0)
            {
                richTextBoxOutput.Text = "There was no metadata available to generate Module / Data Stores relationships. Please check the metadata schema or the database connection.";
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
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [BATCH_ID] FROM [OMD_BATCH_MODULE] WHERE MODULE_ID=(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "') AND BATCH_ID=(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [OMD_BATCH_MODULE]  ([MODULE_ID], [BATCH_ID], [INACTIVE_INDICATOR])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName + "'),'N'");
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
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [BATCH_ID] FROM [OMD_BATCH_MODULE] WHERE MODULE_ID=(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "') AND BATCH_ID=(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [OMD_BATCH_MODULE]  ([MODULE_ID], [BATCH_ID], [INACTIVE_INDICATOR])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName + "'),'N'");
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
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [BATCH_ID] FROM [OMD_BATCH_MODULE] WHERE MODULE_ID=(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "') AND BATCH_ID=(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [OMD_BATCH_MODULE]  ([MODULE_ID], [BATCH_ID], [INACTIVE_INDICATOR])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("  (SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='" + moduleName + "'),(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName + "'),'N'");
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
                            insertIntoStatement.AppendLine("IF NOT EXISTS (SELECT [MODULE_ID], [BATCH_ID] FROM [OMD_BATCH_MODULE] WHERE MODULE_ID=(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='m_200_" + dataStoreName + "_END_DATES" + "') AND BATCH_ID=(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName + "'))");
                        }

                        insertIntoStatement.AppendLine("INSERT INTO [OMD_BATCH_MODULE]  ([MODULE_ID], [BATCH_ID], [INACTIVE_INDICATOR])");
                        insertIntoStatement.AppendLine("VALUES");
                        insertIntoStatement.AppendLine("(");
                        insertIntoStatement.AppendLine("(SELECT MODULE_ID FROM OMD_MODULE WHERE MODULE_CODE='m_200_" + dataStoreName + "_END_DATES" +"'),(SELECT BATCH_ID FROM OMD_BATCH WHERE BATCH_CODE='" + batchName +
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

        private void AddOmdDeletes(StringBuilder insertIntoStatement)
        {
            insertIntoStatement.AppendLine("DELETE FROM OMD_EVENT_LOG;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_SOURCE_CONTROL;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_MODULE_INSTANCE;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_BATCH_INSTANCE;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_MODULE_DATA_STORE;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_BATCH_MODULE;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_MODULE_PARAMETER;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_MODULE;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_BATCH;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_RECORD_SOURCE;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_DATA_STORE_COLUMN;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_DATA_STORE_FILE;");
            insertIntoStatement.AppendLine("DELETE FROM OMD_DATA_STORE;");
            insertIntoStatement.AppendLine();
        }

        private void GenerateInitialOmdMetadata()
        {
            /* Register record source */
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "--Initial OMD values\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "INSERT INTO [OMD_RECORD_SOURCE]\r\n";
            DebuggingTextbox.Text += "([OMD_RECORD_SOURCE_CODE],[OMD_RECORD_SOURCE_DESCRIPTION])\r\n";
            DebuggingTextbox.Text += "VALUES\r\n";
            DebuggingTextbox.Text += "('Data Warehouse','Data Warehouse'),\r\n";
            DebuggingTextbox.Text += "('ACURITY','ETL Framework demo system'),\r\n";
            DebuggingTextbox.Text += "('XYZ','Reference data')\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "-- Placeholder values for referential integrity\r\n";
            DebuggingTextbox.Text += "-- Batch\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT OMD_BATCH ON\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "INSERT OMD_BATCH(BATCH_ID, FREQUENCY_CODE, BATCH_CODE, BATCH_DESCRIPTION, INACTIVE_INDICATOR)\r\n";
            DebuggingTextbox.Text += "VALUES (0, 'Continuous', 'Default Batch', 'Placeholder value for dummy Batch runs', 'N')\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT OMD_BATCH OFF\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "-- Module\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT OMD_MODULE ON\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "INSERT OMD_MODULE(MODULE_ID, AREA_CODE, MODULE_CODE, MODULE_DESCRIPTION, MODULE_TYPE_CODE, INACTIVE_INDICATOR)\r\n";
            DebuggingTextbox.Text += "VALUES (0, 'STG', 'Default Module', 'Placeholder value for dummy Module runs', 'SSIS', 'N')\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT OMD_MODULE OFF\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "-- Batch Instance\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT OMD_BATCH_INSTANCE ON\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "INSERT OMD_BATCH_INSTANCE(BATCH_INSTANCE_ID, BATCH_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, BATCH_EXECUTION_SYSTEM_ID)\r\n";
            DebuggingTextbox.Text += "VALUES (0, 0, '1900-01-01', '9999-12-31', 'P', 'P', 'S', 'N/A')\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT OMD_BATCH_INSTANCE OFF\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "-- Module Instance\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT OMD_MODULE_INSTANCE ON\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "INSERT OMD_MODULE_INSTANCE(MODULE_INSTANCE_ID, MODULE_ID, BATCH_INSTANCE_ID, START_DATETIME, END_DATETIME, PROCESSING_INDICATOR, NEXT_RUN_INDICATOR, EXECUTION_STATUS_CODE, MODULE_EXECUTION_SYSTEM_ID, ROWS_INPUT, ROWS_INSERTED, ROWS_UPDATED, ROWS_DELETED, ROWS_DISCARDED, ROWS_REJECTED)\r\n";
            DebuggingTextbox.Text += "VALUES (0, 0, 0,'1900-01-01', '9999-12-31', 'P', 'P', 'S', 'N/A',0,0,0,0,0,0)\r\n";
            DebuggingTextbox.Text += "\r\n";
            DebuggingTextbox.Text += "SET IDENTITY_INSERT OMD_MODULE_INSTANCE OFF\r\n";
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
                    richTextBoxOutput.Text += "\r\nThe required target directory " + targetPath + " is present.";
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
            private const string FileLocalName = "OMD_Management_configuration.txt";


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
                    initialConfigurationFile.AppendLine("/* Roelant Vos - 2017 */");
                    initialConfigurationFile.AppendLine(@"targetPath|C:\Files\TestOutput\");
                    initialConfigurationFile.AppendLine(@"connectionStringMetadata|Provider=SQLNCLI11;Server=.;Initial Catalog=EDW_000_Metadata;Integrated Security=SSPI");
                    initialConfigurationFile.AppendLine(@"MetaDataDatabaseName|EDW_000_Metadata");
                    initialConfigurationFile.AppendLine(@"connectionStringOMD|Provider=SQLNCLI11;Server=.;Initial Catalog=EDW_900_OMD_Framework;Integrated Security=SSPI");
                    initialConfigurationFile.AppendLine(@"OMDDatabaseName|EDW_900_OMD_Framework");                  
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

                var connectionStringMetadata = configList["connectionStringMetadata"];
                connectionStringMetadata = connectionStringMetadata.Replace("Provider=SQLNCLI11;", "");

                var connectionStringOmd = configList["connectionStringOMD"];
                connectionStringOmd= connectionStringOmd.Replace("Provider=SQLNCLI11;", "");

                textBoxOutputPath.Text = configList["targetPath"];
                textBoxMetadataConnection.Text = connectionStringMetadata;
                textBoxMetaDataDatabaseName.Text = configList["MetaDataDatabaseName"];

                textBoxOmdConnection.Text = connectionStringOmd;
                textBoxOmdDatabase.Text = configList["OMDDatabaseName"];

                richTextBoxOutput.Text += "The default values were loaded. \r\n\r\n";
                richTextBoxOutput.Text += @"The file " + chosenFile + " was uploaded successfully. \r\n";
            }
            catch (Exception ex)
            {
                richTextBoxOutput.Text += ("\r\n\r\nAn error occured while interpreting the configuration file. The original error is: '" + ex.Message + "'");
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
                    richTextBoxOutput.Text="A backup of the current configuration was made at "+targetFilePathName;
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

                configurationFile.AppendLine("/* OMD Management Configuration Settings */");
                configurationFile.AppendLine("/* Saved at "+DateTime.Now+" */");

                configurationFile.AppendLine("targetPath|" + textBoxOutputPath.Text + "");
                configurationFile.AppendLine("connectionStringMetadata|" + textBoxMetadataConnection.Text + "");
                configurationFile.AppendLine("MetaDataDatabaseName|" + textBoxMetaDataDatabaseName.Text + "");

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

        private void ButtonPopulateOmdMetadata (object sender, EventArgs e)
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

            if (checkBoxOMDVerboseDebugging.Checked)
            {
                DebuggingTextbox.Text = queryMetadata.ToString();
            }

            var connOmd = new SqlConnection {ConnectionString = textBoxMetadataConnection.Text};

            try
            {
                connOmd.Open();
            }
            catch (Exception exception)
            {
                richTextBoxOutput.Text = "There was an error connecting to the database. \r\n\r\nThe error message is: " +
                                         exception.Message;
            }

            try
            {
                var tables = GetDataTable(ref connOmd, queryMetadata.ToString());

                if (tables.Rows.Count == 0)
                {
                    richTextBoxOutput.Text =
                        "There was no metadata available to generate the base (Staging Area) tables. Please check the metadata schema or the database connection.";
                }

                foreach (DataRow row in tables.Rows)
                {
                    var targetTableName = (string)row["STAGING_AREA_TABLE"];
                    checkedListBoxStagingTables.Items.Add(targetTableName);
                }
            }
            catch (Exception)
            {
                MessageBox.Show("There is no database connection! Please check the details in the information pane.","An issue has been encountered", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void checkBoxSelectAll_CheckedChanged(object sender, EventArgs e)
        {
            //MessageBox.Show(checkBoxSelectAll.Checked.ToString());
            for (int x = 0; x <= checkedListBoxStagingTables.Items.Count - 1; x++)
            {
                if (checkBoxSelectAll.Checked)
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


    }
}
