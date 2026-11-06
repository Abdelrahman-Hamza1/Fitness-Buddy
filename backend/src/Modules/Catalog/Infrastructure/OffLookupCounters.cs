using FitnessBuddy.BuildingBlocks.Ops;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Recovery;
using FitnessBuddy.Modules.Catalog.Application;
using FitnessBuddy.Modules.Catalog.Contracts;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Catalog.Infrastructure;

/// <summary>
/// Barcode lookup outcomes and sanity rules per day (B23 P4, R#9), counted in memory and written in one batched upsert by the
/// api role's flush service. A failed flush drops the batch; a lookup never waits for or fails on a count.
/// </summary>
internal sealed class OffLookupCounters(IServiceProvider services, TimeProvider clock) : IOffLookupCounters, ICounterFlush
{
    private readonly CounterBatch<(DateOnly Day, string Outcome, string Rule)> batch = new();

    public void Record(string outcome, string rule = "") => batch.Add((DateOnly.FromDateTime(clock.GetUtcNow().UtcDateTime), outcome, rule));

    public async Task FlushAsync(CancellationToken cancellationToken)
    {
        var rows = batch.Drain();
        if (rows.Count == 0) { return; }
        // Resolved on first use: recording needs no database.
        var source = (NpgsqlDataSource)services.GetService(typeof(NpgsqlDataSource))!;
        var recovery = (RecoveryBarrier)services.GetService(typeof(RecoveryBarrier))!;
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, null, cancellationToken);
        await RecoveryBarrier.LockAsync(session, exclusive: false, cancellationToken);
        await recovery.VerifyAsync(session, cancellationToken);
        // Add-only (B23b): the API login has no direct writes to the table.
        await using var command = session.Command("SELECT catalog.count_lookups($1,$2,$3,$4)");
        command.Parameters.AddWithValue(NpgsqlDbType.Array | NpgsqlDbType.Date, rows.Select(row => row.Key.Day).ToArray());
        command.Parameters.AddWithValue(NpgsqlDbType.Array | NpgsqlDbType.Text, rows.Select(row => row.Key.Outcome).ToArray());
        command.Parameters.AddWithValue(NpgsqlDbType.Array | NpgsqlDbType.Text, rows.Select(row => row.Key.Rule).ToArray());
        command.Parameters.AddWithValue(NpgsqlDbType.Array | NpgsqlDbType.Bigint, rows.Select(row => row.Value).ToArray());
        await command.ExecuteNonQueryAsync(cancellationToken);
        await session.CommitAsync(cancellationToken);
    }
}

/// <summary>Runs on the admin role's data source (fb_admin); the application login can't execute these functions.</summary>
internal sealed class PostgresCatalogAdminReads(NpgsqlDataSource source) : ICatalogAdminReads
{
    public async Task<IReadOnlyList<CatalogReleaseInfo>> ReleasesAsync(CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT version,schema_version,foods,pack_bytes,sha_prefix,is_current FROM catalog.admin_releases()");
        var rows = new List<CatalogReleaseInfo>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new CatalogReleaseInfo(reader.GetInt32(0), reader.GetInt32(1), reader.IsDBNull(2) ? 0 : reader.GetInt32(2), reader.GetInt32(3), reader.GetString(4), reader.GetBoolean(5)));
        }
        return rows;
    }

    public async Task<OffCacheInfo> OffCacheAsync(DateTimeOffset now, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT products,unknown_codes,expiring_7d FROM catalog.admin_off_cache($1)");
        command.Parameters.AddWithValue(now);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        await reader.ReadAsync(cancellationToken);
        return new OffCacheInfo(reader.GetInt64(0), reader.GetInt64(1), reader.GetInt64(2));
    }

    public async Task<IReadOnlyList<LookupCount>> LookupsAsync(DateOnly since, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT day,outcome,rule,lookups FROM catalog.admin_lookups($1,$2,$3)");
        command.Parameters.AddWithValue(since);
        command.Parameters.AddWithValue(LookupOutcomes.All);
        command.Parameters.AddWithValue(OffSanity.Rules);
        var rows = new List<LookupCount>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new LookupCount(reader.GetFieldValue<DateOnly>(0), reader.GetString(1), reader.GetString(2), reader.GetInt64(3)));
        }
        return rows;
    }
}
