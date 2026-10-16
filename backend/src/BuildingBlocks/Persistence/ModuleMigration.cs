using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace FitnessBuddy.BuildingBlocks.Persistence;

/// <summary>Explicit migration registry entry; modules register their own context factory and schema history.</summary>
public sealed record ModuleMigration(string Schema, Func<NpgsqlConnection, DbContext> CreateContext);

/// <summary>Runs the registered module migrations in stable order under one session advisory lock.
/// Only the one-shot migrate process supplies the schema-owner connection string.</summary>
public sealed partial class MigrationRunner(IEnumerable<ModuleMigration> modules)
{
    private const long MigrationLock = 0x46424d4947524154;

    public async Task RunAsync(string migratorConnectionString, CancellationToken cancellationToken)
    {
        await using var source = DatabaseConfiguration.CreateSource(migratorConnectionString);
        await using var connection = await source.OpenConnectionAsync(cancellationToken);
        await using var acquire = new NpgsqlCommand("SELECT pg_advisory_lock($1)", connection);
        acquire.Parameters.AddWithValue(MigrationLock);
        await acquire.ExecuteNonQueryAsync(cancellationToken);
        try
        {
            foreach (var module in modules.OrderBy(module => module.Schema, StringComparer.Ordinal))
            {
                if (!SchemaName().IsMatch(module.Schema)) { throw new InvalidOperationException("Invalid module schema name."); }
                await using var createSchema = new NpgsqlCommand($"CREATE SCHEMA IF NOT EXISTS {module.Schema}", connection);
                await createSchema.ExecuteNonQueryAsync(cancellationToken);
                await using var context = module.CreateContext(connection);
                await context.Database.MigrateAsync(cancellationToken);
            }
        }
        finally
        {
            // Session locks survive transaction rollback. Always release before the pooled connection returns.
            await using var release = new NpgsqlCommand("SELECT pg_advisory_unlock($1)", connection);
            release.Parameters.AddWithValue(MigrationLock);
            await release.ExecuteNonQueryAsync(CancellationToken.None);
        }
    }

    [GeneratedRegex("^[a-z][a-z0-9_]{0,62}$", RegexOptions.CultureInvariant)]
    private static partial Regex SchemaName();
}
