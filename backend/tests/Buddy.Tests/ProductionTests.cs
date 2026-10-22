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
    internal static ParsedMessage Parsed(ParsedFood? food = null) => new(MessageLanguage.English, MessageScript.Latin,
        [new(ParsedKind.FoodLog, null, null, null, [food ?? Rice()], null, null)]);

    [Fact]
    [Trait("Rule", "06.9-prompt-schema-versioning")]
    public async Task Production_schema_matches_its_versioned_snapshot()
    {
        Assert.True(JsonNode.DeepEquals(JsonNode.Parse(await File.ReadAllTextAsync(Path.Combine(AppContext.BaseDirectory, "production-schema.json"), Ct)),
            JsonNode.Parse(ProductionProtocol.Schema.GetRawText())));
        Assert.Contains("interpret-v1", ProductionProtocol.Prompt, StringComparison.Ordinal);
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
        Assert.NotNull(ProductionProtocol.Parse(node.ToJsonString())); node["account"] = "secret"; Assert.Null(ProductionProtocol.Parse(node.ToJsonString())); node.Remove("account");
        node["intents"]![0]!["items"]![0]!["amount"] = -1; Assert.Null(ProductionProtocol.Parse(node.ToJsonString()));
        node["intents"] = new JsonArray(); Assert.Null(ProductionProtocol.Parse(node.ToJsonString()));
        Assert.Null(ProductionProtocol.Parse("{"));
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
            Intents = [Parsed().Intents[0], new(ParsedKind.WeighIn, null, null, null, [], new(97.2m, "kg"), null), new(ParsedKind.Medical, null, null, null, [], null, null)]
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

    private sealed class FakeCatalog : IFoodResolver
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
