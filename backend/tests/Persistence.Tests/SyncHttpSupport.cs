using System.Net;
using System.Text;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.UserData.Infrastructure;

namespace FitnessBuddy.Persistence.Tests;

// B19 D10/S4: the B18 sync HTTP helpers that B19 also uses, moved here unchanged
// (the fixture is now a parameter). Used by ChatProposalSyncTests and BodyTargetsSyncTests.
internal static class SyncHttpSupport
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    public static async Task<JsonElement[]> PullAll(HttpClient client, Guid dataset)
    {
        var rows = new List<JsonElement>(); var cursor = "0";
        while (true)
        {
            using var response = await client.GetAsync($"/v1/sync/pull?cursor={cursor}&limit=500&datasetId={dataset}", Ct);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var page = await PersonalFoodHttp.Json(response);
            var changes = page.GetProperty("changes").EnumerateArray().ToArray();
            rows.AddRange(changes); cursor = page.GetProperty("nextCursor").GetString()!;
            // Stop on an empty page, as the app must (never on changes < limit).
            if (changes.Length == 0) { return [.. rows]; }
        }
    }

    public static IEnumerable<IReadOnlyList<T>> ByteBoundedCases<T>(IReadOnlyList<T> cases, Func<T, string> raw)
    {
        var batch = new List<T>(); var bytes = 0;
        foreach (var item in cases)
        {
            var size = Encoding.UTF8.GetByteCount(raw(item)) + 512;
            if (batch.Count > 0 && (bytes + size > 128 * 1024 || batch.Count == 100)) { yield return batch.ToArray(); batch.Clear(); bytes = 0; }
            batch.Add(item); bytes += size;
        }
        if (batch.Count > 0) { yield return batch.ToArray(); }
    }

    public static async Task<long> HistoryCount(PostgresFixture database, Guid user, string entity, Guid id)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var query = owner.CreateCommand("SELECT count(*) FROM userdata.row_history WHERE user_id=$1 AND entity=$2 AND id=$3");
        query.Parameters.AddWithValue(user); query.Parameters.AddWithValue(entity); query.Parameters.AddWithValue(id);
        return (long)(await query.ExecuteScalarAsync(Ct))!;
    }

    public static async Task AgeAndCleanup(PostgresFixture database, IdentityHarness h, Guid user, string entity, Guid id, bool expireHistory)
    {
        // Synthetic aging is operator-only (migrator connection); production grants stay unchanged.
        await using (var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection))
        {
            await using var age = owner.CreateCommand("UPDATE userdata.documents SET accepted_at=$4 WHERE user_id=$1 AND entity=$2 AND id=$3");
            age.Parameters.AddWithValue(user); age.Parameters.AddWithValue(entity); age.Parameters.AddWithValue(id); age.Parameters.AddWithValue(h.Clock.GetUtcNow().AddDays(-31));
            await age.ExecuteNonQueryAsync(Ct);
            if (expireHistory)
            {
                await using var history = owner.CreateCommand("UPDATE userdata.row_history SET replaced_at=$4 WHERE user_id=$1 AND entity=$2 AND id=$3");
                history.Parameters.AddWithValue(user); history.Parameters.AddWithValue(entity); history.Parameters.AddWithValue(id); history.Parameters.AddWithValue(h.Clock.GetUtcNow().AddDays(-31));
                await history.ExecuteNonQueryAsync(Ct);
            }
        }
        await Cleanup(database, h, user);
    }

    public static async Task Cleanup(PostgresFixture database, IdentityHarness h, Guid user)
    {
        await using var session = await database.SessionAsync(user);
        await new SyncRetentionJob(h.Clock, new UuidV7IdGenerator(h.Clock)).HandleAsync(new(Guid.NewGuid(), "userdata.cleanup", "{}", user, 1), session, Ct);
        await session.CommitAsync(Ct);
    }
}
