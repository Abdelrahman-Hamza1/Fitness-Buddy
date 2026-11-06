using System.Collections.Frozen;
using System.Text.Json;
using FitnessBuddy.Modules.UserData.Domain;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

// Schema/type/bound/decimal/duplicate-key checks run first in SyncPayloads. These are exactly the
// wire rules W1–W3 of contracts/README.md § "diaryEntry and savedMealItem versions" (fb_domain's
// DiaryEstimateWireRules, A62a D5/D27, TD-114) and nothing more: no estimate bounds, no FD-012
// sanity check, nothing across rows. v1 has no rules. Dispatch is by entity and version and fails
// closed for a version not in Versions, so a v3 is unadmitted until it is listed here.
internal static class DiaryEstimatePayloadValidator
{
    public const string FoodKind = "estimate";
    public const string Source = "yours";

    public static readonly FrozenSet<int> Versions = FrozenSet.Create(1, 2);

    // (known flag, snapshot, per-100) for the nutrients that can be unknown; kcal is always known.
    public static readonly (string Known, string Snapshot, string Per100)[] Nutrients =
    [
        ("proteinKnown", "proteinG", "per100ProteinG"),
        ("carbsKnown", "carbsG", "per100CarbsG"),
        ("fatKnown", "fatG", "per100FatG"),
        ("fiberKnown", "fiberG", "per100FiberG"),
    ];

    public static bool Covers(string entity) => entity is "diaryEntry" or "savedMealItem";

    // The payload has already passed the schema at version.SchemaVersion, so every member exists
    // with its declared JSON type and every number is a representable decimal.
    public static bool Matches(SyncVersion version) =>
        Covers(version.Entity) && Versions.Contains(version.SchemaVersion) &&
        (version.SchemaVersion == 1 || V2(version.Payload));

    private static bool V2(JsonElement payload)
    {
        var userEstimate = payload.GetProperty("userEstimate").GetBoolean();
        // W1 user estimate shape.
        if (userEstimate && !(payload.GetProperty("foodKind").ValueEquals(FoodKind) && payload.GetProperty("source").ValueEquals(Source) &&
            payload.GetProperty("isEstimate").GetBoolean() && payload.GetProperty("foodId").ValueKind == JsonValueKind.Null)) { return false; }
        foreach (var (known, snapshot, per100) in Nutrients)
        {
            if (payload.GetProperty(known).GetBoolean()) { continue; }
            // W2 unknowns only on user estimates.
            if (!userEstimate) { return false; }
            // W3 unknown is stored zero: a decimal compare, so 0, 0.0 and 0e5 pass and 1e-9 fails.
            if (payload.GetProperty(snapshot).GetDecimal() != 0m || payload.GetProperty(per100).GetDecimal() != 0m) { return false; }
        }
        return true;
    }
}
