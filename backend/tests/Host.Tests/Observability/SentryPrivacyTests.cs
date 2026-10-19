using System.Collections.Concurrent;
using System.Text;
using System.Text.Json;
using FitnessBuddy.Host.Observability;
using FitnessBuddy.Host.Tests.Infrastructure;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Sentry.AspNetCore;
using Sentry.Extensibility;
using Sentry.Protocol;
using Sentry.Protocol.Envelopes;

namespace FitnessBuddy.Host.Tests.Observability;

// Proves 09 §4 / TD-058 against the actual serialized Sentry transport envelope.
[Collection("Observability")]
[Trait("Rule", "09.4-logging")]
public sealed class SentryPrivacyTests
{
    [Fact]
    public async Task Sentry_event_for_a_500_is_scrubbed_and_sent_exactly_once()
    {
        var transport = new CapturingTransport();
        await using var factory = ApiFactory.With(new Dictionary<string, string?>
        {
            ["Sentry:Dsn"] = "https://public@localhost/1",
        }).WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
            services.Configure<SentryAspNetCoreOptions>(options => options.Transport = transport)));
        using var client = factory.CreateClient();
        using var request = Api.Get("/v1/_probe/throw?q=CANARY-QUERY");
        request.Headers.Remove("X-Device-Id");
        request.Headers.Add("X-Device-Id", TelemetryPrivacyTests.Canaries[4]);
        request.Headers.Add("Authorization", "Bearer CANARY-AUTH");
        using var response = await client.SendAsync(request, Api.Ct);
        Assert.Equal(500, (int)response.StatusCode);
        await factory.Services.GetRequiredService<IHub>().FlushAsync(TimeSpan.FromSeconds(5));
        var envelope = Assert.Single(transport.Envelopes, text => text.Contains("\"type\":\"event\"", StringComparison.Ordinal));
        TelemetryPrivacyTests.AssertClean(envelope);
        Assert.Contains(nameof(InvalidOperationException), envelope, StringComparison.Ordinal);
        var eventLine = envelope.Split('\n').First(line => line.Contains("\"exception\":", StringComparison.Ordinal));
        using var json = JsonDocument.Parse(eventLine);
        Assert.False(json.RootElement.GetProperty("request").TryGetProperty("url", out _));
        Assert.Equal(typeof(InvalidOperationException).FullName, json.RootElement.GetProperty("exception").GetProperty("values")[0].GetProperty("type").GetString());
        Assert.False(json.RootElement.GetProperty("exception").GetProperty("values")[0].TryGetProperty("value", out _));
    }

    [Fact]
    public void Scrubber_removes_request_data_user_extra_and_nested_exception_values_but_keeps_safe_headers()
    {
        var sentryEvent = new SentryEvent
        {
            TransactionName = "CANARY-BODY",
            Request = new SentryRequest
            {
                Url = "https://example.test/path?q=CANARY-QUERY",
                QueryString = "q=CANARY-QUERY",
                Data = "CANARY-BODY",
                Cookies = "CANARY-AUTH",
            },
            User = new SentryUser { Email = "CANARY-BODY@example.test", Id = "CANARY-AUTH" },
            Message = new SentryMessage { Message = "Request failed with {Code}", Formatted = "CANARY-BODY", Params = ["CANARY-BODY"] },
            SentryExceptions = [new SentryException
            {
                Type = "System.Exception", Value = "CANARY-EXCEPTION", Mechanism = new Mechanism(),
            }],
        };
        sentryEvent.SetTag("RequestPath", "CANARY-BODY");
        sentryEvent.Request.Headers["Authorization"] = "CANARY-AUTH";
        sentryEvent.Request.Headers["X-Device-Id"] = TelemetryPrivacyTests.Canaries[4];
        sentryEvent.Request.Headers["x-app-version"] = "0.1.0";
        sentryEvent.Request.Headers["X-Platform"] = "android";
        sentryEvent.Request.Env["REMOTE_ADDR"] = "CANARY-AUTH";
        sentryEvent.Request.Other["payload"] = "CANARY-BODY";
        sentryEvent.SetExtra("CANARY-QUERY", "CANARY-BODY");
        Assert.Single(sentryEvent.SentryExceptions!).Mechanism!.Data["secret"] = "CANARY-BODY";
        SentryScrubber.Scrub(sentryEvent);
        Assert.Null(sentryEvent.Request.Url);
        Assert.Null(sentryEvent.TransactionName);
        Assert.Empty(sentryEvent.Tags);
        Assert.Equal(2, sentryEvent.Request.Headers.Count);
        Assert.Empty(sentryEvent.Extra);
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream))
        {
            sentryEvent.WriteTo(writer, null);
        }

        TelemetryPrivacyTests.AssertClean(Encoding.UTF8.GetString(stream.ToArray()));
    }

    private sealed class CapturingTransport : ITransport
    {
        public ConcurrentQueue<string> Envelopes { get; } = new();

        public async Task SendEnvelopeAsync(Envelope envelope, CancellationToken cancellationToken = default)
        {
            using var stream = new MemoryStream();
            await envelope.SerializeAsync(stream, null, cancellationToken);
            Envelopes.Enqueue(Encoding.UTF8.GetString(stream.ToArray()));
        }
    }
}
