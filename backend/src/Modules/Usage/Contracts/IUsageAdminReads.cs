namespace FitnessBuddy.Modules.Usage.Contracts;

/// <summary>Content-free AI usage totals for the admin console (B23, owner O1, TD-118): calls, messages and estimated cost only.</summary>
public interface IUsageAdminReads
{
    /// <summary>Totals for the UTC days <paramref name="first"/> to <paramref name="last"/> (inclusive).</summary>
    Task<UsageTotals> SpendAsync(DateOnly first, DateOnly last, CancellationToken cancellationToken);

    /// <summary>Calls per account (at most 200) since <paramref name="since"/>; accounts without calls are absent.</summary>
    Task<IReadOnlyDictionary<Guid, long>> UsesAsync(IReadOnlyCollection<Guid> users, DateOnly since, CancellationToken cancellationToken);
}

public sealed record UsageTotals(long Calls, long Messages, decimal EstimatedUsd);
