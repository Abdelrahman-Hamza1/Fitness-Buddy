using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using NpgsqlTypes;

namespace FitnessBuddy.BuildingBlocks.Persistence;

/// <summary>A persisted response. Only explicitly replay-safe headers are captured by the HTTP boundary.</summary>
public sealed record StoredResponse(int Status, string? ContentType, byte[] Body, Dictionary<string, string> Headers);

/// <summary>Serializes same-user/operation/key requests across API instances with a transaction advisory lock.</summary>
public sealed class IdempotencyStore(DatabaseSession session, TimeProvider clock)
{
    public static string Hash(string value) => Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(value)));

    public async Task LockAsync(string scopeHash, string keyHash, CancellationToken cancellationToken)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(scopeHash + keyHash));
        await using var command = session.Command("SELECT pg_advisory_xact_lock($1)");
        command.Parameters.AddWithValue(BinaryPrimitives.ReadInt64BigEndian(bytes));
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<(string Fingerprint, StoredResponse Response)?> ReadAsync(string scopeHash, string keyHash, CancellationToken cancellationToken)
    {
        await using var command = session.Command("SELECT fingerprint,status,content_type,body,headers::text FROM ops.idempotency WHERE scope_hash=$1 AND key_hash=$2 AND expires_at > $3");
        command.Parameters.AddWithValue(scopeHash);
        command.Parameters.AddWithValue(keyHash);
        command.Parameters.AddWithValue(clock.GetUtcNow());
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) { return null; }
        return (reader.GetString(0), new StoredResponse(reader.GetInt32(1), reader.IsDBNull(2) ? null : reader.GetString(2),
            reader.GetFieldValue<byte[]>(3), JsonSerializer.Deserialize<Dictionary<string, string>>(reader.GetString(4))!));
    }

    public async Task WriteAsync(string scopeHash, string keyHash, string fingerprint, StoredResponse response, CancellationToken cancellationToken)
    {
        await using var command = session.Command("""
            INSERT INTO ops.idempotency(scope_hash,key_hash,fingerprint,status,content_type,body,headers,created_at,expires_at,user_id)
            VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
            ON CONFLICT(scope_hash,key_hash) DO UPDATE SET fingerprint=excluded.fingerprint,status=excluded.status,
                content_type=excluded.content_type,body=excluded.body,headers=excluded.headers,created_at=excluded.created_at,expires_at=excluded.expires_at,user_id=excluded.user_id
            """);
        command.Parameters.AddWithValue(scopeHash);
        command.Parameters.AddWithValue(keyHash);
        command.Parameters.AddWithValue(fingerprint);
        command.Parameters.AddWithValue(response.Status);
        command.Parameters.AddWithValue(NpgsqlDbType.Text, (object?)response.ContentType ?? DBNull.Value);
        command.Parameters.AddWithValue(response.Body);
        command.Parameters.AddWithValue(NpgsqlDbType.Jsonb, JsonSerializer.Serialize(response.Headers));
        command.Parameters.AddWithValue(clock.GetUtcNow());
        command.Parameters.AddWithValue(clock.GetUtcNow() + TimeSpan.FromHours(24));
        command.Parameters.AddWithValue(NpgsqlDbType.Uuid, (object?)session.UserId ?? DBNull.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
