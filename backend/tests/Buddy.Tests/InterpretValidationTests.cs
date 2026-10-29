using System.Text.Json;
using System.Text.Json.Nodes;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using static FitnessBuddy.Buddy.Tests.ProductionTests;

namespace FitnessBuddy.Buddy.Tests;

public sealed class InterpretValidationTests
{
    [Theory]
    [InlineData("nutrients")]
    [InlineData("missing")]
    [InlineData("nullItem")]
    [InlineData("nullIntents")]
    [InlineData("unknownKind")]
    [InlineData("zeroAmount")]
    [InlineData("quotedAmount")]
    [InlineData("integerEnum")]
    [InlineData("nutrientUnit")]
    [InlineData("unknownUnit")]
    [InlineData("duplicateProperty")]
    [InlineData("emptyIntents")]
    [InlineData("invalidShape")]
    [Trait("Req", "AI-070")]
    [Trait("Rule", "06.1-schema-validation")]
    public async Task Untrusted_output_is_validated_beyond_the_native_provider_schema(string mutation)
    {
        var wire = JsonNode.Parse(await OpenAIContractTests.FixtureAsync("en-eggs"))!;
        var value = JsonNode.Parse(wire["output"]![1]!["content"]![0]!["text"]!.GetValue<string>())!;
        var intent = value["intents"]![0]!;
        var item = intent["items"]![0]!;
        switch (mutation)
        {
            case "nutrients": item["calories"] = 200; break;
            case "missing": item.AsObject().Remove("amount"); break;
            case "nullItem": intent["items"]![0] = null; break;
            case "nullIntents": value["intents"] = null; break;
            case "unknownKind": intent["kind"] = "writeDiary"; break;
            case "zeroAmount": item["amount"] = 0; break;
            case "quotedAmount": item["amount"] = "2"; break;
            case "unknownUnit": item["unit"] = "mystery"; break;
            case "nutrientUnit": item["unit"] = "kcal"; break;
            case "duplicateProperty":
                Assert.Null(InterpretProtocol.Parse(value.ToJsonString().Replace("\"amount\":2", "\"amount\":2,\"amount\":3", StringComparison.Ordinal)));
                return;
            case "integerEnum": intent["kind"] = 0; break;
            case "emptyIntents": value["intents"] = new JsonArray(); break;
            case "invalidShape": intent["kind"] = "weighIn"; break;
        }
        Assert.Null(InterpretProtocol.Parse(value.ToJsonString()));
    }

    [Fact]
    [Trait("Req", "AI-015")]
    public async Task Multi_intent_weights_workout_and_ambiguity_are_interpretations_only()
    {
        var wire = JsonNode.Parse(await OpenAIContractTests.FixtureAsync("en-eggs"))!;
        var value = JsonNode.Parse(wire["output"]![1]!["content"]![0]!["text"]!.GetValue<string>())!;
        value["intents"]![0]!["items"]![0]!["ambiguities"] = new JsonArray("portion");
        value["intents"]!.AsArray().Add(JsonNode.Parse("""
            {"kind":"weighIn","timeHint":"today","slotHint":null,"items":[],"weighIn":{"value":97.2,"unit":"kg"},"exercises":[],"reason":null}
            """));
        value["intents"]!.AsArray().Add(JsonNode.Parse("""
            {"kind":"workout","timeHint":null,"slotHint":null,"items":[],"weighIn":null,"exercises":[{"name":"bench press","sets":[{"count":3,"reps":8,"weight":80,"unit":"kg"}]}],"reason":null}
            """));
        var parsed = InterpretProtocol.Parse(value.ToJsonString());
        Assert.NotNull(parsed);
        Assert.Equal(3, parsed.Intents.Length);
        Assert.Equal(97.2m, parsed.Intents[1].WeighIn!.Value);
        Assert.Equal(3, parsed.Intents[2].Exercises[0].Sets[0].Count);
    }

    // ----- interpret-v2 (B09a WP2): semantic validation with closed invalid-output codes (PA13) -----

