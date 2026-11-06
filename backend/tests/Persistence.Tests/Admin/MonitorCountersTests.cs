using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Ops;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Catalog.Infrastructure;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23 WP8 (T12, parts of T13): the console's counters keep logical rejections, drop nothing on success paths, never break the
// request they count, expire with retention and the account; paused job types are skipped; heartbeats report work in progress.
[Trait("Req", "AD-014")]
[Trait("Req", "AD-011")]
public sealed class MonitorCountersTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private static JsonElement Fixtures => JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "entity-payloads.json"))).RootElement;

    private static SyncVersion Row(IdentityHarness h, int counter = 0, long? wallMs = null) =>
        new("weighIn", Guid.NewGuid(), 1, $"{wallMs ?? h.Clock.GetUtcNow().ToUnixTimeMilliseconds():D13}-{counter:D5}-{h.Device}", h.Device, null,
            Fixtures.GetProperty("weighIn").Clone());

    private static async Task<IdentitySession> Registered(IdentityHarness h) =>
        (await h.Store.GoogleSignInAsync(new("valid-" + Guid.NewGuid(), "synthetic@example.invalid"), Guid.NewGuid(), h.Material(), Ct))!;

    private PostgresSyncStore Store(IdentityHarness h) => new(database.App, h.Store, h.Clock, new UuidV7IdGenerator(h.Clock));

    [Fact]
    [Trait("Rule", "B23.P4-sync-counters")]
    public async Task Push_outcomes_and_pull_rejections_are_counted_and_register_retention()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await Registered(h); var store = Store(h);
        var first = await store.PullForSessionAsync(user, null, 0, 10, false, null, null, Ct);
        var dataset = first!.DatasetId;
        await store.PushForSessionAsync(user, Guid.NewGuid(), [Row(h), Row(h, 1)], h.Clock.GetUtcNow(), Ct);
        var future = h.Clock.GetUtcNow().AddMinutes(10).ToUnixTimeMilliseconds();
        var outcome = await store.PushForSessionAsync(user, dataset, [Row(h, 2), Row(h, 3, future)], h.Clock.GetUtcNow(), Ct);
        Assert.Equal(["accepted", "invalid"], outcome!.Results.Select(r => r.Status));
        Assert.Equal("datasetMismatch", (await store.PullForSessionAsync(user, Guid.NewGuid(), 0, 10, false, null, null, Ct))!.Reason);
        Assert.Equal("cursorInvalid", (await store.PullForSessionAsync(user, dataset, long.MaxValue, 10, false, null, null, Ct))!.Reason);

        var counts = await CountsAsync(user.UserId);
        Assert.Equal(new Dictionary<string, long>
        {
            ["pushes"] = 2,
            ["pulls"] = 3,
            ["changes_in"] = 1,
            ["stale"] = 0,
            ["clock_drift"] = 1,
            ["version_conflict"] = 0,
            ["unsupported"] = 0,
            ["invalid_payload"] = 0,
            ["dataset_mismatch"] = 3,
            ["cursor_invalid"] = 1,
        }, counts);
        Assert.True(await ScheduledAsync(user.UserId));

        // A pull-only account gets its retention schedule from its first count.
        var reader = await Registered(h);
        await store.PullForSessionAsync(reader, null, 0, 10, false, null, null, Ct);
        Assert.Equal(1, (await CountsAsync(reader.UserId))["pulls"]);
        Assert.True(await ScheduledAsync(reader.UserId));
    }

    [Fact]
    [Trait("Rule", "B23.R2-savepoint")]
    public async Task A_failing_counter_rolls_back_to_its_savepoint_and_the_push_still_commits()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await Registered(h); var store = Store(h);
        var dataset = (await store.PullForSessionAsync(user, null, 0, 10, false, null, null, Ct))!.DatasetId;
        var row = Row(h);
        await using var trigger = await TriggerAsync(user.UserId, "RAISE EXCEPTION 'test-only counter failure'");
        var outcome = await store.PushForSessionAsync(user, dataset, [row], h.Clock.GetUtcNow(), Ct);
        Assert.Equal("accepted", Assert.Single(outcome!.Results).Status);
        // Read back through a fresh migrator connection: the push committed, the counter didn't.
        Assert.Equal(1L, await ScalarAsync("SELECT count(*) FROM userdata.documents WHERE user_id=$1 AND id=$2", user.UserId, row.Id));
        Assert.Equal(1L, await ScalarAsync("SELECT coalesce(sum(pulls),0) FROM userdata.sync_daily WHERE user_id=$1", user.UserId));
        Assert.Equal(0L, await ScalarAsync("SELECT coalesce(sum(pushes),0) FROM userdata.sync_daily WHERE user_id=$1", user.UserId));
    }

    [Fact]
    [Trait("Rule", "B23.R2-savepoint")]
    public async Task A_connection_lost_during_the_counter_fails_the_push_with_nothing_committed()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await Registered(h); var store = Store(h);
        var dataset = (await store.PullForSessionAsync(user, null, 0, 10, false, null, null, Ct))!.DatasetId;
        var row = Row(h);
        await using var trigger = await TriggerAsync(user.UserId, "PERFORM pg_terminate_backend(pg_backend_pid())");
        await Assert.ThrowsAnyAsync<Exception>(() => store.PushForSessionAsync(user, dataset, [row], h.Clock.GetUtcNow(), Ct));
        Assert.Equal(0L, await ScalarAsync("SELECT count(*) FROM userdata.documents WHERE user_id=$1 AND id=$2", user.UserId, row.Id));
        Assert.Equal(0L, await ScalarAsync("SELECT coalesce(sum(pushes),0) FROM userdata.sync_daily WHERE user_id=$1", user.UserId));
    }

    [Fact]
    [Trait("Rule", "B23.P3-retention")]
    public async Task Counts_expire_after_90_days_and_with_the_account()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await Registered(h);
        await Store(h).PullForSessionAsync(user, null, 0, 10, false, null, null, Ct);
        await using (var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection))
        {
            await using var old = owner.CreateCommand("INSERT INTO userdata.sync_daily(user_id,day,pulls) VALUES($1,$2,7)");
            old.Parameters.AddWithValue(user.UserId);
            old.Parameters.AddWithValue(DateOnly.FromDateTime(h.Clock.GetUtcNow().UtcDateTime).AddDays(-91));
            await old.ExecuteNonQueryAsync(Ct);
        }
        await SyncHttpSupport.Cleanup(database, h, user.UserId);
        Assert.Equal(1L, await ScalarAsync("SELECT count(*) FROM userdata.sync_daily WHERE user_id=$1", user.UserId));

        await using (var session = await database.SessionAsync(user.UserId))
        {
            await new UserDataErasure().HandleAsync(new QueueMessage(Guid.NewGuid(), UserErasure.EventType, "{}", user.UserId, 1), session, Ct);
            await session.CommitAsync(Ct);
        }
        Assert.Equal(0L, await ScalarAsync("SELECT count(*) FROM userdata.sync_daily WHERE user_id=$1", user.UserId));
    }

    [Fact]
    [Trait("Rule", "B23.P4-global-counters")]
    public async Task Lookup_and_server_error_counts_flush_in_batches_and_a_failed_flush_is_dropped()
    {
        var clock = new TestClock(new DateTimeOffset(2026, 11, 7, 9, 30, 0, TimeSpan.Zero));
        var services = new ServiceCollection().AddSingleton(database.App).AddSingleton(database.Recovery).BuildServiceProvider();
        var lookups = new OffLookupCounters(services, clock);
        lookups.Record("found-complete"); lookups.Record("found-complete"); lookups.Record("sanity-warn", "energy-macros-mismatch");
        await lookups.FlushAsync(Ct);
        lookups.Record("found-complete");
        await lookups.FlushAsync(Ct);
        Assert.Equal(3L, await ScalarAsync("SELECT count FROM catalog.off_lookup_daily WHERE day='2026-11-07' AND outcome='found-complete' AND rule=''"));
        Assert.Equal(1L, await ScalarAsync("SELECT count FROM catalog.off_lookup_daily WHERE day='2026-11-07' AND outcome='sanity-warn' AND rule='energy-macros-mismatch'"));

        var errors = new ServerErrorCounter(() => database.App, clock, database.Recovery);
        errors.Record(500); errors.Record(503); errors.Record(500); errors.Record(404);
        await errors.FlushAsync(Ct);
        Assert.Equal(2L, await ScalarAsync("SELECT count FROM ops.http_errors_hourly WHERE hour='2026-11-07T09:00:00Z' AND role='api' AND status=500"));
        Assert.Equal(0L, await ScalarAsync("SELECT count(*) FROM ops.http_errors_hourly WHERE status<500"));

        // A flush that can't write (here: the console login has no grant) is logged and dropped by the flush service.
        await using var admin = DatabaseConfiguration.CreateSource(database.AdminConnection);
        var failing = new ServerErrorCounter(() => admin, clock, database.Recovery);
        failing.Record(500);
        var service = new CounterFlushService([failing], clock, NullLogger<CounterFlushService>.Instance);
        await service.StopAsync(Ct);
        Assert.Equal(2L, await ScalarAsync("SELECT count FROM ops.http_errors_hourly WHERE hour='2026-11-07T09:00:00Z' AND role='api' AND status=500"));
        await ExecuteAsync("DELETE FROM catalog.off_lookup_daily WHERE day='2026-11-07'; DELETE FROM ops.http_errors_hourly WHERE hour='2026-11-07T09:00:00Z'");
    }

    [Fact]
    [Trait("Rule", "B23.P4-pause")]
    public async Task A_paused_job_type_is_skipped_until_resumed_and_cleanup_cannot_be_paused()
    {
        var clock = new TestClock(DateTimeOffset.UtcNow);
        var type = "test.pausable-" + Guid.NewGuid().ToString("N")[..8];
        var handler = new CountingJob(type);
        await using (var session = await database.SessionAsync())
        {
            await new QueueWriter(session, clock, new UuidV7IdGenerator(clock)).EnqueueAsync(type, new { }, null, Ct);
            await session.CommitAsync(Ct);
        }
        await using var admin = DatabaseConfiguration.CreateSource(database.AdminConnection);
        var ops = new PostgresOpsAdministration(admin, QueueVocabulary.Default.With([type]));
        Assert.Equal(new QueueChange(QueueChangeOutcome.Changed, "running"), await InAdminSessionAsync(admin, session => ops.SetPausedAsync(session, type, true, "owner", clock.GetUtcNow(), Ct)));
        Assert.Equal(QueueChangeOutcome.Refused, (await InAdminSessionAsync(admin, session => ops.SetPausedAsync(session, OpsCleanupJob.Type, true, "owner", clock.GetUtcNow(), Ct))).Outcome);
        Assert.Contains(await ops.QueuesAsync(clock.GetUtcNow(), Ct), queue => queue.Type == type && queue.Paused && queue.Pending == 1);

        var processor = new QueueProcessor(database.Worker, clock, [], [handler], new QueuePolicy(), NullLogger<QueueProcessor>.Instance, new SyntheticLifecycle(), database.Recovery);
        while (await processor.RunJobAsync(Ct)) { }
        Assert.Equal(0, handler.Runs);
        Assert.Equal(new QueueChange(QueueChangeOutcome.Changed, "paused"), await InAdminSessionAsync(admin, session => ops.SetPausedAsync(session, type, false, "owner", clock.GetUtcNow(), Ct)));
        while (await processor.RunJobAsync(Ct)) { }
        Assert.Equal(1, handler.Runs);
    }

    private static async Task<QueueChange> InAdminSessionAsync(NpgsqlDataSource admin, Func<DatabaseSession, Task<QueueChange>> action)
    {
        await using var session = new DatabaseSession();
        await session.BeginAsync(admin, null, Ct);
        var result = await action(session);
        await session.CommitAsync(Ct);
        return result;
    }

    private async Task<Dictionary<string, long>> CountsAsync(Guid user)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var command = owner.CreateCommand("""
            SELECT sum(pushes),sum(pulls),sum(changes_in),sum(stale),sum(clock_drift),sum(version_conflict),sum(unsupported),sum(invalid_payload),
                   sum(dataset_mismatch),sum(cursor_invalid) FROM userdata.sync_daily WHERE user_id=$1
            """);
        command.Parameters.AddWithValue(user);
        await using var reader = await command.ExecuteReaderAsync(Ct);
        Assert.True(await reader.ReadAsync(Ct));
        string[] names = ["pushes", "pulls", "changes_in", "stale", "clock_drift", "version_conflict", "unsupported", "invalid_payload", "dataset_mismatch", "cursor_invalid"];
        return names.Select((name, index) => (name, value: reader.IsDBNull(index) ? 0 : reader.GetInt64(index))).ToDictionary(pair => pair.name, pair => pair.value);
    }

    private async Task<bool> ScheduledAsync(Guid user) =>
        await ScalarAsync("SELECT count(*) FROM ops.schedules WHERE user_id=$1 AND job_type='userdata.cleanup'", user) == 1L;

    /// <summary>A test-only trigger on <c>sync_daily</c> that runs <paramref name="statement"/> for one account only; dropped on dispose.</summary>
    private async Task<IAsyncDisposable> TriggerAsync(Guid user, string statement)
    {
        var name = "test_counter_" + Guid.NewGuid().ToString("N")[..12];
        await ExecuteAsync($"""
            CREATE FUNCTION userdata.{name}() RETURNS trigger LANGUAGE plpgsql AS $f$ BEGIN {statement}; RETURN NEW; END $f$;
            CREATE TRIGGER {name} BEFORE INSERT OR UPDATE ON userdata.sync_daily FOR EACH ROW WHEN (NEW.user_id = '{user}' AND NEW.pushes > 0)
              EXECUTE FUNCTION userdata.{name}();
            """);
        return new Dropper(() => ExecuteAsync($"DROP TRIGGER {name} ON userdata.sync_daily; DROP FUNCTION userdata.{name}();"));
    }

    private async Task<long> ScalarAsync(string sql, params object[] parameters)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var command = owner.CreateCommand(sql);
        foreach (var parameter in parameters) { command.Parameters.AddWithValue(parameter); }
        return Convert.ToInt64(await command.ExecuteScalarAsync(Ct) ?? 0L, System.Globalization.CultureInfo.InvariantCulture);
    }

    private async Task ExecuteAsync(string sql)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var command = owner.CreateCommand(sql);
        await command.ExecuteNonQueryAsync(CancellationToken.None);
    }

    private sealed class Dropper(Func<Task> drop) : IAsyncDisposable
    {
        public async ValueTask DisposeAsync() => await drop();
    }

    private sealed class CountingJob(string type) : IJobHandler
    {
        public int Runs { get; private set; }

        public string JobType => type;

        public Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
        {
            Runs++;
            return Task.CompletedTask;
        }
    }
}
