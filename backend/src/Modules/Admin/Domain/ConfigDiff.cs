using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using FitnessBuddy.BuildingBlocks.Clients;
using FitnessBuddy.Modules.Account.Contracts;
using FitnessBuddy.Modules.Identity.Contracts;

namespace FitnessBuddy.Modules.Admin.Domain;

/// <summary>Which part of the document a change is in; it decides the reach line (AD-006).</summary>
internal enum ConfigSection
{
    MinimumVersion,
    AppFlag,
    Threshold,
    ServerSwitch,
}

/// <summary>One changed key: <paramref name="Old"/> null = added, <paramref name="New"/> null = removed.</summary>
internal sealed record ConfigChange(ConfigSection Section, string Key, string? Old, string? New);

/// <summary>AD-006: the keys a draft adds, removes or changes against the current version, in a stable order.</summary>
internal static class ConfigDiff
{
    public static IReadOnlyList<ConfigChange> Compute(RemoteConfigDocument before, RemoteConfigDocument after)
    {
        ArgumentNullException.ThrowIfNull(before);
        ArgumentNullException.ThrowIfNull(after);
        var changes = new List<ConfigChange>();
        if (before.MinimumAppVersion != after.MinimumAppVersion)
        {
            changes.Add(new ConfigChange(ConfigSection.MinimumVersion, "minimumAppVersion", before.MinimumAppVersion, after.MinimumAppVersion));
        }
        Compare(changes, ConfigSection.AppFlag, before.FeatureFlags, after.FeatureFlags, Flag, StringComparer.Ordinal);
        Compare(changes, ConfigSection.Threshold, before.Thresholds, after.Thresholds, value => value.ToString("R", CultureInfo.InvariantCulture), StringComparer.Ordinal);
        Compare(changes, ConfigSection.ServerSwitch, before.ServerFlags, after.ServerFlags, Flag, StringComparer.OrdinalIgnoreCase);
        return changes;
    }

    /// <summary>The SHA-256 of the canonical JSON, as the publish form carries it (R#3).</summary>
    public static string Hash(RemoteConfigDocument document)
    {
        ArgumentNullException.ThrowIfNull(document);
        return Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(document.ToJson())));
    }

    private static string Flag(bool value) => value ? "on" : "off";

    private static void Compare<T>(List<ConfigChange> changes, ConfigSection section, IReadOnlyDictionary<string, T> before, IReadOnlyDictionary<string, T> after,
        Func<T, string> show, StringComparer comparer)
    {
        foreach (var key in before.Keys.Union(after.Keys, comparer).Order(StringComparer.Ordinal))
        {
            var had = before.TryGetValue(key, out var old);
            var has = after.TryGetValue(key, out var value);
            var oldText = had ? show(old!) : null;
            var newText = has ? show(value!) : null;
            if (oldText != newText) { changes.Add(new ConfigChange(section, key, oldText, newText)); }
        }
    }
}

/// <summary>Why a minimum-version raise is refused (R#1).</summary>
internal enum CeilingRefusal
{
    None,
    NoActiveInstalls,
    AboveNewestReported,
}

/// <summary>
/// AD-006 reach and the R1 lock-out rule (B23 P1, R#1): a new minimum may never be above the newest app version any install
/// active in the last 7 days reported; with no reports, a raise is refused. Lowering is always allowed.
/// </summary>
internal sealed record InstallReach(long Active, AppVersion? Newest, IReadOnlyList<InstallCount> Installs)
{
    public static readonly TimeSpan Window = TimeSpan.FromDays(7);

    public static InstallReach From(IReadOnlyList<InstallCount> installs)
    {
        ArgumentNullException.ThrowIfNull(installs);
        AppVersion? newest = null;
        foreach (var row in installs)
        {
            if (AppVersion.TryParse(row.AppVersion, out var version) && (newest is null || version > newest.Value)) { newest = version; }
        }
        return new InstallReach(installs.Sum(row => row.Installs), newest, installs);
    }

    /// <summary>Installs whose reported version is below <paramref name="minimum"/> (they would get "Update the app").</summary>
    public long BlockedBy(AppVersion minimum) =>
        Installs.Where(row => AppVersion.TryParse(row.AppVersion, out var version) && version < minimum).Sum(row => row.Installs);

    public CeilingRefusal CheckRaise(AppVersion minimum) =>
        Newest is null ? CeilingRefusal.NoActiveInstalls : minimum > Newest.Value ? CeilingRefusal.AboveNewestReported : CeilingRefusal.None;

    /// <summary>True when <paramref name="next"/> raises the minimum above <paramref name="current"/> (both valid versions).</summary>
    public static bool Raises(string current, string next) =>
        AppVersion.TryParse(current, out var from) && AppVersion.TryParse(next, out var to) && to > from;
}
