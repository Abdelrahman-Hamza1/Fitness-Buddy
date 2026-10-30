using System.Collections.Concurrent;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Net.Http.Json;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Net;
using FitnessBuddy.Host.Observability;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.TestData;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Sentry.AspNetCore;
using Sentry.Extensibility;
using Sentry.Protocol.Envelopes;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-041")]
[Trait("Req", "AC-040")]
[Trait("Rule", "09.4-privacy")]
public sealed class IdentityPrivacyTests(PostgresFixture postgres)
{
    [Fact]
    public async Task Auth_success_and_provider_delivery_failures_never_emit_identity_content_to_any_sink()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var canaries = new List<string> { "CANARY-IDENTITY-EMAIL@example.invalid", "CANARY-PROVIDER-TOKEN", "CANARY-DELIVERY-EMAIL@example.invalid" };
        using var capture = new SinkCapture();
        var (logs, activities, metrics, transport) = (capture.Logs, capture.Activities, capture.Metrics, capture.Transport);
        await using var factory = capture.Configure(new IdentityApiTests.IdentityApi(postgres, h), services =>
        {
            services.AddSingleton<IGoogleIdentityVerifier, FailingGoogle>();
            services.AddSingleton<IEmailSender>(new SelectiveEmail(h.Email, canaries));
        });
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android"); client.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
        using var start = await client.PostAsJsonAsync("/v1/auth/email/start", new { email = canaries[0], purpose = "signIn" }, TestContext.Current.CancellationToken);
        Assert.Equal(200, (int)start.StatusCode);
        var code = h.Email.Code; canaries.Add(code);
        using var verify = await client.PostAsJsonAsync("/v1/auth/email/verify", new { challengeId = h.Email.Challenge, code }, TestContext.Current.CancellationToken);
        Assert.Equal(200, (int)verify.StatusCode);
        var issued = (await verify.Content.ReadFromJsonAsync<IssuedTokens>(TestContext.Current.CancellationToken))!;
        canaries.Add(issued.AccessToken); canaries.Add(issued.RefreshToken);
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", issued.AccessToken);
        using var me = await client.GetAsync("/v1/me", TestContext.Current.CancellationToken);
        Assert.Equal(200, (int)me.StatusCode);
        canaries.Add("CANARY-SYNC-PRIVATE-CONTENT");
        using var discovery = await client.GetAsync("/v1/sync/pull?cursor=0&limit=100", TestContext.Current.CancellationToken);
        var syncPage = await discovery.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>(TestContext.Current.CancellationToken);
        var payload = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object?>>(System.Text.Json.JsonDocument.Parse(
            await File.ReadAllTextAsync(Path.Combine(AppContext.BaseDirectory, "entity-payloads.json"), TestContext.Current.CancellationToken)).RootElement.GetProperty("weighIn"))!;
        payload["note"] = canaries[^1];
        foreach (var invalid in new[] { false, true })
        {
            if (invalid) { payload["note"] = canaries[^1] + "\0"; }
            using var push = await client.PostAsJsonAsync("/v1/sync/push", new
            {
                datasetId = syncPage.GetProperty("datasetId").GetGuid(),
                changes = new[] { new { entity = "weighIn", id = Guid.NewGuid(), schemaVersion = 1,
                    hlc = $"{h.Clock.GetUtcNow().ToUnixTimeMilliseconds():D13}-00000-{h.Device}", deviceId = h.Device,
                    deletedAt = (DateTimeOffset?)null, payload } },
            }, TestContext.Current.CancellationToken);
            Assert.Equal(200, (int)push.StatusCode);
            var result = await push.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>(TestContext.Current.CancellationToken);
            Assert.Equal(invalid ? "invalid" : "accepted", result.GetProperty("results")[0].GetProperty("status").GetString());
        }
        // B17: real success/rejection/read traffic, with a unique canary in every
        // private field class. Only owner pull/history may return this content.
        var foodCanaries = new[] { "CANARY-PERSONAL-NAME", "طعام-سري-خاص", "CANARY-PERSONAL-ALIAS", "CANARY-PERSONAL-BRAND", "96385074", "817.26491", "732.83419", "30.91827" };
        canaries.AddRange(foodCanaries);
        var foodPayload = JsonNode.Parse(PersonalFoodHttp.Fixture())!.AsObject();
        foodPayload["nameEn"] = foodCanaries[0]; foodPayload["nameAr"] = foodCanaries[1];
        foodPayload["aliasesJson"] = JsonSerializer.Serialize(new[] { foodCanaries[2] }); foodPayload["brand"] = foodCanaries[3];
        foodPayload["barcodesJson"] = "[\"96385074\"]"; foodPayload["per100Kcal"] = 817.26491m;
        foodPayload["per100ExtrasJson"] = "{\"sodium\":732.83419}"; foodPayload["entryServingAmount"] = 30.91827m;
        var privateRow = PersonalFoodHttp.NewRow(h, foodPayload.ToJsonString());
        var dataset = syncPage.GetProperty("datasetId").GetGuid();
        foreach (var invalid in new[] { false, true })
        {
            var raw = invalid ? privateRow.Raw.Replace("CANARY-PERSONAL-NAME", "", StringComparison.Ordinal) : privateRow.Raw;
            using var response = await PersonalFoodHttp.Push(client, h, dataset, [privateRow with { Id = invalid ? Guid.NewGuid() : privateRow.Id, Raw = raw }]);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var ack = await PersonalFoodHttp.Json(response);
            Assert.Equal(invalid ? "invalidPayload" : null, ack.GetProperty("results")[0].GetProperty("reason").GetString());
            foreach (var canary in foodCanaries) { Assert.DoesNotContain(canary, ack.GetRawText(), StringComparison.Ordinal); }
        }
        using (var update = await PersonalFoodHttp.Push(client, h, dataset, [privateRow with { Hlc = PersonalFoodHttp.Hlc(h, 1) }]))
        { Assert.Equal(HttpStatusCode.OK, update.StatusCode); }
        var pulled = (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray().Single(c => c.GetProperty("id").GetGuid() == privateRow.Id);
        using (var expected = JsonDocument.Parse(privateRow.Raw)) { Assert.True(JsonElement.DeepEquals(expected.RootElement, pulled.GetProperty("payload"))); }
        Assert.Single((await PersonalFoodHttp.Page(client, dataset, privateRow.Id)).GetProperty("changes").EnumerateArray());
        // Unreadable outer JSON is a fixed 400, not a semantic per-row failure.
        using (var malformedBody = new StringContent(PersonalFoodHttp.Body(h, dataset, [privateRow]).Replace("817.26491", "NaN", StringComparison.Ordinal), Encoding.UTF8, "application/json"))
        using (var malformed = await client.PostAsync("/v1/sync/push", malformedBody, TestContext.Current.CancellationToken))
        {
            Assert.Equal(HttpStatusCode.BadRequest, malformed.StatusCode);
            var problem = await malformed.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
            foreach (var canary in foodCanaries) { Assert.DoesNotContain(canary, problem, StringComparison.Ordinal); }
        }
        using (var guestClient = await PersonalFoodHttp.Client(factory, h, await h.GuestAsync()))
        using (var denied = await PersonalFoodHttp.Push(guestClient, h, dataset, [privateRow]))
        {
            Assert.Equal(HttpStatusCode.Forbidden, denied.StatusCode);
            foreach (var canary in foodCanaries) { Assert.DoesNotContain(canary, await denied.Content.ReadAsStringAsync(TestContext.Current.CancellationToken), StringComparison.Ordinal); }
        }
        // TestServer has no body limit: this request must reach actual Kestrel.
        await using (var kestrelFactory = factory.WithWebHostBuilder(_ => { }))
        {
            kestrelFactory.UseKestrel(0);
            using var limited = kestrelFactory.CreateClient();
            limited.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); limited.DefaultRequestHeaders.Add("X-Platform", "android"); limited.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
            limited.DefaultRequestHeaders.Authorization = client.DefaultRequestHeaders.Authorization;
            foodPayload["nameEn"] = foodCanaries[0] + new string('x', 300 * 1024);
            using var oversized = await PersonalFoodHttp.Push(limited, h, dataset, [privateRow with { Raw = foodPayload.ToJsonString() }]);
            Assert.Equal(HttpStatusCode.RequestEntityTooLarge, oversized.StatusCode);
            var problem = await oversized.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
            foreach (var canary in foodCanaries) { Assert.DoesNotContain(canary, problem, StringComparison.Ordinal); }
            await kestrelFactory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        }
        using var provider = await client.PostAsJsonAsync("/v1/auth/google", new { idToken = canaries[1] }, TestContext.Current.CancellationToken);
        Assert.Equal(500, (int)provider.StatusCode);
        using var delivery = await client.PostAsJsonAsync("/v1/auth/email/start", new { email = canaries[2], purpose = "signIn" }, TestContext.Current.CancellationToken);
        Assert.Equal(500, (int)delivery.StatusCode);
        canaries.AddRange(["CANARY-PATH-PRIVATE", "cafebabe-0000-7000-8000-000000000777", "CANARY-UNMATCHED-PRIVATE", "CANARY-PATH-QUERY"]);
        await using (var failingFactory = factory.WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
            services.AddScoped<FitnessBuddy.Modules.UserData.Application.ISyncStore, FailingHistory>())))
        {
            using var historyClient = failingFactory.CreateClient();
            historyClient.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); historyClient.DefaultRequestHeaders.Add("X-Platform", "android"); historyClient.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
            historyClient.DefaultRequestHeaders.Authorization = client.DefaultRequestHeaders.Authorization;
            using var failed = await historyClient.GetAsync("/v1/sync/history/CANARY-PATH-PRIVATE/cafebabe-0000-7000-8000-000000000777?cursor=0&limit=1&q=CANARY-PATH-QUERY", TestContext.Current.CancellationToken);
            Assert.Equal(500, (int)failed.StatusCode);
            using var failedPush = await PersonalFoodHttp.Push(historyClient, h, dataset, [privateRow]);
            Assert.Equal(HttpStatusCode.InternalServerError, failedPush.StatusCode);
            var failedBody = await failedPush.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
            foreach (var canary in foodCanaries) { Assert.DoesNotContain(canary, failedBody, StringComparison.Ordinal); }
            using var unmatched = await historyClient.GetAsync("/CANARY-UNMATCHED-PRIVATE?q=CANARY-PATH-QUERY", TestContext.Current.CancellationToken); Assert.Equal(404, (int)unmatched.StatusCode);
            await failingFactory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        }
        canaries.Add("CANARY-CATALOG-PRIVATE");
        using (var search = await client.GetAsync("/v1/foods/search?query=CANARY-CATALOG-PRIVATE&limit=10", TestContext.Current.CancellationToken)) { Assert.Equal(200, (int)search.StatusCode); }
        using (var missingFood = await client.GetAsync("/v1/foods/CANARY-CATALOG-PRIVATE", TestContext.Current.CancellationToken)) { Assert.Equal(404, (int)missingFood.StatusCode); }
        using var erased = await client.DeleteAsync("/v1/me", TestContext.Current.CancellationToken);
        Assert.Equal(204, (int)erased.StatusCode);
        using var afterErasure = await client.GetAsync("/v1/me", TestContext.Current.CancellationToken);
        Assert.Equal(401, (int)afterErasure.StatusCode);
        await factory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        capture.Meter.RecordObservableInstruments();
        var auditLines = await SinkCapture.AuditAsync(postgres);
        Assert.Contains("operation=push", metrics);
        Assert.NotEmpty(logs.Lines); Assert.NotEmpty(activities); Assert.NotEmpty(metrics); Assert.NotEmpty(auditLines);
        Assert.Contains(transport.Envelopes, envelope => envelope.Contains("\"exception\"", StringComparison.Ordinal));
        await capture.AssertAbsentAsync(canaries, auditLines, postgres);
    }

    // B18 (D13, PA9): chat text (EN/Arabic/Arabizi) and opaque budget/interpretation/draft JSON reach
    // owner pull/history exactly, and no error response, log, scope, span, metric, Sentry event,
    // audit row or Postgres log, across accepted, invalid, oversize, ill-formed, 400, 403, 413 and 500.
    [Fact, Trait("Rule", "09.4-no-user-content"), Trait("Req", "AC-010")]
    public async Task B18_authorized_pull_returns_content_while_errors_logs_and_telemetry_omit_it()
    {
        var ct = TestContext.Current.CancellationToken;
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var capture = new SinkCapture();
        await using var factory = capture.Configure(new IdentityApiTests.IdentityApi(postgres, h), _ => { });
        using var client = await PersonalFoodHttp.Client(factory, h, await PersonalFoodHttp.Register(h));
        var dataset = await PersonalFoodHttp.Dataset(client);
        string[] canaries = ["CANARY-B18-CHAT-EN-private-reply", "رسالة-خاصة-سرية-كناري", "CANARY-ana-3ayez-akol-ta3miya-b18", "CANARY-B18-BUDGET-KEY",
            "CANARY-B18-INTERPRETATION", "تفسير-سري-كناري", "CANARY-B18-DRAFT-NOTE", "CANARY-B18-KIND", "CANARY-B18-LANG"];
        var text = $"{canaries[0]} {canaries[1]} {canaries[2]}";
        var message = B18Encode(ChatProposalCases.Baseline("chatMessage"), new()
        {
            ["text"] = text,
            ["language"] = canaries[8],
            ["budgetJson"] = $"{{\"{canaries[3]}\":[1,2],\"cards\":[]}}",
        });
        var card = B18Encode(ChatProposalCases.Baseline("proposal"), new()
        {
            ["kind"] = canaries[7],
            ["interpretationJson"] = $"[{{\"text\":\"{canaries[4]}\",\"raw\":\"{canaries[5]}\"}}]",
            ["draftJson"] = $"{{\"note\":\"{canaries[6]}\"}}",
        });
        var messageRow = PersonalFoodHttp.NewRow(h, message, entity: "chatMessage");
        var cardRow = PersonalFoodHttp.NewRow(h, card, entity: "proposal");
        using (var accepted = await PersonalFoodHttp.Push(client, h, dataset, [messageRow, cardRow]))
        {
            var ack = await accepted.Content.ReadAsStringAsync(ct);
            Assert.Equal(["accepted", "accepted"], JsonDocument.Parse(ack).RootElement.GetProperty("results").EnumerateArray().Select(r => r.GetProperty("status").GetString()));
            B18AssertNoCanary(canaries, ack);
        }
        // Invalid vocabulary, one unit over each bound, and unpaired surrogates, each carrying the canaries.
        var invalid = new[]
        {
            messageRow with { Id = Guid.NewGuid(), Raw = B18Encode(message, new() { ["role"] = "system" }) },
            cardRow with { Id = Guid.NewGuid(), Raw = B18Encode(card, new() { ["status"] = "active" }) },
            messageRow with { Id = Guid.NewGuid(), Raw = B18Encode(message, new() { ["text"] = text.PadRight(8193, 'x') }) },
            cardRow with { Id = Guid.NewGuid(), Raw = B18Encode(card, new() { ["draftJson"] = $"{{\"note\":\"{canaries[6]}\"}}".PadRight(32769) }) },
            messageRow with { Id = Guid.NewGuid(), Raw = B18Encode(message, new() { ["text"] = "\u0001marker\u0001" }).Replace("\\u0001marker\\u0001", text + "\\ud800", StringComparison.Ordinal) },
            cardRow with { Id = Guid.NewGuid(), Raw = B18Encode(card, new() { ["draftJson"] = "\u0001marker\u0001" }).Replace("\\u0001marker\\u0001", $"{{\\\"{canaries[6]}\\\":\\\"\\\\udc00\\\"}}", StringComparison.Ordinal) },
        };
        using (var rejected = await PersonalFoodHttp.Push(client, h, dataset, invalid))
        {
            Assert.Equal(HttpStatusCode.OK, rejected.StatusCode);
            var ack = await rejected.Content.ReadAsStringAsync(ct);
            Assert.All(JsonDocument.Parse(ack).RootElement.GetProperty("results").EnumerateArray(), r => Assert.Equal("invalidPayload", r.GetProperty("reason").GetString()));
            B18AssertNoCanary(canaries, ack);
        }
        // Owner pull and item history intentionally return the stored content exactly.
        using (var update = await PersonalFoodHttp.Push(client, h, dataset, [messageRow with { Hlc = PersonalFoodHttp.Hlc(h, 1) }, cardRow with { Hlc = PersonalFoodHttp.Hlc(h, 1) }]))
        { Assert.Equal(HttpStatusCode.OK, update.StatusCode); }
        var pulled = (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(2, pulled.Length);
        foreach (var row in new[] { messageRow, cardRow })
        {
            using var expected = JsonDocument.Parse(row.Raw);
            Assert.True(JsonElement.DeepEquals(expected.RootElement, pulled.Single(c => c.GetProperty("id").GetGuid() == row.Id).GetProperty("payload")));
            Assert.True(JsonElement.DeepEquals(expected.RootElement, Assert.Single((await PersonalFoodHttp.Page(client, dataset, row.Id, row.Entity)).GetProperty("changes").EnumerateArray()).GetProperty("payload")));
        }
        Assert.Equal(text, pulled.Single(c => c.GetProperty("id").GetGuid() == messageRow.Id).GetProperty("payload").GetProperty("text").GetString());
        // Unreadable outer JSON is a fixed 400; guests get 403.
        using (var body = new StringContent(PersonalFoodHttp.Body(h, dataset, [messageRow, cardRow]).Replace("\"createdAtMs\":0", "\"createdAtMs\":NaN", StringComparison.Ordinal), Encoding.UTF8, "application/json"))
        using (var malformed = await client.PostAsync("/v1/sync/push", body, ct))
        {
            Assert.Equal(HttpStatusCode.BadRequest, malformed.StatusCode);
            B18AssertNoCanary(canaries, await malformed.Content.ReadAsStringAsync(ct));
        }
        using (var guest = await PersonalFoodHttp.Client(factory, h, await h.GuestAsync()))
        using (var denied = await PersonalFoodHttp.Push(guest, h, dataset, [messageRow, cardRow]))
        {
            Assert.Equal(HttpStatusCode.Forbidden, denied.StatusCode);
            B18AssertNoCanary(canaries, await denied.Content.ReadAsStringAsync(ct));
        }
        // TestServer has no body limit: the 413 must come from real Kestrel.
        await using (var kestrelFactory = factory.WithWebHostBuilder(_ => { }))
        {
            kestrelFactory.UseKestrel(0);
            using var limited = kestrelFactory.CreateClient();
            limited.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); limited.DefaultRequestHeaders.Add("X-Platform", "android"); limited.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
            limited.DefaultRequestHeaders.Authorization = client.DefaultRequestHeaders.Authorization;
            using var oversized = await PersonalFoodHttp.Push(limited, h, dataset, [messageRow with { Raw = B18Encode(message, new() { ["text"] = text + new string('x', 300 * 1024) }) }]);
            Assert.Equal(HttpStatusCode.RequestEntityTooLarge, oversized.StatusCode);
            B18AssertNoCanary(canaries, await oversized.Content.ReadAsStringAsync(ct));
            await kestrelFactory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        }
        // An injected storage failure whose exception message carries the pushed payloads (chat text,
        // budget, interpretation, draft) on push and the chat text on reads: 500 with no content, and
        // the exception reaches logs and Sentry with its message scrubbed.
        await using (var failingFactory = factory.WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
            services.AddScoped<FitnessBuddy.Modules.UserData.Application.ISyncStore>(_ => new FailingWithContent(text)))))
        {
            using var failing = failingFactory.CreateClient();
            failing.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); failing.DefaultRequestHeaders.Add("X-Platform", "android"); failing.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
            failing.DefaultRequestHeaders.Authorization = client.DefaultRequestHeaders.Authorization;
            using var failedPush = await PersonalFoodHttp.Push(failing, h, dataset, [messageRow, cardRow]);
            Assert.Equal(HttpStatusCode.InternalServerError, failedPush.StatusCode);
            B18AssertNoCanary(canaries, await failedPush.Content.ReadAsStringAsync(ct));
            using var failedHistory = await failing.GetAsync($"/v1/sync/history/proposal/{cardRow.Id}?cursor=0&limit=10&datasetId={dataset}", ct);
            Assert.Equal(HttpStatusCode.InternalServerError, failedHistory.StatusCode);
            B18AssertNoCanary(canaries, await failedHistory.Content.ReadAsStringAsync(ct));
            await failingFactory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        }
        using (var erased = await client.DeleteAsync("/v1/me", ct)) { Assert.Equal(HttpStatusCode.NoContent, erased.StatusCode); }
        await factory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        capture.Meter.RecordObservableInstruments();
        var auditLines = await SinkCapture.AuditAsync(postgres);
        Assert.Contains("operation=push", capture.Metrics);
        Assert.NotEmpty(capture.Logs.Lines); Assert.NotEmpty(capture.Activities);
        Assert.Contains(capture.Transport.Envelopes, envelope => envelope.Contains("\"exception\"", StringComparison.Ordinal));
        await capture.AssertAbsentAsync(canaries, auditLines, postgres);
    }

    // B19 (S1): a phase name, an Arabic weigh-in note and distinctive height/weight/kcal/macro numbers reach
    // owner pull/history exactly, and no error response, log, scope, span, metric, Sentry event, audit row or
    // Postgres log, across the entity-dependent legs: accepted, wire-invalid, schema-invalid and guest 403.
    // (400/413/500 don't depend on the entity; the B17/B18 facts above cover them.)
    [Fact, Trait("Rule", "09.4-no-user-content"), Trait("Req", "AC-010"), Trait("Req", "TG-040"), Trait("Req", "WB-003")]
    public async Task B19_body_and_targets_values_never_reach_errors_logs_or_telemetry()
    {
        var ct = TestContext.Current.CancellationToken;
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var capture = new SinkCapture();
        await using var factory = capture.Configure(new IdentityApiTests.IdentityApi(postgres, h), _ => { });
        using var client = await PersonalFoodHttp.Client(factory, h, await PersonalFoodHttp.Register(h));
        var dataset = await PersonalFoodHttp.Dataset(client);
        string[] canaries = ["CANARY-B19-PHASE-NAME", "ملاحظة-وزن-سرية-كناري", "173.4567891", "81.2345671", "179.0987651", "2345.678901", "71.8765431", "141.2345671"];
        var profile = B18Encode(BodyTargetsCases.Raw("profile-base"), new() { ["heightCm"] = 173.4567891m });
        var phase = B18Encode(BodyTargetsCases.Raw("goalPhase-base-targetDate"), new() { ["name"] = canaries[0], ["targetKg"] = 71.8765431m });
        var settings = B18Encode(BodyTargetsCases.Raw("targetSettings-base"), new() { ["baseKcal"] = 2345.678901m, ["proteinValue"] = 141.2345671m });
        var weighIn = B18Encode(BodyTargetsCases.Raw("weighIn2-base"), new() { ["note"] = canaries[1], ["kg"] = 81.2345671m, ["inputValue"] = 179.0987651m });
        PersonalFoodHttp.Row[] rows =
        [
            PersonalFoodHttp.NewRow(h, profile, entity: "profile", id: SyncTestIds.ProfileRowId),
            PersonalFoodHttp.NewRow(h, phase, entity: "goalPhase", id: Guid.CreateVersion7()),
            PersonalFoodHttp.NewRow(h, settings, entity: "targetSettings", id: Guid.CreateVersion7()),
            PersonalFoodHttp.NewRow(h, weighIn, entity: "weighIn", id: Guid.NewGuid(), schemaVersion: 2),
        ];
        foreach (var canary in canaries) { Assert.Contains(canary, string.Concat(rows.Select(r => r.Raw)), StringComparison.Ordinal); }
        using (var accepted = await PersonalFoodHttp.Push(client, h, dataset, rows))
        {
            var ack = await accepted.Content.ReadAsStringAsync(ct);
            Assert.Equal(["accepted", "accepted", "accepted", "accepted"], JsonDocument.Parse(ack).RootElement.GetProperty("results").EnumerateArray().Select(r => r.GetProperty("status").GetString()));
            B18AssertNoCanary(canaries, ack);
        }
        // Wire-invalid (Acknowledgement, Expression fields, Row IDs) and schema-invalid (extra member, unknown inputUnit), each carrying the canaries.
        var invalid = new[]
        {
            rows[2] with { Id = Guid.CreateVersion7(), Raw = B18Encode(settings, new() { ["acknowledged"] = true }) },
            rows[1] with { Id = Guid.CreateVersion7(), Raw = B18Encode(phase, new() { ["kgPerWeek"] = 0.5m }) },
            rows[0] with { Hlc = PersonalFoodHttp.Hlc(h, 5), Raw = B18Encode(profile, new() { ["unexpected"] = canaries[0] }) },
            rows[3] with { Id = Guid.NewGuid(), Raw = B18Encode(weighIn, new() { ["inputUnit"] = "st" }) },
            // Validator-invalid profile (a non-natural row ID) carrying the height canary.
            rows[0] with { Id = Guid.CreateVersion7(), Hlc = PersonalFoodHttp.Hlc(h, 6) },
        };
        using (var rejected = await PersonalFoodHttp.Push(client, h, dataset, invalid))
        {
            Assert.Equal(HttpStatusCode.OK, rejected.StatusCode);
            var ack = await rejected.Content.ReadAsStringAsync(ct);
            Assert.Equal(["invalidPayload", "invalidPayload", "invalidPayload", "invalidPayload", "invalidPayload"], JsonDocument.Parse(ack).RootElement.GetProperty("results").EnumerateArray().Select(r => r.GetProperty("reason").GetString()));
            B18AssertNoCanary(canaries, ack);
        }
        // Owner pull and item history intentionally return the stored content exactly.
        using (var update = await PersonalFoodHttp.Push(client, h, dataset, [.. rows.Select(r => r with { Hlc = PersonalFoodHttp.Hlc(h, 1) })]))
        { Assert.Equal(HttpStatusCode.OK, update.StatusCode); }
        var pulled = (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(rows.Length, pulled.Length);
        foreach (var row in rows)
        {
            using var expected = JsonDocument.Parse(row.Raw);
            Assert.True(JsonElement.DeepEquals(expected.RootElement, pulled.Single(c => c.GetProperty("id").GetGuid() == row.Id).GetProperty("payload")));
            Assert.True(JsonElement.DeepEquals(expected.RootElement, Assert.Single((await PersonalFoodHttp.Page(client, dataset, row.Id, row.Entity)).GetProperty("changes").EnumerateArray()).GetProperty("payload")));
        }
        Assert.Equal(canaries[1], pulled.Single(c => c.GetProperty("id").GetGuid() == rows[3].Id).GetProperty("payload").GetProperty("note").GetString());
        using (var guest = await PersonalFoodHttp.Client(factory, h, await h.GuestAsync()))
        using (var denied = await PersonalFoodHttp.Push(guest, h, dataset, rows))
        {
            Assert.Equal(HttpStatusCode.Forbidden, denied.StatusCode);
            B18AssertNoCanary(canaries, await denied.Content.ReadAsStringAsync(ct));
        }
        using (var erased = await client.DeleteAsync("/v1/me", ct)) { Assert.Equal(HttpStatusCode.NoContent, erased.StatusCode); }
        await factory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        capture.Meter.RecordObservableInstruments();
        Assert.Contains("operation=push", capture.Metrics);
        Assert.NotEmpty(capture.Logs.Lines); Assert.NotEmpty(capture.Activities);
        await capture.AssertAbsentAsync(canaries, await SinkCapture.AuditAsync(postgres), postgres);
    }

    // B20: custom type names (Latin and Arabic) and distinctive measurement values reach owner pull/history
    // exactly, and no error response, log, scope, span, metric, Sentry event, audit row or Postgres log,
    // across the entity-dependent legs: accepted, M1-invalid, M2-invalid, M3-invalid, schema-invalid and guest 403.
    [Fact, Trait("Rule", "09.4-no-user-content"), Trait("Req", "AC-010"), Trait("Req", "WB-040"), Trait("Req", "WB-042")]
    public async Task B20_measurement_names_and_values_never_reach_errors_logs_or_telemetry()
    {
        var ct = TestContext.Current.CancellationToken;
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var capture = new SinkCapture();
        await using var factory = capture.Configure(new IdentityApiTests.IdentityApi(postgres, h), _ => { });
        using var client = await PersonalFoodHttp.Client(factory, h, await PersonalFoodHttp.Register(h));
        var dataset = await PersonalFoodHttp.Dataset(client);
        string[] canaries = ["CANARY-B20-TYPE-NAME", "ذراع-يسار-سري-كناري", "87.6543219", "34.5098761", "18.7654321", "150.1234567"];
        var typeId = Guid.CreateVersion7();
        var type = B18Encode(MeasurementCases.Raw("measurementType-base"), new() { ["name"] = canaries[0] });
        var arabicType = B18Encode(MeasurementCases.Raw("measurementType-base"), new() { ["name"] = canaries[1] });
        var waist = B18Encode(MeasurementCases.Raw("measurement-base-waist-in"), new() { ["value"] = 87.6543219m, ["inputValue"] = 34.5098761m });
        var bodyFat = B18Encode(MeasurementCases.Raw("measurement-base-bodyFat"), new() { ["value"] = 18.7654321m, ["inputValue"] = 18.7654321m });
        var custom = B18Encode(MeasurementCases.Raw("measurement-base-custom-cm"), new() { ["customTypeId"] = typeId.ToString(), ["value"] = 87.6543219m, ["inputValue"] = 87.6543219m });
        PersonalFoodHttp.Row[] rows =
        [
            PersonalFoodHttp.NewRow(h, type, entity: "measurementType", id: typeId),
            PersonalFoodHttp.NewRow(h, arabicType, entity: "measurementType", id: Guid.CreateVersion7()),
            PersonalFoodHttp.NewRow(h, waist, entity: "measurement", id: Guid.CreateVersion7()),
            PersonalFoodHttp.NewRow(h, bodyFat, entity: "measurement", id: Guid.CreateVersion7()),
            PersonalFoodHttp.NewRow(h, custom, entity: "measurement", id: Guid.CreateVersion7()),
        ];
        using (var accepted = await PersonalFoodHttp.Push(client, h, dataset, rows))
        {
            var ack = await accepted.Content.ReadAsStringAsync(ct);
            Assert.All(JsonDocument.Parse(ack).RootElement.GetProperty("results").EnumerateArray(), r => Assert.Equal("accepted", r.GetProperty("status").GetString()));
            B18AssertNoCanary(canaries, ack);
        }
        // M1 (custom without its type), M2 (body fat in cm), M3 (body fat over 100) and schema-invalid
        // (extra member, unknown inputUnit), each carrying canaries.
        var invalid = new[]
        {
            rows[4] with { Id = Guid.CreateVersion7(), Raw = B18Encode(custom, new() { ["customTypeId"] = null }) },
            rows[3] with { Id = Guid.CreateVersion7(), Raw = B18Encode(bodyFat, new() { ["inputUnit"] = "cm" }) },
            rows[3] with { Id = Guid.CreateVersion7(), Raw = B18Encode(bodyFat, new() { ["value"] = 150.1234567m }) },
            rows[0] with { Id = Guid.CreateVersion7(), Raw = B18Encode(type, new() { ["unexpected"] = canaries[1] }) },
            rows[2] with { Id = Guid.CreateVersion7(), Raw = B18Encode(waist, new() { ["inputUnit"] = "inch" }) },
        };
        var sent = string.Concat(rows.Concat(invalid).Select(r => r.Raw));
        foreach (var canary in canaries) { Assert.Contains(canary, sent, StringComparison.Ordinal); }
        using (var rejected = await PersonalFoodHttp.Push(client, h, dataset, invalid))
        {
            Assert.Equal(HttpStatusCode.OK, rejected.StatusCode);
            var ack = await rejected.Content.ReadAsStringAsync(ct);
            Assert.All(JsonDocument.Parse(ack).RootElement.GetProperty("results").EnumerateArray(), r => Assert.Equal("invalidPayload", r.GetProperty("reason").GetString()));
            Assert.Equal(invalid.Length, JsonDocument.Parse(ack).RootElement.GetProperty("results").GetArrayLength());
            B18AssertNoCanary(canaries, ack);
        }
        // Owner pull and item history intentionally return the stored content exactly.
        using (var update = await PersonalFoodHttp.Push(client, h, dataset, [.. rows.Select(r => r with { Hlc = PersonalFoodHttp.Hlc(h, 1) })]))
        { Assert.Equal(HttpStatusCode.OK, update.StatusCode); }
        var pulled = (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(rows.Length, pulled.Length);
        foreach (var row in rows)
        {
            using var expected = JsonDocument.Parse(row.Raw);
            Assert.True(JsonElement.DeepEquals(expected.RootElement, pulled.Single(c => c.GetProperty("id").GetGuid() == row.Id).GetProperty("payload")));
            Assert.True(JsonElement.DeepEquals(expected.RootElement, Assert.Single((await PersonalFoodHttp.Page(client, dataset, row.Id, row.Entity)).GetProperty("changes").EnumerateArray()).GetProperty("payload")));
        }
        Assert.Equal(canaries[1], pulled.Single(c => c.GetProperty("id").GetGuid() == rows[1].Id).GetProperty("payload").GetProperty("name").GetString());
        using (var guest = await PersonalFoodHttp.Client(factory, h, await h.GuestAsync()))
        using (var denied = await PersonalFoodHttp.Push(guest, h, dataset, rows))
        {
            Assert.Equal(HttpStatusCode.Forbidden, denied.StatusCode);
            B18AssertNoCanary(canaries, await denied.Content.ReadAsStringAsync(ct));
        }
        using (var erased = await client.DeleteAsync("/v1/me", ct)) { Assert.Equal(HttpStatusCode.NoContent, erased.StatusCode); }
        await factory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        capture.Meter.RecordObservableInstruments();
        Assert.Contains("operation=push", capture.Metrics);
        Assert.NotEmpty(capture.Logs.Lines); Assert.NotEmpty(capture.Activities);
        await capture.AssertAbsentAsync(canaries, await SinkCapture.AuditAsync(postgres), postgres);
    }

    // B21: exercise, alias, session and template names (Latin and Arabic) and a distinctive set weight
    // reach owner pull/history exactly, and no error response, log, scope, span, metric, Sentry event,
    // audit row or Postgres log, across the legs: accepted, W1-, W3-, W4- and schema-invalid, and guest 403.
    [Fact, Trait("Rule", "09.4-no-user-content"), Trait("Req", "AC-010"), Trait("Req", "WO-003"), Trait("Req", "WO-010"), Trait("Req", "WO-020")]
    public async Task B21_workout_names_and_values_never_reach_errors_logs_or_telemetry()
    {
        var ct = TestContext.Current.CancellationToken;
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var capture = new SinkCapture();
        await using var factory = capture.Configure(new IdentityApiTests.IdentityApi(postgres, h), _ => { });
        using var client = await PersonalFoodHttp.Client(factory, h, await PersonalFoodHttp.Register(h));
        var dataset = await PersonalFoodHttp.Dataset(client);
        string[] canaries = ["CANARY-B21-EXERCISE", "CANARY-B21-ALIAS", "CANARY-B21-SESSION", "CANARY-B21-TEMPLATE", "تمرين-سري-كناري", "87.6543219"];
        var exercise = B18Encode(WorkoutCases.Raw("customExercise-base"), new() { ["name"] = canaries[0], ["aliasesJson"] = $"[\"{canaries[1]}\"]" });
        var arabicExercise = B18Encode(WorkoutCases.Raw("customExercise-base"), new() { ["name"] = canaries[4] });
        var session = B18Encode(WorkoutCases.Raw("workoutSession-base-full"), new() { ["name"] = canaries[2] });
        var template = B18Encode(WorkoutCases.Raw("workoutTemplate-base"), new() { ["name"] = canaries[3] });
        var set = B18Encode(WorkoutCases.Raw("workoutSet-base-weight-kg"), new() { ["kg"] = 87.6543219m, ["inputValue"] = 87.6543219m });
        var sessionExercise = WorkoutCases.Raw("sessionExercise-base-catalog");
        PersonalFoodHttp.Row[] rows =
        [
            PersonalFoodHttp.NewRow(h, exercise, entity: "customExercise", id: Guid.CreateVersion7()),
            PersonalFoodHttp.NewRow(h, arabicExercise, entity: "customExercise", id: Guid.CreateVersion7()),
            PersonalFoodHttp.NewRow(h, session, entity: "workoutSession", id: Guid.CreateVersion7()),
            PersonalFoodHttp.NewRow(h, template, entity: "workoutTemplate", id: Guid.CreateVersion7()),
            PersonalFoodHttp.NewRow(h, set, entity: "workoutSet", id: Guid.CreateVersion7()),
        ];
        using (var accepted = await PersonalFoodHttp.Push(client, h, dataset, rows))
        {
            var ack = await accepted.Content.ReadAsStringAsync(ct);
            Assert.All(JsonDocument.Parse(ack).RootElement.GetProperty("results").EnumerateArray(), r => Assert.Equal("accepted", r.GetProperty("status").GetString()));
            B18AssertNoCanary(canaries, ack);
        }
        // W1 (a legacy muscle code), W3 (a weight without its typed value), W4 (an exercise ID that is
        // no catalog ID) and schema-invalid (an extra member), each carrying canaries.
        var invalid = new[]
        {
            rows[0] with { Id = Guid.CreateVersion7(), Raw = B18Encode(exercise, new() { ["secondaryMusclesJson"] = "[\"back\"]" }) },
            rows[4] with { Id = Guid.CreateVersion7(), Raw = B18Encode(set, new() { ["inputValue"] = null }) },
            PersonalFoodHttp.NewRow(h, B18Encode(sessionExercise, new() { ["exerciseId"] = "ex:" + canaries[0] }), entity: "sessionExercise", id: Guid.CreateVersion7()),
            rows[3] with { Id = Guid.CreateVersion7(), Raw = B18Encode(template, new() { ["unexpected"] = canaries[4] }) },
        };
        var sent = string.Concat(rows.Concat(invalid).Select(r => r.Raw));
        foreach (var canary in canaries) { Assert.Contains(canary, sent, StringComparison.Ordinal); }
        using (var rejected = await PersonalFoodHttp.Push(client, h, dataset, invalid))
        {
            Assert.Equal(HttpStatusCode.OK, rejected.StatusCode);
            var ack = await rejected.Content.ReadAsStringAsync(ct);
            Assert.All(JsonDocument.Parse(ack).RootElement.GetProperty("results").EnumerateArray(), r => Assert.Equal("invalidPayload", r.GetProperty("reason").GetString()));
            Assert.Equal(invalid.Length, JsonDocument.Parse(ack).RootElement.GetProperty("results").GetArrayLength());
            B18AssertNoCanary(canaries, ack);
        }
        // Owner pull and item history intentionally return the stored content exactly.
        using (var update = await PersonalFoodHttp.Push(client, h, dataset, [.. rows.Select(r => r with { Hlc = PersonalFoodHttp.Hlc(h, 1) })]))
        { Assert.Equal(HttpStatusCode.OK, update.StatusCode); }
        var pulled = (await PersonalFoodHttp.Page(client, dataset)).GetProperty("changes").EnumerateArray().ToArray();
        Assert.Equal(rows.Length, pulled.Length);
        foreach (var row in rows)
        {
            using var expected = JsonDocument.Parse(row.Raw);
            Assert.True(JsonElement.DeepEquals(expected.RootElement, pulled.Single(c => c.GetProperty("id").GetGuid() == row.Id).GetProperty("payload")));
            Assert.True(JsonElement.DeepEquals(expected.RootElement, Assert.Single((await PersonalFoodHttp.Page(client, dataset, row.Id, row.Entity)).GetProperty("changes").EnumerateArray()).GetProperty("payload")));
        }
        Assert.Equal(canaries[4], pulled.Single(c => c.GetProperty("id").GetGuid() == rows[1].Id).GetProperty("payload").GetProperty("name").GetString());
        using (var guest = await PersonalFoodHttp.Client(factory, h, await h.GuestAsync()))
        using (var denied = await PersonalFoodHttp.Push(guest, h, dataset, rows))
        {
            Assert.Equal(HttpStatusCode.Forbidden, denied.StatusCode);
            B18AssertNoCanary(canaries, await denied.Content.ReadAsStringAsync(ct));
        }
        using (var erased = await client.DeleteAsync("/v1/me", ct)) { Assert.Equal(HttpStatusCode.NoContent, erased.StatusCode); }
        await factory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        capture.Meter.RecordObservableInstruments();
        Assert.Contains("operation=push", capture.Metrics);
        Assert.NotEmpty(capture.Logs.Lines); Assert.NotEmpty(capture.Activities);
        await capture.AssertAbsentAsync(canaries, await SinkCapture.AuditAsync(postgres), postgres);
    }

    // B09a WP6: EN/AR/Arabizi canaries in the message, entry/saved-meal/batch/personal-food names, aliases, memory values,
    // active-card lines, model mentions/subjects/names and a stated figure never reach logs, scopes, spans, metrics, Sentry,
    // audit rows or Postgres logs, across 200 (incl. the coded repair), replay, 400, 409, an injected 500, 503 and 429.
    // The closed invalid-output code (PA13) does appear, so the repair stays diagnosable without content.
    [Fact, Trait("Rule", "09.4-no-user-content"), Trait("Req", "AC-042")]
    public async Task B09_interpret_context_and_intents_leave_no_content_in_logs_and_telemetry()
    {
        var ct = TestContext.Current.CancellationToken;
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var capture = new SinkCapture();
        string[] canaries = ["CANARY-B09-TEXT-EN", "رسالة-بدي-سرية-كناري", "CANARY-b09-akalt-riz-arabizi", "CANARY-B09-ENTRY-NAME", "CANARY-B09-SAVED-MEAL",
            "CANARY-B09-BATCH-NAME", "CANARY-B09-PERSONAL-NAME", "CANARY-B09-ALIAS", "CANARY-B09-MEMORY-VALUE", "CANARY-B09-CARD-LINE", "CANARY-B09-MENTION",
            "CANARY-B09-SUBJECT", "CANARY-B09-CREATE-NAME", "مقلوبة-كناري-سرية", "8231.5"];
        var text = $"{canaries[0]} {canaries[1]} {canaries[2]} {canaries[13]} save my bar as 8231.5 kcal per 100g";
        static ParsedIntent Intent(ParsedKind kind) => new(kind, null, null, null, null, [], null, null, null, null, null, null, null, null, null, null);
        var valid = new ParsedMessage(MessageLanguage.Mixed, MessageScript.Mixed,
        [
            Intent(ParsedKind.DiaryEdit) with { Reference = new([0], canaries[10], ParsedScope.One, "yesterday", null), Portion = new(150, FoodUnit.G, null, null, false) },
            Intent(ParsedKind.MemoryChange) with { Memory = new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Alias, canaries[11], null, canaries[8], null, null) },
            Intent(ParsedKind.SavedMealCreate) with { Create = new(canaries[12], [], true) },
            Intent(ParsedKind.PersonalFoodCreate) with { Create = new(canaries[12], [canaries[7]], false), Stated = new(ParsedNutrientBasis.Per100g, null, null, 8231.5m, null, null, null, null) },
            Intent(ParsedKind.BatchClose) with { ListRef = 0 },
            Intent(ParsedKind.FoodLog) with { Items = [new(canaries[13], canaries[10], canaries[13], 1, FoodUnit.Plate, true, null, null, null, [], null)] },
        ]);
        var parses = 0;
        // The first send is semantically invalid (a ref outside recentEntries): one coded repair, then the valid output.
        using var wire = new BuddyApiTests.BuddyWire
        {
            Parse = _ => Interlocked.Increment(ref parses) == 1
                ? valid with { Intents = [Intent(ParsedKind.DiaryDelete) with { Reference = new([7], canaries[10], ParsedScope.One, null, null) }] }
                : valid,
        };
        await using var factory = capture.Configure(new BuddyApiTests.BuddyApi(postgres, h, wire, dailyLimit: 4), _ => { });
        using var client = factory.CreateClient(); BuddyApiTests.Headers(client, h); await BuddyApiTests.SignIn(client, h);
        JsonNode Body(Guid id, string message, int entries = 1)
        {
            var body = JsonSerializer.SerializeToNode(BuddyApiTests.Request(id, h, message))!;
            body["activeProposal"] = "019a0000-0000-7000-8000-0000000000a1";
            var context = body["context"]!;
            context["recentEntries"] = new JsonArray([.. Enumerable.Range(0, entries).Select(n => new JsonObject
            {
                ["id"] = $"019a0b0c-0000-4000-8000-{n:D12}", ["date"] = "2026-10-20", ["slot"] = "Lunch", ["name"] = canaries[3], ["grams"] = 200,
            })]);
            context["savedMeals"] = new JsonArray(new JsonObject { ["id"] = "019a0b0c-0000-4000-8000-000000000101", ["name"] = canaries[4] });
            context["openBatches"] = new JsonArray(new JsonObject { ["id"] = "019a0b0c-0000-4000-8000-000000000201", ["name"] = canaries[5] });
            context["personalFoods"] = new JsonArray(new JsonObject
            {
                ["id"] = "019a0b0c-0000-4000-8000-000000000301",
                ["names"] = new JsonArray(canaries[6]),
                ["aliases"] = new JsonArray(canaries[7]),
                ["state"] = "cooked",
                ["nutrients"] = new JsonObject { ["kcal"] = 100, ["proteinG"] = 1, ["carbsG"] = 2, ["fatG"] = 3, ["fiberG"] = 0 },
                ["servings"] = new JsonArray(),
            });
            context["memory"] = new JsonArray(new JsonObject { ["kind"] = "alias", ["key"] = "shake", ["value"] = canaries[8] });
            context["activeCard"] = new JsonObject
            {
                ["slot"] = "Breakfast",
                ["time"] = "08:00",
                ["lines"] = new JsonArray(new JsonObject { ["name"] = canaries[9], ["amount"] = 2, ["unitCode"] = "piece", ["state"] = null }),
            };
            return body;
        }
        async Task<HttpResponseMessage> SendAsync(HttpClient http, Guid id, JsonNode body)
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, "/v1/buddy/interpret") { Content = new StringContent(body.ToJsonString(B18Relaxed), Encoding.UTF8, "application/json") };
            request.Headers.Add("Idempotency-Key", id.ToString()); return await http.SendAsync(request, ct);
        }
        var id = Guid.CreateVersion7();
        using (var accepted = await SendAsync(client, id, Body(id, text)))
        {
            // 200 returns the user's own words in the intents by design; only diagnostics must omit them.
            Assert.Equal(HttpStatusCode.OK, accepted.StatusCode); Assert.Equal(2, wire.Calls);
            Assert.Contains(canaries[12], await accepted.Content.ReadAsStringAsync(ct), StringComparison.Ordinal);
        }
        using (var replay = await SendAsync(client, id, Body(id, text))) { Assert.Equal(HttpStatusCode.OK, replay.StatusCode); Assert.Equal(2, wire.Calls); }
        using (var conflict = await SendAsync(client, id, Body(id, text + " " + canaries[2])))
        { Assert.Equal(HttpStatusCode.Conflict, conflict.StatusCode); B18AssertNoCanary(canaries, await conflict.Content.ReadAsStringAsync(ct)); }
        var tooMany = Guid.CreateVersion7();
        using (var invalid = await SendAsync(client, tooMany, Body(tooMany, text, entries: 31)))
        { Assert.Equal(HttpStatusCode.BadRequest, invalid.StatusCode); B18AssertNoCanary(canaries, await invalid.Content.ReadAsStringAsync(ct)); }
        Assert.Equal(2, wire.Calls);
        // An injected resolver failure whose exception message carries the message: 500, no content, scrubbed diagnostics.
        await using (var failingFactory = factory.WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
            services.AddSingleton<FitnessBuddy.Modules.Catalog.Contracts.IFoodResolver>(new ThrowingResolver(text)))))
        {
            using var failing = failingFactory.CreateClient(); BuddyApiTests.Headers(failing, h);
            failing.DefaultRequestHeaders.Authorization = client.DefaultRequestHeaders.Authorization;
            var crash = Guid.CreateVersion7();
            using var failed = await SendAsync(failing, crash, Body(crash, text));
            Assert.Equal(HttpStatusCode.InternalServerError, failed.StatusCode);
            B18AssertNoCanary(canaries, await failed.Content.ReadAsStringAsync(ct));
            await failingFactory.Services.GetRequiredService<Sentry.IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        }
        wire.Status = HttpStatusCode.ServiceUnavailable;
        var unavailable = Guid.CreateVersion7();
        using (var pending = await SendAsync(client, unavailable, Body(unavailable, text)))
        { Assert.Equal(HttpStatusCode.ServiceUnavailable, pending.StatusCode); B18AssertNoCanary(canaries, await pending.Content.ReadAsStringAsync(ct)); }
        // The daily ceiling (4 sends: two for the repaired message, the crash, the 503) answers 429 without a send.
        var sends = wire.Calls; var limited = Guid.CreateVersion7();
        using (var denied = await SendAsync(client, limited, Body(limited, text)))
        {
            Assert.Equal(HttpStatusCode.TooManyRequests, denied.StatusCode); Assert.Equal(sends, wire.Calls);
            B18AssertNoCanary(canaries, await denied.Content.ReadAsStringAsync(ct));
        }
        await factory.Services.GetRequiredService<Sentry.IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        capture.Meter.RecordObservableInstruments();
        // The repair request names only the closed code; the invalid model output (its mention) is never sent back.
        Assert.DoesNotContain("Previous output was invalid", wire.Requests[0], StringComparison.Ordinal);
        Assert.Contains("Previous output was invalid (refRange)", wire.Requests[1], StringComparison.Ordinal);
        Assert.All(wire.Requests, body => Assert.DoesNotContain(canaries[10], body, StringComparison.Ordinal));
        var logs = string.Join('\n', capture.Logs.Lines);
        Assert.Contains("invalid=refRange", logs, StringComparison.Ordinal);
        Assert.Contains(capture.Activities, a => a.Contains("buddy.invalid_output=refRange", StringComparison.Ordinal));
        Assert.Contains(capture.Transport.Envelopes, envelope => envelope.Contains("\"exception\"", StringComparison.Ordinal));
        await capture.AssertAbsentAsync(canaries, await SinkCapture.AuditAsync(postgres), postgres);
    }

    private sealed class ThrowingResolver(string text) : FitnessBuddy.Modules.Catalog.Contracts.IFoodResolver
    {
        public Task<IReadOnlyList<FitnessBuddy.Modules.Catalog.Contracts.FoodCandidate>> ResolveAsync(FitnessBuddy.Modules.Catalog.Contracts.FoodMention mention, CancellationToken cancellationToken) =>
            throw new InvalidOperationException(text + " " + mention.CanonicalEn);
        public Task<FitnessBuddy.Modules.Catalog.Contracts.FoodDetails?> DetailsAsync(string key, CancellationToken cancellationToken) => throw new InvalidOperationException(text + " " + key);
    }

    // Unescaped UTF-8 like the app's jsonEncode, so Arabic canaries travel as real text.
    private static readonly JsonSerializerOptions B18Relaxed = new() { Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping };

    private static string B18Encode(string raw, Dictionary<string, JsonNode?> fields)
    {
        var payload = JsonNode.Parse(raw)!.AsObject();
        foreach (var field in fields) { payload[field.Key] = field.Value; }
        return payload.ToJsonString(B18Relaxed);
    }

    private static void B18AssertNoCanary(IEnumerable<string> canaries, string body)
    {
        foreach (var canary in canaries.SelectMany(c => new[] { c, JsonSerializer.Serialize(c)[1..^1] }))
        { Assert.DoesNotContain(canary, body, StringComparison.OrdinalIgnoreCase); }
    }
    [Fact]
    public void Privacy_capture_detects_numeric_measurements_scopes_and_unformatted_structured_fields()
    {
        var metrics = new ConcurrentQueue<string>();
        using var listener = CaptureMetrics(metrics);
        using var source = new Meter("B17.PrivacyCapture.PositiveControl");
        source.CreateCounter<byte>("byte").Add(197);
        source.CreateCounter<short>("short").Add(29173);
        source.CreateCounter<int>("int").Add(917264931);
        source.CreateCounter<long>("long").Add(8172649312345L);
        source.CreateHistogram<float>("float").Record(713.25f);
        source.CreateHistogram<double>("double").Record(613.125);
        source.CreateHistogram<decimal>("decimal").Record(513.0625m);
        foreach (var marker in new[] { "197", "29173", "917264931", "8172649312345", "713.25", "613.125", "513.0625" })
        { Assert.Contains(marker, metrics); }

        using var logs = new CaptureLogs();
        var logger = logs.CreateLogger("B17.PositiveControl");
        using (logger.BeginScope(new Dictionary<string, object?> { ["ScopeKeyMarker"] = "ScopeValueMarker" }))
        {
            // Neither the formatter nor Dictionary.ToString reveals these fields.
            if (logger.IsEnabled(LogLevel.Information))
            {
                logger.Log(LogLevel.Information, new EventId(1),
                    new Dictionary<string, object?> { ["FieldKeyMarker"] = "FieldValueMarker" }, null, (_, _) => "fixed message");
            }
        }
        var captured = string.Join('\n', logs.Lines);
        foreach (var marker in new[] { "ScopeKeyMarker", "ScopeValueMarker", "FieldKeyMarker", "FieldValueMarker" })
        { Assert.Contains(marker, captured, StringComparison.Ordinal); }
    }

    // Every diagnostic sink the API writes to (B05/B17/B18 D13): logs and scopes through the production
    // scrubbing decorator, activities, every metric type, serialized Sentry envelopes; audit rows and
    // Postgres logs are read at the end.
    private sealed class SinkCapture : IDisposable
    {
        private readonly ActivityListener listener;
        public SinkCapture()
        {
            listener = new ActivityListener
            {
                ShouldListenTo = _ => true,
                Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllDataAndRecorded,
                SampleUsingParentId = (ref ActivityCreationOptions<string> _) => ActivitySamplingResult.AllDataAndRecorded,
                ActivityStopped = activity => Activities.Enqueue(activity.DisplayName + string.Join('|', activity.TagObjects.Select(t => $"{t.Key}={t.Value}")) + activity.StatusDescription + string.Join('|', activity.Events.Select(e => e.Name + string.Join('|', e.Tags)))),
            };
            ActivitySource.AddActivityListener(listener);
            Meter = CaptureMetrics(Metrics);
        }
        public CaptureLogs Logs { get; } = new();
        public ConcurrentQueue<string> Activities { get; } = new();
        public ConcurrentQueue<string> Metrics { get; } = new();
        public CaptureSentry Transport { get; } = new();
        public MeterListener Meter { get; }

        public WebApplicationFactory<Program> Configure(WebApplicationFactory<Program> factory, Action<IServiceCollection> services) => factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(new Dictionary<string, string?> { ["Sentry:Dsn"] = "https://public@localhost/1" }));
            builder.ConfigureTestServices(collection =>
            {
                collection.AddSingleton<ILoggerProvider>(_ => new ScrubbingLoggerProvider(Logs));
                collection.Configure<SentryAspNetCoreOptions>(options => options.Transport = Transport);
                services(collection);
            });
        });

        // API cannot read even its own audit table directly. Inspect using the schema owner.
        public static async Task<List<string>> AuditAsync(PostgresFixture postgres)
        {
            await using var owner = FitnessBuddy.BuildingBlocks.Persistence.DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
            await using var read = owner.CreateCommand("SELECT row_to_json(a)::text FROM identity.audit a");
            await using var reader = await read.ExecuteReaderAsync(TestContext.Current.CancellationToken);
            var auditLines = new List<string>(); while (await reader.ReadAsync(TestContext.Current.CancellationToken)) { auditLines.Add(reader.GetString(0)); }
            return auditLines;
        }

        public async Task AssertAbsentAsync(IEnumerable<string> canaries, IReadOnlyList<string> auditLines, PostgresFixture postgres)
        {
            foreach (var canary in canaries.SelectMany(c => new[] { c, JsonSerializer.Serialize(c)[1..^1] }).Distinct(StringComparer.Ordinal))
            {
                Assert.DoesNotContain(canary, string.Join('\n', Logs.Lines), StringComparison.OrdinalIgnoreCase);
                Assert.DoesNotContain(canary, string.Join('\n', Activities), StringComparison.OrdinalIgnoreCase);
                Assert.DoesNotContain(canary, string.Join('\n', Metrics), StringComparison.OrdinalIgnoreCase);
                Assert.DoesNotContain(canary, string.Join('\n', Transport.Envelopes), StringComparison.OrdinalIgnoreCase);
                Assert.DoesNotContain(canary, string.Join('\n', auditLines), StringComparison.OrdinalIgnoreCase);
                Assert.DoesNotContain(canary, await postgres.LogsAsync(), StringComparison.OrdinalIgnoreCase);
            }
        }

        public void Dispose() { Meter.Dispose(); listener.Dispose(); Logs.Dispose(); }
    }

    private static MeterListener CaptureMetrics(ConcurrentQueue<string> metrics)
    {
        var listener = new MeterListener { InstrumentPublished = (instrument, receiver) => receiver.EnableMeasurementEvents(instrument) };
        Capture<byte>(); Capture<short>(); Capture<int>(); Capture<long>(); Capture<float>(); Capture<double>(); Capture<decimal>();
        listener.Start();
        return listener;

        void Capture<T>() where T : struct, IFormattable => listener.SetMeasurementEventCallback<T>((_, value, tags, _) =>
        {
            metrics.Enqueue(value.ToString(value is double or float ? "R" : null, System.Globalization.CultureInfo.InvariantCulture));
            foreach (var tag in tags) { metrics.Enqueue($"{tag.Key}={tag.Value}"); }
        });
    }

    private sealed class FailingWithContent(string text) : FitnessBuddy.Modules.UserData.Application.ISyncStore
    {
        public Task<FitnessBuddy.Modules.UserData.Domain.PushOutcome?> PushForSessionAsync(FitnessBuddy.Modules.Identity.Contracts.IdentitySession principal, Guid? dataset, IReadOnlyList<FitnessBuddy.Modules.UserData.Domain.SyncVersion> versions, DateTimeOffset now, CancellationToken cancellationToken) =>
            throw new InvalidOperationException(string.Join('\n', versions.Select(v => v.Payload.GetRawText())));
        public Task<FitnessBuddy.Modules.UserData.Domain.VersionPage?> PullForSessionAsync(FitnessBuddy.Modules.Identity.Contracts.IdentitySession principal, Guid? dataset, long cursor, int limit, bool history, string? entity, Guid? id, CancellationToken cancellationToken) =>
            throw new InvalidOperationException(text);
    }

    private sealed class FailingHistory : FitnessBuddy.Modules.UserData.Application.ISyncStore
    {
        public Task<FitnessBuddy.Modules.UserData.Domain.PushOutcome?> PushForSessionAsync(FitnessBuddy.Modules.Identity.Contracts.IdentitySession principal, Guid? dataset, IReadOnlyList<FitnessBuddy.Modules.UserData.Domain.SyncVersion> versions, DateTimeOffset now, CancellationToken cancellationToken) => throw new InvalidOperationException("CANARY-PATH-PRIVATE");
        public Task<FitnessBuddy.Modules.UserData.Domain.VersionPage?> PullForSessionAsync(FitnessBuddy.Modules.Identity.Contracts.IdentitySession principal, Guid? dataset, long cursor, int limit, bool history, string? entity, Guid? id, CancellationToken cancellationToken) => throw new InvalidOperationException("CANARY-PATH-PRIVATE");
    }

    private sealed class FailingGoogle : IGoogleIdentityVerifier
    {
        public Task<GoogleIdentity?> VerifyAsync(string idToken, CancellationToken ct) => throw new InvalidOperationException(idToken + " CANARY-IDENTITY-EMAIL@example.invalid");
    }
    private sealed class SelectiveEmail(IdentityHarness.CapturingEmail inner, List<string> canaries) : IEmailSender
    {
        public Task SendAsync(Guid challenge, string address, string code, DateTimeOffset expiresAt, CancellationToken ct)
        {
            if (address.StartsWith("canary-delivery", StringComparison.OrdinalIgnoreCase))
            {
                canaries.Add(code);
                throw new InvalidOperationException(address + " " + code);
            }
            return inner.SendAsync(challenge, address, code, expiresAt, ct);
        }
    }
    private sealed class CaptureSentry : ITransport
    {
        public ConcurrentQueue<string> Envelopes { get; } = new();
        public async Task SendEnvelopeAsync(Envelope envelope, CancellationToken cancellationToken = default)
        {
            using var stream = new MemoryStream(); await envelope.SerializeAsync(stream, null, cancellationToken);
            Envelopes.Enqueue(Encoding.UTF8.GetString(stream.ToArray()));
        }
    }
    private sealed class CaptureLogs : ILoggerProvider, ISupportExternalScope
    {
        public ConcurrentQueue<string> Lines { get; } = new();
        private IExternalScopeProvider scopes = new LoggerExternalScopeProvider();
        public void SetScopeProvider(IExternalScopeProvider scopeProvider) => scopes = scopeProvider;
        public ILogger CreateLogger(string categoryName) => new Logger(this);
        private void CaptureState(object? state)
        {
            Lines.Enqueue(state?.ToString() ?? "");
            if (state is IEnumerable<KeyValuePair<string, object?>> fields)
            {
                foreach (var field in fields) { Lines.Enqueue($"{field.Key}={field.Value}"); }
            }
        }
        public void Dispose() { }
        private sealed class Logger(CaptureLogs owner) : ILogger
        {
            public IDisposable? BeginScope<TState>(TState state) where TState : notnull => owner.scopes.Push(state);
            public bool IsEnabled(LogLevel logLevel) => true;
            public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
            {
                owner.Lines.Enqueue(formatter(state, exception) + " " + exception);
                owner.CaptureState(state);
                owner.scopes.ForEachScope((scope, capture) => capture.CaptureState(scope), owner);
            }
        }
    }
}
