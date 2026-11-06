using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Usage.Infrastructure;

internal sealed class UsageErasure : IOutboxHandler
{
    public string EventType => UserErasure.EventType;
    public string Name => "usage.erase";
    public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        if (session.UserId is null || session.UserId != message.UserId) { throw new InvalidOperationException("Invalid usage erasure scope."); }
        await using var command = session.Command("DELETE FROM usage.daily WHERE user_id=$1"); command.Parameters.AddWithValue(session.UserId.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
        // No direct write on the override: the erasure-only capability checks the account is being deleted (B24).
        await using var overrides = session.Command("SELECT usage.erase_limit_override($1)"); overrides.Parameters.AddWithValue(session.UserId.Value);
        await overrides.ExecuteNonQueryAsync(cancellationToken);
    }
}
