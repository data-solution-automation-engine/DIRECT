using IntegrationTests.Infrastructure;

namespace IntegrationTests.Tests.StoredProcedureTests;

[TestClass]
public class OmdGetBatchTests : BaseTestContainer
{
  [TestInitialize]
  public async Task TestInitialize()
  {
    await ContainerManager.InitializeAsync();
  }

  [TestCleanup]
  public async Task TestCleanup()
  {
    await ContainerManager.DisposeAsync();
  }

  [ClassInitialize]
  public static async Task ClassInitialize(TestContext context)
  {
    await Task.Yield();
    // Container is already initialized by GlobalTestSetup
    // Optionally reset database state for this test class
    // await SqlServerContainerManager.ResetDatabaseAsync();
  }

  [TestMethod]
  public async Task OmdBatch_ReturnsY_OnSuccess()
  {
    using var conn = new SqlConnection(ContainerManager.DirectConnectionString);

    var parameters = new DynamicParameters();
    parameters.Add("@BatchCode", "Default Batch");
    parameters.Add("@Debug", "N");
    parameters.Add("@BatchDetails", dbType: System.Data.DbType.String, direction: System.Data.ParameterDirection.Output, size: -1);
    parameters.Add("@SuccessIndicator", dbType: System.Data.DbType.String, direction: System.Data.ParameterDirection.Output, size: 1);
    parameters.Add("@MessageLog", dbType: System.Data.DbType.String, direction: System.Data.ParameterDirection.Output, size: -1);

    await conn.ExecuteAsync("EXEC [omd].[GetBatch] @BatchCode, @Debug, @BatchDetails OUTPUT, @SuccessIndicator OUTPUT, @MessageLog OUTPUT", parameters);

    var successIndicator = parameters.Get<string>("@SuccessIndicator");
    var messageLog = parameters.Get<string>("@MessageLog");

    Assert.AreEqual("Y", successIndicator);
  }
}
