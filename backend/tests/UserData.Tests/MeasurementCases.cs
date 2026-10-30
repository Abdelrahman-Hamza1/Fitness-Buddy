using System.Text.Json;
using System.Text.Json.Nodes;

namespace FitnessBuddy.TestData;

// B20: shared by the pure and the real HTTP tests so the measurementType/measurement admission matrix
// cannot drift. Corpus cases come from the Dart generator
// (contracts/testdata/sync/measurement-validation-vectors.json); the schema matrix adds
// missing/null/wrong-type/extra cases for every contract field of both entities, and the fixtures
// and A15b variants are added as accepted cases (D5).
internal sealed record MeasurementCase(string Id, string Entity, Guid? RowId, string Raw, bool Valid,
    bool Deleted = false, string? Rule = null, string? Asymmetry = null);

internal static class MeasurementCases
{
    public const string CorpusFile = "measurement-validation-vectors.json";
    public const string VariantsFile = "measurement-payload-variants.json";
    public static readonly string[] Entities = ["measurementType", "measurement"];

    private static readonly Lazy<IReadOnlyList<MeasurementCase>> CorpusCases = new(LoadCorpus);

    public static JsonDocument ReadCorpus() => Read(CorpusFile);

    public static JsonDocument Read(string file) => JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, file)));

    // The Dart-generated cases, exactly as declared (rawPayload is parsed with JsonDocument,
    // so unpaired-surrogate escapes, duplicate keys and number spellings survive).
    public static IReadOnlyList<MeasurementCase> Corpus() => CorpusCases.Value;

    public static MeasurementCase Case(string id) => Corpus().Single(c => c.Id == id);

    public static string Raw(string id) => Case(id).Raw;

    // Measurements have no row-ID rule (D3): any UUID; a UUIDv7 as the app mints.
    public static Guid NewId(string entity) => SyncTestIds.For(entity);

    // An explicit corpus rowId (the v4 row-ID case) wins.
    public static Guid IdOf(MeasurementCase test) => test.RowId ?? NewId(test.Entity);

    // The minimal valid row of each entity: the type base and the waist base (cm).
    public static string Baseline(string entity) => Raw(entity == "measurement" ? "measurement-base-waist" : "measurementType-base");

    public static string With(string raw, string field, JsonNode? value) => BodyTargetsCases.With(raw, field, value);

    public static string WithRaw(string raw, string field, string json) => BodyTargetsCases.WithRaw(raw, field, json);

    public static IReadOnlyList<MeasurementCase> All()
    {
        var cases = Corpus().ToList();
        using var schema = Read("sync-entities.json");
        foreach (var entity in Entities)
        {
            var baseline = Baseline(entity);
            using var parsed = JsonDocument.Parse(baseline);
            var properties = schema.RootElement.GetProperty("entities").GetProperty(entity).GetProperty("1").GetProperty("properties");
            foreach (var field in properties.EnumerateObject())
            {
                var absent = JsonNode.Parse(baseline)!.AsObject(); absent.Remove(field.Name);
                cases.Add(new($"{entity}-schema-missing-{field.Name}", entity, null, absent.ToJsonString(), false));
                var types = field.Value.GetProperty("type");
                var nullable = types.ValueKind == JsonValueKind.Array && types.EnumerateArray().Any(t => t.GetString() == "null");
                var primary = types.ValueKind == JsonValueKind.Array ? types.EnumerateArray().First(t => t.GetString() != "null").GetString() : types.GetString();
                // customTypeId is the only nullable field; the waist baseline has it null (M1).
                var wasNull = parsed.RootElement.GetProperty(field.Name).ValueKind == JsonValueKind.Null;
                Add($"null-{field.Name}", field.Name, null, nullable && wasNull);
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
        // The one fixture per entity and the A15b variants: valid, admitted (D5).
        using var fixtures = Read("entity-payloads.json");
        foreach (var entity in Entities) { cases.Add(new($"fixture-{entity}", entity, null, fixtures.RootElement.GetProperty(entity).GetRawText(), true)); }
        using var variants = Read(VariantsFile);
        foreach (var variant in variants.RootElement.GetProperty("cases").EnumerateArray())
        {
            cases.Add(new($"variant-{variant.GetProperty("id").GetString()}", variant.GetProperty("entity").GetString()!, null,
                variant.GetProperty("payload").GetRawText(), true));
        }
        return cases;
    }

    private static MeasurementCase[] LoadCorpus()
    {
        using var corpus = ReadCorpus();
        return corpus.RootElement.GetProperty("payloads").EnumerateArray().Select(item => new MeasurementCase(
            item.GetProperty("id").GetString()!, item.GetProperty("entity").GetString()!,
            item.TryGetProperty("rowId", out var rowId) ? Guid.Parse(rowId.GetString()!) : null,
            item.GetProperty("rawPayload").GetString()!, item.GetProperty("serverAccepts").GetBoolean(), item.GetProperty("deleted").GetBoolean(),
            item.TryGetProperty("rule", out var rule) ? rule.GetString() : null,
            item.TryGetProperty("asymmetry", out var asymmetry) ? asymmetry.GetString() : null)).ToArray();
    }
}
