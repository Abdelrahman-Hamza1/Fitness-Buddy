using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using FitnessBuddy.Modules.Identity.Application;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Persistence.Tests;

/// <summary>
/// The Buddy API harness (B08 → B26): a real authenticated API over the Postgres fixture with Buddy enabled and no provider.
/// Agent tests script <see cref="IAgentModel"/>; <see cref="BuddyApi.Label"/> is a counting label reader for tests that only
/// need one paid Buddy request (allowance limits, lifecycle races). The interpret tests were retired with the route (B26, TD-128).
/// </summary>
internal static class BuddyApiTests
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>
    /// A structurally valid JPEG for the label route's checks (built at runtime): SOI, an optional comment segment, a baseline frame
    /// header of <paramref name="side"/> × <paramref name="side"/> px, a scan header with a few entropy bytes, EOI. No pixels: the reader is scripted.
    /// </summary>
    internal static string Photo(int side = 64, string? comment = null)
    {
        var bytes = new List<byte> { 0xFF, 0xD8 };
        if (comment is not null)
        {
            var text = System.Text.Encoding.UTF8.GetBytes(comment);
            bytes.AddRange([0xFF, 0xFE, (byte)((text.Length + 2) >> 8), (byte)(text.Length + 2)]); bytes.AddRange(text);
        }
        bytes.AddRange([0xFF, 0xC0, 0x00, 0x11, 0x08, (byte)(side >> 8), (byte)side, (byte)(side >> 8), (byte)side, 0x03, 1, 0x22, 0, 2, 0x11, 1, 3, 0x11, 1]);
        bytes.AddRange([0xFF, 0xDA, 0x00, 0x0C, 0x03, 1, 0x00, 2, 0x11, 3, 0x11, 0x00, 0x3F, 0x00, 0x12, 0x34]); // scan header + entropy bytes
        bytes.AddRange([0xFF, 0xD9]);
        return Convert.ToBase64String([.. bytes]);
    }

    /// <summary>One label read: a paid Buddy request (one message and one send).</summary>
    internal static Task<HttpResponseMessage> SendLabel(HttpClient client) => client.PostAsJsonAsync("/v1/buddy/label", new { image = Photo() }, Ct);

    internal static void Headers(HttpClient client, IdentityHarness h)
    { client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android"); client.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString()); }
    internal static async Task SignIn(HttpClient client, IdentityHarness h)
    {
        var tokens = (await h.Service.GuestAsync(h.Device, Ct))!;
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokens.AccessToken);
    }

    internal sealed class BuddyApi(PostgresFixture p, IdentityHarness h, HttpMessageHandler wire, Action<IServiceCollection>? configure = null) : WebApplicationFactory<Program>
    {
        public CountingLabelReader Label { get; } = new();
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");
            builder.ConfigureAppConfiguration((_, c) => c.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:Application"] = p.AppConnection,
                ["Recovery:Directory"] = p.RecoveryDirectory,
                ["Identity:Enabled"] = "true",
                ["Identity:WrappingKeysDirectory"] = h.DirectoryPath,
                ["Identity:PepperFile"] = h.Options.PepperFile,
                ["Buddy:Enabled"] = "true",
                ["Buddy:ApiKeyFile"] = "/unused-synthetic",
                ["RateLimiting:PerIp:PermitLimit"] = "100000",
            }));
            builder.ConfigureTestServices(s =>
            {
                s.AddSingleton<TimeProvider>(h.Clock); s.AddSingleton<IGoogleIdentityVerifier, IdentityHarness.FakeGoogle>(); s.AddSingleton<IEmailSender>(h.Email);
                s.AddSingleton<IChatClient>(_ => OpenAIClientFactory.Create("offline-placeholder", new HttpClient(wire, disposeHandler: false)));
                s.AddScoped<ILabelReader>(_ => Label);
                configure?.Invoke(s);
            });
        }
    }

    /// <summary>A label reader that counts calls and reads nothing (found false).</summary>
    internal sealed class CountingLabelReader : ILabelReader
    {
        private int calls;
        public int Calls => calls;
        public Task<LabelRead> ReadAsync(string imageBase64, CancellationToken cancellationToken)
        {
            Interlocked.Increment(ref calls);
            var none = new BuddyLabelValue(null, BuddyLabelConfidence.Low); var mass = new LabelMass(null, null, BuddyLabelConfidence.Low);
            return Task.FromResult(new LabelRead(AgentModelStatus.Success, new LabelReading(false, null, null, new(null, BuddyLabelConfidence.Low),
                new(none, none, none, none, none, none, none, none, none, mass, mass, mass), []), new(500, 0, 20), 0.0001m, 1));
        }
    }

    /// <summary>Formatted log messages (shared with the barcode tests).</summary>
    internal sealed class CapturedLogs : Microsoft.Extensions.Logging.ILoggerProvider
    {
        public System.Collections.Concurrent.ConcurrentQueue<string> Messages { get; } = new();
        public Microsoft.Extensions.Logging.ILogger CreateLogger(string categoryName) => new Logger(Messages);
        public void Dispose() { }
        private sealed class Logger(System.Collections.Concurrent.ConcurrentQueue<string> messages) : Microsoft.Extensions.Logging.ILogger
        {
            public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
            public bool IsEnabled(Microsoft.Extensions.Logging.LogLevel logLevel) => true;
            public void Log<TState>(Microsoft.Extensions.Logging.LogLevel logLevel, Microsoft.Extensions.Logging.EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
                => messages.Enqueue(formatter(state, exception));
        }
    }

    /// <summary>The provider transport: no test reaches it (models and readers are scripted); it counts and refuses.</summary>
    internal sealed class BuddyWire : HttpMessageHandler
    {
        public int Calls { get; private set; }
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        { Calls++; return Task.FromResult(new HttpResponseMessage(HttpStatusCode.ServiceUnavailable)); }
    }
}
