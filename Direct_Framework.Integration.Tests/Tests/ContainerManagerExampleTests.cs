namespace Direct_Framework.Integration.Tests.Tests;

[TestClass]
public class ContainerManagerExampleTests
{
    private string ConnectionString => SqlServerContainerManager.ConnectionString;

    [TestMethod]
    public async Task Container_Should_Be_Running_And_Accessible()
    {
        // Arrange & Act
        using var connection = new SqlConnection(ConnectionString);

        // Test basic connectivity
        var result = await connection.ExecuteScalarAsync<string>("SELECT 'Hello from SQL Server'");

        // Assert
        result.Should().Be("Hello from SQL Server");
    }

    [TestMethod]
    public async Task Database_Should_Be_Deployed_Successfully()
    {
        // Arrange & Act
        using var connection = new SqlConnection(ConnectionString);

        // Check if our schema exists
        var schemaCount = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM sys.schemas WHERE name IN ('omd', 'omd_metadata', 'omd_processing', 'omd_reporting')");

        // Assert
        schemaCount.Should().BeGreaterThan(0, "DACPAC should have deployed our custom schemas");
    }

    [TestMethod]
    public async Task GetBatch_StoredProcedure_Should_Exist()
    {
        // Arrange & Act
        using var connection = new SqlConnection(ConnectionString);

        // Check if our stored procedure exists
        var procExists = await connection.ExecuteScalarAsync<bool>(
            @"SELECT CASE WHEN EXISTS(
                SELECT 1 FROM sys.procedures p
                JOIN sys.schemas s ON p.schema_id = s.schema_id
                WHERE s.name = 'omd' AND p.name = 'GetBatch'
              ) THEN 1 ELSE 0 END");

        // Assert
        procExists.Should().BeTrue("omd.GetBatch stored procedure should exist after DACPAC deployment");
    }
}
