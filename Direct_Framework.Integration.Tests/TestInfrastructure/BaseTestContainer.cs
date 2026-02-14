using DotNet.Testcontainers.Builders;

using Testcontainers.MsSql;

namespace IntegrationTests.Infrastructure;

public abstract class BaseTestContainer : IDisposable
{
  protected SqlServerContainerManager ContainerManager { get; private set; }
  string MasterConnectionString => ContainerManager.MasterConnectionString;
  string DirectConnectionString => ContainerManager.DirectConnectionString;

  /// <summary>
  /// ctor
  /// </summary>
  protected BaseTestContainer()
  {
    // Initialize the container manager and container
    ContainerManager = new SqlServerContainerManager();
  }

  public void Dispose()
  {
    // Dispose of the container after the test class is done
    Console.WriteLine("Stopping SQL Server container...");
    ContainerManager?.DisposeAsync().GetAwaiter().GetResult();
  }
}
