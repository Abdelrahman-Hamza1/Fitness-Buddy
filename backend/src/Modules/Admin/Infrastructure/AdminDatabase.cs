using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Admin.Application;
using Npgsql;

namespace FitnessBuddy.Modules.Admin.Infrastructure;

/// <summary>System sessions on the console login (the admin role's only data source): no <c>app.user_id</c>, so no user rows.</summary>
internal sealed class AdminDatabase(NpgsqlDataSource source) : IAdminDatabase
{
    public async Task<DatabaseSession> BeginAsync(CancellationToken cancellationToken)
    {
        var session = new DatabaseSession();
        try
        {
            await session.BeginAsync(source, null, cancellationToken);
            return session;
        }
        catch
        {
            await session.DisposeAsync();
            throw;
        }
    }
}
