using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Catalog.Contracts;
using static FitnessBuddy.Modules.Buddy.Application.IntentNames;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>An action's outcome: the card (or why there is none) and the compact code-made summary the model gets back.</summary>
internal sealed record ActionOutcome(BuddyProposalEvent? Proposal, string ResultJson);

/// <summary>
/// The action tools (06 §4.3): each validates its arguments, resolves with the B08/B09a resolvers (personal slice first,
/// TD-091 reference policy kept) and returns a <c>BuddyIntent</c> for a proposal event. Nothing here writes: the Buddy module
/// has no user-data write port (an architecture rule). Every ID in an intent comes from the request or a phone result.
/// </summary>
internal sealed class ActionTools(IFoodResolver catalog, Exercises exercises)
{
    private readonly ResolveFoods foods = new(catalog);

    public async Task<ActionOutcome> RunAsync(AgentToolCall call, TurnRun run, RoundLog log, CancellationToken ct)
    {
        var ws = run.Workspace;
        var (intent, replaces, error) = call.Name switch
        {
            "propose_food_log" => await FoodLogAsync(AgentTools.Bind<FoodLogArgs>(call), ws, ct),
            "propose_diary_edit" => await EditAsync(AgentTools.Bind<DiaryEditArgs>(call), ws, ct),
            "propose_diary_delete" => Delete(AgentTools.Bind<DiaryDeleteArgs>(call), ws),
            "propose_diary_copy" => Copy(AgentTools.Bind<DiaryCopyArgs>(call), ws),
            "propose_saved_meal" => SavedMeal(AgentTools.Bind<SavedMealArgs>(call), ws),
            "propose_batch" => await BatchAsync(AgentTools.Bind<BatchArgs>(call), ws, ct),
            "propose_personal_food" => await PersonalFoodAsync(AgentTools.Bind<PersonalFoodArgs>(call), ws, ct),
            "propose_memory" => await MemoryAsync(AgentTools.Bind<MemoryArgs>(call), ws, ct),
            "propose_weigh_in" => WeighIn(AgentTools.Bind<WeighInArgs>(call), ws),
            "suggest_foods" => await SuggestAsync(AgentTools.Bind<SuggestArgs>(call), ws, ct),
            "propose_measurement" => Measurement(AgentTools.Bind<MeasurementArgs>(call), ws),
            "propose_workout" => await WorkoutAsync(AgentTools.Bind<WorkoutArgs>(call), ws, ct),
            "propose_import" => Import(AgentTools.Bind<ImportArgs>(call), ws),
            _ => (null, null, "unknownTool"),
        };
        if (intent is null) { return new(null, AgentTools.Error(error ?? "invalidArgs")); }
        if (intent is BuddyClarify clarify) { return new(null, AgentTools.Error(clarify.Reason)); }
        CardRef? previous = null;
        if (replaces is not null)
        {
            previous = ws.Resolve(replaces, "c") is { } target ? ws.Cards.FirstOrDefault(c => c.ProposalId.ToString() == target.Id && c.Pending) : null;
            if (previous is null) { return new(null, AgentTools.Error("unknownCard")); }
        }
        var index = log.ProposalIndex++;
        var proposalId = previous?.ProposalId ?? ProposalIds.For(run.TurnId, run.Round, run.Attempt, index);
        var revision = previous is null ? 1 : previous.Revision + 1;
        var label = Label(intent);
        var handle = previous?.Handle ?? ws.Handle("c", proposalId.ToString(), label);
        ws.Cards.RemoveAll(c => c.ProposalId == proposalId);
        ws.Cards.Add(new(handle, proposalId, revision, Kind(intent), label, true));
        ws.CardsEmitted++;
        var summary = new Dictionary<string, object?> { ["ok"] = true, ["card"] = handle, ["kind"] = Kind(intent), ["summary"] = label };
        if (intent is BuddyWorkout workout)
        {
            summary["exercises"] = workout.Exercises.Select(e => new { mention = e.Mention, matched = e.ExerciseRef is not null, sets = e.Sets.Length }).ToArray();
        }
        if (intent is BuddyFoodLog food)
        {
            var n = CardMath.Card(food.Items);
            log.FoodCardKcal.Add(n?.Kcal);
            if (n is not null) { summary["nutrients"] = ClaimSet.Nutrients(ws, n, "card", null, "on card " + handle); }
        }
        return new(new(proposalId, revision, previous is null ? null : new(previous.ProposalId, previous.Revision), intent), AgentTools.Result(summary));
    }

    private async Task<(BuddyIntent?, string?, string?)> FoodLogAsync(FoodLogArgs? a, TurnWorkspace ws, CancellationToken ct)
    {
        if (a is null || a.Items is not { Length: > 0 and <= 30 } || !Hints(a.DateHint)) { return (null, null, "invalidArgs"); }
        if (ParseAll(a.Items, ws) is not { } parsed) { return (null, null, "invalidArgs"); }
        var rule = Rules(Intent(ParsedKind.FoodLog) with { Items = parsed, TimeHint = a.TimeHint, SlotHint = a.SlotHint, DateHint = a.DateHint, DishGroup = a.DishGroup }, Input(ws, []));
        if (rule is not null) { return (null, null, rule); }
        var items = await ResolveItemsAsync(a.Items, parsed, ws, ct);
        if (items.Any(ResolveFoods.Unmatched)) { return (null, null, "unmatchedFood"); }
        return (new BuddyFoodLog(ws.Language, ws.Script, a.TimeHint, a.SlotHint, a.DateHint, a.DishGroup, items), a.Replaces, null);
    }

