using Direct_Framework.Integration.Tests.Infrastructure;

namespace Direct_Framework.Integration.Tests;

/// <summary>
/// Lightweight fixture that provides access to the shared SQL Server container
/// </summary>
public sealed class MsSqlFixture
{
    /// <summary>
    /// Gets the connection string for the shared test database
    /// </summary>
    public string ConnectionString => SqlServerContainerManager.ConnectionString;

    /// <summary>
    /// Optional: Reset database to clean state before each test class
    /// Call this from [ClassInitialize] if you need a fresh database state
    /// </summary>
    public async Task ResetDatabaseAsync()
    {
        await SqlServerContainerManager.ResetDatabaseAsync();
    }
}
