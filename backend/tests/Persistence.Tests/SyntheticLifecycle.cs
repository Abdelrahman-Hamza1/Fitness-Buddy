using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Persistence.Tests;

/// <summary>S04 independent queue/replay fixtures use arbitrary owners; deletion races use real Identity instead.</summary>
internal sealed class SyntheticLifecycle : IUserLifecycle
{
    public Task<bool> IsActiveAsync(DatabaseSession session, Guid? sessionId, CancellationToken cancellationToken) => Task.FromResult(true);
}
