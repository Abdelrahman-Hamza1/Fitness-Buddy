using System.Collections.Concurrent;
using System.Net;
using System.Text.RegularExpressions;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Account.Contracts;
using FitnessBuddy.Modules.Account.Infrastructure;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23 WP6 (T6, T7b–T7d, T10a): the remote-config window on a private database: draft → diff with reach → publish → rollback,
// the minimum-version ceiling, typed confirmation and recent sign-in, draft revision binding, and no user content anywhere.
[Trait("Req", "AD-012")]
[Trait("Req", "AD-006")]
[Trait("Req", "AD-005")]
public sealed partial class AdminConfigTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task Draft_diff_publish_and_rollback_change_the_published_config_with_one_audit_row_each()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await SeedInstallsAsync(database, ("1.4.0", 3), ("1.2.0", 2));
        await using var admin = await StartAsync(database);
        await SeedAsync(admin, database);
        using var owner = await SignInAsync(admin);

        var (page, body, _) = await owner.GetAsync("/admin/config");
        Assert.Equal(HttpStatusCode.OK, page);
        Assert.Contains("version 1", body, StringComparison.Ordinal);
        Assert.Contains("1.4.0", body, StringComparison.Ordinal);

        Assert.Equal(HttpStatusCode.Redirect, (await owner.PostAsync("/admin/config/draft", Form("0.1.0", "buddy.photo_enabled = on", ai: true))).Status);
        var (_, draftBody, _) = await owner.GetAsync("/admin/config");
        Assert.Contains("buddy.photo_enabled", draftBody, StringComparison.Ordinal);
        Assert.Contains("Affects all 5 active installs", draftBody, StringComparison.Ordinal);
        var (publish, _, response) = await owner.PostAsync("/admin/config/publish", PublishForm(draftBody, "turn on photos"));
        Assert.Equal(HttpStatusCode.Redirect, publish);
        Assert.Equal("/admin/config?published=2", response.Headers.Location!.OriginalString);
        Assert.Equal(2, await LatestVersionAsync(database));
        Assert.Equal(1, await AuditAsync(database, "publish", "ok"));
        Assert.Equal(0L, await ScalarAsync(database, "SELECT count(*) FROM admin.config_draft"));

        var (review, reviewBody, _) = await owner.GetAsync("/admin/config/rollback/1");
        Assert.Equal(HttpStatusCode.OK, review);
        Assert.Contains("buddy.photo_enabled", reviewBody, StringComparison.Ordinal);
        Assert.Equal(HttpStatusCode.Redirect, (await owner.PostAsync("/admin/config/rollback/1", new Dictionary<string, string?>
        {
            ["expectedVersion"] = "2",
            ["reason"] = "photos broke",
        })).Status);
        Assert.Equal(3, await LatestVersionAsync(database));
        Assert.Equal(1, await AuditAsync(database, "rollback", "ok"));
        Assert.Equal(await DocumentAsync(database, 1), await DocumentAsync(database, 3));
        Assert.Equal(1L, await ScalarAsync(database, "SELECT rolled_back_from FROM account.config_versions WHERE version=3"));
        // The audit row carries the change itself (before/after), with the reason.
        Assert.Equal(1L, await ScalarAsync(database, "SELECT count(*) FROM admin.audit_log WHERE action='publish' AND before IS NOT NULL AND after IS NOT NULL AND reason='turn on photos'"));
    }

    [Fact]
    [Trait("Req", "AD-007")]
    public async Task The_minimum_can_never_pass_the_newest_reported_version_and_a_raise_needs_typing_and_a_recent_sign_in()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await SeedInstallsAsync(database, ("1.4.0", 1), ("1.2.0", 4));
        await using var admin = await StartAsync(database);
        await SeedAsync(admin, database);
        using var owner = await SignInAsync(admin);

        await owner.PostAsync("/admin/config/draft", Form("999.0.0", "", ai: true));
        var (_, body, _) = await owner.GetAsync("/admin/config");
        Assert.Contains("Blocked", body, StringComparison.Ordinal);
        Assert.Equal(HttpStatusCode.Conflict, (await owner.PostAsync("/admin/config/publish", PublishForm(body, "lock out", "999.0.0"))).Status);
        Assert.Equal(1, await LatestVersionAsync(database));
        Assert.Equal(1, await AuditAsync(database, "publish", "above-newest-reported"));

        await owner.PostAsync("/admin/config/draft", Form("1.4.0", "", ai: true));
        (_, body, _) = await owner.GetAsync("/admin/config");
        Assert.Contains("to 4 of 5 installs", body, StringComparison.Ordinal);
        Assert.Equal(HttpStatusCode.BadRequest, (await owner.PostAsync("/admin/config/publish", PublishForm(body, "raise", "1.3.0"))).Status);
        admin.Clock.Advance(TimeSpan.FromMinutes(16));
        (_, body, _) = await owner.GetAsync("/admin/config");
        var (stale, _, staleResponse) = await owner.PostAsync("/admin/config/publish", PublishForm(body, "raise", "1.4.0"));
        Assert.Equal(HttpStatusCode.Redirect, stale);
        Assert.StartsWith("/admin/reauth", staleResponse.Headers.Location!.OriginalString, StringComparison.Ordinal);
        Assert.Equal(1, await LatestVersionAsync(database));

        // The same publish from the boosted form (htmx): a full navigation to re-auth, never a swapped-in sign-in page, whose
        // Google script and CSP would not load. The re-auth page itself, reached through htmx, also asks for a full load.
        var htmx = new Dictionary<string, string> { ["HX-Request"] = "true" };
        var (boosted, _, boostedResponse) = await owner.PostAsync("/admin/config/publish", PublishForm(body, "raise", "1.4.0"), htmx);
        Assert.Equal(HttpStatusCode.NoContent, boosted);
        Assert.Equal("/admin/reauth?return=%2Fadmin%2Fconfig", Assert.Single(boostedResponse.Headers.GetValues("HX-Redirect")));
        var (boostedPage, boostedBody, boostedPageResponse) = await owner.GetAsync("/admin/reauth?return=/admin/config", htmx);
        Assert.Equal(HttpStatusCode.NoContent, boostedPage);
        Assert.Equal("/admin/reauth?return=%2Fadmin%2Fconfig", Assert.Single(boostedPageResponse.Headers.GetValues("HX-Redirect")));
        Assert.DoesNotContain("data-nonce", boostedBody, StringComparison.Ordinal);
        Assert.Equal(1, await LatestVersionAsync(database));

        await owner.GetAsync("/admin/reauth?return=/admin/config");
        await owner.PostAsync("/admin/reauth", new Dictionary<string, string?> { ["credential"] = AdminApp.Credential("sub-owner", "owner@example.invalid", owner.Nonce!), ["return"] = "/admin/config" });
        (_, body, _) = await owner.GetAsync("/admin/config");
        Assert.Equal(HttpStatusCode.Redirect, (await owner.PostAsync("/admin/config/publish", PublishForm(body, "raise", "1.4.0"))).Status);
        Assert.Equal(2, await LatestVersionAsync(database));
    }

    [Fact]
    public async Task Every_published_version_stays_reachable_through_history_pages_and_rollback_review()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await using var admin = await StartAsync(database);
        await SeedAsync(admin, database);
        // 25 versions: more than one history page (20).
        await ScalarObjectAsync(database, """
            INSERT INTO account.config_versions(version,document,published_at,published_by,reason)
            SELECT g, v.document, now(), 'owner', 'bulk ' || g FROM account.config_versions v CROSS JOIN generate_series(2,25) g WHERE v.version=1
            """);
        using var owner = await SignInAsync(admin);

        var (_, first, _) = await owner.GetAsync("/admin/config");
        Assert.Contains("/admin/config/rollback/6\"", first, StringComparison.Ordinal);
        Assert.DoesNotContain("/admin/config/rollback/5\"", first, StringComparison.Ordinal);
        Assert.Contains("/admin/config?before=6", first, StringComparison.Ordinal);
        var (older, olderBody, _) = await owner.GetAsync("/admin/config?before=6");
        Assert.Equal(HttpStatusCode.OK, older);
        Assert.Contains("/admin/config/rollback/1\"", olderBody, StringComparison.Ordinal);
        Assert.DoesNotContain("before=", olderBody, StringComparison.Ordinal);
        var (review, reviewBody, _) = await owner.GetAsync("/admin/config/rollback/1");
        Assert.Equal(HttpStatusCode.OK, review);
        Assert.Contains("Roll back to version 1", reviewBody, StringComparison.Ordinal);
        Assert.Equal(HttpStatusCode.NotFound, (await owner.GetAsync("/admin/config/rollback/99")).Status);
    }

    [Fact]
    public async Task With_no_reported_installs_a_raise_is_refused_but_other_changes_publish()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await using var admin = await StartAsync(database);
        await SeedAsync(admin, database);
        using var owner = await SignInAsync(admin);
        await owner.PostAsync("/admin/config/draft", Form("0.2.0", "", ai: true));
        var (_, body, _) = await owner.GetAsync("/admin/config");
        Assert.Equal(HttpStatusCode.Conflict, (await owner.PostAsync("/admin/config/publish", PublishForm(body, "raise", "0.2.0"))).Status);
        await owner.PostAsync("/admin/config/draft", Form("0.1.0", "", ai: false));
        (_, body, _) = await owner.GetAsync("/admin/config");
        Assert.Equal(HttpStatusCode.Redirect, (await owner.PostAsync("/admin/config/publish", PublishForm(body, "AI off"))).Status);
        Assert.Equal(2, await LatestVersionAsync(database));
    }

    [Fact]
    public async Task Publish_is_bound_to_the_reviewed_revision_and_two_publishers_make_one_version()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await using var admin = await StartAsync(database);
        await SeedAsync(admin, database);
        using var tabA = await SignInAsync(admin);
        using var tabB = await SignInAsync(admin);
        await tabA.PostAsync("/admin/config/draft", Form("0.1.0", "a.flag = on", ai: true));
        var (_, reviewedByA, _) = await tabA.GetAsync("/admin/config");
        await tabB.PostAsync("/admin/config/draft", Form("0.1.0", "b.flag = on", ai: true));
        Assert.Equal(HttpStatusCode.Conflict, (await tabA.PostAsync("/admin/config/publish", PublishForm(reviewedByA, "A's change"))).Status);
        Assert.Equal(1, await LatestVersionAsync(database));
        Assert.Equal(1, await AuditAsync(database, "publish", "draft-changed"));

        var (_, current, _) = await tabA.GetAsync("/admin/config");
        var (_, sameForB, _) = await tabB.GetAsync("/admin/config");
        var results = await Task.WhenAll(
            tabA.PostAsync("/admin/config/publish", PublishForm(current, "first")),
            tabB.PostAsync("/admin/config/publish", PublishForm(sameForB, "second")));
        Assert.Single(results, result => result.Status == HttpStatusCode.Redirect);
        Assert.Equal(2, await LatestVersionAsync(database));
        Assert.Equal(1, await AuditAsync(database, "publish", "ok"));
        Assert.Contains("b.flag", await DocumentAsync(database, 2), StringComparison.Ordinal);
    }

    [Fact]
    [Trait("Req", "AD-001")]
    [Trait("Req", "AD-002")]
    public async Task No_user_content_reaches_any_console_page_or_log()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        var canaries = await SeedUserContentAsync(database);
        await SeedInstallsAsync(database, ("1.4.0", 1));
        var logs = new ConcurrentQueue<string>();
        await using var admin = await StartAsync(database, builder => builder.Logging.AddProvider(new CapturingLogs(logs)));
        await SeedAsync(admin, database);
        using var owner = await SignInAsync(admin);
        await owner.PostAsync("/admin/config/draft", Form("0.1.0", "x.flag = on", ai: true));
        var (_, draftPage, _) = await owner.GetAsync("/admin/config");
        Assert.Equal(HttpStatusCode.Redirect, (await owner.PostAsync("/admin/config/publish", PublishForm(draftPage, "x on"))).Status);
        await owner.PostAsync("/admin/config/draft", Form("0.1.0", "y.flag = off", ai: true));

        var pages = admin.Services.GetRequiredService<EndpointDataSource>().Endpoints.OfType<RouteEndpoint>()
            .Where(endpoint => endpoint.Metadata.GetMetadata<HttpMethodMetadata>()?.HttpMethods.Contains("GET") == true)
            .Select(endpoint => endpoint.RoutePattern.RawText!)
            .Where(path => path.StartsWith("/admin", StringComparison.Ordinal) && !path.Contains("/assets/", StringComparison.Ordinal) && path != "/admin/signin")
            .Select(path => path.Replace("{version:int}", "1", StringComparison.Ordinal))
            // Paged and filtered variants render through the same code with other rows.
            .Concat(["/admin/config?before=2", "/admin/audit?area=config", "/admin/audit/export.csv?area=config"]).Distinct().ToArray();
        Assert.Contains("/admin/config", pages);
        Assert.Contains("/admin/audit/export.csv", pages);
        var bodies = new List<string>();
        foreach (var path in pages)
        {
            var (status, body, _) = await owner.GetAsync(path);
            Assert.True(status is HttpStatusCode.OK or HttpStatusCode.Redirect, path + " " + status);
            Assert.DoesNotContain('{', path);
            bodies.Add(body);
        }
        foreach (var canary in canaries)
        {
            foreach (var body in bodies) { Assert.DoesNotContain(canary, body, StringComparison.OrdinalIgnoreCase); }
            Assert.DoesNotContain(logs, line => line.Contains(canary, StringComparison.OrdinalIgnoreCase));
        }
        Assert.DoesNotContain(logs, line => line.Contains("owner@example.invalid", StringComparison.OrdinalIgnoreCase) || line.Contains("sub-owner", StringComparison.Ordinal));
    }

    private async Task<AdminApp> StartAsync(ConfigDatabase database, Action<Microsoft.AspNetCore.Builder.WebApplicationBuilder>? configure = null) =>
        await AdminApp.StartAsync(postgres, new Dictionary<string, string?> { ["ConnectionStrings:Admin"] = database.Admin }, configure: configure);

    private static async Task SeedAsync(AdminApp admin, ConfigDatabase database) =>
        await PostgresRemoteConfig.SeedAsync(database.Migrator, admin.Services.GetRequiredService<IRemoteConfigAdmin>().Defaults, DateTimeOffset.UtcNow, Ct);

    private static async Task<AdminApp.Browser> SignInAsync(AdminApp admin)
    {
        var browser = admin.NewBrowser();
        await browser.SignInAsync("sub-owner", "owner@example.invalid");
        await browser.GetAsync("/admin");
        return browser;
    }

    private static Dictionary<string, string?> Form(string minimum, string flags, bool ai) => new()
    {
        ["minimumAppVersion"] = minimum,
        ["appFlags"] = flags,
        ["server.buddy.ai"] = ai ? "on" : null,
    };

    private static Dictionary<string, string?> PublishForm(string page, string reason, string? typed = null) => new()
    {
        ["baseVersion"] = Hidden(page, "baseVersion"),
        ["revision"] = Hidden(page, "revision"),
        ["hash"] = Hidden(page, "hash"),
        ["reason"] = reason,
        ["typedVersion"] = typed,
    };

    private static string Hidden(string page, string name) =>
        Regex.Match(page, "name=\"" + name + "\" value=\"([^\"]*)\"") is { Success: true } match ? match.Groups[1].Value : "";

    private static async Task SeedInstallsAsync(ConfigDatabase database, params (string Version, int Count)[] installs)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.Migrator);
        foreach (var (version, count) in installs)
        {
            for (var i = 0; i < count; i++)
            {
                var user = Guid.NewGuid();
                await using var command = owner.CreateCommand("""
                    INSERT INTO identity.users(id,anonymous,created_at) VALUES($1,true,now());
                    """);
                command.Parameters.AddWithValue(user);
                await command.ExecuteNonQueryAsync(Ct);
                await using var device = owner.CreateCommand("INSERT INTO identity.devices(user_id,device_id,last_seen_at,app_version,platform) VALUES($1,$2,now(),$3,'android')");
                device.Parameters.AddWithValue(user);
                device.Parameters.AddWithValue(Guid.NewGuid());
                device.Parameters.AddWithValue(version);
                await device.ExecuteNonQueryAsync(Ct);
            }
        }
    }

    /// <summary>
    /// T10a: two registered accounts, each with canary strings and numbers in every content category the console must never show
    /// (diary, personal food, chat, proposal, weigh-in, measurement), plus its full email, Google subject and device id.
    /// Returns every canary.
    /// </summary>
    private static async Task<string[]> SeedUserContentAsync(ConfigDatabase database)
    {
        var canaries = new List<string>();
        foreach (var account in new[] { "a", "b" })
        {
            var user = Guid.NewGuid();
            var device = Guid.NewGuid();
            var tag = account.ToUpperInvariant() + user.ToString("N")[..8];
            var email = "canary.person." + tag.ToLowerInvariant() + "@example.invalid";
            var subject = "canary-subject-" + user.ToString("N");
            var number = (account == "a" ? "123.456789" : "987.654321");
            canaries.AddRange([email, subject, device.ToString(), number]);
            await using (var owner = DatabaseConfiguration.CreateSource(database.Migrator))
            {
                await using var identity = owner.CreateCommand("INSERT INTO identity.users(id,anonymous,created_at) VALUES($1,false,now())");
                identity.Parameters.AddWithValue(user);
                await identity.ExecuteNonQueryAsync(Ct);
                await using var mail = owner.CreateCommand("INSERT INTO identity.identities(provider,subject,user_id,email) VALUES('google',$1,$2,$3)");
                mail.Parameters.AddWithValue(subject);
                mail.Parameters.AddWithValue(user);
                mail.Parameters.AddWithValue(email);
                await mail.ExecuteNonQueryAsync(Ct);
                await using var seen = owner.CreateCommand("INSERT INTO identity.devices(user_id,device_id,last_seen_at,app_version,platform) VALUES($1,$2,now(),'1.4.0','android')");
                seen.Parameters.AddWithValue(user);
                seen.Parameters.AddWithValue(device);
                await seen.ExecuteNonQueryAsync(Ct);
            }
            (string Entity, string Field)[] content =
            [
                ("diaryEntry", "name"), ("personalFood", "name"), ("chatMessage", "text"), ("proposal", "summary"), ("weighIn", "note"), ("measurement", "note"),
            ];
            await using var app = DatabaseConfiguration.CreateSource(database.App);
            await using var session = new DatabaseSession();
            await session.BeginAsync(app, user, Ct);
            var counter = 0;
            foreach (var (entity, field) in content)
            {
                var canary = "CANARY-" + entity.ToUpperInvariant() + "-" + tag;
                canaries.Add(canary);
                await using var insert = session.Command("""
                    INSERT INTO userdata.documents(user_id,entity,id,schema_version,hlc,device_id,payload)
                    VALUES($1,$2,$3,1,$4,$5,jsonb_build_object($6::text,$7::text,'value',$8::numeric))
                    """);
                insert.Parameters.AddWithValue(user);
                insert.Parameters.AddWithValue(entity);
                insert.Parameters.AddWithValue(Guid.NewGuid());
                insert.Parameters.AddWithValue("1760351234567-" + (++counter).ToString("D5", System.Globalization.CultureInfo.InvariantCulture) + "-" + device);
                insert.Parameters.AddWithValue(device);
                insert.Parameters.AddWithValue(field);
                insert.Parameters.AddWithValue(canary);
                insert.Parameters.AddWithValue(decimal.Parse(number, System.Globalization.CultureInfo.InvariantCulture));
                await insert.ExecuteNonQueryAsync(Ct);
            }
            await session.CommitAsync(Ct);
        }
        return [.. canaries];
    }

    private static async Task<int> LatestVersionAsync(ConfigDatabase database) => (int)(await ScalarObjectAsync(database, "SELECT max(version) FROM account.config_versions"))!;

    private static async Task<string> DocumentAsync(ConfigDatabase database, int version) =>
        (string)(await ScalarObjectAsync(database, "SELECT document::text FROM account.config_versions WHERE version=" + version.ToString(System.Globalization.CultureInfo.InvariantCulture)))!;

    private static async Task<int> AuditAsync(ConfigDatabase database, string action, string outcome) =>
        (int)await ScalarAsync(database, "SELECT count(*) FROM admin.audit_log WHERE area='config' AND action='" + action + "' AND outcome='" + outcome + "'");

    private static async Task<long> ScalarAsync(ConfigDatabase database, string sql) => Convert.ToInt64(await ScalarObjectAsync(database, sql), System.Globalization.CultureInfo.InvariantCulture);

    private static async Task<object?> ScalarObjectAsync(ConfigDatabase database, string sql)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.Migrator);
        await using var command = owner.CreateCommand(sql);
        return await command.ExecuteScalarAsync(Ct);
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
