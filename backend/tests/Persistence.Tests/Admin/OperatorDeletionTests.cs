using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Recovery;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Host;
using FitnessBuddy.Modules.Account.Application;
using FitnessBuddy.Modules.Account.Infrastructure;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.Identity.Infrastructure;
using FitnessBuddy.Modules.Usage.Infrastructure;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B24 WP3: the console's deletion request runs through the unchanged B06 coordinator with the operator principal, in the api
// role's runner. Zero owner rows in every module schema afterwards; failures are contained, recorded only while the intent
// exists, and retried; nothing completes falsely (R#5); the app/operator races (R#6) and controls queued behind a deletion (R#2).
[Trait("Req", "AD-011")]
[Trait("Req", "AC-031")]
[Trait("Req", "PR-11")]
public sealed class OperatorDeletionTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private readonly PostgresIdentityAdminControls controls = new();

    private ServiceProvider Services(IdentityHarness h, IOutboxHandler? extra = null, string? recoveryDirectory = null) =>
        OperatorDeletionHarness.Services(postgres, h, extra, recoveryDirectory);

    private OperatorDeletionRunner Runner(IdentityHarness h, ServiceProvider provider, IReadOnlyCollection<Guid> only, string environment = "Testing",
        bool failDiscovery = false) => OperatorDeletionHarness.Runner(postgres, h, provider, only, environment, failDiscovery);

    private async Task RequestAsync(Guid user, DateTimeOffset now)
    {
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        await using var session = new DatabaseSession();
        await session.BeginAsync(admin, null, Ct);
        Assert.True((await controls.RequestDeletionAsync(session, user, now, Ct))!.Created);
        await session.CommitAsync(Ct);
    }

    [Fact]
    public async Task The_runner_erases_every_owner_row_in_every_module_schema_and_leaves_others_alone()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var user = (await h.Store.GoogleSignInAsync(new("valid-" + Guid.NewGuid(), Guid.NewGuid() + "@example.invalid"), Guid.NewGuid(), h.Material(), Ct))!;
        var other = (await h.Store.GoogleSignInAsync(new("valid-" + Guid.NewGuid(), Guid.NewGuid() + "@example.invalid"), Guid.NewGuid(), h.Material(), Ct))!;
        await SeedEverySchemaAsync(h, user);
        await SeedEverySchemaAsync(h, other);
        await RequestAsync(user.UserId, h.Clock.GetUtcNow());

        await using var provider = Services(h);
        var before = postgres.Recovery.File.Read();
        Assert.Equal(1, await Runner(h, provider, [user.UserId]).RunOnceAsync(Ct));
        Assert.NotEqual(before, postgres.Recovery.File.Read());
        await OwnerRows.AssertNoneAsync(postgres, user.UserId, user.SessionId);
        Assert.NotNull(await h.Store.ReadSessionAsync(other.UserId, other.SessionId, Ct));
        Assert.True(await CountAsync("SELECT count(*) FROM usage.limit_overrides WHERE user_id=$1", other.UserId) == 1);

        // No false completion: recording a failure after the commit changes nothing and recreates nothing.
        await using (var late = await postgres.SessionAsync(user.UserId))
        {
            Assert.False(await new PostgresOperatorDeletions(postgres.App, h.Clock).RecordFailureAsync(late, "failed", Ct));
            await late.CommitAsync(Ct);
        }
        await OwnerRows.AssertNoneAsync(postgres, user.UserId, user.SessionId);
        Assert.Equal(0, await Runner(h, provider, [user.UserId]).RunOnceAsync(Ct));
    }

    [Fact]
    [Trait("Rule", "B24.R5-runner-containment")]
    public async Task A_failed_item_is_rolled_back_recorded_and_retried_while_the_next_item_still_runs()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var first = await h.GuestAsync(); var second = await h.GuestAsync();
        await RequestAsync(first.UserId, h.Clock.GetUtcNow());
        h.Clock.Advance(TimeSpan.FromSeconds(1));
        await RequestAsync(second.UserId, h.Clock.GetUtcNow());

        await using var failing = Services(h, new FailOnce());
        var generation = postgres.Recovery.File.Read();
        Assert.Equal(1, await Runner(h, failing, [first.UserId, second.UserId]).RunOnceAsync(Ct));
        // The first (earliest) failed: everything rolled back and the generation reconciled; the second was deleted.
        Assert.Equal("active", await StatusAsync(first.UserId));
        Assert.Equal((1, "failed"), await AttemptAsync(first.UserId));
        Assert.Null(await StatusAsync(second.UserId));
        Assert.NotEqual(generation, postgres.Recovery.File.Read());
        await using (var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection))
        await using (var read = new DatabaseSession())
        {
            await read.BeginAsync(admin, null, Ct);
            var state = (await controls.StateAsync(read, first.UserId, Ct))!;
            Assert.NotNull(state.DisabledAt); Assert.Equal("failed", state.DeletionLastError);
        }

        // Backoff: not yet due. Then a fresh runner (a restart) completes it.
        await using var healthy = Services(h);
        Assert.Equal(0, await Runner(h, healthy, [first.UserId]).RunOnceAsync(Ct));
        h.Clock.Advance(TimeSpan.FromMinutes(3));
        Assert.Equal(1, await Runner(h, healthy, [first.UserId]).RunOnceAsync(Ct));
        await OwnerRows.AssertNoneAsync(postgres, first.UserId, first.SessionId);
    }

    [Fact]
    [Trait("Rule", "B24.R5-recovery-unavailable")]
    public async Task A_recovery_state_that_does_not_verify_is_recorded_as_recovery_unavailable_and_the_repaired_retry_deletes()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var user = await h.GuestAsync();
        await RequestAsync(user.UserId, h.Clock.GetUtcNow());
        // Its own recovery state (a generation the database doesn't have), so the shared database and file stay verified.
        var broken = Path.Combine(Path.GetTempPath(), "fb-recovery-broken-" + Guid.NewGuid());
        Directory.CreateDirectory(broken);
        if (!OperatingSystem.IsWindows()) { File.SetUnixFileMode(broken, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute); }
        try
        {
            new RecoveryFile(broken).Write(Guid.NewGuid());
            var shared = postgres.Recovery.File.Read();
            await using (var unverified = Services(h, recoveryDirectory: broken))
            { Assert.Equal(0, await Runner(h, unverified, [user.UserId]).RunOnceAsync(Ct)); }
            Assert.Equal("active", await StatusAsync(user.UserId));
            Assert.Equal((1, "recovery-unavailable"), await AttemptAsync(user.UserId));
            Assert.Equal(shared, postgres.Recovery.File.Read());

            // Repaired (the runner on the verified state), after the backoff: deleted.
            h.Clock.Advance(TimeSpan.FromMinutes(3));
            await using var healthy = Services(h);
            Assert.Equal(1, await Runner(h, healthy, [user.UserId]).RunOnceAsync(Ct));
            await OwnerRows.AssertNoneAsync(postgres, user.UserId, user.SessionId);
        }
        finally { Directory.Delete(broken, recursive: true); }
    }

    [Fact]
    [Trait("Rule", "B24.R5-runner-containment")]
    public async Task Two_runners_at_once_delete_exactly_once()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var user = await h.GuestAsync();
        await RequestAsync(user.UserId, h.Clock.GetUtcNow());
        await using var provider = Services(h);
        // Both runners discover the intent before either may proceed to the deletion, so they really compete (review minor 5).
        var gate = new OperatorDeletionHarness.DiscoveryGate(2);
        var results = await Task.WhenAll(
            OperatorDeletionHarness.Runner(postgres, h, provider, [user.UserId], gate: gate).RunOnceAsync(Ct),
            OperatorDeletionHarness.Runner(postgres, h, provider, [user.UserId], gate: gate).RunOnceAsync(Ct));
        Assert.Equal(2, gate.Discovered(user.UserId));
        Assert.Equal(1, results.Sum());
        await OwnerRows.AssertNoneAsync(postgres, user.UserId, user.SessionId);
    }

    [Fact]
    [Trait("Rule", "B24.R5-runner-containment")]
    public async Task The_hosted_loop_survives_a_failing_pass_and_stops_cleanly()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var provider = Services(h);
        var runner = Runner(h, provider, [], environment: "Production", failDiscovery: true);
        await runner.StartAsync(Ct);
        await Task.Delay(200, Ct);
        Assert.False(runner.ExecuteTask!.IsCompleted);
        await runner.StopAsync(Ct);
        Assert.True(runner.ExecuteTask.IsCompletedSuccessfully);
        using var cancelled = new CancellationTokenSource();
        await cancelled.CancelAsync();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => Runner(h, provider, [Guid.NewGuid()]).RunOnceAsync(cancelled.Token));
    }

    [Fact]
    [Trait("Rule", "B24.R6-app-operator-race")]
    public async Task App_first_refuses_the_request_and_operator_first_refuses_the_app()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var provider = Services(h);
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);

        var appFirst = await h.GuestAsync();
        await using (var scope = provider.CreateAsyncScope())
        { Assert.Equal(DeletionResult.Deleted, await scope.ServiceProvider.GetRequiredService<IAccountDeletion>().DeleteAsync(appFirst.UserId, appFirst.SessionId, Ct)); }
        await using (var session = new DatabaseSession())
        {
            await session.BeginAsync(admin, null, Ct);
            Assert.Null(await controls.RequestDeletionAsync(session, appFirst.UserId, h.Clock.GetUtcNow(), Ct));
            await session.CommitAsync(Ct);
        }
        await OwnerRows.AssertNoneAsync(postgres, appFirst.UserId, appFirst.SessionId);

        var operatorFirst = await h.GuestAsync();
        await RequestAsync(operatorFirst.UserId, h.Clock.GetUtcNow());
        await using (var scope = provider.CreateAsyncScope())
        { Assert.Equal(DeletionResult.Unauthorized, await scope.ServiceProvider.GetRequiredService<IAccountDeletion>().DeleteAsync(operatorFirst.UserId, operatorFirst.SessionId, Ct)); }
        Assert.Equal(1, await Runner(h, provider, [operatorFirst.UserId]).RunOnceAsync(Ct));
        await OwnerRows.AssertNoneAsync(postgres, operatorFirst.UserId, operatorFirst.SessionId);
    }

    [Fact]
    [Trait("Rule", "B24.R2-controls-after-deletion")]
    public async Task Controls_queued_behind_a_deletion_write_nothing_after_it_commits()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var user = await h.GuestAsync();
        await RequestAsync(user.UserId, h.Clock.GetUtcNow());
        await using var provider = Services(h);
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);

        // Hold the user's lifecycle lock, queue the deletion first, then the console's controls behind it.
        await using var held = await postgres.SessionAsync(user.UserId);
        await UserLifecycleLock.AcquireAsync(held, user.UserId, Ct);
        var deletion = Runner(h, provider, [user.UserId]).RunOnceAsync(Ct);
        await LockWaits.UntilWaitingAsync(postgres, "hashtextextended($1, 4603912)");
        await using var revokeSession = new DatabaseSession(); await revokeSession.BeginAsync(admin, null, Ct);
        var revoke = controls.RevokeAsync(revokeSession, user.UserId, null, h.Clock.GetUtcNow(), Ct);
        await LockWaits.UntilWaitingAsync(postgres, "admin_revoke_sessions");
        await using var limitSession = new DatabaseSession(); await limitSession.BeginAsync(admin, null, Ct);
        var limit = SetLimitIfAccountAsync(limitSession, user.UserId);
        await LockWaits.UntilWaitingAsync(postgres, "admin_lock_account");
        await held.CommitAsync(Ct);

        Assert.Equal(1, await deletion);
        Assert.Null(await revoke); await revokeSession.CommitAsync(Ct);
        Assert.False(await limit); await limitSession.CommitAsync(Ct);
        await OwnerRows.AssertNoneAsync(postgres, user.UserId, user.SessionId);
    }

    /// <summary>The console handler's order: Identity's lock and revalidation first, then the Usage write.</summary>
    private async Task<bool> SetLimitIfAccountAsync(DatabaseSession session, Guid user)
    {
        if (await controls.LockAsync(session, user, Ct) is null) { return false; }
        await new PostgresUsageAdminControls().SetDailyLimitAsync(session, user, 5, DateTimeOffset.UtcNow, Ct);
        return true;
    }

    private async Task SeedEverySchemaAsync(IdentityHarness h, IdentitySession user)
    {
        var sync = new PostgresSyncStore(postgres.App, h.Store, h.Clock, new UuidV7IdGenerator(h.Clock));
        var dataset = (await sync.PullForSessionAsync(user, null, 0, 1, false, null, null, Ct))!.DatasetId;
        var payload = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "entity-payloads.json"))).RootElement.GetProperty("weighIn").Clone();
        await sync.PushForSessionAsync(user, dataset,
            [new SyncVersion("weighIn", Guid.NewGuid(), 1, $"{h.Clock.GetUtcNow().ToUnixTimeMilliseconds():D13}-00000-{h.Device}", h.Device, null, payload)], h.Clock.GetUtcNow(), Ct);
        await using (var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection))
        await using (var console = new DatabaseSession())
        {
            await console.BeginAsync(admin, null, Ct);
            Assert.NotNull(await controls.LockAsync(console, user.UserId, Ct));
            await new PostgresUsageAdminControls().SetDailyLimitAsync(console, user.UserId, 3, h.Clock.GetUtcNow(), Ct);
            await console.CommitAsync(Ct);
        }
        await using var session = await postgres.SessionAsync(user.UserId);
        await new PostgresUsageRecorder(h.Clock).ReserveAsync(session, "m", 5, DateOnly.FromDateTime(h.Clock.GetUtcNow().UtcDateTime), true, Ct);
        await using (var attempt = session.Command("INSERT INTO buddy.attempts(user_id,message_id,fingerprint,created_at,expires_at,dispatched_at) VALUES($1,$2,'f',$3,$4,$3)"))
        {
            attempt.Parameters.AddWithValue(user.UserId); attempt.Parameters.AddWithValue(Guid.CreateVersion7());
            attempt.Parameters.AddWithValue(h.Clock.GetUtcNow()); attempt.Parameters.AddWithValue(h.Clock.GetUtcNow().AddHours(24));
            await attempt.ExecuteNonQueryAsync(Ct);
        }
        var writer = new QueueWriter(session, h.Clock, new UuidV7IdGenerator(h.Clock));
        await writer.EnqueueAsync("test.b24-later", new { }, h.Clock.GetUtcNow().AddYears(5), Ct);
        await writer.ScheduleUserAsync("test.b24-seed:" + user.UserId, "0 4 * * *", "test.b24-later", h.Clock.GetUtcNow().AddYears(5), Ct);
        await session.CommitAsync(Ct);
    }

    private async Task<string?> StatusAsync(Guid user)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand("SELECT status FROM identity.users WHERE id=$1");
        command.Parameters.AddWithValue(user);
        return await command.ExecuteScalarAsync(Ct) as string;
    }

    private async Task<(int Attempts, string? Error)> AttemptAsync(Guid user)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand("SELECT attempts,last_error FROM identity.operator_deletions WHERE user_id=$1");
        command.Parameters.AddWithValue(user);
        await using var reader = await command.ExecuteReaderAsync(Ct);
        Assert.True(await reader.ReadAsync(Ct));
        return (reader.GetInt32(0), reader.IsDBNull(1) ? null : reader.GetString(1));
    }

    private async Task<long> CountAsync(string sql, Guid user)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand(sql);
        command.Parameters.AddWithValue(user);
        return (long)(await command.ExecuteScalarAsync(Ct))!;
    }

    private sealed class FailOnce : IOutboxHandler
    {
        private int calls;
        public string EventType => UserErasure.EventType;
        public string Name => "test.b24-failure";
        public Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken) =>
            Interlocked.Increment(ref calls) == 1 ? throw new InvalidOperationException("Synthetic participant failure.") : Task.CompletedTask;
    }
}

