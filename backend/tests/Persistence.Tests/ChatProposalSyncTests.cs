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
