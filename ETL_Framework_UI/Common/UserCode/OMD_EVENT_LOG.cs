using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
namespace LightSwitchApplication
{
    public partial class OMD_EVENT_LOG
    {
           
        partial void MOD_INST_ID_Compute(ref int result)
        {
            // Set result to the desired field value
            result = OMD_MODULE_INSTANCE.MODULE_INSTANCE_ID;
        }

        partial void BATCH_INST_ID_Compute(ref int result)
        {
            // Set result to the desired field value
            result = OMD_BATCH_INSTANCE.BATCH_INSTANCE_ID;
        }

        partial void EVENT_TYPE1_Compute(ref string result)
        {
            // Set result to the desired field value
            result = OMD_EVENT_TYPE.EVENT_TYPE_DESCRIPTION;
        }
    }
}
