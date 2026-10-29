using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using FitnessBuddy.Modules.Catalog.Contracts;
using static FitnessBuddy.Buddy.Tests.ProductionTests;

namespace FitnessBuddy.Buddy.Tests;

/// <summary>B09a WP3: diary references, copies and saved meals resolve to request IDs by server policy (D6/D7/D8, PA4, PA5, TD-091).</summary>
public sealed partial class ResolveReferencesTests
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;
    internal static Guid Id(int n) => Guid.Parse($"019a0000-0000-7000-8000-{n:D12}");

    // recentEntries newest first: two rice entries in today's lunch, then breakfast, yesterday's dinner, and an older lunch.
    internal static InterpretInput ReferenceInput(string text = "the rice was 150g") => ValidationInput(text) with
    {
        Slots = [new(Id(80), "Breakfast", null), new(Id(81), "Lunch", null), new(Id(82), "Dinner", null)],
        Context = ValidationInput(text).Context with
        {
            PersonalFoods = [new(Id(70), ["bulgur"], ["burghul"], "cooked", new(83, 3, 19, 0, 4), [])],
            RecentEntries =
            [
                new(Id(20), new DateOnly(2026, 10, 21), "Lunch", "rice", 200),
                new(Id(21), new DateOnly(2026, 10, 21), "Lunch", "rice", 150),
                new(Id(22), new DateOnly(2026, 10, 21), "Breakfast", "eggs", 100),
                new(Id(23), new DateOnly(2026, 10, 20), "Dinner", "rice", 180),
                new(Id(24), new DateOnly(2026, 10, 20), "Dinner", "pepsi", 330),
                new(Id(25), new DateOnly(2026, 10, 19), "Lunch", "rice", 160),
            ],
        },
    };
    private static ParsedReference Ref(string mention, params int[] refs) => new(refs, mention, ParsedScope.One, null, null);
    private static ParsedIntent Edit(ParsedReference reference) => Intent(ParsedKind.DiaryEdit) with { Reference = reference };
    private static ParsedIntent Delete(ParsedReference reference) => Intent(ParsedKind.DiaryDelete) with { Reference = reference };
    private static ParsedPortion Grams(decimal value) => new(value, FoodUnit.G, null, null, false);
    private static ParsedFood Bulgur(string name = "bulgur") => new(name, name, "برغل", null, null, false, FoodState.Cooked, null, null, [], null);

    private static async Task<BuddyIntent[]> ResolveAsync(InterpretInput input, IFoodResolver? catalog, params ParsedIntent[] intents)
    {
        var message = Message(intents);
        Assert.Null(ProductionProtocol.Validate(message, input)); // the fixtures are valid v2 outputs
        var result = await new ResolveInterpretation(catalog ?? new FakeCatalog()).ResolveAsync(message, input, Ct);
        Assert.Equal(ProductionProtocol.Version, result.PromptVersion);
        return result.Intents;
    }

    [Fact]
    [Trait("Req", "AI-091")]
    [Trait("Req", "AI-050")]
    public async Task AI_091_unqualified_singular_reference_picks_the_newest_candidate()
    {
        // T26 "the rice was 150g" after today's lunch rice was eaten elsewhere: yesterday's dinner rice is the newest linked one.
        var input = ReferenceInput();
        var intents = await ResolveAsync(input, null,
            Edit(Ref("the rice", 5, 3)) with { Portion = Grams(150) },
            Edit(Ref("the rice", 3, 0)) with { Portion = Grams(150) },
            Delete(Ref("it", 2, 1)));
        Assert.Equal([Id(23)], Assert.IsType<BuddyDiaryEdit>(intents[0]).Targets);
        Assert.Equal([Id(20)], Assert.IsType<BuddyDiaryEdit>(intents[1]).Targets);
        // Same date: list position (newest first) decides the group.
        Assert.Equal([Id(21)], Assert.IsType<BuddyDiaryDelete>(intents[2]).Targets);
        AssertProvenance(intents, input, []);
    }

    [Fact]
    [Trait("Req", "AI-091")]
    public async Task AI_091_unqualified_reference_with_two_candidates_in_the_newest_slot_asks()
    {
        var input = ReferenceInput();
        var intents = await ResolveAsync(input, null,
            Edit(Ref("the rice", 0, 1, 3, 5)) with { Portion = Grams(150) },
            Delete(Ref("الرز", 3, 1, 0)));
        var edit = Assert.IsType<BuddyAmbiguousReference>(intents[0]);
        Assert.Equal(BuddyReferenceOperation.Edit, edit.Operation);
        Assert.Equal([Id(20), Id(21)], edit.Candidates); // only the newest (date, slot) group, never the older rice
        Assert.Equal(new BuddyAmount(150, "g", true), edit.Patch!.Amount);
        Assert.Equal(new BuddyEntryReference("the rice", null, null, BuddyReferenceScope.One), edit.Reference);
        var delete = Assert.IsType<BuddyAmbiguousReference>(intents[1]);
        Assert.Equal(BuddyReferenceOperation.Delete, delete.Operation);
        Assert.Equal([Id(20), Id(21)], delete.Candidates); Assert.Null(delete.Patch);
        AssertProvenance(intents, input, []);
    }

    [Fact]
    [Trait("Req", "AI-091")]
    [Trait("Req", "AI-090")]
    public async Task AI_091_qualified_singular_reference_with_several_candidates_becomes_ambiguousReference_with_operation_and_patch()
    {
        // T29 "move the lunch rice to dinner": a slot qualifier with several linked entries asks, carrying the patch for the chip tap.
        var input = ReferenceInput("move the lunch rice to dinner");
        var qualified = new ParsedReference([0, 1, 5], "the lunch rice", ParsedScope.One, null, "Lunch");
        var intents = await ResolveAsync(input, null,
            Edit(qualified) with { Move = new(null, "Dinner", null) },
            Delete(qualified with { SlotHint = null, DateHint = "yesterday", Refs = [3, 4] }));
        var edit = Assert.IsType<BuddyAmbiguousReference>(intents[0]);
        Assert.Equal(BuddyReferenceOperation.Edit, edit.Operation);
        Assert.Equal([Id(20), Id(21), Id(25)], edit.Candidates);
        Assert.Equal(new BuddyDiaryPatch(null, null, new(null, "Dinner", null)), edit.Patch);
        Assert.Equal(new BuddyEntryReference("the lunch rice", null, "Lunch", BuddyReferenceScope.One), edit.Reference);
        var delete = Assert.IsType<BuddyAmbiguousReference>(intents[1]);
        Assert.Equal(BuddyReferenceOperation.Delete, delete.Operation);
        Assert.Equal([Id(23), Id(24)], delete.Candidates); Assert.Null(delete.Patch);
        Assert.Equal("yesterday", delete.Reference.DateHint);
        AssertProvenance(intents, input, []);
    }

    [Fact]
    [Trait("Req", "AI-091")]
    public async Task AI_091_scope_all_targets_every_linked_entry()
    {
        var input = ReferenceInput("delete all the rice");
        var all = new ParsedReference([5, 0, 3, 1], "all the rice", ParsedScope.All, null, null);
        var intents = await ResolveAsync(input, null, Delete(all), Edit(all with { Refs = [1, 0], SlotHint = "Lunch" }) with { Move = new("yesterday", null, null) });
        var delete = Assert.IsType<BuddyDiaryDelete>(intents[0]);
        Assert.Equal([Id(20), Id(21), Id(23), Id(25)], delete.Targets); // list order, newest first
        Assert.Equal(BuddyReferenceScope.All, delete.Reference.Scope);
        Assert.Equal([Id(20), Id(21)], Assert.IsType<BuddyDiaryEdit>(intents[1]).Targets);
        AssertProvenance(intents, input, []);
    }

    [Fact]
    [Trait("Req", "AI-091")]
    [Trait("Req", "AI-090")]
    public async Task AI_091_no_link_with_a_day_hint_returns_empty_targets_without_hints_clarifies()
    {
        // "change the snack on Monday": nothing in the 3-day window, so the app looks the day/slot up locally and asks (A25).
        var input = ReferenceInput("change the snack on monday to 2 dates");
        var catalog = new FakeCatalog();
        var intents = await ResolveAsync(input, catalog,
            Edit(new([], "the snack", ParsedScope.One, "lastWeekday:mon", "snack")) with { Portion = new(2, FoodUnit.Piece, null, null, false) },
            Delete(new([], "dinner", ParsedScope.All, null, "Dinner")),
            Edit(Ref("the falafel")) with { Items = [Bulgur()] },
            Delete(Ref("the falafel")));
        var edit = Assert.IsType<BuddyDiaryEdit>(intents[0]);
        Assert.Empty(edit.Targets);
        Assert.Equal(new BuddyEntryReference("the snack", "lastWeekday:mon", "snack", BuddyReferenceScope.One), edit.Reference);
        Assert.Equal(new BuddyAmount(2, "piece", true), edit.Patch.Amount);
        Assert.Empty(Assert.IsType<BuddyDiaryDelete>(intents[1]).Targets);
        Assert.Equal("referenceNotFound", Assert.IsType<BuddyClarify>(intents[2]).Reason);
        Assert.Equal("referenceNotFound", Assert.IsType<BuddyClarify>(intents[3]).Reason);
        Assert.Empty(catalog.Mentions); // a reference that can't be found never resolves its replacement food
    }

    [Fact]
    [Trait("Req", "AI-050")]
    public async Task AI_050_amount_patch_keeps_value_unit_and_explicitness()
    {
        var input = ReferenceInput("the rice was 150g, it was 2 eggs");
        var intents = await ResolveAsync(input, null,
            Edit(Ref("the rice", 3)) with { Portion = Grams(150.5m) },
            Edit(Ref("the eggs", 2)) with { Portion = new(2, FoodUnit.Piece, null, null, false) });
        var rice = Assert.IsType<BuddyDiaryEdit>(intents[0]);
        Assert.Equal([Id(23)], rice.Targets);
        Assert.Equal(new BuddyDiaryPatch(new(150.5, "g", true), null, null), rice.Patch);
        Assert.Equal(new BuddyDiaryPatch(new(2, "piece", true), null, null), Assert.IsType<BuddyDiaryEdit>(intents[1]).Patch);
    }

    [Fact]
    [Trait("Req", "AI-090")]
    [Trait("Req", "AI-070")]
    public async Task AI_090_food_swap_replacement_carries_catalog_facts_and_distinct_alternatives()
    {
        // T27 "bulgur not rice": the replacement goes through the shared food resolver; the model never supplies its nutrition.
        var input = ReferenceInput("it was bulgur not rice") with { Context = ReferenceInput().Context with { PersonalFoods = [] } };
        var catalog = new RecordingCatalog(new FakeCatalog { Many = true });
        var intents = await ResolveAsync(input, catalog, Edit(Ref("the rice", 3)) with { Items = [Bulgur()] });
        var edit = Assert.IsType<BuddyDiaryEdit>(Assert.Single(intents));
        var replacement = edit.Patch.Replacement!;
        Assert.Null(edit.Patch.Amount); Assert.Null(edit.Patch.Move);
        Assert.Equal("bulgur", replacement.Mention);
        Assert.Equal(new BuddyAmount(null, null, false), replacement.Amount); // keeps the entry's amount
        Assert.Equal("rice/0", replacement.Match!.Key); Assert.Equal(130, replacement.Match.Nutrients.Kcal); Assert.Null(replacement.Estimate);
        Assert.Equal(3, replacement.Alternatives.Length);
        Assert.Equal(4, replacement.Alternatives.Select(a => a.Key).Append(replacement.Match.Key).Distinct().Count());
        AssertProvenance(intents, input, catalog.Keys);

        // Personal facts win, and an unmatched replacement without an estimate clarifies the whole edit (D10).
        var personal = await ResolveAsync(ReferenceInput(), new FakeCatalog(), Edit(Ref("the rice", 3)) with { Items = [Bulgur()] });
        Assert.Equal(Id(70).ToString(), Assert.IsType<BuddyDiaryEdit>(Assert.Single(personal)).Patch.Replacement!.Match!.Key);
        var unmatched = await ResolveAsync(ReferenceInput(), new FakeCatalog { Empty = true }, Edit(Ref("the rice", 3)) with { Items = [Bulgur("freekeh")] });
        Assert.Equal("unmatchedFood", Assert.IsType<BuddyClarify>(Assert.Single(unmatched)).Reason);
    }

    [Fact]
    [Trait("Req", "AI-090")]
    public async Task AI_090_move_patch_carries_slot_and_day_hints()
    {
        var input = ReferenceInput("move the pepsi to lunch today, the eggs were yesterday at 9");
        var intents = await ResolveAsync(input, null,
            Edit(Ref("the pepsi", 4)) with { Move = new("today", "Lunch", null) },
            Edit(Ref("the eggs", 2)) with { Move = new("yesterday", null, "at 9") });
        var pepsi = Assert.IsType<BuddyDiaryEdit>(intents[0]);
        Assert.Equal([Id(24)], pepsi.Targets);
        Assert.Equal(new BuddyDiaryPatch(null, null, new("today", "Lunch", null)), pepsi.Patch);
        Assert.Equal(new BuddyDayHint("yesterday", null, "at 9"), Assert.IsType<BuddyDiaryEdit>(intents[1]).Patch.Move);
    }

    [Fact]
    [Trait("Req", "AI-051")]
    public async Task AI_051_delete_targets_exactly_the_linked_entries()
    {
        // T28 "delete the pepsi".
        var input = ReferenceInput("delete the pepsi");
        var delete = Assert.IsType<BuddyDiaryDelete>(Assert.Single(await ResolveAsync(input, null, Delete(Ref("the pepsi", 4)))));
        Assert.Equal([Id(24)], delete.Targets);
        Assert.Equal(new BuddyEntryReference("the pepsi", null, null, BuddyReferenceScope.One), delete.Reference);
        var json = JsonNode.Parse(JsonSerializer.Serialize<BuddyIntent>(delete, InterpretProtocol.Json))!.AsObject();
        Assert.Equal(["kind", "language", "reference", "script", "targets"], json.Select(p => p.Key).Order(StringComparer.Ordinal));
    }

    [Fact]
    [Trait("Req", "AI-090")]
    public async Task T23_copy_carries_source_and_target_day_hints()
    {
        // T23 "same breakfast as yesterday".
        var input = ReferenceInput("same breakfast as yesterday");
        var intents = await ResolveAsync(input, null,
            Intent(ParsedKind.DiaryCopy) with { DateHint = "yesterday", SlotHint = "Breakfast", Move = new("today", null, null) },
            Intent(ParsedKind.DiaryCopy) with { DateHint = "lastWeekday:mon", SlotHint = "Lunch", TimeHint = "monday lunch" },
            Intent(ParsedKind.DiaryCopy) with { DateHint = "yesterday", Move = new("today", null, null) });
        var copy = Assert.IsType<BuddyDiaryCopy>(intents[0]);
        Assert.Equal(new BuddyDayHint("yesterday", "Breakfast", null), copy.Source);
        Assert.Equal(new BuddyDayHint("today", null, null), copy.Target);
        var monday = Assert.IsType<BuddyDiaryCopy>(intents[1]);
        Assert.Equal(new BuddyDayHint("lastWeekday:mon", "Lunch", "monday lunch"), monday.Source);
        Assert.Equal(new BuddyDayHint(null, null, null), monday.Target); // today, the source's slot, now
        // R1 has no whole-day copy: no source slot is a clarify.
        Assert.Equal("unclear", Assert.IsType<BuddyClarify>(intents[2]).Reason);
    }

    [Fact]
    [Trait("Req", "DY-031")]
    public async Task DY_031_save_from_linked_entries_or_a_meal_hint_keeps_exactly_one_source()
    {
        var input = ReferenceInput("save yesterday's dinner as movie night") with { ActiveProposal = Id(90) };
        ParsedIntent Save(ParsedReference reference) => Intent(ParsedKind.SavedMealCreate) with { Create = new("movie night", [], false), Reference = reference };
        var intents = await ResolveAsync(input, null,
            Save(new([4, 3], "the rice and pepsi", ParsedScope.All, null, null)),
            Save(new([], "yesterday's dinner", ParsedScope.All, "yesterday", "Dinner")),
            Save(new([], "it", ParsedScope.All, null, null)),
            Save(new([0, 1], "the rice", ParsedScope.One, null, null)),
            Intent(ParsedKind.SavedMealCreate) with { Create = new("gym lunch", [], true) });
        var linked = Assert.IsType<BuddySavedMealCreate>(intents[0]);
        Assert.Equal(("movie night", (Guid?)null, (BuddyDayHint?)null), (linked.Name, linked.ActiveProposal, linked.Source));
        Assert.Equal([Id(23), Id(24)], linked.Targets);
        var hinted = Assert.IsType<BuddySavedMealCreate>(intents[1]);
        Assert.Empty(hinted.Targets); Assert.Null(hinted.ActiveProposal);
        Assert.Equal(new BuddyDayHint("yesterday", "Dinner", null), hinted.Source);
        Assert.Equal("referenceNotFound", Assert.IsType<BuddyClarify>(intents[2]).Reason);
        Assert.Equal("unclear", Assert.IsType<BuddyClarify>(intents[3]).Reason); // no ambiguity chip for saving
        var card = Assert.IsType<BuddySavedMealCreate>(intents[4]);
        Assert.Equal(Id(90), card.ActiveProposal); Assert.Empty(card.Targets); Assert.Null(card.Source);
        AssertProvenance(intents, input, []);
    }

    [Fact]
    [Trait("Req", "AI-092")]
    public async Task AI_092_edit_and_delete_interpretations_carry_no_writes_or_totals()
    {
        var input = ReferenceInput("the rice was 150g, delete the pepsi");
        var intents = await ResolveAsync(input, null,
            Edit(Ref("the rice", 3)) with { Portion = Grams(150) },
            Delete(Ref("the pepsi", 4)),
            Edit(Ref("the rice", 0, 1)) with { Move = new(null, "Dinner", null) },
            Intent(ParsedKind.DiaryCopy) with { DateHint = "yesterday", SlotHint = "Breakfast" });
        var json = JsonSerializer.Serialize(intents, InterpretProtocol.Json);
        foreach (var leak in new[] { "kcal", "nutrients", "total", "grams", "operations", "write", "apply", "\"id\"" })
        { Assert.DoesNotContain(leak, json, StringComparison.OrdinalIgnoreCase); }
        Assert.Equal(["kind", "language", "patch", "reference", "script", "targets"], Keys(intents[0]));
        Assert.Equal(["candidates", "kind", "language", "operation", "patch", "reference", "script"], Keys(intents[2]));
        Assert.Equal(["kind", "language", "script", "source", "target"], Keys(intents[3]));
        static IEnumerable<string> Keys(BuddyIntent intent) => JsonNode.Parse(JsonSerializer.Serialize(intent, InterpretProtocol.Json))!.AsObject().Select(p => p.Key).Order(StringComparer.Ordinal);
    }

    [Fact]
    [Trait("Rule", "06.3-day-hints")]
    public async Task Food_log_and_weigh_in_carry_the_structured_day_hint()
    {
        // PA3: the structured dateHint reaches the app; the literal timeHint stays as said.
        var input = ReferenceInput("awal mbare7 ate 200g rice, weighed 97.2 yesterday");
        var intents = await ResolveAsync(input, null,
            Intent(ParsedKind.FoodLog) with { Items = [Rice()], DateHint = "daysAgo:2", TimeHint = "awal mbare7", SlotHint = "Lunch" },
            Intent(ParsedKind.WeighIn) with { WeighIn = new(97.2m, "kg"), DateHint = "yesterday" },
            Intent(ParsedKind.FoodLog) with { Items = [Rice()] },
            Intent(ParsedKind.WeighIn) with { WeighIn = new(97.2m, "kg"), DateHint = "date:2026-10-03" });
        var food = Assert.IsType<BuddyFoodLog>(intents[0]);
        Assert.Equal(("daysAgo:2", "awal mbare7", "Lunch"), (food.DateHint, food.TimeHint, food.SlotHint));
        Assert.Equal("yesterday", Assert.IsType<BuddyWeighIn>(intents[1]).DateHint);
        Assert.Null(Assert.IsType<BuddyFoodLog>(intents[2]).DateHint);
        Assert.Equal("date:2026-10-03", Assert.IsType<BuddyWeighIn>(intents[3]).DateHint);
    }

    [Fact]
    [Trait("Req", "AI-091")]
    [Trait("Req", "DY-031")]
    [Trait("Rule", "04.4.1-contract-first")]
    public async Task Every_response_uuid_comes_from_the_request_and_every_candidate_key_from_personal_facts_or_the_resolver()
    {
        var input = ReferenceInput("mixed") with { ActiveProposal = Id(90) };
        var catalog = new RecordingCatalog(new FakeCatalog { Many = true });
        var intents = await ResolveAsync(input, catalog,
            Intent(ParsedKind.FoodLog) with { Items = [Rice(), Bulgur("burghul")] },
            Edit(Ref("the rice", 3)) with { Items = [Bulgur()] },
            Edit(Ref("the rice", 3, 5)) with { Items = [Rice()] },
            Edit(Ref("the rice", 0, 1, 3)) with { Portion = Grams(100) },
            Delete(new([0, 1, 2, 3, 4, 5], "everything", ParsedScope.All, null, null)),
            Intent(ParsedKind.SavedMealLog) with { ListRef = 1, Portion = new(null, null, null, 2, false) },
            Intent(ParsedKind.SavedMealCreate) with { Create = new("this", [], true) },
            Intent(ParsedKind.SavedMealCreate) with { Create = new("that", [], false), Reference = new([2], "the eggs", ParsedScope.All, null, null) },
            Intent(ParsedKind.DiaryCopy) with { DateHint = "yesterday", SlotHint = "Dinner" });
        Assert.Equal(9, intents.Length);
        Assert.DoesNotContain(intents, i => i is BuddyClarify);
        Assert.Equal(Id(31), Assert.IsType<BuddySavedMealLog>(intents[5]).SavedMealId);
        AssertProvenance(intents, input, catalog.Keys);
        // The check itself can fail: a foreign ID or an unknown candidate key is caught.
        Assert.ThrowsAny<Exception>(() => AssertProvenance([new BuddyDiaryDelete("en", "latin", [input.RequestId], new("x", null, null, BuddyReferenceScope.One))], input, []));
        Assert.ThrowsAny<Exception>(() => AssertProvenance([intents[0]], input, []));
    }

    /// <summary>
    /// PA5: every UUID in a response is a request context ID (recentEntries, savedMeals, openBatches, personalFoods,
    /// activeProposal) and every candidate key comes from request personal facts or the food resolver.
    /// </summary>
    internal static void AssertProvenance(IEnumerable<BuddyIntent> intents, InterpretInput input, IEnumerable<string> resolverKeys)
    {
        var json = JsonSerializer.Serialize(intents.ToArray(), InterpretProtocol.Json);
        var requestIds = input.Context.RecentEntries.Select(r => r.Id).Concat(input.Context.SavedMeals.Select(r => r.Id))
            .Concat(input.Context.OpenBatches.Select(r => r.Id)).Concat(input.Context.PersonalFoods.Select(p => p.Id))
            .Concat(input.ActiveProposal is { } proposal ? [proposal] : []).Select(id => id.ToString()).ToHashSet(StringComparer.OrdinalIgnoreCase);
        foreach (Match uuid in Uuid().Matches(json)) { Assert.Contains(uuid.Value, requestIds); }
        var keys = input.Context.PersonalFoods.Select(p => p.Id.ToString()).Concat(resolverKeys).ToHashSet(StringComparer.Ordinal);
        void Walk(JsonNode? node)
        {
            switch (node)
            {
                case JsonObject obj:
                    foreach (var (name, value) in obj)
                    {
                        if (name is "key" or "candidateKey" && value is JsonValue v && v.GetValue<string>() is var key) { Assert.Contains(key, keys); }
                        Walk(value);
                    }
                    break;
                case JsonArray array: foreach (var item in array) { Walk(item); } break;
            }
        }
        Walk(JsonNode.Parse(json));
    }
    [GeneratedRegex("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", RegexOptions.IgnoreCase)] private static partial Regex Uuid();

    /// <summary>Records every catalog key the resolver port returned, for the PA5 provenance check.</summary>
    internal sealed class RecordingCatalog(IFoodResolver inner) : IFoodResolver
    {
        public HashSet<string> Keys { get; } = [];
        public async Task<IReadOnlyList<FoodCandidate>> ResolveAsync(FoodMention mention, CancellationToken cancellationToken)
        {
            var found = await inner.ResolveAsync(mention, cancellationToken);
            foreach (var candidate in found) { Keys.Add(candidate.CatalogKey); }
            return found;
        }
        public async Task<FoodDetails?> DetailsAsync(string key, CancellationToken cancellationToken)
        {
            var details = await inner.DetailsAsync(key, cancellationToken);
            if (details is not null) { Keys.Add(details.Key); }
            return details;
        }
    }
}
