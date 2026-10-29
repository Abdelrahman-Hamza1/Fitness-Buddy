using System.Text.Json;
using System.Text.Json.Nodes;

namespace FitnessBuddy.TestData;

// B19: shared by the pure and the real HTTP tests so the profile/goalPhase/targetSettings/weighIn
// admission matrix cannot drift. Corpus cases come from the Dart generator
// (contracts/testdata/sync/body-targets-validation-vectors.json); the schema matrix adds
// missing/null/wrong-type/extra cases for every contract field of the five entity/version pairs.
internal sealed record BodyTargetsCase(string Id, string Entity, int SchemaVersion, Guid? RowId, string Raw, bool Valid,
    bool Deleted = false, string? Rule = null, string? Asymmetry = null);

internal static class BodyTargetsCases
{
    public const string CorpusFile = "body-targets-validation-vectors.json";
    public static readonly string[] TargetsEntities = ["profile", "goalPhase", "targetSettings"];
    public static readonly (string Entity, int Version)[] Pairs = [("profile", 1), ("goalPhase", 1), ("targetSettings", 1), ("weighIn", 1), ("weighIn", 2)];

    // Non-null on a kind or macro means "set"; nulling one breaks Expression fields or Macro pairs.
    private static readonly HashSet<string> PairedFields = new(StringComparer.Ordinal)
    {
        "targetKg", "targetDate", "kgPerWeek", "monthKg", "month",
        "proteinValue", "proteinIsPercent", "fatValue", "fatIsPercent", "carbsValue", "carbsIsPercent",
    };

    private static readonly Lazy<IReadOnlyList<BodyTargetsCase>> CorpusCases = new(LoadCorpus);

    public static JsonDocument ReadCorpus() => JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, CorpusFile)));

    // The Dart-generated cases, exactly as declared (rawPayload is parsed with JsonDocument,
    // so unpaired-surrogate escapes, duplicate keys and number spellings survive).
    public static IReadOnlyList<BodyTargetsCase> Corpus() => CorpusCases.Value;

    public static BodyTargetsCase Case(string id) => Corpus().Single(c => c.Id == id);

    public static string Raw(string id) => Case(id).Raw;

    // D10: the natural profile ID, a UUIDv7 for goalPhase/targetSettings, any UUID for weighIn.
    public static Guid NewId(string entity) => entity == "weighIn" ? Guid.NewGuid() : SyncTestIds.For(entity);

    // An explicit corpus rowId (the Row IDs cases) wins; otherwise the entity's default.
    public static Guid IdOf(BodyTargetsCase test) => test.RowId ?? NewId(test.Entity);

    public static string Label(string entity, int version) => entity == "weighIn" ? $"weighIn{version}" : entity;

    // The minimal valid row of each entity/version pair (goalPhase: the weekly kind).
    public static string Baseline(string entity, int version = 1) => Raw(entity switch
    {
        "goalPhase" => "goalPhase-base-weekly",
        "targetSettings" => "targetSettings-base",
        "weighIn" => $"weighIn{version}-base",
        _ => "profile-base",
    });

    // Replaces one top-level field of a valid row, keeping every other field.
    public static string With(string raw, string field, JsonNode? value)
    {
        var payload = JsonNode.Parse(raw)!.AsObject();
        payload[field] = value;
        return payload.ToJsonString();
    }

    // Replaces one top-level field with raw JSON text, kept exactly as written (-0.0, 1e-28, 1e400).
    public static string WithRaw(string raw, string field, string json)
    {
        var payload = JsonNode.Parse(raw)!.AsObject(); payload[field] = "\u0001marker\u0001";
        return payload.ToJsonString().Replace("\"\\u0001marker\\u0001\"", json, StringComparison.Ordinal);
    }

    public static IReadOnlyList<BodyTargetsCase> All()
    {
        var cases = Corpus().ToList();
        using var schema = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "sync-entities.json")));
        foreach (var (entity, version) in Pairs)
        {
            var baseline = Baseline(entity, version);
            using var parsed = JsonDocument.Parse(baseline);
            var properties = schema.RootElement.GetProperty("entities").GetProperty(entity).GetProperty($"{version}").GetProperty("properties");
            var label = Label(entity, version);
            foreach (var field in properties.EnumerateObject())
            {
                var absent = JsonNode.Parse(baseline)!.AsObject(); absent.Remove(field.Name);
                cases.Add(new($"{label}-schema-missing-{field.Name}", entity, version, null, absent.ToJsonString(), false));
                var types = field.Value.GetProperty("type");
                var nullable = types.ValueKind == JsonValueKind.Array && types.EnumerateArray().Any(t => t.GetString() == "null");
                var primary = types.ValueKind == JsonValueKind.Array ? types.EnumerateArray().First(t => t.GetString() != "null").GetString() : types.GetString();
                // A nullable field may be null unless the baseline sets it and a wire rule pairs it.
                var wasNull = parsed.RootElement.GetProperty(field.Name).ValueKind == JsonValueKind.Null;
                Add($"null-{field.Name}", field.Name, null, nullable && (wasNull || !PairedFields.Contains(field.Name)));
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

            void Add(string id, string field, JsonNode? value, bool valid) => cases.Add(new($"{label}-schema-{id}", entity, version, null, With(baseline, field, value), valid));
        }
        return cases;
    }

    private static BodyTargetsCase[] LoadCorpus()
    {
        using var corpus = ReadCorpus();
        return corpus.RootElement.GetProperty("payloads").EnumerateArray().Select(item => new BodyTargetsCase(
            item.GetProperty("id").GetString()!, item.GetProperty("entity").GetString()!, item.GetProperty("schemaVersion").GetInt32(),
            item.TryGetProperty("rowId", out var rowId) ? Guid.Parse(rowId.GetString()!) : null,
            item.GetProperty("rawPayload").GetString()!, item.GetProperty("serverAccepts").GetBoolean(), item.GetProperty("deleted").GetBoolean(),
            item.TryGetProperty("rule", out var rule) ? rule.GetString() : null,
            item.TryGetProperty("asymmetry", out var asymmetry) ? asymmetry.GetString() : null)).ToArray();
    }
}
