using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Buddy.Infrastructure;

namespace FitnessBuddy.Buddy.Tests;

// B09a WP1: the public intent DTOs serialize as the contract's discriminated union, and replays stay readable.
public sealed class PublicIntentContractTests
{
    private static readonly Guid Entry = Guid.Parse("019a0000-0000-7000-8000-0000000000e1");
    private static readonly Guid Other = Guid.Parse("019a0000-0000-7000-8000-0000000000e2");
    private static readonly BuddyEntryReference Rice = new("the rice", "yesterday", "lunch", BuddyReferenceScope.One);

    [Theory]
    [InlineData("today", true)]
    [InlineData("yesterday", true)]
    [InlineData("daysAgo:2", true)]
    [InlineData("daysAgo:999", true)]
    [InlineData("lastWeekday:mon", true)]
    [InlineData("date:03-15", true)]
    [InlineData("date:2026-02-29", true)]
    [InlineData("daysAgo:1", false)]
    [InlineData("daysAgo:1000", false)]
    [InlineData("daysAgo:02", false)]
    [InlineData("lastWeekday:monday", false)]
    [InlineData("date:2026-13-01", false)]
    [InlineData("date:3-15", false)]
    [InlineData("tomorrow", false)]
    [InlineData("last tuesday", false)]
    [Trait("Rule", "04.4.1-contract-first")]
    public void Day_hint_pattern_is_the_closed_grammar(string hint, bool valid)
    {
        // Format only; calendar validity (date:02-30) is the server validator's job (WP2).
        Assert.Equal(valid, Regex.IsMatch(hint, BuddyDayHints.Pattern, RegexOptions.None, TimeSpan.FromSeconds(1)));
    }

    [Fact]
    [Trait("Rule", "04.4.1-contract-first")]
    public void Group_a_intents_serialize_with_kind_camel_case_enums_and_explicit_nulls()
    {
        var patch = new BuddyDiaryPatch(new(2, "piece", true), null, null);
        BuddyIntent[] intents =
        [
            new BuddyDiaryEdit("en", "latin", [Entry], Rice, patch),
            new BuddyDiaryDelete("en", "latin", [], Rice with { Scope = BuddyReferenceScope.All }),
            new BuddyAmbiguousReference("en", "latin", BuddyReferenceOperation.Edit, [Entry, Other], Rice, patch),
            new BuddyDiaryCopy("en", "latin", new("yesterday", "lunch", null), new("today", "lunch", null)),
            new BuddyFoodLog("en", "latin", null, null, "date:03-15", null, []),
            new BuddyWeighIn("en", "latin", 97.2, "kg", null, null),
        ];
        var json = JsonNode.Parse(JsonSerializer.Serialize(new BuddyInterpretation("interpret-v1", "m", intents), InterpretProtocol.Json))!["intents"]!.AsArray();
        Assert.Equal(["diaryEdit", "diaryDelete", "ambiguousReference", "diaryCopy", "foodLog", "weighIn"], json.Select(i => i!["kind"]!.GetValue<string>()));
        Assert.Equal("one", json[0]!["reference"]!["scope"]!.GetValue<string>());
        Assert.Equal("all", json[1]!["reference"]!["scope"]!.GetValue<string>());
        Assert.Equal("edit", json[2]!["operation"]!.GetValue<string>());
        Assert.True(json[0]!["patch"]!.AsObject().ContainsKey("replacement"));
        Assert.Null(json[0]!["patch"]!["move"]);
        Assert.Equal("date:03-15", json[4]!["dateHint"]!.GetValue<string>());
        Assert.True(json[5]!.AsObject().ContainsKey("dateHint"));
        Assert.Null(json[5]!["dateHint"]);
    }

