using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using Microsoft.Extensions.Options;
using static FitnessBuddy.Buddy.Tests.ProductionTests;
using static FitnessBuddy.Buddy.Tests.ResolveReferencesTests;

namespace FitnessBuddy.Buddy.Tests;

/// <summary>InterpretMessage over a scripted provider that replays raw model text through the real v2 validation (B09a WP2).</summary>
public sealed class InterpretFlowTests
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static async Task<(BuddyInterpretation Result, ScriptedProvider Provider)> RunAsync(ParsedMessage output, InterpretInput input)
    {
        var provider = new ScriptedProvider(JsonSerializer.Serialize(output, InterpretProtocol.Json));
        var options = Options.Create(new BuddyOptions { Enabled = true });
        using var concurrency = new BuddyConcurrency(options);
        var flow = new InterpretMessage(new AcceptingLedger(), provider, new ResolveInterpretation(new FakeCatalog()), concurrency, options);
        var result = await flow.ExecuteAsync(input, Ct);
        Assert.Equal(InterpretStatus.Success, result.Status);
        return (result.Value!, provider);
    }

    [Fact]
    [Trait("Req", "AI-054")]
    public async Task AI_054_an_invented_stated_value_gets_one_coded_repair_then_clarifies()
    {
        var input = ValidationInput("my bar is 250 kcal per 100g");
        var output = Message(Intent(ParsedKind.PersonalFoodCreate) with
        {
            Create = new("my bar", [], false),
            Stated = new(ParsedNutrientBasis.Per100g, null, null, 250, 12, null, null, null),
        });
        var (result, provider) = await RunAsync(output, input);
        Assert.Equal(new InvalidOutput?[] { null, InvalidOutput.StatedNotLiteral }, provider.RepairOf);
        var clarify = Assert.IsType<BuddyClarify>(Assert.Single(result.Intents));
        Assert.Equal("invalidInterpretation", clarify.Reason); Assert.Equal(ProductionProtocol.Version, result.PromptVersion);
        Assert.DoesNotContain("250", JsonSerializer.Serialize(result, InterpretProtocol.Json), StringComparison.Ordinal);
    }

    [Theory]
    [InlineData("savedMealNoMatch")]
    [InlineData("savedMealsEmpty")]
    [InlineData("batchPortionNoMatch")]
    [InlineData("batchCloseNoOpenBatches")]
    [InlineData("saveThisWithoutCard")]
    [Trait("Req", "DY-031")]
    [Trait("Req", "AI-102")]
    public async Task PA8_nothing_to_link_to_clarifies_referenceNotFound_without_a_repair(string scenario)
    {
        var input = ValidationInput("had my usual");
        var intent = scenario switch
        {
            "savedMealNoMatch" => Intent(ParsedKind.SavedMealLog) with { SlotHint = "Breakfast" },
            "savedMealsEmpty" => Intent(ParsedKind.SavedMealLog) with { ListRef = 0 },
            "batchPortionNoMatch" => Intent(ParsedKind.BatchPortion) with { Portion = new(1, FoodUnit.Plate, null, null, false) },
            "batchCloseNoOpenBatches" => Intent(ParsedKind.BatchClose) with { ListRef = 0 },
            "saveThisWithoutCard" => Intent(ParsedKind.SavedMealCreate) with { Create = new("gym lunch", [], true) },
            _ => throw new ArgumentOutOfRangeException(nameof(scenario)),
        };
        if (scenario == "savedMealsEmpty") { input = input with { Context = input.Context with { SavedMeals = [] } }; }
        if (scenario == "batchCloseNoOpenBatches") { input = input with { Context = input.Context with { OpenBatches = [] } }; }
        var (result, provider) = await RunAsync(Message(intent), input);
        Assert.Equal(new InvalidOutput?[] { null }, provider.RepairOf);
        Assert.Equal("referenceNotFound", Assert.IsType<BuddyClarify>(Assert.Single(result.Intents)).Reason);
    }

    [Fact]
    [Trait("Req", "AI-055")]
    [Trait("Req", "AI-100")]
    [Trait("Req", "AI-054")]
    public async Task Recorded_creation_fixture_resolves_through_v2_validation_without_a_repair()
    {
        // An Arabic message replayed as raw model text: memory, batch, leftovers, a closed batch and a personal food with
        // Arabic-Indic stated figures (D9 literal guard), next to a weigh-in. No resolver gap is left: nothing is "unsupported".
        var input = ResolveCreationsTests.CreationInput("دايما بوزن الرز نيء، طبخت مقلوبة ٥٠٠ غرام رز وكيلو دجاج، كلت صحن من المجدرة، كبيت باقي المقلوبة، "
            + "لوح البروتين تبعي ٢٠٠ سعرة بالحصة، وزني ٩٧٫٢");
        ParsedFood Food(string name, string ar, decimal? amount, FoodUnit? unit, FoodState? state = null) =>
            new(ar, name, ar, amount, unit, amount is not null, state, null, null, [], null);
        var output = new ParsedMessage(MessageLanguage.Arabic, MessageScript.Arabic,
        [
            Intent(ParsedKind.MemoryChange) with { Memory = new(ParsedMemoryOperation.Remember, ParsedMemoryKind.Default, "الرز", ParsedMemoryDimension.State, "raw", null, null),
                Items = [Food("rice", "رز", null, null, FoodState.Raw)] },
            Intent(ParsedKind.Batch) with { Batch = new("مقلوبة", null, null, null), Items = [Food("rice", "رز", 500, FoodUnit.G, FoodState.Raw), Food("chicken", "دجاج", 1, FoodUnit.Kg, FoodState.Raw)] },
            Intent(ParsedKind.BatchPortion) with { ListRef = 1, Portion = new(1, FoodUnit.Plate, null, null, false) },
            Intent(ParsedKind.BatchClose) with { ListRef = 0 },
            Intent(ParsedKind.PersonalFoodCreate) with { Create = new("لوح البروتين", [], false), Stated = new(ParsedNutrientBasis.PerServing, null, null, 200, null, null, null, null) },
            Intent(ParsedKind.WeighIn) with { WeighIn = new(97.2m, "kg") },
        ]);
        var (result, provider) = await RunAsync(output, input);
        Assert.Equal(new InvalidOutput?[] { null }, provider.RepairOf);
        Assert.Equal(["memoryChange", "batch", "batchPortion", "batchClose", "personalFoodCreate", "weighIn"],
            result.Intents.Select(i => JsonSerializer.SerializeToNode(i, InterpretProtocol.Json)!["kind"]!.GetValue<string>()));
        Assert.All(result.Intents, i => Assert.Equal(("arabic", "arabic"), (i.Language, i.Script)));
        Assert.Equal(Id(41), Assert.IsType<BuddyBatchPortion>(result.Intents[2]).BatchId);
        Assert.Equal(Id(40), Assert.IsType<BuddyBatchClose>(result.Intents[3]).BatchId);
        Assert.Equal(200, Assert.IsType<BuddyPersonalFoodCreate>(result.Intents[4]).Stated!.Kcal);
        AssertProvenance(result.Intents, input, ["rice/cooked"]);
    }

    [Fact]
    [Trait("Req", "AI-102")]
    public async Task AI_102_batch_reference_with_no_open_batches_clarifies_without_repair()
    {
        var input = ValidationInput("a plate of the leftover maqluba");
        var none = input with { Context = input.Context with { OpenBatches = [] } };
        foreach (var (intent, context) in new[]
        {
            (Intent(ParsedKind.BatchPortion) with { ListRef = 0, Portion = new(1, FoodUnit.Plate, null, null, false) }, none),
            (Intent(ParsedKind.BatchPortion) with { Portion = new(null, null, null, null, true) }, input), // no batch matched the name
            (Intent(ParsedKind.BatchClose) with { ListRef = 0 }, none),
        })
        {
            var (result, provider) = await RunAsync(Message(intent), context);
            Assert.Equal(new InvalidOutput?[] { null }, provider.RepairOf);
            Assert.Equal("referenceNotFound", Assert.IsType<BuddyClarify>(Assert.Single(result.Intents)).Reason);
        }
    }

    [Fact]
    [Trait("Req", "DY-031")]
    public async Task DY_031_saved_meal_by_name_maps_to_its_ID_no_match_clarifies_without_repair()
    {
        // "half my gym shake for dinner yesterday": savedMeals ref 1 is the gym shake.
        var input = ValidationInput("half my gym shake for dinner yesterday");
        var log = Intent(ParsedKind.SavedMealLog) with { ListRef = 1, SlotHint = "Dinner", DateHint = "yesterday", Portion = new(null, null, 0.5m, null, false) };
        var (result, provider) = await RunAsync(Message(log), input);
        Assert.Equal(new InvalidOutput?[] { null }, provider.RepairOf);
        Assert.Equal(new BuddySavedMealLog("english", "latin", Guid.Parse("019a0000-0000-7000-8000-000000000031"), null, "Dinner", "yesterday", new(0.5, null)),
            Assert.Single(result.Intents));
        ResolveReferencesTests.AssertProvenance(result.Intents, input, []);

        (result, provider) = await RunAsync(Message(log with { ListRef = null }), input);
        Assert.Equal(new InvalidOutput?[] { null }, provider.RepairOf);
        Assert.Equal("referenceNotFound", Assert.IsType<BuddyClarify>(Assert.Single(result.Intents)).Reason);
    }

    [Fact]
    [Trait("Req", "DY-031")]
    public async Task DY_031_save_this_uses_the_active_proposal_without_one_clarifies_referenceNotFound_without_repair()
    {
        var proposal = Guid.Parse("019a0000-0000-7000-8000-000000000099");
        var input = ValidationInput("save this as gym lunch") with { ActiveProposal = proposal };
        var save = Intent(ParsedKind.SavedMealCreate) with { Create = new("gym lunch", [], true) };
        var (result, provider) = await RunAsync(Message(save), input);
        Assert.Equal(new InvalidOutput?[] { null }, provider.RepairOf);
        var created = Assert.IsType<BuddySavedMealCreate>(Assert.Single(result.Intents));
        Assert.Equal(("gym lunch", (Guid?)proposal, (BuddyDayHint?)null), (created.Name, created.ActiveProposal, created.Source));
        Assert.Empty(created.Targets);
        ResolveReferencesTests.AssertProvenance(result.Intents, input, []);

        (result, provider) = await RunAsync(Message(save), input with { ActiveProposal = null });
        Assert.Equal(new InvalidOutput?[] { null }, provider.RepairOf);
        Assert.Equal("referenceNotFound", Assert.IsType<BuddyClarify>(Assert.Single(result.Intents)).Reason);
    }

    [Fact]
    [Trait("Req", "AI-091")]
    [Trait("Req", "AI-090")]
    [Trait("Req", "AI-051")]
    public async Task Recorded_reference_fixture_resolves_through_v2_validation_to_request_ids_without_a_repair()
    {
        // A mixed Arabizi message replayed as raw model text: edits, ask, delete, copy, saved meals and a dated weigh-in.
        const string text = "el riz kan 150g, sheel el pepsi, nafs fotoor mbare7, save mbare7 el 3asha as movie night, wazni 97.2 mbare7";
        var input = ReferenceInput(text) with { ActiveProposal = Guid.Parse("019a0000-0000-7000-8000-000000000099") };
        var output = new ParsedMessage(MessageLanguage.Mixed, MessageScript.Arabizi,
        [
            Intent(ParsedKind.DiaryEdit) with { Reference = new([3, 5], "el riz", ParsedScope.One, null, null), Portion = new(150, FoodUnit.G, null, null, false) },
            Intent(ParsedKind.DiaryEdit) with { Reference = new([0, 1], "el riz", ParsedScope.One, null, null), Move = new(null, "Dinner", null) },
            Intent(ParsedKind.DiaryDelete) with { Reference = new([4], "el pepsi", ParsedScope.One, null, null) },
            Intent(ParsedKind.DiaryCopy) with { DateHint = "yesterday", SlotHint = "Breakfast", Move = new("today", null, null) },
            Intent(ParsedKind.SavedMealCreate) with { Create = new("movie night", [], false), Reference = new([], "el 3asha", ParsedScope.All, "yesterday", "Dinner") },
            Intent(ParsedKind.WeighIn) with { WeighIn = new(97.2m, "kg"), DateHint = "yesterday", TimeHint = "mbare7" },
        ]);
        var (result, provider) = await RunAsync(output, input);
        Assert.Equal(new InvalidOutput?[] { null }, provider.RepairOf);
        Assert.Equal(["diaryEdit", "ambiguousReference", "diaryDelete", "diaryCopy", "savedMealCreate", "weighIn"],
            result.Intents.Select(i => JsonSerializer.SerializeToNode(i, InterpretProtocol.Json)!["kind"]!.GetValue<string>()));
        Assert.All(result.Intents, i => Assert.Equal(("mixed", "arabizi"), (i.Language, i.Script)));
        Assert.Equal([ResolveReferencesTests.Id(23)], Assert.IsType<BuddyDiaryEdit>(result.Intents[0]).Targets);
        Assert.Equal([ResolveReferencesTests.Id(20), ResolveReferencesTests.Id(21)], Assert.IsType<BuddyAmbiguousReference>(result.Intents[1]).Candidates);
        Assert.Equal([ResolveReferencesTests.Id(24)], Assert.IsType<BuddyDiaryDelete>(result.Intents[2]).Targets);
        Assert.Equal("yesterday", Assert.IsType<BuddyWeighIn>(result.Intents[5]).DateHint);
        ResolveReferencesTests.AssertProvenance(result.Intents, input, []);

        // An out-of-range ref is invalid output: one coded repair, then clarify (D6).
        var invalid = output with { Intents = [output.Intents[2] with { Reference = new([6], "el pepsi", ParsedScope.One, null, null) }] };
        (result, provider) = await RunAsync(invalid, input);
        Assert.Equal(new InvalidOutput?[] { null, InvalidOutput.RefRange }, provider.RepairOf);
        Assert.Equal("invalidInterpretation", Assert.IsType<BuddyClarify>(Assert.Single(result.Intents)).Reason);
    }

    private sealed class ScriptedProvider(string text) : IProductionLlmClient
    {
        public List<InvalidOutput?> RepairOf { get; } = [];
        public Task<ProductionOutcome> ParseAsync(InterpretInput input, InvalidOutput? repairOf, CancellationToken cancellationToken)
        {
            RepairOf.Add(repairOf);
            var (message, invalid) = ProductionProtocol.Parse(text, input);
            return Task.FromResult(message is not null ? new ProductionOutcome(LlmStatus.Success, message, null, null)
                : new ProductionOutcome(LlmStatus.InvalidOutput, null, null, null, invalid));
        }
    }

    private sealed class AcceptingLedger : IInterpretLedger
    {
        public Task<InterpretResult?> ClaimAsync(InterpretInput input, CancellationToken cancellationToken) => Task.FromResult<InterpretResult?>(null);
        public Task<InterpretStatus> ReserveRepairAsync(Guid messageId, CancellationToken cancellationToken) => Task.FromResult(InterpretStatus.Success);
        public Task<bool> RecordAsync(Guid messageId, int attempt, ProductionOutcome outcome, CancellationToken cancellationToken) => Task.FromResult(true);
        public Task<bool> CompleteAsync(Guid messageId, BuddyInterpretation result, CancellationToken cancellationToken) => Task.FromResult(true);
    }
}
