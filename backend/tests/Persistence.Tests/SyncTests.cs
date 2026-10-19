using System.Globalization;
using System.Text.Json;
using FitnessBuddy.Modules.UserData.Domain;
using Npgsql;
using FitnessBuddy.Modules.UserData.Infrastructure;

namespace FitnessBuddy.Persistence.Tests;

public sealed class SyncTests(PostgresFixture database)
{
    private static readonly Guid DeviceA = Guid.Parse("0199e3c2-5b1a-7c3d-8e4f-0123456789ab");
    private static readonly Guid DeviceB = Guid.Parse("0199e3c2-5b1a-7c3d-8e4f-0123456789ac");
    private static readonly DateTimeOffset Now = DateTimeOffset.FromUnixTimeMilliseconds(1_760_351_234_567);
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private PostgresSyncStore Store => new(database.App, new FitnessBuddy.Modules.Identity.Infrastructure.PostgresIdentityStore(database.App, new TestClock()), TimeProvider.System, new FitnessBuddy.BuildingBlocks.Ids.UuidV7IdGenerator(TimeProvider.System));
    private static SyncVersion Version(Guid id, int counter, Guid? device = null, bool deleted = false, string text = "synthetic") =>
        new("diaryEntry", id, 1, $"1760351234567-{counter:D5}-{device ?? DeviceA}", device ?? DeviceA,
            deleted ? Now : null, JsonSerializer.SerializeToElement(new { text }));

    [Fact, Trait("Req", "AC-012")]
    public async Task Winners_losers_and_tombstones_survive_reversed_order_duplicates_and_conflicts()
    {
        var user = Guid.NewGuid(); var id = Guid.NewGuid();
        var first = Version(id, 0); var deleted = Version(id, 2, DeviceB, true); var stale = Version(id, 1);
        await Store.PushAsync(user, [first, deleted, stale, deleted, first], Now, Ct);
        var rows = await Store.PullAsync(user, 0, 500, false, Ct);
        Assert.Equal(deleted.Hlc, Assert.Single(rows.Changes).Version.Hlc);
        Assert.NotNull(rows.Changes[0].Version.DeletedAt);
        var history = await Store.PullAsync(user, 0, 500, true, Ct);
        Assert.Equal(2, history.Changes.Count);
        Assert.Contains(history.Changes, row => row.Version.Hlc == first.Hlc);
        Assert.Contains(history.Changes, row => row.Version.Hlc == stale.Hlc);
        var conflicts = await Store.PushAsync(user, [first with { Payload = JsonSerializer.SerializeToElement(new { changed = true }) }], Now, Ct);
        Assert.Equal("versionConflict", Assert.Single(conflicts).Reason);
        Assert.Equal(2, (await Store.PullAsync(user, 0, 500, true, Ct)).Changes.Count);
    }

    [Fact, Trait("Rule", "05.5-hlc")]
    public async Task Shared_hlc_vectors_and_future_admission_bound_are_exact()
    {
        var valid = true;
        var ordered = new List<string>();
        foreach (var line in await File.ReadAllLinesAsync(Path.Combine(AppContext.BaseDirectory, "hlc_cases.yaml"), Ct))
        {
            if (line == "invalid:") { valid = false; }
            if (line.StartsWith("  - '", StringComparison.Ordinal))
            {
                var text = line[5..^1].Replace("\\n", "\n", StringComparison.Ordinal);
                Assert.Equal(valid, SyncRules.IsHlc(text));
                if (valid) { ordered.Add(text); }
            }
        }
        for (var index = 1; index < ordered.Count; index++) { Assert.True(string.CompareOrdinal(ordered[index - 1], ordered[index]) < 0); }
        await using var sort = database.App.CreateCommand("SELECT value FROM unnest($1::text[]) AS value ORDER BY value COLLATE \"C\"");
        sort.Parameters.AddWithValue(ordered.AsEnumerable().Reverse().ToArray());
        var actual = new List<string>();
        await using (var reader = await sort.ExecuteReaderAsync(Ct))
        {
            while (await reader.ReadAsync(Ct)) { actual.Add(reader.GetString(0)); }
        }
        Assert.Equal(ordered, actual);
        var row = Version(Guid.NewGuid(), 0);
        var wall = Now.ToUnixTimeMilliseconds();
        Assert.Null(SyncRules.InvalidReason(row with { Hlc = $"{wall + 300_000:D13}-00000-{DeviceA}" }, Now));
        var rejected = await Store.PushAsync(Guid.NewGuid(), [row with { Hlc = $"{wall + 300_001:D13}-00000-{DeviceA}" }], Now, Ct);
        Assert.Equal("clockDrift", Assert.Single(rejected).Reason);
        Assert.Equal("unsupported", SyncRules.InvalidReason(row with { DeviceId = DeviceB }, Now));
    }