    [Fact]
    [Trait("Rule", "04.8-additive-contract")]
    public void Stored_replays_without_new_members_or_with_jsonb_key_order_still_read()
    {
        // A response stored before dateHint existed, keys in jsonb order (shorter keys first, "kind" not first).
        const string stored = """
            {"model":"m","intents":[{"unit":"kg","kind":"weighIn","value":97.2,"script":"latin","language":"en","timeHint":null},
              {"kind":"foodLog","items":[],"script":"latin","language":"en","slotHint":null,"timeHint":null,"dishGroup":null}],"promptVersion":"interpret-v1"}
            """;
        var value = JsonSerializer.Deserialize<BuddyInterpretation>(stored, InterpretProtocol.Stored)!;
        Assert.Null(Assert.IsType<BuddyWeighIn>(value.Intents[0]).DateHint);
        Assert.Null(Assert.IsType<BuddyFoodLog>(value.Intents[1]).DateHint);
        var edit = new BuddyInterpretation("interpret-v1", "m", [new BuddyAmbiguousReference("en", "latin", BuddyReferenceOperation.Delete, [Entry, Other], Rice, null)]);
        var reordered = JsonNode.Parse(JsonSerializer.Serialize(edit, InterpretProtocol.Json))!;
        var intent = reordered["intents"]![0]!.AsObject(); var kind = intent["kind"]!.GetValue<string>(); intent.Remove("kind"); intent["kind"] = kind;
        var replayed = JsonSerializer.Deserialize<BuddyInterpretation>(reordered.ToJsonString(), InterpretProtocol.Stored)!;
        Assert.Equal(JsonSerializer.Serialize(edit, InterpretProtocol.Json), JsonSerializer.Serialize(replayed, InterpretProtocol.Json));
    }

    [Fact]
    [Trait("Rule", "04.8-additive-contract")]
    public void Request_without_an_active_card_keeps_its_idempotency_fingerprint_input()
    {
        var without = JsonSerializer.Serialize(ProductionTests.Input(), InterpretProtocol.Json);
        Assert.DoesNotContain("activeCard", without, StringComparison.Ordinal);
        var card = ProductionTests.Input() with { Context = ProductionTests.Input().Context with { ActiveCard = new("Breakfast", "08:00", [new("eggs", 2, "piece", "cooked")]) } };
        var with = JsonSerializer.Serialize(card, InterpretProtocol.Json);
        Assert.Contains("\"activeCard\":{", with, StringComparison.Ordinal);
        Assert.NotEqual(without, with);
    }

    [Fact]
    [Trait("Rule", "04.4.1-contract-first")]
    public void Memory_change_serializes_its_closed_vocabulary_and_replays_with_food_before_kind()
    {
        BuddyIntent[] intents =
        [
            new BuddyMemoryChange("en", "latin", BuddyMemoryOperation.Remember, BuddyMemoryKind.Default, "rice", BuddyMemoryDimension.State, "cooked", null, null),
            new BuddyMemoryChange("ar", "arabic", BuddyMemoryOperation.Forget, BuddyMemoryKind.Portion, "rice", null, null, new(150, "g", true), null),
        ];
        var interpretation = new BuddyInterpretation("interpret-v1", "m", intents);
        var json = JsonNode.Parse(JsonSerializer.Serialize(interpretation, InterpretProtocol.Json))!["intents"]!.AsArray();
        Assert.Equal(("memoryChange", "remember", "default", "state"), (json[0]!["kind"]!.GetValue<string>(), json[0]!["operation"]!.GetValue<string>(),
            json[0]!["memoryKind"]!.GetValue<string>(), json[0]!["dimension"]!.GetValue<string>()));
        Assert.Equal(("forget", "portion"), (json[1]!["operation"]!.GetValue<string>(), json[1]!["memoryKind"]!.GetValue<string>()));
        Assert.True(json[1]!.AsObject().ContainsKey("dimension")); Assert.Null(json[1]!["dimension"]); Assert.Null(json[1]!["food"]);
        JsonbOrder(json); // "food" now precedes "kind"
        Assert.Equal("food", json[0]!.AsObject().First(p => p.Key.Length == 4).Key);
        var stored = new JsonObject { ["promptVersion"] = "interpret-v1", ["model"] = "m", ["intents"] = json.DeepClone() }.ToJsonString();
        var replayed = JsonSerializer.Deserialize<BuddyInterpretation>(stored, InterpretProtocol.Stored)!;
        Assert.Equal(JsonSerializer.Serialize(interpretation, InterpretProtocol.Json), JsonSerializer.Serialize(replayed, InterpretProtocol.Json));
    }

