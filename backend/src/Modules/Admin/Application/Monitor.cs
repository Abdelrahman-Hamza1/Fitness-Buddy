using FitnessBuddy.BuildingBlocks.Features;
using FitnessBuddy.BuildingBlocks.Ops;
using FitnessBuddy.Modules.Account.Contracts;
using FitnessBuddy.Modules.Admin.Domain;
using FitnessBuddy.Modules.Catalog.Contracts;
using FitnessBuddy.Modules.Identity.Contracts;
using FitnessBuddy.Modules.Usage.Contracts;
using FitnessBuddy.Modules.UserData.Contracts;

namespace FitnessBuddy.Modules.Admin.Application;

/// <summary>Everything the Overview shows (AD-010). Counts only: no user content, no emails.</summary>
internal sealed record OverviewState(
    bool? ApiReady,
    BackupState? Backup,
    IReadOnlyList<WorkerBeat> Workers,
    CatalogReleaseInfo? CurrentRelease,
    bool BuddyOn,
    long BuddyCallsToday,
    IReadOnlyDictionary<int, long> InstallsByDays,
    IReadOnlyList<InstallCount> Versions30Days,
    IReadOnlyList<AccountTypeCount> Accounts,
    IReadOnlyList<ServerErrorCount> ServerErrors24h,
    UsageTotals SpendThisMonth,
    IReadOnlyList<OverviewAlert> Alerts,
    string? GrafanaUrl,
    string? SentryUrl);

/// <summary>Use case: read the Overview. Each source is a content-free module contract (B23 P4).</summary>
internal sealed class ReadOverview(IApiHealth api, IBackupStatus backups, IOpsAdministration ops, ICatalogAdminReads catalog, IIdentityAdminReads identity,
    IUsageAdminReads usage, IRemoteConfigAdmin config, IFeatureFlags flags, Microsoft.Extensions.Options.IOptions<AdminOptions> options, TimeProvider clock)
{
    public static readonly int[] InstallWindows = [1, 7, 30];

    public async Task<OverviewState> HandleAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow();
        var today = DateOnly.FromDateTime(now.UtcDateTime);
        var ready = await api.ReadyAsync(cancellationToken);
        var backup = backups.Read();
        var workers = await ops.HeartbeatsAsync(cancellationToken);
        var queues = await ops.QueuesAsync(now, cancellationToken);
        var current = (await catalog.ReleasesAsync(cancellationToken)).FirstOrDefault(release => release.Current);
        var installs = new Dictionary<int, long>();
        IReadOnlyList<InstallCount> versions = [];
        foreach (var days in InstallWindows)
        {
            var rows = await identity.InstallsAsync(now.AddDays(-days), cancellationToken);
            installs[days] = rows.Sum(row => row.Installs);
            versions = rows;
        }
        var errors = await ops.ServerErrorsAsync(now.AddHours(-24), cancellationToken);
        var facts = new OverviewFacts(ready, backup is not null, backup?.CompletedAt, backup?.Ok == true,
            workers.Count == 0 ? null : workers.Max(worker => worker.LastBeatAt), queues.Sum(queue => queue.Dead),
            queues.Where(queue => !queue.Paused && queue.OldestDueAt is not null).Select(queue => queue.OldestDueAt).Min(),
            errors.Sum(error => error.Errors), config.ActiveOverride is not null, current is not null);
        var links = options.Value;
        return new OverviewState(ready, backup, workers, current, flags.IsEnabled("buddy.ai"),
            (await usage.SpendAsync(today, today, cancellationToken)).Calls, installs,
            [.. versions.OrderByDescending(row => row.Installs)], await identity.AccountsByTypeAsync(cancellationToken), errors,
            await usage.SpendAsync(new DateOnly(today.Year, today.Month, 1), today, cancellationToken), OverviewAlerts.Evaluate(facts, now),
            links.GrafanaUrl.Length > 0 ? links.GrafanaUrl : null, links.SentryUrl.Length > 0 ? links.SentryUrl : null);
    }
}

