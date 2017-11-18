using System;
using System.Linq;
using System.IO;
using System.IO.IsolatedStorage;
using System.Collections.Generic;
using Microsoft.LightSwitch;
using Microsoft.LightSwitch.Framework.Client;
using Microsoft.LightSwitch.Presentation;
using Microsoft.LightSwitch.Presentation.Extensions;
namespace LightSwitchApplication
{
    public partial class MODULE_Grid
    {
        partial void Save_Batch_Module_Execute()
        {
            // Write your code here.
            this.DataWorkspace.ApplicationData.SaveChanges();
            this.DataWorkspace.C900_OMD_FrameworkData.SaveChanges();
            this.CloseModalWindow("GROUP_BATCH_MODULE");
        }

        partial void Cancel_Batch_Module_Execute()
        {
            // Write your code here.
            this.CloseModalWindow("GROUP_BATCH_MODULE");
        }

        partial void Save_Module_Data_Store_Execute()
        {
            // Write your code here.
            this.DataWorkspace.ApplicationData.SaveChanges();
            this.DataWorkspace.C900_OMD_FrameworkData.SaveChanges();
            this.CloseModalWindow("GROUP_MODULE_DATA_STORE");
        }

        partial void Cancel_Execute()
        {
            // Write your code here.
            this.CloseModalWindow("GROUP_MODULE_DATA_STORE");
        }

 

        partial void Save_M_Parameter_Execute()
        {
            // Write your code here.
            this.DataWorkspace.ApplicationData.SaveChanges();
            this.DataWorkspace.C900_OMD_FrameworkData.SaveChanges();
            this.CloseModalWindow("GROUP_MODULE_PARAMETER");
        }

        partial void Cancel_M_Parameter_Execute()
        {
            // Write your code here.
            this.CloseModalWindow("GROUP_MODULE_PARAMETER");
        }

        partial void Save_Mod_Data_Store_Execute()
        {
            // Write your code here.
            this.DataWorkspace.ApplicationData.SaveChanges();
            this.DataWorkspace.C900_OMD_FrameworkData.SaveChanges();
            this.CloseModalWindow("GROUP_MODULE_DATA_STORE");
        }

        partial void Cancel_Module_Data_Store_Execute()
        {
            // Write your code here.
            this.CloseModalWindow("GROUP_MODULE_DATA_STORE");
        }
    }
}
