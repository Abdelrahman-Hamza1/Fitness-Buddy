using System.Net;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Account.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B24 WP4: the account controls end to end: console POST → module change + one audit row in the same transaction → the app's
// next request gets 401 /errors/unauthorized; AD-007 typed id and the exact 15-minute boundary; reason codes only; the audit
// rows of a deleted account keep its id and no email; the deletion runner lives only in the api role.
[Trait("Req", "AD-011")]
[Trait("Req", "AD-007")]
[Trait("Req", "AD-005")]
public sealed class AccountControlsConsoleTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private const string Reason = "support";

    private static async Task<AdminApp.Browser> OwnerAsync(AdminApp admin)
    {
        var browser = admin.NewBrowser();
        await browser.SignInAsync("sub-owner", "owner@example.invalid");
        await browser.GetAsync("/admin");
        return browser;
    }

    // B23b's account page, which includes the controls.
    private static string Panel(Guid account) => "/admin/accounts/" + account;

    private static Dictionary<string, string?> Form(Guid? confirm = null, string? reason = Reason, string? dailyCalls = null) => new()
    {
        ["reason"] = reason,
        ["confirmAccountId"] = confirm?.ToString(),
        ["dailyCalls"] = dailyCalls,
    };

    private static async Task<HttpStatusCode> MeAsync(HttpClient api, string bearer)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, "/v1/me");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", bearer);
        using var response = await api.SendAsync(request, Ct);
        if (response.StatusCode == HttpStatusCode.Unauthorized)
        {
            Assert.Contains("/errors/unauthorized", await response.Content.ReadAsStringAsync(Ct), StringComparison.Ordinal);
        }
        return response.StatusCode;
    }

    [Fact]
    public async Task Each_control_changes_the_account_writes_one_audit_row_and_the_app_sees_401()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        using var wire = new BuddyApiTests.BuddyWire();
        await using var apiFactory = new BuddyApiTests.BuddyApi(postgres, h, wire); using var api = apiFactory.CreateClient(); BuddyApiTests.Headers(api, h);
        var subject = "valid-" + Guid.NewGuid();
        var deviceA = Guid.NewGuid(); var deviceB = Guid.NewGuid();
        var a = (await h.Service.GoogleAsync(subject, deviceA, Ct))!;
        var b = (await h.Service.GoogleAsync(subject, deviceB, Ct))!;
        var account = a.UserId;
        Assert.Equal(HttpStatusCode.OK, await MeAsync(api, a.AccessToken));

        await using var admin = await AdminApp.StartAsync(postgres);
        using var owner = await OwnerAsync(admin);
        var (status, page, _) = await owner.GetAsync(Panel(account));
        Assert.Equal(HttpStatusCode.OK, status);
        var keyA = Convert.ToHexStringLower(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(account + ":" + deviceA)))[..32];
        Assert.Contains(keyA, page, StringComparison.Ordinal);
        Assert.DoesNotContain(deviceA.ToString(), page, StringComparison.OrdinalIgnoreCase);

        // Revoke one device: only A is refused, and A's refresh too.
        Assert.Equal(HttpStatusCode.Redirect, (await owner.PostAsync("/admin/accounts/" + account + "/devices/" + keyA + "/revoke", Form())).Status);
        Assert.Equal(HttpStatusCode.Unauthorized, await MeAsync(api, a.AccessToken));
        Assert.Null(await h.Service.RefreshAsync(a.RefreshToken, Ct));
        Assert.Equal(HttpStatusCode.OK, await MeAsync(api, b.AccessToken));

        // Revoke all: refused without the typed id, then done.
        await owner.PostAsync("/admin/accounts/" + account + "/revoke-all", Form(Guid.NewGuid()));
        Assert.Equal(HttpStatusCode.OK, await MeAsync(api, b.AccessToken));
        await owner.PostAsync("/admin/accounts/" + account + "/revoke-all", Form(account));
        Assert.Equal(HttpStatusCode.Unauthorized, await MeAsync(api, b.AccessToken));

        // Buddy limit, disable (sign-in refused), enable (sign-in works again).
        await owner.PostAsync("/admin/accounts/" + account + "/buddy-limit", Form(dailyCalls: "0"));
        await owner.PostAsync("/admin/accounts/" + account + "/buddy-limit", Form(dailyCalls: "1001"));
        await owner.PostAsync("/admin/accounts/" + account + "/disable", Form(account));
        Assert.Null(await h.Service.GoogleAsync(subject, deviceA, Ct));
        await owner.PostAsync("/admin/accounts/" + account + "/enable", Form());
        var again = (await h.Service.GoogleAsync(subject, deviceA, Ct))!;
        Assert.Equal(HttpStatusCode.OK, await MeAsync(api, again.AccessToken));

        // An unknown reason code changes nothing (R#7: no free text).
        await owner.PostAsync("/admin/accounts/" + account + "/disable", Form(account, reason: "my friend asked by email x@example.invalid"));
        Assert.Equal(HttpStatusCode.OK, await MeAsync(api, again.AccessToken));

        // Delete: disabled at once, then the api role's runner erases it.
        await owner.PostAsync("/admin/accounts/" + account + "/delete", Form(account));
        Assert.Equal(HttpStatusCode.Unauthorized, await MeAsync(api, again.AccessToken));
        // The console stamped the intent with its own (real-time) test clock; the runner runs on the harness clock.
        var gap = admin.Clock.GetUtcNow() - h.Clock.GetUtcNow();
        if (gap > TimeSpan.Zero) { h.Clock.Advance(gap + TimeSpan.FromSeconds(1)); }
        await using (var provider = OperatorDeletionHarness.Services(postgres, h))
        { Assert.Equal(1, await OperatorDeletionHarness.Runner(postgres, h, provider, [account]).RunOnceAsync(Ct)); }
        await OwnerRows.AssertNoneAsync(postgres, account, Guid.Parse(new Microsoft.IdentityModel.JsonWebTokens.JsonWebToken(a.AccessToken).GetClaim("sid").Value));

        // One ok row per action, refusals with their codes; P5: the deleted account's rows keep its id and hold no email.
        var rows = await AuditAsync(account);
        foreach (var action in new[] { "revoke-device", "revoke-all", "buddy-limit", "disable", "enable", "delete" })
        { Assert.Single(rows, row => row.Action == action && row.Outcome == "ok"); }
        Assert.Contains(rows, row => row.Action == "revoke-all" && row.Outcome == "typed-id-mismatch");
        Assert.Contains(rows, row => row.Action == "buddy-limit" && row.Outcome == "invalid-limit");
        Assert.Contains(rows, row => row.Action == "disable" && row.Outcome == "invalid-reason" && row.Reason is null);
        Assert.All(rows, row => Assert.DoesNotContain('@', row.Text));
        Assert.Contains(rows, row => row.Action == "buddy-limit" && row.Text.Contains("\"dailyCalls\": 0", StringComparison.Ordinal));
        var (gone, missing, _) = await owner.GetAsync(Panel(account));
        Assert.Equal(HttpStatusCode.NotFound, gone);
        Assert.Contains("No account with that id.", missing, StringComparison.Ordinal);
    }

    [Fact]
    [Trait("Rule", "B24.R8-recent-sign-in-boundary")]
    public async Task Destructive_controls_need_a_sign_in_under_15_minutes_exactly()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var first = await h.GuestAsync(); var second = await h.GuestAsync();
        await using var admin = await AdminApp.StartAsync(postgres);
        using var owner = await OwnerAsync(admin);

        admin.Clock.Advance(TimeSpan.FromMinutes(15) - TimeSpan.FromSeconds(1));
        Assert.Equal(HttpStatusCode.Redirect, (await owner.PostAsync("/admin/accounts/" + first.UserId + "/disable", Form(first.UserId))).Status);
        Assert.Null(await h.Store.ReadSessionAsync(first.UserId, first.SessionId, Ct));

        admin.Clock.Advance(TimeSpan.FromSeconds(1));
        var actions = new[] { "revoke-all", "disable", "delete" };
        foreach (var action in actions)
        {
            // Even with a wrong typed id: the stale sign-in is the refusal, and it goes to re-auth then back to the panel.
            foreach (var typed in new[] { second.UserId, Guid.NewGuid() })
            {
                var (status, _, response) = await owner.PostAsync("/admin/accounts/" + second.UserId + "/" + action, Form(typed));
                Assert.Equal(HttpStatusCode.Redirect, status);
                Assert.Equal("/admin/reauth?return=" + Uri.EscapeDataString(Panel(second.UserId)), response.Headers.Location?.OriginalString);
            }
        }
        Assert.NotNull(await h.Store.ReadSessionAsync(second.UserId, second.SessionId, Ct));
        var stale = await AuditAsync(second.UserId);
        Assert.DoesNotContain(stale, row => row.Outcome == "ok");
        // Every stale attempt is audited with its code (review minor 3).
        foreach (var action in actions)
        { Assert.Equal(2, stale.Count(row => row.Action == action && row.Outcome == "needs-recent-sign-in" && row.Reason == Reason)); }
        // Non-destructive controls don't need it.
        Assert.Equal(HttpStatusCode.Redirect, (await owner.PostAsync("/admin/accounts/" + second.UserId + "/buddy-limit", Form(dailyCalls: "7"))).Status);
        Assert.Contains(await AuditAsync(second.UserId), row => row.Action == "buddy-limit" && row.Outcome == "ok");
    }

    [Fact]
    [Trait("Rule", "B24.P4-runner-api-only")]
    public async Task The_deletion_runner_runs_only_in_the_api_role_and_destructive_routes_check_the_sign_in_in_the_handler()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var admin = await AdminApp.StartAsync(postgres);
        Assert.DoesNotContain(admin.Services.GetServices<IHostedService>(), service => service is OperatorDeletionRunner);
        using var wire = new BuddyApiTests.BuddyWire();
        await using var api = new BuddyApiTests.BuddyApi(postgres, h, wire);
        Assert.Contains(api.Services.GetServices<IHostedService>(), service => service is OperatorDeletionRunner);

        var endpoints = admin.Services.GetRequiredService<Microsoft.AspNetCore.Routing.EndpointDataSource>().Endpoints
            .OfType<Microsoft.AspNetCore.Routing.RouteEndpoint>().Where(endpoint => endpoint.RoutePattern.RawText!.StartsWith("/admin/accounts/", StringComparison.Ordinal)).ToArray();
        foreach (var path in new[] { "/revoke-all", "/disable", "/delete" })
        {
            var endpoint = Assert.Single(endpoints, endpoint => endpoint.RoutePattern.RawText!.EndsWith(path, StringComparison.Ordinal));
            // No endpoint filter: it would refuse before the handler's audited needs-recent-sign-in path.
            Assert.Null(endpoint.Metadata.GetMetadata<FitnessBuddy.Modules.Admin.Api.RecentSignInMetadata>());
        }
    }

    private sealed record AuditRow(string Action, string Outcome, string? Reason, string Text);

    private async Task<List<AuditRow>> AuditAsync(Guid account)
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var command = owner.CreateCommand("SELECT action,outcome,reason,concat_ws(' ',target,before::text,after::text,reason) FROM admin.audit_log WHERE area='accounts' AND target=$1 ORDER BY id");
        command.Parameters.AddWithValue("account " + account);
        await using var reader = await command.ExecuteReaderAsync(Ct);
        var rows = new List<AuditRow>();
        while (await reader.ReadAsync(Ct)) { rows.Add(new AuditRow(reader.GetString(0), reader.GetString(1), reader.IsDBNull(2) ? null : reader.GetString(2), reader.GetString(3))); }
        return rows;
    }
}