    private static readonly InterpretInput V2Input = ValidationInput("save my bar: 250 kcal, 12g protein, fat 1,5 per 100g");
    private static ParsedFood Food(string name = "rice", decimal? amount = 150) => new(name, name, null, amount, amount is null ? null : FoodUnit.G,
        amount is not null, null, null, null, [], null);
    private static ParsedReference Ref(params int[] refs) => new(refs, "the rice", ParsedScope.One, null, null);
    private static ParsedIntent Edit => Intent(ParsedKind.DiaryEdit) with { Reference = Ref(0, 1), Portion = new(150, FoodUnit.G, null, null, false) };
    private static ParsedIntent Valid(ParsedKind kind) => kind switch
    {
        ParsedKind.FoodLog => Intent(kind) with { Items = [Food()], DateHint = "yesterday" },
        ParsedKind.WeighIn => Intent(kind) with { WeighIn = new(97.2m, "kg"), DateHint = "today" },
        ParsedKind.Medical => Intent(kind),
        ParsedKind.Clarify => Intent(kind) with { Reason = DeclineReason.Unsupported },
        ParsedKind.OutOfScope => Intent(kind) with { Reason = DeclineReason.OffTopic },
        ParsedKind.DiaryEdit => Edit,
        ParsedKind.DiaryDelete => Intent(kind) with { Reference = Ref(2) },
        ParsedKind.DiaryCopy => Intent(kind) with { DateHint = "yesterday", SlotHint = "Breakfast", Move = new("today", null, null) },
        ParsedKind.SavedMealLog => Intent(kind) with { ListRef = 1, Portion = new(null, null, 0.5m, null, false) },
        ParsedKind.SavedMealCreate => Intent(kind) with { Create = new("gym lunch", [], false), Reference = Ref(0) with { Scope = ParsedScope.All } },
        ParsedKind.MemoryChange => Intent(kind) with { Memory = new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Default, "rice", ParsedMemoryDimension.State, "raw", null, null) },
        ParsedKind.Batch => Intent(kind) with { Items = [Food(), Food("chicken", 1000)], Batch = new("maqluba", null, null, null), Portion = new(1, FoodUnit.Plate, null, null, false) },
        ParsedKind.BatchPortion => Intent(kind) with { ListRef = 0, Portion = new(null, null, null, null, true) },
        ParsedKind.BatchClose => Intent(kind) with { ListRef = 0 },
        ParsedKind.PersonalFoodCreate => Intent(kind) with { Create = new("my bar", ["bar"], false), Stated = new(ParsedNutrientBasis.Per100g, null, null, 250, 12, null, 1.5m, null) },
        _ => throw new ArgumentOutOfRangeException(nameof(kind)),
    };
    private static InvalidOutput? Check(ParsedIntent intent, InterpretInput? input = null)
    {
        input ??= V2Input;
        var parse = ProductionProtocol.Parse(JsonSerializer.Serialize(Message(intent), InterpretProtocol.Json), input);
        Assert.Equal(parse.Invalid is null, parse.Message is not null);
        return parse.Invalid;
    }

    [Fact]
    [Trait("Rule", "06.1-schema-validation")]
    public void Every_v2_kind_has_a_valid_shape_that_round_trips()
    {
        foreach (var kind in Enum.GetValues<ParsedKind>()) { Assert.True(Check(Valid(kind)) is null, kind.ToString()); }
    }

    [Theory]
    [InlineData("editRefPastTheEnd", nameof(InvalidOutput.RefRange))]
    [InlineData("negativeRef", nameof(InvalidOutput.RefRange))]
    [InlineData("duplicateRefs", nameof(InvalidOutput.RefRange))]
    [InlineData("deleteRefPastTheEnd", nameof(InvalidOutput.RefRange))]
    [InlineData("saveRefPastTheEnd", nameof(InvalidOutput.RefRange))]
    [InlineData("savedMealPastTheEnd", nameof(InvalidOutput.RefRange))]
    [InlineData("batchIndexOnlyValidForEntries", nameof(InvalidOutput.RefRange))]
    [InlineData("negativeBatch", nameof(InvalidOutput.RefRange))]
    [InlineData("listRefOnEdit", nameof(InvalidOutput.MixedGroups))]
    [InlineData("referenceOnBatchPortion", nameof(InvalidOutput.MixedGroups))]
    [InlineData("listRefOnFoodLog", nameof(InvalidOutput.MixedGroups))]
    [InlineData("noMatchSavedMeal", null)]
    [InlineData("noOpenBatches", null)]
    [InlineData("emptyRefs", null)]
    [Trait("Req", "AI-091")]
    [Trait("Req", "AI-102")]
    [Trait("Req", "DY-031")]
    public void Out_of_range_duplicate_or_wrong_list_refs_are_invalid_output(string mutation, string? expected)
    {
        var input = V2Input;
        var intent = mutation switch
        {
            "editRefPastTheEnd" => Edit with { Reference = Ref(0, 3) },
            "negativeRef" => Edit with { Reference = Ref(-1) },
            "duplicateRefs" => Edit with { Reference = Ref(1, 1) },
            "deleteRefPastTheEnd" => Valid(ParsedKind.DiaryDelete) with { Reference = Ref(30) },
            "saveRefPastTheEnd" => Valid(ParsedKind.SavedMealCreate) with { Reference = Ref(3) },
            "savedMealPastTheEnd" => Valid(ParsedKind.SavedMealLog) with { ListRef = 2 },
            "batchIndexOnlyValidForEntries" => Valid(ParsedKind.BatchPortion) with { ListRef = 2 },
            "negativeBatch" => Valid(ParsedKind.BatchClose) with { ListRef = -1 },
            "listRefOnEdit" => Edit with { ListRef = 0 },
            "referenceOnBatchPortion" => Valid(ParsedKind.BatchPortion) with { Reference = Ref(0) },
            "listRefOnFoodLog" => Valid(ParsedKind.FoodLog) with { ListRef = 0 },
            // PA8: no match (null) or nothing to link to (empty list) is not invalid output; the resolver clarifies without a repair.
            "noMatchSavedMeal" => Valid(ParsedKind.SavedMealLog) with { ListRef = null },
            "noOpenBatches" => Valid(ParsedKind.BatchClose) with { ListRef = 3 },
            "emptyRefs" => Edit with { Reference = Ref() with { DateHint = "yesterday" } },
            _ => throw new ArgumentOutOfRangeException(nameof(mutation)),
        };
        if (mutation == "noOpenBatches") { input = input with { Context = input.Context with { OpenBatches = [] } }; }
        Assert.Equal(expected, Check(intent, input)?.ToString());
    }

    [Theory]
    [InlineData("foodLogWithReference", nameof(InvalidOutput.MixedGroups))]
    [InlineData("foodLogWithoutItems", nameof(InvalidOutput.MixedGroups))]
    [InlineData("clarifyWithDateHint", nameof(InvalidOutput.MixedGroups))]
    [InlineData("medicalWithMemory", nameof(InvalidOutput.MixedGroups))]
    [InlineData("weighInWithPortion", nameof(InvalidOutput.MixedGroups))]
    [InlineData("editWithoutReference", nameof(InvalidOutput.MixedGroups))]
    [InlineData("editWithoutChange", nameof(InvalidOutput.MixedGroups))]
    [InlineData("editReplacementAndAmount", nameof(InvalidOutput.MixedGroups))]
    [InlineData("editTwoReplacements", nameof(InvalidOutput.MixedGroups))]
    [InlineData("editEmptyMove", nameof(InvalidOutput.MixedGroups))]
    [InlineData("editRelativeShare", nameof(InvalidOutput.MixedGroups))]
    [InlineData("editAmountWithoutUnit", nameof(InvalidOutput.Bounds))]
    [InlineData("editTopLevelDate", nameof(InvalidOutput.MixedGroups))]
    [InlineData("deleteWithMove", nameof(InvalidOutput.MixedGroups))]
    [InlineData("copyWithItems", nameof(InvalidOutput.MixedGroups))]
    [InlineData("copyEmptyTarget", nameof(InvalidOutput.MixedGroups))]
    [InlineData("savedMealWithAmount", nameof(InvalidOutput.MixedGroups))]
    [InlineData("savedMealBothShares", nameof(InvalidOutput.MixedGroups))]
    [InlineData("saveBothSources", nameof(InvalidOutput.MixedGroups))]
    [InlineData("saveNoSource", nameof(InvalidOutput.MixedGroups))]
    [InlineData("saveBlankName", nameof(InvalidOutput.Bounds))]
    [InlineData("saveWithoutCreate", nameof(InvalidOutput.MixedGroups))]
    [InlineData("memoryDimensionOnAlias", nameof(InvalidOutput.MixedGroups))]
    [InlineData("memoryDefaultWithoutDimension", nameof(InvalidOutput.MixedGroups))]
    [InlineData("memoryStateNotClosed", nameof(InvalidOutput.ClosedValue))]
    [InlineData("memoryFatNotClosed", nameof(InvalidOutput.ClosedValue))]
    [InlineData("memoryPortionWithoutAmount", nameof(InvalidOutput.MixedGroups))]
    [InlineData("memoryAliasWithoutValue", nameof(InvalidOutput.MixedGroups))]
    [InlineData("memoryWithoutSubject", nameof(InvalidOutput.MixedGroups))]
    [InlineData("batchWithoutBatch", nameof(InvalidOutput.MixedGroups))]
    [InlineData("batchWithoutIngredients", nameof(InvalidOutput.MixedGroups))]
    [InlineData("batchCookedWithoutUnit", nameof(InvalidOutput.Bounds))]
    [InlineData("batchEatenRest", nameof(InvalidOutput.MixedGroups))]
    [InlineData("portionRestAndAmount", nameof(InvalidOutput.MixedGroups))]
    [InlineData("portionMissing", nameof(InvalidOutput.MixedGroups))]
    [InlineData("portionEmpty", nameof(InvalidOutput.MixedGroups))]
    [InlineData("portionFractionAboveOne", nameof(InvalidOutput.Bounds))]
    [InlineData("closeWithPortion", nameof(InvalidOutput.MixedGroups))]
    [InlineData("personalFromCard", nameof(InvalidOutput.MixedGroups))]
    [InlineData("personalEmpty", nameof(InvalidOutput.MixedGroups))]
    [InlineData("personalSixAliases", nameof(InvalidOutput.Bounds))]
    [InlineData("personalStatedAllNull", nameof(InvalidOutput.MixedGroups))]
    [InlineData("personalWithReference", nameof(InvalidOutput.MixedGroups))]
    [InlineData("batchInvalidIngredient", nameof(InvalidOutput.Food))]
    [Trait("Req", "AI-050")]
    [Trait("Req", "AI-055")]
    [Trait("Req", "AI-100")]
    [Trait("Rule", "06.1-schema-validation")]
    public void Per_kind_invariants_reject_missing_or_mixed_groups(string mutation, string expected)
    {
        var memory = Valid(ParsedKind.MemoryChange).Memory!;
        var intent = mutation switch
        {
            "foodLogWithReference" => Valid(ParsedKind.FoodLog) with { Reference = Ref(0) },
            "foodLogWithoutItems" => Valid(ParsedKind.FoodLog) with { Items = [] },
            "clarifyWithDateHint" => Valid(ParsedKind.Clarify) with { DateHint = "today" },
            "medicalWithMemory" => Valid(ParsedKind.Medical) with { Memory = memory },
            "weighInWithPortion" => Valid(ParsedKind.WeighIn) with { Portion = new(1, FoodUnit.Plate, null, null, false) },
            "editWithoutReference" => Edit with { Reference = null },
            "editWithoutChange" => Edit with { Portion = null },
            "editReplacementAndAmount" => Edit with { Items = [Food("bulgur")] },
            "editTwoReplacements" => Edit with { Portion = null, Items = [Food("bulgur"), Food("freekeh")] },
            "editEmptyMove" => Edit with { Portion = null, Move = new(null, null, null) },
            "editRelativeShare" => Edit with { Portion = new(null, null, 0.5m, null, false) },
            "editAmountWithoutUnit" => Edit with { Portion = new(150, null, null, null, false) },
            "editTopLevelDate" => Edit with { DateHint = "yesterday" },
            "deleteWithMove" => Valid(ParsedKind.DiaryDelete) with { Move = new(null, "Lunch", null) },
            "copyWithItems" => Valid(ParsedKind.DiaryCopy) with { Items = [Food()] },
            "copyEmptyTarget" => Valid(ParsedKind.DiaryCopy) with { Move = new(null, null, null) },
            "savedMealWithAmount" => Valid(ParsedKind.SavedMealLog) with { Portion = new(200, FoodUnit.G, null, null, false) },
            "savedMealBothShares" => Valid(ParsedKind.SavedMealLog) with { Portion = new(null, null, 0.5m, 2, false) },
            "saveBothSources" => Valid(ParsedKind.SavedMealCreate) with { Create = new("gym lunch", [], true) },
            "saveNoSource" => Valid(ParsedKind.SavedMealCreate) with { Reference = null },
            "saveBlankName" => Valid(ParsedKind.SavedMealCreate) with { Create = new(" ", [], false) },
            "saveWithoutCreate" => Valid(ParsedKind.SavedMealCreate) with { Create = null },
            "memoryDimensionOnAlias" => Valid(ParsedKind.MemoryChange) with { Memory = memory with { MemoryKind = ParsedMemoryKind.Alias, Value = "bar" } },
            "memoryDefaultWithoutDimension" => Valid(ParsedKind.MemoryChange) with { Memory = memory with { Dimension = null } },
            "memoryStateNotClosed" => Valid(ParsedKind.MemoryChange) with { Memory = memory with { Value = "boiled" } },
            "memoryFatNotClosed" => Valid(ParsedKind.MemoryChange) with { Memory = memory with { Dimension = ParsedMemoryDimension.Fat, Value = "butter" } },
            "memoryPortionWithoutAmount" => Valid(ParsedKind.MemoryChange) with { Memory = memory with { MemoryKind = ParsedMemoryKind.Portion, Dimension = null, Value = null } },
            "memoryAliasWithoutValue" => Valid(ParsedKind.MemoryChange) with { Memory = memory with { MemoryKind = ParsedMemoryKind.Alias, Dimension = null, Value = null } },
            "memoryWithoutSubject" => Valid(ParsedKind.MemoryChange) with { Memory = memory with { Subject = null } },
            "batchWithoutBatch" => Valid(ParsedKind.Batch) with { Batch = null },
            "batchWithoutIngredients" => Valid(ParsedKind.Batch) with { Items = [] },
            "batchCookedWithoutUnit" => Valid(ParsedKind.Batch) with { Batch = new("maqluba", 2500, null, null) },
            "batchEatenRest" => Valid(ParsedKind.Batch) with { Portion = new(null, null, null, null, true) },
            "portionRestAndAmount" => Valid(ParsedKind.BatchPortion) with { Portion = new(1, FoodUnit.Plate, null, null, true) },
            "portionMissing" => Valid(ParsedKind.BatchPortion) with { Portion = null },
            "portionEmpty" => Valid(ParsedKind.BatchPortion) with { Portion = new(null, null, null, null, false) },
            "portionFractionAboveOne" => Valid(ParsedKind.BatchPortion) with { Portion = new(null, null, 1.5m, null, false) },
            "closeWithPortion" => Valid(ParsedKind.BatchClose) with { Portion = new(null, null, null, null, true) },
            "personalFromCard" => Valid(ParsedKind.PersonalFoodCreate) with { Create = new("my bar", [], true) },
            "personalEmpty" => Valid(ParsedKind.PersonalFoodCreate) with { Stated = null },
            "personalSixAliases" => Valid(ParsedKind.PersonalFoodCreate) with { Create = new("my bar", ["a", "b", "c", "d", "e", "f"], false) },
            "personalStatedAllNull" => Valid(ParsedKind.PersonalFoodCreate) with { Stated = new(ParsedNutrientBasis.Per100g, null, null, null, null, null, null, null) },
            "personalWithReference" => Valid(ParsedKind.PersonalFoodCreate) with { Reference = Ref(0) },
            "batchInvalidIngredient" => Valid(ParsedKind.Batch) with { Items = [Food() with { Unit = null }] },
            _ => throw new ArgumentOutOfRangeException(nameof(mutation)),
        };
        Assert.Equal(expected, Check(intent)?.ToString());
    }

    [Theory]
    [InlineData("today", true)]
    [InlineData("yesterday", true)]
    [InlineData("daysAgo:2", true)]
    [InlineData("daysAgo:999", true)]
    [InlineData("lastWeekday:fri", true)]
    [InlineData("date:10-03", true)]
    [InlineData("date:02-29", true)]
    [InlineData("date:2024-02-29", true)]
    [InlineData("date:2026-10-03", true)]
    [InlineData("date:02-30", false)]
    [InlineData("date:04-31", false)]
    [InlineData("date:2026-13-01", false)]
    [InlineData("date:2025-02-29", false)]
    [InlineData("date:0000-01-01", false)]
    [InlineData("date:2026-1-03", false)]
    [InlineData("daysAgo:1", false)]
    [InlineData("daysAgo:1000", false)]
    [InlineData("lastWeekday:friday", false)]
    [InlineData("tomorrow", false)]
    [InlineData("last friday", false)]
    [InlineData("امبارح", false)]
    [InlineData("", false)]
    [InlineData("today\n", false)]
    [InlineData("date:2026-02-28\n", false)]
    [Trait("Req", "AI-090")]
    public void Day_hints_outside_the_closed_grammar_are_invalid(string hint, bool valid)
    {
        var expected = valid ? (InvalidOutput?)null : InvalidOutput.DayHint;
        Assert.Equal(valid, ProductionProtocol.Day(hint));
        Assert.Equal(expected, Check(Valid(ParsedKind.FoodLog) with { DateHint = hint }));
        Assert.Equal(expected, Check(Edit with { Reference = Ref(0) with { DateHint = hint } }));
        Assert.Equal(expected, Check(Edit with { Portion = null, Move = new(hint, "Lunch", null) }));
        Assert.Equal(expected, Check(Valid(ParsedKind.BatchPortion) with { DateHint = hint }));
    }

    [Theory]
    [InlineData("State", "raw", null)]
    [InlineData("State", null, null)]
    [InlineData("State", "crispy", "ClosedValue")]
    [InlineData("Fat", "oil", null)]
    [InlineData("Fat", "butter", "ClosedValue")]
    [InlineData("Variant", "chicken", null)]
    [Trait("Req", "AI-055")]
    public void Forget_values_stay_in_the_closed_state_and_fat_lists(string dimension, string? value, string? expected)
    {
        var forget = Intent(ParsedKind.MemoryChange) with { Memory = new(ParsedMemoryOperation.Forget, ParsedMemoryKind.Default, "rice", Enum.Parse<ParsedMemoryDimension>(dimension), value, null, null) };
        Assert.Equal(expected, Check(forget)?.ToString());
    }

    [Fact]
    [Trait("Req", "AI-055")]
    public void Memory_without_a_subject_food_needs_a_subject()
    {
        var memory = new ParsedMemory(ParsedMemoryOperation.Remember, ParsedMemoryKind.Portion, null, null, null, 350, FoodUnit.G);
        Assert.Equal(InvalidOutput.MixedGroups, Check(Intent(ParsedKind.MemoryChange) with { Memory = memory }));
        Assert.Null(Check(Intent(ParsedKind.MemoryChange) with { Memory = memory, Items = [Food("bowl", null)] }));
        Assert.Null(Check(Intent(ParsedKind.MemoryChange) with { Memory = memory with { Subject = "my bowl" } }));
    }

    [Theory]
    [InlineData("protein bar 250 kcal, 20g protein", "kcal=250;protein=20", true)]
    [InlineData("1,200 kcal per pack", "kcal=1200", true)]
    [InlineData("1,200 kcal per pack", "kcal=1.2", true)]
    [InlineData("fat 1,5 per 100g", "fat=1.5", true)]
    [InlineData("fat 1,5 per 100g", "fat=15", false)]
    [InlineData("protein 1,2,3 kcal 250", "protein=123;kcal=250", false)]
    [InlineData("12,345g tub, 250 kcal", "servingG=12345;kcal=250", true)]
    [InlineData("الدهون ١٫٥ غرام والسعرات ٢٥٠", "fat=1.5;kcal=250", true)]
    [InlineData("سعرات ۱۸۰ لكل ٤٠ غرام", "kcal=180;servingG=40", true)]
    [InlineData("40g serving, 180 kcal, 2.5g fiber", "servingG=40;kcal=180;fiber=2.5", true)]
    [InlineData("bar 250 kcal", "kcal=260", false)]
    [InlineData("bar 250 kcal", "kcal=250;protein=12", false)]
    [InlineData("2.5g fiber, 100 kcal", "fiber=25;kcal=100", false)]
    [InlineData("1,200 kcal", "kcal=12", false)]
    [InlineData("half a bar is 125 kcal", "kcal=250", false)]
    [InlineData("1,200.5 kcal", "kcal=1200.5", true)]
    [InlineData("1,200.5 kcal", "kcal=1.2005", false)]
    [Trait("Req", "AI-054")]
    public void AI_054_stated_nutrients_survive_only_when_literally_in_the_message(string text, string values, bool valid)
    {
        var map = values.Split(';').Select(v => v.Split('=')).ToDictionary(v => v[0], v => decimal.Parse(v[1], System.Globalization.CultureInfo.InvariantCulture));
        decimal? Get(string key) => map.TryGetValue(key, out var value) ? value : null;
        var stated = new ParsedStated(Get("servingG") is null ? ParsedNutrientBasis.Per100g : ParsedNutrientBasis.PerServing, Get("servingG"), null,
            Get("kcal"), Get("protein"), null, Get("fat"), Get("fiber"));
        var intent = Valid(ParsedKind.PersonalFoodCreate) with { Stated = stated };
        Assert.Equal(valid ? null : InvalidOutput.StatedNotLiteral, Check(intent, V2Input with { Text = text }));
    }
}
