using System.Data;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using FitnessBuddy.Modules.Catalog.Application;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Catalog.Infrastructure;

internal sealed class PostgresCatalogStore(NpgsqlDataSource source) : ICatalogStore
{
    public async Task<SearchResult> SearchAsync(string key, int limit, string? cursor, string? state, string? kind, CancellationToken ct)
    {
        var hash = Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(key)));
        SearchPosition? position = null;
        if (cursor is not null)
        {
            try
            {
                if (cursor.Length > 2048) { throw new ArgumentException("Invalid search cursor."); }
                position = JsonSerializer.Deserialize<SearchPosition>(Convert.FromBase64String(cursor));
                if (position is null || position.QueryHash != hash || position.Key is not { Length: > 0 and <= 64 } || !double.IsFinite(position.Score)
                    || position.SourceRank is < 0 or > 2 || position.MatchRank is < 0 or > 4 || position.Score is < 0 or > 1) { throw new ArgumentException("Invalid search cursor."); }
            }
            catch (Exception error) when (error is JsonException or FormatException) { throw new ArgumentException("Invalid search cursor."); }
        }
        await using var connection = await source.OpenConnectionAsync(ct);
        await using var tx = await connection.BeginTransactionAsync(IsolationLevel.RepeatableRead, ct);
        int version;
        await using (var current = new NpgsqlCommand("SELECT version FROM catalog.current_release WHERE singleton", connection, tx))
        { version = await current.ExecuteScalarAsync(ct) is int number ? number : 0; }
        if (position is not null && position.Version != version) { throw new ArgumentException("Catalog changed; restart search."); }
        if (key.Length == 0 || version == 0) { return new SearchResult([], null); }
        await using var command = new NpgsqlCommand("""
            WITH matches AS (
              SELECT f.id, f.data, f.name_key, f.state, f.source,
                CASE WHEN f.source='usda' AND (f.data->>'verified')::int=1 THEN 0 WHEN f.source='usda' THEN 1 ELSE 2 END AS source_rank,
                MIN(CASE WHEN n.key=$1 THEN 0 WHEN n.key LIKE $1 || '%' THEN 1
                  WHEN to_tsvector('simple',n.key) @@ plainto_tsquery('simple',$1) THEN 2
                  WHEN n.key LIKE '%' || $1 || '%' THEN 3 ELSE 4 END) AS match_rank,
                MAX(public.similarity(n.key,$1))::double precision AS score
              FROM catalog.names n JOIN catalog.foods f ON f.id=n.food_id
              WHERE f.active AND ($2::text IS NULL OR f.state=$2) AND ($3::text IS NULL OR f.kind=$3)
                AND (n.key LIKE '%' || $1 || '%' OR to_tsvector('simple',n.key) @@ plainto_tsquery('simple',$1)
                  OR ($4 AND n.key OPERATOR(public.%) $1))
              GROUP BY f.id
            ), dedup AS (
              SELECT *,row_number() OVER(PARTITION BY name_key,state,source ORDER BY source_rank,match_rank,score DESC,id COLLATE "C") AS duplicate
              FROM matches
            )
            SELECT data,source_rank,match_rank,score,
              coalesce((SELECT jsonb_agg(s.data ORDER BY s.ordinal) FROM catalog.servings s WHERE s.food_id=dedup.id),'[]'::jsonb)::text
            FROM dedup WHERE duplicate=1 AND ($5::text IS NULL OR (source_rank,match_rank,-score,id COLLATE "C") > ($6,$7,-$8,$5 COLLATE "C"))
            ORDER BY source_rank,match_rank,score DESC,id COLLATE "C" LIMIT $9
            """, connection, tx);
        command.Parameters.AddWithValue(key);
        command.Parameters.Add(new NpgsqlParameter { NpgsqlDbType = NpgsqlDbType.Text, Value = (object?)state ?? DBNull.Value });
        command.Parameters.Add(new NpgsqlParameter { NpgsqlDbType = NpgsqlDbType.Text, Value = (object?)kind ?? DBNull.Value });
        command.Parameters.AddWithValue(key.Length >= 3 && key.All(c => c is >= 'a' and <= 'z' or >= '0' and <= '9' or ' '));
        command.Parameters.Add(new NpgsqlParameter { NpgsqlDbType = NpgsqlDbType.Text, Value = (object?)position?.Key ?? DBNull.Value });
        command.Parameters.AddWithValue(position?.SourceRank ?? 0); command.Parameters.AddWithValue(position?.MatchRank ?? 0); command.Parameters.AddWithValue(position?.Score ?? 0);
        command.Parameters.AddWithValue(limit + 1);
        var rows = new List<RankedFood>();
        await using (var reader = await command.ExecuteReaderAsync(ct))
        {
            while (await reader.ReadAsync(ct))
            {
                using var food = JsonDocument.Parse(reader.GetString(0)); using var servings = JsonDocument.Parse(reader.GetString(4));
                rows.Add(new RankedFood(new FoodRecord(food.RootElement.Clone(), servings.RootElement.EnumerateArray().Select(v => v.Clone()).ToArray()), reader.GetInt32(1), reader.GetInt32(2), reader.GetDouble(3)));
            }
        }
        var more = rows.Count > limit; var page = rows.Take(limit).ToArray(); string? next = null;
        if (more)
        {
            var last = page[^1]; next = Convert.ToBase64String(JsonSerializer.SerializeToUtf8Bytes(new SearchPosition(version, hash, last.SourceRank, last.MatchRank, last.Score, last.Food.Data.GetProperty("id").GetString()!)));
        }
        return new SearchResult(page, next);
    }
    public async Task<FoodRecord?> GetAsync(string id, CancellationToken ct)
    {
        await using var command = source.CreateCommand("""
            SELECT f.data,coalesce((SELECT jsonb_agg(s.data ORDER BY s.ordinal) FROM catalog.servings s WHERE s.food_id=f.id),'[]'::jsonb)::text
            FROM catalog.foods f WHERE f.id=$1
            """);
        command.Parameters.AddWithValue(id); await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) { return null; }
        using var food = JsonDocument.Parse(reader.GetString(0)); using var servings = JsonDocument.Parse(reader.GetString(1));
        return new FoodRecord(food.RootElement.Clone(), servings.RootElement.EnumerateArray().Select(v => v.Clone()).ToArray());
    }
    public async Task<PackRecord?> PackAsync(int? version, CancellationToken ct)
    {
        await using var command = source.CreateCommand("""
            SELECT version,pack_sha256,octet_length(pack),schema_version,CASE WHEN $1::int IS NULL THEN NULL ELSE pack END
            FROM catalog.pack_releases WHERE version=coalesce($1,(SELECT version FROM catalog.current_release WHERE singleton))
            """);
        command.Parameters.Add(new NpgsqlParameter { NpgsqlDbType = NpgsqlDbType.Integer, Value = (object?)version ?? DBNull.Value });
        await using var reader = await command.ExecuteReaderAsync(ct);
        return await reader.ReadAsync(ct) ? new PackRecord(reader.GetInt32(0), reader.GetString(1), reader.GetInt32(2), reader.GetInt32(3), reader.IsDBNull(4) ? null : reader.GetFieldValue<byte[]>(4)) : null;
    }
}
