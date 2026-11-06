using System.Globalization;
using System.Text.RegularExpressions;
using FitnessBuddy.Modules.Admin.Domain;

namespace FitnessBuddy.Modules.Admin.Application;

/// <summary>An audit row read back (AD-016).</summary>
internal sealed record AuditRecord(long Id, DateTimeOffset OccurredAt, string Actor, string Area, string Action, string? Target, string Outcome,
    string? Reason, string? BeforeJson, string? AfterJson);

/// <summary>Validated filters: area, actor and a UTC day range. Unknown shapes are dropped, never put in SQL text.</summary>
internal sealed partial record AuditFilter(string? Area, string? Actor, DateTimeOffset? From, DateTimeOffset? Until)
{
    public static (AuditFilter Filter, bool Dropped) Parse(string? area, string? actor, string? from, string? to)
    {
        var dropped = false;
        string? Keep(string? value, Regex pattern)
        {
            if (string.IsNullOrWhiteSpace(value)) { return null; }
            if (pattern.IsMatch(value.Trim())) { return value.Trim(); }
            dropped = true;
            return null;
        }
        DateTimeOffset? Day(string? value, int addDays)
        {
            if (string.IsNullOrWhiteSpace(value)) { return null; }
            if (DateOnly.TryParseExact(value.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var day))
            {
                return new DateTimeOffset(day.AddDays(addDays).ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
            }
            dropped = true;
            return null;
        }
        return (new AuditFilter(Keep(area, Code()), Keep(actor, Code()), Day(from, 0), Day(to, 1)), dropped);
    }

    [GeneratedRegex("^[a-z][a-z0-9-]{0,63}$", RegexOptions.CultureInvariant)]
    private static partial Regex Code();
}

internal interface IAuditReader
{
    /// <summary>Newest first; <paramref name="beforeId"/> is the paging cursor.</summary>
    Task<IReadOnlyList<AuditRecord>> QueryAsync(AuditFilter filter, long? beforeId, int limit, CancellationToken cancellationToken);
}

/// <summary>Use case: one page of the audit log, newest first.</summary>
internal sealed class ListAudit(IAuditReader reader)
{
    public const int PageSize = 50;

    public async Task<(IReadOnlyList<AuditRecord> Rows, long? Next)> HandleAsync(AuditFilter filter, long? cursor, CancellationToken cancellationToken)
    {
        var rows = await reader.QueryAsync(filter, cursor, PageSize + 1, cancellationToken);
        return rows.Count > PageSize ? (rows.Take(PageSize).ToArray(), rows[PageSize - 1].Id) : (rows, null);
    }
}

/// <summary>Use case: export the filtered audit log as CSV (at most 10 000 rows). The export itself is audited.</summary>
internal sealed class ExportAudit(IAuditReader reader, IAdminDatabase database, IAuditLog audit, TimeProvider clock)
{
    public const int MaxRows = 10_000;

    public async Task<string> HandleAsync(AdminPrincipal principal, AuditFilter filter, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(principal);
        var rows = await reader.QueryAsync(filter, null, MaxRows, cancellationToken);
        var csv = AuditCsv.Start();
        foreach (var row in rows)
        {
            csv.Append(AuditCsv.Line([row.Id.ToString(CultureInfo.InvariantCulture), AuditCsv.Time(row.OccurredAt), row.Actor, row.Area, row.Action,
                row.Target, row.Outcome, row.Reason, row.BeforeJson, row.AfterJson]));
        }
        await using var session = await database.BeginAsync(cancellationToken);
        await audit.AppendAsync(session, new AuditEntry(principal.Handle, "audit", "export", "ok", rows.Count.ToString(CultureInfo.InvariantCulture) + " rows"),
            clock.GetUtcNow(), cancellationToken);
        await session.CommitAsync(cancellationToken);
        return csv.ToString();
    }
}
