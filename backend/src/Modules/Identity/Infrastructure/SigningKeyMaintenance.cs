using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.IdentityModel.Tokens;
using Npgsql;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

/// <summary>Explicit migrate-role tooling only. API startup never generates or writes signing keys.</summary>
internal static class SigningKeyMaintenance
{
    public static async Task RunAsync(string connectionString, string directory, string version, string operation, TimeProvider clock, CancellationToken ct)
    {
        if (version.Length is < 1 or > 64 || version.Any(c => !char.IsAsciiLetterOrDigit(c) && c != '-')) { throw new ArgumentException("Invalid key version."); }
        if (operation is not ("ensure" or "rotate" or "rewrap")) { throw new ArgumentException("Invalid key operation."); }
        var wrap = IdentitySecrets.ReadKey(Path.Combine(directory, version + ".key"));
        try
        {
            await using var source = DatabaseConfiguration.CreateSource(connectionString);
            await using var connection = await source.OpenConnectionAsync(ct);
            await using var transaction = await connection.BeginTransactionAsync(ct);
            await using var acquire = new NpgsqlCommand("SELECT pg_advisory_xact_lock(5062701277)", connection, transaction);
            await acquire.ExecuteNonQueryAsync(ct);
            await using var count = new NpgsqlCommand("SELECT count(*) FROM identity.signing_keys WHERE active", connection, transaction);
            var exists = (long)(await count.ExecuteScalarAsync(ct))! > 0;
            if (operation == "rewrap")
            {
                var rows = new List<(string Kid, byte[] Cipher, byte[] Nonce, byte[] Tag, string Version)>();
                await using (var read = new NpgsqlCommand("SELECT kid,ciphertext,nonce,tag,wrapping_version FROM identity.signing_keys WHERE wrapping_version<>$1", connection, transaction))
                {
                    read.Parameters.AddWithValue(version);
                    await using var reader = await read.ExecuteReaderAsync(ct);
                    while (await reader.ReadAsync(ct)) { rows.Add((reader.GetString(0), (byte[])reader[1], (byte[])reader[2], (byte[])reader[3], reader.GetString(4))); }
                }
                foreach (var row in rows)
                {
                    if (row.Version.Any(c => !char.IsAsciiLetterOrDigit(c) && c != '-')) { throw new CryptographicException("Invalid old key version."); }
                    var old = IdentitySecrets.ReadKey(Path.Combine(directory, row.Version + ".key"));
                    var plaintext = new byte[row.Cipher.Length];
                    try
                    {
                        using var decrypt = new AesGcm(old, 16);
                        decrypt.Decrypt(row.Nonce, row.Cipher, row.Tag, plaintext, Aad(row.Kid));
                        var nonce = RandomNumberGenerator.GetBytes(12); var tag = new byte[16]; var ciphertext = new byte[plaintext.Length];
                        using var encrypt = new AesGcm(wrap, 16);
                        encrypt.Encrypt(nonce, plaintext, ciphertext, tag, Aad(row.Kid));
                        var check = new byte[plaintext.Length];
                        try { encrypt.Decrypt(nonce, ciphertext, tag, check, Aad(row.Kid)); if (!CryptographicOperations.FixedTimeEquals(check, plaintext)) { throw new CryptographicException("Rewrap verification failed."); } }
                        finally { CryptographicOperations.ZeroMemory(check); }
                        await using var update = new NpgsqlCommand("UPDATE identity.signing_keys SET ciphertext=$1,nonce=$2,tag=$3,wrapping_version=$4 WHERE kid=$5", connection, transaction);
                        update.Parameters.AddWithValue(ciphertext); update.Parameters.AddWithValue(nonce); update.Parameters.AddWithValue(tag); update.Parameters.AddWithValue(version); update.Parameters.AddWithValue(row.Kid);
                        await update.ExecuteNonQueryAsync(ct);
                    }
                    finally { CryptographicOperations.ZeroMemory(old); CryptographicOperations.ZeroMemory(plaintext); }
                }
            }
            else if (!exists || operation == "rotate")
            {
                var now = clock.GetUtcNow();
                await using var retire = new NpgsqlCommand("UPDATE identity.signing_keys SET active=false,validate_until=LEAST(validate_until,$1) WHERE active", connection, transaction);
                retire.Parameters.AddWithValue(now.AddMinutes(16));
                await retire.ExecuteNonQueryAsync(ct);
                var kid = Base64UrlEncoder.Encode(RandomNumberGenerator.GetBytes(16));
                using var ec = ECDsa.Create(ECCurve.NamedCurves.nistP256);
                var plaintext = ec.ExportPkcs8PrivateKey();
                try
                {
                    var nonce = RandomNumberGenerator.GetBytes(12); var tag = new byte[16]; var ciphertext = new byte[plaintext.Length];
                    using var aes = new AesGcm(wrap, 16); aes.Encrypt(nonce, plaintext, ciphertext, tag, Aad(kid));
                    var parameters = ec.ExportParameters(false);
                    var jwk = JsonSerializer.Serialize(new { kty = "EC", crv = "P-256", kid, x = Base64UrlEncoder.Encode(parameters.Q.X!), y = Base64UrlEncoder.Encode(parameters.Q.Y!), alg = "ES256", use = "sig" });
                    await using var insert = new NpgsqlCommand("INSERT INTO identity.signing_keys VALUES($1,$2::jsonb,$3,$4,$5,$6,true,$7)", connection, transaction);
                    insert.Parameters.AddWithValue(kid); insert.Parameters.AddWithValue(jwk); insert.Parameters.AddWithValue(ciphertext); insert.Parameters.AddWithValue(nonce); insert.Parameters.AddWithValue(tag); insert.Parameters.AddWithValue(version); insert.Parameters.AddWithValue(now.AddYears(10));
                    await insert.ExecuteNonQueryAsync(ct);
                }
                finally { CryptographicOperations.ZeroMemory(plaintext); }
            }
            await transaction.CommitAsync(ct);
        }
        finally { CryptographicOperations.ZeroMemory(wrap); }
    }
    private static byte[] Aad(string kid) => Encoding.UTF8.GetBytes(kid + ":ES256:PKCS8:v1");
}