    private async Task<(BuddyIntent?, string?, string?)> EditAsync(DiaryEditArgs? a, TurnWorkspace ws, CancellationToken ct)
    {
        if (a is null || !Hints(a.DateHint, a.Move?.DateHint) || (a.Amount is null) != (a.Unit is null)) { return (null, null, "invalidArgs"); }
        if (References(a.Entries, ws, out var entries) is not { } refs) { return (null, null, "unknownHandle"); }
        ParsedFood[] replacement = [];
        if (a.Replacement is { } r) { if (Parse(r, ws) is not { } food) { return (null, null, "invalidArgs"); } replacement = [food]; }
        var intent = Intent(ParsedKind.DiaryEdit) with
        {
            Items = replacement,
            Reference = new(refs, a.Mention, a.All ? ParsedScope.All : ParsedScope.One, a.DateHint, a.SlotHint),
            Portion = a.Amount is { } amount ? new((decimal)amount, a.Unit, null, null, false) : null,
            Move = a.Move is { } m ? new(m.DateHint, m.SlotHint, m.TimeHint) : null,
        };
        if (Rules(intent, Input(ws, entries)) is { } rule) { return (null, null, rule); }
        return (await new ResolveReferences(foods).EditAsync(intent, Input(ws, entries), ws.Language, ws.Script, ct), a.Replaces, null);
    }

    private static (BuddyIntent?, string?, string?) Delete(DiaryDeleteArgs? a, TurnWorkspace ws)
    {
        if (a is null || !Hints(a.DateHint)) { return (null, null, "invalidArgs"); }
        if (References(a.Entries, ws, out var entries) is not { } refs) { return (null, null, "unknownHandle"); }
        var intent = Intent(ParsedKind.DiaryDelete) with { Reference = new(refs, a.Mention, a.All ? ParsedScope.All : ParsedScope.One, a.DateHint, a.SlotHint) };
        if (Rules(intent, Input(ws, entries)) is { } rule) { return (null, null, rule); }
        return (ResolveReferences.Delete(intent, Input(ws, entries), ws.Language, ws.Script), a.Replaces, null);
    }

    private static (BuddyIntent?, string?, string?) Copy(DiaryCopyArgs? a, TurnWorkspace ws)
    {
        if (a is null || !Hints(a.SourceDateHint, a.TargetDateHint)) { return (null, null, "invalidArgs"); }
        var intent = Intent(ParsedKind.DiaryCopy) with
        {
            DateHint = a.SourceDateHint,
            SlotHint = a.SourceSlotHint,
            TimeHint = a.SourceTimeHint,
            Move = new(a.TargetDateHint, a.TargetSlotHint, a.TargetTimeHint),
        };
        if (Rules(intent, Input(ws, [])) is { } rule) { return (null, null, rule); }
        return (ResolveReferences.Copy(intent, ws.Language, ws.Script), a.Replaces, null);
    }

    private static (BuddyIntent?, string?, string?) SavedMeal(SavedMealArgs? a, TurnWorkspace ws)
    {
        if (a is null || !Hints(a.DateHint)) { return (null, null, "invalidArgs"); }
        var share = a.ShareFraction is null && a.SharePeople is null ? null : new ParsedPortion(null, null, (decimal?)a.ShareFraction, a.SharePeople, false);
        if (a.Op == SavedMealOp.Log)
        {
            if (ws.Resolve(a.Meal, "m") is not { } meal) { return (null, null, "unknownHandle"); }
            var index = ws.SavedMeals.FindIndex(m => m.Id.ToString() == meal.Id);
            var intent = Intent(ParsedKind.SavedMealLog) with { ListRef = index, Portion = share, DateHint = a.DateHint, SlotHint = a.SlotHint, TimeHint = a.TimeHint };
            if (Rules(intent, Input(ws, [])) is { } rule) { return (null, null, rule); }
            return (ResolveReferences.SavedMealLog(intent, Input(ws, []), ws.Language, ws.Script), a.Replaces, null);
        }
        if (string.IsNullOrWhiteSpace(a.Name) || a.Name.Length > 120) { return (null, null, "invalidArgs"); }
        Guid? card = null;
        if (a.FromCard is not null)
        {
            if (ws.Resolve(a.FromCard, "c") is not { } c) { return (null, null, "unknownCard"); }
            card = Guid.Parse(c.Id);
        }
        var entries = new List<RecentEntry>();
        var refs = a.Entries is { Length: > 0 } list ? References(list, ws, out entries) : [];
        if (refs is null) { return (null, null, "unknownHandle"); }
        var create = Intent(ParsedKind.SavedMealCreate) with
        {
            Create = new(a.Name.Trim(), [], card is not null),
            Reference = card is not null ? null : new(refs, a.Name, ParsedScope.All, a.DateHint, a.SlotHint),
        };
        var input = Input(ws, entries) with { ActiveProposal = card };
        if (Rules(create, input) is { } createRule) { return (null, null, createRule); }
        return (ResolveReferences.SavedMealCreate(create, input, ws.Language, ws.Script), a.Replaces, null);
    }

