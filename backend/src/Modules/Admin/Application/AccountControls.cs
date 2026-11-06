using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Admin.Domain;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.Usage.Contracts;
using Microsoft.Extensions.Logging;

namespace FitnessBuddy.Modules.Admin.Application;

/// <summary>A control's outcome; anything but <see cref="Done"/> changed nothing.</summary>
internal enum ControlOutcome
{
    Done,
    NotFound,
    NeedsRecentSignIn,
    TypedIdMismatch,
    InvalidReason,
    InvalidLimit,
    UnknownDevice,
    DeletionPending,
}

/// <summary>What the controls panel shows for one account (AD-011): codes, counts, timestamps, opaque device keys.</summary>
internal sealed record AccountControlsState(Guid Account, AccountControlState State, IReadOnlyList<ControlDevice> Devices, int? BuddyLimit);

/// <summary>Use case: read an account's control state; null when the account doesn't exist (deleted or never existed).</summary>
internal sealed class ReadAccountControls(IAdminDatabase database, IIdentityAdminControls identity, IUsageAdminControls usage, TimeProvider clock)
{
    public async Task<AccountControlsState?> HandleAsync(Guid account, CancellationToken cancellationToken)
    {
        await using var session = await database.BeginAsync(cancellationToken);
        var state = await identity.StateAsync(session, account, cancellationToken);
        if (state is null) { return null; }
        var devices = await identity.DevicesAsync(session, account, clock.GetUtcNow(), cancellationToken);
        var limit = await usage.DailyLimitAsync(session, account, cancellationToken);
        return new AccountControlsState(account, state, devices, limit);
    }
}

/// <summary>Use case: revoke one device's sessions (operator). Its next request gets 401.</summary>
internal sealed class RevokeDevice(AccountControlRunner runner, IIdentityAdminControls identity)
{
    public Task<ControlOutcome> HandleAsync(AdminPrincipal principal, Guid account, string? deviceKey, string? reason, CancellationToken cancellationToken) =>
        !AccountControlRules.IsDeviceKey(deviceKey)
            ? runner.RefuseAsync(principal, "revoke-device", account, reason, ControlOutcome.UnknownDevice, cancellationToken)
            : runner.RunAsync(principal, "revoke-device", account, reason, null, false, async (session, now) =>
            {
                var result = await identity.RevokeAsync(session, account, deviceKey, now, cancellationToken);
                if (result is null) { return ControlStep.Refused(ControlOutcome.NotFound); }
                return result.DeviceFound
                    ? ControlStep.Done(null, new { device = deviceKey, revoked = result.RevokedSessions })
                    : ControlStep.Refused(ControlOutcome.UnknownDevice);
            }, cancellationToken);
}

/// <summary>Use case: revoke every device (operator, AD-007: typed account id + recent sign-in).</summary>
internal sealed class RevokeAllDevices(AccountControlRunner runner, IIdentityAdminControls identity)
{
    public Task<ControlOutcome> HandleAsync(AdminPrincipal principal, Guid account, string? reason, string? typedId, CancellationToken cancellationToken) =>
        runner.RunAsync(principal, "revoke-all", account, reason, typedId, true, async (session, now) =>
        {
            var result = await identity.RevokeAsync(session, account, null, now, cancellationToken);
            return result is null ? ControlStep.Refused(ControlOutcome.NotFound) : ControlStep.Done(null, new { revoked = result.RevokedSessions });
        }, cancellationToken);
}

/// <summary>Use case: disable (operator, AD-007) or enable (operator) an account. Enabling is refused while a deletion is pending.</summary>
internal sealed class SetAccountDisabled(AccountControlRunner runner, IIdentityAdminControls identity)
{
    public Task<ControlOutcome> HandleAsync(AdminPrincipal principal, Guid account, bool disabled, string? reason, string? typedId,
        CancellationToken cancellationToken) =>
        runner.RunAsync(principal, disabled ? "disable" : "enable", account, reason, typedId, disabled, async (session, now) =>
        {
            var result = await identity.SetDisabledAsync(session, account, disabled, now, cancellationToken);
            if (result is null) { return ControlStep.Refused(ControlOutcome.NotFound); }
            if (result.DeletionPending) { return ControlStep.Refused(ControlOutcome.DeletionPending); }
            return ControlStep.Done(new { disabled = result.WasDisabled }, new { disabled, revoked = result.RevokedSessions });
        }, cancellationToken);
}

/// <summary>Use case: set or clear the account's Buddy daily limit (operator). Identity's lock and revalidation come first (R#2).</summary>
internal sealed class SetBuddyLimit(AccountControlRunner runner, IIdentityAdminControls identity, IUsageAdminControls usage)
{
    public Task<ControlOutcome> HandleAsync(AdminPrincipal principal, Guid account, string? limit, string? reason, CancellationToken cancellationToken)
    {
        if (!AccountControlRules.TryParseLimit(limit, out var dailyCalls))
        {
            return runner.RefuseAsync(principal, "buddy-limit", account, reason, ControlOutcome.InvalidLimit, cancellationToken);
        }
        return runner.RunAsync(principal, "buddy-limit", account, reason, null, false, async (session, now) =>
        {
            if (await identity.LockAsync(session, account, cancellationToken) is null) { return ControlStep.Refused(ControlOutcome.NotFound); }
            var previous = await usage.SetDailyLimitAsync(session, account, dailyCalls, now, cancellationToken);
            return ControlStep.Done(new { dailyCalls = previous }, new { dailyCalls });
        }, cancellationToken);
    }
}

