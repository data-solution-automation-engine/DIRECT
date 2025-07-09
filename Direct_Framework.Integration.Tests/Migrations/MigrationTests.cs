using Microsoft.SqlServer.Dac;

namespace Direct_Framework.Integration.Tests.Migrations;

[TestClass]
public class MigrationTests
{
  private string ConnectionString => SqlServerContainerManager.ConnectionString;
  private string MasterConnectionString = SqlServerContainerManager.ConnectionString.Replace("Database=Direct_Framework", "Database=master");

  [TestMethod]
  public async Task Can_Migrate_From_Previous_To_Current()
  {
    // Get the output directory (e.g., bin\Debug\net10.0)
    var outputDir = AppContext.BaseDirectory;

    // Traverse up to the project folder
    var projectDir = Directory.GetParent(outputDir)!.Parent!.Parent!.Parent!.Parent!.FullName;


    // 1. Deploy previous version DACPAC
    var previousDacpacPath = Path.Combine(projectDir, "Releases.Direct_Framework", "v2.0.0", "db", "Direct_Framework.dacpac");
    var dacServices = new DacServices(MasterConnectionString);
    var previousDacpac = DacPackage.Load(previousDacpacPath);

    // drop current database if it exists, else we'll be downgrading here...
    try
    {
      using var dconn = new SqlConnection(MasterConnectionString);
      await dconn.OpenAsync();
      using var dcmd = new SqlCommand(@"
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
      dacServices.Deploy(previousDacpac, "Direct_Framework", true);
    }
    catch (Exception ex)
    {
      Assert.Fail($"Failed to deploy **PREVIOUS** version DACPAC:\n{ex.Message}");
    }

    // 2. Run pre/post deploy scripts for v1 if needed
    //var preDeployScript = File.ReadAllText(Path.Combine("Migrations", "PreviousVersion", "PreDeploy_v1.sql"));
    //var postDeployScript = File.ReadAllText(Path.Combine("Migrations", "PreviousVersion", "PostDeploy_v1.sql"));
    //using (var conn = new SqlConnection(ConnectionString))
    //{
    //  await conn.OpenAsync();
    //  using var cmd = new SqlCommand(preDeployScript, conn);
    //  await cmd.ExecuteNonQueryAsync();
    //  using var cmd2 = new SqlCommand(postDeployScript, conn);
    //  await cmd2.ExecuteNonQueryAsync();
    //}

    // 3. Populate with sample/test data
    //var sampleDataScript = File.ReadAllText(Path.Combine("Migrations", "MigrationTestData", "SampleData_v1.sql"));
    //using (var conn = new SqlConnection(ConnectionString))
    //{
    //  await conn.OpenAsync();
    //  using var cmd = new SqlCommand(sampleDataScript, conn);
    //  await cmd.ExecuteNonQueryAsync();
    //}

    // 4. Deploy current version DACPAC (built from the database project)
    var currentDacpacPath = Path.Combine(projectDir, "Releases.Direct_Framework", "Current", "db", "Direct_Framework.dacpac");
    var currentDacpac = DacPackage.Load(currentDacpacPath);
    try
    {
      dacServices.Deploy(currentDacpac, "Direct_Framework", true);
    }
    catch (Exception ex)
    {
      Assert.Fail($"Failed to deploy **CURRENT** version DACPAC:\n{ex.Message}");
    }

    // 5. Run pre/post deploy scripts for current version if needed
    // (Repeat as above, using current version scripts)

    // 6. Assert migration success (check schema, data, etc.)
    using var conn = new SqlConnection(ConnectionString);
    await conn.OpenAsync();
    using var cmd = new SqlCommand("SELECT COUNT(*) FROM sys.schemas WHERE name = 'omd'", conn);
    var res = await cmd.ExecuteScalarAsync();
    var count = Convert.ToInt32(res);
    Assert.IsTrue(count > 0, "Schema 'omd' should exist after migration.");
  }
}
