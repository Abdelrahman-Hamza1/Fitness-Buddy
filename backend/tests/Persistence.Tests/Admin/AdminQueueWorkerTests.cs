using System.Diagnostics;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Ops;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Admin.Application;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23b review (T13 worker proofs): the console's queue changes against the real worker. A retried item runs exactly once, a
// cancelled one never runs, a row a worker holds is refused promptly (never waited for), and a handler blocked in the real
// processor shows in the heartbeat with its queue kind, so jobs and events are counted separately.
[Trait("Req", "AD-014")]
[Trait("Req", "AD-005")]
public sealed class AdminQueueWorkerTests(PostgresFixture postgres) : IAsyncDisposable
{
    private readonly NpgsqlDataSource adminSource = DatabaseConfiguration.CreateSource(postgres.AdminConnection);

    private const string HeldJob = "test.held";
    private const string BusyEvent = "test.busy-event";
    private const string RetryJob = "test.retry-once";

    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    [Trait("Rule", "B23.R7-queue-actions")]
    public async Task A_retried_item_runs_exactly_once_and_a_cancelled_one_never_runs_with_the_real_previous_state()
    {
        var clock = new TestClock(DateTimeOffset.UtcNow);
        var retried = new CountingJob(RetryJob);
        var dead = await EnqueueAsync(clock, RetryJob);
        await ExecuteAsync("UPDATE ops.jobs SET state='dead', attempts=5, last_error='TimeoutException' WHERE id=$1", dead);
        var ops = Ops();

        Assert.Equal(new QueueChange(QueueChangeOutcome.Changed, "dead"), await InAdminSessionAsync(session => ops.RetryAsync(session, QueueKind.Job, dead, clock.GetUtcNow(), Ct)));
        var processor = Processor(clock, [retried]);
        while (await processor.RunJobAsync(Ct)) { }
        Assert.Equal(1, retried.Runs);
        // A replayed retry finds the item done: refused, with the state it found, and the worker doesn't run it again.
        Assert.Equal(new QueueChange(QueueChangeOutcome.Refused, "done"), await InAdminSessionAsync(session => ops.RetryAsync(session, QueueKind.Job, dead, clock.GetUtcNow(), Ct)));
        while (await processor.RunJobAsync(Ct)) { }
        Assert.Equal(1, retried.Runs);

        var cancelledType = "test.cancel-" + Guid.NewGuid().ToString("N")[..8];
        var cancelled = new CountingJob(cancelledType);
        var pending = await EnqueueAsync(clock, cancelledType);
        var deadToo = await EnqueueAsync(clock, cancelledType);
        await ExecuteAsync("UPDATE ops.jobs SET state='dead', attempts=5 WHERE id=$1", deadToo);
        Assert.Equal(new QueueChange(QueueChangeOutcome.Changed, "pending"), await InAdminSessionAsync(session => ops.CancelAsync(session, pending, clock.GetUtcNow(), Ct)));
        Assert.Equal(new QueueChange(QueueChangeOutcome.Changed, "dead"), await InAdminSessionAsync(session => ops.CancelAsync(session, deadToo, clock.GetUtcNow(), Ct)));
        Assert.Equal(new QueueChange(QueueChangeOutcome.Unchanged, "cancelled"), await InAdminSessionAsync(session => ops.CancelAsync(session, pending, clock.GetUtcNow(), Ct)));
        Assert.Equal(QueueChangeOutcome.Missing, (await InAdminSessionAsync(session => ops.CancelAsync(session, Guid.NewGuid(), clock.GetUtcNow(), Ct))).Outcome);
        var worker = Processor(clock, [cancelled]);
        while (await worker.RunJobAsync(Ct)) { }
        Assert.Equal(0, cancelled.Runs);
    }

