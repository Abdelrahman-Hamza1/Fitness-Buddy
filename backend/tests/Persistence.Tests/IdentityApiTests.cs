using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.Identity.Application;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-001")]
[Trait("Req", "AC-002")]
[Trait("Rule", "04.6-authz")]
public sealed class IdentityApiTests(PostgresFixture postgres)
{
    [Fact]
    public async Task Real_host_challenges_guest_policy_logout_and_token_cache_headers()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var factory = new IdentityApi(postgres, h);
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android"); client.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
        using var absent = await client.GetAsync("/v1/me", TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.Unauthorized, absent.StatusCode);
        Assert.Equal("application/problem+json", absent.Content.Headers.ContentType!.MediaType);
        using var created = await client.PostAsync("/v1/auth/anonymous", null, TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.OK, created.StatusCode);
        Assert.True(created.Headers.CacheControl!.NoStore);
        var first = (await created.Content.ReadFromJsonAsync<IssuedTokens>(TestContext.Current.CancellationToken))!;
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", first.AccessToken);
        using var me = await client.GetAsync("/v1/me", TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.OK, me.StatusCode);
        var account = await me.Content.ReadFromJsonAsync<JsonElement>(TestContext.Current.CancellationToken);
        Assert.Equal(first.UserId, account.GetProperty("userId").GetGuid());
        using var forbidden = await client.GetAsync("/v1/_identity-registered", TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.Forbidden, forbidden.StatusCode);
        Assert.Equal("application/problem+json", forbidden.Content.Headers.ContentType!.MediaType);
        using var jwks = await client.GetAsync("/.well-known/jwks.json", TestContext.Current.CancellationToken);
        var publicKeys = await jwks.Content.ReadFromJsonAsync<JsonElement>(TestContext.Current.CancellationToken);
        Assert.NotEmpty(publicKeys.GetProperty("keys").EnumerateArray());
        Assert.DoesNotContain("\"d\"", publicKeys.GetRawText(), StringComparison.Ordinal);
        using var logout = await client.PostAsync("/v1/auth/logout", null, TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.NoContent, logout.StatusCode);
        using var revoked = await client.GetAsync("/v1/me", TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.Unauthorized, revoked.StatusCode);
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", "private-token-canary");
        using var malformed = await client.GetAsync("/v1/me", TestContext.Current.CancellationToken);
        Assert.Equal(HttpStatusCode.Unauthorized, malformed.StatusCode);
        Assert.DoesNotContain("private-token-canary", await malformed.Content.ReadAsStringAsync(TestContext.Current.CancellationToken), StringComparison.Ordinal);
    }
    [Fact]
    [Trait("Req", "AC-003")]
    public async Task Guest_email_link_start_requires_the_guest_bearer_and_sends_a_code()
    {
        var ct = TestContext.Current.CancellationToken;
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await using var factory = new IdentityApi(postgres, h);
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-App-Version", "0.1.0"); client.DefaultRequestHeaders.Add("X-Platform", "android"); client.DefaultRequestHeaders.Add("X-Device-Id", h.Device.ToString());
        var email = new { email = Guid.NewGuid() + "@example.invalid" };
        using var anonymous = await client.PostAsJsonAsync("/v1/auth/link/email/start", email, ct);
        Assert.Equal(HttpStatusCode.Unauthorized, anonymous.StatusCode);
        Assert.Equal(0, h.Email.Count);
        using var created = await client.PostAsync("/v1/auth/anonymous", null, ct);
        var guest = (await created.Content.ReadFromJsonAsync<IssuedTokens>(ct))!;
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", guest.AccessToken);
        using var started = await client.PostAsJsonAsync("/v1/auth/link/email/start", email, ct);
        Assert.Equal(HttpStatusCode.OK, started.StatusCode);
        Assert.True(started.Headers.CacheControl!.NoStore);
        Assert.Equal(1, h.Email.Count);
        var challenge = await started.Content.ReadFromJsonAsync<JsonElement>(ct);
        using var linked = await client.PostAsJsonAsync("/v1/auth/link/email", new { idToken = (string?)null, challengeId = challenge.GetProperty("challengeId").GetGuid(), code = h.Email.Code }, ct);
        Assert.Equal(HttpStatusCode.OK, linked.StatusCode);
        var registered = (await linked.Content.ReadFromJsonAsync<IssuedTokens>(ct))!;
        Assert.Equal(guest.UserId, registered.UserId);
        Assert.False(registered.IsAnonymous);
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", registered.AccessToken);
        using var refused = await client.PostAsJsonAsync("/v1/auth/link/email/start", email, ct);
        Assert.Equal(HttpStatusCode.Forbidden, refused.StatusCode);
        Assert.Equal(1, h.Email.Count);
    }
    internal sealed class IdentityApi(PostgresFixture p, IdentityHarness h) : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");
            builder.ConfigureAppConfiguration((_, configuration) => configuration.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:Application"] = p.AppConnection,
                ["Recovery:Directory"] = p.RecoveryDirectory,
                ["Identity:Enabled"] = "true",
                ["Identity:WrappingKeysDirectory"] = h.DirectoryPath,
                ["Identity:PepperFile"] = h.Options.PepperFile,
            }));
            builder.ConfigureTestServices(services =>
            {
                services.AddSingleton<TimeProvider>(h.Clock);
                services.AddSingleton<IGoogleIdentityVerifier, IdentityHarness.FakeGoogle>();
                services.AddSingleton<IEmailSender>(h.Email);
                services.AddSingleton<IModule, RegisteredProbe>();
            });
        }
    }
    private sealed class RegisteredProbe : IModule
    {
        public string Name => "IdentityProbe";
        public FitnessBuddy.BuildingBlocks.Messaging.UserDataOwnership UserData => new([], [], null);
        public void AddServices(IServiceCollection services, IConfiguration configuration) { }
        public void MapEndpoints(RouteGroupBuilder group) => group.MapGet("/_identity-registered", () => TypedResults.Ok()).RequireAuthorization("registered-user").ExcludeFromDescription();
    }
}
