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
    public partial class EXECUTION_LOG_DETAILS
    {
        partial void OMD_BATCH_INSTANCE_Loaded(bool succeeded)
        {
            // Write your code here.
            this.SetDisplayNameFromEntity(this.OMD_BATCH_INSTANCE);
        }

        partial void OMD_BATCH_INSTANCE_Changed()
        {
            // Write your code here.
            this.SetDisplayNameFromEntity(this.OMD_BATCH_INSTANCE);
        }

        partial void EXECUTION_LOG_DETAILS_Saved()
        {
            // Write your code here.
            this.SetDisplayNameFromEntity(this.OMD_BATCH_INSTANCE);
        }
    }
}