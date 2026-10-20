using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using Npgsql;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

internal sealed class UserDataErasure : IOutboxHandler
{
    public string EventType => UserErasure.EventType;
    public string Name => "userdata.erase";
    public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        if (session.UserId is not Guid user || message.UserId != user) { throw new InvalidOperationException("Invalid erasure scope."); }
        await using var batch = new NpgsqlBatch(session.Connection, session.Transaction);
        foreach (var statement in new[]
        {
            "DELETE FROM userdata.row_history WHERE user_id=$1",
            "DELETE FROM userdata.version_receipts WHERE user_id=$1",
            "DELETE FROM userdata.documents WHERE user_id=$1",
        })
        {
            var command = new NpgsqlBatchCommand(statement);
            command.Parameters.AddWithValue(user);
            batch.BatchCommands.Add(command);
        }
        await batch.ExecuteNonQueryAsync(cancellationToken);
    }
}
