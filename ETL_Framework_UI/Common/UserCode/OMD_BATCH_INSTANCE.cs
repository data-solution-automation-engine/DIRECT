using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
namespace LightSwitchApplication
{
    public partial class OMD_BATCH_INSTANCE
    {
        partial void BATCH_CODE_Compute(ref string result)
        {
            result = OMD_BATCH_TABLE.BATCH_CODE;
        }

        partial void START_DATETIME_IsReadOnly(ref bool result)
        {
            result = true;
        }

        partial void END_DATETIME_IsReadOnly(ref bool result)
        {
            result = true;
        }

        partial void GUID_IsReadOnly(ref bool result)
        {
            result = true;
        }

        partial void OMD_BATCH_TABLE_IsReadOnly(ref bool result)
        {
            result = true;
        }

        partial void EXECUTION_STATUS_DESCRIPTION_Compute(ref string result)
        {
            result = OMD_EXECUTION_STATUS.EXECUTION_STATUS_DESCRIPTION;
        }

        partial void NEXT_RUN_INDICATOR_DESCRIPTION_Compute(ref string result)
        {
            result = OMD_NEXT_RUN_INDICATOR.NEXT_RUN_INDICATOR_DESCRIPTION;
        }

        partial void PROCESSING_INDICATOR_DESCRIPTION_Compute(ref string result)
        {
            result = OMD_PROCESSING_INDICATOR.PROCESSING_INDICATOR_DESCRIPTION;
        }
    }
}
