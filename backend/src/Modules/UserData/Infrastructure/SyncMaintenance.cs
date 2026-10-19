using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

internal static class SyncMaintenance
{
    public static async Task SeedAsync(string migratorConnection, TimeProvider clock, IIdGenerator ids, CancellationToken cancellationToken)
    {
        await using var source = DatabaseConfiguration.CreateSource(migratorConnection);
        var users = new List<Guid>();
        await using (var command = source.CreateCommand("SELECT user_id FROM userdata.documents UNION SELECT user_id FROM userdata.row_history"))
        {
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken)) { users.Add(reader.GetGuid(0)); }
        }
        foreach (var user in users)
        {
            await using var session = new DatabaseSession(); await session.BeginAsync(source, user, cancellationToken);
            await new QueueWriter(session, clock, ids).ScheduleUserAsync("userdata.cleanup:" + user, "0 * * * *", "userdata.cleanup", clock.GetUtcNow().AddHours(1), cancellationToken);
            await session.CommitAsync(cancellationToken);
        }
    }
}
