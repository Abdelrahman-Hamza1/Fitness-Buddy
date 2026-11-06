using System.Net;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Admin.Application;
using FitnessBuddy.Modules.Admin.Domain;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23 WP9 (T11, T14, T1): the Overview and the Accounts window render real counts from a private database; the exact-email
// lookup finds only exact matches, is rate-limited and audited without the term; the alert rules are pure.
[Trait("Req", "AD-010")]
[Trait("Req", "AD-011")]
[Trait("Req", "AD-002")]
public sealed class AdminAccountsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task The_overview_shows_health_counts_spend_and_alerts()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await MonitorSeed.CreateAsync(database);
        await using var admin = await StartAsync(database);
        using var owner = await SignInAsync(admin);
        var (status, body, _) = await owner.GetAsync("/admin");
        Assert.Equal(HttpStatusCode.OK, status);
        Assert.Contains("No cap set", body, StringComparison.Ordinal);
        Assert.Contains("$0.25", body, StringComparison.Ordinal);
        Assert.Contains("1.4.0", body, StringComparison.Ordinal);
        // No worker beat, dead items and no catalog release are open alerts, each linking to its window.
        Assert.Contains("No worker heartbeat", body, StringComparison.Ordinal);
        Assert.Contains("2 failed queue item(s)", body, StringComparison.Ordinal);
        Assert.Contains("No catalog release is published.", body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task The_list_shows_masked_emails_and_sync_health_and_filters_by_type_and_issues()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        var seed = await MonitorSeed.CreateAsync(database);
        await using var admin = await StartAsync(database);
        using var owner = await SignInAsync(admin);
        var all = WebUtility.HtmlDecode((await owner.GetAsync("/admin/accounts")).Body);
        Assert.Contains(seed.MaskedEmail, all, StringComparison.Ordinal);
        Assert.Contains("/admin/accounts/" + seed.Guest, all, StringComparison.Ordinal);
        Assert.Contains("2 rejects", all, StringComparison.Ordinal);
        var (_, guests, _) = await owner.GetAsync("/admin/accounts?type=guest");
        Assert.DoesNotContain("/admin/accounts/" + seed.Registered, guests, StringComparison.Ordinal);
        Assert.Contains("/admin/accounts/" + seed.Guest, guests, StringComparison.Ordinal);
        var (_, issues, _) = await owner.GetAsync("/admin/accounts?issues=1");
        Assert.Contains("/admin/accounts/" + seed.Registered, issues, StringComparison.Ordinal);
        Assert.DoesNotContain("/admin/accounts/" + seed.Guest, issues, StringComparison.Ordinal);

        var (detailStatus, detail, _) = await owner.GetAsync("/admin/accounts/" + seed.Registered);
        Assert.Equal(HttpStatusCode.OK, detailStatus);
        Assert.Contains("diaryEntry", detail, StringComparison.Ordinal);
        Assert.Contains("Device 1", detail, StringComparison.Ordinal);
        Assert.Equal(HttpStatusCode.NotFound, (await owner.GetAsync("/admin/accounts/" + Guid.NewGuid())).Status);
    }

    [Fact]
    public async Task Only_an_exact_email_finds_the_account_and_lookups_are_audited_without_the_term()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        var seed = await MonitorSeed.CreateAsync(database);
        await using var admin = await StartAsync(database);
        using var reader = admin.NewBrowser();
        await reader.SignInAsync("sub-reader", "reader@example.invalid");
        await reader.GetAsync("/admin/accounts");
        foreach (var exact in new[] { seed.Email, "  " + seed.Email.ToUpperInvariant() + " ", seed.Email.ToLowerInvariant() })
        {
            var (status, _, response) = await reader.PostAsync("/admin/accounts/find", new Dictionary<string, string?> { ["email"] = exact });
            Assert.Equal(HttpStatusCode.Redirect, status);
            Assert.Equal("/admin/accounts/" + seed.Registered, response.Headers.Location!.OriginalString);
        }
        foreach (var partial in new[] { "Canary.Person." + seed.Tag, "@Example.invalid", "C%@Example.invalid", "c_nary.person." + seed.Tag + "@example.invalid" })
        {
            var (status, body, _) = await reader.PostAsync("/admin/accounts/find", new Dictionary<string, string?> { ["email"] = partial });
            Assert.Equal(HttpStatusCode.NotFound, status);
            Assert.Contains("No account has exactly that email.", body, StringComparison.Ordinal);
        }
        Assert.Equal(3L, await ScalarAsync(database, "SELECT count(*) FROM admin.audit_log WHERE area='accounts' AND action='find-by-email' AND outcome='match'"));
        // This console has no Identity lookup key, so a searched miss is audited as partial (email sign-in accounts weren't
        // searched); the term without "@" isn't searched at all.
        Assert.Equal(3L, await ScalarAsync(database, "SELECT count(*) FROM admin.audit_log WHERE area='accounts' AND action='find-by-email' AND outcome='no-match-partial'"));
        Assert.Equal(1L, await ScalarAsync(database, "SELECT count(*) FROM admin.audit_log WHERE area='accounts' AND action='find-by-email' AND outcome='no-match'"));
        Assert.Equal(0L, await ScalarAsync(database, "SELECT count(*) FROM admin.audit_log WHERE lower(row(admin.audit_log.*)::text) LIKE '%canary.person%'"));
    }

    [Fact]
    [Trait("Rule", "B23.P4-account-filters")]
    public async Task Type_and_issue_filters_apply_before_the_page_is_cut_and_the_issue_list_pages()
    {
        // 60 Google accounts with more rejects than 55 email accounts: type=email&issues=1 must still list email accounts, a
        // full page of them, and page on to the rest (B23b review).
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await using (var owner = DatabaseConfiguration.CreateSource(database.Migrator))
        {
            await using var seed = owner.CreateCommand("""
                WITH g AS (INSERT INTO identity.users(id,anonymous,created_at) SELECT gen_random_uuid(),false,now() FROM generate_series(1,60) RETURNING id),
                     gi AS (INSERT INTO identity.identities(provider,subject,user_id,email) SELECT 'google','g-'||id,id,'g@example.invalid' FROM g RETURNING user_id),
                     gs AS (INSERT INTO userdata.sync_daily(user_id,day,invalid_payload) SELECT user_id,current_date,9 FROM gi RETURNING 1),
                     e AS (INSERT INTO identity.users(id,anonymous,created_at) SELECT gen_random_uuid(),false,now() FROM generate_series(1,55) RETURNING id),
                     ei AS (INSERT INTO identity.identities(provider,subject,user_id,email) SELECT 'email',md5(id::text)||md5(id::text),id,'' FROM e RETURNING user_id)
                INSERT INTO userdata.sync_daily(user_id,day,invalid_payload) SELECT user_id,current_date,1 FROM ei
                """);
            await seed.ExecuteNonQueryAsync(Ct);
        }
        await using var admin = await StartAsync(database);
        using var owner2 = await SignInAsync(admin);
        var (status, first, _) = await owner2.GetAsync("/admin/accounts?type=email&issues=1");
        Assert.Equal(HttpStatusCode.OK, status);
        Assert.Equal(ListAccounts.PageSize, Rows(first));
        Assert.DoesNotContain("<td>google</td>", first, StringComparison.Ordinal);
        var next = System.Text.RegularExpressions.Regex.Match(WebUtility.HtmlDecode(first), "href=\"(/admin/accounts\\?issues=1&type=email&after=[^\"]+)\"").Groups[1].Value;
        Assert.NotEmpty(next);
        var (_, second, _) = await owner2.GetAsync(next);
        Assert.Equal(5, Rows(second));
        Assert.DoesNotContain("More accounts with issues", second, StringComparison.Ordinal);
        var (_, google, _) = await owner2.GetAsync("/admin/accounts?type=google&issues=1");
        Assert.Equal(ListAccounts.PageSize, Rows(google));
    }

    private static int Rows(string body) => System.Text.RegularExpressions.Regex.Count(body, "<a href=\"/admin/accounts/[0-9a-f-]{36}\">");

    [Fact]
    [Trait("Rule", "B23.P4-email-lookup")]
    public async Task An_email_sign_in_account_is_found_through_identitys_normalization_and_keyed_hash_and_shows_not_stored()
    {
        // The real path: start + verify through IdentityService, so the identity row is exactly what sign-in writes (keyed hash, no address).
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var address = "Email.Only." + Guid.NewGuid().ToString("N")[..8] + "@Example.invalid";
        var start = await h.Service.StartEmailAsync(address, "signIn", null, Guid.NewGuid().ToString(), Ct);
        var account = (await h.Service.VerifyEmailAsync(start.Id, h.Email.Code, h.Device, Ct))!;
        Assert.False(account.IsAnonymous);

        await using (var admin = await AdminApp.StartAsync(postgres, new Dictionary<string, string?> { ["Identity:PepperFile"] = h.Options.PepperFile }))
        {
            using var reader = admin.NewBrowser();
            await reader.SignInAsync("sub-reader", "reader@example.invalid");
            await reader.GetAsync("/admin/accounts");
            foreach (var exact in new[] { address, "  " + address.ToUpperInvariant() + " " })
            {
                var (status, _, response) = await reader.PostAsync("/admin/accounts/find", new Dictionary<string, string?> { ["email"] = exact });
                Assert.Equal(HttpStatusCode.Redirect, status);
                Assert.Equal("/admin/accounts/" + account.UserId, response.Headers.Location!.OriginalString);
            }
            var (missing, missingBody, _) = await reader.PostAsync("/admin/accounts/find", new Dictionary<string, string?> { ["email"] = "x" + address });
            Assert.Equal(HttpStatusCode.NotFound, missing);
            Assert.DoesNotContain("weren't searched", missingBody, StringComparison.Ordinal);

            var (_, detail, _) = await reader.GetAsync("/admin/accounts/" + account.UserId);
            Assert.Contains("not stored (email sign-in)", detail, StringComparison.Ordinal);
            Assert.Contains("<td>email</td>", detail, StringComparison.Ordinal);
            Assert.DoesNotContain(address, WebUtility.HtmlDecode(detail), StringComparison.OrdinalIgnoreCase);
        }

        // Without Identity's lookup key the console can't search email sign-in accounts, and says so (and audits it as partial).
        await using (var keyless = await AdminApp.StartAsync(postgres))
        {
            using var reader = keyless.NewBrowser();
            await reader.SignInAsync("sub-reader", "reader@example.invalid");
            await reader.GetAsync("/admin/accounts");
            var (status, body, _) = await reader.PostAsync("/admin/accounts/find", new Dictionary<string, string?> { ["email"] = address });
            Assert.Equal(HttpStatusCode.NotFound, status);
            Assert.Contains("Email sign-in accounts weren't searched", WebUtility.HtmlDecode(body), StringComparison.Ordinal);
        }
    }

    [Fact]
    public async Task Email_lookups_are_rate_limited()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await using var admin = await AdminApp.StartAsync(postgres, new Dictionary<string, string?>
        {
            ["ConnectionStrings:Admin"] = database.Admin,
            ["Admin:LookupPermitPerMinute"] = "2",
        });
        using var owner = await SignInAsync(admin);
        await owner.GetAsync("/admin/accounts");
        var statuses = new List<HttpStatusCode>();
        for (var i = 0; i < 3; i++) { statuses.Add((await owner.PostAsync("/admin/accounts/find", new Dictionary<string, string?> { ["email"] = "x@example.invalid" })).Status); }
        Assert.Equal([HttpStatusCode.NotFound, HttpStatusCode.NotFound, HttpStatusCode.TooManyRequests], statuses);
    }

    [Fact]
    [Trait("Rule", "B23.P4-alerts")]
    public void Overview_alerts_follow_their_thresholds()
    {
        var now = new DateTimeOffset(2026, 11, 7, 12, 0, 0, TimeSpan.Zero);
        var healthy = new OverviewFacts(true, true, now.AddHours(-25), true, now.AddMinutes(-1), 0, now.AddMinutes(-9), 0, false, true);
        Assert.Empty(OverviewAlerts.Evaluate(healthy, now));
        var codes = OverviewAlerts.Evaluate(new OverviewFacts(false, true, now.AddHours(-27), true, now.AddMinutes(-3), 2, now.AddMinutes(-11), 5, true, false), now)
            .Select(alert => alert.Code);
        Assert.Equal(["api-not-ready", "backup-old", "worker-silent", "dead-items", "queue-behind", "server-errors", "override-active", "no-catalog"], codes);
        Assert.Equal(["backup-failed", "worker-silent"], OverviewAlerts.Evaluate(healthy with { BackupOk = false, LastWorkerBeat = null }, now).Select(alert => alert.Code));
        // Not configured is not an alert.
        Assert.Empty(OverviewAlerts.Evaluate(healthy with { ApiReady = null, BackupConfigured = false, BackupCompletedAt = null }, now));
    }

    private async Task<AdminApp> StartAsync(ConfigDatabase database) =>
        await AdminApp.StartAsync(postgres, new Dictionary<string, string?> { ["ConnectionStrings:Admin"] = database.Admin });

    private static async Task<AdminApp.Browser> SignInAsync(AdminApp admin)
    {
        var browser = admin.NewBrowser();
        await browser.SignInAsync("sub-owner", "owner@example.invalid");
        await browser.GetAsync("/admin");
        return browser;
    }

    private static async Task<long> ScalarAsync(ConfigDatabase database, string sql)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.Migrator);
        await using var command = owner.CreateCommand(sql);
        return Convert.ToInt64(await command.ExecuteScalarAsync(Ct), System.Globalization.CultureInfo.InvariantCulture);
    }
}