    private async Task<(BuddyIntent?, string?, string?)> BatchAsync(BatchArgs? a, TurnWorkspace ws, CancellationToken ct)
    {
        if (a is null || !Hints(a.DateHint)) { return (null, null, "invalidArgs"); }
        var portion = a.PortionAmount is null && a.PortionFraction is null && a.PortionPeople is null && !a.Rest ? null
            : new ParsedPortion((decimal?)a.PortionAmount, a.PortionUnit, (decimal?)a.PortionFraction, a.PortionPeople, a.Rest);
        if (a.Op == BatchOp.Create)
        {
            if (a.Ingredients is not { Length: > 0 and <= 30 } || ParseAll(a.Ingredients, ws) is not { } ingredients) { return (null, null, "invalidArgs"); }
            var intent = Intent(ParsedKind.Batch) with
            {
                Items = ingredients,
                Portion = portion,
                DateHint = a.DateHint,
                SlotHint = a.SlotHint,
                TimeHint = a.TimeHint,
                Batch = new(a.Name, (decimal?)a.CookedAmount, a.CookedUnit, a.Path),
            };
            if (Rules(intent, Input(ws, [])) is { } rule) { return (null, null, rule); }
            return (await new ResolveCreations(foods).BatchAsync(intent, Input(ws, []), ws.Language, ws.Script, ct), a.Replaces, null);
        }
        if (ws.Resolve(a.Batch, "b") is not { } batch) { return (null, null, "unknownHandle"); }
        var index = ws.OpenBatches.FindIndex(b => b.Id.ToString() == batch.Id);
        if (a.Op == BatchOp.Close)
        { return (ResolveCreations.BatchClose(Intent(ParsedKind.BatchClose) with { ListRef = index }, Input(ws, []), ws.Language, ws.Script), a.Replaces, null); }
        var eat = Intent(ParsedKind.BatchPortion) with { ListRef = index, Portion = portion, DateHint = a.DateHint, SlotHint = a.SlotHint, TimeHint = a.TimeHint };
        if (Rules(eat, Input(ws, [])) is { } portionRule) { return (null, null, portionRule); }
        return (ResolveCreations.BatchPortion(eat, Input(ws, []), ws.Language, ws.Script), a.Replaces, null);
    }

