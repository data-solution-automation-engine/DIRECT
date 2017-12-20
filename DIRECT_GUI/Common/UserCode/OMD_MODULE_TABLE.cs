using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
namespace LightSwitchApplication
{
    public partial class OMD_MODULE_TABLE
    {
        partial void MODULE_CODE_Validate(EntityValidationResultsBuilder results)
        {
            // results.AddPropertyError("<Error-Message>");
            var mCode = this.DataWorkspace.C900_OMD_FrameworkData.OMD_MODULE_TABLE.Where(c => c.MODULE_CODE == this.MODULE_CODE && c.MODULE_ID != this.MODULE_ID).FirstOrDefault();
            if (mCode != null)
                results.AddPropertyError("Duplicate Module Code. Please Enter Unique Module Code");
        }

       
    }
}
