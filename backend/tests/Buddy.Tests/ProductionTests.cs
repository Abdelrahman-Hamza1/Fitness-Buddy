using System.Text.Json;
using System.Text.Json.Nodes;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using FitnessBuddy.Modules.Catalog.Contracts;

namespace FitnessBuddy.Buddy.Tests;

public sealed class ProductionTests
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    internal static InterpretInput Input(string text = "200g cooked rice") => new(Guid.Parse("019a0000-0000-7000-8000-000000000001"), text,
        DateTimeOffset.Parse("2026-10-21T12:00:00Z", System.Globalization.CultureInfo.InvariantCulture), 180,
        new(false, null, null), [], null, new([], [], [], [], [], []));
    internal static ParsedFood Rice(FoodState? state = FoodState.Cooked, BuddyRange? estimate = null) => new("200g cooked rice", "rice", null, 200,
        FoodUnit.G, true, state, null, null, [], estimate);
    internal static ParsedIntent Intent(ParsedKind kind) => new(kind, null, null, null, null, [], null, null, null, null, null, null, null, null, null, null);
    internal static ParsedMessage Parsed(ParsedFood? food = null) => new(MessageLanguage.English, MessageScript.Latin,
        [Intent(ParsedKind.FoodLog) with { Items = [food ?? Rice()] }]);
    internal static ParsedMessage Message(params ParsedIntent[] intents) => new(MessageLanguage.English, MessageScript.Latin, intents);

    [Fact]
    [Trait("Rule", "06.9-prompt-schema-versioning")]
    public async Task Production_schema_matches_its_versioned_snapshot()
    {
        Assert.True(JsonNode.DeepEquals(JsonNode.Parse(await File.ReadAllTextAsync(Path.Combine(AppContext.BaseDirectory, "production-schema.json"), Ct)),
            JsonNode.Parse(ProductionProtocol.Schema.GetRawText())));
        Assert.Contains(ProductionProtocol.Version, ProductionProtocol.Prompt, StringComparison.Ordinal);
        Assert.Equal("interpret-v2", ProductionProtocol.Version);
    }

    [Fact]
    [Trait("Req", "AI-070")]
    [Trait("Req", "AI-023")]
    public async Task Real_state_facts_override_model_estimates_and_personal_candidates_win()
    {
        var catalog = new FakeCatalog();
        var resolver = new ResolveInterpretation(catalog);
        var fakeRange = new BuddyRange(new(500, 2, 3, 4, 5), new(700, 3, 4, 5, 6));
        var result = await resolver.ResolveAsync(Parsed(Rice(estimate: fakeRange)), Input(), Ct);
        var item = Assert.Single(Assert.IsType<BuddyFoodLog>(Assert.Single(result.Intents)).Items);
        Assert.Equal("rice/cooked", item.Match!.Key); Assert.Equal(130, item.Match.Nutrients.Kcal); Assert.Null(item.Estimate);
        Assert.Equal("cooked", Assert.Single(catalog.Mentions).State);
        var personal = new PersonalFood(Guid.Parse("019a0000-0000-7000-8000-000000000002"), ["rice"], [], "cooked", new(140, 1, 2, 3, 4), []);
        catalog.Mentions.Clear();
        var input = Input() with { Context = Input().Context with { PersonalFoods = [personal] } };
        result = await resolver.ResolveAsync(Parsed(), input, Ct);
        item = Assert.Single(Assert.IsType<BuddyFoodLog>(Assert.Single(result.Intents)).Items);
        Assert.Equal("personal", item.Match!.Source); Assert.Equal(140, item.Match.Nutrients.Kcal); Assert.Empty(catalog.Mentions);
    }

    [Fact]
    [Trait("Req", "AI-151")]
    [Trait("Req", "AI-041")]
    public async Task Unmatched_food_requires_badged_range_and_alternatives_are_distinct()
    {
        var catalog = new FakeCatalog { Empty = true }; var resolver = new ResolveInterpretation(catalog);
        var range = new BuddyRange(new(100, 1, 1, 1, 1), new(200, 2, 2, 2, 2));
        var result = await resolver.ResolveAsync(Parsed(Rice(estimate: range)), Input(), Ct);
        var item = Assert.Single(Assert.IsType<BuddyFoodLog>(Assert.Single(result.Intents)).Items);
        Assert.Null(item.Match); Assert.Equal(range, item.Estimate!.Range); Assert.Equal("noCatalogMatch", item.Estimate.Reason);
        result = await resolver.ResolveAsync(Parsed(), Input(), Ct); Assert.IsType<BuddyClarify>(Assert.Single(result.Intents));
        catalog.Empty = false; catalog.Many = true;
        result = await resolver.ResolveAsync(Parsed(), Input(), Ct);
        item = Assert.Single(Assert.IsType<BuddyFoodLog>(Assert.Single(result.Intents)).Items);
        Assert.Equal(3, item.Alternatives.Length); Assert.Equal(4, item.Alternatives.Prepend(item.Match!).Select(c => c.Key).Distinct().Count());
    }

    [Fact]
    [Trait("Req", "AC-041")]
    public void Provider_context_omits_identifiers_nutrition_and_unknown_output_is_rejected()
    {
        var input = Input() with { ActiveProposal = Guid.Parse("019a0000-0000-7000-8000-000000000099") };
        Guid Id(int n) => Guid.Parse($"019a0000-0000-7000-8000-{n:D12}");
        input = input with
        {
            Slots = [new(Id(6), "Breakfast", "morning")],
            Context = new(
            [new(Id(2), ["my shake"], [], "raw", new(9876, 1, 2, 3, 4), [])],
            [new(Id(3), "my meal")], [new(Id(4), "my batch")], [new("default", "food state", "raw")],
            [new(Id(5), new DateOnly(2026, 10, 21), "Breakfast", "food", 99999)], [new(Id(7), "custom lift")])
        };
        var text = ProductionProtocol.Input(input);
        foreach (var id in Enumerable.Range(2, 6)) { Assert.DoesNotContain(Id(id).ToString(), text, StringComparison.Ordinal); }
        Assert.DoesNotContain("9876", text, StringComparison.Ordinal); Assert.DoesNotContain("99999", text, StringComparison.Ordinal);
        Assert.DoesNotContain(input.RequestId.ToString(), text, StringComparison.Ordinal);
        Assert.DoesNotContain(input.ActiveProposal.ToString()!, text, StringComparison.Ordinal);
        Assert.DoesNotContain("requestId", text, StringComparison.Ordinal); Assert.DoesNotContain("nutrients", text, StringComparison.Ordinal);
        var node = JsonSerializer.SerializeToNode(Parsed(), InterpretProtocol.Json)!.AsObject();
        ParsedMessage? Parse(string text) => ProductionProtocol.Parse(text, input).Message;
        Assert.NotNull(Parse(node.ToJsonString())); node["account"] = "secret"; Assert.Null(Parse(node.ToJsonString())); node.Remove("account");
        node["intents"]![0]!["items"]![0]!["amount"] = -1; Assert.Equal(InvalidOutput.Food, ProductionProtocol.Parse(node.ToJsonString(), input).Invalid);
        node["intents"] = new JsonArray(); Assert.Equal(InvalidOutput.Bounds, ProductionProtocol.Parse(node.ToJsonString(), input).Invalid);
        Assert.Equal(InvalidOutput.Shape, ProductionProtocol.Parse("{", input).Invalid);
    }

    [Fact]
    [Trait("Req", "AI-015")]
    [Trait("Req", "SF-030")]
    public async Task Multiple_intents_keep_script_and_medical_is_a_closed_template_input()
    {
        var parsed = Parsed() with
        {
            Language = MessageLanguage.Arabic,
            Script = MessageScript.Arabizi,
            Intents = [Parsed().Intents[0], Intent(ParsedKind.WeighIn) with { WeighIn = new(97.2m, "kg") }, Intent(ParsedKind.Medical)]
        };
        var result = await new ResolveInterpretation(new FakeCatalog()).ResolveAsync(parsed, Input(), Ct);
        Assert.Equal(3, result.Intents.Length); Assert.IsType<BuddyWeighIn>(result.Intents[1]); Assert.IsType<BuddyMedical>(result.Intents[2]);
        Assert.All(result.Intents, i => { Assert.Equal("arabic", i.Language); Assert.Equal("arabizi", i.Script); });
    }

    [Fact]
    [Trait("Req", "AI-041")]
    [Trait("Req", "AI-023")]
    public async Task Ambiguity_selection_keeps_late_other_state_and_preserves_stated_variant()
    {
        var catalog = new FakeCatalog { Many = true, LateRaw = true };
        var food = Rice(null) with { Ambiguities = [AmbiguityKind.State] };
        var result = await new ResolveInterpretation(catalog).ResolveAsync(Parsed(food), Input(), Ct);
        var item = Assert.Single(Assert.IsType<BuddyFoodLog>(Assert.Single(result.Intents)).Items);
        Assert.Contains(item.Alternatives, c => c.State == "raw");
        Assert.Contains(item.Dimensions.Single().Options, o => o.Candidate!.State == "raw");
        food = Rice() with { Variant = "1%" };
        result = await new ResolveInterpretation(catalog).ResolveAsync(Parsed(food), Input(), Ct);
        Assert.Equal("rice 1%", catalog.Mentions.Last().CanonicalEn);
        item = Assert.Single(Assert.IsType<BuddyFoodLog>(Assert.Single(result.Intents)).Items);
        Assert.Equal("1%", item.Dimensions.Single(d => d.Kind == "variant").StatedValue);
        food = Rice() with { Ambiguities = [AmbiguityKind.State] };
        result = await new ResolveInterpretation(catalog).ResolveAsync(Parsed(food), Input(), Ct);
        Assert.Equal("cooked", Assert.IsType<BuddyFoodLog>(result.Intents[0]).Items[0].Dimensions.Single().StatedValue);
    }

    [Fact]
    [Trait("Req", "AI-151")]
    [Trait("Req", "FD-012")]
    public void Impossible_per100gram_model_estimates_are_rejected()
    {
        Assert.False(ProductionProtocol.ValidRange(new(new(5000, 500, 500, 500, 500), new(5000, 500, 500, 500, 500))));
        Assert.False(ProductionProtocol.ValidRange(new(new(500, 100, 100, 100, 0), new(500, 100, 100, 100, 0))));
        Assert.False(ProductionProtocol.ValidRange(new(new(200, 1, 2, 3, 0), new(100, 1, 2, 3, 0))));
        Assert.True(ProductionProtocol.ValidRange(new(new(800, 0, 0, 90, 0), new(900, 0, 0, 100, 0))));
    }

    [Fact]
    [Trait("Req", "AI-070")]
    public async Task Generic_Arabic_or_fuzzy_search_cannot_override_stated_percentage()
    {
        var catalog = new FakeCatalog { WrongVariant = true };
        var food = Rice() with { NameAr = "حليب", Variant = "1%" };
        var result = await new ResolveInterpretation(catalog).ResolveAsync(Parsed(food), Input(), Ct);
        Assert.IsType<BuddyClarify>(Assert.Single(result.Intents));
        food = food with { Variant = null, CanonicalNameEn = "rice 1%" };
        result = await new ResolveInterpretation(catalog).ResolveAsync(Parsed(food), Input(), Ct);
        Assert.IsType<BuddyClarify>(Assert.Single(result.Intents));
        catalog.WrongVariant = false;
        food = food with { CanonicalNameEn = "rice", Variant = "1%" };
        result = await new ResolveInterpretation(catalog).ResolveAsync(Parsed(food), Input(), Ct);
        Assert.Contains("1%", Assert.IsType<BuddyFoodLog>(Assert.Single(result.Intents)).Items[0].Match!.NameEn, StringComparison.Ordinal);
        catalog.NameOverride = "rice 3.25%"; catalog.EmptyVariantQuery = true;
        result = await new ResolveInterpretation(catalog).ResolveAsync(Parsed(food with { Variant = "3%" }), Input(), Ct);
        Assert.Equal("rice 3.25%", Assert.IsType<BuddyFoodLog>(Assert.Single(result.Intents)).Items[0].Match!.NameEn);
        result = await new ResolveInterpretation(catalog).ResolveAsync(Parsed(food with { Variant = "3.0%" }), Input(), Ct);
        Assert.IsType<BuddyClarify>(Assert.Single(result.Intents));
        result = await new ResolveInterpretation(catalog).ResolveAsync(Parsed(food with { Variant = "1%" }), Input(), Ct);
        Assert.IsType<BuddyClarify>(Assert.Single(result.Intents));
    }

    [Fact]
    [Trait("Req", "AI-070")]
    public async Task Personal_alias_in_an_amount_phrase_precedes_generic_canonical_name()
    {
        var personal = new PersonalFood(Guid.Parse("019a0000-0000-7000-8000-000000000002"), ["owner shake"], ["my shake"], "raw", new(140, 1, 2, 3, 4), []);
        var generic = personal with { Id = Guid.Parse("019a0000-0000-7000-8000-000000000001"), Names = ["shake"], Aliases = [] };
        var input = Input() with { Context = Input().Context with { PersonalFoods = [generic, personal] } };
        var catalog = new FakeCatalog();
        var food = Rice(null) with { Mention = "200g my shake", CanonicalNameEn = "protein shake" };
        var result = await new ResolveInterpretation(catalog).ResolveAsync(Parsed(food), input, Ct);
        Assert.Equal(personal.Id.ToString(), Assert.IsType<BuddyFoodLog>(Assert.Single(result.Intents)).Items[0].Match!.Key);
        Assert.Empty(catalog.Mentions);
    }

    [Fact]
    [Trait("Rule", "06.9-prompt-schema-versioning")]
    public void V2_schema_stays_within_documented_limits_and_our_budget()
    {
        // OpenAI strict structured outputs (RQ1, 2026-10-28): nesting 10, 5,000 properties, 1,000 enum values,
        // 120,000 characters of names/enum values, no anyOf at the root; const avoided. Our budget (PA14): depth 5, ~150 properties.
        var schema = JsonNode.Parse(ProductionProtocol.Schema.GetRawText())!.AsObject();
        int properties = 0, enumValues = 0, depth = 0, nameChars = 0; var consts = 0; var largestEnum = 0;
        void Walk(JsonNode? node, int level)
        {
            if (node is JsonArray array) { foreach (var child in array) { Walk(child, level); } return; }
            if (node is not JsonObject obj) { return; }
            var type = obj["type"];
            var isObject = type is JsonValue v && v.GetValue<string>() == "object" || type is JsonArray types && types.Any(t => t?.GetValue<string>() == "object");
            if (isObject) { level++; depth = Math.Max(depth, level); }
            if (obj["properties"] is JsonObject props) { properties += props.Count; nameChars += props.Sum(p => p.Key.Length); }
            if (obj["enum"] is JsonArray values)
            {
                var named = values.Where(e => e is not null).Select(e => e!.GetValue<string>()).ToArray();
                enumValues += named.Length; nameChars += named.Sum(e => e.Length); largestEnum = Math.Max(largestEnum, named.Length);
            }
            if (obj.ContainsKey("const")) { consts++; }
            foreach (var (_, child) in obj) { Walk(child, level); }
        }
        Walk(schema, 0);
        Assert.Equal("object", schema["type"]!.GetValue<string>()); Assert.False(schema.ContainsKey("anyOf"));
        Assert.Equal(0, consts); Assert.DoesNotContain(schema, p => p.Key is "$defs" or "definitions");
        Assert.InRange(depth, 1, 10); Assert.InRange(properties, 1, 5000); Assert.InRange(enumValues, 1, 1000);
        Assert.InRange(nameChars, 1, 120_000); Assert.InRange(largestEnum, 1, 500);
        Assert.InRange(depth, 1, 5); Assert.InRange(properties, 1, 150);
        // The numbers at the WP2 snapshot; a grammar change moves them deliberately (with a new snapshot).
        Assert.Equal((5, 81, 97), (depth, properties, enumValues));
    }

    [Fact]
    [Trait("Req", "AI-091")]
    public void V2_schema_kind_enum_has_no_ambiguity_kind()
    {
        var kinds = JsonNode.Parse(ProductionProtocol.Schema.GetRawText())!["properties"]!["intents"]!["items"]!["properties"]!["kind"]!["enum"]!
            .AsArray().Select(k => k!.GetValue<string>()).ToArray();
        Assert.Equal(["foodLog", "clarify", "outOfScope", "medical", "weighIn", "diaryEdit", "diaryDelete", "diaryCopy", "savedMealLog",
            "savedMealCreate", "memoryChange", "batch", "batchPortion", "batchClose", "personalFoodCreate"], kinds);
        Assert.DoesNotContain(kinds, k => k.Contains("ambig", StringComparison.OrdinalIgnoreCase));
        Assert.Equal(15, Enum.GetValues<ParsedKind>().Length);
    }

    [Fact]
    [Trait("Rule", "06.9-prompt-schema-versioning")]
    public async Task Resolved_interpretation_reports_the_production_prompt_version()
    {
        var result = await new ResolveInterpretation(new FakeCatalog()).ResolveAsync(Parsed(), Input(), Ct);
        Assert.Equal(ProductionProtocol.Version, result.PromptVersion); Assert.Equal("interpret-v2", result.PromptVersion);
        result = await new ResolveInterpretation(new FakeCatalog()).ResolveAsync(Message(Intent(ParsedKind.BatchClose)), Input(), Ct);
        Assert.Equal(ProductionProtocol.Version, result.PromptVersion);
    }

    [Fact]
    [Trait("Rule", "06.10-latency-cost")]
    public void Ten_intent_v2_fixture_fits_the_output_token_budget()
    {
        // D15: routing keeps 1,600 max output tokens. Ten intents (the bound), each kind the server routes once, with
        // typical content. Conservative offline count: one token per 3 ASCII chars (this JSON measures ~3.2 chars per o200k
        // token; every absent member costs ~4 tokens, e.g. `,"memory":null`) plus one per non-ASCII char. Reasoning tokens
        // share the same cap and can't be counted offline; WP7 records the real totals. Ten intents with several food items
        // each don't fit (about 1,780 by this count for nine items), in v1 as in v2: the cap bounds message size, not the grammar.
        var input = ValidationInput("250 kcal 12g protein per 100g");
        ParsedFood Food(string name, string ar, decimal? amount, FoodUnit? unit, FoodState? state = null, BuddyRange? estimate = null) =>
            new(name, name, ar, amount, unit, amount is not null, state, null, null, amount is null ? [AmbiguityKind.Portion] : [], estimate);
        var range = new BuddyRange(new(150, 6, 15, 6, 1), new(220, 10, 22, 11, 2));
        var message = new ParsedMessage(MessageLanguage.Mixed, MessageScript.Mixed,
        [
            Intent(ParsedKind.FoodLog) with { SlotHint = "Breakfast", DateHint = "today", TimeHint = "this morning",
                Items = [Food("fried egg", "بيض مقلي", 2, FoodUnit.Piece, FoodState.Fried), Food("chicken maqluba", "مقلوبة دجاج", 1, FoodUnit.Plate, estimate: range)] },
            Intent(ParsedKind.WeighIn) with { WeighIn = new(97.2m, "kg"), DateHint = "today" },
            Intent(ParsedKind.DiaryEdit) with { Reference = new([0, 1], "the rice", ParsedScope.One, "yesterday", "Lunch"), Items = [Food("bulgur", "برغل", null, null, FoodState.Cooked)] },
            Intent(ParsedKind.DiaryDelete) with { Reference = new([2], "the pepsi", ParsedScope.All, null, null) },
            Intent(ParsedKind.DiaryCopy) with { DateHint = "yesterday", SlotHint = "Breakfast", Move = new("today", null, null) },
            Intent(ParsedKind.SavedMealLog) with { ListRef = 0, SlotHint = "Dinner", Portion = new(null, null, 0.5m, null, false) },
            Intent(ParsedKind.SavedMealCreate) with { Create = new("gym lunch", [], false), Reference = new([], "lunch", ParsedScope.All, "yesterday", "Lunch") },
            Intent(ParsedKind.MemoryChange) with { Memory = new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Default, "rice", ParsedMemoryDimension.State, "raw", null, null) },
            Intent(ParsedKind.Batch) with { Batch = new("maqluba", 2.5m, FoodUnit.Kg, ParsedBatchPath.Leftovers), Portion = new(1, FoodUnit.Plate, null, null, false),
                Items = [Food("rice", "رز", 500, FoodUnit.G, FoodState.Raw), Food("chicken", "دجاج", 1, FoodUnit.Kg, FoodState.Raw)] },
            Intent(ParsedKind.PersonalFoodCreate) with { Create = new("my protein bar", ["bar"], false),
                Stated = new(ParsedNutrientBasis.Per100g, null, null, 250, 12, null, null, null) },
        ]);
        Assert.Null(ProductionProtocol.Validate(message, input));
        var json = JsonSerializer.Serialize(message, InterpretProtocol.Json);
        var ascii = json.Count(c => c < 128);
        var tokens = (int)Math.Ceiling(ascii / 3.0) + json.Length - ascii;
        Assert.InRange(tokens, 1, 1600);
        TestContext.Current.TestOutputHelper?.WriteLine($"ten-intent v2 fixture: {json.Length} chars, conservative {tokens} output tokens");
    }

    [Fact]
    [Trait("Req", "AC-041")]
    [Trait("Req", "AI-091")]
    public void Provider_projection_uses_list_indexes_and_never_ids_grams_or_nutrients()
    {
        Guid Id(int n) => Guid.Parse($"019a0000-0000-7000-8000-{n:D12}");
        var input = ValidationInput("make it 3 eggs") with
        {
            ActiveProposal = Id(90),
            Slots = [new(Id(80), "Breakfast", "morning")],
        };
        input = input with
        {
            Context = input.Context with
            {
                PersonalFoods = [new(Id(70), ["canary shake"], ["canary alias"], "raw", new(9876, 1, 2, 3, 4), [new("scoop", 31.7, null, null, null, "label")])],
                ActiveCard = new("canary-card-slot", "08:30", [new("canary-card-line", 2, "piece", "fried"), new("canary-second-line", null, null, null)]),
            },
        };
        var text = ProductionProtocol.Input(input);
        var ids = new[] { input.RequestId, input.ActiveProposal!.Value }.Concat(input.Slots.Select(s => s.Id)).Concat(input.Context.PersonalFoods.Select(f => f.Id))
            .Concat(input.Context.RecentEntries.Select(r => r.Id)).Concat(input.Context.SavedMeals.Select(r => r.Id)).Concat(input.Context.OpenBatches.Select(r => r.Id));
        foreach (var id in ids) { Assert.DoesNotContain(id.ToString(), text, StringComparison.OrdinalIgnoreCase); }
        foreach (var leak in new[] { "9876", "31.7", "77777", "requestId", "activeProposal", "nutrients", "grams", "servings", "\"id\"" })
        { Assert.DoesNotContain(leak, text, StringComparison.Ordinal); }
        var root = JsonNode.Parse(text)!.AsObject();
        static string[] Keys(JsonNode? node) => node!.AsObject().Select(p => p.Key).ToArray();
        Assert.Equal(["text", "now", "tzOffsetMin", "ramadan", "slots", "personalFoods", "memory", "recentEntries", "savedMeals", "openBatches", "customExercises", "activeCard"], Keys(root));
        Assert.All(root["recentEntries"]!.AsArray(), (e, i) => { Assert.Equal(["ref", "date", "slot", "name"], Keys(e)); Assert.Equal(i, e!["ref"]!.GetValue<int>()); });
        Assert.All(root["savedMeals"]!.AsArray(), (e, i) => { Assert.Equal(["ref", "name"], Keys(e)); Assert.Equal(i, e!["ref"]!.GetValue<int>()); });
        Assert.All(root["openBatches"]!.AsArray(), (e, i) => { Assert.Equal(["ref", "name"], Keys(e)); Assert.Equal(i, e!["ref"]!.GetValue<int>()); });
        Assert.Equal(3, root["recentEntries"]!.AsArray().Count); Assert.Equal(2, root["savedMeals"]!.AsArray().Count);
        Assert.Equal(["names", "aliases", "state"], Keys(root["personalFoods"]![0]));
        // The active card goes through an allowlist: slot, time and each line's name/amount/unitCode/state (A22 PA6), nothing else.
        var card = root["activeCard"]!;
        Assert.Equal(["slot", "time", "lines"], Keys(card)); Assert.Equal("canary-card-slot", card["slot"]!.GetValue<string>());
        Assert.All(card["lines"]!.AsArray(), line => Assert.Equal(["name", "amount", "unitCode", "state"], Keys(line)));
        Assert.Equal(["canary-card-line", "canary-second-line"], card["lines"]!.AsArray().Select(l => l!["name"]!.GetValue<string>()));
        Assert.Equal(1, text.Split("canary-card-line").Length - 1);
        Assert.Null(JsonNode.Parse(ProductionProtocol.Input(input with { Context = input.Context with { ActiveCard = null } }))!["activeCard"]);
    }

    internal static InterpretInput ValidationInput(string text)
    {
        Guid Id(int n) => Guid.Parse($"019a0000-0000-7000-8000-{n:D12}");
        return Input(text) with
        {
            Context = new([],
                [new(Id(30), "usual breakfast"), new(Id(31), "gym shake")],
                [new(Id(40), "maqluba batch")],
                [new("default", "rice", "state:raw")],
                [new(Id(20), new DateOnly(2026, 10, 21), "Lunch", "rice", 77777), new(Id(21), new DateOnly(2026, 10, 21), "Lunch", "rice", 150),
                    new(Id(22), new DateOnly(2026, 10, 20), "Dinner", "pepsi", 330)],
                [new(Id(50), "custom lift")]),
        };
    }

    internal sealed class FakeCatalog : IFoodResolver
    {
        public List<FoodMention> Mentions { get; } = [];
        public bool Empty { get; set; }
        public bool Many { get; set; }
        public bool LateRaw { get; set; }
        public bool WrongVariant { get; set; }
        public bool EmptyVariantQuery { get; set; }
        public string? NameOverride { get; set; }
        public Task<IReadOnlyList<FoodCandidate>> ResolveAsync(FoodMention mention, CancellationToken cancellationToken)
        {
            Mentions.Add(mention);
            return Task.FromResult<IReadOnlyList<FoodCandidate>>(Empty || EmptyVariantQuery && mention.CanonicalEn!.Contains('%', StringComparison.Ordinal) ? [] : Enumerable.Range(0, Many ? 6 : 1).Select(i => new FoodCandidate(Many ? "rice/" + i : "rice/cooked", NameOverride ?? (WrongVariant ? "rice 3%" : mention.CanonicalEn!), null, LateRaw && i == 5 ? "raw" : "cooked", "basic", 1)).ToArray());
        }
        public Task<FoodDetails?> DetailsAsync(string key, CancellationToken cancellationToken) => Task.FromResult<FoodDetails?>(new(key, NameOverride ?? (WrongVariant ? "rice 3%" : Mentions.Last().CanonicalEn!), null, LateRaw && key == "rice/5" ? "raw" : "cooked", "usda", new(130, 2, 28, 0, 0), null, [], null, "rice"));
    }
}
