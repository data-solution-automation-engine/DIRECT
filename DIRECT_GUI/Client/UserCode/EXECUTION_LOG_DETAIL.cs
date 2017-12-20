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
    public partial class EXECUTION_LOG_DETAIL
    {
        partial void OMD_EXECUTION_LOG_Loaded(bool succeeded)
        {
            // Write your code here.
            this.SetDisplayNameFromEntity(this.OMD_EXECUTION_LOG);
        }

        partial void OMD_EXECUTION_LOG_Changed()
        {
            // Write your code here.
            this.SetDisplayNameFromEntity(this.OMD_EXECUTION_LOG);
        }

        partial void EXECUTION_LOG_DETAIL_Saved()
        {
            // Write your code here.
            this.SetDisplayNameFromEntity(this.OMD_EXECUTION_LOG);
        }

        partial void MODULE_INSTANCE_FIX_INDICATORS_CanExecute(ref bool result)
        {
            if (OMD_EXECUTION_LOG_MODULE_INSTANCEs.Count > 0)
            {
                result = ! ((OMD_EXECUTION_LOG_MODULE_INSTANCEs.SelectedItem.EXECUTION_STATUS_CODE == "S") || (OMD_EXECUTION_LOG_MODULE_INSTANCEs.SelectedItem.EXECUTION_STATUS_CODE == "X"));
            }
            else
            {
                result = false;
            }
        }

        partial void MODULE_INSTANCE_FIX_INDICATORS_Execute()
        {
            if (this.ShowMessageBox("Module instance record will be set for re-execution. Do you want to proceed?", "Module Instance", MessageBoxOption.YesNo) == System.Windows.MessageBoxResult.Yes)
            {
                DataWorkspace dataWorkspace = new DataWorkspace();
                OMD_EXECUTION_LOG_MODULE_INSTANCE entity = this.OMD_EXECUTION_LOG_MODULE_INSTANCEs.SelectedItem;

                OMD_UI_EXEC_usp_OMD_MODULE_INSTANCE_FIX_INDICATOR operation =
                    dataWorkspace.C900_OMD_UI_Views.OMD_UI_EXEC_usp_OMD_MODULE_INSTANCE_FIX_INDICATORS.AddNew();

                operation.MODULE_INSTANCE_ID = entity.MODULE_INSTANCE_ID;

                dataWorkspace.C900_OMD_UI_Views.SaveChanges();
                this.Refresh();
            }
        }

        partial void BATCH_INSTANCE_FIX_INDICATORS_CanExecute(ref bool result)
        {
            result = !((OMD_EXECUTION_LOG.EXECUTION_STATUS_CODE == "S") || (OMD_EXECUTION_LOG.EXECUTION_STATUS_CODE == "X"));
        }

        partial void BATCH_INSTANCE_FIX_INDICATORS_Execute()
        {
            if (this.ShowMessageBox("Batch instance record will be set for re-execution. Do you want to proceed?", "Batch Instance", MessageBoxOption.YesNo) == System.Windows.MessageBoxResult.Yes)
            {
                DataWorkspace dataWorkspace = new DataWorkspace();
                OMD_EXECUTION_LOG entity = this.OMD_EXECUTION_LOG;

                OMD_UI_EXEC_usp_OMD_BATCH_INSTANCE_FIX_INDICATOR operation =
                    dataWorkspace.C900_OMD_UI_Views.OMD_UI_EXEC_usp_OMD_BATCH_INSTANCE_FIX_INDICATORS.AddNew();

                operation.BATCH_INSTANCE_ID = entity.BATCH_INSTANCE_ID;

                dataWorkspace.C900_OMD_UI_Views.SaveChanges();
                this.Refresh();
            }
        }
    }
}