    [Fact]
    [Trait("Rule", "B23.R7-queue-actions")]
    public async Task A_row_a_worker_holds_is_refused_promptly_as_busy()
    {
        var clock = new TestClock(DateTimeOffset.UtcNow);
        var held = new BlockingJob(HeldJob);
        var job = await EnqueueAsync(clock, HeldJob);
        var worker = Processor(clock, [held]);
        var run = RunUntilAsync(() => worker.RunJobAsync(Ct), held.Started.Task);
        await held.Started.Task.WaitAsync(TimeSpan.FromSeconds(30), Ct);
        var ops = Ops();
        var timer = Stopwatch.StartNew();
        Assert.Equal(new QueueChange(QueueChangeOutcome.Busy, null), await InAdminSessionAsync(session => ops.CancelAsync(session, job, clock.GetUtcNow(), Ct)));
        Assert.True(timer.Elapsed < TimeSpan.FromSeconds(5), "the cancel waited for the worker's lock");

        // A dead event held by another transaction (as a dispatch would hold it) is skipped the same way.
        var deadEvent = Guid.CreateVersion7();
        await ExecuteAsync("INSERT INTO ops.outbox(id,event_type,payload,created_at,available_at,attempts,state) VALUES($1,'test.monitor-event','{}',now(),now(),5,'dead')", deadEvent);
        await using (var locker = await postgres.WorkerSessionAsync())
        {
            await using (var lockRow = locker.Command("SELECT 1 FROM ops.outbox WHERE id=$1 FOR UPDATE"))
            {
                lockRow.Parameters.AddWithValue(deadEvent);
                await lockRow.ExecuteNonQueryAsync(Ct);
            }
            timer.Restart();
            Assert.Equal(QueueChangeOutcome.Busy, (await InAdminSessionAsync(session => ops.RetryAsync(session, QueueKind.Event, deadEvent, clock.GetUtcNow(), Ct))).Outcome);
            Assert.True(timer.Elapsed < TimeSpan.FromSeconds(5), "the retry waited for the lock");
        }
        held.Release.SetResult();
        await run;
        Assert.Equal(1, held.Runs);
        Assert.Equal(new QueueChange(QueueChangeOutcome.Changed, "dead"), await InAdminSessionAsync(session => ops.RetryAsync(session, QueueKind.Event, deadEvent, clock.GetUtcNow(), Ct)));
        await ExecuteAsync("DELETE FROM ops.outbox WHERE id=$1", deadEvent);
    }

