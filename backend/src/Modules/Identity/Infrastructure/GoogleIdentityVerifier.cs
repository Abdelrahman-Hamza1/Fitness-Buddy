using System.Text.Json;
using FitnessBuddy.Modules.Identity.Application;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

internal sealed class GoogleIdentityVerifier(HttpClient http, IOptions<IdentityOptions> options, TimeProvider clock) : IGoogleIdentityVerifier, IDisposable
{
    private readonly SemaphoreSlim gate = new(1);
    private JsonWebKeySet? keys;
    private DateTimeOffset refreshed = DateTimeOffset.MinValue;
    private readonly JsonWebTokenHandler handler = new() { MapInboundClaims = false, MaximumTokenSizeInBytes = 16384 };
    public async Task<GoogleIdentity?> VerifyAsync(string idToken, CancellationToken ct)
    {
        if (idToken.Length is < 1 or > 16384 || options.Value.GoogleClientIds.Length == 0 || !handler.CanReadToken(idToken)) { return null; }
        var jwt = handler.ReadJsonWebToken(idToken);
        if (jwt.Alg != SecurityAlgorithms.RsaSha256 || string.IsNullOrEmpty(jwt.Kid)) { return null; }
        await gate.WaitAsync(ct);
        JsonWebKeySet? current;
        try
        {
            var now = clock.GetUtcNow();
            // Unknown-key traffic cannot force a network call for every attacker-supplied kid.
            if (keys is null || now - refreshed > TimeSpan.FromMinutes(10) || (!keys.Keys.Any(key => key.Kid == jwt.Kid) && now - refreshed > TimeSpan.FromMinutes(1)))
            {
                refreshed = now;
                try
                {
                    using var response = await http.GetAsync("https://www.googleapis.com/oauth2/v3/certs", HttpCompletionOption.ResponseHeadersRead, ct);
                    response.EnsureSuccessStatusCode();
                    await using var stream = await response.Content.ReadAsStreamAsync(ct);
                    using var buffer = new MemoryStream();
                    var bytes = new byte[4096];
                    int read;
                    while ((read = await stream.ReadAsync(bytes, ct)) > 0)
                    {
                        if (buffer.Length + read > 65536) { return null; }
                        await buffer.WriteAsync(bytes.AsMemory(0, read), ct);
                    }
                    keys = new JsonWebKeySet(System.Text.Encoding.UTF8.GetString(buffer.ToArray()));
                }
                catch (HttpRequestException) { return null; }
                catch (JsonException) { return null; }
            }
            current = keys;
        }
        finally { gate.Release(); }
        var time = clock.GetUtcNow().UtcDateTime;
        var result = await handler.ValidateTokenAsync(idToken, new TokenValidationParameters
        {
            ValidIssuers = ["https://accounts.google.com", "accounts.google.com"],
            ValidAudiences = options.Value.GoogleClientIds,
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateIssuerSigningKey = true,
            TryAllIssuerSigningKeys = false,
            RequireSignedTokens = true,
            RequireExpirationTime = true,
            ValidateLifetime = true,
            IssuerSigningKeys = current?.Keys,
            ValidAlgorithms = [SecurityAlgorithms.RsaSha256],
            ClockSkew = TimeSpan.FromSeconds(30),
            LifetimeValidator = (nbf, exp, _, _) => exp.HasValue && exp.Value > time.AddSeconds(-30) && (!nbf.HasValue || (nbf.Value <= time.AddSeconds(30) && nbf.Value < exp.Value)),
        });
        if (!result.IsValid || !jwt.TryGetPayloadValue<long>("iat", out var iat) || iat > clock.GetUtcNow().AddSeconds(30).ToUnixTimeSeconds()
            || !jwt.TryGetPayloadValue<bool>("email_verified", out var verified) || !verified
            || !jwt.TryGetPayloadValue<string>("email", out var email) || email.Length > 254
            || string.IsNullOrEmpty(jwt.Subject) || jwt.Subject.Length > 255) { return null; }
        return new GoogleIdentity(jwt.Subject, email);
    }
    public void Dispose() => gate.Dispose();
}
