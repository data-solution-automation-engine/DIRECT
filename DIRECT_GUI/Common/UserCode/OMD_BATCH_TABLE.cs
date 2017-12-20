using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
namespace LightSwitchApplication
{
    public partial class OMD_BATCH_TABLE
    {
        partial void BATCH_CODE_Validate(EntityValidationResultsBuilder results)
        {
            var bCode = this.DataWorkspace.C900_OMD_FrameworkData.OMD_BATCH_TABLE.Where(c => c.BATCH_CODE == this.BATCH_CODE && c.BATCH_ID != this.BATCH_ID ).FirstOrDefault();
            if (bCode != null)
            {
                results.AddPropertyError("Duplicate Batch Code. Please Enter Unique Batch Code");
            }           

        }       
    }
}
