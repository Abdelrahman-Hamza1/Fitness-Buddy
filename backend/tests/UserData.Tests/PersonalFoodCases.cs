using System.Text.Json;
using System.Text.Json.Nodes;

namespace FitnessBuddy.TestData;

// Shared by pure and real HTTP tests so the adversarial matrix cannot drift.
internal sealed record PersonalFoodCase(string Id, string Raw, bool Valid, bool Deleted = false);

internal static class PersonalFoodCases
{
    public static IReadOnlyList<PersonalFoodCase> All()
    {
        using var corpus = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "personal-food-validation-vectors.json")));
        var cases = corpus.RootElement.GetProperty("payloads").EnumerateArray().Select(item => new PersonalFoodCase(
            item.GetProperty("id").GetString()!, item.GetProperty("rawPayload").GetString()!,
            item.GetProperty("serverAccepts").GetBoolean(), item.GetProperty("deleted").GetBoolean())).ToList();
        var baseline = cases.Single(c => c.Id == "minimal").Raw;
        using var schema = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "sync-entities.json")));
        var properties = schema.RootElement.GetProperty("entities").GetProperty("personalFood").GetProperty("1").GetProperty("properties");
        foreach (var field in properties.EnumerateObject())
        {
            var absent = JsonNode.Parse(baseline)!.AsObject(); absent.Remove(field.Name);
            cases.Add(new("missing-" + field.Name, absent.ToJsonString(), false));
            Set("type-" + field.Name, field.Name, new JsonArray(), false);
            var nullable = field.Value.GetProperty("type").ValueKind == JsonValueKind.Array;
            Set("null-" + field.Name, field.Name, null, nullable);
        }
        Set("extra-field", "unexpected", JsonValue.Create("private-invalid-value"), false);
        foreach (var field in new[] { "nameEn", "nameAr", "brand", "createdFrom" })
        {
            Set("long-" + field, field, JsonValue.Create(new string('x', 16384)), false);
        }
        foreach (var field in new[] { "aliasesJson", "barcodesJson", "per100ExtrasJson", "servingsJson" })
        {
            var empty = field == "per100ExtrasJson" ? "{}" : "[]";
            Set("json-limit-" + field, field, JsonValue.Create(empty.PadRight(16384)), true);
            Set("json-over-limit-" + field, field, JsonValue.Create(empty.PadRight(16385)), false);
            Set("json-malformed-" + field, field, JsonValue.Create("["), false);
            Set("json-deep-" + field, field, JsonValue.Create(new string('[', 25) + "0" + new string(']', 25)), false);
            Set("json-scalar-" + field, field, JsonValue.Create("true"), false);
        }
        foreach (var field in new[] { "per100Kcal", "per100ProteinG", "per100CarbsG", "per100FatG", "per100FiberG", "entryServingAmount" })
        {
            foreach (var number in new[] { "1e10000", "1e-10000", "0." + new string('0', 130) + "1", "\"NaN\"", "\"Infinity\"" })
            {
                var p = JsonNode.Parse(baseline)!.AsObject();
                p[field] = JsonNode.Parse(number);
                if (field == "entryServingAmount") { p["entryServingUnit"] = "piece"; }
                cases.Add(new("number-" + field + "-" + number, p.ToJsonString(), false));
            }
        }
        foreach (var value in new[] { "1e10000", "1e-10000", "NaN", "Infinity", "\"NaN\"", "\"Infinity\"", "null", "true" })
        {
            Set("extras-number-" + value, "per100ExtrasJson", JsonValue.Create("{\"sodium\":" + value + "}"), false);
            Set("serving-number-" + value, "servingsJson", JsonValue.Create("[{\"unit\":\"piece\",\"amount\":" + value + "}]"), false);
        }
        cases.Add(new("escaped-duplicate-name", baseline.Replace("\"nameEn\":", "\"\\u006eameEn\":\"old\",\"nameEn\":", StringComparison.Ordinal), false));
        Set("alias-empty", "aliasesJson", JsonValue.Create("[\"\"]"), false);
        Set("alias-exact-duplicate", "aliasesJson", JsonValue.Create("[\"alias\",\"alias\"]"), false);
        Set("barcode-empty", "barcodesJson", JsonValue.Create("[\"\"]"), false);
        Set("serving-escaped-duplicate", "servingsJson", JsonValue.Create("[{\"unit\":\"piece\",\"amount\":1,\"\\u0061mount\":2}]"), false);
        return cases;

        void Set(string id, string field, JsonNode? value, bool valid)
        {
            var p = JsonNode.Parse(baseline)!.AsObject(); p[field] = value;
            cases.Add(new(id, p.ToJsonString(), valid));
        }
    }
}
