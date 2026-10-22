using FitnessBuddy.BuildingBlocks.Jobs;
using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Usage.Contracts;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

internal sealed class BuddyCleanup(TimeProvider clock, IUsageRecorder usage) : IJobHandler
{
    public string JobType => "buddy.cleanup";
    public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        if (session.UserId is not { } owner || owner != message.UserId) { throw new InvalidOperationException("Missing Buddy cleanup owner."); }
        await UserLifecycleLock.AcquireAsync(session, owner, cancellationToken);
        await using var command = session.Command("DELETE FROM buddy.attempts WHERE user_id=$1 AND expires_at<=$2");
        command.Parameters.AddWithValue(owner); command.Parameters.AddWithValue(clock.GetUtcNow());
        await command.ExecuteNonQueryAsync(cancellationToken); await usage.CleanupAsync(session, cancellationToken);
    }
}
