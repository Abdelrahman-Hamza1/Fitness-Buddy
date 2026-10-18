using FitnessBuddy.BuildingBlocks.Persistence;
using Npgsql;
using FitnessBuddy.Modules.UserData.Infrastructure;
using FitnessBuddy.Modules.Identity.Infrastructure;
using Testcontainers.PostgreSql;

[assembly: Xunit.v3.Parallelization(Mode = Xunit.Sdk.ParallelMode.None)]
[assembly: AssemblyFixture(typeof(FitnessBuddy.Persistence.Tests.PostgresFixture))]

namespace FitnessBuddy.Persistence.Tests;

public sealed class PostgresFixture : IAsyncLifetime
{
    public const string Image = "postgres:18.6-bookworm@sha256:afc7e2d441324c0388fa80c3d24f733b4194a4eb7f47dd8ee2b08eb1a24a647c";
    private readonly PostgreSqlContainer container = new PostgreSqlBuilder(Image)
        .WithCommand("-c", "log_min_messages=fatal", "-c", "log_min_error_statement=panic", "-c", "log_error_verbosity=terse",
            "-c", "log_statement=none", "-c", "log_parameter_max_length=0", "-c", "log_parameter_max_length_on_error=0")
        .WithDatabase("fitness_buddy").WithUsername("postgres").WithPassword("test-admin-only").Build();

    public NpgsqlDataSource App { get; private set; } = null!;
    public string MigratorConnection { get; private set; } = "";
    public string AppConnection { get; private set; } = "";
    public MigrationRunner Runner { get; private set; } = null!;

    public async ValueTask InitializeAsync()
    {
        await container.StartAsync(TestContext.Current.CancellationToken);
        await using var admin = NpgsqlDataSource.Create(container.GetConnectionString());
        await using var command = admin.CreateCommand(await File.ReadAllTextAsync(Path.Combine(AppContext.BaseDirectory, "bootstrap.sql"), TestContext.Current.CancellationToken));
        await command.ExecuteNonQueryAsync(TestContext.Current.CancellationToken);
        var appSettings = new NpgsqlConnectionStringBuilder(container.GetConnectionString())
        {
            Username = "fb_app",
            Password = "local-app-only",
            MaxPoolSize = 10,
        };
        AppConnection = appSettings.ConnectionString;
        App = DatabaseConfiguration.CreateSource(AppConnection);
        appSettings.Username = "fb_migrator";
        appSettings.Password = "local-migrator-only";
        MigratorConnection = appSettings.ConnectionString;
        Runner = new MigrationRunner([
            new ModuleMigration("identity", connection => new IdentityContext(DatabaseConfiguration.ContextOptions<IdentityContext>(connection, "identity"))),
            new ModuleMigration("ops", connection => new OpsDbContext(DatabaseConfiguration.ContextOptions<OpsDbContext>(connection, "ops"))),
            new ModuleMigration("userdata", connection => new UserDataContext(DatabaseConfiguration.ContextOptions<UserDataContext>(connection, "userdata"))),
            new ModuleMigration("testdata", connection => new SampleContext(DatabaseConfiguration.ContextOptions<SampleContext>(connection, "testdata"))),
        ]);
        await Runner.RunAsync(MigratorConnection, TestContext.Current.CancellationToken);
    }

    public Task PauseAsync() => container.PauseAsync(TestContext.Current.CancellationToken);
    public Task UnpauseAsync() => container.UnpauseAsync(CancellationToken.None);

    public async Task<string> LogsAsync()
    {
        var (stdout, stderr) = await container.GetLogsAsync(ct: TestContext.Current.CancellationToken);
        return stdout + stderr;
    }

    public async Task TerminateAsync(int processId)
    {
        await using var admin = NpgsqlDataSource.Create(container.GetConnectionString());
        await using var terminate = admin.CreateCommand("SELECT pg_terminate_backend($1)");
        terminate.Parameters.AddWithValue(processId);
        await terminate.ExecuteNonQueryAsync(TestContext.Current.CancellationToken);
    }

    public async Task<DatabaseSession> SessionAsync(Guid? userId = null)
    {
        var session = new DatabaseSession();
        await session.BeginAsync(App, userId, TestContext.Current.CancellationToken);
        return session;
    }

    public async ValueTask DisposeAsync()
    {
        await App.DisposeAsync();
        await container.DisposeAsync();
    }
}
