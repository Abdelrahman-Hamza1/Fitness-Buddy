using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Catalog.Domain;
using Npgsql;

namespace FitnessBuddy.Modules.Catalog.Infrastructure;

internal static class CatalogImporter
{
    public static async Task ImportAsync(string connection, string directory, CancellationToken ct)
    {
        // Validate and snapshot bounded input before opening the publication transaction.
        var release = await CatalogRelease.ReadAsync(directory, ct);
        await using var source = DatabaseConfiguration.CreateSource(connection);
        await using var database = await source.OpenConnectionAsync(ct);
        await using var tx = await database.BeginTransactionAsync(ct);
        async Task<int> Execute(string sql, params object[] values)
        {
            await using var command = new NpgsqlCommand(sql, database, tx);
            foreach (var value in values) { command.Parameters.Add(new NpgsqlParameter { Value = value }); }
            return await command.ExecuteNonQueryAsync(ct);
        }
        // Operator maintenance already owns the global lock. This also serializes direct fixture import.
        await Execute("SELECT pg_advisory_xact_lock(7804307001)");
        await using (var existing = new NpgsqlCommand("SELECT version,content_sha256,pack_sha256,schema_version,octet_length(pack) FROM catalog.pack_releases ORDER BY version DESC LIMIT 1", database, tx))
        await using (var reader = await existing.ExecuteReaderAsync(ct))
        {
            if (await reader.ReadAsync(ct))
            {
                var latest = reader.GetInt32(0);
                if (release.Version < latest) { throw new InvalidDataException("Catalog version rollback is forbidden."); }
                if (release.Version == latest)
                {
                    if (reader.GetString(1) != release.Manifest.GetProperty("content_sha256").GetString() || reader.GetString(2) != release.Manifest.GetProperty("pack").GetProperty("sha256").GetString()
                        || reader.GetInt32(3) != release.Manifest.GetProperty("schema_version").GetInt32() || reader.GetInt32(4) != release.Pack.Length) { throw new InvalidDataException("Catalog version cannot be reused."); }
                    return;
                }
            }
        }
        foreach (var table in new[] { "foods", "dishes", "exercises", "cities" })
        { await Execute("UPDATE catalog." + table + " SET active=false"); }
        await Execute("DELETE FROM catalog.names; DELETE FROM catalog.yields");
        foreach (var food in release.Rows["foods"])
        {
            var id = food.GetProperty("id").GetString()!; var kind = food.GetProperty("kind").GetString()!;
            var sourceName = food.GetProperty("source").GetString()!; var sourceRef = food.GetProperty("source_ref").GetString() ?? "";
            var first = food.GetProperty("catalog_version").GetInt32();
            await using (var check = new NpgsqlCommand("SELECT kind,source,source_ref,first_version FROM catalog.foods WHERE id=$1", database, tx))
            {
                check.Parameters.AddWithValue(id); await using var reader = await check.ExecuteReaderAsync(ct);
                if (await reader.ReadAsync(ct) && (reader.GetString(0) != kind || reader.GetString(1) != sourceName || reader.GetString(2) != sourceRef || reader.GetInt32(3) != first)) { throw new InvalidDataException("Catalog identity cannot change."); }
            }
            await Execute("""
                INSERT INTO catalog.foods VALUES($1,$2,$3,$4,$5,$6,$7,true,$8::jsonb)
                ON CONFLICT(id) DO UPDATE SET name_key=excluded.name_key,state=excluded.state,active=true,data=excluded.data
                """, id, kind, sourceName, sourceRef, first, SearchKey.Normalize(food.GetProperty("name_en").GetString()!), food.GetProperty("state").GetString()!, food.GetRawText());
        }
        foreach (var table in new[] { "dishes", "exercises", "cities" })
            foreach (var row in release.Rows[table])
            {
                var id = row.GetProperty("id").GetString()!;
                if (table != "cities")
                {
                    await using var check = new NpgsqlCommand("SELECT first_version FROM catalog." + table + " WHERE id=$1", database, tx);
                    check.Parameters.AddWithValue(id); var previous = await check.ExecuteScalarAsync(ct);
                    if (previous is int first && first != row.GetProperty("catalog_version").GetInt32()) { throw new InvalidDataException("Catalog first appearance cannot change."); }
                }
                if (table == "dishes") { await Execute("INSERT INTO catalog.dishes VALUES($1,$2,$3,true,$4::jsonb) ON CONFLICT(id) DO UPDATE SET default_variant_id=excluded.default_variant_id,active=true,data=excluded.data", id, row.GetProperty("catalog_version").GetInt32(), row.GetProperty("default_variant_id").GetString()!, row.GetRawText()); }
                else if (table == "exercises") { await Execute("INSERT INTO catalog.exercises VALUES($1,$2,true,$3::jsonb) ON CONFLICT(id) DO UPDATE SET active=true,data=excluded.data", id, row.GetProperty("catalog_version").GetInt32(), row.GetRawText()); }
                else { await Execute("INSERT INTO catalog.cities VALUES($1,true,$2::jsonb) ON CONFLICT(id) DO UPDATE SET active=true,data=excluded.data", id, row.GetRawText()); }
            }
        var dishes = release.Rows["dishes"].ToDictionary(v => v.GetProperty("id").GetString()!, v => v.GetProperty("default_variant_id").GetString()!, StringComparer.Ordinal);
        var foodIds = release.Rows["foods"].Select(v => v.GetProperty("id").GetString()!).ToHashSet(StringComparer.Ordinal);
        foreach (var name in release.Rows["names"])
        {
            var target = name.GetProperty("target_id").GetString()!;
            object food = foodIds.Contains(target) ? target : dishes.TryGetValue(target, out var variant) ? variant : DBNull.Value;
            await Execute("INSERT INTO catalog.names VALUES($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING", target, food, name.GetProperty("lang").GetString()!, name.GetProperty("name").GetString()!, name.GetProperty("key").GetString()!);
        }
        var ordinal = 0;
        foreach (var food in release.Rows["foods"]) { await Execute("DELETE FROM catalog.servings WHERE food_id=$1", food.GetProperty("id").GetString()!); }
        foreach (var serving in release.Rows["servings"]) { await Execute("INSERT INTO catalog.servings VALUES($1,$2,$3::jsonb)", serving.GetProperty("food_id").GetString()!, ordinal++, serving.GetRawText()); }
        ordinal = 0;
        foreach (var yield in release.Rows["yields"]) { await Execute("INSERT INTO catalog.yields VALUES($1,$2::jsonb)", ordinal++, yield.GetRawText()); }
        await Execute("INSERT INTO catalog.pack_releases VALUES($1,$2,$3,$4,$5,$6::jsonb)", release.Version, release.Manifest.GetProperty("content_sha256").GetString()!, release.Manifest.GetProperty("pack").GetProperty("sha256").GetString()!, release.Manifest.GetProperty("schema_version").GetInt32(), release.Pack, release.Manifest.GetRawText());
        await Execute("INSERT INTO catalog.current_release VALUES(true,$1) ON CONFLICT(singleton) DO UPDATE SET version=excluded.version", release.Version);
        await tx.CommitAsync(ct);
    }
}
