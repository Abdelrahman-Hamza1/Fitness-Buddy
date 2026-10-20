using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using Microsoft.Extensions.Logging.Abstractions;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-012")]
[Trait("Rule", "05.7-retention")]
public sealed class SyncRetentionTests(PostgresFixture database) : IAsyncLifetime
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    public async ValueTask InitializeAsync()
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var command = owner.CreateCommand("TRUNCATE ops.jobs,ops.schedules,ops.outbox,ops.processed_messages,ops.idempotency"); await command.ExecuteNonQueryAsync(Ct);
    }
    public ValueTask DisposeAsync() => ValueTask.CompletedTask;

    [Fact]
    public async Task Idle_owner_schedule_produces_user_scoped_cleanup_and_failed_effects_roll_back_before_retry()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await h.GuestAsync();
        var store = new PostgresSyncStore(database.App, h.Store, h.Clock, new UuidV7IdGenerator(h.Clock));
        var row = new SyncVersion("weighIn", Guid.NewGuid(), 1, $"{h.Clock.GetUtcNow().ToUnixTimeMilliseconds():D13}-00000-{h.Device}", h.Device, null, JsonSerializer.SerializeToElement(new { value = 1 }));
        await store.PushAsync(user.UserId, [row, row with { Hlc = row.Hlc.Replace("-00000-", "-00001-", StringComparison.Ordinal), DeletedAt = h.Clock.GetUtcNow() }], h.Clock.GetUtcNow(), Ct);
        h.Clock.Advance(TimeSpan.FromDays(31));
        var scheduler = new JobScheduler(database.App, h.Clock, new UuidV7IdGenerator(h.Clock), h.Store, database.Recovery); Assert.True(await scheduler.TickAsync(Ct));
        var handler = new FailOnce(new SyncRetentionJob(h.Clock, new UuidV7IdGenerator(h.Clock)));
        var processor = new QueueProcessor(database.App, h.Clock, [], [handler], new QueuePolicy(), NullLogger<QueueProcessor>.Instance, h.Store, database.Recovery);
        Assert.True(await processor.RunJobAsync(Ct));
        Assert.Single((await store.PullAsync(user.UserId, 0, 500, true, Ct)).Changes);
        Assert.False(Assert.Single((await store.PullAsync(user.UserId, 0, 500, false, Ct)).Changes).Compacted);
        await using (var check = database.App.CreateCommand("SELECT user_id,attempts,state FROM ops.jobs WHERE job_type='userdata.cleanup'"))
        {
            await using var reader = await check.ExecuteReaderAsync(Ct); Assert.True(await reader.ReadAsync(Ct)); Assert.Equal(user.UserId, reader.GetGuid(0)); Assert.Equal(1, reader.GetInt32(1)); Assert.Equal("pending", reader.GetString(2));
        }
        h.Clock.Advance(TimeSpan.FromSeconds(6)); Assert.True(await processor.RunJobAsync(Ct));
        Assert.Empty((await store.PullAsync(user.UserId, 0, 500, true, Ct)).Changes);
        Assert.True(Assert.Single((await store.PullAsync(user.UserId, 0, 500, false, Ct)).Changes).Compacted);
        // The schedule persists after completion, so idle users get another sweep without a new push.
        h.Clock.Advance(TimeSpan.FromHours(2)); Assert.True(await scheduler.TickAsync(Ct)); Assert.True(await processor.RunJobAsync(Ct));
    }

    [Fact]
    public async Task Legacy_backfill_is_bounded_and_continues_until_all_payloads_are_purged()
    {
        var clock = new TestClock(); var user = Guid.NewGuid(); var device = Guid.NewGuid();
        await using (var session = await database.SessionAsync(user))
        {
            await using var seed = session.Command("""
                INSERT INTO userdata.row_history(user_id,entity,id,schema_version,hlc,device_id,deleted_at,payload,replaced_at)
                SELECT $1,'weighIn',gen_random_uuid(),1,$2,$3,NULL,'{"legacy":1e100}'::jsonb,$4 FROM generate_series(1,1001)
                """);
            seed.Parameters.AddWithValue(user); seed.Parameters.AddWithValue($"{clock.GetUtcNow().ToUnixTimeMilliseconds():D13}-00000-{device}"); seed.Parameters.AddWithValue(device); seed.Parameters.AddWithValue(clock.GetUtcNow().AddDays(-31)); await seed.ExecuteNonQueryAsync(Ct);
            await new QueueWriter(session, clock, new UuidV7IdGenerator(clock)).EnqueueAsync("userdata.cleanup", new { }, null, Ct); await session.CommitAsync(Ct);
        }
        var handler = new SyncRetentionJob(clock, new UuidV7IdGenerator(clock));
        var processor = new QueueProcessor(database.App, clock, [], [handler], new QueuePolicy(), NullLogger<QueueProcessor>.Instance, new SyntheticLifecycle(), database.Recovery);
        Assert.True(await processor.RunJobAsync(Ct));
        Assert.Equal(1L, await Count(user, "row_history")); Assert.Equal(1000L, await Count(user, "version_receipts"));
        Assert.True(await processor.RunJobAsync(Ct)); Assert.Equal(0L, await Count(user, "row_history")); Assert.Equal(1001L, await Count(user, "version_receipts"));
        Assert.False(await processor.RunJobAsync(Ct));
    }

    [Fact, Trait("Rule", "04.6-rls")]
    public async Task Cleanup_introduces_no_elevated_cross_user_userdata_capability()
    {
        await using var command = database.App.CreateCommand("SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='userdata' AND p.prosecdef AND has_function_privilege('fb_app',p.oid,'EXECUTE')");
        Assert.Equal(0L, await command.ExecuteScalarAsync(Ct));
    }

    private async Task<long> Count(Guid user, string table)
    {
        await using var session = await database.SessionAsync(user);
        await using var command = session.Command($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1"); command.Parameters.AddWithValue(user); return (long)(await command.ExecuteScalarAsync(Ct))!;
    }
    private sealed class FailOnce(IJobHandler inner) : IJobHandler
    {
        private bool first = true;
        public string JobType => inner.JobType;
        public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
        {
            await inner.HandleAsync(message, session, cancellationToken);
            if (first) { first = false; throw new InvalidOperationException("injected-cleanup-failure"); }
        }
    }
}
