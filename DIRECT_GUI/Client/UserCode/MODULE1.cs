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
    public partial class MODULE1
    {
        partial void OK_Execute()
        {
            // Write your code here.
            this.DataWorkspace.ApplicationData.SaveChanges();
            this.DataWorkspace.C900_OMD_FrameworkData.SaveChanges();
            this.CloseModalWindow("GROUP_MODULE1");
        }

        partial void Cancel_Execute()
        {
            // Write your code here.
            this.CloseModalWindow("GROUP_MODULE1");
        }

        partial void OK1_Execute()
        {
            // Write your code here.
            this.DataWorkspace.ApplicationData.SaveChanges();
            this.DataWorkspace.C900_OMD_FrameworkData.SaveChanges();
            this.CloseModalWindow("GROUP_MODULE_DATA_STORE");

        }

        partial void Cancel1_Execute()
        {
            // Write your code here.
            this.CloseModalWindow("GROUP_MODULE_DATA_STORE");
        }
    }
}
