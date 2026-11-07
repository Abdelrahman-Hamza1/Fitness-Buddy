using System.Net;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Admin.Api;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23 WP2 (T3–T6): Google sign-in against the allow-list, subject-bound sessions, capabilities, CSRF and recent sign-in.
[Trait("Req", "AD-003")]
[Trait("Req", "AD-004")]
[Trait("Req", "AD-005")]
public sealed class AdminAuthTests(PostgresFixture postgres)
{
    private const string Owner = "sub-owner";
    private const string OwnerEmail = "owner@example.invalid";

    [Fact]
    public async Task An_allow_listed_account_signs_in_with_a_strict_session_cookie_and_is_audited()
    {
        // A handle of its own: the audit log is shared with tests running in parallel that also sign in as "owner".
        var handle = "owner-" + Guid.NewGuid().ToString("N")[..8];
        await using var admin = await AdminApp.StartAsync(postgres, allowList: new
        {
            admins = new object[] { new { handle, googleSubject = Owner, email = OwnerEmail, role = "operator" } },
            pending = Array.Empty<object>(),
        });
        using var browser = admin.NewBrowser();
        var (status, _, response) = await browser.SignInAsync(Owner, " OWNER@example.invalid ");
        Assert.Equal(HttpStatusCode.Redirect, status);
        Assert.Equal("/admin", response.Headers.Location!.OriginalString);
        var cookie = response.Headers.GetValues("Set-Cookie").Single(header => header.StartsWith(AdminCookies.Session + "=", StringComparison.Ordinal));
        foreach (var attribute in new[] { "secure", "httponly", "samesite=strict", "path=/" }) { Assert.Contains(attribute, cookie, StringComparison.OrdinalIgnoreCase); }
        Assert.DoesNotContain("domain=", cookie, StringComparison.OrdinalIgnoreCase);
        var expires = DateTimeOffset.Parse(cookie.Split(';').Single(part => part.Trim().StartsWith("expires=", StringComparison.OrdinalIgnoreCase)).Split('=')[1], System.Globalization.CultureInfo.InvariantCulture);
        Assert.InRange(expires - admin.Clock.GetUtcNow(), TimeSpan.FromHours(11.9), TimeSpan.FromHours(12.1));
        var (home, body, _) = await browser.GetAsync("/admin");
        Assert.Equal(HttpStatusCode.OK, home);
        Assert.Contains("owner", body, StringComparison.Ordinal);
        Assert.DoesNotContain(OwnerEmail, body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain(Owner, body, StringComparison.Ordinal);
        Assert.Equal(1, await AuditCountAsync(handle, "sign-in", "ok"));
    }

    [Theory]
    [InlineData("wrong-subject", "not-allow-listed")]
    [InlineData("wrong-email", "not-allow-listed")]
    [InlineData("stranger", "not-allow-listed")]
    [InlineData("wrong-audience", "bad-token")]
    [InlineData("stale", "stale-token")]
    [InlineData("wrong-nonce", "challenge-invalid")]
    [InlineData("no-challenge", "challenge-invalid")]
    public async Task Refused_sign_ins_create_no_session_and_are_audited_with_a_reason(string scenario, string reason)
    {
        await using var admin = await AdminApp.StartAsync(postgres);
        using var browser = admin.NewBrowser();
        await browser.GetAsync("/admin/signin");
        var nonce = browser.Nonce!;
        if (scenario == "no-challenge") { browser.Forget(AdminCookies.Challenge); }
        var stranger = "stranger-" + Guid.NewGuid().ToString("N")[..8] + "@example.invalid";
        var credential = scenario switch
        {
            "wrong-subject" => AdminApp.Credential("sub-attacker", OwnerEmail, nonce),
            "wrong-email" => AdminApp.Credential(Owner, "other@example.invalid", nonce),
            "stranger" => AdminApp.Credential("sub-stranger", stranger, nonce),
            "wrong-audience" => AdminApp.Credential(Owner, OwnerEmail, nonce, audience: "app-client"),
            "stale" => AdminApp.Credential(Owner, OwnerEmail, nonce, iatOffset: -180),
            "wrong-nonce" => AdminApp.Credential(Owner, OwnerEmail, "another-nonce"),
            _ => AdminApp.Credential(Owner, OwnerEmail, nonce),
        };
        var before = await AuditCountAsync("unknown", "sign-in", reason);
        var (status, body, _) = await browser.PostAsync("/admin/signin", new Dictionary<string, string?> { ["credential"] = credential });
        Assert.Equal(HttpStatusCode.Forbidden, status);
        Assert.False(browser.Cookies.ContainsKey(AdminCookies.Session));
        Assert.Equal(before + 1, await AuditCountAsync("unknown", "sign-in", reason));
        Assert.Equal(HttpStatusCode.Redirect, (await browser.GetAsync("/admin")).Status);
        if (scenario == "stranger") { Assert.DoesNotContain(stranger, body, StringComparison.OrdinalIgnoreCase); }
    }

    [Fact]
    public async Task A_favicon_request_after_the_page_keeps_its_challenge()
    {
        // The browser asks for /favicon.ico after the sign-in page: no redirect, no new challenge, so the page's nonce still signs in.
        await using var admin = await AdminApp.StartAsync(postgres, allowList: new
        {
            admins = new object[] { new { handle = "owner-" + Guid.NewGuid().ToString("N")[..8], googleSubject = Owner, email = OwnerEmail, role = "operator" } },
            pending = Array.Empty<object>(),
        });
        using var browser = admin.NewBrowser();
        await browser.GetAsync("/admin/signin", new Dictionary<string, string> { ["Sec-Fetch-Dest"] = "document" });
        var nonce = browser.Nonce!;
        var challenge = browser.Cookies[AdminCookies.Challenge];
        var image = new Dictionary<string, string> { ["Sec-Fetch-Dest"] = "image" };
        Assert.Equal(HttpStatusCode.Unauthorized, (await browser.GetAsync("/favicon.ico", image)).Status);
        Assert.Equal(HttpStatusCode.NotFound, (await browser.GetAsync("/admin/signin", image)).Status);
        Assert.Equal(challenge, browser.Cookies[AdminCookies.Challenge]);
        var (status, _, _) = await browser.PostAsync("/admin/signin", new Dictionary<string, string?> { ["credential"] = AdminApp.Credential(Owner, OwnerEmail, nonce) });
        Assert.Equal(HttpStatusCode.Redirect, status);
        Assert.True(browser.Cookies.ContainsKey(AdminCookies.Session));
    }

    [Fact]
    public async Task A_challenge_works_once()
    {
        await using var admin = await AdminApp.StartAsync(postgres);
        using var browser = admin.NewBrowser();
        await browser.GetAsync("/admin/signin");
        var challenge = browser.Cookies[AdminCookies.Challenge];
        var credential = AdminApp.Credential(Owner, OwnerEmail, browser.Nonce!);
        Assert.Equal(HttpStatusCode.Redirect, (await browser.PostAsync("/admin/signin", new Dictionary<string, string?> { ["credential"] = credential })).Status);
        using var replay = admin.NewBrowser();
        await replay.GetAsync("/admin/signin");
        replay.SetCookie(AdminCookies.Challenge, challenge);
        var (status, _, _) = await replay.PostAsync("/admin/signin", new Dictionary<string, string?> { ["credential"] = credential });
        Assert.Equal(HttpStatusCode.Forbidden, status);
        Assert.False(replay.Cookies.ContainsKey(AdminCookies.Session));
    }

    [Fact]
    public async Task A_pending_email_sees_its_own_subject_to_pin_and_gets_no_session()
    {
        await using var admin = await AdminApp.StartAsync(postgres);
        using var browser = admin.NewBrowser();
        await browser.GetAsync("/admin/signin");
        var (status, body, _) = await browser.PostAsync("/admin/signin", new Dictionary<string, string?>
        {
            ["credential"] = AdminApp.Credential("sub-newbie-own", "newbie@example.invalid", browser.Nonce!),
        });
        Assert.Equal(HttpStatusCode.OK, status);
        Assert.Contains("sub-newbie-own", body, StringComparison.Ordinal);
        Assert.False(browser.Cookies.ContainsKey(AdminCookies.Session));
        Assert.Equal(HttpStatusCode.Redirect, (await browser.GetAsync("/admin")).Status);
        Assert.True(await AuditCountAsync("newbie", "sign-in", "enrolment-needed") >= 1);
    }

    [Theory]
    [InlineData("removed")]
    [InlineData("re-keyed")]
    [InlineData("handle-reused")]
    [InlineData("file-broken")]
    public async Task A_session_ends_when_its_allow_list_identity_changes(string change)
    {
        await using var admin = await AdminApp.StartAsync(postgres);
        using var browser = admin.NewBrowser();
        await browser.SignInAsync(Owner, OwnerEmail);
        Assert.Equal(HttpStatusCode.OK, (await browser.GetAsync("/admin")).Status);
        var token = browser.Cookies[AdminCookies.Session];
        object list = change switch
        {
            "removed" => new { admins = new[] { new { handle = "reader", googleSubject = "sub-reader", email = "reader@example.invalid", role = "viewer" } } },
            "re-keyed" => new { admins = new[] { new { handle = "owner", googleSubject = "sub-owner-new-phone", email = OwnerEmail, role = "operator" } } },
            "handle-reused" => new { admins = new[] { new { handle = "owner", googleSubject = "sub-someone-else", email = "else@example.invalid", role = "operator" } } },
            _ => "not an allow-list",
        };
        await admin.ReplaceAllowListAsync(list);
        Assert.Equal(HttpStatusCode.Redirect, (await browser.GetAsync("/admin")).Status);
        if (change == "file-broken")
        {
            // Fail closed without revoking: fixing the file restores the session.
            await admin.ReplaceAllowListAsync(AdminApp.DefaultAllowList);
            browser.SetCookie(AdminCookies.Session, token);
            Assert.Equal(HttpStatusCode.OK, (await browser.GetAsync("/admin")).Status);
            return;
        }
        // Revoked, not just refused: restoring the old entry doesn't revive it.
        await admin.ReplaceAllowListAsync(AdminApp.DefaultAllowList);
        browser.SetCookie(AdminCookies.Session, token);
        Assert.Equal(HttpStatusCode.Redirect, (await browser.GetAsync("/admin")).Status);
        Assert.True(await AuditCountAsync("owner", "session-revoked", "allow-list-changed") >= 1);
    }

    [Fact]
    public async Task A_role_change_takes_effect_on_the_next_request()
    {
        await using var admin = await AdminApp.StartAsync(postgres, map: MapProbes);
        using var browser = admin.NewBrowser();
        await browser.SignInAsync(Owner, OwnerEmail);
        await browser.GetAsync("/admin");
        Assert.Equal(HttpStatusCode.OK, (await browser.PostAsync("/admin/_probe/operate", new Dictionary<string, string?>())).Status);
        await admin.ReplaceAllowListAsync(new { admins = new[] { new { handle = "owner", googleSubject = Owner, email = OwnerEmail, role = "viewer" } } });
        Assert.Equal(HttpStatusCode.Forbidden, (await browser.PostAsync("/admin/_probe/operate", new Dictionary<string, string?>())).Status);
        Assert.Equal(HttpStatusCode.OK, (await browser.GetAsync("/admin")).Status);
    }

    [Fact]
    public async Task Without_a_valid_session_pages_redirect_htmx_gets_401_and_forged_or_expired_cookies_fail()
    {
        await using var admin = await AdminApp.StartAsync(postgres);
        using var anonymous = admin.NewBrowser();
        var (status, _, response) = await anonymous.GetAsync("/admin");
        Assert.Equal(HttpStatusCode.Redirect, status);
        Assert.Equal("/admin/signin", response.Headers.Location!.OriginalString);
        var (htmx, _, htmxResponse) = await anonymous.GetAsync("/admin", new Dictionary<string, string> { ["HX-Request"] = "true" });
        Assert.Equal(HttpStatusCode.Unauthorized, htmx);
        Assert.Equal("/admin/signin", htmxResponse.Headers.GetValues("HX-Redirect").Single());
        Assert.Equal(HttpStatusCode.Redirect, (await anonymous.GetAsync("/admin/no-such-page")).Status);

        anonymous.SetCookie(AdminCookies.Session, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
        Assert.Equal(HttpStatusCode.Redirect, (await anonymous.GetAsync("/admin")).Status);

        using var browser = admin.NewBrowser();
        await browser.SignInAsync(Owner, OwnerEmail);
        Assert.Equal(HttpStatusCode.OK, (await browser.GetAsync("/admin")).Status);
        admin.Clock.Advance(TimeSpan.FromHours(12) + TimeSpan.FromSeconds(1));
        Assert.Equal(HttpStatusCode.Redirect, (await browser.GetAsync("/admin")).Status);
    }

    [Fact]
    public async Task Sign_out_revokes_the_session()
    {
        await using var admin = await AdminApp.StartAsync(postgres);
        using var browser = admin.NewBrowser();
        await browser.SignInAsync("sub-reader", "reader@example.invalid");
        await browser.GetAsync("/admin");
        var token = browser.Cookies[AdminCookies.Session];
        Assert.Equal(HttpStatusCode.Redirect, (await browser.PostAsync("/admin/signout", new Dictionary<string, string?>())).Status);
        browser.SetCookie(AdminCookies.Session, token);
        Assert.Equal(HttpStatusCode.Redirect, (await browser.GetAsync("/admin")).Status);
        Assert.True(await AuditCountAsync("reader", "sign-out", "ok") >= 1);
    }

    [Fact]
    [Trait("Rule", "B23.P2-capabilities")]
    public async Task Every_endpoint_declares_one_capability_and_operate_endpoints_refuse_a_viewer()
    {
        await using var admin = await AdminApp.StartAsync(postgres, map: MapProbes);
        var endpoints = admin.Services.GetRequiredService<EndpointDataSource>().Endpoints.OfType<RouteEndpoint>().ToArray();
        Assert.NotEmpty(endpoints);
        var anonymous = new List<string>();
        var operate = new List<(string Method, string Path)>();
        foreach (var endpoint in endpoints)
        {
            var capabilities = endpoint.Metadata.GetOrderedMetadata<AdminCapabilityMetadata>();
            Assert.True(capabilities.Count == 1, endpoint.RoutePattern.RawText);
            var methods = endpoint.Metadata.GetMetadata<HttpMethodMetadata>()?.HttpMethods ?? ["*"];
            foreach (var method in methods)
            {
                if (capabilities[0].Capability == AdminCapability.Anonymous) { anonymous.Add(method + " " + endpoint.RoutePattern.RawText); }
                // Route parameters get a real value, or the request would not match the endpoint at all.
                if (capabilities[0].Capability == AdminCapability.Operate)
                {
                    operate.Add((method, endpoint.RoutePattern.RawText!.Replace("{version:int}", "1", StringComparison.Ordinal)
                    .Replace("{id:guid}", Guid.NewGuid().ToString(), StringComparison.Ordinal).Replace("{key}", new string('0', 32), StringComparison.Ordinal)));
                }
            }
        }
        Assert.Equal(["* /health/live", "* /health/ready", "GET /admin/assets/{name}", "GET /admin/signin", "POST /admin/signin"], anonymous.Order(StringComparer.Ordinal));

        using var viewer = admin.NewBrowser();
        await viewer.SignInAsync("sub-reader", "reader@example.invalid");
        await viewer.GetAsync("/admin");
        Assert.NotEmpty(operate);
        foreach (var (method, path) in operate)
        {
            var (status, _, _) = method == "GET" ? await viewer.GetAsync(path) : await viewer.PostAsync(path, new Dictionary<string, string?>());
            Assert.True(status == HttpStatusCode.Forbidden, method + " " + path);
        }
        // Session capabilities stay open to a viewer.
        Assert.Equal(HttpStatusCode.OK, (await viewer.PostAsync("/admin/_probe/session", new Dictionary<string, string?>())).Status);
    }

    [Theory]
    [InlineData("no-token")]
    [InlineData("cross-site")]
    [InlineData("other-origin")]
    [Trait("Rule", "B23.P2-csrf")]
    public async Task Unsafe_requests_need_the_antiforgery_token_and_the_same_origin(string attack)
    {
        await using var admin = await AdminApp.StartAsync(postgres, map: MapProbes);
        using var browser = admin.NewBrowser();
        await browser.SignInAsync(Owner, OwnerEmail);
        await browser.GetAsync("/admin");
        var headers = attack switch
        {
            "cross-site" => new Dictionary<string, string> { ["Sec-Fetch-Site"] = "cross-site" },
            "other-origin" => new Dictionary<string, string> { ["Origin"] = "https://attacker.invalid" },
            _ => new Dictionary<string, string>(),
        };
        var (status, _, _) = await browser.PostAsync("/admin/_probe/operate", new Dictionary<string, string?>(), headers, includeCsrf: attack != "no-token");
        Assert.Equal(attack == "no-token" ? HttpStatusCode.BadRequest : HttpStatusCode.Forbidden, status);
        var (allowed, _, _) = await browser.PostAsync("/admin/_probe/operate", new Dictionary<string, string?>(),
            new Dictionary<string, string> { ["Sec-Fetch-Site"] = "same-origin", ["Origin"] = "http://localhost" });
        Assert.Equal(HttpStatusCode.OK, allowed);
    }

    [Fact]
    [Trait("Req", "AD-007")]
    public async Task A_stale_sign_in_must_re_authenticate_with_a_fresh_session_bound_challenge()
    {
        await using var admin = await AdminApp.StartAsync(postgres, map: MapProbes);
        using var browser = admin.NewBrowser();
        await browser.SignInAsync(Owner, OwnerEmail);
        await browser.GetAsync("/admin");
        Assert.Equal(HttpStatusCode.OK, (await browser.PostAsync("/admin/_probe/recent", new Dictionary<string, string?>())).Status);
        admin.Clock.Advance(TimeSpan.FromMinutes(16));
        var (stale, staleBody, _) = await browser.PostAsync("/admin/_probe/recent", new Dictionary<string, string?>());
        Assert.Equal(HttpStatusCode.Forbidden, stale);
        Assert.Contains("/admin/reauth", staleBody, StringComparison.Ordinal);

        // Another account's token, an old auth_time and a wrong nonce are refused.
        foreach (var credential in new Func<string, string>[]
        {
            nonce => AdminApp.Credential("sub-reader", "reader@example.invalid", nonce),
            nonce => AdminApp.Credential(Owner, OwnerEmail, nonce, authTimeOffset: -20 * 60),
            _ => AdminApp.Credential(Owner, OwnerEmail, "not-this-challenge"),
        })
        {
            await browser.GetAsync("/admin/reauth?return=/admin");
            var (refused, _, _) = await browser.PostAsync("/admin/reauth", new Dictionary<string, string?> { ["credential"] = credential(browser.Nonce!), ["return"] = "/admin" });
            Assert.Equal(HttpStatusCode.Forbidden, refused);
        }
        Assert.Equal(HttpStatusCode.Forbidden, (await browser.PostAsync("/admin/_probe/recent", new Dictionary<string, string?>())).Status);

        // A re-auth challenge issued to another session can't be used here.
        using var other = admin.NewBrowser();
        await other.SignInAsync(Owner, OwnerEmail);
        await other.GetAsync("/admin/reauth?return=/admin");
        var foreignChallenge = other.Cookies[AdminCookies.Challenge];
        var foreignNonce = other.Nonce!;
        await browser.GetAsync("/admin/reauth?return=/admin");
        browser.SetCookie(AdminCookies.Challenge, foreignChallenge);
        Assert.Equal(HttpStatusCode.Forbidden, (await browser.PostAsync("/admin/reauth", new Dictionary<string, string?>
        {
            ["credential"] = AdminApp.Credential(Owner, OwnerEmail, foreignNonce),
            ["return"] = "/admin",
        })).Status);

        // A fresh challenge for this session works once, then the action is allowed.
        await browser.GetAsync("/admin/reauth?return=/admin/_probe");
        var challenge = browser.Cookies[AdminCookies.Challenge];
        var good = AdminApp.Credential(Owner, OwnerEmail, browser.Nonce!, authTimeOffset: -60);
        var (ok, _, okResponse) = await browser.PostAsync("/admin/reauth", new Dictionary<string, string?> { ["credential"] = good, ["return"] = "https://attacker.invalid/x" });
        Assert.Equal(HttpStatusCode.Redirect, ok);
        Assert.Equal("/admin", okResponse.Headers.Location!.OriginalString);
        Assert.Equal(HttpStatusCode.OK, (await browser.PostAsync("/admin/_probe/recent", new Dictionary<string, string?>())).Status);
        browser.SetCookie(AdminCookies.Challenge, challenge);
        Assert.Equal(HttpStatusCode.Forbidden, (await browser.PostAsync("/admin/reauth", new Dictionary<string, string?> { ["credential"] = good, ["return"] = "/admin" })).Status);
    }

    [Fact]
    [Trait("Req", "AD-007")]
    public async Task A_stale_sign_in_through_htmx_navigates_the_whole_page_to_re_auth()
    {
        await using var admin = await AdminApp.StartAsync(postgres, map: MapProbes);
        using var browser = admin.NewBrowser();
        await browser.SignInAsync(Owner, OwnerEmail);
        await browser.GetAsync("/admin");
        admin.Clock.Advance(TimeSpan.FromMinutes(16));
        var htmx = new Dictionary<string, string> { ["HX-Request"] = "true", ["Referer"] = "http://localhost/admin/config" };
        var (status, body, response) = await browser.PostAsync("/admin/_probe/recent", new Dictionary<string, string?>(), htmx);
        Assert.Equal(HttpStatusCode.NoContent, status);
        Assert.Empty(body);
        Assert.Equal("/admin/reauth?return=%2Fadmin%2Fconfig", Assert.Single(response.Headers.GetValues("HX-Redirect")));
        // The sign-in page reached inside htmx also asks for a full page load (htmx follows a 302 but honours HX-Redirect).
        using var anonymous = admin.NewBrowser();
        var (signIn, _, signInResponse) = await anonymous.GetAsync("/admin/signin", htmx);
        Assert.Equal(HttpStatusCode.NoContent, signIn);
        Assert.Equal("/admin/signin", Assert.Single(signInResponse.Headers.GetValues("HX-Redirect")));
    }

    [Fact]
    [Trait("Rule", "B23.P2-signin-total-limit")]
    public async Task Sign_in_attempts_have_a_process_wide_limit_no_address_can_multiply()
    {
        await using var admin = await AdminApp.StartAsync(postgres, new Dictionary<string, string?> { ["Admin:SignInPermitPerMinuteTotal"] = "3" });
        using var browser = admin.NewBrowser();
        for (var i = 1; i <= 3; i++)
        {
            var forwarded = new Dictionary<string, string> { ["X-Forwarded-For"] = "100.64.0." + i.ToString(System.Globalization.CultureInfo.InvariantCulture) };
            Assert.Equal(HttpStatusCode.OK, (await browser.GetAsync("/admin/signin", forwarded)).Status);
        }
        Assert.Equal(HttpStatusCode.TooManyRequests, (await browser.GetAsync("/admin/signin", new Dictionary<string, string> { ["X-Forwarded-For"] = "100.64.0.9" })).Status);
        Assert.Equal(HttpStatusCode.TooManyRequests, (await browser.PostAsync("/admin/signin", new Dictionary<string, string?> { ["credential"] = "x" })).Status);
        // Other routes are not limited by it.
        Assert.Equal(HttpStatusCode.OK, (await browser.GetAsync("/health/ready")).Status);
    }

    [Fact]
    [Trait("Rule", "B23.P2-headers")]
    public async Task Pages_carry_a_strict_csp_and_only_sign_in_pages_allow_googles_script()
    {
        await using var admin = await AdminApp.StartAsync(postgres);
        using var browser = admin.NewBrowser();
        var (_, _, signIn) = await browser.GetAsync("/admin/signin");
        var signInCsp = signIn.Headers.GetValues("Content-Security-Policy").Single();
        Assert.Contains("https://accounts.google.com/gsi/client", signInCsp, StringComparison.Ordinal);
        Assert.Contains("frame-ancestors 'none'", signInCsp, StringComparison.Ordinal);
        Assert.True(signIn.Headers.CacheControl!.NoStore);
        await browser.PostAsync("/admin/signin", new Dictionary<string, string?> { ["credential"] = AdminApp.Credential(Owner, OwnerEmail, browser.Nonce!) });
        var (_, _, home) = await browser.GetAsync("/admin");
        var csp = home.Headers.GetValues("Content-Security-Policy").Single();
        Assert.DoesNotContain("google", csp, StringComparison.Ordinal);
        Assert.Contains("script-src 'self';", csp, StringComparison.Ordinal);
        Assert.Equal("nosniff", home.Headers.GetValues("X-Content-Type-Options").Single());
        Assert.Equal("DENY", home.Headers.GetValues("X-Frame-Options").Single());
    }

    private static void MapProbes(WebApplication app)
    {
        var group = app.MapGroup("/admin/_probe");
        group.MapPost("/operate", () => "ok").WithCapability(AdminCapability.Operate);
        group.MapPost("/session", () => "ok").WithCapability(AdminCapability.Session);
        group.MapPost("/recent", () => "ok").WithCapability(AdminCapability.Session).RequireRecentSignIn();
    }

    private async Task<long> AuditCountAsync(string actor, string action, string outcome)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand("SELECT count(*) FROM admin.audit_log WHERE actor=$1 AND action=$2 AND outcome=$3");
        command.Parameters.AddWithValue(actor);
        command.Parameters.AddWithValue(action);
        command.Parameters.AddWithValue(outcome);
        return (long)(await command.ExecuteScalarAsync(TestContext.Current.CancellationToken))!;
    }
}
