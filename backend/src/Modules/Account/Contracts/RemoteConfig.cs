using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;
using FitnessBuddy.BuildingBlocks.Clients;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Results;

namespace FitnessBuddy.Modules.Account.Contracts;

/// <summary>
/// One remote-config version (B23 P1, TD-120 candidate): what <c>GET /v1/config</c> serves (minimum version, client flags,
/// thresholds) plus the server flags behind <c>IFeatureFlags</c>. Client and server flags are separate namespaces.
/// </summary>
public sealed record RemoteConfigDocument(string MinimumAppVersion, IReadOnlyDictionary<string, bool> FeatureFlags,
    IReadOnlyDictionary<string, double> Thresholds, IReadOnlyDictionary<string, bool> ServerFlags)
{
    public const int FormatVersion = 1;

    /// <summary>Canonical JSON (sorted keys, fixed shape), so equal documents have equal bytes and hashes.</summary>
    public string ToJson()
    {
        using var stream = new MemoryStream();
        using (var json = new Utf8JsonWriter(stream))
        {
            json.WriteStartObject();
            json.WriteNumber("v", FormatVersion);
            json.WriteString("minimumAppVersion", MinimumAppVersion);
            json.WriteStartObject("featureFlags");
            foreach (var (key, value) in FeatureFlags.OrderBy(pair => pair.Key, StringComparer.Ordinal)) { json.WriteBoolean(key, value); }
            json.WriteEndObject();
            json.WriteStartObject("thresholds");
            foreach (var (key, value) in Thresholds.OrderBy(pair => pair.Key, StringComparer.Ordinal)) { json.WriteNumber(key, value); }
            json.WriteEndObject();
            json.WriteStartObject("serverFlags");
            foreach (var (key, value) in ServerFlags.OrderBy(pair => pair.Key, StringComparer.Ordinal)) { json.WriteBoolean(key, value); }
            json.WriteEndObject();
            json.WriteEndObject();
        }
        return System.Text.Encoding.UTF8.GetString(stream.ToArray());
    }

    /// <summary>Parses a stored document; null when its shape or format version is unknown.</summary>
    public static RemoteConfigDocument? FromJson(string json)
    {
        try
        {
            using var document = JsonDocument.Parse(json);
            var root = document.RootElement;
            if (root.ValueKind != JsonValueKind.Object || !root.TryGetProperty("v", out var v) || v.GetInt32() != FormatVersion) { return null; }
            return new RemoteConfigDocument(root.GetProperty("minimumAppVersion").GetString() ?? "",
                Bools(root.GetProperty("featureFlags"), StringComparer.Ordinal), Numbers(root.GetProperty("thresholds")),
                Bools(root.GetProperty("serverFlags"), StringComparer.OrdinalIgnoreCase));
        }
        catch (Exception error) when (error is JsonException or InvalidOperationException or KeyNotFoundException or FormatException)
        {
            return null;
        }
    }

    private static Dictionary<string, bool> Bools(JsonElement element, StringComparer comparer) =>
        element.EnumerateObject().ToDictionary(property => property.Name, property => property.Value.GetBoolean(), comparer);

    private static Dictionary<string, double> Numbers(JsonElement element) =>
        element.EnumerateObject().ToDictionary(property => property.Name, property => property.Value.GetDouble(), StringComparer.Ordinal);
}

/// <summary>A published version. Rows are append-only; a rollback is a new version with <paramref name="RolledBackFrom"/> set.</summary>
public sealed record PublishedConfig(int Version, RemoteConfigDocument Document, DateTimeOffset PublishedAt, string PublishedBy, string Reason, int? RolledBackFrom);

/// <summary>
/// The validation every published document passes (B23 P1). The baseline is the current document: server flags
/// can't be invented from the console, and thresholds outside the known keys may only stay as they were.
/// </summary>
public static partial class RemoteConfigRules
{
    public const string AiSwitch = "buddy.ai";
    public const int MaxClientFlags = 50;

