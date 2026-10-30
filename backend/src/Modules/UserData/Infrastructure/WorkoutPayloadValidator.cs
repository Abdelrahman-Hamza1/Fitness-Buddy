using System.Collections.Frozen;
using System.Collections.Immutable;
using System.Text.Json;
using FitnessBuddy.Modules.UserData.Domain;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

// Schema/type/bound/decimal/duplicate-key checks run first in SyncPayloads (including the generic
// pass over the nested ...Json strings). These are exactly the row-local wire rules W1–W5 of
// contracts/README.md § "Workout semantic rules" (fb_domain's WorkoutWireRules) and nothing more:
// no app write bounds, no name trimming, and nothing across rows (a child's parent, its aggregate
// and the referenced exercise or template need not exist; B21 D4, TD-080, TD-089). Dispatch is by
// entity for every schema version and fails closed for a version not in Versions (D3). No regex:
// hand-written character loops and Guid.TryParseExact.
internal static class WorkoutPayloadValidator
{
    public const int MaxSecondaries = 4;
    public const int MaxAliases = 10;
    public const int MaxCatalogIdLength = 60;
    public const string CatalogPrefix = "ex:";

    // A37a D2, in contract order (the corpus pins the order and the schema enum).
    public static readonly ImmutableArray<string> MuscleCodes =
    [
        "chest", "shoulders", "biceps", "triceps", "forearms", "traps", "upper_back", "lower_back",
        "abs", "obliques", "quadriceps", "hamstrings", "glutes", "calves", "adductors",
    ];

    public static readonly FrozenSet<string> Muscles = MuscleCodes.ToFrozenSet(StringComparer.Ordinal);

    // naturalId('weeklyPlanDay', '<weekday>') (UUIDv5, TD-070) by ISO weekday, Monday first.
    public static readonly ImmutableArray<Guid> PlanDayIds =
    [
        new("17605af2-922b-5ee3-8648-11da5a26601f"),
        new("5b872683-47af-576f-a2ad-4b38b7980f88"),
        new("30b96b41-d543-5b1b-8d94-1f15769f9c3b"),
        new("840d975c-6188-5c39-bb01-ab163f0b8dc4"),
        new("790cb635-2370-51be-8315-a706422fb27d"),
        new("ff8f65bc-5c85-521a-a8e9-7fb18060ccfe"),
        new("8009ef9a-6a6f-56d7-a915-30314b3e26f2"),
    ];

    public static readonly FrozenSet<int> Versions = FrozenSet.Create(1);

    private static readonly JsonDocumentOptions Nested = new() { MaxDepth = 24 };

    public static bool Covers(string entity) => entity is "customExercise" or "workoutSession" or "sessionExercise"
        or "workoutSet" or "workoutTemplate" or "workoutTemplateItem" or "weeklyPlanDay";

    // The payload has already passed the schema at version.SchemaVersion, so every member exists
    // with its declared JSON type and every number is a representable decimal.
    public static bool Matches(SyncVersion version) =>
        Versions.Contains(version.SchemaVersion) && version.Entity switch
        {
            "customExercise" => MusclesHold(version.Payload) && AliasesHold(version.Payload),
            "workoutSet" => SetShapeHolds(version.Payload),
            "sessionExercise" or "workoutTemplateItem" => IsExerciseRef(version.Payload.GetProperty("exerciseId").GetString()!),
            "weeklyPlanDay" => PlanDayIdHolds(version.Id, version.Payload.GetProperty("weekday").GetDecimal()),
            "workoutSession" or "workoutTemplate" => true, // no wire rules (README); version-pinned only
            _ => false,
        };

    // W1 muscles: a JSON array of at most 4 codes (compared after unescaping, ordinal), distinct,
    // none equal to a non-null primaryMuscle. GetString throws on an ill-formed UTF-16 escape; the
    // caller maps that to invalidPayload.
    private static bool MusclesHold(JsonElement payload)
    {
        var primary = payload.GetProperty("primaryMuscle");
        var primaryCode = primary.ValueKind == JsonValueKind.String ? primary.GetString() : null;
        using var secondaries = JsonDocument.Parse(payload.GetProperty("secondaryMusclesJson").GetString()!, Nested);
        var root = secondaries.RootElement;
        if (root.ValueKind != JsonValueKind.Array || root.GetArrayLength() > MaxSecondaries) { return false; }
        var seen = new HashSet<string>(StringComparer.Ordinal);
        foreach (var item in root.EnumerateArray())
        {
            if (item.ValueKind != JsonValueKind.String) { return false; }
            var code = item.GetString()!;
            if (!Muscles.Contains(code) || code == primaryCode || !seen.Add(code)) { return false; }
        }
        return true;
    }

    // W2 aliases shape: a JSON array of at most 10 strings.
    private static bool AliasesHold(JsonElement payload)
    {
        using var aliases = JsonDocument.Parse(payload.GetProperty("aliasesJson").GetString()!, Nested);
        var root = aliases.RootElement;
        return root.ValueKind == JsonValueKind.Array && root.GetArrayLength() <= MaxAliases &&
            root.EnumerateArray().All(item => item.ValueKind == JsonValueKind.String);
    }

    // W3 set shape: exactly one of reps and durationSeconds; kg only with reps; distanceMeters only
    // with durationSeconds; kg, inputValue and inputUnit all null or all set.
    private static bool SetShapeHolds(JsonElement payload)
    {
        bool Has(string name) => payload.GetProperty(name).ValueKind != JsonValueKind.Null;
        var reps = Has("reps");
        var duration = Has("durationSeconds");
        var kg = Has("kg");
        return reps != duration && (!kg || reps) && (!Has("distanceMeters") || duration) &&
            kg == Has("inputValue") && kg == Has("inputUnit");
    }

    // W4 exercise reference: "ex:" then 1–60 of [a-z0-9_], or a lowercase canonical UUID.
    public static bool IsExerciseRef(string id)
    {
        if (id.StartsWith(CatalogPrefix, StringComparison.Ordinal))
        {
            var rest = id.AsSpan(CatalogPrefix.Length);
            if (rest.Length is 0 or > MaxCatalogIdLength) { return false; }
            foreach (var c in rest)
            {
                if (c is not ((>= 'a' and <= 'z') or (>= '0' and <= '9') or '_')) { return false; }
            }
            return true;
        }
        return Guid.TryParseExact(id, "D", out var guid) && string.Equals(guid.ToString("D"), id, StringComparison.Ordinal);
    }

    // W5 plan-day row ID: the natural ID of the weekday (a schema-checked integer 1…7; GetDecimal so
    // a whole 3.0 works).
    private static bool PlanDayIdHolds(Guid id, decimal weekday) =>
        weekday is >= 1 and <= 7 && id == PlanDayIds[(int)weekday - 1];
}
