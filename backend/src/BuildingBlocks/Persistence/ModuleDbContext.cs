using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;

namespace FitnessBuddy.BuildingBlocks.Persistence;

/// <summary>Base for schema-owned module contexts. Derived OnModelCreating configures entities, then calls base.
/// IDs/timestamps are explicit application values from IIdGenerator/TimeProvider; never database-local time.</summary>
public abstract partial class ModuleDbContext(DbContextOptions options, string schema) : DbContext(options)
{
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema(schema);
        foreach (var entity in modelBuilder.Model.GetEntityTypes())
        {
            entity.SetTableName(SnakeCase(entity.GetTableName()!));
            entity.SetSchema(schema);
            foreach (var key in entity.GetKeys()) { key.SetName(SnakeCase(key.GetName()!)); }
            foreach (var index in entity.GetIndexes()) { index.SetDatabaseName(SnakeCase(index.GetDatabaseName()!)); }
            foreach (var foreignKey in entity.GetForeignKeys()) { foreignKey.SetConstraintName(SnakeCase(foreignKey.GetConstraintName()!)); }
            foreach (var property in entity.GetProperties())
            {
                property.SetColumnName(SnakeCase(property.Name));
                if (property.ClrType == typeof(Guid)) { property.SetColumnType("uuid"); }
                if (property.ClrType == typeof(DateTimeOffset) || property.ClrType == typeof(DateTimeOffset?))
                {
                    property.SetColumnType("timestamp with time zone");
                }
            }
        }
    }

    private static string SnakeCase(string name) => WordBoundary().Replace(name, "$1_$2").ToLowerInvariant();

    [GeneratedRegex("([a-z0-9])([A-Z])", RegexOptions.CultureInvariant)]
    private static partial Regex WordBoundary();
}