/// <summary>One account row (AD-011): identity facts, sync and storage, AI uses in 30 days.</summary>
internal sealed record AccountRow(AdminAccount Account, UserSyncStats? Sync, long AiUses30Days);

/// <summary>A filtered page of accounts and the cursor of the next one: <paramref name="Next"/> (newest first) or
/// <paramref name="NextIssue"/> (sync issues, most rejects first). <paramref name="ScanLimited"/>: the issue scan stopped at its
/// bound before filling the page, so more matches may follow the cursor.</summary>
internal sealed record AccountList(IReadOnlyList<AccountRow> Rows, Guid? Next, UserRejects? NextIssue = null, bool ScanLimited = false);

internal sealed record AccountFilter(string? Type, bool SyncIssues)
{
    public static readonly string[] Types = ["guest", "google", "email", "registered"];

    public static AccountFilter Parse(string? type, string? issues) =>
        new(type is not null && Types.Contains(type, StringComparer.Ordinal) ? type : null, issues == "1");
}

/// <summary>Use case: list accounts newest first, by type, or those with sync rejects in the last 7 days first (AD-011).</summary>
internal sealed class ListAccounts(IIdentityAdminReads identity, IUserDataAdminReads userData, IUsageAdminReads usage, TimeProvider clock)
{
    public const int PageSize = 50;
    public static readonly TimeSpan IssueWindow = TimeSpan.FromDays(7);

    /// <summary>Accounts with issues are read in batches of this size and filtered by type until the page is full (B23b review)…</summary>
    public const int IssueBatch = 200;

    /// <summary>…scanning at most this many per request; past it the page says so and the cursor continues the scan.</summary>
    public const int IssueScanLimit = 2000;

    public async Task<AccountList> HandleAsync(AccountFilter filter, Guid? before, UserRejects? afterIssue, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(filter);
        var today = DateOnly.FromDateTime(clock.GetUtcNow().UtcDateTime);
        if (filter.SyncIssues) { return await IssuesAsync(filter, afterIssue, today, cancellationToken); }
        var page = await identity.AccountPageAsync(filter.Type, before, PageSize + 1, cancellationToken);
        IReadOnlyList<AdminAccount> accounts = [.. page.Take(PageSize)];
        Guid? next = page.Count > PageSize ? accounts[^1].Id : null;
        return new AccountList(await RowsAsync(accounts, userData, usage, today, cancellationToken), next);
    }

    /// <summary>Both filters apply before the page is cut: issue batches are filtered by type until a page and one more match
    /// are found, the issues run out, or the scan bound is reached.</summary>
    private async Task<AccountList> IssuesAsync(AccountFilter filter, UserRejects? after, DateOnly today, CancellationToken cancellationToken)
    {
        var since = today.AddDays(-(int)IssueWindow.TotalDays);
        var matches = new List<(AdminAccount Account, UserRejects Issue)>();
        var cursor = after;
        var scanned = 0;
        var exhausted = false;
        while (matches.Count <= PageSize && scanned < IssueScanLimit)
        {
            var batch = await userData.UsersWithIssuesAsync(since, IssueBatch, cursor, cancellationToken);
            scanned += batch.Count;
            exhausted = batch.Count < IssueBatch;
            if (batch.Count == 0) { break; }
            var byId = (await identity.AccountsAsync([.. batch.Select(issue => issue.UserId)], cancellationToken)).ToDictionary(account => account.Id);
            foreach (var issue in batch)
            {
                if (byId.TryGetValue(issue.UserId, out var account) && (filter.Type is null || account.Type == filter.Type)) { matches.Add((account, issue)); }
            }
            cursor = batch[^1];
            if (exhausted) { break; }
        }
        var shown = matches.Take(PageSize).ToArray();
        // More matches than a page: continue after the last one shown. Scan bound hit first: continue after the last one scanned.
        var (nextIssue, limited) = matches.Count > PageSize ? (shown[^1].Issue, false) : !exhausted && cursor is not null ? (cursor, true) : (null, false);
        return new AccountList(await RowsAsync([.. shown.Select(match => match.Account)], userData, usage, today, cancellationToken), null, nextIssue, limited);
    }

