using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.BuildingBlocks.Messaging;

/// <summary>A durable message. Payloads are private data and must never be logged.</summary>
public sealed record QueueMessage(Guid Id, string Type, string Payload, Guid? UserId, int Attempt);

/// <summary>Database-only handler. All effects use the supplied session; never commit it or perform network I/O.
/// Stable Name identifies this handler in processed-message tracking across deployments.</summary>
public interface IOutboxHandler
{
    string EventType { get; }
    string Name { get; }
    Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken);
}
