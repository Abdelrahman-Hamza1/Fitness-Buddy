using System.Text.Json;
using System.Text.Json.Nodes;

namespace FitnessBuddy.TestData;

// B21: shared by the pure and the real HTTP tests so the workout admission matrix cannot drift.
// Corpus cases come from the Dart generator (contracts/testdata/sync/workout-validation-vectors.json);
// the schema matrix adds missing/null/wrong-type/extra cases for every contract field of all seven
// entities, and the fixtures are added as accepted cases (D13).
internal sealed record WorkoutCase(string Id, string Entity, Guid? RowId, string Raw, bool Valid,
    bool Deleted = false, string? Rule = null, string? Asymmetry = null);

internal static class WorkoutCases
{
    public const string CorpusFile = "workout-validation-vectors.json";

    public static readonly string[] Entities =
        ["customExercise", "workoutSession", "sessionExercise", "workoutSet", "workoutTemplate", "workoutTemplateItem", "weeklyPlanDay"];

    private static readonly Lazy<IReadOnlyList<WorkoutCase>> CorpusCases = new(LoadCorpus);

    // The W3 fields the weight × reps baseline needs non-null: nulling one breaks the set shape.
    private static readonly HashSet<string> BaselineSetFields = new(["reps", "kg", "inputValue", "inputUnit"], StringComparer.Ordinal);

    public static JsonDocument ReadCorpus() => Read(CorpusFile);

    public static JsonDocument Read(string file) => JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, file)));

    // The Dart-generated cases, exactly as declared (rawPayload is parsed with JsonDocument, so
    // unpaired-surrogate escapes, duplicate keys and number spellings survive).
    public static IReadOnlyList<WorkoutCase> Corpus() => CorpusCases.Value;

    public static WorkoutCase Case(string id) => Corpus().Single(c => c.Id == id);

    public static string Raw(string id) => Case(id).Raw;

    // Only weeklyPlanDay has a row-ID rule (W5): its fixture weekday's natural ID; any UUID otherwise.
    public static Guid NewId(string entity) => SyncTestIds.For(entity);

    // An explicit corpus rowId (every plan-day case, the v4 and nil row-ID cases) wins.
    public static Guid IdOf(WorkoutCase test) => test.RowId ?? NewId(test.Entity);

    // A valid row of each entity with every nullable field set where possible; the plan day is the
    // fixture's Saturday, so NewId matches it.
    public static string Baseline(string entity) => Raw(entity switch
    {
        "customExercise" => "customExercise-base",
        "workoutSession" => "workoutSession-base-full",
        "sessionExercise" => "sessionExercise-base-catalog",
        "workoutSet" => "workoutSet-base-weight-kg",
        "workoutTemplate" => "workoutTemplate-base",
        "workoutTemplateItem" => "workoutTemplateItem-base",
        "weeklyPlanDay" => "weeklyPlanDay-base-6",
        _ => throw new ArgumentOutOfRangeException(nameof(entity), entity, "not a workout entity"),
    });

    public static string With(string raw, string field, JsonNode? value) => BodyTargetsCases.With(raw, field, value);

    public static string WithRaw(string raw, string field, string json) => BodyTargetsCases.WithRaw(raw, field, json);

    public static IReadOnlyList<WorkoutCase> All()
    {
        var cases = Corpus().ToList();
        using var schema = Read("sync-entities.json");
        foreach (var entity in Entities)
        {
            var baseline = Baseline(entity);
            var properties = schema.RootElement.GetProperty("entities").GetProperty(entity).GetProperty("1").GetProperty("properties");
            foreach (var field in properties.EnumerateObject())
            {
                var absent = JsonNode.Parse(baseline)!.AsObject(); absent.Remove(field.Name);
                cases.Add(new($"{entity}-schema-missing-{field.Name}", entity, null, absent.ToJsonString(), false));
                var types = field.Value.GetProperty("type");
                var nullable = types.ValueKind == JsonValueKind.Array && types.EnumerateArray().Any(t => t.GetString() == "null");
                var primary = types.ValueKind == JsonValueKind.Array ? types.EnumerateArray().First(t => t.GetString() != "null").GetString() : types.GetString();
                // Null is the schema's for a nullable field, except where W3 needs the baseline's value.
                Add($"null-{field.Name}", field.Name, null, nullable && !(entity == "workoutSet" && BaselineSetFields.Contains(field.Name)));
                Add($"type-array-{field.Name}", field.Name, new JsonArray(), false);
                Add($"type-object-{field.Name}", field.Name, new JsonObject(), false);
                // A scalar of the wrong JSON type: no coercion between strings, numbers and booleans.
                Add($"type-scalar-{field.Name}", field.Name, primary switch
                {
                    "string" => JsonValue.Create(1),
                    "integer" or "number" => JsonValue.Create("1"),
                    "boolean" => JsonValue.Create("false"),
                    _ => throw new InvalidOperationException("unexpected schema type"),
                }, false);
                if (primary is "integer" or "number") { Add($"type-boolean-{field.Name}", field.Name, JsonValue.Create(true), false); }
            }
            Add("extra-field", "unexpected", JsonValue.Create("synthetic-extra-value"), false);
            Add("extra-null-field", "unexpected", null, false);

            void Add(string id, string field, JsonNode? value, bool valid) => cases.Add(new($"{entity}-schema-{id}", entity, null, With(baseline, field, value), valid));
        }
        // The one fixture per entity: valid, admitted.
        using var fixtures = Read("entity-payloads.json");
        foreach (var entity in Entities) { cases.Add(new($"fixture-{entity}", entity, null, fixtures.RootElement.GetProperty(entity).GetRawText(), true)); }
        return cases;
    }

    private static WorkoutCase[] LoadCorpus()
    {
        using var corpus = ReadCorpus();
        return corpus.RootElement.GetProperty("payloads").EnumerateArray().Select(item => new WorkoutCase(
            item.GetProperty("id").GetString()!, item.GetProperty("entity").GetString()!,
            item.TryGetProperty("rowId", out var rowId) ? Guid.Parse(rowId.GetString()!) : null,
            item.GetProperty("rawPayload").GetString()!, item.GetProperty("serverAccepts").GetBoolean(), item.GetProperty("deleted").GetBoolean(),
            item.TryGetProperty("rule", out var rule) ? rule.GetString() : null,
            item.TryGetProperty("asymmetry", out var asymmetry) ? asymmetry.GetString() : null)).ToArray();
    }
}
