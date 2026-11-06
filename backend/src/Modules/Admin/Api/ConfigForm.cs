using System.Globalization;
using FitnessBuddy.Modules.Account.Contracts;
using FitnessBuddy.Modules.Admin.Api.Pages;
using FitnessBuddy.Modules.Admin.Application;
using FitnessBuddy.Modules.Admin.Domain;
using Microsoft.AspNetCore.Http;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>The config window's form and views (AD-012): parses the edit form, renders documents, diffs and reach lines.</summary>
internal static class ConfigForm
{
    /// <summary>Parses the edit form against the current document (its threshold and switch keys). Errors are plain English.</summary>
    public static (RemoteConfigDocument? Document, IReadOnlyList<string> Errors, ConfigFormView Typed) Parse(IFormCollection form, RemoteConfigDocument current)
    {
        ArgumentNullException.ThrowIfNull(form);
        ArgumentNullException.ThrowIfNull(current);
        var errors = new List<string>();
        var minimum = form["minimumAppVersion"].ToString().Trim();
        var flagsText = form["appFlags"].ToString();
        var flags = new Dictionary<string, bool>(StringComparer.Ordinal);
        foreach (var raw in flagsText.Split('\n'))
        {
            var line = raw.Trim();
            if (line.Length == 0) { continue; }
            var eq = line.IndexOf('=', StringComparison.Ordinal);
            var name = eq > 0 ? line[..eq].Trim() : "";
            var value = eq > 0 ? line[(eq + 1)..].Trim().ToUpperInvariant() : "";
            if (name.Length == 0 || value is not ("ON" or "OFF" or "TRUE" or "FALSE")) { errors.Add("App flags: one per line as name = on or name = off."); break; }
            if (!flags.TryAdd(name, value is "ON" or "TRUE")) { errors.Add("App flags: " + Short(name) + " appears twice."); }
        }
        var thresholds = new Dictionary<string, double>(StringComparer.Ordinal);
        var thresholdFields = new List<ThresholdFieldView>();
        foreach (var key in ThresholdKeys(current))
        {
            var text = form["threshold." + key].ToString().Trim();
            thresholdFields.Add(new ThresholdFieldView(key, text, Range(key)));
            if (text.Length == 0) { continue; }
            if (double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out var number)) { thresholds[key] = number; }
            else { errors.Add("Threshold " + key + " must be a number (use a dot for decimals)."); }
        }
        var switches = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
        var switchFields = new List<SwitchFieldView>();
        foreach (var key in current.ServerFlags.Keys.Order(StringComparer.Ordinal))
        {
            var on = form["server." + key].ToString() == "on";
            switches[key] = on;
            switchFields.Add(new SwitchFieldView(key, on));
        }
        var typed = new ConfigFormView(minimum, flagsText, thresholdFields, switchFields);
        return errors.Count > 0 ? (null, errors, typed) : (new RemoteConfigDocument(minimum, flags, thresholds, switches), [], typed);
    }

    public static ConfigFormView FormFor(RemoteConfigDocument document, RemoteConfigDocument current) => new(document.MinimumAppVersion,
        string.Join('\n', document.FeatureFlags.OrderBy(pair => pair.Key, StringComparer.Ordinal).Select(pair => pair.Key + " = " + (pair.Value ? "on" : "off"))),
        [.. ThresholdKeys(current).Select(key => new ThresholdFieldView(key,
            document.Thresholds.TryGetValue(key, out var value) ? value.ToString("R", CultureInfo.InvariantCulture) : "", Range(key)))],
        [.. current.ServerFlags.Keys.Order(StringComparer.Ordinal).Select(key => new SwitchFieldView(key, document.ServerFlags.TryGetValue(key, out var on) && on))]);

    public static ConfigValuesView Values(RemoteConfigDocument document) => new(document.MinimumAppVersion,
        [.. document.FeatureFlags.OrderBy(pair => pair.Key, StringComparer.Ordinal).Select(pair => new KeyValueView(pair.Key, pair.Value ? "on" : "off"))],
        [.. document.Thresholds.OrderBy(pair => pair.Key, StringComparer.Ordinal).Select(pair => new KeyValueView(pair.Key, pair.Value.ToString("R", CultureInfo.InvariantCulture)))],
        [.. document.ServerFlags.OrderBy(pair => pair.Key, StringComparer.Ordinal).Select(pair => new KeyValueView(pair.Key, pair.Value ? "on" : "off"))]);

    /// <summary>The diff with one reach line per change (AD-006).</summary>
    public static IReadOnlyList<ChangeView> Changes(IReadOnlyList<ConfigChange> changes, InstallReach reach) =>
        [.. changes.Select(change => Change(change, reach))];

    private static ChangeView Change(ConfigChange change, InstallReach reach)
    {
        var active = reach.Active.ToString(CultureInfo.InvariantCulture);
        switch (change.Section)
        {
            case ConfigSection.MinimumVersion when InstallReach.Raises(change.Old ?? "", change.New ?? "")
                && FitnessBuddy.BuildingBlocks.Clients.AppVersion.TryParse(change.New, out var minimum):
                var refusal = reach.CheckRaise(minimum);
                var line = refusal switch
                {
                    CeilingRefusal.NoActiveInstalls => "Refused: no install reported a version in the last 7 days, so a raise can't be checked.",
                    CeilingRefusal.AboveNewestReported => "Refused: above the newest version an active install reported (" + reach.Newest + "). That would lock out every app.",
                    _ => "Shows \"Update the app\" to " + reach.BlockedBy(minimum).ToString(CultureInfo.InvariantCulture) + " of " + active
                        + " installs active in the last 7 days. Newest reported: " + reach.Newest + ".",
                };
                return new ChangeView("Minimum app version", change.Key, change.Old, change.New, line, refusal != CeilingRefusal.None);
            case ConfigSection.MinimumVersion:
                return new ChangeView("Minimum app version", change.Key, change.Old, change.New, "Lowers or keeps the minimum: no install is newly blocked.", false);
            case ConfigSection.AppFlag:
                return new ChangeView("App flag", change.Key, change.Old, change.New, "Affects all " + active + " active installs at their next config fetch.", false);
            case ConfigSection.Threshold:
                return new ChangeView("Threshold", change.Key, change.Old, change.New, "Affects new proposal sessions on all " + active + " active installs.", false);
            default:
                return new ChangeView("Server switch", change.Key, change.Old, change.New, "Server only: takes effect within a few seconds.", false);
        }
    }

    public static string Notice(PublishStatus status) => status switch
    {
        PublishStatus.NoDraft => "There is no draft to publish.",
        PublishStatus.DraftChanged => "The draft changed since you reviewed it. Review the new diff and publish again.",
        PublishStatus.Stale => "The config changed since you started. Review the new diff.",
        PublishStatus.Invalid => "The draft breaks a config rule. Nothing was published.",
        PublishStatus.NoActiveInstalls => "Refused: no install reported a version in the last 7 days, so the minimum can't be raised.",
        PublishStatus.AboveNewestReported => "Refused: the new minimum is above the newest version any active install reported.",
        PublishStatus.TypedVersionMismatch => "Type the new minimum version exactly to confirm the raise.",
        PublishStatus.NeedsRecentSignIn => "Raising the minimum needs a recent sign-in.",
        PublishStatus.UnknownVersion => "That version doesn't exist.",
        _ => "Done.",
    };

    private static IEnumerable<string> ThresholdKeys(RemoteConfigDocument current) =>
        RemoteConfigRules.KnownThresholds.Keys.Union(current.Thresholds.Keys, StringComparer.Ordinal).Order(StringComparer.Ordinal);

    private static string Range(string key) => RemoteConfigRules.KnownThresholds.TryGetValue(key, out var range)
        ? string.Create(CultureInfo.InvariantCulture, $"{range.Min}–{range.Max}") : "kept as is";

    private static string Short(string value) => value.Length <= 40 ? value : value[..40] + "…";
}
