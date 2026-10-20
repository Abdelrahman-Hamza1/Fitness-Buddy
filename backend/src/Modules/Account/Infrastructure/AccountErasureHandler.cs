using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Modules.Account.Infrastructure;

internal sealed class AccountErasureHandler : IOutboxHandler
{
    public string EventType => UserErasure.EventType;
    public string Name => "account.erase";
    public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        if (session.UserId is null || session.UserId != message.UserId) { throw new InvalidOperationException("Invalid erasure scope."); }
        await using var command = session.Command("DELETE FROM account.deletion_requests WHERE user_id=$1");
        command.Parameters.AddWithValue(session.UserId.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
