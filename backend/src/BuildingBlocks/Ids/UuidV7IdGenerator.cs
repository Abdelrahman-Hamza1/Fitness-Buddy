namespace FitnessBuddy.BuildingBlocks.Ids;

/// <summary>UUIDv7 from the injected clock, so IDs follow <see cref="TimeProvider"/> in tests too.</summary>
public sealed class UuidV7IdGenerator(TimeProvider timeProvider) : IIdGenerator
{
    public Guid NewId() => Guid.CreateVersion7(timeProvider.GetUtcNow());
}
