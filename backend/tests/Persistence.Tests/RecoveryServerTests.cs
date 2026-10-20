using System.Net;
using System.Net.Http.Headers;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Recovery;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Rule", "08.5-deletion-safe-restore")]
public sealed class RecoveryServerTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task Mismatch_blocks_direct_online_traffic_as_well_as_readiness_but_config_and_liveness_remain_available()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var issued = (await h.Service.GuestAsync(h.Device, Ct))!;
        await using var api = new IdentityApiTests.IdentityApi(database, h); using var client = api.CreateClient(); Headers(client, h);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", issued.AccessToken);
        using (var before = await client.GetAsync("/v1/me", Ct)) { Assert.Equal(HttpStatusCode.OK, before.StatusCode); }
        var previous = database.Recovery.File.Read();
        try
        {
            // A crash before DB commit or a manual stale restore produces this same mismatch.
            database.Recovery.File.Write(Guid.NewGuid());
            foreach (var path in new[] { "/v1/me", "/v1/sync/pull?cursor=0&limit=1", "/.well-known/jwks.json", "/health/ready" })
            { using var response = await client.GetAsync(path, Ct); Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode); }
            using (var signIn = await client.PostAsync("/v1/auth/anonymous", null, Ct)) { Assert.Equal(HttpStatusCode.ServiceUnavailable, signIn.StatusCode); }
            using (var deletion = await client.DeleteAsync("/v1/me", Ct)) { Assert.Equal(HttpStatusCode.ServiceUnavailable, deletion.StatusCode); }
            using (var config = await client.GetAsync("/v1/config", Ct)) { Assert.Equal(HttpStatusCode.OK, config.StatusCode); }
            using (var live = await client.GetAsync("/health/live", Ct)) { Assert.Equal(HttpStatusCode.OK, live.StatusCode); }
        }
        finally { database.Recovery.File.Write(previous); }
        using var recovered = await client.GetAsync("/v1/me", Ct); Assert.Equal(HttpStatusCode.OK, recovered.StatusCode);
    }

    [Fact]
    public async Task Missing_protected_state_is_not_regenerated_even_by_explicit_initialize_on_an_existing_database()
    {
        var marker = Path.Combine(database.RecoveryDirectory, "generation");
        var saved = marker + ".saved"; File.Move(marker, saved);
        try
        {
            await Assert.ThrowsAsync<RecoveryUnavailableException>(() => RecoveryMaintenance.RunAsync(database.MigratorConnection,
                new RecoveryOptions { Directory = database.RecoveryDirectory }, new UuidV7IdGenerator(new TestClock()), true,
                _ => Task.CompletedTask, Ct));
            Assert.False(File.Exists(marker));
            await using var h = new IdentityHarness(database); await h.InitializeAsync();
            await using var api = new IdentityApiTests.IdentityApi(database, h); using var client = api.CreateClient(); Headers(client, h);
            using var denied = await client.PostAsync("/v1/auth/anonymous", null, Ct); Assert.Equal(HttpStatusCode.ServiceUnavailable, denied.StatusCode);
        }
        finally { File.Move(saved, marker); }
    }

    [Fact]
    public async Task First_initialization_is_explicit_stable_and_retryable_after_a_later_maintenance_failure()
    {
        var name = "fb_upgrade_" + Guid.NewGuid().ToString("N");
        var connection = await database.CreateUpgradeDatabaseAsync(name);
        var directory = Path.Combine(Path.GetTempPath(), "fb-recovery-init-" + Guid.NewGuid());
        Directory.CreateDirectory(directory);
        if (!OperatingSystem.IsWindows()) { File.SetUnixFileMode(directory, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute); }
        var options = new RecoveryOptions { Directory = directory }; var file = new RecoveryFile(directory);
        var ids = new UuidV7IdGenerator(new TestClock());
        try
        {
            await database.Runner.RunAsync(connection, Ct);
            await Assert.ThrowsAsync<RecoveryUnavailableException>(() => RecoveryMaintenance.RunAsync(connection, options, ids, false, _ => Task.CompletedTask, Ct));
            Assert.False(file.Exists());
            await Assert.ThrowsAsync<InvalidOperationException>(() => RecoveryMaintenance.RunAsync(connection, options, ids, true,
                _ => throw new InvalidOperationException("Synthetic post-initialization failure."), Ct));
            var generation = file.Read();
            await RecoveryMaintenance.RunAsync(connection, options, ids, true, _ => Task.CompletedTask, Ct);
            Assert.Equal(generation, file.Read());
            await RecoveryMaintenance.RunAsync(connection, options, ids, false, _ => Task.CompletedTask, Ct);
            Assert.Equal(generation, file.Read());
            await using var owner = DatabaseConfiguration.CreateSource(connection);
            await using var reset = owner.CreateCommand("UPDATE ops.recovery SET generation=NULL WHERE singleton"); await reset.ExecuteNonQueryAsync(Ct);
            await Assert.ThrowsAsync<RecoveryUnavailableException>(() => RecoveryMaintenance.RunAsync(connection, options, ids, true, _ => Task.CompletedTask, Ct));
            Assert.Equal(generation, file.Read()); // Never infer a DB generation from a surviving file.
        }
        finally { await database.DropUpgradeDatabaseAsync(name); Directory.Delete(directory, recursive: true); }
    }

    private static void Headers(HttpClient client, IdentityHarness h)
    {
        client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android");
        client.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
    }
}
