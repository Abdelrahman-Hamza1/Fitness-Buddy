using Npgsql;

namespace FitnessBuddy.Persistence.Tests.Admin;

/// <summary>
/// A private, fully migrated database for remote-config tests. Published versions are append-only and change the 426 gate,
/// so these tests never publish into the shared database other tests use.
/// </summary>
internal sealed class ConfigDatabase(PostgresFixture postgres, string name) : IAsyncDisposable
{
    public string Migrator { get; private set; } = "";
    public string App => new NpgsqlConnectionStringBuilder(postgres.AppConnection) { Database = name }.ConnectionString;
    public string Admin => new NpgsqlConnectionStringBuilder(postgres.AdminConnection) { Database = name }.ConnectionString;

    public static async Task<ConfigDatabase> CreateAsync(PostgresFixture postgres)
    {
        var database = new ConfigDatabase(postgres, "fb_upgrade_" + Guid.NewGuid().ToString("N"));
        database.Migrator = await postgres.CreateUpgradeDatabaseAsync(name: database.Name);
        await postgres.Runner.RunAsync(database.Migrator, TestContext.Current.CancellationToken);
        return database;
    }

    public string Name => name;

    public async ValueTask DisposeAsync() => await postgres.DropUpgradeDatabaseAsync(name);
}