    internal static async Task<IReadOnlyList<AccountRow>> RowsAsync(IReadOnlyList<AdminAccount> accounts, IUserDataAdminReads userData, IUsageAdminReads usage,
        DateOnly today, CancellationToken cancellationToken)
    {
        var ids = accounts.Select(account => account.Id).ToArray();
        var stats = (await userData.StatsAsync(ids, today.AddDays(-(int)IssueWindow.TotalDays), cancellationToken)).ToDictionary(row => row.UserId);
        var uses = await usage.UsesAsync(ids, today.AddDays(-30), cancellationToken);
        return [.. accounts.Select(account => new AccountRow(account, stats.GetValueOrDefault(account.Id), uses.GetValueOrDefault(account.Id)))];
    }
}

/// <summary>One account's detail (AD-011 read): its row, documents per entity type and devices (no device ids).</summary>
internal sealed record AccountDetail(AccountRow Row, IReadOnlyList<EntityCount> Documents, IReadOnlyList<AdminDevice> Devices);

/// <summary>Use case: read one account by its pseudonymous id; null when it doesn't exist.</summary>
internal sealed class ReadAccount(IIdentityAdminReads identity, IUserDataAdminReads userData, IUsageAdminReads usage, TimeProvider clock)
{
    public async Task<AccountDetail?> HandleAsync(Guid id, CancellationToken cancellationToken)
    {
        var account = (await identity.AccountsAsync([id], cancellationToken)).SingleOrDefault();
        if (account is null) { return null; }
        var now = clock.GetUtcNow();
        var row = (await ListAccounts.RowsAsync([account], userData, usage, DateOnly.FromDateTime(now.UtcDateTime), cancellationToken))[0];
        return new AccountDetail(row, await userData.DocumentsAsync(id, cancellationToken), await identity.DevicesAsync(id, now, cancellationToken));
    }
}

/// <summary>The lookup's answer: the account when exactly one matches, and whether email sign-in accounts were searched.</summary>
internal sealed record EmailFindResult(Guid? Match, bool EmailSignInSearched);

/// <summary>
/// Use case: find an account by its exact email (AD-002). Returns the account id when exactly one account matches. Email sign-in
/// accounts are found through Identity's keyed address hash, so only when the console has Identity's lookup key; the result says
/// when they weren't searched. Audited with the outcome only: the term is never stored, logged or put in a URL (the form posts it).
/// </summary>
internal sealed class FindAccountByEmail(IIdentityAdminReads identity, IAdminDatabase database, IAuditLog audit, TimeProvider clock)
{
    public const int MaxLength = 320;

    public async Task<EmailFindResult> HandleAsync(AdminPrincipal principal, string? email, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        var term = email?.Trim() ?? "";
        var lookup = term.Length is >= 3 and <= MaxLength && term.Contains('@', StringComparison.Ordinal)
            ? await identity.FindByEmailAsync(term, cancellationToken) : null;
        Guid? match = lookup?.Accounts.Count == 1 ? lookup.Accounts[0] : null;
        // "no-match-partial": nothing found, and email sign-in accounts couldn't be searched (no lookup key).
        var outcome = match is not null ? "match" : lookup is { EmailSignInSearched: false } ? "no-match-partial" : "no-match";
        await using var session = await database.BeginAsync(cancellationToken);
        await audit.AppendAsync(session, new AuditEntry(principal.Handle, "accounts", "find-by-email", outcome, match?.ToString()), clock.GetUtcNow(), cancellationToken);
        await session.CommitAsync(cancellationToken);
        return new EmailFindResult(match, lookup?.EmailSignInSearched ?? true);
    }
}
