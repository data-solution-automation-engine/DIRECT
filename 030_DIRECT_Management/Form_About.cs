using System;
using System.Windows.Forms;
using DIRECT_Manager;

namespace DIRECT_Manager
{
    public partial class FormAbout : Form
    {
        public FormAbout(FormMain parent)
        {
            InitializeComponent();
        }

        private void buttonClose_Click(object sender, EventArgs e)
        {
            Close();
        }
   
    }
}
