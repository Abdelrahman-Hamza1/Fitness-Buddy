using System.Collections.Frozen;
using System.Text.Json;
using FitnessBuddy.Modules.UserData.Domain;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

// Schema/type/bound/decimal/duplicate-key checks run first in SyncPayloads. These are exactly the
// wire rules M1–M3 of contracts/README.md § "Measurement semantic rules" (fb_domain's
// MeasurementWireRules, A15b D14) and nothing more: no plausibility ranges, no unit-factor or
// local-date check, and nothing across rows (the custom type need not exist; B20 D3, TD-080, TD-089).
// Dispatch is by entity for every schema version and fails closed for a version not in Versions (D2).
internal static class MeasurementPayloadValidator
{
    public const decimal MaxPercent = 100m;
    public const string CustomKind = "custom";
    public const string PercentKind = "bodyFat";
    public const string PercentUnit = "percent";

    public static readonly FrozenSet<int> Versions = FrozenSet.Create(1);

    public static bool Covers(string entity) => entity is "measurementType" or "measurement";

    // The payload has already passed the schema at version.SchemaVersion, so every member exists
    // with its declared JSON type and every number is a representable decimal.
    public static bool Matches(SyncVersion version) =>
        Versions.Contains(version.SchemaVersion) && version.Entity switch
        {
            "measurementType" => true, // no wire rules (README); version-pinned only
            "measurement" => Measurement(version.Payload),
            _ => false,
        };

    private static bool Measurement(JsonElement payload)
    {
        var kind = payload.GetProperty("kind");
        var percentKind = kind.ValueEquals(PercentKind);
        // M1 custom type: customTypeId is non-null exactly when kind is custom.
        if (kind.ValueEquals(CustomKind) == (payload.GetProperty("customTypeId").ValueKind == JsonValueKind.Null)) { return false; }
        // M2 unit fits kind: percent exactly for body fat (the schema limits the rest to cm/in).
        if (percentKind != payload.GetProperty("inputUnit").ValueEquals(PercentUnit)) { return false; }
        // M3 percent bound: a decimal compare, so 100.0 passes and 100.0000000000000001 fails.
        return !percentKind ||
            (payload.GetProperty("value").GetDecimal() <= MaxPercent && payload.GetProperty("inputValue").GetDecimal() <= MaxPercent);
    }
}
