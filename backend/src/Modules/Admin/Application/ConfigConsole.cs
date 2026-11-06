using System.Globalization;
using FitnessBuddy.BuildingBlocks.Clients;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Results;
using FitnessBuddy.Modules.Account.Contracts;
using FitnessBuddy.Modules.Admin.Domain;
using FitnessBuddy.Modules.Identity.Contracts;

namespace FitnessBuddy.Modules.Admin.Application;

/// <summary>The one draft (B23 P1, R#3): its base version, a revision bumped on every save and the document's hash.</summary>
internal sealed record ConfigDraft(int BaseVersion, long Revision, RemoteConfigDocument Document, string Hash, string UpdatedBy, DateTimeOffset UpdatedAt);

internal interface IConfigDraftStore
{
    /// <summary>The draft; <paramref name="forUpdate"/> locks its row until the transaction ends.</summary>
    Task<ConfigDraft?> GetAsync(DatabaseSession session, bool forUpdate, CancellationToken cancellationToken);

    Task<long> SaveAsync(DatabaseSession session, int baseVersion, RemoteConfigDocument document, string hash, string actor, DateTimeOffset now, CancellationToken cancellationToken);

    Task DeleteAsync(DatabaseSession session, CancellationToken cancellationToken);
}

/// <summary>Everything the config window shows (AD-012).</summary>
/// <remarks><see cref="History"/> is one page (newest first); <see cref="OlderBefore"/> is the cursor of the next page, if any.</remarks>
internal sealed record ConfigState(int CurrentVersion, RemoteConfigDocument Current, PublishedConfig? Published, ConfigDraft? Draft,
    IReadOnlyList<ConfigChange> DraftChanges, IReadOnlyList<PublishedConfig> History, InstallReach Reach, string? ActiveOverride, int? OlderBefore = null);

/// <summary>Use case: read the window's state, including the install reach of the last 7 days.</summary>
internal sealed class ReadConfig(IAdminDatabase database, IRemoteConfigAdmin config, IConfigDraftStore drafts, IIdentityAdminReads installs, TimeProvider clock)
{
    /// <summary>History page size. Every version stays reachable through the older-versions cursor (AD-006).</summary>
    public const int HistoryPage = 20;

    public async Task<ConfigState> HandleAsync(CancellationToken cancellationToken) => await HandleAsync(null, cancellationToken);

    /// <summary>The window's state with the history page of versions below <paramref name="historyBefore"/> (newest when null).</summary>
    public async Task<ConfigState> HandleAsync(int? historyBefore, CancellationToken cancellationToken)
    {
        await using var session = await database.BeginAsync(cancellationToken);
        var published = await config.CurrentAsync(session, cancellationToken);
        var current = published?.Document ?? config.Defaults;
        var draft = await drafts.GetAsync(session, false, cancellationToken);
        var page = await config.HistoryAsync(session, HistoryPage + 1, historyBefore, cancellationToken);
        var history = page.Take(HistoryPage).ToArray();
        var reach = InstallReach.From(await installs.InstallsAsync(clock.GetUtcNow() - InstallReach.Window, cancellationToken));
        return new ConfigState(published?.Version ?? 0, current, published, draft, draft is null ? [] : ConfigDiff.Compute(current, draft.Document),
            history, reach, config.ActiveOverride, page.Count > HistoryPage ? history[^1].Version : null);
    }

    /// <summary>One published version, however old (the rollback review), or null when it doesn't exist.</summary>
    public async Task<PublishedConfig?> VersionAsync(int version, CancellationToken cancellationToken)
    {
        await using var session = await database.BeginAsync(cancellationToken);
        return await config.VersionAsync(session, version, cancellationToken);
    }
}

