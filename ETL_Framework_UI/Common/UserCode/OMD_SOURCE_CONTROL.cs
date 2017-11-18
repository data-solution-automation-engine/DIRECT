using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
namespace LightSwitchApplication
{
    public partial class OMD_SOURCE_CONTROL
    {
        partial void MODULE_CODE_Compute(ref string result)
        {
            result = OMD_MODULE_INSTANCE.MODULE_CODE;
        }

        partial void BATCH_CODE_Compute(ref string result)
        {
            result = OMD_MODULE_INSTANCE.BATCH_CODE;
        }

        partial void OMD_MODULE_INSTANCE_IsReadOnly(ref bool result)
        {
            result = true;
        }

    }
}
