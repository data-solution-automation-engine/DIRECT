using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
namespace LightSwitchApplication
{
    public partial class OMD_DATA_STORE
    {
       /* partial void DATA_STORE_CODE_Validate(EntityValidationResultsBuilder results)
        {
            // results.AddPropertyError("<Error-Message>");
            var pkCode = this.DataWorkspace.C900_OMD_FrameworkData.OMD_DATA_STOREs.Where(c => c.DATA_STORE_CODE == this.DATA_STORE_CODE).FirstOrDefault();
            if (pkCode != null)
                results.AddPropertyError("Duplicate Data Store Code. Please Enter Unique Data Store Code");

        }*/
        partial void DATA_STORE_CODE_Validate(EntityValidationResultsBuilder results)
        {
            // results.AddPropertyError("<Error-Message>");
            var pkCode = this.DataWorkspace.C900_OMD_FrameworkData.OMD_DATA_STOREs.Where(c => c.DATA_STORE_CODE == this.DATA_STORE_CODE && c.DATA_STORE_ID != this.DATA_STORE_ID).FirstOrDefault();
            if (pkCode != null)
                results.AddPropertyError("Duplicate Data Store Code. Please Enter Unique Data Store Code");
        }
    }
}