    [Fact]
    [Trait("Rule", "04.4.1-contract-first")]
    public void Group_c_intents_serialize_with_kind_camel_case_enums_and_replay_from_jsonb_order()
    {
        var batch = Guid.Parse("019a0000-0000-7000-8000-0000000000b1");
        var meal = Guid.Parse("019a0000-0000-7000-8000-0000000000c1");
        var rice = new BuddyFoodItem("rice", null, [], new(500, "g", true), null, [], null);
        BuddyIntent[] intents =
        [
            new BuddyBatch("en", "latin", "mujaddara", [rice], new(1200, "g", true), BuddyBatchPath.Leftovers, new(null, new(0.25, null)), null, null, "today"),
            new BuddyBatchPortion("en", "latin", batch, new(new(1, "plate", true), null), false, null, "dinner", null),
            new BuddyBatchPortion("en", "latin", batch, null, true, null, null, null),
            new BuddyBatchClose("en", "latin", batch),
            new BuddyPersonalFoodCreate("en", "latin", "protein bar", ["bar"], [], new(BuddyNutrientBasis.Per100ml, null, null, 380, 30, 40, 10, null)),
            new BuddySavedMealLog("en", "latin", meal, null, "breakfast", "yesterday", null),
            new BuddySavedMealCreate("en", "latin", "my breakfast", null, [Entry, Other], null),
        ];
        var interpretation = new BuddyInterpretation("interpret-v1", "m", intents);
        var json = JsonNode.Parse(JsonSerializer.Serialize(interpretation, InterpretProtocol.Json))!["intents"]!.AsArray();
        Assert.Equal(["batch", "batchPortion", "batchPortion", "batchClose", "personalFoodCreate", "savedMealLog", "savedMealCreate"], json.Select(i => i!["kind"]!.GetValue<string>()));
        Assert.Equal("leftovers", json[0]!["path"]!.GetValue<string>());
        Assert.Equal("per100ml", json[4]!["stated"]!["basis"]!.GetValue<string>());
        Assert.Null(json[4]!["stated"]!["fiberG"]);
        Assert.Equal(batch, json[3]!["batchId"]!.GetValue<Guid>());
        Assert.Equal((true, true), (json[2]!["rest"]!.GetValue<bool>(), json[2]!.AsObject().ContainsKey("portion") && json[2]!["portion"] is null));
        Assert.False(json[1]!["rest"]!.GetValue<bool>());
        JsonbOrder(json);
        var stored = new JsonObject { ["promptVersion"] = "interpret-v1", ["model"] = "m", ["intents"] = json.DeepClone() }.ToJsonString();
        var replayed = JsonSerializer.Deserialize<BuddyInterpretation>(stored, InterpretProtocol.Stored)!;
        Assert.Equal(JsonSerializer.Serialize(interpretation, InterpretProtocol.Json), JsonSerializer.Serialize(replayed, InterpretProtocol.Json));
    }

    // jsonb stores object keys shorter first, then bytewise.
    private static void JsonbOrder(JsonArray intents)
    {
        foreach (var intent in intents.Select(i => i!.AsObject()))
        {
            var ordered = intent.OrderBy(p => p.Key.Length).ThenBy(p => p.Key, StringComparer.Ordinal).Select(p => (p.Key, Value: p.Value?.DeepClone())).ToList();
            intent.Clear(); foreach (var (key, value) in ordered) { intent[key] = value; }
        }
    }
}
