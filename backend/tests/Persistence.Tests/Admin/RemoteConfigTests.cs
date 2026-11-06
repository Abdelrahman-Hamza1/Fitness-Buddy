using System.Net;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Results;
using FitnessBuddy.Modules.Account.Contracts;
using FitnessBuddy.Modules.Account.Infrastructure;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23 WP5 (T7a–T7c): remote config moves to versioned rows with the same /v1/config response; publish and rollback change
// what the API and its 426 gate serve; the configuration override wins even with the database down.
[Trait("Req", "AD-012")]
[Trait("Req", "AD-006")]
public sealed class RemoteConfigTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>Non-default values for every part of the document (R#2).</summary>
    private static Dictionary<string, string?> NonDefault(ConfigDatabase database) => new()
    {
        ["ConnectionStrings:Application"] = database.App,
        ["Clients:MinimumAppVersion"] = "0.2.0",
        ["Account:ClientConfig:FeatureFlags:buddy.photo_enabled"] = "true",
        ["Account:ClientConfig:Thresholds:proposalQuestionRelativeDelta"] = "0.3",
        ["Account:ClientConfig:Thresholds:proposalQuestionKcalDelta"] = "70",
        ["FeatureFlags:server.experiment"] = "true",
    };

    [Fact]
    public async Task Seeding_version_one_keeps_the_config_response_byte_identical()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await using var api = new ConfigApi(postgres, NonDefault(database));
        using var client = Client(api, "0.2.0");
        var before = await client.GetStringAsync("/v1/config", Ct);
        Assert.Contains("\"minimumAppVersion\":\"0.2.0\"", before, StringComparison.Ordinal);

        var defaults = api.Services.GetRequiredService<IRemoteConfigAdmin>().Defaults;
        await PostgresRemoteConfig.SeedAsync(database.Migrator, defaults, DateTimeOffset.UtcNow, Ct);
        await PostgresRemoteConfig.SeedAsync(database.Migrator, defaults with { MinimumAppVersion = "9.9.9" }, DateTimeOffset.UtcNow, Ct);
        await api.Services.GetRequiredService<RuntimeConfigCache>().RefreshAsync(Ct);
        Assert.Equal(1, api.Services.GetRequiredService<RuntimeConfigCache>().Version);
        Assert.Equal(before, await client.GetStringAsync("/v1/config", Ct));
        Assert.True(api.Services.GetRequiredService<FitnessBuddy.BuildingBlocks.Features.IFeatureFlags>().IsEnabled("server.experiment"));
        Assert.True(api.Services.GetRequiredService<FitnessBuddy.BuildingBlocks.Features.IFeatureFlags>().IsEnabled("buddy.ai"));
    }

    [Fact]
    [Trait("Rule", "B23.P1-seed-serialized")]
    public async Task Concurrent_first_time_seeds_write_exactly_one_version()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await using var api = new ConfigApi(postgres, NonDefault(database));
        var defaults = api.Services.GetRequiredService<IRemoteConfigAdmin>().Defaults;
        // Without the lock, two of these see an empty table and one fails on the version primary key.
        await Task.WhenAll(Enumerable.Range(0, 8).Select(_ => PostgresRemoteConfig.SeedAsync(database.Migrator, defaults, DateTimeOffset.UtcNow, Ct)));
        await using var source = DatabaseConfiguration.CreateSource(database.Migrator);
        await using var count = source.CreateCommand("SELECT count(*) FROM account.config_versions");
        Assert.Equal(1L, (long)(await count.ExecuteScalarAsync(Ct))!);
    }

    [Fact]
    public async Task Publish_changes_config_and_the_426_gate_and_rollback_restores_them()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await using var api = new ConfigApi(postgres, NonDefault(database));
        var store = api.Services.GetRequiredService<IRemoteConfigAdmin>();
        await PostgresRemoteConfig.SeedAsync(database.Migrator, store.Defaults, DateTimeOffset.UtcNow, Ct);
        var cache = api.Services.GetRequiredService<RuntimeConfigCache>();
        await cache.RefreshAsync(Ct);
        using var old = Client(api, "0.2.0");
        var original = await old.GetStringAsync("/v1/config", Ct);
        await using var admin = DatabaseConfiguration.CreateSource(database.Admin);

        var raised = store.Defaults with { MinimumAppVersion = "0.3.0", ServerFlags = new Dictionary<string, bool>(store.Defaults.ServerFlags) { ["buddy.ai"] = false } };
        Assert.True((await PublishAsync(admin, store, raised, expected: 1)).IsSuccess);
        await cache.RefreshAsync(Ct);
        Assert.Contains("\"minimumAppVersion\":\"0.3.0\"", await old.GetStringAsync("/v1/config", Ct), StringComparison.Ordinal);
        using (var gated = await old.GetAsync("/v1/me", Ct)) { Assert.Equal(HttpStatusCode.UpgradeRequired, gated.StatusCode); }
        Assert.False(api.Services.GetRequiredService<FitnessBuddy.BuildingBlocks.Features.IFeatureFlags>().IsEnabled("buddy.ai"));

        // A stale publisher (still on version 1) is refused; invalid documents are refused.
        var stale = await PublishAsync(admin, store, store.Defaults, expected: 1);
        Assert.Equal(ErrorKind.VersionConflict, stale.Error.Kind);
        var invalid = await PublishAsync(admin, store, raised with { MinimumAppVersion = "v1" }, expected: 2);
        Assert.Equal(ErrorKind.Validation, invalid.Error.Kind);
        var invented = await PublishAsync(admin, store, raised with { ServerFlags = new Dictionary<string, bool>(raised.ServerFlags) { ["new.switch"] = true } }, expected: 2);
        Assert.Equal(ErrorKind.Validation, invented.Error.Kind);

        // Rollback = a new version with version 1's document.
        await using (var session = new DatabaseSession())
        {
            await session.BeginAsync(admin, null, Ct);
            var first = await store.VersionAsync(session, 1, Ct);
            var rolledBack = await store.PublishAsync(session, first!.Document, 2, "test", "roll back", 1, DateTimeOffset.UtcNow, Ct);
            Assert.Equal(3, rolledBack.Value.Version);
            await session.CommitAsync(Ct);
        }
        await cache.RefreshAsync(Ct);
        Assert.Equal(original, await old.GetStringAsync("/v1/config", Ct));
        using (var open = await old.GetAsync("/v1/me", Ct)) { Assert.NotEqual(HttpStatusCode.UpgradeRequired, open.StatusCode); }

        // Published rows are append-only, even for the console login.
        await using var update = admin.CreateCommand("UPDATE account.config_versions SET reason='x'");
        await Assert.ThrowsAsync<Npgsql.PostgresException>(async () => await update.ExecuteNonQueryAsync(Ct));
        await using var appWrite = DatabaseConfiguration.CreateSource(database.App).CreateCommand("INSERT INTO account.config_versions VALUES(99,'{}','2026-01-01','x','x',NULL)");
        await Assert.ThrowsAsync<Npgsql.PostgresException>(async () => await appWrite.ExecuteNonQueryAsync(Ct));
    }

    [Fact]
    [Trait("Req", "AD-007")]
    public async Task The_override_wins_over_a_bad_published_version_and_without_the_database()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        var settings = NonDefault(database);
        await using (var api = new ConfigApi(postgres, settings))
        {
            var store = api.Services.GetRequiredService<IRemoteConfigAdmin>();
            await PostgresRemoteConfig.SeedAsync(database.Migrator, store.Defaults, DateTimeOffset.UtcNow, Ct);
            await using var admin = DatabaseConfiguration.CreateSource(database.Admin);
            Assert.True((await PublishAsync(admin, store, store.Defaults with { MinimumAppVersion = "999.0.0" }, expected: 1)).IsSuccess);
        }
        settings["Clients:MinimumAppVersionOverride"] = "0.2.0";
        await using (var recovered = new ConfigApi(postgres, settings))
        {
            await recovered.Services.GetRequiredService<RuntimeConfigCache>().RefreshAsync(Ct);
            using var client = Client(recovered, "0.2.0");
            Assert.Contains("\"minimumAppVersion\":\"0.2.0\"", await client.GetStringAsync("/v1/config", Ct), StringComparison.Ordinal);
            using var me = await client.GetAsync("/v1/me", Ct);
            Assert.NotEqual(HttpStatusCode.UpgradeRequired, me.StatusCode);
        }
        // Restart with the database unreachable: the override still applies (and without it, the configured defaults, never "no minimum").
        settings["ConnectionStrings:Application"] = "Host=127.0.0.1;Port=1;Database=unused;Username=fb_app;Pooling=false;Timeout=1";
        await using (var offline = new ConfigApi(postgres, settings))
        {
            await offline.Services.GetRequiredService<RuntimeConfigCache>().RefreshAsync(Ct);
            using var client = Client(offline, "0.2.0");
            Assert.Contains("\"minimumAppVersion\":\"0.2.0\"", await client.GetStringAsync("/v1/config", Ct), StringComparison.Ordinal);
        }
        settings.Remove("Clients:MinimumAppVersionOverride");
        settings["Clients:MinimumAppVersion"] = "0.4.0";
        await using (var offlineDefaults = new ConfigApi(postgres, settings))
        {
            using var client = Client(offlineDefaults, "0.2.0");
            using var me = await client.GetAsync("/v1/me", Ct);
            Assert.Equal(HttpStatusCode.UpgradeRequired, me.StatusCode);
        }
    }

    private static async Task<Result<PublishedConfig>> PublishAsync(Npgsql.NpgsqlDataSource admin, IRemoteConfigAdmin store, RemoteConfigDocument document, int expected)
    {
        await using var session = new DatabaseSession();
        await session.BeginAsync(admin, null, Ct);
        var result = await store.PublishAsync(session, document, expected, "test", "test publish", null, DateTimeOffset.UtcNow, Ct);
        if (result.IsSuccess) { await session.CommitAsync(Ct); }
        return result;
    }

    private static HttpClient Client(ConfigApi api, string version)
    {
        var client = api.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Version", version);
        client.DefaultRequestHeaders.Add("X-Platform", "android");
        client.DefaultRequestHeaders.Add("X-Device-Id", "0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b");
        return client;
    }

    private sealed class ConfigApi(PostgresFixture postgres, IReadOnlyDictionary<string, string?> settings) : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");
            builder.ConfigureAppConfiguration((_, configuration) => configuration.AddInMemoryCollection(
                new Dictionary<string, string?>(settings) { ["Recovery:Directory"] = postgres.RecoveryDirectory, ["Account:RemoteConfig:PollSeconds"] = "300" }));
        }
    }
}
