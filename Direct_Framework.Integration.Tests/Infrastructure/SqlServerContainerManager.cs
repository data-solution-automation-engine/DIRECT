using Microsoft.SqlServer.Dac;
using Testcontainers.MsSql;
using DotNet.Testcontainers.Builders;
using Microsoft.Data.SqlClient;

namespace Direct_Framework.Integration.Tests.Infrastructure;

/// <summary>
/// Manages the lifecycle of a shared SQL Server container for integration tests
/// Uses Podman with Microsoft SQL Server Linux images
/// </summary>
public static class SqlServerContainerManager
{
    private static MsSqlContainer? _container;
    private static string? _connectionString;
    private static readonly object _lock = new object();
    private static bool _isInitialized = false;

    /// <summary>
    /// Gets the connection string for the shared SQL Server container
    /// </summary>
    public static string ConnectionString
    {
        get
        {
            if (!_isInitialized)
                throw new InvalidOperationException("Container not initialized. Call InitializeAsync first.");
            return _connectionString!;
        }
    }

    /// <summary>
    /// Gets whether the container is initialized and ready for use
    /// </summary>
    public static bool IsInitialized => _isInitialized;

    /// <summary>
    /// Initializes the SQL Server container and deploys the database schema
    /// This method is thread-safe and can be called multiple times
    /// </summary>
    public static async Task InitializeAsync()
    {
        if (_isInitialized) return;

        lock (_lock)
        {
            if (_isInitialized) return;

            // Create the container for Linux SQL Server
            _container = new MsSqlBuilder()
                .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
                .WithPassword("P@ssword123!")
                .WithEnvironment("ACCEPT_EULA", "Y")
                .WithEnvironment("MSSQL_SA_PASSWORD", "P@ssword123!")
                .WithPortBinding(0, 1433) // Random host port
                .WithWaitStrategy(Wait.ForUnixContainer().UntilPortIsAvailable(1433))
                .WithCleanUp(true)
                .Build();
        }        // Start the container
        Console.WriteLine($"Starting SQL Server Linux container with Podman");
        Console.WriteLine($"Image: {_container.Image}");

        await _container.StartAsync();
        _connectionString = _container.GetConnectionString();

        var hostPort = _container.GetMappedPublicPort(1433);
        Console.WriteLine($"SQL Server container started on host port: {hostPort}");
        Console.WriteLine($"Container ID: {_container.Id}");
        Console.WriteLine($"Initial connection string: {_connectionString}");

        // Wait for SQL Server to be fully ready for connections
        await WaitForSqlServerReadyAsync();

        // Deploy the database schema
        await DeployDatabaseSchemaAsync();

        // Update connection string to point to the deployed database
        _connectionString = _connectionString.Replace("Database=master", "Database=Direct_Framework");
        Console.WriteLine($"Updated connection string: {_connectionString}");

        _isInitialized = true;
    }

    /// <summary>
    /// Disposes the SQL Server container
    /// </summary>
    public static async Task DisposeAsync()
    {
        if (_container != null)
        {
            await _container.DisposeAsync();
            _container = null;
            _connectionString = null;
            _isInitialized = false;
        }
    }

    /// <summary>
    /// Resets the database to a clean state by redeploying the DACPAC
    /// </summary>
    public static async Task ResetDatabaseAsync()
    {
        if (!_isInitialized)
            throw new InvalidOperationException("Container not initialized.");

        await DeployDatabaseSchemaAsync();
    }

