using DotNet.Testcontainers.Builders;

using Microsoft.SqlServer.Dac;

using Testcontainers.MsSql;

namespace IntegrationTests.Infrastructure;

/// <summary>
/// Manages the lifecycle of a shared SQL Server container for integration tests
/// Uses Podman with Microsoft SQL Server Linux images
/// </summary>
public static class SqlServerContainerManager
{
  private static MsSqlContainer? _container;
  private static string? _connectionString;
  private static readonly Lock _lock = new();
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
    }
    // Start the container
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
    await DeployDatabaseSchemaAsync("next");

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

    await DeployDatabaseSchemaAsync("next");
  }

  public static async Task PopulateDatabaseAsync()
  {
    // add some initial data to the database
    if (!_isInitialized)
      throw new InvalidOperationException("Container not initialized.");
    int moduleId;
    int batchId;
    int moduleInstanceId;
    //int batchInstanceId;

    var batch = new
    {
      BatchCode = "b_INGESTION_EXAMPLE",
      BatchType = "Ingestion",
      FrequencyCode = "On-demand",
      ActiveIndicator = "Y",
      BatchDescription = "Example batch for ingestion",
    };
    // insert the batch into the database
    using var connection = new SqlConnection(_connectionString);
    await connection.OpenAsync();
    using var command = new SqlCommand(
        @"INSERT INTO omd.BATCH (BATCH_CODE, BATCH_TYPE, FREQUENCY_CODE, ACTIVE_INDICATOR, BATCH_DESCRIPTION)
          VALUES (@BatchCode, @BatchType, @FrequencyCode, @ActiveIndicator, @BatchDescription);
          SELECT SCOPE_IDENTITY();", connection);

    command.Parameters.AddWithValue("@BatchCode", batch.BatchCode);
    command.Parameters.AddWithValue("@BatchType", batch.BatchType);
    command.Parameters.AddWithValue("@FrequencyCode", batch.FrequencyCode);
    command.Parameters.AddWithValue("@ActiveIndicator", batch.ActiveIndicator);
    command.Parameters.AddWithValue("@BatchDescription", batch.BatchDescription);

    // Execute the insert and get the identity value
    var result = await command.ExecuteScalarAsync();
    batchId = Convert.ToInt32(result);

    Console.WriteLine($"Inserted batch: {batch.BatchCode} with id: {batchId}");

    var module = new
    {
      ModuleCode = "M_INGESTION_EXAMPLE",
      ModuleType = "Ingestion",
      DataObjectSource = "SourceObject",
      DataObjectTarget = "TargetObject",
      AreaCode = "STG",
      FrequencyCode = "On-demand",
      ModuleDescription = "Example module for ingestion",
      ActiveIndicator = "Y",
      Executable = "SELECT SYSUTCDATETIME() AS NowUtc"
    };
    // check if a module with the same code already exists
    using var checkCommand = new SqlCommand(
        "SELECT COUNT(*) FROM omd.MODULE WHERE MODULE_CODE = @ModuleCode", connection);
    checkCommand.Parameters.AddWithValue("@ModuleCode", module.ModuleCode);
    var exists = (int?)await checkCommand.ExecuteScalarAsync() > 0;
    if (exists)
    {
      Console.WriteLine($"Module with code {module.ModuleCode} already exists. Skipping insert.");
      // get the id of the existing module
      using var getModuleIdCommand = new SqlCommand(
          "SELECT MODULE_ID FROM omd.MODULE WHERE MODULE_CODE = @ModuleCode", connection);
      getModuleIdCommand.Parameters.AddWithValue("@ModuleCode", module.ModuleCode);
      moduleId = (int?)await getModuleIdCommand.ExecuteScalarAsync() ?? 0;
    }
    else
    {
      // insert the module into the database and get the identity value
      using var moduleCommand = new SqlCommand(
          @"INSERT INTO omd.MODULE (MODULE_CODE, MODULE_TYPE, DATA_OBJECT_SOURCE, DATA_OBJECT_TARGET, AREA_CODE, FREQUENCY_CODE, MODULE_DESCRIPTION, ACTIVE_INDICATOR, EXECUTABLE) 
                VALUES (@ModuleCode, @ModuleType, @DataObjectSource, @DataObjectTarget, @AreaCode, @FrequencyCode, @ModuleDescription, @ActiveIndicator, @Executable);
                SELECT SCOPE_IDENTITY();", connection);
      moduleCommand.Parameters.AddWithValue("@ModuleCode", module.ModuleCode);
      moduleCommand.Parameters.AddWithValue("@ModuleType", module.ModuleType);
      moduleCommand.Parameters.AddWithValue("@DataObjectSource", module.DataObjectSource);
      moduleCommand.Parameters.AddWithValue("@DataObjectTarget", module.DataObjectTarget);
      moduleCommand.Parameters.AddWithValue("@AreaCode", module.AreaCode);
      moduleCommand.Parameters.AddWithValue("@FrequencyCode", module.FrequencyCode);
      moduleCommand.Parameters.AddWithValue("@ModuleDescription", module.ModuleDescription);
      moduleCommand.Parameters.AddWithValue("@ActiveIndicator", module.ActiveIndicator);
      moduleCommand.Parameters.AddWithValue("@Executable", module.Executable);
      var moduleResult = await moduleCommand.ExecuteScalarAsync();
      moduleId = Convert.ToInt32(moduleResult);
      Console.WriteLine($"Inserted module: {module.ModuleCode} with id: {moduleId}");
    }

    var moduleInstance = new
    {
      ModuleId = moduleId,
      BatchInstanceId = 0,
      StartTimestamp = DateTime.UtcNow,
      EndTimestamp = (DateTime?)null,
      InternalProcessingCode = "Proceed",
      NextRunStatusCode = "Proceed",
      ExecutionStatusCode = "Succeeded",
      ExecutionContext = (string?)null,
      RowsInput = (long?)10,
      RowsInserted = (long?)10,
      RowsUpdated = (long?)0,
      RowsDeleted = (long?)0,
      RowsDiscarded = (long?)0,
      RowsRejected = (long?)0,
      ExecutedCodeChecksum = new byte[64]
    };

    // insert the module instance into the database and get the identity value
    using var moduleInstanceCommand = new SqlCommand(
        @"INSERT INTO omd.MODULE_INSTANCE (MODULE_ID, BATCH_INSTANCE_ID, START_TIMESTAMP, END_TIMESTAMP, INTERNAL_PROCESSING_CODE, NEXT_RUN_STATUS_CODE, EXECUTION_STATUS_CODE, EXECUTION_CONTEXT, ROWS_INPUT, ROWS_INSERTED, ROWS_UPDATED, ROWS_DELETED, ROWS_DISCARDED, ROWS_REJECTED, EXECUTED_CODE_CHECKSUM) 
              VALUES (@ModuleId, @BatchInstanceId, @StartTimestamp, @EndTimestamp, @InternalProcessingCode, @NextRunStatusCode, @ExecutionStatusCode, @ExecutionContext, @RowsInput, @RowsInserted, @RowsUpdated, @RowsDeleted, @RowsDiscarded, @RowsRejected, @ExecutedCodeChecksum);
              SELECT SCOPE_IDENTITY();", connection);
    moduleInstanceCommand.Parameters.AddWithValue("@ModuleId", moduleInstance.ModuleId);
    moduleInstanceCommand.Parameters.AddWithValue("@BatchInstanceId", 0);
    moduleInstanceCommand.Parameters.AddWithValue("@StartTimestamp", moduleInstance.StartTimestamp);
    moduleInstanceCommand.Parameters.AddWithValue("@EndTimestamp", moduleInstance.EndTimestamp ?? (object)DBNull.Value);
    moduleInstanceCommand.Parameters.AddWithValue("@InternalProcessingCode", moduleInstance.InternalProcessingCode);
    moduleInstanceCommand.Parameters.AddWithValue("@NextRunStatusCode", moduleInstance.NextRunStatusCode);
    moduleInstanceCommand.Parameters.AddWithValue("@ExecutionStatusCode", moduleInstance.ExecutionStatusCode);
    moduleInstanceCommand.Parameters.AddWithValue("@ExecutionContext", moduleInstance.ExecutionContext ?? (object)DBNull.Value);
    moduleInstanceCommand.Parameters.AddWithValue("@RowsInput", moduleInstance.RowsInput ?? (object)DBNull.Value);
    moduleInstanceCommand.Parameters.AddWithValue("@RowsInserted", moduleInstance.RowsInserted ?? (object)DBNull.Value);
    moduleInstanceCommand.Parameters.AddWithValue("@RowsUpdated", moduleInstance.RowsUpdated ?? (object)DBNull.Value);
    moduleInstanceCommand.Parameters.AddWithValue("@RowsDeleted", moduleInstance.RowsDeleted ?? (object)DBNull.Value);
    moduleInstanceCommand.Parameters.AddWithValue("@RowsDiscarded", moduleInstance.RowsDiscarded ?? (object)DBNull.Value);
    moduleInstanceCommand.Parameters.AddWithValue("@RowsRejected", moduleInstance.RowsRejected ?? (object)DBNull.Value);
    moduleInstanceCommand.Parameters.AddWithValue("@ExecutedCodeChecksum", moduleInstance.ExecutedCodeChecksum ?? (object)DBNull.Value);
    var moduleInstanceResult = await moduleInstanceCommand.ExecuteScalarAsync();
    moduleInstanceId = Convert.ToInt32(moduleInstanceResult);
    Console.WriteLine($"Inserted module instance with id: {moduleInstanceId}");
  }

  private static async Task DeployDatabaseSchemaAsync(string version = "next")
  {
    var dacpacPath = FindDacpacPath(version);

    if (!File.Exists(dacpacPath))
    {
      throw new FileNotFoundException(
          $"DACPAC not found at: {dacpacPath}. " +
          "Ensure the Direct_Framework project is built before running tests.");
    }

    Console.WriteLine($"Deploying DACPAC '{version}' from: {dacpacPath}");
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

  private static string FindDacpacPath(string version = "next")
  {
    // Get the output directory (e.g., bin\Debug\net10.0)
    var outputDir = AppContext.BaseDirectory;

    // Traverse up to the project folder
    var projectDir = Directory.GetParent(outputDir)!.Parent!.Parent!.Parent!.Parent!.FullName;

    // 1. Deploy previous version DACPAC
    var dacpacPath = Path.Combine(projectDir, "Releases.Direct_Framework", version, "db", "Direct_Framework.dacpac");

    if (File.Exists(dacpacPath))
    {
      return dacpacPath;
    }

    throw new FileNotFoundException($"Could not locate '{version}' Direct_Framework.dacpac. Please validate the reference location and build the main project.");
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
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        // Try to execute a simple query to ensure SQL Server is fully ready
        using var command = new SqlCommand("SELECT 1", connection);
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
