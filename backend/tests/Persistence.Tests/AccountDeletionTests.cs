using System.Security.Cryptography;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Recovery;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Host;
using FitnessBuddy.Modules.Account.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-031")]
[Trait("Req", "PR-11")]
[Trait("Req", "C-4")]
public sealed class AccountDeletionTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private static SyncVersion Row(IdentityHarness h, int counter = 0) => new("weighIn", Guid.NewGuid(), 1,
        $"{h.Clock.GetUtcNow().ToUnixTimeMilliseconds():D13}-{counter:D5}-{h.Device}", h.Device, null,
        JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "entity-payloads.json"))).RootElement.GetProperty("weighIn").Clone());
    private PostgresSyncStore Sync(IdentityHarness h) => new(database.App, h.Store, h.Clock, new UuidV7IdGenerator(h.Clock));
    private static async Task<IdentitySession> Register(IdentityHarness h, string? address = null) =>
        (await h.Store.GoogleSignInAsync(new("valid-" + Guid.NewGuid(), address ?? Guid.NewGuid() + "@example.invalid"), Guid.NewGuid(), h.Material(), Ct))!;

    private ServiceProvider Services(IdentityHarness h, IOutboxHandler? extra = null, IModule? extraModule = null)
    {
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Identity:Enabled"] = "true",
            ["Identity:WrappingKeysDirectory"] = h.DirectoryPath,
            ["Identity:PepperFile"] = Path.Combine(h.DirectoryPath, "pepper"),
            ["Recovery:Directory"] = database.RecoveryDirectory,
        }).Build();
        var services = new ServiceCollection();
        services.AddLogging(); services.AddSingleton<TimeProvider>(h.Clock);
        services.AddSingleton<IIdGenerator>(new UuidV7IdGenerator(h.Clock)); services.AddSingleton(database.App);
        services.AddScoped<DatabaseSession>(); services.AddSingleton(new QueuePolicy()); services.AddScoped<QueueProcessor>();
        services.Configure<RecoveryOptions>(config.GetSection("Recovery")); services.AddSingleton<RecoveryBarrier>();
        foreach (var module in ModuleCatalog.All) { module.AddServices(services, config); services.AddSingleton<IModule>(module); }
        if (extra is not null) { services.AddSingleton(extra); }
        if (extraModule is not null) { services.AddSingleton(extraModule); }
        return services.BuildServiceProvider(new ServiceProviderOptions { ValidateScopes = true });
    }

    [Fact]
    public async Task Erasure_removes_user_rows_history_receipts_fences_and_ops_but_preserves_other_user_and_globals()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var address = Guid.NewGuid() + "@example.invalid";
        var material = h.Material();
        var user = (await h.Store.GoogleSignInAsync(new("valid-" + Guid.NewGuid(), address), Guid.NewGuid(), material, Ct))!;
        var other = await Register(h);
        var dataset = (await Sync(h).PullForSessionAsync(user, null, 0, 1, false, null, null, Ct))!.DatasetId;
        var row = Row(h);
        await Sync(h).PushForSessionAsync(user, dataset, [row], h.Clock.GetUtcNow(), Ct);
        await Sync(h).PushForSessionAsync(user, dataset, [row with { Hlc = row.Hlc.Replace("-00000-", "-00001-", StringComparison.Ordinal), DeletedAt = h.Clock.GetUtcNow() }], h.Clock.GetUtcNow(), Ct);
        await Sync(h).PushForSessionAsync(other, dataset, [Row(h)], h.Clock.GetUtcNow(), Ct);
        await using (var session = await database.SessionAsync(user.UserId))
        {
            await using var age = session.Command("UPDATE userdata.documents SET accepted_at=$2 WHERE user_id=$1");
            age.Parameters.AddWithValue(user.UserId); age.Parameters.AddWithValue(h.Clock.GetUtcNow().AddDays(-31)); await age.ExecuteNonQueryAsync(Ct);
            await new SyncRetentionJob(h.Clock, new UuidV7IdGenerator(h.Clock)).HandleAsync(new QueueMessage(Guid.NewGuid(), "userdata.cleanup", "{}", user.UserId, 1), session, Ct);
            var writer = new QueueWriter(session, h.Clock, new UuidV7IdGenerator(h.Clock));
            var message = await writer.PublishAsync("test.private", new { text = "erasure-canary" }, Ct);
            await writer.EnqueueAsync("test.private", new { text = "erasure-canary" }, null, Ct);
            await using var marker = session.Command("INSERT INTO ops.processed_messages VALUES($1,'test.handler',$2)");
            marker.Parameters.AddWithValue(message); marker.Parameters.AddWithValue(h.Clock.GetUtcNow()); await marker.ExecuteNonQueryAsync(Ct);
            await new IdempotencyStore(session, h.Clock).WriteAsync("erase-" + user.UserId, "key", "fingerprint", new StoredResponse(200, "application/json", "private-response"u8.ToArray(), []), Ct);
            await session.CommitAsync(Ct);
        }
        var addressHash = h.Tokens.ProtectLookup("email-address", address);
        var ipHash = h.Tokens.ProtectLookup("email-ip", Guid.NewGuid().ToString());
        Assert.True(await h.Store.StartEmailAsync(Guid.NewGuid(), addressHash, RandomNumberGenerator.GetBytes(32), "signIn", null, ipHash, Ct));
        Assert.True(Assert.Single((await Sync(h).PullForSessionAsync(user, dataset, 0, 100, false, null, null, Ct))!.Changes).Compacted);
        Assert.NotEmpty((await Sync(h).PullForSessionAsync(user, dataset, 0, 100, true, null, null, Ct))!.Changes);
        var keysBefore = await KeyDigest();
        await using var provider = Services(h); await using var scope = provider.CreateAsyncScope();
        var deletion = scope.ServiceProvider.GetRequiredService<IAccountDeletion>();
        var previous = database.Recovery.File.Read();
        Assert.Equal(DeletionResult.Deleted, await deletion.DeleteAsync(user.UserId, user.SessionId, Ct));
        Assert.NotEqual(previous, database.Recovery.File.Read());
        Assert.Equal(keysBefore, await KeyDigest());
        await AssertNoOwnerRows(user.UserId, user.SessionId);
        Assert.Null(await h.Store.RotateAsync(material.RefreshHash, RandomNumberGenerator.GetBytes(32), Ct));
        Assert.Null(await h.Store.ReadSessionAsync(user.UserId, user.SessionId, Ct));
        Assert.NotNull(await h.Store.ReadSessionAsync(other.UserId, other.SessionId, Ct));
        Assert.Single((await Sync(h).PullForSessionAsync(other, dataset, 0, 100, false, null, null, Ct))!.Changes);
        Assert.Equal(dataset, (await Sync(h).PullForSessionAsync(other, null, 0, 1, false, null, null, Ct))!.DatasetId);
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var check = owner.CreateCommand("SELECT (SELECT count(*) FROM identity.signing_keys),(SELECT count(*) FROM identity.email_challenges WHERE address_hash=$1),(SELECT count(*) FROM identity.throttles WHERE bucket=$1),(SELECT count(*) FROM identity.throttles WHERE bucket=$2),(SELECT count(*) FROM ops.processed_messages p LEFT JOIN ops.outbox o ON o.id=p.message_id WHERE o.id IS NULL)");
        check.Parameters.AddWithValue(addressHash); check.Parameters.AddWithValue(ipHash);
        await using var reader = await check.ExecuteReaderAsync(Ct); Assert.True(await reader.ReadAsync(Ct));
        Assert.True(reader.GetInt64(0) > 0); Assert.Equal(0, reader.GetInt64(1)); Assert.Equal(0, reader.GetInt64(2)); Assert.Equal(1, reader.GetInt64(3)); Assert.Equal(0, reader.GetInt64(4));
        var committedGeneration = database.Recovery.File.Read();
        Assert.Equal(DeletionResult.Unauthorized, await deletion.DeleteAsync(user.UserId, user.SessionId, Ct));
        Assert.Equal(committedGeneration, database.Recovery.File.Read());
    }

    [Fact]
    public async Task Failed_participant_rolls_back_all_effects_and_known_generation_before_retry()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await Register(h);
        var dataset = (await Sync(h).PullForSessionAsync(user, null, 0, 1, false, null, null, Ct))!.DatasetId;
        await Sync(h).PushForSessionAsync(user, dataset, [Row(h)], h.Clock.GetUtcNow(), Ct);
        var fault = new FailOnce();
        await using var provider = Services(h, fault); await using var scope = provider.CreateAsyncScope();
        var deletion = scope.ServiceProvider.GetRequiredService<IAccountDeletion>();
        var previous = database.Recovery.File.Read();
        await Assert.ThrowsAsync<InvalidOperationException>(() => deletion.DeleteAsync(user.UserId, user.SessionId, Ct));
        Assert.Equal(previous, database.Recovery.File.Read());
        Assert.NotNull(await h.Store.ReadSessionAsync(user.UserId, user.SessionId, Ct));
        Assert.Single((await Sync(h).PullForSessionAsync(user, dataset, 0, 100, false, null, null, Ct))!.Changes);
        await using (var session = await database.SessionAsync(user.UserId)) { Assert.Equal(previous, await database.Recovery.VerifyAsync(session, Ct)); }
        Assert.Equal(DeletionResult.Deleted, await deletion.DeleteAsync(user.UserId, user.SessionId, Ct));
        await AssertNoOwnerRows(user.UserId, user.SessionId);
    }

    [Fact]
    public async Task Guest_can_erase_self_but_crafted_session_cannot_erase_another_account()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await h.GuestAsync(); var other = await h.GuestAsync();
        await using var provider = Services(h); await using var scope = provider.CreateAsyncScope();
        var deletion = scope.ServiceProvider.GetRequiredService<IAccountDeletion>();
        var guestAddress = h.Tokens.ProtectLookup("email-address", Guid.NewGuid() + "@example.invalid");
        Assert.True(await h.Store.StartEmailAsync(Guid.NewGuid(), guestAddress, RandomNumberGenerator.GetBytes(32), "link", user, RandomNumberGenerator.GetBytes(32), Ct));
        var previous = database.Recovery.File.Read();
        Assert.Equal(DeletionResult.Unauthorized, await deletion.DeleteAsync(user.UserId, other.SessionId, Ct));
        Assert.Equal(previous, database.Recovery.File.Read());
        Assert.NotNull(await h.Store.ReadSessionAsync(user.UserId, user.SessionId, Ct));
        Assert.Equal(DeletionResult.Deleted, await deletion.DeleteAsync(user.UserId, user.SessionId, Ct));
        await AssertNoOwnerRows(user.UserId, user.SessionId);
        Assert.NotNull(await h.Store.ReadSessionAsync(other.UserId, other.SessionId, Ct));
    }

    [Fact]
    [Trait("Rule", "05.6-lifecycle")]
    public async Task Refresh_and_sync_queued_behind_deletion_cannot_recreate_the_user()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var material = h.Material(); var user = (await h.Store.GoogleSignInAsync(new("valid-" + Guid.NewGuid(), "race@example.invalid"), Guid.NewGuid(), material, Ct))!;
        var dataset = (await Sync(h).PullForSessionAsync(user, null, 0, 1, false, null, null, Ct))!.DatasetId;
        await using var provider = Services(h); await using var scope = provider.CreateAsyncScope();
        await using var held = await database.SessionAsync(user.UserId); await UserLifecycleLock.AcquireAsync(held, user.UserId, Ct);
        var erase = scope.ServiceProvider.GetRequiredService<IAccountDeletion>().DeleteAsync(user.UserId, user.SessionId, Ct);
        await WaitForWaiters(1);
        var refresh = h.Store.RotateAsync(material.RefreshHash, RandomNumberGenerator.GetBytes(32), Ct);
        var push = Sync(h).PushForSessionAsync(user, dataset, [Row(h)], h.Clock.GetUtcNow(), Ct);
        await WaitForWaiters(3);
        await held.CommitAsync(Ct);
        Assert.Equal(DeletionResult.Deleted, await erase); Assert.Null(await refresh); Assert.Null(await push);
        await AssertNoOwnerRows(user.UserId, user.SessionId);
    }

    [Fact]
    [Trait("Rule", "04.3-erasure-coverage")]
    public async Task Missing_module_eraser_fails_closed_before_revocation_or_generation_change()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await h.GuestAsync();
        await using var provider = Services(h, extraModule: new MissingEraser()); await using var scope = provider.CreateAsyncScope();
        var before = database.Recovery.File.Read();
        Assert.Equal(DeletionResult.Unavailable, await scope.ServiceProvider.GetRequiredService<IAccountDeletion>().DeleteAsync(user.UserId, user.SessionId, Ct));
        Assert.Equal(before, database.Recovery.File.Read());
        Assert.NotNull(await h.Store.ReadSessionAsync(user.UserId, user.SessionId, Ct));
    }

    [Fact]
    [Trait("Rule", "04.3-erasure-coverage")]
    public async Task Every_actual_module_table_is_classified_and_no_global_table_hides_user_ownership()
    {
        var policies = ModuleCatalog.All.ToDictionary(module => module.Name.ToLowerInvariant(), module => module.UserData, StringComparer.Ordinal);
        policies.Add("ops", OpsErasure.Ownership);
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var catalog = owner.CreateCommand("""
            SELECT t.table_schema,t.table_name,EXISTS(SELECT 1 FROM information_schema.columns c
              WHERE c.table_schema=t.table_schema AND c.table_name=t.table_name AND c.column_name IN('user_id','session_id','address_hash'))
            FROM information_schema.tables t WHERE t.table_schema=ANY($1) AND t.table_type='BASE TABLE' AND t.table_name<>'__ef_migrations_history'
            """);
        catalog.Parameters.AddWithValue(policies.Keys.ToArray());
        await using var reader = await catalog.ExecuteReaderAsync(Ct);
        var actual = new HashSet<string>(StringComparer.Ordinal);
        while (await reader.ReadAsync(Ct))
        {
            var schema = reader.GetString(0); var table = reader.GetString(1); var policy = policies[schema]; actual.Add(schema + "." + table);
            Assert.True(policy.UserTables.Contains(table, StringComparer.Ordinal) || policy.GlobalTables.Contains(table, StringComparer.Ordinal), schema + "." + table);
            if (reader.GetBoolean(2)) { Assert.Contains(table, policy.UserTables); }
        }
        await reader.DisposeAsync();
        // Ownership propagates through real foreign keys regardless of a column's spelling.
        await using var foreignKeys = owner.CreateCommand("""
            WITH RECURSIVE owned(oid) AS (
              SELECT c.oid FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
              WHERE n.nspname||'.'||c.relname=ANY($1)
              UNION
              SELECT f.conrelid FROM pg_constraint f JOIN owned o ON f.confrelid=o.oid WHERE f.contype='f'
            ) SELECT n.nspname,c.relname FROM owned o JOIN pg_class c ON c.oid=o.oid
              JOIN pg_namespace n ON n.oid=c.relnamespace
            """);
        foreignKeys.Parameters.AddWithValue(policies.SelectMany(p => p.Value.UserTables.Select(table => p.Key + "." + table)).ToArray());
        await using var foreignReader = await foreignKeys.ExecuteReaderAsync(Ct);
        while (await foreignReader.ReadAsync(Ct))
        {
            Assert.True(policies.TryGetValue(foreignReader.GetString(0), out var policy), "Foreign-key owner schema must be classified.");
            Assert.Contains(foreignReader.GetString(1), policy.UserTables);
        }
        foreach (var (schema, policy) in policies)
        {
            foreach (var table in policy.UserTables.Concat(policy.GlobalTables)) { Assert.Contains(schema + "." + table, actual); }
            Assert.Empty(policy.UserTables.Intersect(policy.GlobalTables, StringComparer.Ordinal));
            if (schema != "ops" && policy.UserTables.Length > 0) { Assert.False(string.IsNullOrWhiteSpace(policy.Eraser)); }
        }
    }

    [Fact]
    public async Task Address_state_owned_by_another_linking_account_is_preserved()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var address = Guid.NewGuid() + "@example.invalid"; var user = await Register(h, address); var other = await h.GuestAsync();
        var addressHash = h.Tokens.ProtectLookup("email-address", address); var code = RandomNumberGenerator.GetBytes(32); var challenge = Guid.NewGuid();
        Assert.True(await h.Store.StartEmailAsync(challenge, addressHash, code, "link", other, RandomNumberGenerator.GetBytes(32), Ct));
        await using var provider = Services(h); await using var scope = provider.CreateAsyncScope();
        Assert.Equal(DeletionResult.Deleted, await scope.ServiceProvider.GetRequiredService<IAccountDeletion>().DeleteAsync(user.UserId, user.SessionId, Ct));
        await AssertNoOwnerRows(user.UserId, user.SessionId);
        Assert.NotNull(await h.Store.ReadSessionAsync(other.UserId, other.SessionId, Ct));
        var linked = await h.Store.ConsumeEmailAsync(challenge, code, "link", other, Guid.NewGuid(), h.Material(), Ct);
        Assert.NotNull(linked); Assert.Equal(other.UserId, linked.UserId); Assert.False(linked.IsAnonymous);
    }

    [Fact]
    [Trait("Rule", "04.3-database-only-events")]
    public async Task Erasure_participant_never_reads_a_secret_file_inside_the_transaction()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var address = Guid.NewGuid() + "@example.invalid"; var user = await Register(h, address);
        var hash = h.Tokens.ProtectLookup("email-address", address);
        Assert.True(await h.Store.StartEmailAsync(Guid.NewGuid(), hash, RandomNumberGenerator.GetBytes(32), "signIn", null, RandomNumberGenerator.GetBytes(32), Ct));
        await using var provider = Services(h); await using var scope = provider.CreateAsyncScope();
        var deletion = scope.ServiceProvider.GetRequiredService<IAccountDeletion>(); // Resolves/prepares all participants first.
        var saved = h.Options.PepperFile + ".saved"; File.Move(h.Options.PepperFile, saved);
        try { Assert.Equal(DeletionResult.Deleted, await deletion.DeleteAsync(user.UserId, user.SessionId, Ct)); }
        finally { File.Move(saved, h.Options.PepperFile); }
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var remaining = owner.CreateCommand("SELECT count(*) FROM identity.email_challenges WHERE address_hash=$1");
        remaining.Parameters.AddWithValue(hash); Assert.Equal(0L, await remaining.ExecuteScalarAsync(Ct));
    }

    private async Task<string> KeyDigest()
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var query = owner.CreateCommand("SELECT md5(string_agg(to_jsonb(k)::text,',' ORDER BY kid)) FROM identity.signing_keys k");
        return (string)(await query.ExecuteScalarAsync(Ct))!;
    }

    private async Task WaitForWaiters(int expected)
    {
        for (var i = 0; i < 200; i++)
        {
            await using var command = database.App.CreateCommand("SELECT count(*) FROM pg_locks WHERE locktype='advisory' AND NOT granted");
            if ((long)(await command.ExecuteScalarAsync(Ct))! >= expected) { return; }
            await Task.Delay(10, Ct);
        }
        Assert.Fail("Expected lifecycle lock waiters did not arrive.");
    }

    private async Task AssertNoOwnerRows(Guid user, Guid session)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        var columns = new List<(string Schema, string Table, string Column)>();
        await using (var catalog = owner.CreateCommand("SELECT table_schema,table_name,column_name FROM information_schema.columns WHERE table_schema IN('identity','account','userdata','ops') AND (column_name IN('user_id','session_id') OR (table_schema='identity' AND table_name='users' AND column_name='id'))"))
        {
            await using var reader = await catalog.ExecuteReaderAsync(Ct);
            while (await reader.ReadAsync(Ct)) { columns.Add((reader.GetString(0), reader.GetString(1), reader.GetString(2))); }
        }
        using var quote = new NpgsqlCommandBuilder();
        foreach (var column in columns)
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM {quote.QuoteIdentifier(column.Schema)}.{quote.QuoteIdentifier(column.Table)} WHERE {quote.QuoteIdentifier(column.Column)}=$1");
            query.Parameters.AddWithValue(column.Column == "session_id" ? session : user);
            Assert.True((long)(await query.ExecuteScalarAsync(Ct))! == 0, column.Schema + "." + column.Table + "." + column.Column);
        }
    }

    private sealed class MissingEraser : IModule
    {
        public string Name => "Missing";
        public UserDataOwnership UserData => new(["rows"], [], "missing.erase");
        public void AddServices(IServiceCollection services, IConfiguration configuration) { }
        public void MapEndpoints(Microsoft.AspNetCore.Routing.RouteGroupBuilder group) { }
    }

    private sealed class FailOnce : IOutboxHandler
    {
        private bool first = true;
        public string EventType => UserErasure.EventType;
        public string Name => "test.failure";
        public Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
        {
            if (first) { first = false; throw new InvalidOperationException("Synthetic participant failure."); }
            return Task.CompletedTask;
        }
    }
}
