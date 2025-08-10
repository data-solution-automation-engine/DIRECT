
namespace IntegrationTests.Tests.StoredProcedureTests;

[TestClass]
public class OmdSetSourceControlValuesTests : BaseTestContainer
{
  [ClassInitialize]
  public static async Task ClassInitialize(TestContext context)
  {
    await Task.Yield();
    // TODO: explore if more convenient to have a single static container manager
    // for the class, shared across tests, or to use one for each test like current
  }

  [ClassCleanup]
  public static async Task ClassCleanup()
  {
    await Task.Yield();
    // placeholder
  }

  [TestInitialize]
  public async Task TestInitialize()
  {
    await ContainerManager.InitializeAsync();
    await ContainerManager.PopulateDatabaseAsync();
  }

  [TestCleanup]
  public async Task TestCleanup()
  {
    await ContainerManager.DisposeAsync();
  }

  private string SpName => "[omd].[SetSourceControlValues]";
  private string TableName => "[omd].[SOURCE_CONTROL]";

  private static DynamicParameters ToDynamicParameters(OmdSetSourceControlValuesParams param)
  {
    var parameters = new DynamicParameters();
    parameters.Add("@ModuleInstanceId", param.ModuleInstanceId);
    parameters.Add("@StartValue", param.StartValue, dbType: System.Data.DbType.String, size: 100);
    parameters.Add("@EndValue", param.EndValue, dbType: System.Data.DbType.String, size: 100);
    parameters.Add("@Debug", param.Debug);
    parameters.Add("@SourceControlId", dbType: System.Data.DbType.Int64, direction: System.Data.ParameterDirection.Output);
    parameters.Add("@SuccessIndicator", dbType: System.Data.DbType.String, direction: System.Data.ParameterDirection.Output, size: 1);
    parameters.Add("@MessageLog", dbType: System.Data.DbType.String, direction: System.Data.ParameterDirection.Output, size: -1);
    parameters.Add("@ReturnCode", dbType: System.Data.DbType.Int32, direction: System.Data.ParameterDirection.ReturnValue);
    return parameters;
  }

  private static void MapOutputParameters(DynamicParameters dapperParams, OmdSetSourceControlValuesParams param)
  {
    param.SourceControlId = dapperParams.Get<long?>("@SourceControlId");
    param.SuccessIndicator = dapperParams.Get<string?>("@SuccessIndicator");
    param.MessageLog = dapperParams.Get<string?>("@MessageLog");
  }


  [TestMethod]
  public async Task OmdSetSourceControlValues_Returns0AndInsertsRow_OnSuccess()
  {
    // Arrange
    var param = new OmdSetSourceControlValuesParams
    {
      ModuleInstanceId = 1,
      StartValue = "2025-01-01",
      EndValue = "2025-01-02",
      Debug = "N"
    };

    using var conn = new SqlConnection(ContainerManager.DirectConnectionString);
    var dapperParams = ToDynamicParameters(param);

    // Act
    await conn.ExecuteAsync(SpName, dapperParams, commandType: System.Data.CommandType.StoredProcedure);
    MapOutputParameters(dapperParams, param);
    int returnCode = dapperParams.Get<int>("@ReturnCode");

    // Assert
    Assert.AreEqual(0, returnCode, $"Stored procedure should return 0 on success. MessageLog: {param.MessageLog}");
    Assert.AreEqual("Y", param.SuccessIndicator, $"Expected SuccessIndicator 'Y'. MessageLog: {param.MessageLog}");
    Assert.IsNotNull(param.SourceControlId, "SourceControlId should not be null on success.");
    Assert.IsGreaterThan(0L, param.SourceControlId ?? 0L, "SourceControlId should be a valid, positive bigint/long integer.");

    // Arrange
    var query = $@"
            SELECT COUNT(*)
            FROM {TableName}
            WHERE [SOURCE_CONTROL_ID] = @SourceControlId
        ";
    // Act
    var count = await conn.ExecuteScalarAsync<int>(query, new { param.SourceControlId });

    // Assert
    Assert.AreEqual(1, count, $"returned SourceControlId value should exist in [SOURCE_CONTROL_ID] in the {TableName} table.");

    // Arrange
    // Check if the inserted row has correct values
    query = $@"
            SELECT COUNT(*)
            FROM {TableName}
            WHERE [SOURCE_CONTROL_ID] = @SourceControlId
              AND [START_VALUE] = @StartValue
              AND [END_VALUE] = @EndValue
        ";

    // Act
    count = await conn.ExecuteScalarAsync<int>(query, new
    {
      param.SourceControlId,
      param.StartValue,
      param.EndValue
    });

    // Assert
    Assert.AreEqual(1, count, $"Set values should match what is in the {TableName} table.");
  }

