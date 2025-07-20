using System.Diagnostics;

using Microsoft.SqlServer.Dac;

namespace Direct_Framework.Integration.Tests.Migrations;

[TestClass]
public class MigrationTests
{
  private static string ConnectionString => SqlServerContainerManager.ConnectionString;
  private static readonly string MasterConnectionString = SqlServerContainerManager.ConnectionString.Replace("Database=Direct_Framework", "Database=master");

  public static void RunSqlCmdScript(string scriptPath, string connectionString)
  {
    // Parse connection string for server and database
    var builder = new Microsoft.Data.SqlClient.SqlConnectionStringBuilder(connectionString);

    var process = new Process
    {
      StartInfo = new ProcessStartInfo
      {
        FileName = "sqlcmd",
        Arguments = $"-S {builder.DataSource} -d {builder.InitialCatalog} -U {builder.UserID} -P {builder.Password} -i \"{scriptPath}\" -b -I",
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        CreateNoWindow = true,
        WorkingDirectory = Path.GetDirectoryName(scriptPath)
      }
    };

    process.Start();
    string output = process.StandardOutput.ReadToEnd();
    string error = process.StandardError.ReadToEnd();
    process.WaitForExit();

    if (process.ExitCode != 0)
    {
      throw new Exception($"sqlcmd failed: {error}\n{output}");
    }
  }

  [TestMethod]
  public async Task Can_Migrate_From_Current_To_Next()
  {
    var outputDir = AppContext.BaseDirectory;

    // Traverse up to the project folder
    var projectDir = Directory.GetParent(outputDir)!.Parent!.Parent!.Parent!.Parent!.FullName;

    // 1. Deploy current version DACPAC
    var currentDacpacPath = Path.Combine(projectDir, "Releases.Direct_Framework", "Current", "db", "Direct_Framework.dacpac");
    var dacServices = new DacServices(MasterConnectionString);
    var currentDacpac = DacPackage.Load(currentDacpacPath);

    // drop database if it exists, else we might try to downgrade here...
    try
    {
      await using var dconn = new SqlConnection(MasterConnectionString);
      await dconn.OpenAsync();
      await using var dcmd = new SqlCommand(@"
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Direct_Framework')
BEGIN
  ALTER DATABASE [Direct_Framework] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE [Direct_Framework];
END
", dconn);

      await dcmd.ExecuteNonQueryAsync();
    }
    catch (Exception ex)
    {
      Assert.Fail($"Failed to drop existing database: {ex.Message}");
    }

    try
    {
      dacServices.Deploy(currentDacpac, "Direct_Framework", true);
    }
    catch (Exception ex)
    {
      Assert.Fail($"Failed to deploy **CURRENT** version DACPAC:\n{ex.Message}");
    }

    // 2. Run pre/post deploy scripts for current version if needed
    //var preDeployScript = File.ReadAllText(Path.Combine("Migrations", "CurrentVersion", "PreDeploy_v1.sql"));
    //var postDeployScript = File.ReadAllText(Path.Combine("Migrations", "CurrentVersion", "PostDeploy_v1.sql"));
    //using (var conn = new SqlConnection(ConnectionString))
    //{
    //  await conn.OpenAsync();
    //  using var cmd = new SqlCommand(preDeployScript, conn);
    //  await cmd.ExecuteNonQueryAsync();
    //  using var cmd2 = new SqlCommand(postDeployScript, conn);
    //  await cmd2.ExecuteNonQueryAsync();
    //}

    var predeployPath = Path.Combine(projectDir, "Releases.Direct_Framework", "next", "db", "DeploymentScripts", "1-PreDacpacDeployment", "PreDacpacDeployment.sql");

    RunSqlCmdScript(predeployPath, ConnectionString);

    // 3. Populate with sample/test data
    //var sampleDataScript = File.ReadAllText(Path.Combine("Migrations", "MigrationTestData", "SampleData_v1.sql"));
    //using (var conn = new SqlConnection(ConnectionString))
    //{
    //  await conn.OpenAsync();
    //  using var cmd = new SqlCommand(sampleDataScript, conn);
    //  await cmd.ExecuteNonQueryAsync();
    //}

    //// 4. Deploy next version DACPAC (built from the database project)
    //var nextDacpacPath = Path.Combine(projectDir, "Releases.Direct_Framework", "Next", "db", "Direct_Framework.dacpac");
    //var nextDacpac = DacPackage.Load(nextDacpacPath);
    //try
    //{
    //  dacServices.Deploy(nextDacpac, "Direct_Framework", true);
    //}
    //catch (Exception ex)
    //{
    //  Assert.Fail($"Failed to deploy **NEXT** version DACPAC:\n{ex.Message}");
    //}

    // 5. Run pre/post deploy scripts for next version if needed
    // (Repeat as above, using next version scripts)

    //// 6. Assert migration success (check schema, data, etc.)
    //using var conn = new SqlConnection(ConnectionString);
    //await conn.OpenAsync();
    //using var cmd = new SqlCommand("SELECT COUNT(*) FROM sys.schemas WHERE name = 'omd'", conn);
    //var res = await cmd.ExecuteScalarAsync();
    //var count = Convert.ToInt32(res);
    //Assert.IsTrue(count > 0, "Schema 'omd' should exist after migration.");
  }
}
