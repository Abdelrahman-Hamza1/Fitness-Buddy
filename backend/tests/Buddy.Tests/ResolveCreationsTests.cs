using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using FitnessBuddy.Modules.Catalog.Contracts;
using static FitnessBuddy.Buddy.Tests.ProductionTests;
using static FitnessBuddy.Buddy.Tests.ResolveReferencesTests;

namespace FitnessBuddy.Buddy.Tests;

/// <summary>B09a WP4: memory, batches and personal foods resolve through the shared food resolver and request batch IDs (D9–D12, PA5, PA8).</summary>
public sealed class ResolveCreationsTests
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    private static readonly BuddyRange DishRange = new(new(150, 6, 15, 6, 1), new(220, 10, 22, 11, 2));

    internal static InterpretInput CreationInput(string text) => ReferenceInput(text) with
    {
        Context = ReferenceInput(text).Context with { OpenBatches = [new(Id(40), "maqluba batch"), new(Id(41), "mjadara")] },
    };
    private static ParsedFood Food(string name, decimal? amount = null, FoodUnit? unit = null, FoodState? state = null, BuddyRange? estimate = null, string? ar = null) =>
        new(name, name, ar, amount, unit, amount is not null, state, null, null, [], estimate);
    private static ParsedIntent Memory(ParsedMemory memory, params ParsedFood[] items) => Intent(ParsedKind.MemoryChange) with { Memory = memory, Items = items };

    private static async Task<BuddyIntent[]> ResolveAsync(InterpretInput input, IFoodResolver? catalog, params ParsedIntent[] intents)
    {
        var message = Message(intents);
        Assert.Null(ProductionProtocol.Validate(message, input)); // the fixtures are valid v2 outputs
        return (await new ResolveInterpretation(catalog ?? new FakeCatalog()).ResolveAsync(message, input, Ct)).Intents;
    }

    [Fact]
    [Trait("Req", "AI-055")]
    public async Task AI_055_memory_default_resolves_a_real_subject_food_and_a_closed_value()
    {
        // T25 "I always weigh rice raw" and "I cook with 1 tbsp oil".
        var input = CreationInput("I always weigh rice raw, I cook with 1 tbsp oil");
        var catalog = new RecordingCatalog(new FakeCatalog());
        var intents = await ResolveAsync(input, catalog,
            Memory(new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Default, "rice", ParsedMemoryDimension.State, "raw", null, null), Food("rice", state: FoodState.Raw)),
            Memory(new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Default, "oil", ParsedMemoryDimension.Fat, "oil", 1, FoodUnit.Tbsp)));
        var state = Assert.IsType<BuddyMemoryChange>(intents[0]);
        Assert.Equal((BuddyMemoryOperation.Remember, BuddyMemoryKind.Default, "rice", (BuddyMemoryDimension?)BuddyMemoryDimension.State, "raw"),
            (state.Operation, state.MemoryKind, state.Subject, state.Dimension, state.Value));
        Assert.Null(state.Amount);
        Assert.Equal("rice/cooked", state.Food!.Match!.Key); Assert.Null(state.Food.Estimate);
        var fat = Assert.IsType<BuddyMemoryChange>(intents[1]);
        Assert.Equal((BuddyMemoryDimension?)BuddyMemoryDimension.Fat, fat.Dimension); Assert.Equal("oil", fat.Value);
        Assert.Equal(new BuddyAmount(1, "tbsp", true), fat.Amount); Assert.Null(fat.Food);
        AssertProvenance(intents, input, catalog.Keys);

        // D10: memory never keys on an estimate; an unmatched subject food is null and the subject stays as said.
        var unmatched = await ResolveAsync(input, new FakeCatalog { Empty = true },
            Memory(new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Default, "my maqluba", ParsedMemoryDimension.Variant, "chicken", null, null),
                Food("maqluba", estimate: DishRange, ar: "مقلوبة")));
        var variant = Assert.IsType<BuddyMemoryChange>(Assert.Single(unmatched));
        Assert.Null(variant.Food); Assert.Equal(("my maqluba", "chicken"), (variant.Subject, variant.Value));
    }

    [Fact]
    [Trait("Req", "AI-055")]
    public async Task AI_055_portion_memory_keeps_the_stated_amount_forget_is_typed()
    {
        var input = CreationInput("my bowl is 350g, forget that my shake is called canary");
        var intents = await ResolveAsync(input, null,
            Memory(new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Portion, "my bowl", null, null, 350, FoodUnit.G)),
            Memory(new(ParsedMemoryOperation.Forget, ParsedMemoryKind.Alias, "canary", null, null, null, null)),
            Memory(new(ParsedMemoryOperation.Forget, ParsedMemoryKind.Default, "rice", ParsedMemoryDimension.State, null, null, null), Food("rice")));
        var portion = Assert.IsType<BuddyMemoryChange>(intents[0]);
        Assert.Equal(new BuddyMemoryChange("english", "latin", BuddyMemoryOperation.Remember, BuddyMemoryKind.Portion, "my bowl", null, null, new(350, "g", true), null), portion);
        var alias = Assert.IsType<BuddyMemoryChange>(intents[1]);
        Assert.Equal((BuddyMemoryOperation.Forget, BuddyMemoryKind.Alias, "canary"), (alias.Operation, alias.MemoryKind, alias.Subject));
        // Forget of a default matches local memory on memoryKind + food.match.key (contract), so the food is carried.
        var forget = Assert.IsType<BuddyMemoryChange>(intents[2]);
        Assert.Equal((BuddyMemoryOperation.Forget, (BuddyMemoryDimension?)BuddyMemoryDimension.State), (forget.Operation, forget.Dimension));
        Assert.Equal("rice/cooked", forget.Food!.Match!.Key);
        var json = JsonSerializer.SerializeToNode<BuddyIntent>(forget, InterpretProtocol.Json)!;
        Assert.Equal(("memoryChange", "forget", "default", "state"), (json["kind"]!.GetValue<string>(), json["operation"]!.GetValue<string>(),
            json["memoryKind"]!.GetValue<string>(), json["dimension"]!.GetValue<string>()));
    }

    [Fact]
    [Trait("Req", "AI-055")]
    public async Task AI_055_memory_whose_food_is_dropped_keeps_the_mention_as_subject()
    {
        // No subject from the model and no real match: the statement still says what it is about (D10 drops only the food).
        var input = CreationInput("my freekeh bowl is 350g");
        var intents = await ResolveAsync(input, new FakeCatalog { Empty = true },
            Memory(new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Portion, null, null, null, 350, FoodUnit.G), Food("freekeh bowl", estimate: DishRange)),
            Memory(new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Portion, "my bowl", null, null, 300, FoodUnit.G), Food("bowl")));
        var dropped = Assert.IsType<BuddyMemoryChange>(intents[0]);
        Assert.Null(dropped.Food); Assert.Equal("freekeh bowl", dropped.Subject);
        Assert.Equal("my bowl", Assert.IsType<BuddyMemoryChange>(intents[1]).Subject); // a stated subject wins
        var matched = Assert.IsType<BuddyMemoryChange>(Assert.Single(await ResolveAsync(input, null,
            Memory(new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Portion, null, null, null, 350, FoodUnit.G), Food("rice")))));
        Assert.Null(matched.Subject); Assert.Equal("rice/cooked", matched.Food!.Match!.Key); // the food is the subject
    }

    [Fact]
    [Trait("Rule", "04.4.1-contract-first")]
    public void Internal_and_public_enums_keep_the_same_names()
    {
        // ResolveCreations maps these by name; a renamed or added member must fail here, not at runtime.
        Assert.Equal(Enum.GetNames<ParsedMemoryOperation>(), Enum.GetNames<BuddyMemoryOperation>());
        Assert.Equal(Enum.GetNames<ParsedMemoryKind>(), Enum.GetNames<BuddyMemoryKind>());
        Assert.Equal(Enum.GetNames<ParsedMemoryDimension>(), Enum.GetNames<BuddyMemoryDimension>());
        Assert.Equal(Enum.GetNames<ParsedNutrientBasis>(), Enum.GetNames<BuddyNutrientBasis>());
        Assert.Equal(Enum.GetNames<ParsedBatchPath>(), Enum.GetNames<BuddyBatchPath>());
        Assert.Equal(Enum.GetNames<ParsedScope>(), Enum.GetNames<BuddyReferenceScope>());
    }

    [Fact]
    [Trait("Req", "AI-100")]
    [Trait("Req", "DY-040")]
    [Trait("Req", "DY-042")]
    public async Task AI_100_batch_keeps_ingredients_states_cooked_weight_path_hint_and_eaten_now_portion()
    {
        // T20 "I cooked maqluba: 500g raw rice and 1kg raw chicken, 2.5kg cooked, for the week; ate a plate for dinner".
        var input = CreationInput("I cooked maqluba: 500g raw rice and 1kg raw chicken, 2.5kg cooked, for the week; ate a plate for dinner");
        var catalog = new RecordingCatalog(new FakeCatalog());
        var batch = Assert.IsType<BuddyBatch>(Assert.Single(await ResolveAsync(input, catalog,
            Intent(ParsedKind.Batch) with
            {
                Batch = new("maqluba", 2.5m, FoodUnit.Kg, ParsedBatchPath.Leftovers),
                Items = [Food("rice", 500, FoodUnit.G, FoodState.Raw), Food("chicken", 1, FoodUnit.Kg, FoodState.Raw)],
                Portion = new(1, FoodUnit.Plate, null, null, false),
                SlotHint = "Dinner",
                DateHint = "today",
            })));
        Assert.Equal("maqluba", batch.Name);
        Assert.Equal(["rice", "chicken"], batch.Ingredients.Select(i => i.Mention));
        Assert.Equal([new BuddyAmount(500, "g", true), new BuddyAmount(1, "kg", true)], batch.Ingredients.Select(i => i.Amount));
        // The stated raw state survives as a state dimension when the facts found are cooked (the phone converts with yields).
        Assert.All(batch.Ingredients, i => Assert.Equal("raw", Assert.Single(i.Dimensions, d => d.Kind == "state").StatedValue));
        Assert.Equal(new BuddyAmount(2.5, "kg", true), batch.CookedWeight);
        Assert.Equal(BuddyBatchPath.Leftovers, batch.Path);
        Assert.Equal(new BuddyPortion(new(1, "plate", true), null), batch.EatenNow);
        Assert.Equal((null, "Dinner", "today"), (batch.TimeHint, batch.SlotHint, batch.DateHint));
        AssertProvenance([batch], input, catalog.Keys);

        // Path and eaten-now are hints only: both null when the user didn't say.
        var quiet = Assert.IsType<BuddyBatch>(Assert.Single(await ResolveAsync(input, null,
            Intent(ParsedKind.Batch) with { Batch = new(null, null, null, null), Items = [Food("lentils", 300, FoodUnit.G, FoodState.Dry)] })));
        Assert.Equal((null, null, (BuddyBatchPath?)null, (BuddyPortion?)null), (quiet.Name, quiet.CookedWeight, quiet.Path, quiet.EatenNow));
    }

    [Fact]
    [Trait("Req", "AI-101")]
    [Trait("Req", "DY-041")]
    public async Task AI_101_portions_accept_grams_plates_fractions_and_people()
    {
        var input = CreationInput("ate 200g, a plate, a quarter, and we were 4");
        ParsedIntent Eat(ParsedPortion portion) => Intent(ParsedKind.BatchPortion) with { ListRef = 0, Portion = portion };
        var intents = await ResolveAsync(input, null,
            Eat(new(200, FoodUnit.G, null, null, false)),
            Eat(new(1, FoodUnit.Plate, null, null, false)),
            Eat(new(null, null, 0.25m, null, false)),
            Eat(new(null, null, null, 4, false)),
            Intent(ParsedKind.Batch) with { Batch = new("soup", null, null, null), Items = [Food("lentils", 300, FoodUnit.G)], Portion = new(null, null, null, 4, false) });
        BuddyPortion? Portion(int i) => Assert.IsType<BuddyBatchPortion>(intents[i]).Portion;
        Assert.Equal(new BuddyPortion(new(200, "g", true), null), Portion(0));
        Assert.Equal(new BuddyPortion(new(1, "plate", true), null), Portion(1));
        Assert.Equal(new BuddyPortion(null, new(0.25, null)), Portion(2));
        Assert.Equal(new BuddyPortion(null, new(null, 4)), Portion(3));
        Assert.All(intents.Take(4), i => Assert.False(((BuddyBatchPortion)i).Rest));
        Assert.Equal(new BuddyPortion(null, new(null, 4)), Assert.IsType<BuddyBatch>(intents[4]).EatenNow);
    }

    [Fact]
    [Trait("Req", "AI-102")]
    [Trait("Req", "DY-043")]
    public async Task AI_102_leftover_reference_maps_to_the_open_batch_ID()
    {
        // T21 "a plate of the leftover mjadara for lunch yesterday" and "finished the maqluba".
        var input = CreationInput("a plate of the leftover mjadara for lunch yesterday, finished the maqluba");
        var intents = await ResolveAsync(input, null,
            Intent(ParsedKind.BatchPortion) with { ListRef = 1, Portion = new(1, FoodUnit.Plate, null, null, false), SlotHint = "Lunch", DateHint = "yesterday" },
            Intent(ParsedKind.BatchPortion) with { ListRef = 0, Portion = new(null, null, null, null, true) });
        Assert.Equal(new BuddyBatchPortion("english", "latin", Id(41), new(new(1, "plate", true), null), false, null, "Lunch", "yesterday"), intents[0]);
        var rest = Assert.IsType<BuddyBatchPortion>(intents[1]);
        Assert.Equal((Id(40), (BuddyPortion?)null, true), (rest.BatchId, rest.Portion, rest.Rest)); // exactly one of portion or rest
        AssertProvenance(intents, input, []);
    }

    [Fact]
    [Trait("Req", "DY-044")]
    public async Task DY_044_threw_the_rest_away_closes_the_referenced_batch()
    {
        // T22 "threw the rest of the mjadara away".
        var input = CreationInput("threw the rest of the mjadara away");
        var close = Assert.IsType<BuddyBatchClose>(Assert.Single(await ResolveAsync(input, null, Intent(ParsedKind.BatchClose) with { ListRef = 1 })));
        Assert.Equal(new BuddyBatchClose("english", "latin", Id(41)), close);
        var json = JsonSerializer.SerializeToNode<BuddyIntent>(close, InterpretProtocol.Json)!.AsObject();
        Assert.Equal(["batchId", "kind", "language", "script"], json.Select(p => p.Key).Order(StringComparer.Ordinal)); // closes without logging
    }

    [Fact]
    [Trait("Req", "DY-040")]
    [Trait("Req", "AI-070")]
    public async Task DY_040_an_unmatched_ingredient_without_an_estimate_clarifies_the_batch()
    {
        var input = CreationInput("cooked a pot of freekeh with 1kg lamb");
        var catalog = new FakeCatalog { Empty = true };
        var clarify = await ResolveAsync(input, catalog,
            Intent(ParsedKind.Batch) with { Batch = new(null, null, null, null), Items = [Food("freekeh", 500, FoodUnit.G, estimate: DishRange), Food("lamb", 1, FoodUnit.Kg)] });
        Assert.Equal("unmatchedFood", Assert.IsType<BuddyClarify>(Assert.Single(clarify)).Reason);
        // Every ingredient with a badged estimate keeps the batch; the estimate stays marked (review-only).
        var badged = Assert.IsType<BuddyBatch>(Assert.Single(await ResolveAsync(input, catalog,
            Intent(ParsedKind.Batch) with { Batch = new(null, null, null, null), Items = [Food("freekeh", 500, FoodUnit.G, estimate: DishRange)] })));
        var item = Assert.Single(badged.Ingredients);
        Assert.Null(item.Match); Assert.Equal(new BuddyEstimate(DishRange, "noCatalogMatch"), item.Estimate);
    }

    [Fact]
    [Trait("Req", "AI-054")]
    public async Task AI_054_personal_food_components_resolve_personal_then_catalog_facts()
    {
        var input = CreationInput("save my bulgur bowl as my food: bulgur and 100g rice, 250 kcal, 12g protein per 100g");
        var catalog = new RecordingCatalog(new FakeCatalog());
        var food = Assert.IsType<BuddyPersonalFoodCreate>(Assert.Single(await ResolveAsync(input, catalog,
            Intent(ParsedKind.PersonalFoodCreate) with
            {
                Create = new("bulgur bowl", ["my bowl"], false),
                Items = [Food("bulgur", state: FoodState.Cooked), Food("rice", 100, FoodUnit.G)],
                Stated = new(ParsedNutrientBasis.Per100g, null, null, 250, 12, null, null, null),
            })));
        Assert.Equal("bulgur bowl", food.Name); Assert.Equal(["my bowl"], food.Aliases);
        Assert.Equal([Id(70).ToString(), "rice/cooked"], food.Components.Select(c => c.Match!.Key)); // personal first, then catalog
        Assert.Equal("personal", food.Components[0].Match!.Source);
        // The user's own figures, exactly as written; the server never fills kcal or other members (TD-092).
        Assert.Equal(new BuddyStatedNutrients(BuddyNutrientBasis.Per100g, null, null, 250, 12, null, null, null), food.Stated);
        AssertProvenance([food], input, catalog.Keys);

        // Stated only (no components) is valid; an unmatched component without an estimate clarifies; an estimate keeps its badge.
        var arabic = CreationInput("لوح البروتين تبعي ٢٠٠ سعرة و ٢٠ غرام بروتين بالحصة ٦٠ غرام");
        var statedOnly = Assert.IsType<BuddyPersonalFoodCreate>(Assert.Single(await ResolveAsync(arabic, null,
            Intent(ParsedKind.PersonalFoodCreate) with { Create = new("لوح البروتين", [], false), Stated = new(ParsedNutrientBasis.PerServing, 60, null, 200, 20, null, null, null) })));
        Assert.Empty(statedOnly.Components);
        Assert.Equal(new BuddyStatedNutrients(BuddyNutrientBasis.PerServing, 60, null, 200, 20, null, null, null), statedOnly.Stated);
        var empty = new FakeCatalog { Empty = true };
        var unmatched = await ResolveAsync(input, empty, Intent(ParsedKind.PersonalFoodCreate) with { Create = new("x", [], false), Items = [Food("mystery seeds", 10, FoodUnit.G)] });
        Assert.Equal("unmatchedFood", Assert.IsType<BuddyClarify>(Assert.Single(unmatched)).Reason);
        var estimated = Assert.IsType<BuddyPersonalFoodCreate>(Assert.Single(await ResolveAsync(input, empty,
            Intent(ParsedKind.PersonalFoodCreate) with { Create = new("x", [], false), Items = [Food("maqluba", 1, FoodUnit.Plate, estimate: DishRange)] })));
        Assert.Equal("noCatalogMatch", Assert.Single(estimated.Components).Estimate!.Reason);
    }

    [Fact]
    [Trait("Req", "AI-102")]
    [Trait("Req", "AI-055")]
    [Trait("Rule", "04.4.1-contract-first")]
    public async Task Every_creation_response_uuid_comes_from_the_request_and_every_candidate_key_from_personal_facts_or_the_resolver()
    {
        var input = CreationInput("mixed 250 kcal") with { ActiveProposal = Id(90) };
        var catalog = new RecordingCatalog(new FakeCatalog { Many = true });
        var intents = await ResolveAsync(input, catalog,
            Memory(new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Default, "rice", ParsedMemoryDimension.State, "cooked", null, null), Food("rice")),
            Intent(ParsedKind.Batch) with { Batch = new("maqluba", null, null, null), Items = [Food("rice", 500, FoodUnit.G), Food("bulgur", 200, FoodUnit.G)] },
            Intent(ParsedKind.BatchPortion) with { ListRef = 1, Portion = new(null, null, 0.5m, null, false) },
            Intent(ParsedKind.BatchClose) with { ListRef = 0 },
            Intent(ParsedKind.PersonalFoodCreate) with { Create = new("bowl", [], false), Items = [Food("burghul"), Food("rice", 50, FoodUnit.G)], Stated = new(ParsedNutrientBasis.Per100g, null, null, 250, null, null, null, null) });
        Assert.DoesNotContain(intents, i => i is BuddyClarify);
        Assert.Equal(Id(41), Assert.IsType<BuddyBatchPortion>(intents[2]).BatchId);
        Assert.Equal(Id(40), Assert.IsType<BuddyBatchClose>(intents[3]).BatchId);
        AssertProvenance(intents, input, catalog.Keys);
        Assert.ThrowsAny<Exception>(() => AssertProvenance([new BuddyBatchClose("en", "latin", Id(42))], input, []));
    }
}
