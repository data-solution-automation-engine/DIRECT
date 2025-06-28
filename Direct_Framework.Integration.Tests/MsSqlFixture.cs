using Dapper;
using DotNet.Testcontainers.Builders;
using DotNet.Testcontainers.Containers;
using Microsoft.SqlServer.Dac;
using Xunit;

public sealed class MsSqlFixture : IAsyncLifetime
{
    public string ConnectionString => _container.GetConnectionString();
    readonly MsSqlContainer _container =
        new MsSqlBuilder().WithPassword("P@ssword123").Build();

    public async Task InitializeAsync()
    {
        await _container.StartAsync();

        // load the production DACPAC
        var dacpac = DacPackage.Load(
            Path.Combine("..", "..", "src", "MyDatabase", "bin", "Debug",
                         "MyDatabase.dacpac"));

        var svc = new DacServices(ConnectionString);
        await Task.Run(() =>
            svc.Deploy(dacpac, "MyDatabase", upgradeExisting: true));
    }

    public Task DisposeAsync() => _container.DisposeAsync().AsTask();
}