/// <summary>The deletion services and a runner limited to one test's accounts (the database is shared).</summary>
internal static class OperatorDeletionHarness
{
    public static ServiceProvider Services(PostgresFixture postgres, IdentityHarness h, IOutboxHandler? extra = null, string? recoveryDirectory = null)
    {
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Identity:Enabled"] = "true",
            ["Identity:WrappingKeysDirectory"] = h.DirectoryPath,
            ["Identity:PepperFile"] = Path.Combine(h.DirectoryPath, "pepper"),
            ["Recovery:Directory"] = recoveryDirectory ?? postgres.RecoveryDirectory,
        }).Build();
        var services = new ServiceCollection();
        services.AddLogging(); services.AddSingleton<TimeProvider>(h.Clock);
        services.AddSingleton<IIdGenerator>(new UuidV7IdGenerator(h.Clock)); services.AddSingleton(postgres.App);
        services.AddScoped<DatabaseSession>(); services.AddSingleton(new QueuePolicy()); services.AddScoped<QueueProcessor>();
        services.Configure<RecoveryOptions>(config.GetSection("Recovery")); services.AddSingleton<RecoveryBarrier>();
        foreach (var module in ModuleCatalog.All) { module.AddServices(services, config); services.AddSingleton<IModule>(module); }
        if (extra is not null) { services.AddSingleton(extra); }
        return services.BuildServiceProvider(new ServiceProviderOptions { ValidateScopes = true });
    }

    public static OperatorDeletionRunner Runner(PostgresFixture postgres, IdentityHarness h, ServiceProvider provider, IReadOnlyCollection<Guid> only,
        string environment = "Testing", bool failDiscovery = false, DiscoveryGate? gate = null) =>
        new(provider.GetRequiredService<IServiceScopeFactory>(), new Only(new PostgresOperatorDeletions(postgres.App, h.Clock), only, failDiscovery, gate), postgres.App,
            Microsoft.Extensions.Options.Options.Create(new OperatorDeletionOptions { PollSeconds = 1 }), new Environment(environment), h.Clock,
            NullLogger<OperatorDeletionRunner>.Instance);

    internal sealed class Only(IIdentityOperatorDeletions inner, IReadOnlyCollection<Guid> users, bool failDiscovery, DiscoveryGate? gate = null) : IIdentityOperatorDeletions
    {
        public async Task<IReadOnlyList<Guid>> DueAsync(DateTimeOffset now, int limit, CancellationToken cancellationToken)
        {
            if (failDiscovery) { throw new InvalidOperationException("Synthetic discovery failure."); }
            var due = (await inner.DueAsync(now, 50, cancellationToken)).Where(users.Contains).Take(limit).ToArray();
            if (gate is not null) { await gate.ArriveAsync(due, cancellationToken); }
            return due;
        }

        public Task<bool> RecordFailureAsync(DatabaseSession session, string code, CancellationToken cancellationToken) =>
            inner.RecordFailureAsync(session, code, cancellationToken);
    }

    /// <summary>Holds every runner after its discovery until all <paramref name="parties"/> have discovered.</summary>
    internal sealed class DiscoveryGate(int parties)
    {
        private readonly System.Collections.Concurrent.ConcurrentBag<Guid> discovered = [];
        private readonly TaskCompletionSource all = new(TaskCreationOptions.RunContinuationsAsynchronously);
        private int arrived;

        public int Discovered(Guid user) => discovered.Count(id => id == user);

        public async Task ArriveAsync(IEnumerable<Guid> due, CancellationToken cancellationToken)
        {
            foreach (var user in due) { discovered.Add(user); }
            if (Interlocked.Increment(ref arrived) == parties) { all.TrySetResult(); }
            await all.Task.WaitAsync(TimeSpan.FromSeconds(30), cancellationToken);
        }
    }

    internal sealed class Environment(string name) : IHostEnvironment
    {
        public string EnvironmentName { get; set; } = name;
        public string ApplicationName { get; set; } = "test";
        public string ContentRootPath { get; set; } = AppContext.BaseDirectory;
        public Microsoft.Extensions.FileProviders.IFileProvider ContentRootFileProvider { get; set; } = new Microsoft.Extensions.FileProviders.NullFileProvider();
    }

}