    [Fact, Trait("Req", "AC-012")]
    public async Task Tombstone_instants_accept_rfc3339_offsets_and_store_utc()
    {
        var user = Guid.NewGuid();
        var version = Version(Guid.NewGuid(), 0) with { DeletedAt = Now.ToOffset(TimeSpan.FromHours(3)) };
        Assert.Equal("accepted", Assert.Single(await Store.PushAsync(user, [version], Now, Ct)).Status);
        var stored = Assert.Single((await Store.PullAsync(user, 0, 1, false, Ct)).Changes).Version.DeletedAt;
        Assert.Equal(Now, stored);
        Assert.Equal(TimeSpan.Zero, stored!.Value.Offset);
    }

    [Fact, Trait("Rule", "04.6-rls")]
    public async Task Both_document_and_history_tables_force_user_isolation_and_anonymous_reads_are_empty()
    {
        var userA = Guid.NewGuid(); var userB = Guid.NewGuid(); var id = Guid.NewGuid();
        await Store.PushAsync(userA, [Version(id, 0), Version(id, 1, DeviceB)], Now, Ct);
        await Store.PushAsync(userB, [Version(id, 2)], Now, Ct);
        await using var session = await database.SessionAsync(userA);
        foreach (var table in new[] { "documents", "row_history" })
        {
            await using var count = session.Command($"SELECT count(*) FROM userdata.{table} WHERE user_id<>$1");
            count.Parameters.AddWithValue(userA);
            Assert.Equal(0L, await count.ExecuteScalarAsync(Ct));
        }
        await using var anonymous = await database.SessionAsync();
        await using var hidden = anonymous.Command("SELECT count(*) FROM userdata.documents UNION ALL SELECT count(*) FROM userdata.row_history");
        await using var reader = await hidden.ExecuteReaderAsync(Ct);
        while (await reader.ReadAsync(Ct)) { Assert.Equal(0L, reader.GetInt64(0)); }
    }