    [Fact]
    [Trait("Rule", "B23.R11-in-progress")]
    public async Task A_handler_blocked_in_the_real_processor_shows_in_the_heartbeat_with_its_queue_kind()
    {
        var clock = new TestClock(DateTimeOffset.UtcNow);
        var activity = new WorkerActivity(clock, new UuidV7IdGenerator(clock));
        var heartbeat = new WorkerHeartbeatService(postgres.Worker, activity, clock, postgres.Recovery, NullLogger<WorkerHeartbeatService>.Instance);
        var job = new BlockingJob(HeldJob);
        var handler = new BlockingEvent(BusyEvent);
        var processor = new QueueProcessor(postgres.Worker, clock, [handler], [job], new QueuePolicy(), NullLogger<QueueProcessor>.Instance, new SyntheticLifecycle(),
            postgres.Recovery, activity);
        await using var admin = await AdminApp.StartAsync(postgres);
        var ops = admin.Services.GetRequiredService<IOpsAdministration>();

        await EnqueueAsync(clock, HeldJob);
        var running = RunUntilAsync(() => processor.RunJobAsync(Ct), job.Started.Task);
        await job.Started.Task.WaitAsync(TimeSpan.FromSeconds(30), Ct);
        await heartbeat.BeatAsync(Ct);
        var beat = Assert.Single(await ops.HeartbeatsAsync(Ct), row => row.Instance == activity.Instance);
        Assert.Equal((QueueKind.Job, HeldJob), (beat.BusyKind!.Value, beat.BusyType!));
        job.Release.SetResult();
        await running;

        await using (var session = await postgres.SessionAsync())
        {
            await new QueueWriter(session, clock, new UuidV7IdGenerator(clock)).PublishAsync(BusyEvent, new { }, Ct);
            await session.CommitAsync(Ct);
        }
        var dispatching = RunUntilAsync(() => processor.DispatchOutboxAsync(Ct), handler.Started.Task);
        await handler.Started.Task.WaitAsync(TimeSpan.FromSeconds(30), Ct);
        await heartbeat.BeatAsync(Ct);
        beat = Assert.Single(await ops.HeartbeatsAsync(Ct), row => row.Instance == activity.Instance);
        Assert.Equal((QueueKind.Event, BusyEvent), (beat.BusyKind!.Value, beat.BusyType!));
        await using (var scope = admin.Services.CreateAsyncScope())
        {
            var state = await scope.ServiceProvider.GetRequiredService<ReadJobsAndSync>().HandleAsync(Ct);
            Assert.Equal(1, state.InProgress[(QueueKind.Event, BusyEvent)]);
            Assert.False(state.InProgress.ContainsKey((QueueKind.Job, BusyEvent)));
        }
        handler.Release.SetResult();
        await dispatching;
        await heartbeat.BeatAsync(Ct);
        beat = Assert.Single(await ops.HeartbeatsAsync(Ct), row => row.Instance == activity.Instance);
        Assert.Null(beat.BusyKind);
        Assert.Null(beat.BusyType);
        await ExecuteAsync("DELETE FROM ops.worker_heartbeats WHERE instance=$1", activity.Instance);
    }

    public ValueTask DisposeAsync() => adminSource.DisposeAsync();

    private PostgresOpsAdministration Ops() => new(adminSource, AdminApp.TestVocabulary);

    /// <summary>Runs due items until <paramref name="started"/> fires (another test's leftover item may come first), then to completion.</summary>
    private static async Task RunUntilAsync(Func<Task<bool>> next, Task started)
    {
        while (!started.IsCompleted && await next()) { }
    }

    private QueueProcessor Processor(TimeProvider clock, IJobHandler[] jobs) =>
        new(postgres.Worker, clock, [], jobs, new QueuePolicy(), NullLogger<QueueProcessor>.Instance, new SyntheticLifecycle(), postgres.Recovery);

    private async Task<Guid> EnqueueAsync(TimeProvider clock, string type)
    {
        await using var session = await postgres.SessionAsync();
        var id = await new QueueWriter(session, clock, new UuidV7IdGenerator(clock)).EnqueueAsync(type, new { }, null, Ct);
        await session.CommitAsync(Ct);
        return id;
    }

    private async Task<QueueChange> InAdminSessionAsync(Func<DatabaseSession, Task<QueueChange>> action)
    {
        await using var session = new DatabaseSession();
        await session.BeginAsync(adminSource, null, Ct);
        var result = await action(session);
        await session.CommitAsync(Ct);
        return result;
    }

    private async Task ExecuteAsync(string sql, Guid id)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand(sql);
        command.Parameters.AddWithValue(id);
        await command.ExecuteNonQueryAsync(Ct);
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

    private sealed class BlockingJob(string type) : IJobHandler
    {
        public TaskCompletionSource Started { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);

        public TaskCompletionSource Release { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);

        public int Runs { get; private set; }

        public string JobType => type;

        public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
        {
            Runs++;
            Started.TrySetResult();
            await Release.Task.WaitAsync(cancellationToken);
        }
    }

    private sealed class BlockingEvent(string type) : IOutboxHandler
    {
        public TaskCompletionSource Started { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);

        public TaskCompletionSource Release { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);

        public string EventType => type;

        public string Name => "test.blocking-event";

        public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
        {
            Started.TrySetResult();
            await Release.Task.WaitAsync(cancellationToken);
        }
    }
}
