using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Npgsql;

namespace FitnessBuddy.BuildingBlocks.Persistence;

/// <summary>Shared PostgreSQL configuration. SQL text, parameters and provider error details never enter telemetry.</summary>
public static class DatabaseConfiguration
{
    public static NpgsqlDataSource CreateSource(string connectionString)
    {
        var settings = new NpgsqlConnectionStringBuilder(connectionString)
        {
            IncludeErrorDetail = false,
            LogParameters = false,
            Timeout = 5,
            CommandTimeout = 15,
        };
        // Password/SCRAM deployments do not need native Kerberos discovery in the chiseled image.
        if (settings.GssEncryptionMode == GssEncryptionMode.Require) { throw new InvalidOperationException("Kerberos encryption is unavailable in the application image; use the configured TLS/SCRAM transport."); }
        settings.GssEncryptionMode = GssEncryptionMode.Disable;
        // No logger factory or tracing is attached to the driver: even SQL literals can contain content.
        return new NpgsqlDataSourceBuilder(settings.ConnectionString)
            .ConfigureTracing(tracing => tracing.ConfigureCommandFilter(_ => false).ConfigureBatchFilter(_ => false)
                .ConfigureCopyOperationFilter(_ => false).EnablePhysicalOpenTracing(false))
            .Build();
    }

    public static DbContextOptions<T> ContextOptions<T>(NpgsqlConnection connection, string schema) where T : DbContext =>
        new DbContextOptionsBuilder<T>().UseNpgsql(connection, options => options.MigrationsHistoryTable("__ef_migrations_history", schema))
            .UseLoggerFactory(NullLoggerFactory.Instance).EnableSensitiveDataLogging(false).EnableDetailedErrors(false)
            // EF's DiagnosticSource otherwise publishes command objects even with an empty logger.
            .ConfigureWarnings(warnings => warnings.Ignore(RelationalEventId.CommandExecuting, RelationalEventId.CommandExecuted,
                RelationalEventId.CommandError, RelationalEventId.DataReaderDisposing, RelationalEventId.DataReaderClosing))
            .Options;

    public static IServiceCollection AddFbDatabase(this IServiceCollection services, string applicationConnectionString) =>
        services.AddFbDatabase(_ => applicationConnectionString);

    public static IServiceCollection AddFbDatabase(this IServiceCollection services, Func<IServiceProvider, string> applicationConnectionString)
    {
        services.AddSingleton(provider => CreateSource(applicationConnectionString(provider)));
        services.AddScoped<DatabaseSession>();
        services.AddScoped<UserDatabase>();
        services.AddSingleton<ModuleMigration>(new ModuleMigration("ops", connection => new OpsDbContext(ContextOptions<OpsDbContext>(connection, "ops"))));
        return services;
    }
}
