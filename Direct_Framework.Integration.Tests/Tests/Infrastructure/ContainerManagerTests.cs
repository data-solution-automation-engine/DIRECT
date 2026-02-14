using Testcontainers.MsSql;

namespace IntegrationTests.Tests.Infrastructure;

[TestClass]
public class ContainerManagerTests : BaseTestContainer
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


  [TestMethod]
  public async Task Container_Should_Be_Running_And_Accessible()
  {
    // Arrange
    using var connection = new SqlConnection(ContainerManager.MasterConnectionString);

    // Act
    // Test SQL Instance query connectivity
    var result = await connection.ExecuteScalarAsync<string>(
@"
SELECT 'Hello from SQL Server'
");

    // Assert
    Assert.IsNotNull(result, "SQL Server instance should be accessible and respond to queries. Result is null.");
    Assert.AreEqual("Hello from SQL Server", result, "SQL Server instance should respond with deterministic results to queries. Expected query result not received.");
  }

  [TestMethod]
  public async Task Database_Should_Be_Deployed_Successfully()
  {
    // Arrange
    using var connection = new SqlConnection(ContainerManager.DirectConnectionString);

    // Act
    // Check if any of our expected schema exists
    var schemaCount = await connection.ExecuteScalarAsync<int>(
@"
SELECT COUNT(*)
FROM sys.schemas
WHERE name IN ('omd', 'omd_metadata', 'omd_processing', 'omd_reporting')
");

    // Assert
    Assert.IsGreaterThan(0, schemaCount, "DACPAC should have deployed our custom schemas. No schemas found.");
  }

  [TestMethod]
  public async Task GetBatch_StoredProcedure_Should_Exist()
  {
    // Arrange
    using var connection = new SqlConnection(ContainerManager.DirectConnectionString);

    // Act
    // Check if the 'omd.GetBatch' stored procedure exists
    var procExists = await connection.ExecuteScalarAsync<bool>(
@"
SELECT CASE WHEN EXISTS (
  SELECT 1 FROM sys.procedures p
  JOIN sys.schemas s ON p.schema_id = s.schema_id
  WHERE s.name = 'omd' AND p.name = 'GetBatch'
)
THEN 1 ELSE 0 END
");

    // Assert
    Assert.IsTrue(procExists, "omd.GetBatch stored procedure should exist after DACPAC deployment. Procedure not found.");
  }
}
