using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.LightSwitch;
using Microsoft.LightSwitch.Security.Server;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace LightSwitchApplication
{
    public partial class C900_OMD_UI_ViewsService
    {
        partial void OMD_UI_EXEC_usp_OMD_MODULE_INSTANCE_FIX_INDICATORS_Inserting(OMD_UI_EXEC_usp_OMD_MODULE_INSTANCE_FIX_INDICATOR entity)
        {
            using (SqlConnection connection = new SqlConnection())
            {
                string connectionStringName = this.DataWorkspace.C900_OMD_UI_Views.Details.Name;
                connection.ConnectionString =
                    ConfigurationManager.ConnectionStrings[connectionStringName].ConnectionString;

                string procedure = "dbo.usp_OMD_MODULE_INSTANCE_FIX_INDICATORS";
                using (SqlCommand command = new SqlCommand(procedure, connection))
                {
                    command.CommandType = CommandType.StoredProcedure;

                    command.Parameters.Add(
                        new SqlParameter("@pMODULE_INSTANCE_ID", entity.MODULE_INSTANCE_ID));

                    connection.Open();
                    command.ExecuteNonQuery();
                }
            }

            this.Details.DiscardChanges();
        }

        partial void OMD_UI_EXEC_usp_OMD_BATCH_INSTANCE_FIX_INDICATORS_Inserting(OMD_UI_EXEC_usp_OMD_BATCH_INSTANCE_FIX_INDICATOR entity)
        {
            using (SqlConnection connection = new SqlConnection())
            {
                string connectionStringName = this.DataWorkspace.C900_OMD_UI_Views.Details.Name;
                connection.ConnectionString =
                    ConfigurationManager.ConnectionStrings[connectionStringName].ConnectionString;

                string procedure = "dbo.usp_OMD_BATCH_INSTANCE_FIX_INDICATORS";
                using (SqlCommand command = new SqlCommand(procedure, connection))
                {
                    command.CommandType = CommandType.StoredProcedure;

                    command.Parameters.Add(
                        new SqlParameter("@pBATCH_INSTANCE_ID", entity.BATCH_INSTANCE_ID));

                    connection.Open();
                    command.ExecuteNonQuery();
                }
            }

            this.Details.DiscardChanges();
        }
    }
}
