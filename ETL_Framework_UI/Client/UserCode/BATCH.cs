using System;
using System.Linq;
using System.IO;
using System.IO.IsolatedStorage;
using System.Collections.Generic;
using Microsoft.LightSwitch;
using Microsoft.LightSwitch.Framework.Client;
using Microsoft.LightSwitch.Presentation;
using Microsoft.LightSwitch.Presentation.Extensions;
using System.Collections;
using Microsoft.LightSwitch.Threading;
using System.Windows.Hosting;
using System.Windows.Browser;

namespace LightSwitchApplication
{
    public partial class BATCH
    {

        partial void OK2_Execute()
        {
           // this.DataWorkspace.ApplicationData.SaveChanges();           
            this.DataWorkspace.C900_OMD_FrameworkData.SaveChanges();
            this.CloseModalWindow("GROUP_BATCH");

        }

        partial void CANCEL2_Execute()
        {
            // Write your code here.
            this.CloseModalWindow("GROUP_BATCH");
        }
        
    }
}
