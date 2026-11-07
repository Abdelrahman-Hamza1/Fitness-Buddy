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

    // B25 (TD-125, TD-128, exit criteria 2–4) with a scripted model and no provider: the turn stream carries the user's own words
    // by design, while logs, spans, metrics, Sentry, the audit table and the ledger rows hold none of them. Along the way it pins
    // the protocol: SSE ids, a phone round trip, attempt-scoped proposal IDs, one message per turn across a retry, 409 for an
    // acknowledged round, error invalid for wrong call IDs and error expired for an old continuation or a third attempt.
    [Fact, Trait("Rule", "09.4-no-user-content"), Trait("Req", "AC-040")]
    public async Task B25_agent_turns_stream_content_while_logs_telemetry_and_ledger_omit_it()
    {
        var ct = TestContext.Current.CancellationToken;
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var capture = new SinkCapture();
        string[] canaries = ["CANARY-B25-MESSAGE", "رسالة-وكيل-سرية-كناري", "CANARY-B25-PERSONAL", "CANARY-B25-ENTRY", "CANARY-B25-REPLY", "CANARY-B25-HISTORY", "CANARY-B25-MEMORY"];
        var keyDir = Directory.CreateTempSubdirectory("fb-b25-seal-");
        var keyFile = Path.Combine(keyDir.FullName, "seal");
        // Built at runtime (no key-shaped literal in the repository).
        await File.WriteAllTextAsync(keyFile, Convert.ToBase64String(System.Security.Cryptography.RandomNumberGenerator.GetBytes(32)), ct);
        if (!OperatingSystem.IsWindows()) { File.SetUnixFileMode(keyFile, UnixFileMode.UserRead | UnixFileMode.UserWrite); }
        var model = new ScriptedAgentModel(canaries);
        using var wire = new BuddyApiTests.BuddyWire();
        await using var api = capture.Configure(new BuddyApiTests.BuddyApi(postgres, h, wire,
            configure: s => s.AddScoped<FitnessBuddy.Modules.Buddy.Application.IAgentModel>(_ => model)), _ => { });
        await using var factory = api.WithWebHostBuilder(b => b.ConfigureAppConfiguration((_, c) => c.AddInMemoryCollection(new Dictionary<string, string?>
        { ["Buddy:Agent:SealKeyFile"] = keyFile, ["Buddy:Agent:TraceEnabled"] = "true" })));
        using var client = factory.CreateClient(); BuddyApiTests.Headers(client, h); await BuddyApiTests.SignIn(client, h);
        var personal = "019a0b0c-0000-4000-8000-000000000301";
        var turnA = Guid.CreateVersion7();

        JsonObject Start(Guid turn, string text, Guid? ack = null, JsonObject? prior = null) => new()
        {
            ["turnId"] = turn.ToString(),
            ["mode"] = "chat",
            ["message"] = new JsonObject { ["text"] = text, ["image"] = null },
            ["history"] = new JsonArray(new JsonObject { ["messageId"] = "019a0b0c-0000-7000-8000-000000000001", ["role"] = "user", ["text"] = canaries[5], ["outcomes"] = new JsonArray() }),
            ["summary"] = null,
            ["compact"] = null,
            ["personal"] = new JsonArray(new JsonObject
            {
                ["ref"] = personal,
                ["kind"] = "personalFood",
                ["names"] = new JsonArray(canaries[2]),
                ["aliases"] = new JsonArray(),
                ["state"] = "cooked",
                ["per100"] = new JsonObject { ["kcal"] = 150, ["proteinG"] = 10, ["carbsG"] = 5, ["fatG"] = 8, ["fiberG"] = 0 },
                ["servings"] = new JsonArray(new JsonObject { ["unitCode"] = "piece", ["g"] = 50, ["ml"] = null, ["rangeLo"] = null, ["rangeHi"] = null, ["source"] = "user" }),
                ["portions"] = new JsonArray(),
            }),
            ["profile"] = new JsonObject
            {
                ["memory"] = new JsonArray(new JsonObject { ["kind"] = "alias", ["key"] = "shake", ["value"] = canaries[6] }),
                ["defaults"] = new JsonArray(),
                ["halal"] = true,
                ["units"] = new JsonObject { ["mass"] = "kg", ["length"] = "cm", ["energy"] = "kcal" },
                ["ramadan"] = new JsonObject { ["active"] = false, ["fajr"] = null, ["maghrib"] = null },
            },
            ["snapshot"] = new JsonObject
            {
                ["now"] = h.Clock.GetUtcNow().ToString("O"),
                ["tzOffsetMin"] = 120,
                ["slots"] = new JsonArray(),
                ["today"] = new JsonObject
                {
                    ["kcal"] = 900,
                    ["proteinG"] = 40,
                    ["carbsG"] = 100,
                    ["fatG"] = 30,
                    ["fiberG"] = 10,
                    ["targets"] = new JsonObject { ["kcal"] = 2100, ["proteinG"] = 120, ["carbsG"] = null, ["fatG"] = null, ["fiberG"] = null }
                },
                ["openCards"] = new JsonArray(),
            },
            ["ackTurn"] = ack is { } a ? new JsonObject { ["turnId"] = a.ToString() } : null,
            ["priorAttempt"] = prior,
            ["trace"] = true,
        };
        async Task<(HttpStatusCode Status, List<(string Id, JsonNode Data)> Events, string Body)> PostAsync(string path, Guid turn, JsonNode body)
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, path) { Content = new StringContent(body.ToJsonString(B18Relaxed), Encoding.UTF8, "application/json") };
            request.Headers.Add("Idempotency-Key", turn.ToString());
            using var response = await client.SendAsync(request, ct);
            var text = await response.Content.ReadAsStringAsync(ct);
            var events = new List<(string, JsonNode)>();
            if (response.Content.Headers.ContentType?.MediaType == "text/event-stream")
            {
                Assert.Equal("no", response.Headers.GetValues("X-Accel-Buffering").Single());
                foreach (var frame in text.Split("\n\n", StringSplitOptions.RemoveEmptyEntries).Where(f => !f.StartsWith(':')))
                {
                    var lines = frame.Split('\n');
                    events.Add((lines[0]["id: ".Length..], JsonNode.Parse(lines[1]["data: ".Length..])!));
                }
            }
            return (response.StatusCode, events, text);
        }
        static string Type((string, JsonNode Data) e) => e.Data["type"]!.GetValue<string>();
        var user = Guid.Parse((await h.Tokens.ValidateAsync(client.DefaultRequestHeaders.Authorization!.Parameter!, ct))!.FindFirst("sub")!.Value);
        async Task<long> MessagesAsync()
        {
            await using var inspect = await postgres.SessionAsync(user);
            await using var read = inspect.Command("SELECT coalesce(sum(messages),0)::bigint FROM usage.daily WHERE user_id=$1"); read.Parameters.AddWithValue(user);
            return (long)(await read.ExecuteScalarAsync(ct))!;
        }

        // 1. A phone round trip: proposal (personal slice first) + read_diary → phoneTools; the continuation answers it → text, done.
        var a0 = await PostAsync("/v1/buddy/turns", turnA, Start(turnA, $"{canaries[0]} {canaries[1]} {canaries[2]} and what did I eat"));
        Assert.Equal(HttpStatusCode.OK, a0.Status);
        Assert.Equal(Enumerable.Range(0, a0.Events.Count).Select(i => $"{turnA}:0:{i}"), a0.Events.Select(e => e.Id));
        Assert.Equal(["step", "proposal", "step", "trace", "phoneTools"], a0.Events.Select(Type));
        var proposal = a0.Events.Single(e => Type(e) == "proposal").Data;
        Assert.Equal(FitnessBuddy.Modules.Buddy.Domain.ProposalIds.For(turnA, 0, 1, 0).ToString(), proposal["proposalId"]!.GetValue<string>());
        Assert.Equal(personal, proposal["intent"]!["items"]![0]!["match"]!["key"]!.GetValue<string>());
        var pause = a0.Events.Last().Data;
        var call = pause["calls"]![0]!;
        JsonObject Continue(string callId, string entryName = "") => new()
        {
            ["turnId"] = turnA.ToString(),
            ["round"] = 1,
            ["continuation"] = pause["continuation"]!.GetValue<string>(),
            ["priorAttempt"] = null,
            ["results"] = new JsonArray(new JsonObject
            {
                ["name"] = "readDiary",
                ["callId"] = callId,
                ["ok"] = true,
                ["error"] = null,
                ["data"] = new JsonObject
                {
                    ["truncated"] = false,
                    ["entries"] = new JsonArray(new JsonObject
                    { ["id"] = "019a0b0c-0000-4000-8000-000000000401", ["date"] = "2026-10-16", ["slot"] = "Lunch", ["name"] = canaries[3] + entryName, ["grams"] = 200, ["kcal"] = 330 })
                },
            }),
        };
        // Nested result limits are checked before any ledger change: 400, and the round can still run.
        var oversized = await PostAsync("/v1/buddy/turns/continue", turnA, Continue(call["callId"]!.GetValue<string>(), new string('x', 300)));
        Assert.Equal(HttpStatusCode.BadRequest, oversized.Status); B18AssertNoCanary(canaries, oversized.Body);
        var wrong = await PostAsync("/v1/buddy/turns/continue", turnA, Continue(Guid.CreateVersion7().ToString()));
        Assert.Equal(["error"], wrong.Events.Select(Type)); Assert.Equal("invalid", wrong.Events[0].Data["code"]!.GetValue<string>());
        var a1 = await PostAsync("/v1/buddy/turns/continue", turnA, Continue(call["callId"]!.GetValue<string>()));
        Assert.Equal(HttpStatusCode.OK, a1.Status);
        Assert.Equal("done", Type(a1.Events[^1])); Assert.Equal("answered", a1.Events[^1].Data["reason"]!.GetValue<string>());
        var reply = string.Concat(a1.Events.Where(e => Type(e) == "text").Select(e => e.Data["text"]!.GetValue<string>()));
        Assert.Contains("330 kcal", reply, StringComparison.Ordinal); // a claim rendered by code
        Assert.Equal(1, await MessagesAsync());
        // A retry of that round must repeat its results (digest): different results are invalid, with no send.
        var sendsBefore = model.Calls;
        var changed = await PostAsync("/v1/buddy/turns/continue", turnA, Continue(call["callId"]!.GetValue<string>(), "-changed"));
        Assert.Equal("invalid", changed.Events.Single().Data["code"]!.GetValue<string>()); Assert.Equal(sendsBefore, model.Calls);

        // 2. A completed but unacknowledged round re-runs once as attempt 2 with new card IDs and no new message; a third is expired.
        var turnB = Guid.CreateVersion7();
        var b1 = await PostAsync("/v1/buddy/turns", turnB, Start(turnB, $"2 {canaries[2]}"));
        Assert.Equal(["step", "proposal", "text", "trace", "done"], b1.Events.Select(Type));
        var firstCard = b1.Events.Single(e => Type(e) == "proposal").Data["proposalId"]!.GetValue<string>();
        JsonObject Prior() => new() { ["attempt"] = 1, ["cards"] = new JsonArray(new JsonObject { ["proposalId"] = firstCard, ["status"] = "pending", ["revision"] = 1, ["line"] = canaries[2] }) };
        var b2 = await PostAsync("/v1/buddy/turns", turnB, Start(turnB, $"2 {canaries[2]}", prior: Prior()));
        Assert.Equal(FitnessBuddy.Modules.Buddy.Domain.ProposalIds.For(turnB, 0, 2, 0).ToString(), b2.Events.Single(e => Type(e) == "proposal").Data["proposalId"]!.GetValue<string>());
        Assert.Equal(2, await MessagesAsync());
        var b3 = await PostAsync("/v1/buddy/turns", turnB, Start(turnB, $"2 {canaries[2]}"));
        Assert.Equal("expired", b3.Events.Single().Data["code"]!.GetValue<string>());

        // A first post may already carry priorAttempt (the phone's send was ambiguous but never arrived): it runs as attempt 1.
        var turnF = Guid.CreateVersion7();
        var f1 = await PostAsync("/v1/buddy/turns", turnF, Start(turnF, $"2 {canaries[2]}", prior: new JsonObject { ["attempt"] = 1, ["cards"] = new JsonArray() }));
        Assert.Equal(FitnessBuddy.Modules.Buddy.Domain.ProposalIds.For(turnF, 0, 1, 0).ToString(), f1.Events.Single(e => Type(e) == "proposal").Data["proposalId"]!.GetValue<string>());

        // 3. An acknowledged round (ackTurn in the next start) already ran: 409 without a send.
        var turnC = Guid.CreateVersion7();
        Assert.Equal(HttpStatusCode.OK, (await PostAsync("/v1/buddy/turns", turnC, Start(turnC, $"2 {canaries[2]}", ack: turnB))).Status);
        var sends = model.Calls;
        var replay = await PostAsync("/v1/buddy/turns", turnB, Start(turnB, $"2 {canaries[2]}"));
        Assert.Equal(HttpStatusCode.Conflict, replay.Status); Assert.Equal(sends, model.Calls);
        B18AssertNoCanary(canaries, replay.Body);

        // An app that doesn't know a tool answers it with the unsupported variant; the model gets a tool error and the turn ends.
        var turnE = Guid.CreateVersion7();
        var e0 = await PostAsync("/v1/buddy/turns", turnE, Start(turnE, $"{canaries[0]} what did I eat"));
        var ePause = e0.Events.Last().Data;
        var e1 = await PostAsync("/v1/buddy/turns/continue", turnE, new JsonObject
        {
            ["turnId"] = turnE.ToString(),
            ["round"] = 1,
            ["continuation"] = ePause["continuation"]!.GetValue<string>(),
            ["priorAttempt"] = null,
            ["results"] = new JsonArray(new JsonObject { ["name"] = "unsupported", ["callId"] = ePause["calls"]![0]!["callId"]!.GetValue<string>(), ["ok"] = false, ["error"] = "unsupported" }),
        });
        Assert.True(Type(e1.Events[^1]) == "done", string.Join(",", e1.Events.Select(e => e.Data.ToJsonString())));

        // 4. A continuation older than 10 minutes is expired, with no send.
        var turnD = Guid.CreateVersion7();
        var d0 = await PostAsync("/v1/buddy/turns", turnD, Start(turnD, $"{canaries[0]} what did I eat"));
        var paused = d0.Events.Last().Data;
        h.Clock.Advance(TimeSpan.FromMinutes(11)); sends = model.Calls;
        var late = await PostAsync("/v1/buddy/turns/continue", turnD, new JsonObject
        {
            ["turnId"] = turnD.ToString(),
            ["round"] = 1,
            ["continuation"] = paused["continuation"]!.GetValue<string>(),
            ["priorAttempt"] = null,
            ["results"] = new JsonArray(new JsonObject { ["name"] = "readDiary", ["callId"] = paused["calls"]![0]!["callId"]!.GetValue<string>(), ["ok"] = false, ["error"] = "unavailable", ["data"] = null }),
        });
        Assert.Equal("expired", late.Events.Single().Data["code"]!.GetValue<string>()); Assert.Equal(sends, model.Calls);

        // Diagnostics and the ledger hold no content (the stream itself carries the user's words by design).
        await factory.Services.GetRequiredService<Sentry.IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        capture.Meter.RecordObservableInstruments();
        Assert.Contains(capture.Logs.Lines, l => l.Contains("Buddy turn", StringComparison.Ordinal) && l.Contains("prompt=agent-v1", StringComparison.Ordinal));
        await using (var inspect = await postgres.SessionAsync(user))
        {
            await using var rows = inspect.Command("SELECT (SELECT count(*) FROM buddy.turns)::text || ' ' || coalesce((SELECT string_agg(row_to_json(t)::text, ' ') FROM buddy.turns t), '') || coalesce((SELECT string_agg(row_to_json(r)::text, ' ') FROM buddy.turn_rounds r), '')");
            var ledger = (string)(await rows.ExecuteScalarAsync(ct))!;
            Assert.StartsWith("6 ", ledger, StringComparison.Ordinal);
            B18AssertNoCanary(canaries, ledger);
            // Every send's input reservation was reconciled to the reported usage (1200 per scripted send): none outstanding.
            await using var reserved = inspect.Command("SELECT coalesce(sum(reserved_input),0)::bigint, coalesce(sum(input_tokens),0)::bigint, coalesce(sum(sends),0)::bigint FROM buddy.turns");
            await using var totals = await reserved.ExecuteReaderAsync(ct); Assert.True(await totals.ReadAsync(ct));
            Assert.Equal(0, totals.GetInt64(0)); Assert.Equal(1200 * totals.GetInt64(2), totals.GetInt64(1));
        }
        await capture.AssertAbsentAsync(canaries, await SinkCapture.AuditAsync(postgres), postgres);
        keyDir.Delete(recursive: true);
    }

    // B26 WP5: a label read returns the label's values (by design: the user reviews them) while logs, spans, metrics, Sentry, the
    // audit table and Postgres hold neither the photo nor anything read from it. Code converts kJ and salt; Usage counts one message.
    [Fact, Trait("Rule", "09.4-no-user-content"), Trait("Req", "AC-040"), Trait("Req", "FD-041")]
    public async Task B26_label_read_returns_values_while_logs_and_telemetry_omit_photo_and_text()
    {
        var ct = TestContext.Current.CancellationToken;
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var capture = new SinkCapture();
        string[] canaries = ["CANARY-B26-LABEL-NAME", "CANARY-B26-SERVING", "CANARY-B26-VITAMIN", "CANARY-B26-PHOTO"];
        var reader = new ScriptedLabelReader(canaries);
        using var wire = new BuddyApiTests.BuddyWire();
        await using var factory = capture.Configure(new BuddyApiTests.BuddyApi(postgres, h, wire,
            configure: s => s.AddScoped<FitnessBuddy.Modules.Buddy.Application.ILabelReader>(_ => reader)), _ => { });
        using var client = factory.CreateClient(); BuddyApiTests.Headers(client, h); await BuddyApiTests.SignIn(client, h);
        // A valid JPEG whose comment segment carries the canary (built at runtime).
        var photo = BuddyApiTests.Photo(comment: canaries[3] + new string('x', 64));

        // Not a JPEG, a truncated one, one larger than 1024 px, or one without scan data: 400 before any allowance or call.
        var noScan = Convert.FromBase64String(BuddyApiTests.Photo()); noScan = [.. noScan[..^18], 0xFF, 0xD9]; // frame header, then EOI
        foreach (var bad in new[] { Convert.ToBase64String(Encoding.UTF8.GetBytes(canaries[3] + "-not-a-jpeg")), photo[..^8], BuddyApiTests.Photo(side: 2000), Convert.ToBase64String(noScan) })
        {
            using var rejected = await client.PostAsJsonAsync("/v1/buddy/label", new { image = bad }, ct);
            Assert.Equal(HttpStatusCode.BadRequest, rejected.StatusCode);
        }
        Assert.Equal(0, reader.Calls);
        var response = await client.PostAsJsonAsync("/v1/buddy/label", new { image = photo }, ct);
        var body = await response.Content.ReadAsStringAsync(ct);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var read = JsonNode.Parse(body)!;
        Assert.True(read["found"]!.GetValue<bool>());
        Assert.Equal(canaries[0], read["name"]!["value"]!.GetValue<string>());
        Assert.Equal(100, read["nutrients"]!["kcal"]!["value"]!.GetValue<double>()); Assert.True(read["nutrients"]!["kcalFromKj"]!.GetValue<bool>());
        Assert.Equal(400, read["nutrients"]!["sodiumMg"]!["value"]!.GetValue<double>()); Assert.True(read["nutrients"]!["sodiumFromSalt"]!.GetValue<bool>());
        Assert.Null(read["nutrients"]!["proteinG"]!["value"]); // 140 g per 100 g can't be on a label
        Assert.Equal("low", read["nutrients"]!["proteinG"]!["confidence"]!.GetValue<string>());
        Assert.Equal(1, reader.Calls);

        var user = Guid.Parse((await h.Tokens.ValidateAsync(client.DefaultRequestHeaders.Authorization!.Parameter!, ct))!.FindFirst("sub")!.Value);
        await using (var inspect = await postgres.SessionAsync(user))
        {
            await using var usage = inspect.Command("SELECT coalesce(sum(messages),0)::bigint, coalesce(sum(calls),0)::bigint FROM usage.daily WHERE user_id=$1");
            usage.Parameters.AddWithValue(user);
            await using var row = await usage.ExecuteReaderAsync(ct); Assert.True(await row.ReadAsync(ct));
            Assert.Equal(1, row.GetInt64(0)); Assert.Equal(1, row.GetInt64(1));
        }
        await using (var owner = FitnessBuddy.BuildingBlocks.Persistence.DatabaseConfiguration.CreateSource(postgres.MigratorConnection))
        await using (var cleanup = owner.CreateCommand("SELECT count(*) FROM ops.schedules WHERE name=$1"))
        {
            cleanup.Parameters.AddWithValue("buddy.cleanup:" + user);
            Assert.Equal(1L, await cleanup.ExecuteScalarAsync(ct)); // label-only accounts' usage rows still expire
        }
        await factory.Services.GetRequiredService<Sentry.IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        capture.Meter.RecordObservableInstruments();
        Assert.Contains(capture.Logs.Lines, l => l.Contains("Buddy label outcome=ok", StringComparison.Ordinal) && l.Contains("prompt=label-v1", StringComparison.Ordinal));
        await capture.AssertAbsentAsync([.. canaries, photo[8..40]], await SinkCapture.AuditAsync(postgres), postgres);
    }

    /// <summary>A label model that transcribes canaries: kJ only (code converts), salt only (code converts), an impossible protein.</summary>
    private sealed class ScriptedLabelReader(string[] canaries) : FitnessBuddy.Modules.Buddy.Application.ILabelReader
    {
        private int calls;
        public int Calls => calls;
        public Task<FitnessBuddy.Modules.Buddy.Application.LabelRead> ReadAsync(string imageBase64, CancellationToken cancellationToken)
        {
            Interlocked.Increment(ref calls);
            BuddyLabelValue V(double? v) => new(v, BuddyLabelConfidence.High);
            var none = new LabelMass(null, null, BuddyLabelConfidence.Low);
            var reading = new LabelReading(true, BuddyLabelBasis.Per100g, new(1, "cup", 240, null, canaries[1], BuddyLabelConfidence.Medium),
                new(canaries[0], BuddyLabelConfidence.High),
                new(V(null), V(418.4), V(140), V(12), V(3), V(1), V(5), V(1), V(0), none, new LabelMass(1, LabelMassUnit.G, BuddyLabelConfidence.High), none),
                [new(canaries[2], 12, "mg", BuddyLabelConfidence.Low)]);
            return Task.FromResult(new FitnessBuddy.Modules.Buddy.Application.LabelRead(FitnessBuddy.Modules.Buddy.Application.AgentModelStatus.Success, reading,
                new(900, 0, 120), 0.0002m, 5));
        }
    }

    /// <summary>A model that answers from the transcript shape only: a food log (+ a diary read when asked), then a reply with a claim.</summary>
    private sealed class ScriptedAgentModel(string[] canaries) : FitnessBuddy.Modules.Buddy.Application.IAgentModel
    {
        private int calls;
        public int Calls => calls;
        public Task<FitnessBuddy.Modules.Buddy.Application.AgentModelResult> SendAsync(FitnessBuddy.Modules.Buddy.Application.AgentModelRequest request, CancellationToken cancellationToken)
        {
            var n = Interlocked.Increment(ref calls);
            var last = request.Transcript[^1];
            var usage = new FitnessBuddy.Modules.Buddy.Application.TokenUsage(1200, 0, 80);
            FitnessBuddy.Modules.Buddy.Application.AgentModelResult Result(string text, params AgentToolCall[] toolCalls) =>
                new(FitnessBuddy.Modules.Buddy.Application.AgentModelStatus.Success, text, toolCalls, usage, 0.0001m, 5);
            if (last.Role == AgentRole.Tool)
            {
                // The phone's diary row came back as an entry handle with a kcal claim; the reply refers to it by ID.
                var entryClaim = System.Text.RegularExpressions.Regex.Match(last.Results[0].ResultJson, "\"kcal\":\"(k[0-9]+)\"").Groups[1].Value;
                return Task.FromResult(Result($"{canaries[4]}: lunch was {{fact:{entryClaim}}}."));
            }
            var text = last.Text ?? "";
            var log = new AgentToolCall($"call-{n}-log", "propose_food_log", JsonSerializer.Serialize(new
            {
                items = new[] { new { mention = canaries[2], canonicalNameEn = canaries[2], nameAr = (string?)null, amount = 2, unit = "piece", amountExplicit = true, ambiguities = Array.Empty<string>() } },
                slotHint = "breakfast",
            }));
            return Task.FromResult(text.Contains("what did I eat", StringComparison.Ordinal)
                ? Result("", log, new AgentToolCall($"call-{n}-diary", "read_diary", "{\"dateHint\":\"today\"}"))
                : Result("", log));
        }
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
