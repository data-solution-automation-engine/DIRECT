namespace Direct_Framework.Integration.Tests.Tests;

[TestClass]
public class OrderProcedureTests
{
  private string ConnectionString => SqlServerContainerManager.ConnectionString;

  [ClassInitialize]
  public static async Task ClassInitialize(TestContext context)
  {
    await Task.Yield();
    // Container is already initialized by GlobalTestSetup
    // Optionally reset database state for this test class
    // await SqlServerContainerManager.ResetDatabaseAsync();
  }

  [TestMethod]
  public async Task OmdBatch_returns_y_on_success()
  {
    using var conn = new SqlConnection(ConnectionString);

    var parameters = new DynamicParameters();
    parameters.Add("@BatchCode", "Default Batch");
    parameters.Add("@Debug", "N");
    parameters.Add("@BatchDetails", dbType: System.Data.DbType.String, direction: System.Data.ParameterDirection.Output, size: -1);
    parameters.Add("@SuccessIndicator", dbType: System.Data.DbType.String, direction: System.Data.ParameterDirection.Output, size: 1);
    parameters.Add("@MessageLog", dbType: System.Data.DbType.String, direction: System.Data.ParameterDirection.Output, size: -1);

    await conn.ExecuteAsync("EXEC [omd].[GetBatch] @BatchCode, @Debug, @BatchDetails OUTPUT, @SuccessIndicator OUTPUT, @MessageLog OUTPUT", parameters);

    var successIndicator = parameters.Get<string>("@SuccessIndicator");
    var messageLog = parameters.Get<string>("@MessageLog");

    successIndicator.Should().Be("Y");
  }
}
