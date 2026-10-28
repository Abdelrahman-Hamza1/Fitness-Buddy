using System.Text.Json;
using System.Text.Json.Nodes;

namespace FitnessBuddy.TestData;

// B18 D12: shared by the pure and the real HTTP tests so the chatMessage/proposal
// admission matrix cannot drift. Corpus cases come from the Dart generator
// (contracts/testdata/sync/chat-proposal-validation-vectors.json); the schema
// matrix adds missing/null/wrong-type/extra cases for every contract field.
internal sealed record ChatProposalCase(string Id, string Entity, string Raw, bool Valid, bool Deleted = false);

internal static class ChatProposalCases
{
    public const string CorpusFile = "chat-proposal-validation-vectors.json";
    public static readonly string[] Entities = ["chatMessage", "proposal"];
    private static readonly Lazy<IReadOnlyList<ChatProposalCase>> CorpusCases = new(LoadCorpus);

    public static JsonDocument ReadCorpus() => JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, CorpusFile)));

    // The Dart-generated cases, exactly as declared (rawPayload is parsed with
    // JsonDocument, so unpaired-surrogate escapes survive until GetString()).
    public static IReadOnlyList<ChatProposalCase> Corpus() => CorpusCases.Value;

    public static string Raw(string id) => Corpus().Single(c => c.Id == id).Raw;

    // The minimal valid row of each entity (an assistant message, a pending foodLog card).
    public static string Baseline(string entity) => Raw(entity == "chatMessage" ? "chat-base" : "proposal-base");

    // Replaces one top-level field of a valid row, keeping every other field.
    public static string With(string raw, string field, JsonNode? value)
    {
        var payload = JsonNode.Parse(raw)!.AsObject();
        payload[field] = value;
        return payload.ToJsonString();
    }

    public static IReadOnlyList<ChatProposalCase> All()
    {
        var cases = Corpus().ToList();
        using var schema = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "sync-entities.json")));
        foreach (var entity in Entities)
        {
            var baseline = Baseline(entity);
            var properties = schema.RootElement.GetProperty("entities").GetProperty(entity).GetProperty("1").GetProperty("properties");
            foreach (var field in properties.EnumerateObject())
            {
                var absent = JsonNode.Parse(baseline)!.AsObject(); absent.Remove(field.Name);
                cases.Add(new($"{entity}-missing-{field.Name}", entity, absent.ToJsonString(), false));
                var types = field.Value.GetProperty("type");
                var nullable = types.ValueKind == JsonValueKind.Array && types.EnumerateArray().Any(t => t.GetString() == "null");
                var primary = types.ValueKind == JsonValueKind.Array ? types.EnumerateArray().First(t => t.GetString() != "null").GetString() : types.GetString();
                Add($"null-{field.Name}", field.Name, null, nullable);
                Add($"type-array-{field.Name}", field.Name, new JsonArray(), false);
                Add($"type-object-{field.Name}", field.Name, new JsonObject(), false);
                // A scalar of the wrong JSON type: no coercion between strings, numbers and booleans.
                Add($"type-scalar-{field.Name}", field.Name, primary switch
                {
                    "string" => JsonValue.Create(1),
                    "integer" => JsonValue.Create("1"),
                    "boolean" => JsonValue.Create("false"),
                    _ => throw new InvalidOperationException("unexpected schema type"),
                }, false);
                if (primary == "integer") { Add($"type-boolean-{field.Name}", field.Name, JsonValue.Create(true), false); }
            }
            Add("extra-field", "unexpected", JsonValue.Create("synthetic-extra-value"), false);
            Add("extra-null-field", "unexpected", null, false);

            void Add(string id, string field, JsonNode? value, bool valid) => cases.Add(new($"{entity}-{id}", entity, With(baseline, field, value), valid));
        }
        return cases;
    }

    private static ChatProposalCase[] LoadCorpus()
    {
        using var corpus = ReadCorpus();
        return corpus.RootElement.GetProperty("payloads").EnumerateArray().Select(item => new ChatProposalCase(
            item.GetProperty("id").GetString()!, item.GetProperty("entity").GetString()!, item.GetProperty("rawPayload").GetString()!,
            item.GetProperty("serverAccepts").GetBoolean(), item.GetProperty("deleted").GetBoolean())).ToArray();
    }
}
