using Microsoft.AspNetCore.Builder;

namespace FitnessBuddy.BuildingBlocks.Web.Idempotency;

/// <summary>Marks an unsafe POST whose database effects and replay record share one transaction.
/// Endpoints must use the scoped DatabaseSession and must not commit it themselves.</summary>
public sealed class IdempotencyMetadata
{
    private IdempotencyMetadata() { }
    public static IdempotencyMetadata Instance { get; } = new();
}

public static class IdempotencyEndpointExtensions
{
    public static TBuilder RequireIdempotency<TBuilder>(this TBuilder builder) where TBuilder : IEndpointConventionBuilder =>
        builder.WithMetadata(IdempotencyMetadata.Instance);
}
