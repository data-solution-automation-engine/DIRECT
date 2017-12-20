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
    public partial class PARAMETER
    {
        partial void Save_Parameter_Execute()
        {
            // Write your code here.
            this.DataWorkspace.ApplicationData.SaveChanges();
            this.DataWorkspace.C900_OMD_FrameworkData.SaveChanges();
            this.CloseModalWindow("GROUP_MODULE_PARAMETER");
        }

        partial void Cancel_Parameter_Execute()
        {
            // Write your code here.
            this.CloseModalWindow("GROUP_MODULE_PARAMETER");
        }
    }
}
