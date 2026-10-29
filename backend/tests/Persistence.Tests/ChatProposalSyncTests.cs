using System.Net;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Host.Http;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.TestData;
using static FitnessBuddy.Persistence.Tests.SyncHttpSupport;
using Row = FitnessBuddy.Persistence.Tests.PersonalFoodHttp.Row;

namespace FitnessBuddy.Persistence.Tests;

// B18: chatMessage and proposal ride the entity-agnostic B05 storage (push/pull/history,
// LWW, receipts, retention fences, RLS, erasure) through the real authenticated host.
[Trait("Req", "AC-010")]
[Trait("Req", "AC-012")]
public sealed class ChatProposalSyncTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private static readonly string[] ExactStringFields = ["budgetJson", "interpretationJson", "draftJson", "text"];
    public static TheoryData<string> Entities => new(ChatProposalCases.Entities);

    [Fact, Trait("Rule", "05.5-payload-validation")]
    public async Task Batched_matrix_preserves_result_order_and_valid_neighbors_without_persisting_invalid_versions()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var invalidIds = new List<Guid>(); var accepted = new List<Row>(); var batches = 0;
        // Raw JSON keeps duplicate keys and lone-surrogate escapes through HTTP binding.
        foreach (var group in ByteBoundedCases(ChatProposalCases.All(), c => c.Raw))
        {
            batches++;
            var entries = group.Select(c => (Case: c, Row: PersonalFoodHttp.NewRow(h, c.Raw, c.Deleted ? h.Clock.GetUtcNow() : null, c.Entity))).ToArray();
            var neighbor = PersonalFoodHttp.NewRow(h, entity: ChatProposalCases.Entities[batches % 2]); accepted.Add(neighbor);
            using var response = await PersonalFoodHttp.Push(client, h, dataset, [neighbor, .. entries.Select(e => e.Row)]);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var ack = await response.Content.ReadAsStringAsync(Ct);
            // Error responses carry no content: only id/entity/hlc/status/reason come back.
            Assert.DoesNotContain("synthetic", ack, StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain("Json", ack, StringComparison.Ordinal);
            using var result = JsonDocument.Parse(ack);
            var results = result.RootElement.GetProperty("results").EnumerateArray().ToArray();
            Assert.Equal(entries.Length + 1, results.Length);
            Assert.Equal("accepted", results[0].GetProperty("status").GetString());
            for (var i = 0; i < entries.Length; i++)
            {
                var (test, row) = entries[i]; var item = results[i + 1];
                Assert.Equal(row.Id, item.GetProperty("id").GetGuid());
                Assert.Equal(row.Entity, item.GetProperty("entity").GetString());
                Assert.Equal(row.Hlc, item.GetProperty("hlc").GetString());
                Assert.True((test.Valid ? "accepted" : "invalid") == item.GetProperty("status").GetString(), test.Id);
                Assert.Equal(test.Valid ? null : "invalidPayload", item.GetProperty("reason").GetString());
                Assert.Equal(["entity", "hlc", "id", "reason", "status"], item.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
                if (test.Valid) { accepted.Add(row); } else { invalidIds.Add(row.Id); }
            }
        }
        Assert.True(batches > 1);
        Assert.NotEmpty(invalidIds);
        // Privileged inventory: invalid inputs never reached any content or receipt table.
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        foreach (var table in new[] { "documents", "row_history", "version_receipts" })
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1 AND id=ANY($2)");
            query.Parameters.AddWithValue(user.UserId); query.Parameters.AddWithValue(invalidIds.ToArray());
            Assert.Equal(0L, await query.ExecuteScalarAsync(Ct));
        }
        var rows = await PullAll(client, dataset);
        Assert.Equal(accepted.Count, rows.Length);
        foreach (var row in accepted) { AssertSame(row, rows.Single(r => r.GetProperty("id").GetGuid() == row.Id)); }
    }

    [Fact, Trait("Rule", "B18.opaque-engine-json")]
    public async Task B18_opaque_interpretation_draft_and_budget_JSON_round_trip_without_engine_validation()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        // Real codec output plus odd-but-well-formed opaque JSON (roots, unknown versions, engine-invalid
        // keys, inner whitespace, near-limit sizes): all stored and served exactly as sent.
        var cases = ChatProposalCases.Corpus().Where(c => c.Valid && !c.Deleted && (c.Id.StartsWith("codec-", StringComparison.Ordinal) ||
            c.Id.Contains("Json-", StringComparison.Ordinal))).ToList();
        var spaced = ChatProposalCases.With(ChatProposalCases.Baseline("proposal"), "draftJson", "{ \"a\" :  [ 1 , 2 ] }\n");
        cases.Add(new("draft-whitespace", "proposal", spaced, true));
        Assert.Contains(cases, c => c.Id == "codec-worst-choices-128-card-1");
        var rows = cases.Select(c => PersonalFoodHttp.NewRow(h, c.Raw, entity: c.Entity)).ToArray();
        foreach (var batch in rows.Chunk(40))
        {
            using var push = await PersonalFoodHttp.Push(client, h, dataset, batch);
            Assert.All((await PersonalFoodHttp.Json(push)).GetProperty("results").EnumerateArray(), r => Assert.Equal("accepted", r.GetProperty("status").GetString()));
            // Same payload, newer HLC: the first version moves to history unchanged.
            using var update = await PersonalFoodHttp.Push(client, h, dataset, batch.Select(r => r with { Hlc = PersonalFoodHttp.Hlc(h, 1) }).ToArray());
            Assert.All((await PersonalFoodHttp.Json(update)).GetProperty("results").EnumerateArray(), r => Assert.Equal("accepted", r.GetProperty("status").GetString()));
        }
        var pulled = await PullAll(client, dataset);
        Assert.Equal(rows.Length, pulled.Length);
        foreach (var row in rows)
        {
            AssertSame(row with { Hlc = PersonalFoodHttp.Hlc(h, 1) }, pulled.Single(r => r.GetProperty("id").GetGuid() == row.Id));
            AssertSame(row, Assert.Single((await PersonalFoodHttp.Page(client, dataset, row.Id, row.Entity)).GetProperty("changes").EnumerateArray()));
        }
        Assert.Equal("{ \"a\" :  [ 1 , 2 ] }\n", pulled.Single(r => r.GetProperty("id").GetGuid() == rows[^1].Id).GetProperty("payload").GetProperty("draftJson").GetString());
    }

    [Fact, Trait("Rule", "B18.no-cross-row-validation")]
    public async Task B18_row_admission_does_not_require_related_message_or_card_rows()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var card = JsonNode.Parse(ChatProposalCases.Raw("codec-follow-up-m2-card-1"))!.AsObject();
        card["originMessageId"] = Guid.NewGuid().ToString(); card["budgetMessageId"] = Guid.NewGuid().ToString();
        var rows = new[]
        {
            PersonalFoodHttp.NewRow(h, card.ToJsonString(), entity: "proposal"),                                  // bound to absent messages
            PersonalFoodHttp.NewRow(h, ChatProposalCases.Raw("chat-budget-foreign-card"), entity: "chatMessage"), // budget names an absent card
            PersonalFoodHttp.NewRow(h, ChatProposalCases.Raw("codec-multi-card-card-2"), entity: "proposal"),      // sibling cards and message never sent
            PersonalFoodHttp.NewRow(h, ChatProposalCases.Raw("proposal-foodlog-null-refs"), entity: "proposal"),   // foodLog with null refs (no kind pairing)
        };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, rows))
        { Assert.Equal(["accepted", "accepted", "accepted", "accepted"], (await PersonalFoodHttp.Json(push)).GetProperty("results").EnumerateArray().Select(r => r.GetProperty("status").GetString())); }
        var pulled = await PullAll(client, dataset);
        Assert.Equal(rows.Length, pulled.Length);
        foreach (var row in rows) { AssertSame(row, pulled.Single(r => r.GetProperty("id").GetGuid() == row.Id)); }
        Assert.Single(pulled, r => r.GetProperty("entity").GetString() == "chatMessage");
    }

    [Fact, Trait("Req", "AI-045"), Trait("Rule", "B18.fresh-device-pull")]
    public async Task Pending_proposal_and_assistant_message_survive_fresh_device_pull()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var subject = "valid-" + Guid.NewGuid();
        var original = (await h.Store.GoogleSignInAsync(new GoogleIdentity(subject, "fresh-device@example.invalid"), Guid.NewGuid(), h.Material(), Ct))!;
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var client = await PersonalFoodHttp.Client(factory, h, original);
        var dataset = await PersonalFoodHttp.Dataset(client);
        // Row ids are the codec ids, so the card's budgetMessageId names the synced message row.
        using var messageRaw = JsonDocument.Parse(ChatProposalCases.Raw("codec-six-item-message"));
        using var budget = JsonDocument.Parse(messageRaw.RootElement.GetProperty("budgetJson").GetString()!);
        var messageId = budget.RootElement.GetProperty("messageId").GetGuid();
        var cardId = Guid.Parse(budget.RootElement.GetProperty("cards")[0].GetString()!);
        var message = PersonalFoodHttp.NewRow(h, ChatProposalCases.Raw("codec-six-item-message"), entity: "chatMessage") with { Id = messageId };
        var card = PersonalFoodHttp.NewRow(h, ChatProposalCases.Raw("codec-six-item-card-1"), entity: "proposal") with { Id = cardId };
        var user = PersonalFoodHttp.NewRow(h, ChatProposalCases.Raw("chat-user-row"), entity: "chatMessage");
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [user, message, card]))
        { Assert.All((await PersonalFoodHttp.Json(push)).GetProperty("results").EnumerateArray(), r => Assert.Equal("accepted", r.GetProperty("status").GetString())); }
        // A reinstall: a new sign-in for the same account on a new device id, pulling from cursor 0.
        var device = Guid.NewGuid();
        var fresh = (await h.Store.GoogleSignInAsync(new GoogleIdentity(subject, "fresh-device@example.invalid"), Guid.NewGuid(), new SessionMaterial(Guid.NewGuid(), device, RandomNumberGenerator.GetBytes(32)), Ct))!;
        Assert.Equal(original.UserId, fresh.UserId); Assert.NotEqual(original.SessionId, fresh.SessionId);
        using var reinstalled = factory.CreateClient();
        reinstalled.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); reinstalled.DefaultRequestHeaders.Add("X-Platform", "android"); reinstalled.DefaultRequestHeaders.Add("X-Device-Id", device.ToString());
        reinstalled.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", await h.Tokens.SignAsync(fresh, Ct));
        using var response = await reinstalled.GetAsync("/v1/sync/pull?cursor=0&limit=500", Ct);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var page = await PersonalFoodHttp.Json(response);
        Assert.Equal(dataset, page.GetProperty("datasetId").GetGuid());
        var changes = page.GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(3, changes.Length);
        foreach (var row in new[] { user, message, card }) { AssertSame(row, changes.Single(c => c.GetProperty("id").GetGuid() == row.Id)); }
        var pending = changes.Single(c => c.GetProperty("id").GetGuid() == cardId);
        Assert.Equal("pending", pending.GetProperty("payload").GetProperty("status").GetString());
        Assert.Equal(messageId, pending.GetProperty("payload").GetProperty("budgetMessageId").GetGuid());
        Assert.Equal(h.Device, pending.GetProperty("deviceId").GetGuid());
    }

    [Fact, Trait("Rule", "B18.max-row-fits-push")]
    public async Task Maximum_size_rows_fit_one_push_and_round_trip()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var api = new IdentityApiTests.IdentityApi(database, h);
        // TestServer has no body limit: these pushes go through real Kestrel and its 256 KiB cap.
        await using var factory = api.WithWebHostBuilder(_ => { });
        factory.UseKestrel(0);
        using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        const char Wide = '\u4e2d'; // BMP, three UTF-8 bytes, one UTF-16 unit
        // Every bounded field at its UTF-16 limit; JSON fields hold one JSON string literal of 32768 units.
        var json = "\\\"" + new string(Wide, 32766) + "\\\"";
        var proposal = ChatProposalCases.Baseline("proposal")
            .Replace("\"origin\":\"synthetic\"", $"\"origin\":\"{new string(Wide, 128)}\"", StringComparison.Ordinal)
            .Replace("\"kind\":\"foodLog\"", $"\"kind\":\"{new string(Wide, 32)}\"", StringComparison.Ordinal)
            .Replace("\"interpretationJson\":\"[]\"", $"\"interpretationJson\":\"{json}\"", StringComparison.Ordinal)
            .Replace("\"draftJson\":\"{}\"", $"\"draftJson\":\"{json}\"", StringComparison.Ordinal);
        var message = ChatProposalCases.Baseline("chatMessage")
            .Replace("\"origin\":\"synthetic\"", $"\"origin\":\"{new string(Wide, 128)}\"", StringComparison.Ordinal)
            .Replace("\"text\":\"Synthetic reply\"", $"\"text\":\"{new string(Wide, 8192)}\"", StringComparison.Ordinal)
            .Replace("\"language\":\"en\"", $"\"language\":\"{new string(Wide, 16)}\"", StringComparison.Ordinal)
            .Replace("\"budgetJson\":\"{}\"", $"\"budgetJson\":\"{json}\"", StringComparison.Ordinal);
        foreach (var (entity, raw) in new[] { ("proposal", proposal), ("chatMessage", message) })
        {
            using (var parsed = JsonDocument.Parse(raw))
            {
                foreach (var field in ExactStringFields.Where(f => parsed.RootElement.TryGetProperty(f, out _)))
                { Assert.Equal(field == "text" ? 8192 : 32768, parsed.RootElement.GetProperty(field).GetString()!.Length); }
            }
            var row = PersonalFoodHttp.NewRow(h, raw, entity: entity);
            long bytes = Encoding.UTF8.GetByteCount(PersonalFoodHttp.Body(h, dataset, [row]));
            // D14: unescaped UTF-8 fits; the same row with \u-escaped non-ASCII would not.
            Assert.InRange(bytes, entity == "proposal" ? 196_608L : 122_880L, HttpSetup.MaxRequestBodyBytes - 1);
            if (entity == "proposal") { Assert.True(Encoding.UTF8.GetByteCount(JsonNode.Parse(raw)!.ToJsonString()) > HttpSetup.MaxRequestBodyBytes); }
            using var push = await PersonalFoodHttp.Push(client, h, dataset, [row]);
            Assert.Equal(HttpStatusCode.OK, push.StatusCode);
            Assert.Equal("accepted", (await PersonalFoodHttp.Json(push)).GetProperty("results")[0].GetProperty("status").GetString());
            AssertSame(row, (await PullAll(client, dataset)).Single(r => r.GetProperty("id").GetGuid() == row.Id));
        }
    }

    [Theory, MemberData(nameof(Entities)), Trait("Rule", "05.5-version-identity")]
    public async Task Lww_preserves_displaced_and_incoming_losers_and_replays_are_immutable(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client); var first = PersonalFoodHttp.NewRow(h, entity: entity);
        var winner = first with { Hlc = PersonalFoodHttp.Hlc(h, 2) }; var stale = first with { Hlc = PersonalFoodHttp.Hlc(h, 1) };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [first, winner, stale, winner]))
        {
            Assert.Equal(HttpStatusCode.OK, push.StatusCode);
            Assert.Equal(["accepted", "accepted", "stale", "accepted"], (await PersonalFoodHttp.Json(push)).GetProperty("results").EnumerateArray().Select(r => r.GetProperty("status").GetString()));
        }
        var history = (await PersonalFoodHttp.Page(client, dataset, first.Id, entity)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(2, history.Length); Assert.Contains(history, r => r.GetProperty("hlc").GetString() == first.Hlc); Assert.Contains(history, r => r.GetProperty("hlc").GetString() == stale.Hlc);
        Assert.All(history, r => AssertSame(first, r, hlc: false));
        Assert.Equal(winner.Hlc, Assert.Single((await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray()).GetProperty("hlc").GetString());
        // A replay of an accepted (entity, id, hlc) with different content is a conflict, never an overwrite.
        var changed = first with { Raw = entity == "chatMessage" ? ChatProposalCases.With(first.Raw, "text", "Changed reply") : ChatProposalCases.With(first.Raw, "draftJson", "{\"changed\":true}") };
        using var conflict = await PersonalFoodHttp.Push(client, h, dataset, [changed]);
        Assert.Equal("versionConflict", (await PersonalFoodHttp.Json(conflict)).GetProperty("results")[0].GetProperty("reason").GetString());
        Assert.Equal(2, (await PersonalFoodHttp.Page(client, dataset, first.Id, entity)).GetProperty("changes").GetArrayLength());
        // Same entity/id under the other B18 entity is a different document.
        var twin = first with { Entity = entity == "chatMessage" ? "proposal" : "chatMessage", Raw = PersonalFoodHttp.Fixture(entity == "chatMessage" ? "proposal" : "chatMessage") };
        using (var other = await PersonalFoodHttp.Push(client, h, dataset, [twin])) { Assert.Equal("accepted", (await PersonalFoodHttp.Json(other)).GetProperty("results")[0].GetProperty("status").GetString()); }
        Assert.Equal(2, (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").GetArrayLength());
    }

    [Theory, MemberData(nameof(Entities)), Trait("Rule", "05.5-retention")]
    public async Task Tombstones_compact_by_acceptance_time_and_fence_prevents_resurrection(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client); var first = PersonalFoodHttp.NewRow(h, entity: entity);
        // A23 clear history (AC-033) sends scrubbed, still-valid tombstone payloads.
        var scrubbed = ChatProposalCases.Raw(entity == "chatMessage" ? "chat-tombstone-scrubbed" : "proposal-tombstone-scrubbed");
        var tombstone = first with { Hlc = PersonalFoodHttp.Hlc(h, 1), DeletedAt = h.Clock.GetUtcNow().AddYears(-5), Raw = scrubbed };
        using (var push = await PersonalFoodHttp.Push(client, h, dataset, [first, tombstone]))
        { Assert.Equal(["accepted", "accepted"], (await PersonalFoodHttp.Json(push)).GetProperty("results").EnumerateArray().Select(r => r.GetProperty("status").GetString())); }
        // Compaction is by acceptance time, not by the client's deletedAt.
        await Cleanup(database, h, user.UserId);
        var live = Assert.Single((await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray());
        Assert.False(live.GetProperty("compacted").GetBoolean()); AssertSame(tombstone, live);
        Assert.Equal(1L, await HistoryCount(database, user.UserId, entity, first.Id));
        await AgeAndCleanup(database, h, user.UserId, entity, first.Id, expireHistory: true);
        Assert.Equal(0L, await HistoryCount(database, user.UserId, entity, first.Id));
        var fence = Assert.Single((await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray());
        Assert.True(fence.GetProperty("compacted").GetBoolean()); Assert.Empty(fence.GetProperty("payload").EnumerateObject());
        Assert.Equal(tombstone.Hlc, fence.GetProperty("hlc").GetString());
        Assert.Empty((await PersonalFoodHttp.Page(client, dataset, first.Id, entity)).GetProperty("changes").EnumerateArray());
        // An older version (e.g. a stale device re-uploading) cannot resurrect the row.
        using (var old = await PersonalFoodHttp.Push(client, h, dataset, [first])) { Assert.Equal("stale", (await PersonalFoodHttp.Json(old)).GetProperty("results")[0].GetProperty("status").GetString()); }
        Assert.True(Assert.Single((await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray()).GetProperty("compacted").GetBoolean());
        var restore = first with { Hlc = PersonalFoodHttp.Hlc(h, 2) };
        using (var response = await PersonalFoodHttp.Push(client, h, dataset, [restore])) { Assert.Equal("accepted", (await PersonalFoodHttp.Json(response)).GetProperty("results")[0].GetProperty("status").GetString()); }
        var restored = Assert.Single((await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray());
        Assert.False(restored.GetProperty("compacted").GetBoolean()); AssertSame(restore, restored);
    }

    [Theory, MemberData(nameof(Entities)), Trait("Rule", "04.6-rls")]
    public async Task Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var a = await PersonalFoodHttp.Register(h); var b = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var ca = await PersonalFoodHttp.Client(factory, h, a); using var cb = await PersonalFoodHttp.Client(factory, h, b);
        var dataset = await PersonalFoodHttp.Dataset(ca); var row = PersonalFoodHttp.NewRow(h, entity: entity);
        using (var push = await PersonalFoodHttp.Push(ca, h, dataset, [row, row with { Hlc = PersonalFoodHttp.Hlc(h, 1) }])) { Assert.Equal(HttpStatusCode.OK, push.StatusCode); }
        Assert.Empty((await PersonalFoodHttp.Page(cb, dataset)).GetProperty("changes").EnumerateArray());
        Assert.Empty((await PersonalFoodHttp.Page(cb, dataset, row.Id, entity)).GetProperty("changes").EnumerateArray());
        Assert.Single((await PersonalFoodHttp.Page(ca, dataset, row.Id, entity)).GetProperty("changes").EnumerateArray());
        using (var tombstone = await PersonalFoodHttp.Push(ca, h, dataset, [row with { Hlc = PersonalFoodHttp.Hlc(h, 2), DeletedAt = h.Clock.GetUtcNow() }])) { Assert.Equal(HttpStatusCode.OK, tombstone.StatusCode); }
        await AgeAndCleanup(database, h, a.UserId, entity, row.Id, expireHistory: false);
        Assert.True(Assert.Single((await PersonalFoodHttp.Page(ca, dataset)).GetProperty("changes").EnumerateArray()).GetProperty("compacted").GetBoolean());
        Assert.Empty((await PersonalFoodHttp.Page(cb, dataset)).GetProperty("changes").EnumerateArray());
        Assert.Empty((await PersonalFoodHttp.Page(cb, dataset, row.Id, entity)).GetProperty("changes").EnumerateArray());
        // B's same (entity, id) is its own document: A's fence neither blocks nor reveals it.
        using (var own = await PersonalFoodHttp.Push(cb, h, dataset, [row])) { Assert.Equal("accepted", (await PersonalFoodHttp.Json(own)).GetProperty("results")[0].GetProperty("status").GetString()); }
        AssertSame(row, Assert.Single((await PersonalFoodHttp.Page(cb, dataset)).GetProperty("changes").EnumerateArray()));
        Assert.True(Assert.Single((await PersonalFoodHttp.Page(ca, dataset)).GetProperty("changes").EnumerateArray()).GetProperty("compacted").GetBoolean());
    }

    [Theory, MemberData(nameof(Entities)), Trait("Rule", "04.6-authz")]
    public async Task Guests_get_403_for_push_pull_and_item_history_and_unauthenticated_get_401(string entity)
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, await h.GuestAsync());
        using (var response = await PersonalFoodHttp.Push(client, h, Guid.NewGuid(), [PersonalFoodHttp.NewRow(h, entity: entity)])) { Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode); }
        foreach (var path in new[] { "/v1/sync/pull?cursor=0&limit=10", $"/v1/sync/history/{entity}/{Guid.NewGuid()}?cursor=0&limit=10" })
        {
            using (var response = await client.GetAsync(path, Ct)) { Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode); }
            var token = client.DefaultRequestHeaders.Authorization; client.DefaultRequestHeaders.Authorization = null;
            using (var response = await client.GetAsync(path, Ct)) { Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode); }
            client.DefaultRequestHeaders.Authorization = token;
        }
        client.DefaultRequestHeaders.Authorization = null;
        using (var response = await PersonalFoodHttp.Push(client, h, Guid.NewGuid(), [PersonalFoodHttp.NewRow(h, entity: entity)])) { Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode); }
    }

    [Fact, Trait("Rule", "B18.well-formed-utf16")]
    public async Task Ill_formed_utf16_never_500s_or_reaches_postgres_logs()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync(); var user = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h); using var client = await PersonalFoodHttp.Client(factory, h, user);
        var dataset = await PersonalFoodHttp.Dataset(client);
        // Each unpaired unit sits next to a unique canary, top level and inside nested JSON
        // values and keys, live and as tombstones, for chatMessage, proposal and weighIn.note.
        var canary = "CANARY-B18-UTF16-" + Guid.NewGuid().ToString("N");
        var chat = ChatProposalCases.Baseline("chatMessage"); var proposal = ChatProposalCases.Baseline("proposal");
        var weighIn = PersonalFoodHttp.Fixture("weighIn");
        var cases = new List<(string Entity, string Raw)>
        {
            ("chatMessage", Raw(chat, "text", $"\"{canary}-text\\ud800\"")),
            ("chatMessage", Raw(chat, "text", $"\"\\udc00{canary}-low\"")),
            ("chatMessage", Raw(chat, "text", $"\"{canary}-reversed\\ude00\\ud83d\"")),
            ("chatMessage", Raw(chat, "language", "\"e\\ud800\"")),
            ("chatMessage", Raw(chat, "budgetJson", $"\"{{\\\"{canary}-outer\\\":\\\"\\ud800\\\"}}\"")),
            ("chatMessage", Raw(chat, "budgetJson", $"\"{{\\\"{canary}-nested\\\":\\\"\\\\ud800\\\"}}\"")),
            ("proposal", Raw(proposal, "draftJson", $"\"{{\\\"a\\\":\\\"{canary}-draft\\\\udc00\\\"}}\"")),
            ("proposal", Raw(proposal, "interpretationJson", $"\"[{{\\\"{canary}-key\\\\ud800\\\":1}}]\"")),
            ("proposal", Raw(proposal, "kind", "\"k\\ud800\"")),
            ("weighIn", Raw(weighIn, "note", $"\"{canary}-note\\ud800\"")),
            ("weighIn", Raw(weighIn, "note", $"\"\\udfff{canary}-note-low\"")),
            ("chatMessage", "{\"" + canary + "-top-key\\ud800\":1," + chat[1..]),
        };
        cases.AddRange(ChatProposalCases.Corpus().Where(c => c.Id.Contains("lone", StringComparison.Ordinal) || c.Id.Contains("reversed", StringComparison.Ordinal)).Select(c => (c.Entity, c.Raw)));
        Assert.True(cases.Count >= 20);
        var rows = cases.SelectMany(c => new[] { PersonalFoodHttp.NewRow(h, c.Raw, entity: c.Entity), PersonalFoodHttp.NewRow(h, c.Raw, h.Clock.GetUtcNow(), c.Entity) }).ToArray();
        // One batch and every row alone: no single row can turn the request into a 500.
        foreach (var batch in rows.Chunk(rows.Length).Concat(rows.Select(r => new[] { r })))
        {
            using var push = await PersonalFoodHttp.Push(client, h, dataset, batch);
            Assert.Equal(HttpStatusCode.OK, push.StatusCode);
            var ack = await push.Content.ReadAsStringAsync(Ct);
            Assert.DoesNotContain(canary, ack, StringComparison.Ordinal);
            using var result = JsonDocument.Parse(ack);
            Assert.All(result.RootElement.GetProperty("results").EnumerateArray(), r => Assert.Equal("invalidPayload", r.GetProperty("reason").GetString()));
        }
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using (var query = owner.CreateCommand("SELECT count(*) FROM userdata.documents WHERE user_id=$1"))
        { query.Parameters.AddWithValue(user.UserId); Assert.Equal(0L, await query.ExecuteScalarAsync(Ct)); }
        Assert.Empty((await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray());
        Assert.DoesNotContain(canary, await database.LogsAsync(), StringComparison.OrdinalIgnoreCase);

        static string Raw(string raw, string field, string escapedJson)
        {
            var payload = JsonNode.Parse(raw)!.AsObject(); payload[field] = "\u0001marker\u0001";
            return payload.ToJsonString().Replace("\"\\u0001marker\\u0001\"", escapedJson, StringComparison.Ordinal);
        }
    }

    [Fact, Trait("Req", "AC-031")]
    public async Task Delete_account_erases_chat_and_proposal_live_history_fences_and_receipts_and_preserves_second_owner()
    {
        await using var h = new IdentityHarness(database); await h.InitializeAsync();
        var user = await PersonalFoodHttp.Register(h); var other = await PersonalFoodHttp.Register(h);
        await using var factory = new IdentityApiTests.IdentityApi(database, h);
        using var client = await PersonalFoodHttp.Client(factory, h, user); using var otherClient = await PersonalFoodHttp.Client(factory, h, other);
        var dataset = await PersonalFoodHttp.Dataset(client);
        var kept = new List<Row>(); var fences = new List<Row>();
        foreach (var entity in ChatProposalCases.Entities)
        {
            var live = PersonalFoodHttp.NewRow(h, entity: entity); var fence = PersonalFoodHttp.NewRow(h, entity: entity);
            using (var push = await PersonalFoodHttp.Push(client, h, dataset, [live, live with { Hlc = PersonalFoodHttp.Hlc(h, 1) }, fence, fence with { Hlc = PersonalFoodHttp.Hlc(h, 1), DeletedAt = h.Clock.GetUtcNow() }]))
            { Assert.All((await PersonalFoodHttp.Json(push)).GetProperty("results").EnumerateArray(), r => Assert.Equal("accepted", r.GetProperty("status").GetString())); }
            using (var push = await PersonalFoodHttp.Push(otherClient, h, dataset, [live])) { Assert.Equal(HttpStatusCode.OK, push.StatusCode); }
            kept.Add(live); fences.Add(fence);
        }
        foreach (var fence in fences) { await AgeAndCleanup(database, h, user.UserId, fence.Entity, fence.Id, expireHistory: false); }
        var before = (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(4, before.Length); Assert.Equal(2, before.Count(r => r.GetProperty("compacted").GetBoolean()));
        foreach (var live in kept) { Assert.NotEmpty((await PersonalFoodHttp.Page(client, dataset, live.Id, live.Entity)).GetProperty("changes").EnumerateArray()); }
        await using var owner = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        // Per entity: live + fence documents, their two displaced versions (compaction keeps
        // history; only expiry removes it), and four immutable-version receipts.
        var inventory = await Inventory(user.UserId);
        Assert.Equal(new long[] { 2, 2, 4, 2, 2, 4 }, inventory);
        using (var erased = await client.DeleteAsync("/v1/me", Ct)) { Assert.Equal(HttpStatusCode.NoContent, erased.StatusCode); }
        using (var revoked = await client.GetAsync("/v1/sync/pull?cursor=0&limit=10", Ct)) { Assert.Equal(HttpStatusCode.Unauthorized, revoked.StatusCode); }
        Assert.Equal(new long[6], await Inventory(user.UserId));
        foreach (var table in new[] { "documents", "row_history", "version_receipts" })
        {
            await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1"); query.Parameters.AddWithValue(user.UserId);
            Assert.Equal(0L, await query.ExecuteScalarAsync(Ct));
        }
        var preserved = (await PersonalFoodHttp.Page(otherClient, dataset)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(kept.Select(r => r.Id).Order(), preserved.Select(r => r.GetProperty("id").GetGuid()).Order());
        foreach (var row in kept) { AssertSame(row, preserved.Single(r => r.GetProperty("id").GetGuid() == row.Id)); }
        Assert.Equal(new long[] { 1, 0, 1, 1, 0, 1 }, await Inventory(other.UserId));

        // documents / row_history / version_receipts, per B18 entity.
        async Task<long[]> Inventory(Guid id)
        {
            var counts = new List<long>();
            foreach (var entity in ChatProposalCases.Entities)
            {
                foreach (var table in new[] { "documents", "row_history", "version_receipts" })
                {
                    await using var query = owner.CreateCommand($"SELECT count(*) FROM userdata.{table} WHERE user_id=$1 AND entity=$2");
                    query.Parameters.AddWithValue(id); query.Parameters.AddWithValue(entity);
                    counts.Add((long)(await query.ExecuteScalarAsync(Ct))!);
                }
            }
            return [.. counts];
        }
    }

    // Owner reads return the exact payload: same members/values, and the opaque strings byte for byte.
    private static void AssertSame(Row row, JsonElement change, bool hlc = true)
    {
        Assert.Equal(row.Entity, change.GetProperty("entity").GetString());
        if (hlc) { Assert.Equal(row.Hlc, change.GetProperty("hlc").GetString()); }
        Assert.False(change.GetProperty("compacted").GetBoolean());
        using var expected = JsonDocument.Parse(row.Raw);
        var payload = change.GetProperty("payload");
        Assert.True(JsonElement.DeepEquals(expected.RootElement, payload), row.Id.ToString());
        foreach (var field in ExactStringFields.Where(f => expected.RootElement.TryGetProperty(f, out var v) && v.ValueKind == JsonValueKind.String))
        { Assert.Equal(expected.RootElement.GetProperty(field).GetString(), payload.GetProperty(field).GetString()); }
    }
}