    private async Task<(BuddyIntent?, string?, string?)> PersonalFoodAsync(PersonalFoodArgs? a, TurnWorkspace ws, CancellationToken ct)
    {
        if (a is null || string.IsNullOrWhiteSpace(a.Name) || a.Name.Length > 120 || a.Aliases is { Length: > 5 }) { return (null, null, "invalidArgs"); }
        var components = a.Components is { Length: > 0 } list ? ParseAll(list, ws) : [];
        if (components is null || components.Length > 30) { return (null, null, "invalidArgs"); }
        ParsedStated? stated = null;
        if (a.Stated is { } s)
        {
            double?[] nutrients = [s.Kcal, s.ProteinG, s.CarbsG, s.FatG, s.FiberG];
            if (nutrients.All(v => v is null)) { return (null, null, "invalidArgs"); }
            // TD-092: stated figures are the user's own numbers, each written in the message; never computed or filled.
            var literals = MessageNumbers.Parse(ws.MessageText);
            if (nutrients.Append(s.ServingG).Append(s.ServingMl).Any(v => v is { } x && !literals.Contains((decimal)x))) { return (null, null, "statedNotLiteral"); }
            stated = new(s.Basis, D(s.ServingG), D(s.ServingMl), D(s.Kcal), D(s.ProteinG), D(s.CarbsG), D(s.FatG), D(s.FiberG));
        }
        if (stated is null && components.Length == 0) { return (null, null, "invalidArgs"); }
        var intent = Intent(ParsedKind.PersonalFoodCreate) with
        {
            Items = components,
            Stated = stated,
            Create = new(a.Name.Trim(), (a.Aliases ?? []).Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).ToArray(), false),
        };
        if (Rules(intent, Input(ws, [])) is { } rule) { return (null, null, rule); }
        return (await new ResolveCreations(foods).PersonalFoodAsync(intent, Input(ws, []), ws.Language, ws.Script, ct), a.Replaces, null);
    }

    private async Task<(BuddyIntent?, string?, string?)> MemoryAsync(MemoryArgs? a, TurnWorkspace ws, CancellationToken ct)
    {
        if (a is null || (a.Amount is null) != (a.Unit is null)) { return (null, null, "invalidArgs"); }
        ParsedFood[] food = [];
        if (a.Food is { } f) { if (Parse(f, ws) is not { } parsed) { return (null, null, "invalidArgs"); } food = [parsed]; }
        var intent = Intent(ParsedKind.MemoryChange) with
        { Items = food, Memory = new(a.Operation, a.MemoryKind, a.Subject, a.Dimension, a.Value, (decimal?)a.Amount, a.Unit) };
        if (Rules(intent, Input(ws, [])) is { } rule) { return (null, null, rule); }
        return (await new ResolveCreations(foods).MemoryAsync(intent, Input(ws, []), ws.Language, ws.Script, ct), a.Replaces, null);
    }

    private static (BuddyIntent?, string?, string?) WeighIn(WeighInArgs? a, TurnWorkspace ws)
    {
        if (a is null || !Hints(a.DateHint) || a.Value is <= 0 or > 1000) { return (null, null, "invalidArgs"); }
        // The value is the user's own number, transcribed (like stated figures, TD-092).
        if (!MessageNumbers.Parse(ws.MessageText).Contains((decimal)a.Value)) { return (null, null, "notStated"); }
        return (new BuddyWeighIn(ws.Language, ws.Script, a.Value, Name(a.Unit), a.TimeHint, a.DateHint), a.Replaces, null);
    }

    private async Task<(BuddyIntent?, string?, string?)> SuggestAsync(SuggestArgs? a, TurnWorkspace ws, CancellationToken ct)
    {
        if (a is null || a.Options is not { Length: >= 2 and <= 4 }) { return (null, null, "invalidArgs"); }
        var options = new List<BuddySuggestionOption>();
        foreach (var option in a.Options)
        {
            if (option.Items is not { Length: > 0 and <= 10 } || string.IsNullOrWhiteSpace(option.Label)) { continue; }
            if (ParseAll(option.Items, ws) is not { } parsed || Rules(Intent(ParsedKind.FoodLog) with { Items = parsed, SlotHint = option.SlotHint }, Input(ws, [])) is not null) { continue; }
            var items = await ResolveItemsAsync(option.Items, parsed, ws, ct);
            if (items.Any(ResolveFoods.Unmatched)) { continue; }
            // FD-082: with the halal setting on, suggestions keep only options without any halal flag.
            if (ws.Halal && items.Any(Flagged)) { continue; }
            // Suggestion text is model text: claims rendered, guarded; a failing label becomes the food names (template, AI-175).
            var label = ReplyGuard.Check(option.Label, ws.Claims, ws.MassUnit, ws.LengthUnit);
            options.Add(new(Short(label.Clean ? label.Rendered : string.Join(", ", items.Select(i => i.Match?.NameEn ?? i.Mention)), 120), option.SlotHint, items));
        }
        return options.Count >= 2 ? (new BuddySuggestion(ws.Language, ws.Script, [.. options]), a.Replaces, null) : (null, null, "unmatchedFood");
    }

    private static bool Flagged(BuddyFoodItem item) => HalalCheck.Flags(item.Match?.NameEn, item.Match?.NameAr, item.Mention).Length > 0;

    /// <summary>
    /// <c>check_fit</c> (B26 D11): each option resolved like a suggestion, its kcal and protein computed by code, compared with what
    /// is left today (the snapshot's claims). Unknown remaining → <c>fits: null</c>; an option code can't compute says why.
    /// </summary>
    public async Task<string> CheckFitAsync(CheckFitArgs a, TurnWorkspace ws, CancellationToken ct)
    {
        if (a.Options is not { Length: >= 1 and <= 4 }) { return AgentTools.Error("invalidArgs"); }
        var context = ws.Claims.Take(ws.ContextClaims).ToArray();
        var kcalLeft = context.FirstOrDefault(c => c is { Metric: "kcal", Operation: "remaining", Period: "today" })?.Value;
        var proteinLeft = context.FirstOrDefault(c => c is { Metric: "protein", Operation: "remaining", Period: "today" })?.Value;
        var results = new List<object>();
        foreach (var option in a.Options)
        {
            if (option.Items is not { Length: > 0 and <= 10 } || ParseAll(option.Items, ws) is not { } parsed) { results.Add(new { error = "invalidArgs" }); continue; }
            var items = await ResolveItemsAsync(option.Items, parsed, ws, ct);
            var names = string.Join(", ", items.Select(i => i.Match?.NameEn ?? i.Mention).Take(4));
            if (items.Any(ResolveFoods.Unmatched)) { results.Add(new { option = names, error = "unmatchedFood" }); continue; }
            var halal = ws.Halal && items.Any(Flagged);
            if (CardMath.Card(items) is not { } n) { results.Add(new { option = names, error = "needsAmounts", halalFlag = halal }); continue; }
            var claims = ClaimSet.Nutrients(ws, n, "option", null, "in " + names);
            string? after = kcalLeft is { } left ? ws.AddClaim("kcal", "remaining", "today", ClaimSet.Round(left - n.Kcal), null, "kcal", "left today after " + names).Id : null;
            string? proteinAfter = proteinLeft is { } p ? ws.AddClaim("protein", "remaining", "today", ClaimSet.Round(p - n.ProteinG, 1), null, "g", "protein left today after " + names).Id : null;
            results.Add(new
            {
                option = names,
                kcal = claims["kcal"],
                protein = claims["protein"],
                kcalLeftAfter = after,
                proteinLeftAfter = proteinAfter,
                fits = kcalLeft is { } l ? n.Kcal <= l : (bool?)null,
                halalFlag = halal
            });
        }
        return AgentTools.Result(new { ok = true, options = results });
    }

    /// <summary>A stated body measurement (B26 D8): built-in kinds only, the unit fits the kind, the value as written (TD-092).</summary>
    private static (BuddyIntent?, string?, string?) Measurement(MeasurementArgs? a, TurnWorkspace ws)
    {
        if (a is null || !Hints(a.DateHint) || !double.IsFinite(a.Value) || a.Value is <= 0 or > 1000) { return (null, null, "invalidArgs"); }
        if ((a.Kind == MeasurementKindArg.BodyFat) != (a.Unit == MeasurementUnitArg.Percent) || a.Unit == MeasurementUnitArg.Percent && a.Value > 100)
        { return (null, null, "unitMismatch"); }
        if (!MessageNumbers.Parse(ws.MessageText).Contains((decimal)a.Value)) { return (null, null, "notStated"); }
        var kind = Enum.Parse<BuddyBodyMeasurementKind>(a.Kind.ToString());
        var unit = Enum.Parse<BuddyMeasurementUnit>(a.Unit.ToString());
        return (new BuddyMeasurement(ws.Language, ws.Script, kind, null, a.Value, unit, a.TimeHint, a.DateHint), a.Replaces, null);
    }

    /// <summary>
    /// Pasted rows (WB-030–032, B26 D9): each row's original text is a literal piece of the message, and its value and unit are
    /// in that text; dates are as read. Unit inference, jumps and duplicates are flagged by the app.
    /// </summary>
    private static (BuddyIntent?, string?, string?) Import(ImportArgs? a, TurnWorkspace ws)
    {
        if (a is null || a.Rows is not { Length: > 0 and <= 200 } || (a.Metric == ImportMetricArg.Measurement) != (a.MeasurementKind is not null))
        { return (null, null, "invalidArgs"); }
        var message = Flat(ws.MessageText);
        var rows = new List<BuddyImportRow>();
        foreach (var row in a.Rows)
        {
            if (string.IsNullOrWhiteSpace(row.Original) || row.Original.Length > 200 || row.Unit is { Length: 0 or > 16 }) { return (null, null, "invalidArgs"); }
            var original = Flat(row.Original);
            // A whole span of the message ("80kg" never inside "180kg", Codex B26 #5); its value a number token in it, its unit
            // written right after a number in it.
            if (!Spans.Contains(message, original)) { return (null, null, "originalNotInMessage"); }
            if (row.Value is { } v && (!double.IsFinite(v) || v is < 0 or > 100000 || !MessageNumbers.Parse(row.Original).Contains((decimal)v))) { return (null, null, "notStated"); }
            if (row.Unit is { } u && !System.Text.RegularExpressions.Regex.IsMatch(original, "[0-9]\\s*" + System.Text.RegularExpressions.Regex.Escape(Flat(u)) + "(?![\\p{L}])"))
            { return (null, null, "notStated"); }
            // The date is read by code from the original (Codex B26 #7); the model's reading is never used.
            rows.Add(new(ImportDates.Parse(row.Original), row.Value, row.Unit?.Trim(), row.Original.Trim()));
        }
        var kind = a.MeasurementKind is { } k ? Enum.Parse<BuddyBodyMeasurementKind>(k.ToString()) : (BuddyBodyMeasurementKind?)null;
        return (new BuddyImportRows(ws.Language, ws.Script, a.Metric == ImportMetricArg.Weight ? BuddyImportMetric.Weight : BuddyImportMetric.Measurement, kind, [.. rows]), a.Replaces, null);
    }

    private static string Flat(string text) => string.Join(' ', text.ToLowerInvariant().Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));

    /// <summary>
    /// A workout (WO-030–033, B26 D5–D7). Exercises resolve to library codes or the user's own exercise handles (null → the app
    /// asks). Sets come from the user's own notation read by code (SetNotation); the model's sets are used only when there is no
    /// notation, and then only with numbers the user stated. "Same as last … but …" copies a session the phone returned.
    /// </summary>
    private async Task<(BuddyIntent?, string?, string?)> WorkoutAsync(WorkoutArgs? a, TurnWorkspace ws, CancellationToken ct)
    {
        if (a is null || a.Exercises is not { Length: <= 30 } || !Hints(a.DateHint) || a.Name is { Length: > 120 }) { return (null, null, "invalidArgs"); }
        SeenWorkout? basis = null;
        if (a.CopyFrom is not null)
        {
            if (ws.Resolve(a.CopyFrom, "w") is not { } w || ws.Workouts.FirstOrDefault(x => x.Id.ToString() == w.Id) is not { } seen) { return (null, null, "unknownHandle"); }
            basis = seen;
        }
        if (a.Exercises.Length == 0 && basis is null) { return (null, null, "invalidArgs"); }
        var library = await exercises.ListAsync(ct);
        var defaultUnit = ws.MassUnit == "lb" ? BuddyLoadUnit.Lb : BuddyLoadUnit.Kg;
        var segments = Segments(a.Exercises, ws.MessageText);
        var argUnit = (WorkoutExerciseArg e) => e.Unit is { } u ? (u == WeightUnit.Lb ? BuddyLoadUnit.Lb : BuddyLoadUnit.Kg) : defaultUnit;
        var list = (basis?.Exercises ?? []).Select(e => new WorkoutLine(e.Ref, e.Name, [.. e.Sets], ["copied from " + (basis!.Name ?? "your last session")])).ToList();
        for (var k = 0; k < a.Exercises.Length; k++)
        {
            var arg = a.Exercises[k];
            if (string.IsNullOrWhiteSpace(arg.Mention) || arg.Mention.Length > 200 || arg.Notation is { Length: > 200 } || arg.Sets is { Length: > 50 }) { return (null, null, "invalidArgs"); }
            string? exerciseRef = null; LibraryExercise? known = null;
            if (arg.Exercise is { } handle)
            {
                if (ws.Resolve(handle, "x") is { } x) { exerciseRef = x.Id; known = library.FirstOrDefault(l => l.Id == x.Id); }
                else if (library.FirstOrDefault(l => l.Id == handle.Trim()) is { } code) { exerciseRef = code.Id; known = code; }
                else { return (null, null, "unknownExercise"); }
            }
            var existing = exerciseRef is null ? null : list.FirstOrDefault(l => l.Ref == exerciseRef);
            var assumptions = new List<string>();
            NotationResult? parsed = null;
            if (arg.Notation is { Length: > 0 } notation)
            {
                if (!SetNotation.InMessage(notation, ws.MessageText)) { return (null, null, "notationNotStated"); }
                parsed = SetNotation.Parse(notation);
            }
            List<NotationSet> sets;
            if (parsed is { LoadOnly: true } load)
            {
                if (existing is null) { return (null, null, "setsNeeded"); }
                // A new load takes the notation's unit, else the argument's, else the profile's; never the copied session's (#6).
                var unit = load.Sets[0].Unit ?? argUnit(arg);
                sets = [.. existing.Sets.Select(x => x with { Weight = load.Sets[0].Weight, Unit = unit })];
            }
            else if (parsed is not null)
            {
                sets = [.. parsed.Sets];
                if (arg.Sets is { Length: > 0 } given && !Same(given, sets)) { assumptions.Add("sets read from “" + Short(arg.Notation!, 40) + "”"); }
            }
            else if (arg.Sets is { Length: > 0 } given)
            {
                // No notation code could read: every number must be a quantity stated in this exercise's part of the message,
                // in its own unit (minutes stay minutes, Codex B26 #4), and repeated sets need a stated count.
                if (segments[k] is not { } segment || Stated(given, StatedQuantities.Parse(segment), SetCounts(segment)) is not { } read) { return (null, null, "setsNotStated"); }
                sets = read;
            }
            else { sets = existing?.Sets ?? []; }
            if (sets.Any(x => x.Reps is < 1 or > 1000 || x.Weight is < 0 or > 10000 || x.DurationSeconds is < 1 or > 86_400 || x.DistanceMeters is < 0 or > 1_000_000))
            { return (null, null, "invalidArgs"); }
            if (known is not null && !Exercises.Names(known, arg.Mention)) { assumptions.Insert(0, "matched “" + Short(arg.Mention, 40) + "” → " + known.Name); }
            var line = new WorkoutLine(exerciseRef, arg.Mention.Trim(), sets, assumptions, known, arg);
            if (existing is not null) { list[list.IndexOf(existing)] = line with { Assumptions = [.. existing.Assumptions, .. assumptions] }; }
            else { list.Add(line); }
        }
        if (list.Count is 0 or > 30) { return (null, null, "invalidArgs"); }
        var built = list.Select(l =>
        {
            var lib = l.Known ?? library.FirstOrDefault(x => x.Id == l.Ref);
            var hasLoad = l.Sets.Any(x => x.Weight is not null);
            var dumbbell = lib?.Equipment == "dumbbell";
            var perDumbbell = dumbbell ? l.Arg?.PerDumbbell ?? true : l.Arg?.PerDumbbell ?? false;
            var notes = new List<string>(l.Assumptions);
            if (hasLoad && dumbbell && l.Arg?.PerDumbbell is null) { notes.Add("weight per dumbbell"); }
            if (hasLoad && lib?.Type == "bodyweight_reps") { notes.Add("added load"); }
            if (hasLoad && lib?.Type == "assisted") { notes.Add("assistance weight"); }
            var unit = l.Arg is { } given ? argUnit(given) : defaultUnit;
            return new BuddyWorkoutExercise(l.Mention, l.Ref,
                [.. l.Sets.Take(50).Select(x => new BuddyWorkoutSet(x.Reps, x.Weight, x.Weight is null ? null : x.Unit ?? unit, perDumbbell, x.DurationSeconds, x.DistanceMeters))],
                [.. notes.Distinct().Take(5).Select(n => Short(n, 120))]);
        }).ToArray();
        return (new BuddyWorkout(ws.Language, ws.Script, a.Name?.Trim() is { Length: > 0 } name ? name : basis?.Name, a.TimeHint, a.DateHint, built), a.Replaces, null);
    }

    /// <summary>Each exercise's part of the message: from its mention to the next exercise's mention (null when not written).</summary>
    private static string?[] Segments(WorkoutExerciseArg[] args, string message)
    {
        var text = SetNotation.Normalize(message);
        var starts = args.Select(e => string.IsNullOrWhiteSpace(e.Mention) ? -1 : text.IndexOf(SetNotation.Normalize(e.Mention), StringComparison.Ordinal)).ToArray();
        return [.. starts.Select(start =>
        {
            if (start < 0) { return null; }
            var end = starts.Where(s => s > start).DefaultIfEmpty(text.Length).Min();
            return text[start..end];
        })];
    }

    /// <summary>The model's sets when each number is a stated quantity of its kind, with the unit the user wrote; null otherwise.</summary>
    private static List<NotationSet>? Stated(WorkoutSetArg[] given, Quantity[] said, HashSet<int> setCounts)
    {
        bool Has(decimal v, params QuantityUnit[] units) => said.Any(q => q.Value == v && units.Contains(q.Unit));
        var sets = new List<NotationSet>();
        foreach (var g in given)
        {
            if (g.Reps is { } r && !Has(r, QuantityUnit.Plain)) { return null; }
            BuddyLoadUnit? unit = null;
            if (g.Weight is { } w)
            {
                var q = said.FirstOrDefault(x => x.Value == (decimal)w && x.Unit is QuantityUnit.Plain or QuantityUnit.Kg or QuantityUnit.Lb);
                if (q is null) { return null; }
                unit = q.Unit switch { QuantityUnit.Kg => BuddyLoadUnit.Kg, QuantityUnit.Lb => BuddyLoadUnit.Lb, _ => null };
            }
            if (g.DurationSeconds is { } d && !Has(d, QuantityUnit.Seconds) && !(d % 60 == 0 && Has(d / 60, QuantityUnit.Minutes))) { return null; }
            if (g.DistanceMeters is { } m && !Has((decimal)m, QuantityUnit.Meters) && !Has((decimal)m / 1000, QuantityUnit.Km)) { return null; }
            sets.Add(new(g.Reps, g.Weight, unit, g.DurationSeconds, g.DistanceMeters));
        }
        // Multiplicity: one set, sets that each differ (each was written), or an explicit set count ("3 sets", "3x8", "3 times");
        // a rep count or a load never authorizes repetition (fix-check).
        var repeated = sets.Count > 1 && sets.Distinct().Count() < sets.Count;
        return !repeated || setCounts.Contains(sets.Count) ? sets : null;
    }

    /// <summary>Set counts the text states explicitly: "N sets", "N times", or N directly before "x" and a rep count ("3x8").</summary>
    private static HashSet<int> SetCounts(string segment) =>
        [.. System.Text.RegularExpressions.Regex.Matches(segment, @"(?<![0-9.])([0-9]{1,2})\s*(?:sets?\b|times\b|x(?=\s*[0-9]))")
            .Select(m => int.Parse(m.Groups[1].Value, System.Globalization.CultureInfo.InvariantCulture))];

    private sealed record WorkoutLine(string? Ref, string Mention, List<NotationSet> Sets, List<string> Assumptions,
        LibraryExercise? Known = null, WorkoutExerciseArg? Arg = null);

    private static bool Same(WorkoutSetArg[] given, List<NotationSet> sets) =>
        given.Length == sets.Count && given.Zip(sets).All(p => p.First.Reps == p.Second.Reps && p.First.Weight == p.Second.Weight
            && p.First.DurationSeconds == p.Second.DurationSeconds && p.First.DistanceMeters == p.Second.DistanceMeters);

    /// <summary>
    /// Food items (AI-070): personal slice → catalog → badged estimate. A handle the model passes pins its candidate only when
    /// no personal food matched; a personal match is never replaced by shared nutrition.
    /// </summary>
    private async Task<BuddyFoodItem[]> ResolveItemsAsync(FoodArg[] args, ParsedFood[] parsed, TurnWorkspace ws, CancellationToken ct)
    {
        var items = new List<BuddyFoodItem>();
        for (var i = 0; i < args.Length; i++)
        {
            var item = await foods.ResolveAsync(parsed[i], [.. ws.PersonalFoods], ct);
            if (item.Match?.Source != "personal" && ServerTools.Food(ws, args[i].Food) is { } pinned && item.Match?.Key != pinned.Key)
            {
                var others = new[] { item.Match }.Concat(item.Alternatives).OfType<BuddyCandidate>().Where(c => c.Key != pinned.Key).Take(3).ToArray();
                item = item with { Match = pinned, Alternatives = others, Estimate = null };
            }
            items.Add(item);
        }
        return [.. items];
    }

    private static ParsedFood[]? ParseAll(FoodArg[] args, TurnWorkspace ws)
    {
        var parsed = args.Select(a => Parse(a, ws)).ToArray();
        return parsed.Any(p => p is null) ? null : parsed.OfType<ParsedFood>().ToArray();
    }

    /// <summary>The B08 food rules as a parsed mention (bounds as interpret validated them).</summary>
    private static ParsedFood? Parse(FoodArg a, TurnWorkspace ws)
    {
        static bool Text(string? s) => !string.IsNullOrWhiteSpace(s) && s.Length <= 200;
        var pinned = ServerTools.Food(ws, a.Food);
        var canonical = Text(a.CanonicalNameEn) ? a.CanonicalNameEn : pinned?.NameEn;
        if (!Text(a.Mention) || canonical is null || a.NameAr is { Length: > 200 } || a.Variant is { Length: > 200 }) { return null; }
        if (a.Amount is { } amount ? amount is <= 0 or > 100000 || a.Unit is null : a.Unit is not null) { return null; }
        if (a.ShareFraction is not null && a.SharePeople is not null || a.ShareFraction is <= 0 or > 1 || a.SharePeople is <= 0 or > 1000) { return null; }
        var ambiguities = (a.Ambiguities ?? []).Distinct().Take(4).ToArray();
        BuddyRange? estimate = a.Estimate is { } e && ValidRange(e.Low, e.High) ? new(e.Low, e.High) : null;
        var share = a.ShareFraction is null && a.SharePeople is null ? null : new Share((decimal?)a.ShareFraction, a.SharePeople);
        return new(a.Mention.Trim(), canonical.Trim(), a.NameAr, (decimal?)a.Amount, a.Unit, a.Amount is not null && a.AmountExplicit, a.State, a.Variant, share, ambiguities, estimate);
    }

    /// <summary>A physically bounded badged range per 100 g (B08): the only model nutrition, and only when nothing matched.</summary>
    private static bool ValidRange(BuddyNutrients low, BuddyNutrients high)
    {
        double[] lo = [low.Kcal, low.ProteinG, low.CarbsG, low.FatG, low.FiberG]; double[] hi = [high.Kcal, high.ProteinG, high.CarbsG, high.FatG, high.FiberG];
        return lo.Zip(hi).All(p => double.IsFinite(p.First) && double.IsFinite(p.Second) && p.First >= 0 && p.Second >= p.First && p.Second <= 1000) && high.Kcal > 0
            && new[] { low, high }.All(n => n.ProteinG <= 100 && n.CarbsG <= 100 && n.FatG <= 100 && n.FiberG <= 100 && n.ProteinG + n.CarbsG + n.FatG <= 105);
    }

    /// <summary>Entry handles → positions in the newest-first list the reference policy reads (TD-091).</summary>
    private static int[]? References(string[] handles, TurnWorkspace ws, out List<RecentEntry> entries)
    {
        entries = [.. ws.Entries.OrderByDescending(e => e.Date)];
        var ids = new List<int>();
        foreach (var handle in handles.Distinct(StringComparer.Ordinal))
        {
            if (ws.Resolve(handle, "e") is not { } target) { return null; }
            var index = entries.FindIndex(e => e.Id.ToString() == target.Id);
            if (index < 0) { return null; }
            ids.Add(index);
        }
        return ids.Count <= 30 ? [.. ids] : null;
    }

    private static InterpretInput Input(TurnWorkspace ws, List<RecentEntry> entries) => new(Guid.Empty, ws.MessageText, ws.Now, ws.TzOffsetMin, ws.Ramadan,
        ws.Slots, null, new([.. ws.PersonalFoods], [.. ws.SavedMeals], [.. ws.OpenBatches], ws.Memory, [.. entries], []));

    /// <summary>Interpret's semantic rules (B09a), so the resolvers get the shapes they assume; the closed code goes back to the model.</summary>
    private static string? Rules(ParsedIntent intent, InterpretInput input) => ParsedIntentRules.Validate(intent, input) is { } code ? BuddyAgent.JsonCode(code) : null;

    private static ParsedIntent Intent(ParsedKind kind) => new(kind, null, null, null, null, [], null, null, null, null, null, null, null, null, null, null);
    private static bool Hints(params string?[] hints) => hints.All(MessageNumbers.Day);
    private static decimal? D(double? value) => (decimal?)value;
    private static string Short(string s, int n) { var t = s.Trim(); return t.Length <= n ? t : t[..n]; }

    internal static string Kind(BuddyIntent intent) => intent switch
    {
        BuddyFoodLog => "foodLog",
        BuddyWeighIn => "weighIn",
        BuddyDiaryEdit => "diaryEdit",
        BuddyDiaryDelete => "diaryDelete",
        BuddyAmbiguousReference => "ambiguousReference",
        BuddyDiaryCopy => "diaryCopy",
        BuddyMemoryChange => "memoryChange",
        BuddyBatch => "batch",
        BuddyBatchPortion => "batchPortion",
        BuddyBatchClose => "batchClose",
        BuddyPersonalFoodCreate => "personalFoodCreate",
        BuddySavedMealLog => "savedMealLog",
        BuddySavedMealCreate => "savedMealCreate",
        BuddySuggestion => "suggestion",
        BuddyMeasurement => "measurement",
        BuddyWorkout => "workout",
        BuddyImportRows => "importRows",
        _ => "other",
    };

    /// <summary>A short code-made card label (names, no numbers), for the model and later updates.</summary>
    private static string Label(BuddyIntent intent)
    {
        static string Items(IEnumerable<BuddyFoodItem> items) => string.Join(", ", items.Select(i => i.Match?.NameEn ?? i.Mention).Take(6));
        var text = intent switch
        {
            BuddyFoodLog f => (f.SlotHint is { } slot ? slot + ": " : "") + Items(f.Items),
            BuddyDiaryEdit e => "edit " + e.Reference.Mention,
            BuddyDiaryDelete d => "delete " + d.Reference.Mention,
            BuddyAmbiguousReference a => "which " + a.Reference.Mention,
            BuddyDiaryCopy c => "copy " + c.Source.SlotHint,
            BuddyMemoryChange m => "remember " + (m.Subject ?? m.Value ?? "this"),
            BuddyBatch b => "batch " + (b.Name ?? Items(b.Ingredients)),
            BuddyBatchPortion => "batch portion",
            BuddyBatchClose => "close batch",
            BuddyPersonalFoodCreate p => "save " + p.Name,
            BuddySavedMealLog => "saved meal",
            BuddySavedMealCreate s => "save meal " + s.Name,
            BuddyWeighIn => "weigh-in",
            BuddySuggestion s => "ideas: " + string.Join(" / ", s.Options.Select(o => o.Label)),
            BuddyMeasurement m => "measurement: " + BuddyAgent.JsonCode(m.MeasurementKind),
            BuddyWorkout w => "workout: " + string.Join(", ", w.Exercises.Select(e => e.Mention).Take(6)),
            BuddyImportRows i => "import " + BuddyAgent.JsonCode(i.Metric) + " rows",
            _ => "card",
        };
        return text.Length <= 120 ? text : text[..120];
    }
}
