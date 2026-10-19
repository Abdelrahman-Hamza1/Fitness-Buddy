using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.UserData.Domain;

namespace FitnessBuddy.Modules.UserData.Application;

internal interface ISyncStore
{
    Task<PushOutcome?> PushForSessionAsync(IdentitySession principal, Guid? dataset, IReadOnlyList<SyncVersion> versions, DateTimeOffset now, CancellationToken cancellationToken);
    Task<VersionPage?> PullForSessionAsync(IdentitySession principal, Guid? dataset, long cursor, int limit, bool history, string? entity, Guid? id, CancellationToken cancellationToken);
}
