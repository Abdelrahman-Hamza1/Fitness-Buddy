using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

/// <summary>Replay content and paid-attempt markers are erased atomically with the account.</summary>
internal sealed class BuddyErasure : IOutboxHandler
{
    public string EventType => UserErasure.EventType;
    public string Name => "buddy.erase";
    public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        if (session.UserId is null || session.UserId != message.UserId) { throw new InvalidOperationException("Invalid erasure scope."); }
        await using var command = session.Command("DELETE FROM buddy.attempts WHERE user_id=$1");
        command.Parameters.AddWithValue(session.UserId.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
