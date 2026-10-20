using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

/// <summary>B02 has no user database state. Adding storage requires an eraser and inventory update.</summary>
internal sealed class BuddyErasure : IOutboxHandler
{
    public string EventType => UserErasure.EventType;
    public string Name => "buddy.erase";
    public Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        if (session.UserId is null || session.UserId != message.UserId) { throw new InvalidOperationException("Invalid erasure scope."); }
        return Task.CompletedTask;
    }
}
