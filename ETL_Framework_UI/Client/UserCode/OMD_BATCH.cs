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
    public partial class BATCH
    {
        partial void OK_Execute()
        {
            // Write your code here.
            this.DataWorkspace.ApplicationData.SaveChanges();
            this.CloseModalWindow("GROUP_BATCH_MODULE");
        }

        partial void Cancel_Execute()
        {
            // Write your code here.
            this.CloseModalWindow("GROUP_BATCH_MODULE");

        }
    }
}