/// <summary>B06's zero-rows query, extended to every module schema (B24 T7).</summary>
internal static class OwnerRows
{
    private static readonly string[] Schemas = ["account", "buddy", "catalog", "identity", "ops", "usage", "userdata"];

    public static async Task AssertNoneAsync(PostgresFixture postgres, Guid user, Guid session)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        var columns = new List<(string Schema, string Table, string Column)>();
        await using (var catalog = owner.CreateCommand("SELECT c.table_schema,c.table_name,c.column_name FROM information_schema.columns c JOIN information_schema.tables t ON t.table_schema=c.table_schema AND t.table_name=c.table_name AND t.table_type='BASE TABLE' WHERE c.table_schema=ANY($1) AND (c.column_name IN('user_id','session_id') OR (c.table_schema='identity' AND c.table_name='users' AND c.column_name='id'))"))
        {
            catalog.Parameters.AddWithValue(Schemas);
            await using var reader = await catalog.ExecuteReaderAsync(TestContext.Current.CancellationToken);
            while (await reader.ReadAsync(TestContext.Current.CancellationToken)) { columns.Add((reader.GetString(0), reader.GetString(1), reader.GetString(2))); }
        }
        Assert.Contains(columns, column => column.Schema == "usage" && column.Table == "limit_overrides");
        Assert.Contains(columns, column => column.Schema == "identity" && column.Table == "operator_deletions");
        using var quote = new NpgsqlCommandBuilder();
        foreach (var column in columns)
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM {quote.QuoteIdentifier(column.Schema)}.{quote.QuoteIdentifier(column.Table)} WHERE {quote.QuoteIdentifier(column.Column)}=$1");
            query.Parameters.AddWithValue(column.Column == "session_id" ? session : user);
            Assert.True((long)(await query.ExecuteScalarAsync(TestContext.Current.CancellationToken))! == 0, column.Schema + "." + column.Table + "." + column.Column);
        }
    }
}
