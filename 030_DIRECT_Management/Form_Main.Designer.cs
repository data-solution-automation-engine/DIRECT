using System.Security.AccessControl;

namespace DIRECT_Manager
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
            this.checkBoxSelectAllMain = new System.Windows.Forms.CheckBox();
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
            this.dateTimePickerReinitialisation = new System.Windows.Forms.DateTimePicker();
            this.button3 = new System.Windows.Forms.Button();
            this.checkBoxExecuteReinitialisation = new System.Windows.Forms.CheckBox();
            this.richTextBox1 = new System.Windows.Forms.RichTextBox();
            this.button2 = new System.Windows.Forms.Button();
            this.checkBoxSelectAllReinistialisation = new System.Windows.Forms.CheckBox();
            this.label8 = new System.Windows.Forms.Label();
            this.groupBox11 = new System.Windows.Forms.GroupBox();
            this.textBoxReinitialisationFilterCriterion = new System.Windows.Forms.TextBox();
            this.groupBox10 = new System.Windows.Forms.GroupBox();
            this.radioButtonSTG = new System.Windows.Forms.RadioButton();
            this.radioButtonPSA = new System.Windows.Forms.RadioButton();
            this.checkedListboxReinistalisation = new System.Windows.Forms.CheckedListBox();
            this.tabPageConnectivity = new System.Windows.Forms.TabPage();
            this.groupBox12 = new System.Windows.Forms.GroupBox();
            this.label12 = new System.Windows.Forms.Label();
            this.textBoxDataVaultPrefix = new System.Windows.Forms.TextBox();
            this.label9 = new System.Windows.Forms.Label();
            this.textBoxPrefix = new System.Windows.Forms.TextBox();
            this.groupBox9 = new System.Windows.Forms.GroupBox();
            this.label2 = new System.Windows.Forms.Label();
            this.textBoxGenerationMetadataConnection = new System.Windows.Forms.TextBox();
            this.MetadataConnectionLabel = new System.Windows.Forms.Label();
            this.textBoxGenerationMetadataDatabaseName = new System.Windows.Forms.TextBox();
            this.groupBox8 = new System.Windows.Forms.GroupBox();
            this.labelOMDdatabase = new System.Windows.Forms.Label();
            this.textBoxDirectConnection = new System.Windows.Forms.TextBox();
            this.label5 = new System.Windows.Forms.Label();
            this.textBoxDirectDatabase = new System.Windows.Forms.TextBox();
            this.groupBox7 = new System.Windows.Forms.GroupBox();
            this.label10 = new System.Windows.Forms.Label();
            this.textBoxPSAConnection = new System.Windows.Forms.TextBox();
            this.label11 = new System.Windows.Forms.Label();
            this.textBoxPSADatabase = new System.Windows.Forms.TextBox();
            this.groupBox6 = new System.Windows.Forms.GroupBox();
            this.label3 = new System.Windows.Forms.Label();
            this.textBoxSTGConnection = new System.Windows.Forms.TextBox();
            this.label7 = new System.Windows.Forms.Label();
            this.textBoxSTGDatabase = new System.Windows.Forms.TextBox();
            this.groupBox5 = new System.Windows.Forms.GroupBox();
            this.checkBoxOMDVerboseDebugging = new System.Windows.Forms.CheckBox();
            this.label1 = new System.Windows.Forms.Label();
            this.textBoxOutputPath = new System.Windows.Forms.TextBox();
            this.tabPageOutput = new System.Windows.Forms.TabPage();
            this.menuStrip1 = new System.Windows.Forms.MenuStrip();
            this.fileToolStripMenuItem1 = new System.Windows.Forms.ToolStripMenuItem();
            this.openConfigurationFileToolStripMenuItem1 = new System.Windows.Forms.ToolStripMenuItem();
            this.saveConfigurationFileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.openOutputDirectoryToolStripMenuItem1 = new System.Windows.Forms.ToolStripMenuItem();
            this.openConfigurationDirectoryToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.exitToolStripMenuItem1 = new System.Windows.Forms.ToolStripMenuItem();
            this.helpToolStripMenuItem2 = new System.Windows.Forms.ToolStripMenuItem();
            this.linksToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripSeparator2 = new System.Windows.Forms.ToolStripSeparator();
            this.aboutToolStripMenuItem1 = new System.Windows.Forms.ToolStripMenuItem();
            this.fileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.openConfigurationFileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem2 = new System.Windows.Forms.ToolStripMenuItem();
            this.openOutputDirectoryToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.exitToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.helpToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.helpToolStripMenuItem1 = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripSeparator1 = new System.Windows.Forms.ToolStripSeparator();
            this.aboutToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.richTextBoxInformation = new System.Windows.Forms.RichTextBox();
            this.label6 = new System.Windows.Forms.Label();
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.MainTabControl.SuspendLayout();
            this.tabPageBatchModule.SuspendLayout();
            this.groupBox1.SuspendLayout();
            this.panel2.SuspendLayout();
            this.groupBox3.SuspendLayout();
            this.groupBox2.SuspendLayout();
            this.groupBox4.SuspendLayout();
            this.tabPageReinitialise.SuspendLayout();
            this.groupBox11.SuspendLayout();
            this.groupBox10.SuspendLayout();
            this.tabPageConnectivity.SuspendLayout();
            this.groupBox12.SuspendLayout();
            this.groupBox9.SuspendLayout();
            this.groupBox8.SuspendLayout();
            this.groupBox7.SuspendLayout();
            this.groupBox6.SuspendLayout();
            this.groupBox5.SuspendLayout();
            this.tabPageOutput.SuspendLayout();
            this.menuStrip1.SuspendLayout();
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
            this.DebuggingTextbox.Size = new System.Drawing.Size(1354, 518);
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
            this.MainTabControl.Size = new System.Drawing.Size(1374, 556);
            this.MainTabControl.TabIndex = 3;
            // 
            // tabPageBatchModule
            // 
            this.tabPageBatchModule.BackColor = System.Drawing.Color.WhiteSmoke;
            this.tabPageBatchModule.Controls.Add(this.radioButtonCatalog);
            this.tabPageBatchModule.Controls.Add(this.groupBox1);
            this.tabPageBatchModule.Controls.Add(this.radioButtonETLGenerationMetadata);
            this.tabPageBatchModule.Controls.Add(this.checkBoxSelectAllMain);
            this.tabPageBatchModule.Controls.Add(this.checkedListBoxStagingTables);
            this.tabPageBatchModule.Controls.Add(this.button1);
            this.tabPageBatchModule.Controls.Add(this.panel2);
            this.tabPageBatchModule.Controls.Add(this.label4);
            this.tabPageBatchModule.Controls.Add(this.buttonGeneratePSA);
            this.tabPageBatchModule.Location = new System.Drawing.Point(4, 22);
            this.tabPageBatchModule.Name = "tabPageBatchModule";
            this.tabPageBatchModule.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageBatchModule.Size = new System.Drawing.Size(1366, 530);
            this.tabPageBatchModule.TabIndex = 9;
            this.tabPageBatchModule.Text = "Batch / Module Generation";
            // 
            // radioButtonCatalog
            // 
            this.radioButtonCatalog.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.radioButtonCatalog.AutoSize = true;
            this.radioButtonCatalog.Location = new System.Drawing.Point(357, 501);
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
            this.groupBox1.Location = new System.Drawing.Point(534, 483);
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
            this.radioButtonETLGenerationMetadata.Location = new System.Drawing.Point(357, 483);
            this.radioButtonETLGenerationMetadata.Name = "radioButtonETLGenerationMetadata";
            this.radioButtonETLGenerationMetadata.Size = new System.Drawing.Size(148, 17);
            this.radioButtonETLGenerationMetadata.TabIndex = 19;
            this.radioButtonETLGenerationMetadata.TabStop = true;
            this.radioButtonETLGenerationMetadata.Text = "ETL Generation Metadata";
            this.radioButtonETLGenerationMetadata.UseVisualStyleBackColor = true;
            this.radioButtonETLGenerationMetadata.CheckedChanged += new System.EventHandler(this.radioButtonETLGenerationMetadata_CheckedChanged);
            // 
            // checkBoxSelectAllMain
            // 
            this.checkBoxSelectAllMain.AutoSize = true;
            this.checkBoxSelectAllMain.Location = new System.Drawing.Point(257, 6);
            this.checkBoxSelectAllMain.Name = "checkBoxSelectAllMain";
            this.checkBoxSelectAllMain.Size = new System.Drawing.Size(69, 17);
            this.checkBoxSelectAllMain.TabIndex = 18;
            this.checkBoxSelectAllMain.Text = "Select all";
            this.checkBoxSelectAllMain.UseVisualStyleBackColor = true;
            this.checkBoxSelectAllMain.CheckedChanged += new System.EventHandler(this.checkBoxSelectAll_CheckedChanged);
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
            this.checkedListBoxStagingTables.Size = new System.Drawing.Size(1110, 439);
            this.checkedListBoxStagingTables.TabIndex = 0;
            // 
            // button1
            // 
            this.button1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.button1.Location = new System.Drawing.Point(6, 483);
            this.button1.Name = "button1";
            this.button1.Size = new System.Drawing.Size(158, 39);
            this.button1.TabIndex = 17;
            this.button1.Text = "Refresh Selection";
            this.button1.UseVisualStyleBackColor = true;
            // 
            // panel2
            // 
            this.panel2.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.panel2.BackColor = System.Drawing.Color.WhiteSmoke;
            this.panel2.Controls.Add(this.groupBox3);
            this.panel2.Controls.Add(this.groupBox2);
            this.panel2.Controls.Add(this.groupBox4);
            this.panel2.Location = new System.Drawing.Point(1116, 16);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(246, 508);
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
            this.groupBox3.Size = new System.Drawing.Size(225, 266);
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
            this.groupBox2.Size = new System.Drawing.Size(225, 246);
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
            this.buttonGeneratePSA.Location = new System.Drawing.Point(170, 483);
            this.buttonGeneratePSA.Name = "buttonGeneratePSA";
            this.buttonGeneratePSA.Size = new System.Drawing.Size(158, 39);
            this.buttonGeneratePSA.TabIndex = 3;
            this.buttonGeneratePSA.Text = "Generate";
            this.buttonGeneratePSA.UseVisualStyleBackColor = true;
            // 
            // tabPageHub
            // 
            this.tabPageHub.BackColor = System.Drawing.Color.WhiteSmoke;
            this.tabPageHub.Location = new System.Drawing.Point(4, 22);
            this.tabPageHub.Name = "tabPageHub";
            this.tabPageHub.Size = new System.Drawing.Size(1366, 530);
            this.tabPageHub.TabIndex = 11;
            this.tabPageHub.Text = "Hub Zero Record Generation";
            // 
            // tabPageReinitialise
            // 
            this.tabPageReinitialise.BackColor = System.Drawing.Color.WhiteSmoke;
            this.tabPageReinitialise.Controls.Add(this.dateTimePickerReinitialisation);
            this.tabPageReinitialise.Controls.Add(this.button3);
            this.tabPageReinitialise.Controls.Add(this.checkBoxExecuteReinitialisation);
            this.tabPageReinitialise.Controls.Add(this.richTextBox1);
            this.tabPageReinitialise.Controls.Add(this.button2);
            this.tabPageReinitialise.Controls.Add(this.checkBoxSelectAllReinistialisation);
            this.tabPageReinitialise.Controls.Add(this.label8);
            this.tabPageReinitialise.Controls.Add(this.groupBox11);
            this.tabPageReinitialise.Controls.Add(this.groupBox10);
            this.tabPageReinitialise.Controls.Add(this.checkedListboxReinistalisation);
            this.tabPageReinitialise.Location = new System.Drawing.Point(4, 22);
            this.tabPageReinitialise.Name = "tabPageReinitialise";
            this.tabPageReinitialise.Size = new System.Drawing.Size(1366, 530);
            this.tabPageReinitialise.TabIndex = 12;
            this.tabPageReinitialise.Text = "Staging Layer Reinitialisation";
            // 
            // dateTimePickerReinitialisation
            // 
            this.dateTimePickerReinitialisation.Location = new System.Drawing.Point(1144, 189);
            this.dateTimePickerReinitialisation.MinDate = new System.DateTime(1900, 1, 1, 0, 0, 0, 0);
            this.dateTimePickerReinitialisation.Name = "dateTimePickerReinitialisation";
            this.dateTimePickerReinitialisation.Size = new System.Drawing.Size(200, 20);
            this.dateTimePickerReinitialisation.TabIndex = 31;
            this.dateTimePickerReinitialisation.Value = new System.DateTime(1900, 1, 1, 0, 0, 0, 0);
            // 
            // button3
            // 
            this.button3.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.button3.Location = new System.Drawing.Point(235, 478);
            this.button3.Name = "button3";
            this.button3.Size = new System.Drawing.Size(158, 39);
            this.button3.TabIndex = 30;
            this.button3.Text = "Refresh Selection";
            this.button3.UseVisualStyleBackColor = true;
            this.button3.Click += new System.EventHandler(this.button3_Click);
            // 
            // checkBoxExecuteReinitialisation
            // 
            this.checkBoxExecuteReinitialisation.AutoSize = true;
            this.checkBoxExecuteReinitialisation.Checked = true;
            this.checkBoxExecuteReinitialisation.CheckState = System.Windows.Forms.CheckState.Checked;
            this.checkBoxExecuteReinitialisation.Location = new System.Drawing.Point(1144, 166);
            this.checkBoxExecuteReinitialisation.Name = "checkBoxExecuteReinitialisation";
            this.checkBoxExecuteReinitialisation.Size = new System.Drawing.Size(180, 17);
            this.checkBoxExecuteReinitialisation.TabIndex = 29;
            this.checkBoxExecuteReinitialisation.Text = "Execute in database immediately";
            this.checkBoxExecuteReinitialisation.UseVisualStyleBackColor = true;
            // 
            // richTextBox1
            // 
            this.richTextBox1.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.richTextBox1.Location = new System.Drawing.Point(1142, 231);
            this.richTextBox1.Name = "richTextBox1";
            this.richTextBox1.ReadOnly = true;
            this.richTextBox1.Size = new System.Drawing.Size(200, 82);
            this.richTextBox1.TabIndex = 28;
            this.richTextBox1.Text = "Re-initialisation will truncate the Staging Area table en reload this from the PS" +
    "A counterpart. \n\nOr, in the case of using PSA as a source, it will reset the loa" +
    "ding window.";
            // 
            // button2
            // 
            this.button2.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.button2.Location = new System.Drawing.Point(1142, 119);
            this.button2.Name = "button2";
            this.button2.Size = new System.Drawing.Size(200, 39);
            this.button2.TabIndex = 27;
            this.button2.Text = "Excecute Re-initialisation";
            this.button2.UseVisualStyleBackColor = true;
            this.button2.Click += new System.EventHandler(this.button2_Click);
            // 
            // checkBoxSelectAllReinistialisation
            // 
            this.checkBoxSelectAllReinistialisation.AutoSize = true;
            this.checkBoxSelectAllReinistialisation.Location = new System.Drawing.Point(257, 6);
            this.checkBoxSelectAllReinistialisation.Name = "checkBoxSelectAllReinistialisation";
            this.checkBoxSelectAllReinistialisation.Size = new System.Drawing.Size(69, 17);
            this.checkBoxSelectAllReinistialisation.TabIndex = 26;
            this.checkBoxSelectAllReinistialisation.Text = "Select all";
            this.checkBoxSelectAllReinistialisation.UseVisualStyleBackColor = true;
            this.checkBoxSelectAllReinistialisation.CheckedChanged += new System.EventHandler(this.checkBoxSelectAllReinistialisation_CheckedChanged);
            // 
            // label8
            // 
            this.label8.AutoSize = true;
            this.label8.Location = new System.Drawing.Point(3, 7);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(248, 13);
            this.label8.TabIndex = 25;
            this.label8.Text = "The following metadata is available in the database";
            // 
            // groupBox11
            // 
            this.groupBox11.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.groupBox11.BackColor = System.Drawing.Color.WhiteSmoke;
            this.groupBox11.Controls.Add(this.textBoxReinitialisationFilterCriterion);
            this.groupBox11.Location = new System.Drawing.Point(6, 473);
            this.groupBox11.Name = "groupBox11";
            this.groupBox11.Size = new System.Drawing.Size(223, 44);
            this.groupBox11.TabIndex = 24;
            this.groupBox11.TabStop = false;
            this.groupBox11.Text = "Filter Criterion";
            // 
            // textBoxReinitialisationFilterCriterion
            // 
            this.textBoxReinitialisationFilterCriterion.Location = new System.Drawing.Point(6, 15);
            this.textBoxReinitialisationFilterCriterion.Name = "textBoxReinitialisationFilterCriterion";
            this.textBoxReinitialisationFilterCriterion.Size = new System.Drawing.Size(211, 20);
            this.textBoxReinitialisationFilterCriterion.TabIndex = 16;
            this.textBoxReinitialisationFilterCriterion.TextChanged += new System.EventHandler(this.textBoxReinitialisationFilterCriterion_TextChanged);
            // 
            // groupBox10
            // 
            this.groupBox10.Controls.Add(this.radioButtonSTG);
            this.groupBox10.Controls.Add(this.radioButtonPSA);
            this.groupBox10.Location = new System.Drawing.Point(1142, 24);
            this.groupBox10.Name = "groupBox10";
            this.groupBox10.Size = new System.Drawing.Size(200, 74);
            this.groupBox10.TabIndex = 23;
            this.groupBox10.TabStop = false;
            this.groupBox10.Text = "Area Selection";
            // 
            // radioButtonSTG
            // 
            this.radioButtonSTG.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.radioButtonSTG.AutoSize = true;
            this.radioButtonSTG.Checked = true;
            this.radioButtonSTG.Location = new System.Drawing.Point(11, 22);
            this.radioButtonSTG.Name = "radioButtonSTG";
            this.radioButtonSTG.Size = new System.Drawing.Size(86, 17);
            this.radioButtonSTG.TabIndex = 23;
            this.radioButtonSTG.TabStop = true;
            this.radioButtonSTG.Text = "Staging Area";
            this.radioButtonSTG.UseVisualStyleBackColor = true;
            this.radioButtonSTG.CheckedChanged += new System.EventHandler(this.radioButtonSTG_CheckedChanged);
            // 
            // radioButtonPSA
            // 
            this.radioButtonPSA.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.radioButtonPSA.AutoSize = true;
            this.radioButtonPSA.Location = new System.Drawing.Point(11, 40);
            this.radioButtonPSA.Name = "radioButtonPSA";
            this.radioButtonPSA.Size = new System.Drawing.Size(135, 17);
            this.radioButtonPSA.TabIndex = 24;
            this.radioButtonPSA.Text = "Persistent Staging Area";
            this.radioButtonPSA.UseVisualStyleBackColor = true;
            // 
            // checkedListboxReinistalisation
            // 
            this.checkedListboxReinistalisation.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.checkedListboxReinistalisation.BackColor = System.Drawing.SystemColors.Control;
            this.checkedListboxReinistalisation.CheckOnClick = true;
            this.checkedListboxReinistalisation.ColumnWidth = 475;
            this.checkedListboxReinistalisation.FormattingEnabled = true;
            this.checkedListboxReinistalisation.Location = new System.Drawing.Point(6, 24);
            this.checkedListboxReinistalisation.MultiColumn = true;
            this.checkedListboxReinistalisation.Name = "checkedListboxReinistalisation";
            this.checkedListboxReinistalisation.ScrollAlwaysVisible = true;
            this.checkedListboxReinistalisation.Size = new System.Drawing.Size(1110, 439);
            this.checkedListboxReinistalisation.TabIndex = 1;
            this.checkedListboxReinistalisation.SelectedIndexChanged += new System.EventHandler(this.checkedListBox1_SelectedIndexChanged);
            // 
            // tabPageConnectivity
            // 
            this.tabPageConnectivity.BackColor = System.Drawing.Color.WhiteSmoke;
            this.tabPageConnectivity.Controls.Add(this.groupBox12);
            this.tabPageConnectivity.Controls.Add(this.groupBox9);
            this.tabPageConnectivity.Controls.Add(this.groupBox8);
            this.tabPageConnectivity.Controls.Add(this.groupBox7);
            this.tabPageConnectivity.Controls.Add(this.groupBox6);
            this.tabPageConnectivity.Controls.Add(this.groupBox5);
            this.tabPageConnectivity.Location = new System.Drawing.Point(4, 22);
            this.tabPageConnectivity.Name = "tabPageConnectivity";
            this.tabPageConnectivity.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageConnectivity.Size = new System.Drawing.Size(1366, 530);
            this.tabPageConnectivity.TabIndex = 3;
            this.tabPageConnectivity.Text = "Settings";
            // 
            // groupBox12
            // 
            this.groupBox12.Controls.Add(this.label12);
            this.groupBox12.Controls.Add(this.textBoxDataVaultPrefix);
            this.groupBox12.Controls.Add(this.label9);
            this.groupBox12.Controls.Add(this.textBoxPrefix);
            this.groupBox12.Location = new System.Drawing.Point(12, 391);
            this.groupBox12.Name = "groupBox12";
            this.groupBox12.Size = new System.Drawing.Size(199, 120);
            this.groupBox12.TabIndex = 41;
            this.groupBox12.TabStop = false;
            this.groupBox12.Text = "Other Settings";
            this.groupBox12.Enter += new System.EventHandler(this.groupBox12_Enter);
            // 
            // label12
            // 
            this.label12.AutoSize = true;
            this.label12.Location = new System.Drawing.Point(5, 66);
            this.label12.Name = "label12";
            this.label12.Size = new System.Drawing.Size(160, 13);
            this.label12.TabIndex = 32;
            this.label12.Text = "Data Vault ETL Prefix / Identifier";
            // 
            // textBoxDataVaultPrefix
            // 
            this.textBoxDataVaultPrefix.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxDataVaultPrefix.Location = new System.Drawing.Point(7, 82);
            this.textBoxDataVaultPrefix.Multiline = true;
            this.textBoxDataVaultPrefix.Name = "textBoxDataVaultPrefix";
            this.textBoxDataVaultPrefix.Size = new System.Drawing.Size(181, 20);
            this.textBoxDataVaultPrefix.TabIndex = 31;
            this.textBoxDataVaultPrefix.Text = "m_200_";
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Location = new System.Drawing.Point(6, 22);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(76, 13);
            this.label9.TabIndex = 30;
            this.label9.Text = "DIRECT Prefix";
            // 
            // textBoxPrefix
            // 
            this.textBoxPrefix.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxPrefix.Location = new System.Drawing.Point(8, 38);
            this.textBoxPrefix.Multiline = true;
            this.textBoxPrefix.Name = "textBoxPrefix";
            this.textBoxPrefix.Size = new System.Drawing.Size(180, 20);
            this.textBoxPrefix.TabIndex = 29;
            this.textBoxPrefix.Text = "OMD_";
            // 
            // groupBox9
            // 
            this.groupBox9.Controls.Add(this.label2);
            this.groupBox9.Controls.Add(this.textBoxGenerationMetadataConnection);
            this.groupBox9.Controls.Add(this.MetadataConnectionLabel);
            this.groupBox9.Controls.Add(this.textBoxGenerationMetadataDatabaseName);
            this.groupBox9.Location = new System.Drawing.Point(12, 145);
            this.groupBox9.Name = "groupBox9";
            this.groupBox9.Size = new System.Drawing.Size(646, 110);
            this.groupBox9.TabIndex = 40;
            this.groupBox9.TabStop = false;
            this.groupBox9.Text = "ETL Generation Metadata";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(6, 62);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(82, 13);
            this.label2.TabIndex = 24;
            this.label2.Text = "Database name";
            // 
            // textBoxGenerationMetadataConnection
            // 
            this.textBoxGenerationMetadataConnection.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxGenerationMetadataConnection.Location = new System.Drawing.Point(8, 39);
            this.textBoxGenerationMetadataConnection.Multiline = true;
            this.textBoxGenerationMetadataConnection.Name = "textBoxGenerationMetadataConnection";
            this.textBoxGenerationMetadataConnection.Size = new System.Drawing.Size(629, 20);
            this.textBoxGenerationMetadataConnection.TabIndex = 19;
            // 
            // MetadataConnectionLabel
            // 
            this.MetadataConnectionLabel.AutoSize = true;
            this.MetadataConnectionLabel.Location = new System.Drawing.Point(6, 23);
            this.MetadataConnectionLabel.Name = "MetadataConnectionLabel";
            this.MetadataConnectionLabel.Size = new System.Drawing.Size(137, 13);
            this.MetadataConnectionLabel.TabIndex = 20;
            this.MetadataConnectionLabel.Text = "Database connection string";
            // 
            // textBoxGenerationMetadataDatabaseName
            // 
            this.textBoxGenerationMetadataDatabaseName.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxGenerationMetadataDatabaseName.Location = new System.Drawing.Point(8, 78);
            this.textBoxGenerationMetadataDatabaseName.Multiline = true;
            this.textBoxGenerationMetadataDatabaseName.Name = "textBoxGenerationMetadataDatabaseName";
            this.textBoxGenerationMetadataDatabaseName.Size = new System.Drawing.Size(629, 20);
            this.textBoxGenerationMetadataDatabaseName.TabIndex = 23;
            // 
            // groupBox8
            // 
            this.groupBox8.Controls.Add(this.labelOMDdatabase);
            this.groupBox8.Controls.Add(this.textBoxDirectConnection);
            this.groupBox8.Controls.Add(this.label5);
            this.groupBox8.Controls.Add(this.textBoxDirectDatabase);
            this.groupBox8.Location = new System.Drawing.Point(12, 16);
            this.groupBox8.Name = "groupBox8";
            this.groupBox8.Size = new System.Drawing.Size(646, 110);
            this.groupBox8.TabIndex = 39;
            this.groupBox8.TabStop = false;
            this.groupBox8.Text = "DIRECT Metadata";
            // 
            // labelOMDdatabase
            // 
            this.labelOMDdatabase.AutoSize = true;
            this.labelOMDdatabase.Location = new System.Drawing.Point(6, 60);
            this.labelOMDdatabase.Name = "labelOMDdatabase";
            this.labelOMDdatabase.Size = new System.Drawing.Size(82, 13);
            this.labelOMDdatabase.TabIndex = 28;
            this.labelOMDdatabase.Text = "Database name";
            // 
            // textBoxDirectConnection
            // 
            this.textBoxDirectConnection.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxDirectConnection.Location = new System.Drawing.Point(8, 37);
            this.textBoxDirectConnection.Multiline = true;
            this.textBoxDirectConnection.Name = "textBoxDirectConnection";
            this.textBoxDirectConnection.Size = new System.Drawing.Size(629, 20);
            this.textBoxDirectConnection.TabIndex = 25;
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(6, 21);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(137, 13);
            this.label5.TabIndex = 26;
            this.label5.Text = "Database connection string";
            // 
            // textBoxDirectDatabase
            // 
            this.textBoxDirectDatabase.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxDirectDatabase.Location = new System.Drawing.Point(8, 76);
            this.textBoxDirectDatabase.Multiline = true;
            this.textBoxDirectDatabase.Name = "textBoxDirectDatabase";
            this.textBoxDirectDatabase.Size = new System.Drawing.Size(629, 20);
            this.textBoxDirectDatabase.TabIndex = 27;
            // 
            // groupBox7
            // 
            this.groupBox7.Controls.Add(this.label10);
            this.groupBox7.Controls.Add(this.textBoxPSAConnection);
            this.groupBox7.Controls.Add(this.label11);
            this.groupBox7.Controls.Add(this.textBoxPSADatabase);
            this.groupBox7.Location = new System.Drawing.Point(683, 145);
            this.groupBox7.Name = "groupBox7";
            this.groupBox7.Size = new System.Drawing.Size(646, 114);
            this.groupBox7.TabIndex = 38;
            this.groupBox7.TabStop = false;
            this.groupBox7.Text = "Persistent Staging Area (PSA)";
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Location = new System.Drawing.Point(6, 64);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(82, 13);
            this.label10.TabIndex = 32;
            this.label10.Text = "Database name";
            // 
            // textBoxPSAConnection
            // 
            this.textBoxPSAConnection.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxPSAConnection.Location = new System.Drawing.Point(8, 41);
            this.textBoxPSAConnection.Multiline = true;
            this.textBoxPSAConnection.Name = "textBoxPSAConnection";
            this.textBoxPSAConnection.Size = new System.Drawing.Size(629, 20);
            this.textBoxPSAConnection.TabIndex = 29;
            // 
            // label11
            // 
            this.label11.AutoSize = true;
            this.label11.Location = new System.Drawing.Point(6, 25);
            this.label11.Name = "label11";
            this.label11.Size = new System.Drawing.Size(137, 13);
            this.label11.TabIndex = 30;
            this.label11.Text = "Database connection string";
            // 
            // textBoxPSADatabase
            // 
            this.textBoxPSADatabase.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxPSADatabase.Location = new System.Drawing.Point(8, 80);
            this.textBoxPSADatabase.Multiline = true;
            this.textBoxPSADatabase.Name = "textBoxPSADatabase";
            this.textBoxPSADatabase.Size = new System.Drawing.Size(629, 20);
            this.textBoxPSADatabase.TabIndex = 31;
            // 
            // groupBox6
            // 
            this.groupBox6.Controls.Add(this.label3);
            this.groupBox6.Controls.Add(this.textBoxSTGConnection);
            this.groupBox6.Controls.Add(this.label7);
            this.groupBox6.Controls.Add(this.textBoxSTGDatabase);
            this.groupBox6.Location = new System.Drawing.Point(683, 16);
            this.groupBox6.Name = "groupBox6";
            this.groupBox6.Size = new System.Drawing.Size(646, 114);
            this.groupBox6.TabIndex = 37;
            this.groupBox6.TabStop = false;
            this.groupBox6.Text = "Staging Area (STG)";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(6, 64);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(82, 13);
            this.label3.TabIndex = 32;
            this.label3.Text = "Database name";
            // 
            // textBoxSTGConnection
            // 
            this.textBoxSTGConnection.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxSTGConnection.Location = new System.Drawing.Point(8, 41);
            this.textBoxSTGConnection.Multiline = true;
            this.textBoxSTGConnection.Name = "textBoxSTGConnection";
            this.textBoxSTGConnection.Size = new System.Drawing.Size(629, 20);
            this.textBoxSTGConnection.TabIndex = 29;
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Location = new System.Drawing.Point(6, 25);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(137, 13);
            this.label7.TabIndex = 30;
            this.label7.Text = "Database connection string";
            // 
            // textBoxSTGDatabase
            // 
            this.textBoxSTGDatabase.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxSTGDatabase.Location = new System.Drawing.Point(8, 80);
            this.textBoxSTGDatabase.Multiline = true;
            this.textBoxSTGDatabase.Name = "textBoxSTGDatabase";
            this.textBoxSTGDatabase.Size = new System.Drawing.Size(629, 20);
            this.textBoxSTGDatabase.TabIndex = 31;
            // 
            // groupBox5
            // 
            this.groupBox5.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.groupBox5.BackColor = System.Drawing.Color.WhiteSmoke;
            this.groupBox5.Controls.Add(this.checkBoxOMDVerboseDebugging);
            this.groupBox5.Controls.Add(this.label1);
            this.groupBox5.Controls.Add(this.textBoxOutputPath);
            this.groupBox5.Location = new System.Drawing.Point(12, 272);
            this.groupBox5.Name = "groupBox5";
            this.groupBox5.Size = new System.Drawing.Size(646, 99);
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
            this.label1.Location = new System.Drawing.Point(6, 47);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(209, 13);
            this.label1.TabIndex = 21;
            this.label1.Text = "Output path (for file outputs and debuggin):";
            this.label1.Click += new System.EventHandler(this.label1_Click);
            // 
            // textBoxOutputPath
            // 
            this.textBoxOutputPath.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.textBoxOutputPath.Location = new System.Drawing.Point(6, 63);
            this.textBoxOutputPath.Multiline = true;
            this.textBoxOutputPath.Name = "textBoxOutputPath";
            this.textBoxOutputPath.Size = new System.Drawing.Size(629, 20);
            this.textBoxOutputPath.TabIndex = 18;
            this.textBoxOutputPath.TextChanged += new System.EventHandler(this.textBoxOutputPath_TextChanged);
            // 
            // tabPageOutput
            // 
            this.tabPageOutput.Controls.Add(this.DebuggingTextbox);
            this.tabPageOutput.Location = new System.Drawing.Point(4, 22);
            this.tabPageOutput.Name = "tabPageOutput";
            this.tabPageOutput.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageOutput.Size = new System.Drawing.Size(1366, 530);
            this.tabPageOutput.TabIndex = 10;
            this.tabPageOutput.Text = "Output / Debugging";
            this.tabPageOutput.UseVisualStyleBackColor = true;
            // 
            // menuStrip1
            // 
            this.menuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.fileToolStripMenuItem1,
            this.helpToolStripMenuItem2});
            this.menuStrip1.Location = new System.Drawing.Point(0, 0);
            this.menuStrip1.Name = "menuStrip1";
            this.menuStrip1.Size = new System.Drawing.Size(1400, 24);
            this.menuStrip1.TabIndex = 4;
            this.menuStrip1.Text = "menuStrip1";
            // 
            // fileToolStripMenuItem1
            // 
            this.fileToolStripMenuItem1.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.openConfigurationFileToolStripMenuItem1,
            this.saveConfigurationFileToolStripMenuItem,
            this.openOutputDirectoryToolStripMenuItem1,
            this.openConfigurationDirectoryToolStripMenuItem,
            this.exitToolStripMenuItem1});
            this.fileToolStripMenuItem1.Name = "fileToolStripMenuItem1";
            this.fileToolStripMenuItem1.Size = new System.Drawing.Size(37, 20);
            this.fileToolStripMenuItem1.Text = "File";
            // 
            // openConfigurationFileToolStripMenuItem1
            // 
            this.openConfigurationFileToolStripMenuItem1.Image = global::OMD_Manager.Properties.Resources.OpenFileIcon;
            this.openConfigurationFileToolStripMenuItem1.Name = "openConfigurationFileToolStripMenuItem1";
            this.openConfigurationFileToolStripMenuItem1.Size = new System.Drawing.Size(231, 22);
            this.openConfigurationFileToolStripMenuItem1.Text = "Open Configuration File";
            this.openConfigurationFileToolStripMenuItem1.Click += new System.EventHandler(this.openConfigurationFileToolStripMenuItem1_Click);
            // 
            // saveConfigurationFileToolStripMenuItem
            // 
            this.saveConfigurationFileToolStripMenuItem.Image = global::OMD_Manager.Properties.Resources.SaveFile;
            this.saveConfigurationFileToolStripMenuItem.Name = "saveConfigurationFileToolStripMenuItem";
            this.saveConfigurationFileToolStripMenuItem.Size = new System.Drawing.Size(231, 22);
            this.saveConfigurationFileToolStripMenuItem.Text = "Save Configuration File";
            this.saveConfigurationFileToolStripMenuItem.Click += new System.EventHandler(this.saveConfigurationFileToolStripMenuItem_Click_1);
            // 
            // openOutputDirectoryToolStripMenuItem1
            // 
            this.openOutputDirectoryToolStripMenuItem1.Image = global::OMD_Manager.Properties.Resources.OpenDirectoryIcon;
            this.openOutputDirectoryToolStripMenuItem1.Name = "openOutputDirectoryToolStripMenuItem1";
            this.openOutputDirectoryToolStripMenuItem1.Size = new System.Drawing.Size(231, 22);
            this.openOutputDirectoryToolStripMenuItem1.Text = "Open Output Directory";
            this.openOutputDirectoryToolStripMenuItem1.Click += new System.EventHandler(this.openOutputDirectoryToolStripMenuItem1_Click);
            // 
            // openConfigurationDirectoryToolStripMenuItem
            // 
            this.openConfigurationDirectoryToolStripMenuItem.Image = global::OMD_Manager.Properties.Resources.OpenDirectoryIcon;
            this.openConfigurationDirectoryToolStripMenuItem.Name = "openConfigurationDirectoryToolStripMenuItem";
            this.openConfigurationDirectoryToolStripMenuItem.Size = new System.Drawing.Size(231, 22);
            this.openConfigurationDirectoryToolStripMenuItem.Text = "Open Configuration Directory";
            this.openConfigurationDirectoryToolStripMenuItem.Click += new System.EventHandler(this.openConfigurationDirectoryToolStripMenuItem_Click);
            // 
            // exitToolStripMenuItem1
            // 
            this.exitToolStripMenuItem1.Image = global::OMD_Manager.Properties.Resources.ExitApplication;
            this.exitToolStripMenuItem1.Name = "exitToolStripMenuItem1";
            this.exitToolStripMenuItem1.Size = new System.Drawing.Size(231, 22);
            this.exitToolStripMenuItem1.Text = "Exit";
            this.exitToolStripMenuItem1.Click += new System.EventHandler(this.exitToolStripMenuItem1_Click);
            // 
            // helpToolStripMenuItem2
            // 
            this.helpToolStripMenuItem2.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.linksToolStripMenuItem,
            this.toolStripSeparator2,
            this.aboutToolStripMenuItem1});
            this.helpToolStripMenuItem2.Name = "helpToolStripMenuItem2";
            this.helpToolStripMenuItem2.Size = new System.Drawing.Size(44, 20);
            this.helpToolStripMenuItem2.Text = "Help";
            // 
            // linksToolStripMenuItem
            // 
            this.linksToolStripMenuItem.Image = global::OMD_Manager.Properties.Resources.LinkIcon;
            this.linksToolStripMenuItem.Name = "linksToolStripMenuItem";
            this.linksToolStripMenuItem.Size = new System.Drawing.Size(180, 22);
            this.linksToolStripMenuItem.Text = "Links";
            // 
            // toolStripSeparator2
            // 
            this.toolStripSeparator2.Name = "toolStripSeparator2";
            this.toolStripSeparator2.Size = new System.Drawing.Size(177, 6);
            // 
            // aboutToolStripMenuItem1
            // 
            this.aboutToolStripMenuItem1.Image = global::OMD_Manager.Properties.Resources.RavosLogo;
            this.aboutToolStripMenuItem1.Name = "aboutToolStripMenuItem1";
            this.aboutToolStripMenuItem1.Size = new System.Drawing.Size(180, 22);
            this.aboutToolStripMenuItem1.Text = "About";
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
            // richTextBoxInformation
            // 
            this.richTextBoxInformation.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.richTextBoxInformation.Location = new System.Drawing.Point(12, 621);
            this.richTextBoxInformation.Name = "richTextBoxInformation";
            this.richTextBoxInformation.Size = new System.Drawing.Size(1240, 110);
            this.richTextBoxInformation.TabIndex = 16;
            this.richTextBoxInformation.Text = "";
            // 
            // label6
            // 
            this.label6.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(12, 606);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(59, 13);
            this.label6.TabIndex = 17;
            this.label6.Text = "Information";
            // 
            // pictureBox1
            // 
            this.pictureBox1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.pictureBox1.Location = new System.Drawing.Point(1272, 621);
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
            this.ClientSize = new System.Drawing.Size(1400, 746);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.richTextBoxInformation);
            this.Controls.Add(this.pictureBox1);
            this.Controls.Add(this.MainTabControl);
            this.Controls.Add(this.menuStrip1);
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.MainMenuStrip = this.menuStrip1;
            this.MinimumSize = new System.Drawing.Size(1233, 656);
            this.Name = "FormMain";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Data Integration Runtime Exection Control Tool (DIRECT) Framework Manager";
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
            this.tabPageReinitialise.ResumeLayout(false);
            this.tabPageReinitialise.PerformLayout();
            this.groupBox11.ResumeLayout(false);
            this.groupBox11.PerformLayout();
            this.groupBox10.ResumeLayout(false);
            this.groupBox10.PerformLayout();
            this.tabPageConnectivity.ResumeLayout(false);
            this.groupBox12.ResumeLayout(false);
            this.groupBox12.PerformLayout();
            this.groupBox9.ResumeLayout(false);
            this.groupBox9.PerformLayout();
            this.groupBox8.ResumeLayout(false);
            this.groupBox8.PerformLayout();
            this.groupBox7.ResumeLayout(false);
            this.groupBox7.PerformLayout();
            this.groupBox6.ResumeLayout(false);
            this.groupBox6.PerformLayout();
            this.groupBox5.ResumeLayout(false);
            this.groupBox5.PerformLayout();
            this.tabPageOutput.ResumeLayout(false);
            this.menuStrip1.ResumeLayout(false);
            this.menuStrip1.PerformLayout();
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
        private System.Windows.Forms.RichTextBox richTextBoxInformation;
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
        internal System.Windows.Forms.TextBox textBoxGenerationMetadataConnection;
        internal System.Windows.Forms.TextBox textBoxOutputPath;
        private System.Windows.Forms.Label label2;
        internal System.Windows.Forms.TextBox textBoxGenerationMetadataDatabaseName;
        private System.Windows.Forms.CheckedListBox checkedListBoxStagingTables;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.TextBox textBoxFilterCriterion;
        private System.Windows.Forms.GroupBox groupBox2;
        private System.Windows.Forms.CheckBox checkBoxGenerateInt;
        private System.Windows.Forms.CheckBox checkBoxGenerateStg;
        private System.Windows.Forms.CheckBox checkBoxGenerateHstg;
        private System.Windows.Forms.CheckBox checkBoxGenerateEndDating;
        private System.Windows.Forms.CheckBox checkBoxSelectAllMain;
        private System.Windows.Forms.RadioButton radioButtonCatalog;
        private System.Windows.Forms.RadioButton radioButtonETLGenerationMetadata;
        private System.Windows.Forms.GroupBox groupBox3;
        private System.Windows.Forms.CheckBox checkBoxGenerateModules;
        private System.Windows.Forms.CheckBox checkBoxGenerateDataStoreModule;
        private System.Windows.Forms.CheckBox checkBoxGenerateBatchModule;
        private System.Windows.Forms.CheckBox checkBoxGenerateDataStore;
        private System.Windows.Forms.CheckBox checkBoxGenerateBatches;
        private System.Windows.Forms.Label labelOMDdatabase;
        internal System.Windows.Forms.TextBox textBoxDirectDatabase;
        private System.Windows.Forms.Label label5;
        internal System.Windows.Forms.TextBox textBoxDirectConnection;
        private System.Windows.Forms.PictureBox pictureBox1;
        private System.Windows.Forms.CheckedListBox checkedListboxReinistalisation;
        private System.Windows.Forms.GroupBox groupBox9;
        private System.Windows.Forms.GroupBox groupBox8;
        private System.Windows.Forms.GroupBox groupBox7;
        private System.Windows.Forms.Label label10;
        internal System.Windows.Forms.TextBox textBoxPSAConnection;
        private System.Windows.Forms.Label label11;
        internal System.Windows.Forms.TextBox textBoxPSADatabase;
        private System.Windows.Forms.GroupBox groupBox6;
        private System.Windows.Forms.Label label3;
        internal System.Windows.Forms.TextBox textBoxSTGConnection;
        private System.Windows.Forms.Label label7;
        internal System.Windows.Forms.TextBox textBoxSTGDatabase;
        private System.Windows.Forms.ToolStripMenuItem fileToolStripMenuItem1;
        private System.Windows.Forms.ToolStripMenuItem openConfigurationFileToolStripMenuItem1;
        private System.Windows.Forms.ToolStripMenuItem saveConfigurationFileToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem openOutputDirectoryToolStripMenuItem1;
        private System.Windows.Forms.ToolStripMenuItem exitToolStripMenuItem1;
        private System.Windows.Forms.ToolStripMenuItem helpToolStripMenuItem2;
        private System.Windows.Forms.ToolStripMenuItem linksToolStripMenuItem;
        private System.Windows.Forms.ToolStripSeparator toolStripSeparator2;
        private System.Windows.Forms.ToolStripMenuItem aboutToolStripMenuItem1;
        private System.Windows.Forms.GroupBox groupBox10;
        private System.Windows.Forms.RadioButton radioButtonSTG;
        private System.Windows.Forms.RadioButton radioButtonPSA;
        private System.Windows.Forms.GroupBox groupBox11;
        private System.Windows.Forms.TextBox textBoxReinitialisationFilterCriterion;
        private System.Windows.Forms.CheckBox checkBoxSelectAllReinistialisation;
        private System.Windows.Forms.Label label8;
        private System.Windows.Forms.Button button2;
        private System.Windows.Forms.RichTextBox richTextBox1;
        private System.Windows.Forms.CheckBox checkBoxExecuteReinitialisation;
        private System.Windows.Forms.GroupBox groupBox12;
        private System.Windows.Forms.Label label9;
        internal System.Windows.Forms.TextBox textBoxPrefix;
        private System.Windows.Forms.Label label12;
        internal System.Windows.Forms.TextBox textBoxDataVaultPrefix;
        private System.Windows.Forms.Button button3;
        private System.Windows.Forms.DateTimePicker dateTimePickerReinitialisation;
        private System.Windows.Forms.ToolStripMenuItem openConfigurationDirectoryToolStripMenuItem;
    }
}