  [TestMethod]
  public async Task OmdSetSourceControlValues_ReturnsNAndNoRow_WhenModuleInstanceIdIsNull()
  {
    // Arrange
    var param = new OmdSetSourceControlValuesParams
    {
      ModuleInstanceId = 999, // Invalid
      StartValue = "2025-01-01",
      EndValue = "2025-01-02",
      Debug = "N"
    };

    using var conn = new SqlConnection(ContainerManager.DirectConnectionString);
    var dapperParams = ToDynamicParameters(param);

    // Act
    await conn.ExecuteAsync(SpName, dapperParams, commandType: System.Data.CommandType.StoredProcedure);
    MapOutputParameters(dapperParams, param);
    int returnCode = dapperParams.Get<int>("@ReturnCode");

    // Assert
    Assert.AreNotEqual(0, returnCode, $"Should not return 0 for invalid ModuleInstanceId. MessageLog: {param.MessageLog}");
    Assert.AreEqual("N", param.SuccessIndicator, $"Expected SuccessIndicator 'N' for invalid ModuleInstanceId. MessageLog: {param.MessageLog}");
    Assert.IsNull(param.SourceControlId, "SourceControlId should be null for invalid ModuleInstanceId.");
  }

  [TestMethod]
  public async Task OmdSetSourceControlValues_ReturnsNAndNoRow_WhenStartValueIsNull()
  {
    // Arrange
    var param = new OmdSetSourceControlValuesParams
    {
      ModuleInstanceId = 1,
      StartValue = null, // Invalid
      EndValue = "2025-01-02",
      Debug = "N"
    };

    using var conn = new SqlConnection(ContainerManager.DirectConnectionString);
    var dapperParams = ToDynamicParameters(param);

    // Act
    await conn.ExecuteAsync(SpName, dapperParams, commandType: System.Data.CommandType.StoredProcedure);
    MapOutputParameters(dapperParams, param);
    int returnCode = dapperParams.Get<int>("@ReturnCode");

    // Assert
    Assert.AreNotEqual(0, returnCode, $"Should not return 0 for null StartValue. MessageLog: {param.MessageLog}");
    Assert.AreEqual("N", param.SuccessIndicator, $"Expected SuccessIndicator 'N' for null StartValue. MessageLog: {param.MessageLog}");
    Assert.IsNull(param.SourceControlId, "SourceControlId should be null for null StartValue.");
  }

  [TestMethod]
  public async Task OmdSetSourceControlValues_ReturnsNAndNoRow_WhenModuleInstanceIdNotFound()
  {
    // Arrange
    var param = new OmdSetSourceControlValuesParams
    {
      ModuleInstanceId = 999999, // Assumed not to exist
      StartValue = "2025-01-01",
      EndValue = "2025-01-02",
      Debug = "N"
    };

    using var conn = new SqlConnection(ContainerManager.DirectConnectionString);
    var dapperParams = ToDynamicParameters(param);

    // Act
    await conn.ExecuteAsync(SpName, dapperParams, commandType: System.Data.CommandType.StoredProcedure);
    MapOutputParameters(dapperParams, param);
    int returnCode = dapperParams.Get<int>("@ReturnCode");

    // Assert
    Assert.AreNotEqual(0, returnCode, $"Should not return 0 for non-existent ModuleInstanceId. MessageLog: {param.MessageLog}");
    Assert.AreEqual("N", param.SuccessIndicator, $"Expected SuccessIndicator 'N' for non-existent ModuleInstanceId. MessageLog: {param.MessageLog}");
    Assert.IsNull(param.SourceControlId, "SourceControlId should be null for non-existent ModuleInstanceId.");
  }
}

// See references for test to code for assistants
// See: Direct_Framework\Stored Procedures\omd.SetSourceControlValues.sql
// See: Direct_Framework\Tables\omd.SOURCE_CONTROL.sql
// See: Direct_Framework.Integration.Tests\StoredProcedureValueParams\OmdSetSourceControlValuesParams.cs
