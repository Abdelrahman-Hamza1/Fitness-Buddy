using System.Text.Json;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using FitnessBuddy.TestData;

namespace FitnessBuddy.UserData.Tests;

[Trait("Req", "FD-071")]
[Trait("Req", "AC-010")]
public sealed class PersonalFoodPayloadTests
{
    private static JsonDocument Read(string file) => JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, file)));

    [Fact, Trait("Rule", "A09.3.0-personal-food-bounds")]
    public void Constants_match_corpus_and_contract()
    {
        using var corpus = Read("personal-food-validation-vectors.json");
        var constants = corpus.RootElement.GetProperty("constants");
        var actual = new Dictionary<string, decimal>(StringComparer.Ordinal)
        {
            ["name"] = PersonalFoodBounds.Name,
            ["brand"] = PersonalFoodBounds.Brand,
            ["aliases"] = PersonalFoodBounds.Aliases,
            ["barcodes"] = PersonalFoodBounds.Barcodes,
            ["servings"] = PersonalFoodBounds.Servings,
            ["kcal"] = PersonalFoodBounds.Kcal,
            ["grams"] = PersonalFoodBounds.Grams,
            ["milligrams"] = PersonalFoodBounds.Milligrams,
            ["minServing"] = PersonalFoodBounds.MinServing,
            ["maxServing"] = PersonalFoodBounds.MaxServing,
            ["createdFrom"] = PersonalFoodBounds.CreatedFrom,
            ["jsonLength"] = PersonalFoodBounds.JsonLength,
        };
        Assert.Equal(actual.Count, constants.EnumerateObject().Count());
        foreach (var entry in actual) { Assert.Equal(entry.Value, constants.GetProperty(entry.Key).GetDecimal()); }
        using var schema = Read("sync-entities.json");
        var props = schema.RootElement.GetProperty("entities").GetProperty("personalFood").GetProperty("1").GetProperty("properties");
        foreach (var field in new[] { "nameEn", "nameAr" }) { Bound(field, "maxLength", PersonalFoodBounds.Name); }
        Bound("brand", "maxLength", PersonalFoodBounds.Brand);
        Bound("createdFrom", "maxLength", PersonalFoodBounds.CreatedFrom);
        foreach (var field in new[] { "aliasesJson", "barcodesJson", "per100ExtrasJson", "servingsJson" }) { Bound(field, "maxLength", PersonalFoodBounds.JsonLength); }
        foreach (var field in new[] { "per100Kcal", "per100ProteinG", "per100CarbsG", "per100FatG", "per100FiberG" })
        {
            Bound(field, "minimum", 0);
            Bound(field, "maximum", field == "per100Kcal" ? PersonalFoodBounds.Kcal : PersonalFoodBounds.Grams);
        }
        Bound("entryServingAmount", "minimum", PersonalFoodBounds.MinServing);
        Bound("entryServingAmount", "maximum", PersonalFoodBounds.MaxServing);
        Same(PersonalFoodBounds.States, Strings(props.GetProperty("state").GetProperty("enum")));
        Same(PersonalFoodBounds.Bases, Strings(props.GetProperty("basis").GetProperty("enum")));
        Same(PersonalFoodBounds.Units, props.GetProperty("entryServingUnit").GetProperty("enum").EnumerateArray()
            .Where(v => v.ValueKind != JsonValueKind.Null).Select(v => v.GetString()!));
        void Bound(string field, string keyword, decimal expected) => Assert.Equal(expected, props.GetProperty(field).GetProperty(keyword).GetDecimal());
    }

    [Fact, Trait("Rule", "A09.3.0-personal-food-bounds")]
    public void Vocabularies_match_Dart_generated_corpus()
    {
        using var corpus = Read("personal-food-validation-vectors.json");
        var words = corpus.RootElement.GetProperty("vocabularies");
        Same(PersonalFoodBounds.States, Strings(words.GetProperty("states")));
        Same(PersonalFoodBounds.Bases, Strings(words.GetProperty("bases")));
        Same(PersonalFoodBounds.Units, Strings(words.GetProperty("units")));
        var nutrients = words.GetProperty("nutrients");
        Assert.Equal(PersonalFoodBounds.NutrientUnits.Count, nutrients.EnumerateObject().Count());
        foreach (var item in PersonalFoodBounds.NutrientUnits) { Assert.Equal(item.Value, nutrients.GetProperty(item.Key).GetString()); }
    }

    [Fact, Trait("Rule", "A09.3.0-personal-food-bounds")]
    public void Shared_rule_field_rows_exist()
    {
        var card = File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "A09-personal-foods-quick-add.md"));
        var table = card.Split("**3.0 Shared", StringSplitOptions.None)[1].Split("**3.1", StringSplitOptions.None)[0];
        foreach (var field in new[]
        {
            "nameEn", "nameAr", "brand", "aliasesJson", "barcodesJson", "state", "basis", "per100Kcal",
            "per100ProteinG", "per100CarbsG", "per100FatG", "per100FiberG", "per100ExtrasJson", "servingsJson",
            "entryServingUnit", "entryServingAmount", "createdFrom",
        })
        {
            Assert.Contains(table.Split('\n'), line => line.StartsWith("| `", StringComparison.Ordinal) &&
                line.Split('|')[1].Contains("`" + field + "`", StringComparison.Ordinal));
        }
    }

    [Fact, Trait("Rule", "A09.3.0-string-parity")]
    public void Dart_scan_pins_actual_platform_whitespace_differences()
    {
        using var corpus = Read("personal-food-validation-vectors.json");
        var dart = corpus.RootElement.GetProperty("trimCodeUnits").EnumerateArray().Select(v => v.GetInt32()).ToHashSet();
        var net = Enumerable.Range(0, 65536).Where(c => !char.IsSurrogate((char)c) && char.IsWhiteSpace((char)c)).ToHashSet();
        Assert.Equal([0xfeff], dart.Except(net).Order());
        Assert.Empty(net.Except(dart));
        Assert.Contains(0x85, dart); Assert.Contains(0x85, net);
        foreach (var c in Enumerable.Range(0x1c, 4)) { Assert.DoesNotContain(c, net); }
        foreach (var item in corpus.RootElement.GetProperty("strings").EnumerateArray())
        { Assert.Equal(item.GetProperty("length").GetInt32(), item.GetProperty("input").GetString()!.Length); }
    }

    [Fact, Trait("Rule", "A09.3.0-mapper-parity")]
    public void Corpus_declares_every_outcome_and_preserves_asymmetric_raw_cases()
    {
        using var corpus = Read("personal-food-validation-vectors.json");
        var root = corpus.RootElement;
        var cases = root.GetProperty("payloads").EnumerateArray().ToArray();
        Assert.Equal(cases.Length, cases.Select(c => c.GetProperty("id").GetString()).Distinct(StringComparer.Ordinal).Count());
        Same(Strings(root.GetProperty("serverRejectsAppTolerates")), cases
            .Where(c => !c.GetProperty("serverAccepts").GetBoolean() && c.GetProperty("appReads").GetBoolean())
            .Select(c => c.GetProperty("id").GetString()!));
        foreach (var item in cases)
        {
            using var payload = JsonDocument.Parse(item.GetProperty("rawPayload").GetString()!);
            Assert.Equal(JsonValueKind.Object, payload.RootElement.ValueKind);
            if (item.GetProperty("serverAccepts").GetBoolean()) { Assert.True(item.GetProperty("appReads").GetBoolean()); }
            _ = item.GetProperty("deleted").GetBoolean();
        }
        var asymmetric = Strings(root.GetProperty("serverRejectsAppTolerates")).ToArray();
        foreach (var id in new[] { "unknown-state", "unknown-extra", "duplicate-payload-name", "extras-json-null", @"name-lone-\ud800", @"name-lone-\udc00", @"alias-lone-\ud800", @"alias-lone-\udc00" })
        { Assert.Contains(id, asymmetric); }
        foreach (var writer in root.GetProperty("writers").EnumerateArray())
        { Assert.True(cases.Single(c => c.GetProperty("id").GetString() == writer.GetProperty("payloadId").GetString()).GetProperty("serverAccepts").GetBoolean()); }
    }

    public static IEnumerable<object[]> Payloads() => PersonalFoodCases.All().Select(c => new object[] { c.Id, c.Raw, c.Valid, c.Deleted });

    [Theory, MemberData(nameof(Payloads)), Trait("Rule", "05.5-payload-validation")]
    public void Payload_matrix_matches_semantic_admission_for_live_and_tombstone(string id, string raw, bool valid, bool deleted)
    {
        Assert.False(string.IsNullOrEmpty(id));
        using var payload = JsonDocument.Parse(raw);
        // Tombstones are full documents; apply the exact same rule to each case.
        foreach (var tombstone in new[] { deleted, !deleted })
        {
            var version = new SyncVersion("personalFood", Guid.NewGuid(), 1, "unused", Guid.NewGuid(),
                tombstone ? DateTimeOffset.UnixEpoch : null, payload.RootElement);
            Assert.Equal(valid ? null : "invalidPayload", SyncPayloads.InvalidReason(version));
        }
    }

    [Fact, Trait("Rule", "A09.3.0-string-parity")]
    public void Explicit_trim_predicate_matches_every_BMP_code_unit_in_the_Dart_scan()
    {
        using var corpus = Read("personal-food-validation-vectors.json");
        var set = corpus.RootElement.GetProperty("trimCodeUnits").EnumerateArray().Select(v => v.GetInt32()).ToHashSet();
        for (var c = 0; c <= 65535; c++) { Assert.Equal(set.Contains(c), PersonalFoodPayloadValidator.IsDartWhitespace((char)c)); }
    }

    [Fact(Timeout = 10000), Trait("Rule", "05.5-payload-validation")]
    public void Near_limit_hostile_strings_complete_with_bounded_work()
    {
        var cases = PersonalFoodCases.All().Where(c => c.Id.StartsWith("json-", StringComparison.Ordinal) || c.Id.StartsWith("long-", StringComparison.Ordinal)).ToArray();
        foreach (var item in cases)
        {
            TestContext.Current.CancellationToken.ThrowIfCancellationRequested();
            using var payload = JsonDocument.Parse(item.Raw);
            Assert.Equal(item.Valid ? null : "invalidPayload", SyncPayloads.InvalidReason(new("personalFood", Guid.NewGuid(), 1, "unused", Guid.NewGuid(), null, payload.RootElement)));
        }
    }

    [Fact, Trait("Rule", "05.5-payload-validation")]
    public void All_current_entity_fixtures_still_pass_schema_admission()
    {
        // One file per schema version (contracts/testdata/README.md), each pushed at its own version.
        foreach (var (file, version) in new[] { ("entity-payloads.json", 1), ("entity-payloads-v2.json", 2) })
        {
            using var fixtures = Read(file);
            foreach (var item in fixtures.RootElement.EnumerateObject())
            { Assert.Null(SyncPayloads.InvalidReason(new(item.Name, SyncTestIds.For(item.Name), version, "unused", Guid.NewGuid(), null, item.Value))); }
        }
    }

    private static IEnumerable<string> Strings(JsonElement value) => value.EnumerateArray().Select(v => v.GetString()!);
    private static void Same(IEnumerable<string> a, IEnumerable<string> b) => Assert.Equal(a.Order(StringComparer.Ordinal), b.Order(StringComparer.Ordinal));
}
