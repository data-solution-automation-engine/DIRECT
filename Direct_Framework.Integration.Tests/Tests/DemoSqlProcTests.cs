using Dapper;
using FluentAssertions;
using System.Data.SqlClient;
using Xunit;

public class OrderProcedureTests : IClassFixture<MsSqlFixture>
{
    readonly string _cs;
    public OrderProcedureTests(MsSqlFixture f) => _cs = f.ConnectionString;

    [Fact]
    public async Task UpsertOrder_returns_zero_on_success()
    {
        using var conn = new SqlConnection(_cs);

        var result = await conn.ExecuteScalarAsync<int>(
            "EXEC dbo.UpsertOrder @OrderId = @Id, @Amount = @Amt",
            new { Id = 42, Amt = 100 });

        result.Should().Be(0);
    }
}
