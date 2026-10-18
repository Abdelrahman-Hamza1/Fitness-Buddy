using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using Npgsql;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

internal sealed class IdentityTokens(NpgsqlDataSource source, IOptions<IdentityOptions> options, TimeProvider clock) : IIdentityTokens
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private readonly JsonWebTokenHandler handler = new() { MapInboundClaims = false, MaximumTokenSizeInBytes = 16384 };
    public byte[] Hash(string value) => SHA256.HashData(Encoding.UTF8.GetBytes(value));
    public byte[] ProtectLookup(string domain, string value)
    {
        var pepper = IdentitySecrets.ReadKey(options.Value.PepperFile);
        try { return HMACSHA256.HashData(pepper, Encoding.UTF8.GetBytes(domain + "\0" + value)); }
        finally { CryptographicOperations.ZeroMemory(pepper); }
    }
    public async Task<string> SignAsync(IdentitySession session, CancellationToken ct)
    {
        var keys = await ReadAsync(ct);
        var active = keys.Single(key => key.Active && key.ValidateUntil > clock.GetUtcNow().AddMinutes(16));
        var wrapping = IdentitySecrets.ReadKey(Path.Combine(options.Value.WrappingKeysDirectory, active.Version + ".key"));
        var plaintext = new byte[active.Ciphertext.Length];
        try
        {
            using var aes = new AesGcm(wrapping, 16);
            aes.Decrypt(active.Nonce, active.Ciphertext, active.Tag, plaintext, Encoding.UTF8.GetBytes(active.Kid + ":ES256:PKCS8:v1"));
            using var ec = ECDsa.Create();
            ec.ImportPkcs8PrivateKey(plaintext, out var read);
            if (read != plaintext.Length || ec.KeySize != 256) { throw new CryptographicException("Invalid signing material."); }
            var now = clock.GetUtcNow();
            return handler.CreateToken(new SecurityTokenDescriptor
            {
                Issuer = options.Value.Issuer,
                Audience = options.Value.Audience,
                IssuedAt = now.UtcDateTime,
                NotBefore = now.UtcDateTime,
                Expires = now.AddMinutes(15).UtcDateTime,
                Claims = new Dictionary<string, object>(StringComparer.Ordinal)
                {
                    ["sub"] = session.UserId.ToString(),
                    ["sid"] = session.SessionId.ToString(),
                    ["anon"] = session.IsAnonymous,
                },
                SigningCredentials = new SigningCredentials(new ECDsaSecurityKey(ec) { KeyId = active.Kid, CryptoProviderFactory = new CryptoProviderFactory { CacheSignatureProviders = false } }, SecurityAlgorithms.EcdsaSha256),
            });
        }
        finally { CryptographicOperations.ZeroMemory(plaintext); CryptographicOperations.ZeroMemory(wrapping); }
    }
    public async Task<ClaimsPrincipal?> ValidateAsync(string token, CancellationToken ct)
    {
        if (token.Length > 16384) { return null; }
        var keys = await PublicKeysAsync(ct);
        var now = clock.GetUtcNow().UtcDateTime;
        var result = await handler.ValidateTokenAsync(token, new TokenValidationParameters
        {
            ValidIssuer = options.Value.Issuer,
            ValidAudience = options.Value.Audience,
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateIssuerSigningKey = true,
            TryAllIssuerSigningKeys = false,
            RequireSignedTokens = true,
            RequireExpirationTime = true,
            ValidateLifetime = true,
            ValidAlgorithms = [SecurityAlgorithms.EcdsaSha256],
            ClockSkew = TimeSpan.FromSeconds(30),
            IssuerSigningKeys = keys.Select(key => new JsonWebKey(JsonSerializer.Serialize(new { kty = key.Kty, crv = key.Crv, kid = key.Kid, x = key.X, y = key.Y, alg = key.Alg, use = key.Use }))),
            LifetimeValidator = (nbf, exp, _, _) => nbf.HasValue && exp.HasValue && nbf.Value <= now.AddSeconds(30) && exp.Value > now.AddSeconds(-30),
        });
        return result.IsValid ? new ClaimsPrincipal(result.ClaimsIdentity) : null;
    }
    public async Task<IReadOnlyList<PublicIdentityKey>> PublicKeysAsync(CancellationToken ct) =>
        (await ReadAsync(ct)).Where(key => key.ValidateUntil > clock.GetUtcNow()).Select(key => JsonSerializer.Deserialize<PublicIdentityKey>(key.PublicJwk, JsonOptions)!).ToArray();

    private async Task<List<StoredKey>> ReadAsync(CancellationToken ct)
    {
        await using var command = source.CreateCommand("SELECT kid,public_jwk::text,ciphertext,nonce,tag,wrapping_version,active,validate_until FROM identity.read_keyring()");
        await using var reader = await command.ExecuteReaderAsync(ct);
        var result = new List<StoredKey>();
        while (await reader.ReadAsync(ct))
        {
            var version = reader.GetString(5);
            if (version.Length is < 1 or > 64 || version.Any(c => !char.IsAsciiLetterOrDigit(c) && c != '-')) { throw new CryptographicException("Invalid wrapping key version."); }
            result.Add(new StoredKey(reader.GetString(0), reader.GetString(1), (byte[])reader[2], (byte[])reader[3], (byte[])reader[4], version, reader.GetBoolean(6), reader.GetFieldValue<DateTimeOffset>(7)));
        }
        return result;
    }
    private sealed record StoredKey(string Kid, string PublicJwk, byte[] Ciphertext, byte[] Nonce, byte[] Tag, string Version, bool Active, DateTimeOffset ValidateUntil);
}