    [Fact, Trait("Rule", "04.6-rls")]
    public async Task Both_tables_reject_cross_user_inserts_with_check_and_force_rls()
    {
        foreach (var table in new[] { "documents", "row_history" })
        {
            await using var session = await database.SessionAsync(Guid.NewGuid());
            var extraColumn = table == "row_history" ? ",replaced_at" : "";
            var extraValue = table == "row_history" ? ",CURRENT_TIMESTAMP" : "";
            await using var command = session.Command($"INSERT INTO userdata.{table}(user_id,entity,id,schema_version,hlc,device_id,payload{extraColumn}) VALUES($1,'weighIn',$2,1,$3,$4,'{{}}'{extraValue})");
            command.Parameters.AddWithValue(Guid.NewGuid()); command.Parameters.AddWithValue(Guid.NewGuid());
            command.Parameters.AddWithValue(Version(Guid.NewGuid(), 0).Hlc); command.Parameters.AddWithValue(DeviceA);
            var error = await Assert.ThrowsAsync<PostgresException>(() => command.ExecuteNonQueryAsync(Ct));
            Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, error.SqlState);
        }
        await using var flags = database.App.CreateCommand("SELECT relrowsecurity AND relforcerowsecurity FROM pg_class WHERE oid IN ('userdata.documents'::regclass,'userdata.row_history'::regclass)");
        await using var reader = await flags.ExecuteReaderAsync(Ct);
        var count = 0;
        while (await reader.ReadAsync(Ct)) { Assert.True(reader.GetBoolean(0)); count++; }
        Assert.Equal(2, count);
    }

    [Fact, Trait("Rule", "05.5-cursors")]
    public async Task Same_user_push_cannot_commit_past_an_uncommitted_sequence()
    {
        var user = Guid.NewGuid(); var id = Guid.NewGuid();
        await using var first = await database.SessionAsync(user);
        await using var locked = first.Command("SELECT pg_advisory_xact_lock(hashtextextended($1, 4603912))");
        locked.Parameters.AddWithValue(user.ToString());
        await locked.ExecuteNonQueryAsync(Ct);
        await using var insert = first.Command("""
            INSERT INTO userdata.documents(user_id,entity,id,schema_version,hlc,device_id,payload)
            VALUES($1,'diaryEntry',$2,1,$3,$4,'{}') RETURNING server_seq
            """);
        insert.Parameters.AddWithValue(user); insert.Parameters.AddWithValue(id);
        insert.Parameters.AddWithValue(Version(id, 0).Hlc); insert.Parameters.AddWithValue(DeviceA);
        var firstSequence = (long)(await insert.ExecuteScalarAsync(Ct))!;
        var second = Store.PushAsync(user, [Version(Guid.NewGuid(), 1)], Now, Ct);
        var blocked = false;
        for (var attempt = 0; attempt < 100; attempt++)
        {
            await using var probe = database.App.CreateCommand("SELECT EXISTS(SELECT 1 FROM pg_locks WHERE locktype='advisory' AND NOT granted)");
            if ((bool)(await probe.ExecuteScalarAsync(Ct))!) { blocked = true; break; }
            await Task.Delay(20, Ct);
        }
        Assert.True(blocked, "The second push must be blocked before allocating a sequence.");
        Assert.Empty((await Store.PullAsync(user, 0, 500, false, Ct)).Changes);
        await first.CommitAsync(Ct);
        await second;
        var page1 = await Store.PullAsync(user, 0, 1, false, Ct);
        Assert.Equal(firstSequence.ToString(CultureInfo.InvariantCulture), page1.NextCursor);
        var page2 = await Store.PullAsync(user, firstSequence, 1, false, Ct);
        Assert.Single(page2.Changes);
        Assert.True(long.Parse(page2.NextCursor, CultureInfo.InvariantCulture) > firstSequence);
        var empty = await Store.PullAsync(user, long.Parse(page2.NextCursor, CultureInfo.InvariantCulture), 1, false, Ct);
        Assert.Empty(empty.Changes); Assert.Equal(page2.NextCursor, empty.NextCursor);
    }

    [Fact, Trait("Rule", "05.5-cursors")]
    public async Task Rows_updated_while_paging_move_forward_and_are_delivered_again()
    {
        var user = Guid.NewGuid(); var a = Guid.NewGuid(); var b = Guid.NewGuid();
        await Store.PushAsync(user, [Version(a, 0), Version(b, 0)], Now, Ct);
        var first = await Store.PullAsync(user, 0, 1, false, Ct);
        await Store.PushAsync(user, [Version(a, 1)], Now, Ct);
        var rest = await Store.PullAsync(user, long.Parse(first.NextCursor, CultureInfo.InvariantCulture), 500, false, Ct);
        Assert.Equal(2, rest.Changes.Count);
        Assert.Contains(rest.Changes, row => row.Version.Id == a && row.Version.Hlc == Version(a, 1).Hlc);
    }

}
