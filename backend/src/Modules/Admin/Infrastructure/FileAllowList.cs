using System.Text.Json;
using System.Text.RegularExpressions;
using FitnessBuddy.Modules.Admin.Application;
using FitnessBuddy.Modules.Admin.Domain;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Admin.Infrastructure;

/// <summary>
/// The allow-list from the private file at <c>Admin:AllowListFile</c> (B23 P2: config/secret, never the DB). Re-read when the
/// file's timestamp or size changes, checked at most every 10 s. Any read or validation problem gives an invalid list: nobody
/// can sign in and existing sessions are refused (fail closed). Emails and subjects are never logged.
/// </summary>
internal sealed partial class FileAllowList(IOptions<AdminOptions> options, TimeProvider clock, ILogger<FileAllowList> logger) : IAllowList, IHealthCheck
{
    private static readonly TimeSpan RecheckInterval = TimeSpan.FromSeconds(10);
    private readonly Lock gate = new();
    private AllowListSnapshot snapshot = AllowListSnapshot.Invalid;
    private (DateTime Written, long Length)? version;
    private DateTimeOffset checkedAt = DateTimeOffset.MinValue;

    public AllowListSnapshot Current()
    {
        lock (gate)
        {
            var now = clock.GetUtcNow();
            if (version is not null && now - checkedAt < RecheckInterval) { return snapshot; }
            checkedAt = now;
            var path = options.Value.AllowListFile;
            try
            {
                var info = new FileInfo(path);
                if (!info.Exists) { return Replace(AllowListSnapshot.Invalid, null, "missing"); }
                var current = (info.LastWriteTimeUtc, info.Length);
                if (version == current) { return snapshot; }
                if (info.Length > 64 * 1024) { return Replace(AllowListSnapshot.Invalid, current, "too-large"); }
                var (parsed, reason) = Parse(File.ReadAllText(path));
                return Replace(parsed, current, reason);
            }
            catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
            {
                return Replace(AllowListSnapshot.Invalid, null, "unreadable");
            }
        }
    }

    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default) =>
        Task.FromResult(Current().IsValid ? HealthCheckResult.Healthy() : HealthCheckResult.Unhealthy("allow-list-invalid"));

    internal static (AllowListSnapshot Snapshot, string Reason) Parse(string json)
    {
        try
        {
            var file = JsonSerializer.Deserialize<AllowListFileModel>(json, JsonOptions);
            if (file?.Admins is null) { return (AllowListSnapshot.Invalid, "shape"); }
            var admins = new List<AllowListEntry>();
            foreach (var item in file.Admins)
            {
                if (item is null || !Handle(item.Handle) || !Role(item.Role, out var role) || !Email(item.Email)
                    || string.IsNullOrWhiteSpace(item.GoogleSubject) || item.GoogleSubject.Length > 255) { return (AllowListSnapshot.Invalid, "entry"); }
                admins.Add(new AllowListEntry(item.Handle!, item.GoogleSubject.Trim(), item.Email!.Trim(), role));
            }
            var pending = new List<PendingEntry>();
            foreach (var item in file.Pending ?? [])
            {
                if (item is null || !Handle(item.Handle) || !Role(item.Role, out var role) || !Email(item.Email)) { return (AllowListSnapshot.Invalid, "entry"); }
                pending.Add(new PendingEntry(item.Handle!, item.Email!.Trim(), role));
            }
            var handles = admins.Select(a => a.Handle).Concat(pending.Select(p => p.Handle)).ToArray();
            var emails = admins.Select(a => a.Email.ToUpperInvariant()).Concat(pending.Select(p => p.Email.ToUpperInvariant())).ToArray();
            if (handles.Distinct(StringComparer.Ordinal).Count() != handles.Length || emails.Distinct(StringComparer.Ordinal).Count() != emails.Length
                || admins.Select(a => a.GoogleSubject).Distinct(StringComparer.Ordinal).Count() != admins.Count)
            {
                return (AllowListSnapshot.Invalid, "duplicate");
            }
            return (new AllowListSnapshot(true, admins, pending), "ok");
        }
        catch (JsonException)
        {
            return (AllowListSnapshot.Invalid, "json");
        }
    }

    private AllowListSnapshot Replace(AllowListSnapshot value, (DateTime, long)? current, string reason)
    {
        var changed = snapshot.IsValid != value.IsValid || version != current;
        snapshot = value;
        version = current;
        if (changed)
        {
            if (value.IsValid) { LogLoaded(logger, value.Admins.Count, value.Pending.Count); }
            else { LogInvalid(logger, reason); }
        }
        return snapshot;
    }

    private static bool Handle(string? value) => value is not null && HandlePattern().IsMatch(value);

    private static bool Email(string? value) => value is { Length: > 2 and <= 254 } && value.Trim().LastIndexOf('@') is > 0 and var at && at < value.Trim().Length - 1;

    private static bool Role(string? value, out ConsoleRole role)
    {
        role = ConsoleRole.Viewer;
        switch (value)
        {
            case "viewer": return true;
            case "operator": role = ConsoleRole.Operator; return true;
            default: return false;
        }
    }

    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = false, PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

    [GeneratedRegex("^[a-z][a-z0-9-]{0,31}$", RegexOptions.CultureInvariant)]
    private static partial Regex HandlePattern();

    [LoggerMessage(Level = LogLevel.Information, Message = "Admin allow-list loaded: {Admins} admins, {Pending} pending")]
    private static partial void LogLoaded(ILogger logger, int admins, int pending);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Admin allow-list invalid ({Reason}); nobody can sign in")]
    private static partial void LogInvalid(ILogger logger, string reason);

    private sealed record AllowListFileModel(IReadOnlyList<AdminItem?>? Admins, IReadOnlyList<PendingItem?>? Pending);

    private sealed record AdminItem(string? Handle, string? GoogleSubject, string? Email, string? Role);

    private sealed record PendingItem(string? Handle, string? Email, string? Role);
}