    /// <summary>The known client thresholds and their accepted ranges (09 §9).</summary>
    public static IReadOnlyDictionary<string, (double Min, double Max)> KnownThresholds { get; } = new Dictionary<string, (double, double)>(StringComparer.Ordinal)
    {
        ["proposalQuestionRelativeDelta"] = (0, 1),
        ["proposalQuestionKcalDelta"] = (0, 10000),
    };

    public static IReadOnlyList<string> Validate(RemoteConfigDocument document, RemoteConfigDocument? baseline)
    {
        ArgumentNullException.ThrowIfNull(document);
        var errors = new List<string>();
        if (!AppVersion.TryParse(document.MinimumAppVersion, out _)) { errors.Add("The minimum app version must be MAJOR.MINOR.PATCH."); }
        if (document.FeatureFlags.Count > MaxClientFlags) { errors.Add("At most " + MaxClientFlags.ToString(CultureInfo.InvariantCulture) + " app flags."); }
        foreach (var name in document.FeatureFlags.Keys.Where(name => !ClientFlagName().IsMatch(name)))
        {
            errors.Add("App flag names start with a lowercase letter and use letters, digits, '_' or '.' (max 64): " + Shorten(name) + ".");
        }
        foreach (var (key, value) in document.Thresholds)
        {
            if (!double.IsFinite(value)) { errors.Add("Threshold " + Shorten(key) + " must be a finite number."); continue; }
            if (KnownThresholds.TryGetValue(key, out var range))
            {
                if (value < range.Min || value > range.Max)
                {
                    errors.Add(string.Create(CultureInfo.InvariantCulture, $"Threshold {key} must be between {range.Min} and {range.Max}."));
                }
            }
            else if (baseline is null || !baseline.Thresholds.TryGetValue(key, out var old) || old != value)
            {
                errors.Add("Unknown threshold " + Shorten(key) + ".");
            }
        }
        var allowedServer = new HashSet<string>(baseline?.ServerFlags.Keys ?? [], StringComparer.OrdinalIgnoreCase) { AiSwitch };
        foreach (var name in document.ServerFlags.Keys.Where(name => !allowedServer.Contains(name)))
        {
            errors.Add("Server switches can't be added from the console: " + Shorten(name) + ".");
        }
        return errors;
    }

    private static string Shorten(string value) => value.Length <= 40 ? value : value[..40] + "…";

    [GeneratedRegex("^[a-z][a-zA-Z0-9_.]{0,63}$", RegexOptions.CultureInvariant)]
    private static partial Regex ClientFlagName();
}

/// <summary>Remote config for the admin console (B23). Every write enlists in the caller's session so the audit row commits with it.</summary>
public interface IRemoteConfigAdmin
{
    /// <summary>The configuration defaults (what version 1 is seeded from, and what serves before anything is published).</summary>
    RemoteConfigDocument Defaults { get; }

    /// <summary>The override version while <c>Clients:MinimumAppVersionOverride</c> is set, else null.</summary>
    string? ActiveOverride { get; }

    Task<PublishedConfig?> CurrentAsync(DatabaseSession session, CancellationToken cancellationToken);

    Task<PublishedConfig?> VersionAsync(DatabaseSession session, int version, CancellationToken cancellationToken);

    /// <summary>Newest first, at most <paramref name="limit"/> versions, only those below <paramref name="before"/> when set (paging).</summary>
    Task<IReadOnlyList<PublishedConfig>> HistoryAsync(DatabaseSession session, int limit, int? before, CancellationToken cancellationToken);

    /// <summary>
    /// Publishes <paramref name="document"/> as the next version if the newest version is still <paramref name="expectedVersion"/>
    /// (under a transaction lock), else a <c>VersionConflict</c>. Validation failures are <c>Validation</c> errors. Doesn't commit.
    /// </summary>
    Task<Result<PublishedConfig>> PublishAsync(DatabaseSession session, RemoteConfigDocument document, int expectedVersion, string actor, string reason,
        int? rolledBackFrom, DateTimeOffset now, CancellationToken cancellationToken);
}
