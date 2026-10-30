using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Recovery;
using FitnessBuddy.Modules.Catalog.Application;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Catalog.Infrastructure;

/// <summary><c>catalog.off_cache</c>: OFF data only, never joined into release tables (`07` §3). Writes take the
/// shared recovery barrier like every other application write.</summary>
internal sealed class PostgresOffCache(NpgsqlDataSource source, RecoveryBarrier recovery) : IOffCache
{
    private const int Version = 1;
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    private sealed record Row(int V, OffProduct? Product);

    public async Task<OffCacheEntry?> GetAsync(string code, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT data::text, expires_at FROM catalog.off_cache WHERE code=$1");
        command.Parameters.AddWithValue(code);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) { return null; }
        Row? row;
        try { row = JsonSerializer.Deserialize<Row>(reader.GetString(0), Json); }
        catch (JsonException) { return null; }
        // An unknown format is a miss: the next read replaces it.
        return row is null || row.V != Version || row.Product is { } p && (p.Code != code || p.Labels is null || p.Per100 is null)
            ? null : new OffCacheEntry(row.Product, reader.GetFieldValue<DateTimeOffset>(1));
    }

    public async Task PutAsync(string code, OffProduct? product, DateTimeOffset expiresAt, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, null, cancellationToken);
        await RecoveryBarrier.LockAsync(session, exclusive: false, cancellationToken);
        await recovery.VerifyAsync(session, cancellationToken);
        await using var command = session.Command("""
            INSERT INTO catalog.off_cache(code,data,expires_at) VALUES($1,$2,$3)
            ON CONFLICT(code) DO UPDATE SET data=excluded.data, expires_at=excluded.expires_at
            """);
        command.Parameters.AddWithValue(code);
        command.Parameters.AddWithValue(NpgsqlDbType.Jsonb, JsonSerializer.Serialize(new Row(Version, product), Json));
        command.Parameters.AddWithValue(expiresAt);
        await command.ExecuteNonQueryAsync(cancellationToken);
        await session.CommitAsync(cancellationToken);
    }
}
