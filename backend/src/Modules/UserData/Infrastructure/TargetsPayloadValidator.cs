using System.Collections.Frozen;
using System.Globalization;
using System.Text.Json;
using FitnessBuddy.Modules.UserData.Domain;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

// Schema/type/bound/decimal/duplicate-key checks run first in SyncPayloads. These are exactly the
// wire rules of contracts/README.md § "Targets semantic rules" (TargetRules.wire, A13 PA6) plus its
// row-ID rule, and nothing more: no plausibility ranges and nothing across rows (B19 D3, TD-080, TD-089).
// Dispatch is by entity for every schema version and fails closed for a version not in Versions (D2).
internal static class TargetsPayloadValidator
{
    public const decimal MaxPercent = 100m;

    // naturalId('profile', 'self'): the one profile row (UUIDv5, TD-070).
    public static readonly Guid ProfileRowId = new("f0b8e132-056c-5b98-8c9b-ff9a6dc1bb96");

    public static readonly FrozenSet<int> Versions = FrozenSet.Create(1);

    // expressionKind → which of targetKg, targetDate, kgPerWeek, monthKg, month are non-null.
    private static readonly (string Kind, bool TargetKg, bool TargetDate, bool KgPerWeek, bool MonthKg, bool Month)[] Expected =
    [
        ("targetDate", true, true, false, false, false),
        ("targetRate", true, false, true, false, false),
        ("weekly", false, false, true, false, false),
        ("monthly", false, false, false, true, true),
    ];

    private static readonly (string Value, string IsPercent)[] Macros =
        [("proteinValue", "proteinIsPercent"), ("fatValue", "fatIsPercent"), ("carbsValue", "carbsIsPercent")];

    public static bool Covers(string entity) => entity is "profile" or "goalPhase" or "targetSettings";

    // The payload has already passed the schema at version.SchemaVersion, so every member exists
    // with its declared JSON type and every number is a representable decimal.
    public static bool Matches(SyncVersion version)
    {
        if (!Versions.Contains(version.SchemaVersion)) { return false; }
        var payload = version.Payload;
        return version.Entity switch
        {
            "profile" => version.Id == ProfileRowId && Positive(payload.GetProperty("heightCm")),
            "goalPhase" => IsUuidV7(version.Id) && GoalPhase(payload),
            "targetSettings" => IsUuidV7(version.Id) && TargetSettings(payload),
            _ => false,
        };
    }

    // PA3: version nibble 7 and the RFC 9562 variant (high bits 10, Dart isUuidV7's [89ab]).
    private static bool IsUuidV7(Guid id) => id.Version == 7 && (id.Variant & 0xC) == 0x8;

    private static bool GoalPhase(JsonElement payload)
    {
        var targetKg = payload.GetProperty("targetKg");
        var kgPerWeek = payload.GetProperty("kgPerWeek");
        // Positive numbers: targetKg > 0 when set.
        if (!IsNull(targetKg) && !Positive(targetKg)) { return false; }
        // Expression fields: exactly the kind's own fields are non-null; a target-rate speed is positive.
        var kind = payload.GetProperty("expressionKind");
        var found = false;
        foreach (var expected in Expected)
        {
            if (!kind.ValueEquals(expected.Kind)) { continue; }
            found = true;
            if (IsNull(targetKg) == expected.TargetKg || IsNull(payload.GetProperty("targetDate")) == expected.TargetDate ||
                IsNull(kgPerWeek) == expected.KgPerWeek || IsNull(payload.GetProperty("monthKg")) == expected.MonthKg ||
                IsNull(payload.GetProperty("month")) == expected.Month) { return false; }
            if (expected.Kind == "targetRate" && !Positive(kgPerWeek)) { return false; }
        }
        if (!found) { return false; }
        // Maintain: weekly with kgPerWeek 0 (a decimal compare, so -0.0 is 0).
        if (payload.GetProperty("goalType").ValueEquals("maintain") &&
            (!kind.ValueEquals("weekly") || kgPerWeek.GetDecimal() != 0m)) { return false; }
        // Phase dates: endDate, when set, is not before startDate.
        var end = payload.GetProperty("endDate");
        return IsNull(end) || Date(end) >= Date(payload.GetProperty("startDate"));
    }

    private static bool TargetSettings(JsonElement payload)
    {
        // Positive numbers.
        if (!Positive(payload.GetProperty("baseKcal")) || !Positive(payload.GetProperty("basisWeightKg"))) { return false; }
        // Acknowledgement: acknowledged only with manual.
        if (payload.GetProperty("acknowledged").GetBoolean() && !payload.GetProperty("manual").GetBoolean()) { return false; }
        // Macro pairs: both null or both set; a percent value is at most 100.
        foreach (var (valueField, flagField) in Macros)
        {
            var value = payload.GetProperty(valueField);
            var isPercent = payload.GetProperty(flagField);
            if (IsNull(value) != IsNull(isPercent)) { return false; }
            if (!IsNull(isPercent) && isPercent.GetBoolean() && value.GetDecimal() > MaxPercent) { return false; }
        }
        return true;
    }

    private static bool IsNull(JsonElement value) => value.ValueKind == JsonValueKind.Null;

    private static bool Positive(JsonElement value) => value.GetDecimal() > 0m;

    private static DateOnly Date(JsonElement value) =>
        DateOnly.ParseExact(value.GetString()!, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None);
}