    private static async Task DeployDatabaseSchemaAsync()
    {
        var dacpacPath = FindDacpacPath();

        if (!File.Exists(dacpacPath))
        {
            throw new FileNotFoundException(
                $"DACPAC not found at: {dacpacPath}. " +
                "Ensure the Direct_Framework project is built before running tests.");
        }

        Console.WriteLine($"Deploying DACPAC from: {dacpacPath}");
        Console.WriteLine($"Target connection: {_connectionString}");

        try
        {
            var dacpac = DacPackage.Load(dacpacPath);
            Console.WriteLine($"DACPAC loaded successfully: {dacpac.Name}");
            Console.WriteLine($"DACPAC version: {dacpac.Version}");

            var dacServices = new DacServices(_connectionString);

            // Configure deployment options
            var deployOptions = new DacDeployOptions
            {
                BlockOnPossibleDataLoss = false,
                CreateNewDatabase = true,
                DropObjectsNotInSource = true,
                VerifyDeployment = true,
                CommandTimeout = 300 // 5 minutes timeout
            };

            Console.WriteLine("Starting DACPAC deployment...");
            await Task.Run(() => dacServices.Deploy(dacpac, "Direct_Framework", upgradeExisting: true, deployOptions));
            Console.WriteLine("DACPAC deployment completed successfully");

            // Verify deployment by checking what was actually created
            await VerifyDeploymentAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"DACPAC deployment failed: {ex.GetType().Name}: {ex.Message}");
            if (ex.InnerException != null)
            {
                Console.WriteLine($"Inner exception: {ex.InnerException.GetType().Name}: {ex.InnerException.Message}");
            }
            throw;
        }
    }

    private static string FindDacpacPath()
    {
        // Try multiple possible paths
        var possiblePaths = new[]
        {
            Path.Combine("..", "..", "Direct_Framework", "bin", "Debug", "Direct_Framework.dacpac"),
            Path.Combine("..", "..", "Direct_Framework", "bin", "Release", "Direct_Framework.dacpac"),
            Path.Combine("Direct_Framework", "bin", "Debug", "Direct_Framework.dacpac"),
            Path.Combine("Direct_Framework", "bin", "Release", "Direct_Framework.dacpac"),
            Path.Combine(@"C:\repos\github\data-solution-automation-engine\DIRECT\Direct_Framework\bin\debug", "Direct_Framework.dacpac")
        };

        foreach (var path in possiblePaths)
        {
            if (File.Exists(path))
                return path;
        }

        throw new FileNotFoundException("Could not locate Direct_Framework.dacpac in any expected location.");
    }

    /// <summary>
    /// Waits for SQL Server to be fully ready to accept connections and execute commands
    /// </summary>
    private static async Task WaitForSqlServerReadyAsync()
    {
        const int maxRetries = 30;
        const int delayMs = 5000;

        for (int i = 0; i < maxRetries; i++)
        {
            try
            {
                using var connection = new Microsoft.Data.SqlClient.SqlConnection(_connectionString);
                await connection.OpenAsync();

                // Try to execute a simple query to ensure SQL Server is fully ready
                using var command = new Microsoft.Data.SqlClient.SqlCommand("SELECT 1", connection);
                await command.ExecuteScalarAsync();

                Console.WriteLine($"SQL Server is ready after {i + 1} attempts");
                return;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Attempt {i + 1}/{maxRetries}: SQL Server not ready yet - {ex.GetType().Name}: {ex.Message}");

                if (i == maxRetries - 1)
                {
                    throw new InvalidOperationException($"SQL Server did not become ready after {maxRetries} attempts", ex);
                }

                await Task.Delay(delayMs);
            }
        }
    }

    /// <summary>
    /// Verifies that the DACPAC deployment was successful by checking for expected schemas and objects
    /// </summary>
    private static async Task VerifyDeploymentAsync()
    {
        try
        {
            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            // Check databases
            using var dbCommand = new SqlCommand("SELECT name FROM sys.databases WHERE name != 'master' AND name != 'tempdb' AND name != 'model' AND name != 'msdb'", connection);
            using var dbReader = await dbCommand.ExecuteReaderAsync();
            Console.WriteLine("Databases found:");
            while (await dbReader.ReadAsync())
            {
                Console.WriteLine($"  - {dbReader.GetString(0)}");
            }
            dbReader.Close();

            // Switch to the Direct_Framework database
            connection.ChangeDatabase("Direct_Framework");

            // Check schemas
            using var schemaCommand = new SqlCommand("SELECT name FROM sys.schemas WHERE name IN ('omd', 'omd_metadata', 'omd_processing', 'omd_reporting')", connection);
            using var schemaReader = await schemaCommand.ExecuteReaderAsync();
            Console.WriteLine("Expected schemas found:");
            while (await schemaReader.ReadAsync())
            {
                Console.WriteLine($"  - {schemaReader.GetString(0)}");
            }
            schemaReader.Close();

            // Check for the specific stored procedure
            using var procCommand = new SqlCommand(@"
                SELECT s.name as schema_name, p.name as procedure_name
                FROM sys.procedures p
                JOIN sys.schemas s ON p.schema_id = s.schema_id
                WHERE s.name = 'omd' AND p.name = 'GetBatch'", connection);
            using var procReader = await procCommand.ExecuteReaderAsync();
            Console.WriteLine("omd.GetBatch procedure check:");
            if (await procReader.ReadAsync())
            {
                Console.WriteLine($"  Found: {procReader.GetString(0)}.{procReader.GetString(1)}");
            }
            else
            {
                Console.WriteLine("  NOT FOUND");
            }
            procReader.Close();

            // List all procedures in omd schema
            using var allProcCommand = new SqlCommand(@"
                SELECT s.name as schema_name, p.name as procedure_name
                FROM sys.procedures p
                JOIN sys.schemas s ON p.schema_id = s.schema_id
                WHERE s.name = 'omd'", connection);
            using var allProcReader = await allProcCommand.ExecuteReaderAsync();
            Console.WriteLine("All procedures in omd schema:");
            while (await allProcReader.ReadAsync())
            {
                Console.WriteLine($"  - {allProcReader.GetString(0)}.{allProcReader.GetString(1)}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Verification failed: {ex.Message}");
        }
    }
}