/// <summary>Use case: save the draft (operator). It must pass the same rules as a publish; saving is audited.</summary>
internal sealed class SaveConfigDraft(IAdminDatabase database, IRemoteConfigAdmin config, IConfigDraftStore drafts, IAuditLog audit, TimeProvider clock)
{
    public async Task<IReadOnlyList<string>> HandleAsync(AdminPrincipal principal, RemoteConfigDocument document, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        var now = clock.GetUtcNow();
        await using var session = await database.BeginAsync(cancellationToken);
        var published = await config.CurrentAsync(session, cancellationToken);
        var errors = RemoteConfigRules.Validate(document, published?.Document ?? config.Defaults);
        if (errors.Count > 0) { return errors; }
        var hash = ConfigDiff.Hash(document);
        var revision = await drafts.SaveAsync(session, published?.Version ?? 0, document, hash, principal.Handle, now, cancellationToken);
        await audit.AppendAsync(session, new AuditEntry(principal.Handle, "config", "save-draft", "ok", "revision " + revision.ToString(CultureInfo.InvariantCulture),
            AfterJson: document.ToJson()), now, cancellationToken);
        await session.CommitAsync(cancellationToken);
        return [];
    }
}

/// <summary>Use case: discard the draft (operator), audited.</summary>
internal sealed class DiscardConfigDraft(IAdminDatabase database, IConfigDraftStore drafts, IAuditLog audit, TimeProvider clock)
{
    public async Task HandleAsync(AdminPrincipal principal, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        await using var session = await database.BeginAsync(cancellationToken);
        await drafts.DeleteAsync(session, cancellationToken);
        await audit.AppendAsync(session, new AuditEntry(principal.Handle, "config", "discard-draft", "ok"), clock.GetUtcNow(), cancellationToken);
        await session.CommitAsync(cancellationToken);
    }
}

/// <summary>A publish or rollback outcome; anything but <see cref="Published"/> changed nothing.</summary>
internal enum PublishStatus
{
    Published,
    NoDraft,
    DraftChanged,
    Stale,
    Invalid,
    NoActiveInstalls,
    AboveNewestReported,
    TypedVersionMismatch,
    NeedsRecentSignIn,
    UnknownVersion,
}

internal sealed record PublishOutcome(PublishStatus Status, int? Version = null, IReadOnlyList<string>? Errors = null);

/// <summary>What the operator reviewed and confirmed (R#3): the exact draft and, for a raise, the typed new minimum.</summary>
internal sealed record PublishRequest(int BaseVersion, long Revision, string Hash, string Reason, string? TypedVersion);

/// <summary>
/// Use case: publish the reviewed draft (AD-006, B23 P1). One transaction: lock the draft, check its revision and hash, check the
/// minimum-version ceiling and confirmations, publish the next version (Account, same session), write the audit row with
/// before/after, delete the draft, commit. Refusals change nothing and are audited with their reason.
/// </summary>
internal sealed class PublishConfig(IAdminDatabase database, IRemoteConfigAdmin config, IConfigDraftStore drafts, IIdentityAdminReads installs,
    IAuditLog audit, TimeProvider clock)
{
    public async Task<PublishOutcome> HandleAsync(AdminPrincipal principal, PublishRequest request, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        ArgumentNullException.ThrowIfNull(request);
        var now = clock.GetUtcNow();
        var reach = InstallReach.From(await installs.InstallsAsync(now - InstallReach.Window, cancellationToken));
        await using var session = await database.BeginAsync(cancellationToken);
        var draft = await drafts.GetAsync(session, true, cancellationToken);
        PublishOutcome outcome;
        if (draft is null) { outcome = new(PublishStatus.NoDraft); }
        else if (draft.Revision != request.Revision || draft.Hash != request.Hash || draft.BaseVersion != request.BaseVersion) { outcome = new(PublishStatus.DraftChanged); }
        else
        {
            outcome = await ConfigPublishing.PublishAsync(session, config, audit, principal, draft.Document, request.BaseVersion, request.Reason,
                request.TypedVersion, null, reach, "publish", now, cancellationToken);
            if (outcome.Status == PublishStatus.Published)
            {
                await drafts.DeleteAsync(session, cancellationToken);
                await session.CommitAsync(cancellationToken);
                return outcome;
            }
        }
        await session.DisposeAsync();
        await ConfigPublishing.AuditRefusalAsync(database, audit, principal, "publish", outcome.Status, now, cancellationToken);
        return outcome;
    }
}

