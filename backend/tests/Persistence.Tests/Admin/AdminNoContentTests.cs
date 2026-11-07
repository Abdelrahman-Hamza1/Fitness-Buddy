using System.Collections.Concurrent;
using System.Net;
using FitnessBuddy.Modules.Account.Contracts;
using FitnessBuddy.Modules.Account.Infrastructure;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23 WP11 (T10b, card exit 3): no user content reaches any console page, the CSV export or the logs. Every GET route of the
// console is enumerated (new windows are covered automatically), each account's detail page is rendered (the metadata account's
// too: its device controls carry the app-version canary, R1 audit), and the email lookup's
// pages too. Bodies are HTML-decoded before the scan, so an encoded canary can't slip through. The masked email does appear.
// B23b: writer-controlled metadata (types, error types, roles, builds, codes, versions, an email domain) carries canaries too.
[Trait("Req", "AD-001")]
[Trait("Req", "AD-002")]
public sealed class AdminNoContentTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task No_user_content_reaches_any_console_page_the_csv_or_the_logs()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        var seed = await MonitorSeed.CreateAsync(database);
        await seed.SeedMetadataCanariesAsync(database);
        var logs = new ConcurrentQueue<string>();
        await using var admin = await AdminApp.StartAsync(postgres, new Dictionary<string, string?> { ["ConnectionStrings:Admin"] = database.Admin },
            configure: builder => builder.Logging.AddProvider(new CapturingLogs(logs)));
        await PostgresRemoteConfig.SeedAsync(database.Migrator, admin.Services.GetRequiredService<IRemoteConfigAdmin>().Defaults, DateTimeOffset.UtcNow, Ct);
        using var owner = admin.NewBrowser();
        await owner.SignInAsync("sub-owner", "owner@example.invalid");
        await owner.GetAsync("/admin/jobs");
        // Changes and lookups that write audit rows, so the audit page and CSV have rows to render.
        await owner.PostAsync("/admin/jobs/retry", new Dictionary<string, string?> { ["kind"] = "job", ["id"] = seed.DeadJob.ToString() });
        await owner.GetAsync("/admin/accounts");
        var bodies = new List<string>();
        foreach (var email in new[] { seed.Email, seed.Email.ToUpperInvariant(), "Canary.Person." + seed.Tag })
        {
            bodies.Add((await owner.PostAsync("/admin/accounts/find", new Dictionary<string, string?> { ["email"] = email })).Body);
        }

        var routes = admin.Services.GetRequiredService<EndpointDataSource>().Endpoints.OfType<RouteEndpoint>()
            .Where(endpoint => endpoint.Metadata.GetMetadata<HttpMethodMetadata>()?.HttpMethods.Contains("GET") == true)
            .Select(endpoint => endpoint.RoutePattern.RawText!.TrimEnd('/'))
            .Where(path => path.StartsWith("/admin", StringComparison.Ordinal) && !path.Contains("/assets/", StringComparison.Ordinal) && path != "/admin/signin")
            .ToArray();
        foreach (var window in new[] { "/admin", "/admin/accounts", "/admin/accounts/{id:guid}", "/admin/jobs", "/admin/catalog", "/admin/config", "/admin/audit", "/admin/audit/export.csv" })
        {
            Assert.Contains(window, routes);
        }
        var pages = routes.SelectMany(path => path.Contains("{id:guid}", StringComparison.Ordinal)
                ? [.. new[] { seed.Registered, seed.Guest, seed.Stranger }.Select(id => path.Replace("{id:guid}", id.ToString(), StringComparison.Ordinal))]
                : new[] { path.Replace("{version:int}", "1", StringComparison.Ordinal) })
            .Concat(["/admin/accounts?issues=1", "/admin/accounts?type=google", "/admin/jobs?result=retried", "/admin/audit?area=accounts",
                "/admin/audit/export.csv", "/admin/audit/export.csv?area=jobs"])
            .Distinct().ToArray();
        foreach (var path in pages)
        {
            var (status, body, _) = await owner.GetAsync(path);
            Assert.DoesNotContain('{', path);
            // The rollback review of the only version is a "not found" page, which renders through the same layout.
            Assert.True(status is HttpStatusCode.OK || (status == HttpStatusCode.NotFound && path.Contains("/rollback/", StringComparison.Ordinal)), path + " " + status);
            bodies.Add(body);
        }
        var decoded = bodies.Select(WebUtility.HtmlDecode).ToArray();
        foreach (var canary in seed.Canaries)
        {
            foreach (var body in decoded) { Assert.DoesNotContain(canary, body!, StringComparison.OrdinalIgnoreCase); }
            Assert.DoesNotContain(logs, line => line.Contains(canary, StringComparison.OrdinalIgnoreCase));
        }
        Assert.DoesNotContain(logs, line => line.Contains("Canary.Person", StringComparison.OrdinalIgnoreCase) || line.Contains("owner@example.invalid", StringComparison.OrdinalIgnoreCase));
        Assert.Contains(decoded, body => body!.Contains(seed.MaskedEmail, StringComparison.Ordinal));
        // The mapped metadata is visibly there, as the closed fallback.
        Assert.Contains(decoded, body => body!.Contains("<code>other</code>", StringComparison.Ordinal));
    }

    private sealed class CapturingLogs(ConcurrentQueue<string> lines) : ILoggerProvider
    {
        public ILogger CreateLogger(string categoryName) => new Logger(lines);

        public void Dispose() { }

        private sealed class Logger(ConcurrentQueue<string> lines) : ILogger
        {
            public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

            public bool IsEnabled(LogLevel logLevel) => true;

            public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter) =>
                lines.Enqueue(formatter(state, exception) + " " + exception);
        }
    }
}