/// <summary>
/// Use case: delete an account (operator, AD-007). Disables it, revokes every session and records the deletion intent in this
/// transaction; the api role's runner then runs the app's own deletion (AC-031, B06) within seconds.
/// </summary>
internal sealed class RequestAccountDeletion(AccountControlRunner runner, IIdentityAdminControls identity)
{
    public Task<ControlOutcome> HandleAsync(AdminPrincipal principal, Guid account, string? reason, string? typedId, CancellationToken cancellationToken) =>
        runner.RunAsync(principal, "delete", account, reason, typedId, true, async (session, now) =>
        {
            var result = await identity.RequestDeletionAsync(session, account, now, cancellationToken);
            return result is null ? ControlStep.Refused(ControlOutcome.NotFound)
                : ControlStep.Done(new { disabled = result.WasDisabled }, new { deletion = "requested", revoked = result.RevokedSessions, created = result.Created });
        }, cancellationToken);
}

/// <summary>One step's result: done with its before/after (codes and numbers only), or a refusal.</summary>
internal sealed record ControlStep(ControlOutcome Outcome, object? Before, object? After)
{
    public static ControlStep Done(object? before, object? after) => new(ControlOutcome.Done, before, after);

    public static ControlStep Refused(ControlOutcome outcome) => new(outcome, null, null);
}

/// <summary>
/// The shared transaction shape of every account control (AD-005, AD-007): check the reason code, and for a destructive control
/// the typed account id and a sign-in under 15 minutes; then one console session: the module call (which takes the account's
/// lifecycle lock first), the audit row, commit. A refusal changes nothing and is audited with its code in its own transaction.
/// </summary>
internal sealed partial class AccountControlRunner(IAdminDatabase database, IAuditLog audit, TimeProvider clock, ILogger<AccountControlRunner> logger)
{
    public const string Area = "accounts";

    public static string Target(Guid account) => "account " + account.ToString("D");

    /// <summary>Runs one control. <c>confirm</c> marks AD-007's destructive controls (revoke all, disable, delete): typed id + recent sign-in.</summary>
    public async Task<ControlOutcome> RunAsync(AdminPrincipal principal, string action, Guid account, string? reason, string? typedId, bool confirm,
        Func<DatabaseSession, DateTimeOffset, Task<ControlStep>> step, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        ArgumentNullException.ThrowIfNull(step);
        var now = clock.GetUtcNow();
        // A stale sign-in comes first: the operator re-authenticates whatever else the form holds, and it's audited (review minor 3).
        ControlOutcome? refusal = confirm && !principal.SignedInRecently(now) ? ControlOutcome.NeedsRecentSignIn
            : !AccountControlRules.IsReason(reason) ? ControlOutcome.InvalidReason
            : confirm && !AccountControlRules.TypedIdMatches(typedId, account) ? ControlOutcome.TypedIdMismatch
            : null;
        if (refusal is null)
        {
            await using var session = await database.BeginAsync(cancellationToken);
            var result = await step(session, now);
            if (result.Outcome == ControlOutcome.Done)
            {
                await audit.AppendAsync(session, new AuditEntry(principal.Handle, Area, action, "ok", Target(account),
                    Json(result.Before), Json(result.After), reason), now, cancellationToken);
                await session.CommitAsync(cancellationToken);
                LogControl(logger, action, "ok");
                return ControlOutcome.Done;
            }
            refusal = result.Outcome;
        }
        return await RefuseAsync(principal, action, account, reason, refusal.Value, cancellationToken);
    }

    public async Task<ControlOutcome> RefuseAsync(AdminPrincipal principal, string action, Guid account, string? reason, ControlOutcome refusal,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        await using var session = await database.BeginAsync(cancellationToken);
        await audit.AppendAsync(session, new AuditEntry(principal.Handle, Area, action, Code(refusal), Target(account),
            Reason: AccountControlRules.IsReason(reason) ? reason : null), clock.GetUtcNow(), cancellationToken);
        await session.CommitAsync(cancellationToken);
        var code = Code(refusal);
        LogControl(logger, action, code);
        return refusal;
    }

    public static string Code(ControlOutcome outcome) => outcome switch
    {
        ControlOutcome.NotFound => "not-found",
        ControlOutcome.NeedsRecentSignIn => "needs-recent-sign-in",
        ControlOutcome.TypedIdMismatch => "typed-id-mismatch",
        ControlOutcome.InvalidReason => "invalid-reason",
        ControlOutcome.InvalidLimit => "invalid-limit",
        ControlOutcome.UnknownDevice => "unknown-device",
        ControlOutcome.DeletionPending => "deletion-pending",
        _ => "ok",
    };

    private static string? Json(object? value) => value is null ? null : JsonSerializer.Serialize(value);

    // The action and outcome codes only: never the account id, the device key or the typed text.
    [LoggerMessage(Level = LogLevel.Information, Message = "Account control {Action}: {Outcome}")]
    private static partial void LogControl(ILogger logger, string action, string outcome);
}
