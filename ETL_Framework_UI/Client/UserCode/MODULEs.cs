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
    public partial class MODULEs
    {      

        partial void gridDeleteSelected_Execute()
        {
            // Write your code here.
            if (this.ShowMessageBox("All the information related to the Module will be deleted", "Delete",
                          MessageBoxOption.YesNo) == System.Windows.MessageBoxResult.Yes)             
                    this.OMD_MODULEs.SelectedItem.Delete();
        }

        partial void MODULEs_Activated()
        {
            // Write your code here.
          
        }

        partial void gridDeleteSelected_CanExecute(ref bool result)
        {
            // Write your code here.

        }

        partial void MODULEs_Saving(ref bool handled)
        {
            // Write your code here.
          
        }
        

        partial void gridAddAndEditNew_Execute()
        {
            // Write your code here.
           // this.OpenModalWindow(OMD_BATCH_MODULE);
        }

        partial void MODULEs_InitializeDataWorkspace(List<IDataService> saveChangesTo)
        {
            // Write your code here.
            int index = 4;

            OMD_DATA_STORE ds = this.DataWorkspace.C900_OMD_FrameworkData.OMD_DATA_STOREs.AddNew();
            ds.ALLOW_TRUNCATE_INDICATOR = "Y";
            ds.DATA_STORE_CODE = "MOD"+index;
            ds.DATA_STORE_DESCRIPTION = "MODIFY RECORD";
            ds.OMD_DATA_STORE_TYPE = this.DataWorkspace.C900_OMD_FrameworkData.OMD_DATA_STORE_TYPEs.First();

            OMD_MODULE_DATA_STORE omds = this.DataWorkspace.C900_OMD_FrameworkData.OMD_MODULE_DATA_STOREs.AddNew();
            omds.MODULE_ID = OMD_MODULEs.SelectedItem.MODULE_ID;
            omds.DATA_STORE_CODE = "MODULE TABLE INSERT";
            omds.RELATIONSHIP_TYPE = "SRC"+index;
            omds.OMD_DATA_STORE = this.DataWorkspace.C900_OMD_FrameworkData.OMD_DATA_STOREs.First();

            index++;
            this.DataWorkspace.ApplicationData.SaveChanges();
        }       
      
    }
}
