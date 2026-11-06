using System.Net;
using System.Security.Cryptography;
using System.Text.Json;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.Modules.Identity.Infrastructure;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-001")]
[Trait("Rule", "04.5-tokens")]
public sealed class GoogleIdentityTests
{
    [Theory]
    [InlineData("valid")]
    [InlineData("wrong-audience")]
    [InlineData("wrong-issuer")]
    [InlineData("expired")]
    [InlineData("unverified")]
    [InlineData("unknown-key")]
    [InlineData("future-iat")]
    [InlineData("future-nbf")]
    [InlineData("wrong-alg")]
    [InlineData("tampered")]
    public async Task Official_verifier_contract_is_proven_with_offline_signed_tokens(string scenario)
    {
        using var rsa = RSA.Create(2048);
        var p = rsa.ExportParameters(false);
        var key = new RsaSecurityKey(rsa) { KeyId = "offline-key", CryptoProviderFactory = new CryptoProviderFactory { CacheSignatureProviders = false } };
        var jwks = JsonSerializer.Serialize(new { keys = new[] { new { kty = "RSA", kid = key.KeyId, n = Base64UrlEncoder.Encode(p.Modulus!), e = Base64UrlEncoder.Encode(p.Exponent!), alg = "RS256", use = "sig" } } });
        using var transport = new StaticJwks(jwks);
        using var client = new HttpClient(transport);
        var clock = new TestClock(); var now = clock.GetUtcNow().UtcDateTime;
        using var verifier = new GoogleIdentityVerifier(client, Options.Create(new IdentityOptions { GoogleClientIds = ["synthetic-server-client"] }), clock);
        if (scenario == "unknown-key") { key.KeyId = "attacker-unknown"; }
        var descriptor = new SecurityTokenDescriptor
        {
            Issuer = scenario == "wrong-issuer" ? "https://attacker.invalid" : "https://accounts.google.com",
            Audience = scenario == "wrong-audience" ? "other-app" : "synthetic-server-client",
            IssuedAt = scenario == "future-iat" ? now.AddMinutes(5) : now.AddMinutes(-1),
            NotBefore = scenario == "future-nbf" ? now.AddMinutes(2) : now.AddHours(-2),
            Expires = scenario == "expired" ? now.AddMinutes(-1) : now.AddMinutes(5),
            Claims = new Dictionary<string, object>(StringComparer.Ordinal) { ["sub"] = "offline-subject", ["email"] = "synthetic@example.invalid", ["email_verified"] = scenario != "unverified" },
            SigningCredentials = new SigningCredentials(key, scenario == "wrong-alg" ? SecurityAlgorithms.RsaSha384 : SecurityAlgorithms.RsaSha256),
        };
        var token = new JsonWebTokenHandler().CreateToken(descriptor);
        if (scenario == "tampered") { var parts = token.Split('.'); parts[2] = new string('A', parts[2].Length); token = string.Join('.', parts); }
        var result = await verifier.VerifyAsync(token, TestContext.Current.CancellationToken);
        Assert.Equal(scenario == "valid", result is not null);
        Assert.Equal(scenario == "wrong-alg" ? 0 : 1, transport.Requests);
        if (scenario == "unknown-key")
        {
            Assert.Null(await verifier.VerifyAsync(token, TestContext.Current.CancellationToken));
            Assert.Equal(scenario == "wrong-alg" ? 0 : 1, transport.Requests);
        }
    }
    [Theory]
    [InlineData("admin-web-client", true)]
    [InlineData("synthetic-server-client", false)]
    [Trait("Req", "AD-003")]
    public async Task The_console_reuses_the_verifier_with_its_own_audience_and_reads_nonce_and_auth_time(string audience, bool accepted)
    {
        // B23 P2: one verification path; the caller supplies the audiences, so app tokens don't sign in to the console.
        using var rsa = RSA.Create(2048);
        var p = rsa.ExportParameters(false);
        var key = new RsaSecurityKey(rsa) { KeyId = "offline-key", CryptoProviderFactory = new CryptoProviderFactory { CacheSignatureProviders = false } };
        var jwks = JsonSerializer.Serialize(new { keys = new[] { new { kty = "RSA", kid = key.KeyId, n = Base64UrlEncoder.Encode(p.Modulus!), e = Base64UrlEncoder.Encode(p.Exponent!), alg = "RS256", use = "sig" } } });
        using var transport = new StaticJwks(jwks);
        using var client = new HttpClient(transport);
        var clock = new TestClock(); var now = clock.GetUtcNow().UtcDateTime;
        using var verifier = new GoogleIdentityVerifier(client, Options.Create(new IdentityOptions { GoogleClientIds = ["synthetic-server-client"] }), clock);
        var token = new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Issuer = "https://accounts.google.com",
            Audience = audience,
            IssuedAt = now.AddSeconds(-10),
            NotBefore = now.AddMinutes(-1),
            Expires = now.AddMinutes(5),
            Claims = new Dictionary<string, object>(StringComparer.Ordinal)
            {
                ["sub"] = "offline-subject",
                ["email"] = "synthetic@example.invalid",
                ["email_verified"] = true,
                ["nonce"] = "synthetic-nonce",
                ["auth_time"] = new DateTimeOffset(now.AddMinutes(-3)).ToUnixTimeSeconds(),
            },
            SigningCredentials = new SigningCredentials(key, SecurityAlgorithms.RsaSha256),
        });
        var result = await verifier.VerifyAsync(token, ["admin-web-client"], TestContext.Current.CancellationToken);
        Assert.Equal(accepted, result is not null);
        if (result is not null)
        {
            Assert.Equal("offline-subject", result.Subject);
            Assert.Equal("synthetic-nonce", result.Nonce);
            Assert.Equal(new DateTimeOffset(now.AddMinutes(-3)).ToUnixTimeSeconds(), result.AuthTime!.Value.ToUnixTimeSeconds());
            // The app sign-in path keeps its own audiences and refuses the console's token.
            Assert.Null(await verifier.VerifyAsync(token, TestContext.Current.CancellationToken));
        }
        Assert.Null(await verifier.VerifyAsync(token, [], TestContext.Current.CancellationToken));
    }

    private sealed class StaticJwks(string body) : HttpMessageHandler
    {
        public int Requests { get; private set; }
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Assert.Equal("https://www.googleapis.com/oauth2/v3/certs", request.RequestUri!.AbsoluteUri);
            Requests++;
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent(body) });
        }
    }
}
