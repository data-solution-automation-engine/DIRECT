using Microsoft.VisualStudio.TestTools.UnitTesting;
using Direct_Framework.Integration.Tests.Infrastructure;

namespace Direct_Framework.Integration.Tests;

/// <summary>
/// Global test setup that manages a single SQL Server container for all integration tests
/// </summary>
[TestClass]
public sealed class GlobalTestSetup
{
    /// <summary>
    /// Gets the connection string for the shared test database
    /// </summary>
    public static string ConnectionString => SqlServerContainerManager.ConnectionString;

    /// <summary>
    /// Initializes the shared SQL Server container and deploys the DACPAC
    /// This runs once per test assembly
    /// </summary>
    [AssemblyInitialize]
    public static async Task AssemblyInitialize(TestContext context)
    {
        await SqlServerContainerManager.InitializeAsync();
    }

    /// <summary>
    /// Cleans up the shared container
    /// This runs once per test assembly
    /// </summary>
    [AssemblyCleanup]
    public static async Task AssemblyCleanup()
    {
        await SqlServerContainerManager.DisposeAsync();
    }

    /// <summary>
    /// Resets the database to a clean state
    /// Can be called by individual test classes that need a fresh database
    /// </summary>
    public static async Task ResetDatabaseAsync()
    {
        await SqlServerContainerManager.ResetDatabaseAsync();
    }
}
