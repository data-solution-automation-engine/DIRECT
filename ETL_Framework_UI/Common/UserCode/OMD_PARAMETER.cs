using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
namespace LightSwitchApplication
{
    public partial class OMD_PARAMETER
    {
        partial void PARAMETER_KEY_CODE_Validate(EntityValidationResultsBuilder results)
        {
            // results.AddPropertyError("<Error-Message>");
            var pkCode = this.DataWorkspace.C900_OMD_FrameworkData.OMD_PARAMETERs.Where(c => c.PARAMETER_KEY_CODE == this.PARAMETER_KEY_CODE && c.PARAMETER_ID != this.PARAMETER_ID).FirstOrDefault();
            if (pkCode != null)
                results.AddPropertyError("Duplicate Parameter Key Code. Please Enter Unique Parameter Key Code");
        }

        partial void PARAMETER_DESCRIPTION_Validate(EntityValidationResultsBuilder results)
        {
            // results.AddPropertyError("<Error-Message>");

        }
    }
}
