namespace FitnessBuddy.BuildingBlocks.Ids;

/// <summary>Creates new IDs. Inject it instead of calling <see cref="Guid.NewGuid"/>, so tests control the IDs.</summary>
public interface IIdGenerator
{
    /// <summary>A new UUIDv7 (time-ordered, 04 §4.2 "Formats").</summary>
    Guid NewId();
}
