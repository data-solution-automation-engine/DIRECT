using System.Security.AccessControl;

namespace OMD_Manager
{
    partial class FormMain
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        /// 
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(FormMain));
            this.DebuggingTextbox = new System.Windows.Forms.RichTextBox();
            this.MainTabControl = new System.Windows.Forms.TabControl();
            this.tabPageBatchModule = new System.Windows.Forms.TabPage();
            this.radioButtonCatalog = new System.Windows.Forms.RadioButton();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.textBoxFilterCriterion = new System.Windows.Forms.TextBox();
            this.radioButtonETLGenerationMetadata = new System.Windows.Forms.RadioButton();
            this.checkBoxSelectAll = new System.Windows.Forms.CheckBox();
            this.checkedListBoxStagingTables = new System.Windows.Forms.CheckedListBox();
            this.button1 = new System.Windows.Forms.Button();
            this.panel2 = new System.Windows.Forms.Panel();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.checkBoxGenerateModules = new System.Windows.Forms.CheckBox();
            this.checkBoxGenerateDataStoreModule = new System.Windows.Forms.CheckBox();
            this.checkBoxGenerateBatchModule = new System.Windows.Forms.CheckBox();
            this.checkBoxGenerateDataStore = new System.Windows.Forms.CheckBox();
            this.checkBoxGenerateBatches = new System.Windows.Forms.CheckBox();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this.checkBoxGenerateEndDating = new System.Windows.Forms.CheckBox();
            this.checkBoxGenerateInt = new System.Windows.Forms.CheckBox();
            this.checkBoxGenerateStg = new System.Windows.Forms.CheckBox();
            this.checkBoxGenerateHstg = new System.Windows.Forms.CheckBox();
            this.groupBox4 = new System.Windows.Forms.GroupBox();
            this.checkBoxAddDelete = new System.Windows.Forms.CheckBox();
            this.checkBoxInitialOMD = new System.Windows.Forms.CheckBox();
            this.checkBoxIfExists = new System.Windows.Forms.CheckBox();
            this.label4 = new System.Windows.Forms.Label();
            this.buttonGeneratePSA = new System.Windows.Forms.Button();
            this.tabPageHub = new System.Windows.Forms.TabPage();
            this.tabPageReinitialise = new System.Windows.Forms.TabPage();
            this.tabPageConnectivity = new System.Windows.Forms.TabPage();
            this.labelOMDdatabase = new System.Windows.Forms.Label();
            this.textBoxOmdDatabase = new System.Windows.Forms.TextBox();
            this.label5 = new System.Windows.Forms.Label();
            this.textBoxOmdConnection = new System.Windows.Forms.TextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.textBoxMetaDataDatabaseName = new System.Windows.Forms.TextBox();
            this.groupBox5 = new System.Windows.Forms.GroupBox();
            this.checkBoxOMDVerboseDebugging = new System.Windows.Forms.CheckBox();
            this.label1 = new System.Windows.Forms.Label();
            this.MetadataConnectionLabel = new System.Windows.Forms.Label();
            this.textBoxMetadataConnection = new System.Windows.Forms.TextBox();
            this.textBoxOutputPath = new System.Windows.Forms.TextBox();
            this.tabPageOutput = new System.Windows.Forms.TabPage();
            this.menuStrip1 = new System.Windows.Forms.MenuStrip();
            this.fileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.openConfigurationFileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem2 = new System.Windows.Forms.ToolStripMenuItem();
            this.openOutputDirectoryToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.exitToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.helpToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.helpToolStripMenuItem1 = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripSeparator1 = new System.Windows.Forms.ToolStripSeparator();
            this.aboutToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.richTextBoxOutput = new System.Windows.Forms.RichTextBox();
            this.label6 = new System.Windows.Forms.Label();
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.MainTabControl.SuspendLayout();
            this.tabPageBatchModule.SuspendLayout();
            this.groupBox1.SuspendLayout();
            this.panel2.SuspendLayout();
            this.groupBox3.SuspendLayout();
            this.groupBox2.SuspendLayout();
            this.groupBox4.SuspendLayout();
            this.tabPageConnectivity.SuspendLayout();
            this.groupBox5.SuspendLayout();
            this.tabPageOutput.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.SuspendLayout();
            // 
            // DebuggingTextbox
            // 
            this.DebuggingTextbox.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.DebuggingTextbox.Location = new System.Drawing.Point(6, 6);
            this.DebuggingTextbox.Name = "DebuggingTextbox";
            this.DebuggingTextbox.Size = new System.Drawing.Size(1171, 390);
            this.DebuggingTextbox.TabIndex = 2;
            this.DebuggingTextbox.Text = "";
            this.DebuggingTextbox.LinkClicked += new System.Windows.Forms.LinkClickedEventHandler(this.DebuggingTextbox_LinkClicked);
            // 
            // MainTabControl
            // 
            this.MainTabControl.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.MainTabControl.Controls.Add(this.tabPageBatchModule);
            this.MainTabControl.Controls.Add(this.tabPageHub);
            this.MainTabControl.Controls.Add(this.tabPageReinitialise);
            this.MainTabControl.Controls.Add(this.tabPageConnectivity);
            this.MainTabControl.Controls.Add(this.tabPageOutput);
            this.MainTabControl.Location = new System.Drawing.Point(12, 40);
            this.MainTabControl.Name = "MainTabControl";
            this.MainTabControl.SelectedIndex = 0;
            this.MainTabControl.Size = new System.Drawing.Size(1191, 428);
            this.MainTabControl.TabIndex = 3;
            // 
            // tabPageBatchModule
            // 
            this.tabPageBatchModule.BackColor = System.Drawing.Color.WhiteSmoke;
            this.tabPageBatchModule.Controls.Add(this.radioButtonCatalog);
            this.tabPageBatchModule.Controls.Add(this.groupBox1);
            this.tabPageBatchModule.Controls.Add(this.radioButtonETLGenerationMetadata);
            this.tabPageBatchModule.Controls.Add(this.checkBoxSelectAll);
            this.tabPageBatchModule.Controls.Add(this.checkedListBoxStagingTables);
            this.tabPageBatchModule.Controls.Add(this.button1);
            this.tabPageBatchModule.Controls.Add(this.panel2);
            this.tabPageBatchModule.Controls.Add(this.label4);
            this.tabPageBatchModule.Controls.Add(this.buttonGeneratePSA);
            this.tabPageBatchModule.Location = new System.Drawing.Point(4, 22);
            this.tabPageBatchModule.Name = "tabPageBatchModule";
            this.tabPageBatchModule.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageBatchModule.Size = new System.Drawing.Size(1183, 402);
            this.tabPageBatchModule.TabIndex = 9;
            this.tabPageBatchModule.Text = "Batch / Module Generation";
            // 
            // radioButtonCatalog
            // 
            this.radioButtonCatalog.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.radioButtonCatalog.AutoSize = true;
            this.radioButtonCatalog.Location = new System.Drawing.Point(357, 373);
            this.radioButtonCatalog.Name = "radioButtonCatalog";
            this.radioButtonCatalog.Size = new System.Drawing.Size(61, 17);
            this.radioButtonCatalog.TabIndex = 20;
            this.radioButtonCatalog.TabStop = true;
            this.radioButtonCatalog.Text = "Catalog";
            this.radioButtonCatalog.UseVisualStyleBackColor = true;
            // 
            // groupBox1
            // 
            this.groupBox1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.groupBox1.BackColor = System.Drawing.Color.WhiteSmoke;
            this.groupBox1.Controls.Add(this.textBoxFilterCriterion);
            this.groupBox1.Location = new System.Drawing.Point(534, 355);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(223, 44);
            this.groupBox1.TabIndex = 17;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Filter Criterion";
            // 
            // textBoxFilterCriterion
            // 
            this.textBoxFilterCriterion.Location = new System.Drawing.Point(6, 15);
            this.textBoxFilterCriterion.Name = "textBoxFilterCriterion";
            this.textBoxFilterCriterion.Size = new System.Drawing.Size(211, 20);
            this.textBoxFilterCriterion.TabIndex = 16;
            this.textBoxFilterCriterion.TextChanged += new System.EventHandler(this.textBoxFilterCriterion_TextChanged);
            // 
            // radioButtonETLGenerationMetadata
            // 
            this.radioButtonETLGenerationMetadata.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.radioButtonETLGenerationMetadata.AutoSize = true;
            this.radioButtonETLGenerationMetadata.Location = new System.Drawing.Point(357, 355);
            this.radioButtonETLGenerationMetadata.Name = "radioButtonETLGenerationMetadata";
            this.radioButtonETLGenerationMetadata.Size = new System.Drawing.Size(148, 17);
            this.radioButtonETLGenerationMetadata.TabIndex = 19;
            this.radioButtonETLGenerationMetadata.TabStop = true;
            this.radioButtonETLGenerationMetadata.Text = "ETL Generation Metadata";
            this.radioButtonETLGenerationMetadata.UseVisualStyleBackColor = true;
            this.radioButtonETLGenerationMetadata.CheckedChanged += new System.EventHandler(this.radioButtonETLGenerationMetadata_CheckedChanged);
            // 
            // checkBoxSelectAll
            // 
            this.checkBoxSelectAll.AutoSize = true;
            this.checkBoxSelectAll.Location = new System.Drawing.Point(257, 6);
            this.checkBoxSelectAll.Name = "checkBoxSelectAll";
            this.checkBoxSelectAll.Size = new System.Drawing.Size(69, 17);
            this.checkBoxSelectAll.TabIndex = 18;
            this.checkBoxSelectAll.Text = "Select all";
            this.checkBoxSelectAll.UseVisualStyleBackColor = true;
            this.checkBoxSelectAll.CheckedChanged += new System.EventHandler(this.checkBoxSelectAll_CheckedChanged);
            // 
            // checkedListBoxStagingTables
            // 
            this.checkedListBoxStagingTables.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.checkedListBoxStagingTables.BackColor = System.Drawing.SystemColors.Control;
            this.checkedListBoxStagingTables.CheckOnClick = true;
            this.checkedListBoxStagingTables.ColumnWidth = 350;
            this.checkedListBoxStagingTables.FormattingEnabled = true;
            this.checkedListBoxStagingTables.Location = new System.Drawing.Point(6, 24);
            this.checkedListBoxStagingTables.MultiColumn = true;
            this.checkedListBoxStagingTables.Name = "checkedListBoxStagingTables";
            this.checkedListBoxStagingTables.ScrollAlwaysVisible = true;
            this.checkedListBoxStagingTables.Size = new System.Drawing.Size(919, 319);
            this.checkedListBoxStagingTables.TabIndex = 0;
            // 
            // button1
            // 
            this.button1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.button1.Location = new System.Drawing.Point(6, 355);
            this.button1.Name = "button1";
            this.button1.Size = new System.Drawing.Size(158, 39);
            this.button1.TabIndex = 17;
            this.button1.Text = "Populate";
            this.button1.UseVisualStyleBackColor = true;
            this.button1.Click += new System.EventHandler(this.ButtonPopulateOmdMetadata);
            // 
            // panel2
            // 
            this.panel2.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.panel2.BackColor = System.Drawing.Color.WhiteSmoke;
            this.panel2.Controls.Add(this.groupBox3);
            this.panel2.Controls.Add(this.groupBox2);
            this.panel2.Controls.Add(this.groupBox4);
            this.panel2.Location = new System.Drawing.Point(931, 16);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(246, 380);
            this.panel2.TabIndex = 16;
            // 
            // groupBox3
            // 
            this.groupBox3.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.groupBox3.BackColor = System.Drawing.Color.WhiteSmoke;
            this.groupBox3.Controls.Add(this.checkBoxGenerateModules);
            this.groupBox3.Controls.Add(this.checkBoxGenerateDataStoreModule);
            this.groupBox3.Controls.Add(this.checkBoxGenerateBatchModule);
            this.groupBox3.Controls.Add(this.checkBoxGenerateDataStore);
            this.groupBox3.Controls.Add(this.checkBoxGenerateBatches);
            this.groupBox3.Location = new System.Drawing.Point(11, 240);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(225, 138);
            this.groupBox3.TabIndex = 19;
            this.groupBox3.TabStop = false;
            this.groupBox3.Text = "Component Selection";
            // 
            // checkBoxGenerateModules
            // 
            this.checkBoxGenerateModules.AutoSize = true;
            this.checkBoxGenerateModules.Location = new System.Drawing.Point(6, 19);
            this.checkBoxGenerateModules.Name = "checkBoxGenerateModules";
            this.checkBoxGenerateModules.Size = new System.Drawing.Size(113, 17);
            this.checkBoxGenerateModules.TabIndex = 17;
            this.checkBoxGenerateModules.Text = "Generate Modules";
            this.checkBoxGenerateModules.UseVisualStyleBackColor = true;
            // 
            // checkBoxGenerateDataStoreModule
            // 
            this.checkBoxGenerateDataStoreModule.AutoSize = true;
            this.checkBoxGenerateDataStoreModule.Location = new System.Drawing.Point(6, 111);
            this.checkBoxGenerateDataStoreModule.Name = "checkBoxGenerateDataStoreModule";
            this.checkBoxGenerateDataStoreModule.Size = new System.Drawing.Size(217, 17);
            this.checkBoxGenerateDataStoreModule.TabIndex = 15;
            this.checkBoxGenerateDataStoreModule.Text = "Generate Data Store / Module Relations";
            this.checkBoxGenerateDataStoreModule.UseVisualStyleBackColor = true;
            // 
            // checkBoxGenerateBatchModule
            // 
            this.checkBoxGenerateBatchModule.AutoSize = true;
            this.checkBoxGenerateBatchModule.Location = new System.Drawing.Point(6, 65);
            this.checkBoxGenerateBatchModule.Name = "checkBoxGenerateBatchModule";
            this.checkBoxGenerateBatchModule.Size = new System.Drawing.Size(188, 17);
            this.checkBoxGenerateBatchModule.TabIndex = 14;
            this.checkBoxGenerateBatchModule.Text = "Generate Batch/Module Relations";
            this.checkBoxGenerateBatchModule.UseVisualStyleBackColor = true;
            // 
            // checkBoxGenerateDataStore
            // 
            this.checkBoxGenerateDataStore.AutoSize = true;
            this.checkBoxGenerateDataStore.Location = new System.Drawing.Point(6, 88);
            this.checkBoxGenerateDataStore.Name = "checkBoxGenerateDataStore";
            this.checkBoxGenerateDataStore.Size = new System.Drawing.Size(129, 17);
            this.checkBoxGenerateDataStore.TabIndex = 13;
            this.checkBoxGenerateDataStore.Text = "Generate Data Stores";
            this.checkBoxGenerateDataStore.UseVisualStyleBackColor = true;
            // 
            // checkBoxGenerateBatches
            // 
            this.checkBoxGenerateBatches.AutoSize = true;
            this.checkBoxGenerateBatches.Location = new System.Drawing.Point(6, 42);
            this.checkBoxGenerateBatches.Name = "checkBoxGenerateBatches";
            this.checkBoxGenerateBatches.Size = new System.Drawing.Size(112, 17);
            this.checkBoxGenerateBatches.TabIndex = 11;
            this.checkBoxGenerateBatches.Text = "Generate Batches";
            this.checkBoxGenerateBatches.UseVisualStyleBackColor = true;
            // 
            // groupBox2
            // 
            this.groupBox2.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.groupBox2.BackColor = System.Drawing.Color.WhiteSmoke;
            this.groupBox2.Controls.Add(this.checkBoxGenerateEndDating);
            this.groupBox2.Controls.Add(this.checkBoxGenerateInt);
            this.groupBox2.Controls.Add(this.checkBoxGenerateStg);
            this.groupBox2.Controls.Add(this.checkBoxGenerateHstg);
            this.groupBox2.Location = new System.Drawing.Point(11, 111);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(225, 118);
            this.groupBox2.TabIndex = 18;
            this.groupBox2.TabStop = false;
            this.groupBox2.Text = "Area Selection";
            // 
            // checkBoxGenerateEndDating
            // 
            this.checkBoxGenerateEndDating.AutoSize = true;
            this.checkBoxGenerateEndDating.Location = new System.Drawing.Point(6, 92);
            this.checkBoxGenerateEndDating.Name = "checkBoxGenerateEndDating";
            this.checkBoxGenerateEndDating.Size = new System.Drawing.Size(82, 17);
            this.checkBoxGenerateEndDating.TabIndex = 12;
            this.checkBoxGenerateEndDating.Text = "End Dating ";
            this.checkBoxGenerateEndDating.UseVisualStyleBackColor = true;
            // 
            // checkBoxGenerateInt
            // 
            this.checkBoxGenerateInt.AutoSize = true;
            this.checkBoxGenerateInt.Location = new System.Drawing.Point(6, 69);
            this.checkBoxGenerateInt.Name = "checkBoxGenerateInt";
            this.checkBoxGenerateInt.Size = new System.Drawing.Size(105, 17);
            this.checkBoxGenerateInt.TabIndex = 10;
            this.checkBoxGenerateInt.Text = "Integration Layer";
            this.checkBoxGenerateInt.UseVisualStyleBackColor = true;
            // 
            // checkBoxGenerateStg
            // 
            this.checkBoxGenerateStg.AutoSize = true;
            this.checkBoxGenerateStg.Location = new System.Drawing.Point(6, 22);
            this.checkBoxGenerateStg.Name = "checkBoxGenerateStg";
            this.checkBoxGenerateStg.Size = new System.Drawing.Size(87, 17);
            this.checkBoxGenerateStg.TabIndex = 7;
            this.checkBoxGenerateStg.Text = "Staging Area";
            this.checkBoxGenerateStg.UseVisualStyleBackColor = true;
            // 
            // checkBoxGenerateHstg
            // 
            this.checkBoxGenerateHstg.AutoSize = true;
            this.checkBoxGenerateHstg.Location = new System.Drawing.Point(6, 45);
            this.checkBoxGenerateHstg.Name = "checkBoxGenerateHstg";
            this.checkBoxGenerateHstg.Size = new System.Drawing.Size(83, 17);
            this.checkBoxGenerateHstg.TabIndex = 9;
            this.checkBoxGenerateHstg.Text = "History Area";
            this.checkBoxGenerateHstg.UseVisualStyleBackColor = true;
            // 
            // groupBox4
            // 
            this.groupBox4.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.groupBox4.BackColor = System.Drawing.Color.WhiteSmoke;
            this.groupBox4.Controls.Add(this.checkBoxAddDelete);
            this.groupBox4.Controls.Add(this.checkBoxInitialOMD);
            this.groupBox4.Controls.Add(this.checkBoxIfExists);
            this.groupBox4.Location = new System.Drawing.Point(11, 2);
            this.groupBox4.Name = "groupBox4";
            this.groupBox4.Size = new System.Drawing.Size(223, 98);
            this.groupBox4.TabIndex = 15;
            this.groupBox4.TabStop = false;
            this.groupBox4.Text = "Generation Options";
            // 
            // checkBoxAddDelete
            // 
            this.checkBoxAddDelete.AutoSize = true;
            this.checkBoxAddDelete.Location = new System.Drawing.Point(6, 69);
            this.checkBoxAddDelete.Name = "checkBoxAddDelete";
            this.checkBoxAddDelete.Size = new System.Drawing.Size(139, 17);
            this.checkBoxAddDelete.TabIndex = 10;
            this.checkBoxAddDelete.Text = "Add DELETE statement";
            this.checkBoxAddDelete.UseVisualStyleBackColor = true;
            // 
            // checkBoxInitialOMD
            // 
            this.checkBoxInitialOMD.AutoSize = true;
            this.checkBoxInitialOMD.Location = new System.Drawing.Point(6, 22);
            this.checkBoxInitialOMD.Name = "checkBoxInitialOMD";
            this.checkBoxInitialOMD.Size = new System.Drawing.Size(149, 17);
            this.checkBoxInitialOMD.TabIndex = 7;
            this.checkBoxInitialOMD.Text = "Generate Initial OMD data";
            this.checkBoxInitialOMD.UseVisualStyleBackColor = true;
            // 
            // checkBoxIfExists
            // 
            this.checkBoxIfExists.AutoSize = true;
            this.checkBoxIfExists.Location = new System.Drawing.Point(6, 45);
            this.checkBoxIfExists.Name = "checkBoxIfExists";
            this.checkBoxIfExists.Size = new System.Drawing.Size(110, 17);
            this.checkBoxIfExists.TabIndex = 9;
            this.checkBoxIfExists.Text = "Check IF EXISTS";
            this.checkBoxIfExists.UseVisualStyleBackColor = true;
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(3, 7);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(248, 13);
            this.label4.TabIndex = 1;
            this.label4.Text = "The following metadata is available in the database";
            // 
            // buttonGeneratePSA
            // 
            this.buttonGeneratePSA.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.buttonGeneratePSA.Location = new System.Drawing.Point(170, 355);
            this.buttonGeneratePSA.Name = "buttonGeneratePSA";
            this.buttonGeneratePSA.Size = new System.Drawing.Size(158, 39);
            this.buttonGeneratePSA.TabIndex = 3;
            this.buttonGeneratePSA.Text = "Generate";
            this.buttonGeneratePSA.UseVisualStyleBackColor = true;
            this.buttonGeneratePSA.Click += new System.EventHandler(this.ButtonGenerateOmdMetadata);
            // 
            // tabPageHub
            // 
            this.tabPageHub.BackColor = System.Drawing.Color.WhiteSmoke;
            this.tabPageHub.Location = new System.Drawing.Point(4, 22);
            this.tabPageHub.Name = "tabPageHub";
            this.tabPageHub.Size = new System.Drawing.Size(1183, 402);
            this.tabPageHub.TabIndex = 11;
            this.tabPageHub.Text = "Hub Record Generation";
            // 
            // tabPageReinitialise
            // 
            this.tabPageReinitialise.BackColor = System.Drawing.Color.WhiteSmoke;
            this.tabPageReinitialise.Location = new System.Drawing.Point(4, 22);
            this.tabPageReinitialise.Name = "tabPageReinitialise";
            this.tabPageReinitialise.Size = new System.Drawing.Size(1183, 402);
            this.tabPageReinitialise.TabIndex = 12;
            this.tabPageReinitialise.Text = "STG Reinitialisation";
            // 
            // tabPageConnectivity
            // 
            this.tabPageConnectivity.BackColor = System.Drawing.Color.WhiteSmoke;
            this.tabPageConnectivity.Controls.Add(this.labelOMDdatabase);
            this.tabPageConnectivity.Controls.Add(this.textBoxOmdDatabase);
            this.tabPageConnectivity.Controls.Add(this.label5);
            this.tabPageConnectivity.Controls.Add(this.textBoxOmdConnection);
            this.tabPageConnectivity.Controls.Add(this.label2);
            this.tabPageConnectivity.Controls.Add(this.textBoxMetaDataDatabaseName);
            this.tabPageConnectivity.Controls.Add(this.groupBox5);
            this.tabPageConnectivity.Controls.Add(this.label1);
            this.tabPageConnectivity.Controls.Add(this.MetadataConnectionLabel);
            this.tabPageConnectivity.Controls.Add(this.textBoxMetadataConnection);
            this.tabPageConnectivity.Controls.Add(this.textBoxOutputPath);
            this.tabPageConnectivity.Location = new System.Drawing.Point(4, 22);
            this.tabPageConnectivity.Name = "tabPageConnectivity";
            this.tabPageConnectivity.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageConnectivity.Size = new System.Drawing.Size(1183, 402);
            this.tabPageConnectivity.TabIndex = 3;
            this.tabPageConnectivity.Text = "Settings";
            // 
            // labelOMDdatabase
            // 
            this.labelOMDdatabase.AutoSize = true;
            this.labelOMDdatabase.Location = new System.Drawing.Point(4, 205);
            this.labelOMDdatabase.Name = "labelOMDdatabase";
            this.labelOMDdatabase.Size = new System.Drawing.Size(108, 13);
            this.labelOMDdatabase.TabIndex = 28;
            this.labelOMDdatabase.Text = "OMD database name";
            // 
            // textBoxOmdDatabase
            // 
            this.textBoxOmdDatabase.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxOmdDatabase.Location = new System.Drawing.Point(6, 221);
            this.textBoxOmdDatabase.Multiline = true;
            this.textBoxOmdDatabase.Name = "textBoxOmdDatabase";
            this.textBoxOmdDatabase.Size = new System.Drawing.Size(629, 20);
            this.textBoxOmdDatabase.TabIndex = 27;
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(4, 166);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(135, 13);
            this.label5.TabIndex = 26;
            this.label5.Text = "OMD database connection";
            // 
            // textBoxOmdConnection
            // 
            this.textBoxOmdConnection.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxOmdConnection.Location = new System.Drawing.Point(6, 182);
            this.textBoxOmdConnection.Multiline = true;
            this.textBoxOmdConnection.Name = "textBoxOmdConnection";
            this.textBoxOmdConnection.Size = new System.Drawing.Size(629, 20);
            this.textBoxOmdConnection.TabIndex = 25;
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(3, 108);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(128, 13);
            this.label2.TabIndex = 24;
            this.label2.Text = "Metadata database name";
            // 
            // textBoxMetaDataDatabaseName
            // 
            this.textBoxMetaDataDatabaseName.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxMetaDataDatabaseName.Location = new System.Drawing.Point(5, 124);
            this.textBoxMetaDataDatabaseName.Multiline = true;
            this.textBoxMetaDataDatabaseName.Name = "textBoxMetaDataDatabaseName";
            this.textBoxMetaDataDatabaseName.Size = new System.Drawing.Size(629, 20);
            this.textBoxMetaDataDatabaseName.TabIndex = 23;
            // 
            // groupBox5
            // 
            this.groupBox5.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.groupBox5.BackColor = System.Drawing.Color.WhiteSmoke;
            this.groupBox5.Controls.Add(this.checkBoxOMDVerboseDebugging);
            this.groupBox5.Location = new System.Drawing.Point(6, 300);
            this.groupBox5.Name = "groupBox5";
            this.groupBox5.Size = new System.Drawing.Size(163, 99);
            this.groupBox5.TabIndex = 22;
            this.groupBox5.TabStop = false;
            this.groupBox5.Text = "Processing Options";
            // 
            // checkBoxOMDVerboseDebugging
            // 
            this.checkBoxOMDVerboseDebugging.AutoSize = true;
            this.checkBoxOMDVerboseDebugging.Checked = true;
            this.checkBoxOMDVerboseDebugging.CheckState = System.Windows.Forms.CheckState.Checked;
            this.checkBoxOMDVerboseDebugging.Location = new System.Drawing.Point(6, 22);
            this.checkBoxOMDVerboseDebugging.Name = "checkBoxOMDVerboseDebugging";
            this.checkBoxOMDVerboseDebugging.Size = new System.Drawing.Size(120, 17);
            this.checkBoxOMDVerboseDebugging.TabIndex = 7;
            this.checkBoxOMDVerboseDebugging.Text = "Verbose Debugging";
            this.checkBoxOMDVerboseDebugging.UseVisualStyleBackColor = true;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(6, 16);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(63, 13);
            this.label1.TabIndex = 21;
            this.label1.Text = "Output path";
            // 
            // MetadataConnectionLabel
            // 
            this.MetadataConnectionLabel.AutoSize = true;
            this.MetadataConnectionLabel.Location = new System.Drawing.Point(3, 69);
            this.MetadataConnectionLabel.Name = "MetadataConnectionLabel";
            this.MetadataConnectionLabel.Size = new System.Drawing.Size(155, 13);
            this.MetadataConnectionLabel.TabIndex = 20;
            this.MetadataConnectionLabel.Text = "Metadata database connection";
            // 
            // textBoxMetadataConnection
            // 
            this.textBoxMetadataConnection.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxMetadataConnection.Location = new System.Drawing.Point(5, 85);
            this.textBoxMetadataConnection.Multiline = true;
            this.textBoxMetadataConnection.Name = "textBoxMetadataConnection";
            this.textBoxMetadataConnection.Size = new System.Drawing.Size(629, 20);
            this.textBoxMetadataConnection.TabIndex = 19;
            // 
            // textBoxOutputPath
            // 
            this.textBoxOutputPath.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxOutputPath.Location = new System.Drawing.Point(6, 32);
            this.textBoxOutputPath.Multiline = true;
            this.textBoxOutputPath.Name = "textBoxOutputPath";
            this.textBoxOutputPath.Size = new System.Drawing.Size(629, 20);
            this.textBoxOutputPath.TabIndex = 18;
            // 
            // tabPageOutput
            // 
            this.tabPageOutput.Controls.Add(this.DebuggingTextbox);
            this.tabPageOutput.Location = new System.Drawing.Point(4, 22);
            this.tabPageOutput.Name = "tabPageOutput";
            this.tabPageOutput.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageOutput.Size = new System.Drawing.Size(1183, 402);
            this.tabPageOutput.TabIndex = 10;
            this.tabPageOutput.Text = "Output / Debugging";
            this.tabPageOutput.UseVisualStyleBackColor = true;
            // 
            // menuStrip1
            // 
            this.menuStrip1.Location = new System.Drawing.Point(0, 0);
            this.menuStrip1.Name = "menuStrip1";
            this.menuStrip1.Size = new System.Drawing.Size(1217, 24);
            this.menuStrip1.TabIndex = 4;
            this.menuStrip1.Text = "menuStrip1";
            // 
            // fileToolStripMenuItem
            // 
            this.fileToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.openConfigurationFileToolStripMenuItem,
            this.toolStripMenuItem2,
            this.openOutputDirectoryToolStripMenuItem,
            this.exitToolStripMenuItem});
            this.fileToolStripMenuItem.Name = "fileToolStripMenuItem";
            this.fileToolStripMenuItem.Size = new System.Drawing.Size(37, 20);
            this.fileToolStripMenuItem.Text = "File";
            // 
            // openConfigurationFileToolStripMenuItem
            // 
            this.openConfigurationFileToolStripMenuItem.Name = "openConfigurationFileToolStripMenuItem";
            this.openConfigurationFileToolStripMenuItem.Size = new System.Drawing.Size(201, 22);
            this.openConfigurationFileToolStripMenuItem.Text = "Open Configuration File";
            this.openConfigurationFileToolStripMenuItem.Click += new System.EventHandler(this.openConfigurationFileToolStripMenuItem_Click);
            // 
            // toolStripMenuItem2
            // 
            this.toolStripMenuItem2.Name = "toolStripMenuItem2";
            this.toolStripMenuItem2.Size = new System.Drawing.Size(201, 22);
            this.toolStripMenuItem2.Text = "Save Configuration File";
            this.toolStripMenuItem2.Click += new System.EventHandler(this.saveConfigurationFileToolStripMenuItem_Click);
            // 
            // openOutputDirectoryToolStripMenuItem
            // 
            this.openOutputDirectoryToolStripMenuItem.Name = "openOutputDirectoryToolStripMenuItem";
            this.openOutputDirectoryToolStripMenuItem.Size = new System.Drawing.Size(201, 22);
            this.openOutputDirectoryToolStripMenuItem.Text = "Open Output Directory";
            this.openOutputDirectoryToolStripMenuItem.Click += new System.EventHandler(this.openOutputDirectoryToolStripMenuItem_Click);
            // 
            // exitToolStripMenuItem
            // 
            this.exitToolStripMenuItem.Name = "exitToolStripMenuItem";
            this.exitToolStripMenuItem.Size = new System.Drawing.Size(201, 22);
            this.exitToolStripMenuItem.Text = "Exit";
            this.exitToolStripMenuItem.Click += new System.EventHandler(this.exitToolStripMenuItem_Click);
            // 
            // helpToolStripMenuItem
            // 
            this.helpToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.helpToolStripMenuItem1,
            this.toolStripSeparator1,
            this.aboutToolStripMenuItem});
            this.helpToolStripMenuItem.Name = "helpToolStripMenuItem";
            this.helpToolStripMenuItem.Size = new System.Drawing.Size(44, 20);
            this.helpToolStripMenuItem.Text = "Help";
            // 
            // helpToolStripMenuItem1
            // 
            this.helpToolStripMenuItem1.Name = "helpToolStripMenuItem1";
            this.helpToolStripMenuItem1.Size = new System.Drawing.Size(107, 22);
            this.helpToolStripMenuItem1.Text = "Help";
            this.helpToolStripMenuItem1.Click += new System.EventHandler(this.helpToolStripMenuItem1_Click);
            // 
            // toolStripSeparator1
            // 
            this.toolStripSeparator1.Name = "toolStripSeparator1";
            this.toolStripSeparator1.Size = new System.Drawing.Size(104, 6);
            // 
            // aboutToolStripMenuItem
            // 
            this.aboutToolStripMenuItem.Name = "aboutToolStripMenuItem";
            this.aboutToolStripMenuItem.Size = new System.Drawing.Size(107, 22);
            this.aboutToolStripMenuItem.Text = "About";
            this.aboutToolStripMenuItem.ToolTipText = "Information about OMD Manager";
            this.aboutToolStripMenuItem.Click += new System.EventHandler(this.aboutToolStripMenuItem_Click);
            // 
            // richTextBoxOutput
            // 
            this.richTextBoxOutput.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.richTextBoxOutput.Location = new System.Drawing.Point(12, 493);
            this.richTextBoxOutput.Name = "richTextBoxOutput";
            this.richTextBoxOutput.Size = new System.Drawing.Size(989, 110);
            this.richTextBoxOutput.TabIndex = 16;
            this.richTextBoxOutput.Text = "";
            // 
            // label6
            // 
            this.label6.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(12, 478);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(59, 13);
            this.label6.TabIndex = 17;
            this.label6.Text = "Information";
            // 
            // pictureBox1
            // 
            this.pictureBox1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.pictureBox1.Image = global::OMD_Manager.Properties.Resources.RavosLogo;
            this.pictureBox1.Location = new System.Drawing.Point(1089, 493);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(111, 110);
            this.pictureBox1.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.pictureBox1.TabIndex = 15;
            this.pictureBox1.TabStop = false;
            // 
            // FormMain
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.SystemColors.Control;
            this.ClientSize = new System.Drawing.Size(1217, 618);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.richTextBoxOutput);
            this.Controls.Add(this.pictureBox1);
            this.Controls.Add(this.MainTabControl);
            this.Controls.Add(this.menuStrip1);
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.MainMenuStrip = this.menuStrip1;
            this.MinimumSize = new System.Drawing.Size(1233, 656);
            this.Name = "FormMain";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "DIRECT Framework Manager";
            this.Load += new System.EventHandler(this.FormMain_Load);
            this.MainTabControl.ResumeLayout(false);
            this.tabPageBatchModule.ResumeLayout(false);
            this.tabPageBatchModule.PerformLayout();
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.panel2.ResumeLayout(false);
            this.groupBox3.ResumeLayout(false);
            this.groupBox3.PerformLayout();
            this.groupBox2.ResumeLayout(false);
            this.groupBox2.PerformLayout();
            this.groupBox4.ResumeLayout(false);
            this.groupBox4.PerformLayout();
            this.tabPageConnectivity.ResumeLayout(false);
            this.tabPageConnectivity.PerformLayout();
            this.groupBox5.ResumeLayout(false);
            this.groupBox5.PerformLayout();
            this.tabPageOutput.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.RichTextBox DebuggingTextbox;
        private System.Windows.Forms.TabControl MainTabControl;
        private System.Windows.Forms.MenuStrip menuStrip1;
        private System.Windows.Forms.ToolStripMenuItem fileToolStripMenuItem;
        private System.Windows.Forms.TabPage tabPageConnectivity;
        private System.Windows.Forms.ToolStripMenuItem openConfigurationFileToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem openOutputDirectoryToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem exitToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem helpToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem helpToolStripMenuItem1;
        private System.Windows.Forms.ToolStripMenuItem aboutToolStripMenuItem;
        private System.Windows.Forms.ToolStripSeparator toolStripSeparator1;
        private System.Windows.Forms.ToolStripMenuItem toolStripMenuItem2;
        private System.Windows.Forms.TabPage tabPageOutput;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.TabPage tabPageHub;
        private System.Windows.Forms.TabPage tabPageReinitialise;
        private System.Windows.Forms.RichTextBox richTextBoxOutput;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.TabPage tabPageBatchModule;
        private System.Windows.Forms.Panel panel2;
        private System.Windows.Forms.GroupBox groupBox4;
        private System.Windows.Forms.CheckBox checkBoxAddDelete;
        private System.Windows.Forms.CheckBox checkBoxInitialOMD;
        private System.Windows.Forms.CheckBox checkBoxIfExists;
        private System.Windows.Forms.Button buttonGeneratePSA;
        private System.Windows.Forms.Button button1;
        private System.Windows.Forms.GroupBox groupBox5;
        private System.Windows.Forms.CheckBox checkBoxOMDVerboseDebugging;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label MetadataConnectionLabel;
        internal System.Windows.Forms.TextBox textBoxMetadataConnection;
        internal System.Windows.Forms.TextBox textBoxOutputPath;
        private System.Windows.Forms.Label label2;
        internal System.Windows.Forms.TextBox textBoxMetaDataDatabaseName;
        private System.Windows.Forms.CheckedListBox checkedListBoxStagingTables;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.TextBox textBoxFilterCriterion;
        private System.Windows.Forms.GroupBox groupBox2;
        private System.Windows.Forms.CheckBox checkBoxGenerateInt;
        private System.Windows.Forms.CheckBox checkBoxGenerateStg;
        private System.Windows.Forms.CheckBox checkBoxGenerateHstg;
        private System.Windows.Forms.CheckBox checkBoxGenerateEndDating;
        private System.Windows.Forms.CheckBox checkBoxSelectAll;
        private System.Windows.Forms.RadioButton radioButtonCatalog;
        private System.Windows.Forms.RadioButton radioButtonETLGenerationMetadata;
        private System.Windows.Forms.GroupBox groupBox3;
        private System.Windows.Forms.CheckBox checkBoxGenerateModules;
        private System.Windows.Forms.CheckBox checkBoxGenerateDataStoreModule;
        private System.Windows.Forms.CheckBox checkBoxGenerateBatchModule;
        private System.Windows.Forms.CheckBox checkBoxGenerateDataStore;
        private System.Windows.Forms.CheckBox checkBoxGenerateBatches;
        private System.Windows.Forms.Label labelOMDdatabase;
        internal System.Windows.Forms.TextBox textBoxOmdDatabase;
        private System.Windows.Forms.Label label5;
        internal System.Windows.Forms.TextBox textBoxOmdConnection;
        private System.Windows.Forms.PictureBox pictureBox1;
    }
}

