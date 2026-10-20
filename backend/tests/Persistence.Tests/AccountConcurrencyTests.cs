using System.Net;
using System.Net.Http.Headers;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Web.Idempotency;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.Account.Application;
using FitnessBuddy.Modules.Account.Infrastructure;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging.Abstractions;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-031")]
[Trait("Rule", "05.6-lifecycle")]
public sealed class AccountConcurrencyTests(PostgresFixture database) : IAsyncLifetime
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    public async ValueTask InitializeAsync()
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var reset = owner.CreateCommand("TRUNCATE ops.jobs,ops.outbox,ops.schedules,ops.processed_messages,ops.idempotency"); await reset.ExecuteNonQueryAsync(Ct);
    }
    public ValueTask DisposeAsync() => ValueTask.CompletedTask;

    [Fact]
    public async Task Ordinary_request_holds_recovery_lease_but_delete_does_not_deadlock_on_its_own_preliminary_lease()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var issued = (await h.Service.GuestAsync(h.Device, Ct))!;
        var signals = new Signals(); await using var api = new TestApi(database, h, signals); using var client = Client(api, h, issued.AccessToken);
        var reading = client.GetAsync("/v1/_recovery/hold", Ct); await signals.Entered.Task.WaitAsync(TimeSpan.FromSeconds(10), Ct);
        var deleting = client.DeleteAsync("/v1/me", Ct); await Waiters(1);
        Assert.False(deleting.IsCompleted);
        signals.Release.TrySetResult();
        using var read = await reading.WaitAsync(TimeSpan.FromSeconds(10), Ct); Assert.Equal(HttpStatusCode.NoContent, read.StatusCode);
        using var deleted = await deleting.WaitAsync(TimeSpan.FromSeconds(10), Ct); Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
        using var old = await client.GetAsync("/v1/me", Ct); Assert.Equal(HttpStatusCode.Unauthorized, old.StatusCode);
    }

    [Fact]
    public async Task Authenticated_cached_replay_waiting_on_user_lock_cannot_return_bytes_after_deletion()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var issued = (await h.Service.GuestAsync(h.Device, Ct))!;
        var signals = new Signals(); await using var api = new TestApi(database, h, signals); using var client = Client(api, h, issued.AccessToken);
        client.DefaultRequestHeaders.Add("Idempotency-Key", "same-request");
        using (var first = await client.PostAsync("/v1/_cache/response", null, Ct)) { Assert.Equal(HttpStatusCode.OK, first.StatusCode); Assert.Equal("CACHE-PRIVATE-CANARY", await first.Content.ReadAsStringAsync(Ct)); }
        using var scope = api.Services.CreateScope(); var deletion = scope.ServiceProvider.GetRequiredService<IAccountDeletion>();
        await using var held = await database.SessionAsync(issued.UserId); await UserLifecycleLock.AcquireAsync(held, issued.UserId, Ct);
        var principal = await h.Tokens.ValidateAsync(issued.AccessToken, Ct); var sid = Guid.Parse(principal!.FindFirst("sid")!.Value);
        var erase = deletion.DeleteAsync(issued.UserId, sid, Ct); await Waiters(1);
        // This test-only probe deliberately omits the module-wide recovery lease, isolating the
        // generic replay middleware's OWN live-session fence rather than hiding it behind the gate.
        var replay = client.PostAsync("/v1/_cache/response", null, Ct); await Waiters(2);
        await held.CommitAsync(Ct); Assert.Equal(DeletionResult.Deleted, await erase);
        using var denied = await replay.WaitAsync(TimeSpan.FromSeconds(10), Ct); Assert.Equal(HttpStatusCode.Unauthorized, denied.StatusCode);
        Assert.DoesNotContain("CACHE-PRIVATE-CANARY", await denied.Content.ReadAsStringAsync(Ct), StringComparison.Ordinal);
        Assert.Equal(1, signals.Executions);
    }

    [Fact]
    public async Task Connection_death_before_commit_rolls_back_database_and_leaves_recovery_fail_closed()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var issued = (await h.Service.GuestAsync(h.Device, Ct))!;
        var previous = database.Recovery.File.Read(); var signals = new Signals();
        await using var api = new TestApi(database, h, signals, terminate: true); using var client = Client(api, h, issued.AccessToken);
        try
        {
            using var failed = await client.DeleteAsync("/v1/me", Ct); Assert.Equal(HttpStatusCode.InternalServerError, failed.StatusCode);
            await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
            await using var query = owner.CreateCommand("SELECT generation FROM ops.recovery WHERE singleton"); Assert.Equal(previous, await query.ExecuteScalarAsync(Ct));
            Assert.NotEqual(previous, database.Recovery.File.Read());
            using var blocked = await client.GetAsync("/v1/me", Ct); Assert.Equal(HttpStatusCode.ServiceUnavailable, blocked.StatusCode);
            var principal = await h.Tokens.ValidateAsync(issued.AccessToken, Ct);
            Assert.NotNull(await h.Store.ReadSessionAsync(issued.UserId, Guid.Parse(principal!.FindFirst("sid")!.Value), Ct));
        }
        finally
        {
            // Verified synthetic pre-commit abort only, restoring this fixture for other tests.
            // Production never guesses that a mismatched snapshot is an uncommitted deletion.
            database.Recovery.File.Write(previous);
        }
    }

    [Fact]
    public async Task Lost_connection_after_durable_commit_never_reopens_old_credentials_or_replays_success()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var issued = (await h.Service.GuestAsync(h.Device, Ct))!;
        var signals = new Signals(); await using var api = new TestApi(database, h, signals, loseReply: true); using var client = Client(api, h, issued.AccessToken);
        using var abort = CancellationTokenSource.CreateLinkedTokenSource(Ct);
        var deleting = client.DeleteAsync("/v1/me", abort.Token); await signals.Committed.Task.WaitAsync(TimeSpan.FromSeconds(10), Ct);
        abort.Cancel(); await Assert.ThrowsAnyAsync<OperationCanceledException>(() => deleting);
        await signals.Finished.Task.WaitAsync(TimeSpan.FromSeconds(10), Ct);
        using var old = await client.GetAsync("/v1/me", Ct); Assert.Equal(HttpStatusCode.Unauthorized, old.StatusCode);
        using var retry = await client.DeleteAsync("/v1/me", Ct); Assert.Equal(HttpStatusCode.Unauthorized, retry.StatusCode);
        using var ready = await client.GetAsync("/health/ready", Ct); Assert.Equal(HttpStatusCode.OK, ready.StatusCode);
    }

    [Fact]
    public async Task Claimed_worker_finishes_before_erasure_and_orphan_jobs_are_consumed_without_effects()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await h.GuestAsync(); var signals = new Signals();
        var ids = new UuidV7IdGenerator(h.Clock);
        await using (var seed = await database.SessionAsync(user.UserId)) { await new QueueWriter(seed, h.Clock, ids).EnqueueAsync("test.slow", new { }, null, Ct); await seed.CommitAsync(Ct); }
        var processor = new QueueProcessor(database.App, h.Clock, [], [new SlowJob(signals)], new QueuePolicy(), NullLogger<QueueProcessor>.Instance, h.Store, database.Recovery);
        var work = processor.RunJobAsync(Ct); await signals.Entered.Task.WaitAsync(TimeSpan.FromSeconds(10), Ct);
        await using var api = new TestApi(database, h, signals); using var scope = api.Services.CreateScope();
        var erase = scope.ServiceProvider.GetRequiredService<IAccountDeletion>().DeleteAsync(user.UserId, user.SessionId, Ct); await Waiters(1);
        signals.Release.TrySetResult(); Assert.True(await work); Assert.Equal(DeletionResult.Deleted, await erase);
        Assert.Equal(1, signals.Executions);
        await using (var orphan = await database.SessionAsync(user.UserId)) { await new QueueWriter(orphan, h.Clock, ids).EnqueueAsync("test.slow", new { }, null, Ct); await orphan.CommitAsync(Ct); }
        Assert.True(await processor.RunJobAsync(Ct)); Assert.Equal(1, signals.Executions); Assert.False(await processor.RunJobAsync(Ct));
    }

    private async Task Waiters(int count)
    {
        for (var i = 0; i < 200; i++)
        {
            await using var command = database.App.CreateCommand("SELECT count(*) FROM pg_locks WHERE locktype='advisory' AND NOT granted");
            if ((long)(await command.ExecuteScalarAsync(Ct))! >= count) { return; }
            await Task.Delay(10, Ct);
        }
        Assert.Fail("Expected serialized operation did not reach its lock.");
    }
    private static HttpClient Client(TestApi api, IdentityHarness h, string token)
    {
        var client = api.CreateClient(); client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android");
        client.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString()); client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token); return client;
    }
    private sealed class Signals
    {
        public TaskCompletionSource Entered { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource Release { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource Committed { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource Finished { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public int Executions;
    }
    private sealed class TestApi(PostgresFixture database, IdentityHarness h, Signals signals, bool terminate = false, bool loseReply = false) : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");
            builder.ConfigureAppConfiguration((_, configuration) => configuration.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:Application"] = database.AppConnection,
                ["Recovery:Directory"] = database.RecoveryDirectory,
                ["Identity:Enabled"] = "true",
                ["Identity:WrappingKeysDirectory"] = h.DirectoryPath,
                ["Identity:PepperFile"] = h.Options.PepperFile,
            }));
            builder.ConfigureTestServices(services =>
            {
                services.AddSingleton<TimeProvider>(h.Clock); services.AddSingleton(signals);
                services.AddSingleton<IModule, HoldModule>(); services.AddSingleton<IModule, CacheModule>();
                if (terminate) { services.AddSingleton<IOutboxHandler>(new Terminate(database)); }
                if (loseReply)
                {
                    services.RemoveAll<IAccountDeletion>();
                    services.AddScoped<IAccountDeletion>(provider => new LostReply(ActivatorUtilities.CreateInstance<PostgresAccountDeletion>(provider), signals));
                }
            });
        }
    }
    private sealed class HoldModule : IModule
    {
        public string Name => "Buddy";
        public UserDataOwnership UserData => new([], [], null);
        public void AddServices(IServiceCollection services, IConfiguration configuration) { }
        public void MapEndpoints(RouteGroupBuilder group) => group.MapGet("/_recovery/hold", async (Signals signals, CancellationToken ct) =>
        { signals.Entered.TrySetResult(); await signals.Release.Task.WaitAsync(ct); return TypedResults.NoContent(); }).RequireAuthorization("any-user").ExcludeFromDescription();
    }
    private sealed class CacheModule : IModule
    {
        public string Name => "CacheProbe";
        public UserDataOwnership UserData => new([], [], null);
        public void AddServices(IServiceCollection services, IConfiguration configuration) { }
        public void MapEndpoints(RouteGroupBuilder group) => group.MapPost("/_cache/response", (Signals signals) =>
        { Interlocked.Increment(ref signals.Executions); return TypedResults.Text("CACHE-PRIVATE-CANARY"); }).RequireAuthorization("any-user").RequireIdempotency().ExcludeFromDescription();
    }
    private sealed class Terminate(PostgresFixture database) : IOutboxHandler
    {
        public string EventType => UserErasure.EventType;
        public string Name => "test.disconnect";
        public Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken) => database.TerminateAsync(session.Connection.ProcessID);
    }
    private sealed class LostReply(IAccountDeletion inner, Signals signals) : IAccountDeletion
    {
        public async Task<DeletionResult> DeleteAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken)
        {
            var result = await inner.DeleteAsync(userId, sessionId, cancellationToken);
            if (result == DeletionResult.Deleted)
            {
                signals.Committed.TrySetResult();
                try { await Task.Delay(Timeout.InfiniteTimeSpan, cancellationToken); }
                finally { signals.Finished.TrySetResult(); }
            }
            return result;
        }
    }
    private sealed class SlowJob(Signals signals) : IJobHandler
    {
        public string JobType => "test.slow";
        public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
        { signals.Entered.TrySetResult(); await signals.Release.Task.WaitAsync(cancellationToken); Interlocked.Increment(ref signals.Executions); }
    }
}
