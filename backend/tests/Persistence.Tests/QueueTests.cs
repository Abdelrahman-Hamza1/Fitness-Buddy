using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.Extensions.Logging.Abstractions;

namespace FitnessBuddy.Persistence.Tests;

// Transaction boundaries are exercised against a real process connection, not an in-memory queue.
public sealed class QueueTests(PostgresFixture database) : IAsyncLifetime
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private readonly TestClock clock = new();
    private readonly TestHandler handler = new();

    public async ValueTask InitializeAsync()
    {
        await using var migrator = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var reset = migrator.CreateCommand("TRUNCATE ops.outbox,ops.jobs,ops.schedules,ops.processed_messages,ops.idempotency");
        await reset.ExecuteNonQueryAsync(Ct);
    }
    public ValueTask DisposeAsync() => ValueTask.CompletedTask;

    [Fact]
    [Trait("Rule", "04.3.3-outbox")]
    public async Task Business_change_and_event_both_roll_back_without_commit()
    {
        var id = Guid.CreateVersion7();
        await using (var session = await database.SessionAsync())
        {
            await EffectAsync(session, id, Ct);
            await Writer(session).PublishAsync("test.event", new { content = "private" }, Ct);
        }
        Assert.Equal(0, await CountEffectsAsync(id));
        Assert.False(await Processor().DispatchOutboxAsync(Ct));
    }

    [Fact]
    [Trait("Rule", "04.3.3-outbox")]
    public async Task Connection_death_after_effect_before_ack_rolls_back_then_restart_applies_exactly_once()
    {
        var id = await PublishAsync();
        var crashed = false;
        handler.Execute = async (message, session, ct) =>
        {
            await EffectAsync(session, message.Id, ct);
            if (!crashed)
            {
                crashed = true;
                await database.TerminateAsync(session.Connection.ProcessID);
            }
        };
        await Assert.ThrowsAnyAsync<Exception>(() => Processor().DispatchOutboxAsync(Ct));
        Assert.Equal(0, await CountEffectsAsync(id));
        Assert.True(await Processor().DispatchOutboxAsync(Ct));
        Assert.False(await Processor().DispatchOutboxAsync(Ct));
        Assert.Equal(1, await CountEffectsAsync(id));
        await using var session = await database.SessionAsync();
        await using var marker = session.Command("SELECT count(*) FROM ops.processed_messages WHERE message_id=$1");
        marker.Parameters.AddWithValue(id);
        Assert.Equal(1L, await marker.ExecuteScalarAsync(Ct));
        // Even a duplicate delivery cannot repeat this handler's effect.
        await using var redeliver = session.Command("UPDATE ops.outbox SET state='pending' WHERE id=$1");
        redeliver.Parameters.AddWithValue(id);
        await redeliver.ExecuteNonQueryAsync(Ct);
        await session.CommitAsync(Ct);
        Assert.True(await Processor().DispatchOutboxAsync(Ct));
        Assert.Equal(1, await CountEffectsAsync(id));
    }

    [Fact]
    [Trait("Rule", "04.3.4-jobs")]
    public async Task Failed_effect_rolls_back_retries_with_backoff_and_dead_letters_on_third_attempt()
    {
        var id = await EnqueueAsync();
        handler.Execute = async (message, session, ct) =>
        {
            await EffectAsync(session, message.Id, ct);
            throw new InvalidOperationException("content-must-never-be-logged");
        };
        var processor = Processor(new QueuePolicy(3, 5));
        Assert.True(await processor.RunJobAsync(Ct));
        Assert.Equal(0, await CountEffectsAsync(id));
        Assert.False(await processor.RunJobAsync(Ct));
        clock.Advance(TimeSpan.FromSeconds(5));
        Assert.True(await processor.RunJobAsync(Ct));
        Assert.False(await processor.RunJobAsync(Ct));
        clock.Advance(TimeSpan.FromSeconds(9));
        Assert.False(await processor.RunJobAsync(Ct));
        clock.Advance(TimeSpan.FromSeconds(1));
        Assert.True(await processor.RunJobAsync(Ct));
        clock.Advance(TimeSpan.FromDays(1));
        Assert.False(await processor.RunJobAsync(Ct));
        await using var command = database.App.CreateCommand("SELECT state,attempts,last_error FROM ops.jobs WHERE id=$1");
        command.Parameters.AddWithValue(id);
        await using var reader = await command.ExecuteReaderAsync(Ct);
        Assert.True(await reader.ReadAsync(Ct));
        Assert.Equal("dead", reader.GetString(0));
        Assert.Equal(3, reader.GetInt32(1));
        Assert.Equal(nameof(InvalidOperationException), reader.GetString(2));
    }

    [Fact]
    [Trait("Rule", "04.3.3-outbox")]
    public async Task Competing_workers_skip_a_claimed_row()
    {
        var id = await PublishAsync();
        var started = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var release = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        handler.Execute = async (message, session, ct) =>
        {
            started.SetResult();
            await release.Task.WaitAsync(ct);
            await EffectAsync(session, message.Id, ct);
        };
        var first = Processor().DispatchOutboxAsync(Ct);
        await started.Task.WaitAsync(TimeSpan.FromSeconds(10), Ct);
        Assert.False(await Processor().DispatchOutboxAsync(Ct));
        release.SetResult();
        Assert.True(await first);
        Assert.Equal(1, await CountEffectsAsync(id));
    }

    [Fact]
    [Trait("Rule", "04.3.4-jobs")]
    public async Task Shutdown_cancellation_rolls_back_without_counting_an_attempt()
    {
        var id = await EnqueueAsync();
        using var stopping = CancellationTokenSource.CreateLinkedTokenSource(Ct);
        handler.Execute = async (message, session, ct) =>
        {
            await EffectAsync(session, message.Id, ct);
            stopping.Cancel();
            ct.ThrowIfCancellationRequested();
        };
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => Processor().RunJobAsync(stopping.Token));
        Assert.Equal(0, await CountEffectsAsync(id));
        await using var command = database.App.CreateCommand("SELECT attempts FROM ops.jobs WHERE id=$1");
        command.Parameters.AddWithValue(id);
        Assert.Equal(0, await command.ExecuteScalarAsync(Ct));
        handler.Execute = (message, session, ct) => EffectAsync(session, message.Id, ct);
        Assert.True(await Processor().RunJobAsync(Ct));
        Assert.Equal(1, await CountEffectsAsync(id));
    }

    [Fact]
    [Trait("Rule", "04.3.4-jobs")]
    public async Task Persistent_cron_fires_on_fake_clock_and_coalesces_missed_ticks_without_duplicates()
    {
        var scheduler = new JobScheduler(database.App, clock, new UuidV7IdGenerator(clock), new SyntheticLifecycle(), database.Recovery);
        var schedule = new JobSchedule("test.minute", "* * * * *", "test.job");
        await scheduler.RegisterAsync(schedule, Ct);
        Assert.False(await scheduler.TickAsync(Ct));
        clock.Advance(TimeSpan.FromMinutes(1));
        await scheduler.RegisterAsync(schedule, Ct); // Restart must not postpone a due job.
        var competing = await Task.WhenAll(scheduler.TickAsync(Ct), scheduler.TickAsync(Ct));
        Assert.Single(competing, value => value);
        Assert.False(await scheduler.TickAsync(Ct));
        handler.Execute = (message, session, ct) => EffectAsync(session, message.Id, ct);
        Assert.True(await Processor().RunJobAsync(Ct));
        clock.Advance(TimeSpan.FromHours(12));
        Assert.True(await scheduler.TickAsync(Ct));
        Assert.False(await scheduler.TickAsync(Ct));
        Assert.True(await Processor().RunJobAsync(Ct));
        Assert.False(await Processor().RunJobAsync(Ct));
        await using var command = database.App.CreateCommand("SELECT count(*) FROM ops.jobs WHERE state='done'");
        Assert.Equal(2L, await command.ExecuteScalarAsync(Ct));
    }

    [Fact]
    [Trait("Rule", "04.6-rls")]
    public async Task Worker_restores_trusted_envelope_identity_for_user_scoped_handler_queries()
    {
        var user = Guid.CreateVersion7();
        var row = Guid.CreateVersion7();
        await using (var session = await database.SessionAsync(user))
        {
            await using var insert = session.Command("INSERT INTO testdata.sample_rows VALUES($1,$2,'private', $3)");
            insert.Parameters.AddWithValue(row);
            insert.Parameters.AddWithValue(user);
            insert.Parameters.AddWithValue(clock.GetUtcNow());
            await insert.ExecuteNonQueryAsync(Ct);
            await Writer(session).PublishAsync("test.event", new { }, Ct);
            await session.CommitAsync(Ct);
        }
        var found = false;
        handler.Execute = async (message, session, ct) =>
        {
            Assert.Equal(user, message.UserId);
            Assert.Equal(user, session.UserId);
            await using var query = session.Command("SELECT id FROM testdata.sample_rows");
            Assert.Equal(row, await query.ExecuteScalarAsync(ct));
            found = true;
        };
        Assert.True(await Processor().DispatchOutboxAsync(Ct));
        Assert.True(found);
    }

    [Fact]
    [Trait("Rule", "04.3.4-jobs")]
    public async Task Cleanup_removes_expired_replays_and_old_completed_items_but_keeps_dead_letters()
    {
        var expired = clock.GetUtcNow() - TimeSpan.FromDays(8);
        await using (var session = await database.SessionAsync())
        {
            await using var seed = session.Command("""
                WITH replay AS(INSERT INTO ops.idempotency VALUES('scope','expired','fp',200,NULL,''::bytea,'{}',$1,$1) RETURNING scope_hash)
                INSERT INTO ops.jobs(id,job_type,payload,created_at,available_at,state,completed_at)
                VALUES($2,'test.job','{}',$1,$1,'done',$1),($3,'test.job','{}',$1,$1,'dead',NULL);
                """);
            seed.Parameters.AddWithValue(expired);
            seed.Parameters.AddWithValue(Guid.CreateVersion7());
            seed.Parameters.AddWithValue(Guid.CreateVersion7());
            await seed.ExecuteNonQueryAsync(Ct);
            await new OpsCleanupJob(clock).HandleAsync(new QueueMessage(Guid.CreateVersion7(), OpsCleanupJob.Type, "{}", null, 1), session, Ct);
            await session.CommitAsync(Ct);
        }
        await using var query = database.App.CreateCommand("SELECT (SELECT count(*) FROM ops.idempotency),(SELECT count(*) FROM ops.jobs WHERE state='done'),(SELECT count(*) FROM ops.jobs WHERE state='dead')");
        await using var reader = await query.ExecuteReaderAsync(Ct);
        Assert.True(await reader.ReadAsync(Ct));
        Assert.Equal(0, reader.GetInt64(0));
        Assert.Equal(0, reader.GetInt64(1));
        Assert.Equal(1, reader.GetInt64(2));
    }

    [Fact]
    [Trait("Req", "AC-031")]
    public async Task Transactional_dispatch_shares_commit_rollback_and_worker_deduplication()
    {
        var user = Guid.CreateVersion7();
        Guid rolledBack;
        handler.Execute = (message, session, ct) => EffectAsync(session, message.Id, ct);
        await using (var session = await database.SessionAsync(user))
        {
            rolledBack = await Writer(session).PublishAsync("test.event", new { }, Ct);
            await Processor().DispatchWithinTransactionAsync(rolledBack, session, Ct);
            Assert.Equal(0, await CountEffectsAsync(rolledBack)); // No separate connection sees uncommitted effects.
        }
        Assert.Equal(0, await CountEffectsAsync(rolledBack));
        await using (var query = database.App.CreateCommand("SELECT count(*) FROM ops.processed_messages WHERE message_id=$1"))
        { query.Parameters.AddWithValue(rolledBack); Assert.Equal(0L, await query.ExecuteScalarAsync(Ct)); }
        Guid committed;
        await using (var session = await database.SessionAsync(user))
        {
            committed = await Writer(session).PublishAsync("test.event", new { }, Ct);
            await Processor().DispatchWithinTransactionAsync(committed, session, Ct);
            await session.CommitAsync(Ct);
        }
        Assert.Equal(1, await CountEffectsAsync(committed));
        Assert.False(await Processor().DispatchOutboxAsync(Ct));
    }

    private QueueWriter Writer(DatabaseSession session) => new(session, clock, new UuidV7IdGenerator(clock));
    private QueueProcessor Processor(QueuePolicy? policy = null) => new(database.App, clock, [handler], [handler], policy ?? new QueuePolicy(), NullLogger<QueueProcessor>.Instance, new SyntheticLifecycle(), database.Recovery);

    private async Task<Guid> PublishAsync()
    {
        await using var session = await database.SessionAsync();
        var id = await Writer(session).PublishAsync("test.event", new { }, Ct);
        await session.CommitAsync(Ct);
        return id;
    }
    private async Task<Guid> EnqueueAsync()
    {
        await using var session = await database.SessionAsync();
        var id = await Writer(session).EnqueueAsync("test.job", new { }, null, Ct);
        await session.CommitAsync(Ct);
        return id;
    }
    private static async Task EffectAsync(DatabaseSession session, Guid id, CancellationToken ct)
    {
        await using var command = session.Command("INSERT INTO testdata.effects VALUES($1,1) ON CONFLICT(id) DO UPDATE SET count=testdata.effects.count+1");
        command.Parameters.AddWithValue(id);
        await command.ExecuteNonQueryAsync(ct);
    }
    private async Task<int> CountEffectsAsync(Guid id)
    {
        await using var command = database.App.CreateCommand("SELECT count FROM testdata.effects WHERE id=$1");
        command.Parameters.AddWithValue(id);
        return (int?)await command.ExecuteScalarAsync(Ct) ?? 0;
    }
    private sealed class TestHandler : IOutboxHandler, IJobHandler
    {
        public string EventType => "test.event";
        public string Name => "test.handler";
        public string JobType => "test.job";
        public Func<QueueMessage, DatabaseSession, CancellationToken, Task> Execute { get; set; } = (_, _, _) => Task.CompletedTask;
        public Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken) => Execute(message, session, cancellationToken);
    }
}
