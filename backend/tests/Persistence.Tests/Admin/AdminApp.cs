using System.Globalization;
using System.Net;
using System.Text.Json;
using System.Text.RegularExpressions;
using FitnessBuddy.Host.Roles;
using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Persistence.Tests.Admin;

/// <summary>
/// The real admin role on a test server, with the fb_admin login against the shared test database, a fake Google verifier,
/// a test clock and a private allow-list file. <see cref="StartAsync"/> can map test-only routes before the app starts.
/// </summary>
internal sealed partial class AdminApp : IAsyncDisposable
{
    public const string ClientId = "admin-web-client";
    private readonly WebApplication app;
    private readonly string directory;

    private AdminApp(WebApplication app, string directory, TestClock clock)
    {
        this.app = app;
        this.directory = directory;
        Clock = clock;
    }

    public IServiceProvider Services => app.Services;

    public TestClock Clock { get; }

    public string AllowListPath => Path.Combine(directory, "allow-list.json");

    public static async Task<AdminApp> StartAsync(PostgresFixture postgres, IReadOnlyDictionary<string, string?>? overrides = null,
        Action<WebApplication>? map = null, object? allowList = null, Action<WebApplicationBuilder>? configure = null)
    {
        var directory = Directory.CreateTempSubdirectory("fb-admin-test-").FullName;
        await File.WriteAllTextAsync(Path.Combine(directory, "allow-list.json"), JsonSerializer.Serialize(allowList ?? DefaultAllowList), TestContext.Current.CancellationToken);
        // A real-time start so session rows from different tests never look expired to each other; tests advance it.
        var clock = new TestClock(DateTimeOffset.UtcNow);
        var settings = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase)
        {
            ["ConnectionStrings:Admin"] = postgres.AdminConnection,
            ["Clients:MinimumAppVersion"] = "0.1.0",
            ["Admin:GoogleClientId"] = ClientId,
            ["Admin:AllowListFile"] = Path.Combine(directory, "allow-list.json"),
            ["Admin:SignInPermitPerMinute"] = "10000",
            ["Admin:SignInPermitPerMinuteTotal"] = "100000",
            ["Account:RemoteConfig:PollSeconds"] = "300",
        };
        foreach (var (key, value) in overrides ?? new Dictionary<string, string?>()) { settings[key] = value; }
        var app = AdminRole.Build(["--environment=Testing"], builder =>
        {
            builder.WebHost.UseTestServer();
            builder.Configuration.AddInMemoryCollection(settings);
            builder.Services.AddSingleton<TimeProvider>(clock);
            builder.Services.AddSingleton<IGoogleIdTokenVerifier>(new FakeGoogle(clock));
            builder.Services.AddSingleton(TestVocabulary);
            configure?.Invoke(builder);
        });
        map?.Invoke(app);
        await app.StartAsync(TestContext.Current.CancellationToken);
        return new AdminApp(app, directory, clock);
    }

    /// <summary>The queue codes the console shows as they are: the real ones plus the seeds' test types (B23b).</summary>
    public static FitnessBuddy.BuildingBlocks.Ops.QueueVocabulary TestVocabulary { get; } =
        FitnessBuddy.BuildingBlocks.Ops.QueueVocabulary.Default.With(["test.monitor", "test.retry-once", "test.held"], ["test.monitor-event", "test.busy-event"]);

    /// <summary>owner (operator) and reader (viewer) are pinned; newbie is pending.</summary>
    public static object DefaultAllowList => new
    {
        admins = new object[]
        {
            new { handle = "owner", googleSubject = "sub-owner", email = "owner@example.invalid", role = "operator" },
            new { handle = "reader", googleSubject = "sub-reader", email = "reader@example.invalid", role = "viewer" },
        },
        pending = new object[] { new { handle = "newbie", email = "newbie@example.invalid", role = "viewer" } },
    };

    /// <summary>Rewrites the allow-list and moves the clock past the 10 s recheck so the console reads it.</summary>
    public async Task ReplaceAllowListAsync(object allowList)
    {
        await File.WriteAllTextAsync(AllowListPath, JsonSerializer.Serialize(allowList), TestContext.Current.CancellationToken);
        File.SetLastWriteTimeUtc(AllowListPath, DateTime.UtcNow.AddSeconds(Random.Shared.Next(1, 1000)));
        Clock.Advance(TimeSpan.FromSeconds(11));
    }

    public Browser NewBrowser() => new(app.GetTestClient());

    public async ValueTask DisposeAsync()
    {
        await app.DisposeAsync();
        try { Directory.Delete(directory, recursive: true); } catch (IOException) { }
    }

    /// <summary>A fake Google credential: <c>fake|sub|email|nonce|iat-offset-seconds|auth-time-offset-seconds-or-empty|audience</c>.</summary>
    public static string Credential(string subject, string email, string nonce, int iatOffset = -5, int? authTimeOffset = null, string audience = ClientId) =>
        string.Join('|', "fake", subject, email, nonce, iatOffset.ToString(CultureInfo.InvariantCulture),
            authTimeOffset?.ToString(CultureInfo.InvariantCulture) ?? "", audience);

    private sealed class FakeGoogle(TimeProvider clock) : IGoogleIdTokenVerifier
    {
        public Task<VerifiedGoogleToken?> VerifyAsync(string idToken, IReadOnlyCollection<string> audiences, CancellationToken cancellationToken)
        {
            var parts = idToken.Split('|');
            if (parts.Length != 7 || parts[0] != "fake" || !audiences.Contains(parts[6])) { return Task.FromResult<VerifiedGoogleToken?>(null); }
            var now = clock.GetUtcNow();
            DateTimeOffset? authTime = parts[5].Length == 0 ? null : now.AddSeconds(int.Parse(parts[5], CultureInfo.InvariantCulture));
            return Task.FromResult<VerifiedGoogleToken?>(new VerifiedGoogleToken(parts[1], parts[2],
                now.AddSeconds(int.Parse(parts[4], CultureInfo.InvariantCulture)), authTime, parts[3].Length == 0 ? null : parts[3]));
        }
    }

    /// <summary>A minimal browser: keeps cookies, reads the page's antiforgery token and Google nonce, posts forms.</summary>
    internal sealed partial class Browser(HttpClient client) : IDisposable
    {
        private readonly Dictionary<string, string> cookies = new(StringComparer.Ordinal);

        public string? Csrf { get; private set; }

        public string? Nonce { get; private set; }

        public IReadOnlyDictionary<string, string> Cookies => cookies;

        public string? LastSetCookie { get; private set; }

        public async Task<(HttpStatusCode Status, string Body, HttpResponseMessage Response)> GetAsync(string path, IReadOnlyDictionary<string, string>? headers = null)
        {
            using var request = new HttpRequestMessage(HttpMethod.Get, path);
            return await SendAsync(request, headers);
        }

        public async Task<(HttpStatusCode Status, string Body, HttpResponseMessage Response)> PostAsync(string path, IReadOnlyDictionary<string, string?> form,
            IReadOnlyDictionary<string, string>? headers = null, bool includeCsrf = true)
        {
            var fields = new Dictionary<string, string>(StringComparer.Ordinal);
            foreach (var (key, value) in form) { if (value is not null) { fields[key] = value; } }
            if (includeCsrf && Csrf is not null && !fields.ContainsKey("__csrf")) { fields["__csrf"] = Csrf; }
            using var request = new HttpRequestMessage(HttpMethod.Post, path) { Content = new FormUrlEncodedContent(fields) };
            return await SendAsync(request, headers);
        }

        /// <summary>Signs in (page, then the Google callback's POST); returns the final status of the POST.</summary>
        public async Task<(HttpStatusCode Status, string Body, HttpResponseMessage Response)> SignInAsync(string subject, string email, int iatOffset = -5, string? nonce = null)
        {
            await GetAsync("/admin/signin");
            return await PostAsync("/admin/signin", new Dictionary<string, string?> { ["credential"] = Credential(subject, email, nonce ?? Nonce!, iatOffset) });
        }

        public void SetCookie(string name, string value) => cookies[name] = value;

        public void Forget(string name) => cookies.Remove(name);

        private async Task<(HttpStatusCode, string, HttpResponseMessage)> SendAsync(HttpRequestMessage request, IReadOnlyDictionary<string, string>? headers)
        {
            if (cookies.Count > 0) { request.Headers.Add("Cookie", string.Join("; ", cookies.Select(c => c.Key + "=" + c.Value))); }
            foreach (var (key, value) in headers ?? new Dictionary<string, string>()) { request.Headers.TryAddWithoutValidation(key, value); }
            var response = await client.SendAsync(request, TestContext.Current.CancellationToken);
            if (response.Headers.TryGetValues("Set-Cookie", out var setCookies))
            {
                foreach (var header in setCookies)
                {
                    LastSetCookie = header;
                    var pair = header.Split(';')[0];
                    var eq = pair.IndexOf('=', StringComparison.Ordinal);
                    var name = pair[..eq];
                    var value = pair[(eq + 1)..];
                    if (value.Length == 0 || header.Contains("expires=Thu, 01 Jan 1970", StringComparison.OrdinalIgnoreCase)) { cookies.Remove(name); }
                    else { cookies[name] = value; }
                }
            }
            var body = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
            if (CsrfPattern().Match(body) is { Success: true } csrf) { Csrf = WebUtility.HtmlDecode(csrf.Groups[1].Value); }
            if (NoncePattern().Match(body) is { Success: true } nonce) { Nonce = WebUtility.HtmlDecode(nonce.Groups[1].Value); }
            return (response.StatusCode, body, response);
        }

        public void Dispose() => client.Dispose();

        [GeneratedRegex("name=\"__csrf\" value=\"([^\"]+)\"")]
        private static partial Regex CsrfPattern();

        [GeneratedRegex("data-nonce=\"([^\"]+)\"")]
        private static partial Regex NoncePattern();
    }
}
