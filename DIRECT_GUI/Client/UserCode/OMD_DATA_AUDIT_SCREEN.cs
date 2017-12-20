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
    public partial class OMD_DATA_AUDIT_SCREEN
    {
        partial void OMD_DATA_AUDIT_Loaded(bool succeeded)
        {
            // Write your code here.
            this.SetDisplayNameFromEntity(this.OMD_DATA_AUDIT);
        }

        partial void OMD_DATA_AUDIT_Changed()
        {
            // Write your code here.
            this.SetDisplayNameFromEntity(this.OMD_DATA_AUDIT);
        }

        partial void OMD_DATA_AUDIT_SCREEN_Saved()
        {
            // Write your code here.
            this.SetDisplayNameFromEntity(this.OMD_DATA_AUDIT);
        }
    }
}