/// <summary>Use case: roll back to version K = publish a new version with K's document (AD-006), same checks and audit.</summary>
internal sealed class RollbackConfig(IAdminDatabase database, IRemoteConfigAdmin config, IIdentityAdminReads installs, IAuditLog audit, TimeProvider clock)
{
    public async Task<PublishOutcome> HandleAsync(AdminPrincipal principal, int target, int expectedVersion, string reason, string? typedVersion,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        var now = clock.GetUtcNow();
        var reach = InstallReach.From(await installs.InstallsAsync(now - InstallReach.Window, cancellationToken));
        await using var session = await database.BeginAsync(cancellationToken);
        var version = await config.VersionAsync(session, target, cancellationToken);
        var outcome = version is null ? new PublishOutcome(PublishStatus.UnknownVersion)
            : await ConfigPublishing.PublishAsync(session, config, audit, principal, version.Document, expectedVersion, reason, typedVersion, target, reach,
                "rollback", now, cancellationToken);
        if (outcome.Status == PublishStatus.Published)
        {
            await session.CommitAsync(cancellationToken);
            return outcome;
        }
        await session.DisposeAsync();
        await ConfigPublishing.AuditRefusalAsync(database, audit, principal, "rollback", outcome.Status, now, cancellationToken);
        return outcome;
    }
}

internal static class ConfigPublishing
{
    public static async Task<PublishOutcome> PublishAsync(DatabaseSession session, IRemoteConfigAdmin config, IAuditLog audit, AdminPrincipal principal,
        RemoteConfigDocument document, int expectedVersion, string reason, string? typedVersion, int? rolledBackFrom, InstallReach reach, string action,
        DateTimeOffset now, CancellationToken cancellationToken)
    {
        var current = await config.CurrentAsync(session, cancellationToken);
        if ((current?.Version ?? 0) != expectedVersion) { return new(PublishStatus.Stale); }
        var before = current?.Document ?? config.Defaults;
        if (InstallReach.Raises(before.MinimumAppVersion, document.MinimumAppVersion) && AppVersion.TryParse(document.MinimumAppVersion, out var minimum))
        {
            switch (reach.CheckRaise(minimum))
            {
                case CeilingRefusal.NoActiveInstalls: return new(PublishStatus.NoActiveInstalls);
                case CeilingRefusal.AboveNewestReported: return new(PublishStatus.AboveNewestReported);
            }
            if (!string.Equals(typedVersion?.Trim(), document.MinimumAppVersion, StringComparison.Ordinal)) { return new(PublishStatus.TypedVersionMismatch); }
            if (!principal.SignedInRecently(now)) { return new(PublishStatus.NeedsRecentSignIn); }
        }
        var result = await config.PublishAsync(session, document, expectedVersion, principal.Handle, reason, rolledBackFrom, now, cancellationToken);
        if (result.IsFailure)
        {
            return result.Error.Kind == ErrorKind.VersionConflict ? new(PublishStatus.Stale)
                : new(PublishStatus.Invalid, Errors: result.Error.FieldErrors?.SelectMany(pair => pair.Value).ToArray() ?? []);
        }
        await audit.AppendAsync(session, new AuditEntry(principal.Handle, "config", action, "ok", "version " + result.Value.Version.ToString(CultureInfo.InvariantCulture),
            before.ToJson(), document.ToJson(), reason.Trim()), now, cancellationToken);
        return new(PublishStatus.Published, result.Value.Version);
    }

    public static async Task AuditRefusalAsync(IAdminDatabase database, IAuditLog audit, AdminPrincipal principal, string action, PublishStatus status,
        DateTimeOffset now, CancellationToken cancellationToken)
    {
        await using var session = await database.BeginAsync(cancellationToken);
        await audit.AppendAsync(session, new AuditEntry(principal.Handle, "config", action, Code(status)), now, cancellationToken);
        await session.CommitAsync(cancellationToken);
    }

    public static string Code(PublishStatus status) => status switch
    {
        PublishStatus.NoDraft => "no-draft",
        PublishStatus.DraftChanged => "draft-changed",
        PublishStatus.Stale => "stale",
        PublishStatus.Invalid => "invalid",
        PublishStatus.NoActiveInstalls => "no-active-installs",
        PublishStatus.AboveNewestReported => "above-newest-reported",
        PublishStatus.TypedVersionMismatch => "typed-version-mismatch",
        PublishStatus.NeedsRecentSignIn => "needs-recent-sign-in",
        PublishStatus.UnknownVersion => "unknown-version",
        _ => "ok",
    };
}
