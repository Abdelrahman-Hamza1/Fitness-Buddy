using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Catalog.Contracts;
using static FitnessBuddy.Modules.Buddy.Application.IntentNames;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>
/// The server tools (06 §4.1): shared data only. Every number the model may mention comes back as a claim; foods come back as
/// f handles whose facts stay in the workspace for <c>compute</c> and the action tools.
/// </summary>
internal sealed class ServerTools(IFoodResolver catalog, IBarcodeFacts barcodes, ICurrentUser user, Exercises exercises, ActionTools actions)
{
    public Task<string> RunAsync(AgentToolCall call, TurnWorkspace ws, CancellationToken ct) => call.Name switch
    {
        "search_foods" => AgentTools.Bind<SearchFoodsArgs>(call) is { } a ? SearchAsync(a, ws, ct) : Invalid(),
        "get_dish" => AgentTools.Bind<GetDishArgs>(call) is { } d ? DishAsync(d, ws, ct) : Invalid(),
        "lookup_barcode" => AgentTools.Bind<LookupBarcodeArgs>(call) is { } b ? BarcodeAsync(b, ws, ct) : Invalid(),
        "compute" => Task.FromResult(AgentTools.Bind<ComputeArgs>(call) is { } c ? Compute(c, ws) : AgentTools.Error("invalidArgs")),
        "exercise_search" => AgentTools.Bind<ExerciseSearchArgs>(call) is { } x ? ExerciseSearchAsync(x, ws, ct) : Invalid(),
        "check_fit" => AgentTools.Bind<CheckFitArgs>(call) is { } f ? actions.CheckFitAsync(f, ws, ct) : Invalid(),
        _ => Invalid(),
    };

    private static Task<string> Invalid() => Task.FromResult(AgentTools.Error("invalidArgs"));

    private async Task<string> SearchAsync(SearchFoodsArgs args, TurnWorkspace ws, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(args.Query) || args.Query.Length > 200 || args.Arabic is { Length: > 200 }) { return AgentTools.Error("invalidArgs"); }
        var kind = args.Kind is "food" or "dish" or "branded" ? args.Kind : null;
        var hits = await catalog.ResolveAsync(new(args.Query, args.Arabic, args.State is { } s ? Name(s) : null, kind), ct);
        var candidates = new List<object>();
        foreach (var hit in hits.Take(Math.Clamp(args.Limit ?? 5, 1, 8)))
        {
            if (await catalog.DetailsAsync(hit.CatalogKey, ct) is { } facts) { candidates.Add(Describe(ws, From(facts), hit.Kind)); }
        }
        return AgentTools.Result(new { ok = true, candidates });
    }

    /// <summary>Library exercises by name (B26 D5); handles map back to library codes in propose_workout.</summary>
    private async Task<string> ExerciseSearchAsync(ExerciseSearchArgs args, TurnWorkspace ws, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(args.Query) || args.Query.Length > 200) { return AgentTools.Error("invalidArgs"); }
        var hits = Exercises.Search(await exercises.ListAsync(ct), args.Query, Math.Clamp(args.Limit ?? 5, 1, 8)).Select(e => new
        {
            exercise = ws.Handle("x", e.Id, e.Name),
            name = e.Name,
            aliases = e.Aliases.Take(4).ToArray(),
            type = e.Type,
            equipment = e.Equipment,
            muscleGroup = e.PrimaryMuscle,
            perDumbbell = e.Equipment == "dumbbell",
        }).ToArray();
        return AgentTools.Result(new { ok = true, exercises = hits });
    }

    private async Task<string> DishAsync(GetDishArgs args, TurnWorkspace ws, CancellationToken ct)
    {
        if (ws.Resolve(args.Dish, "f") is not { } target || !ws.Foods.TryGetValue(target.Id, out var food)) { return AgentTools.Error("unknownHandle"); }
        var portions = food.Servings.Where(s => s.G is not null).Select(s => new
        {
            unit = s.UnitCode,
            grams = ws.AddClaim("grams", "serving", null, ClaimSet.Round(s.G!.Value, 1), null, "g", $"in one {s.UnitCode} of {food.NameEn}").Id,
        }).ToArray();
        var similar = await catalog.ResolveAsync(new(food.NameEn, food.NameAr, null, null), ct);
        var variants = new List<object>();
        foreach (var hit in similar.Where(h => h.CatalogKey != food.Key).Take(4))
        {
            if (await catalog.DetailsAsync(hit.CatalogKey, ct) is { } facts) { variants.Add(new { food = Register(ws, From(facts)), name = facts.NameEn, state = facts.State }); }
        }
        return AgentTools.Result(new { ok = true, food = args.Dish, name = food.NameEn, state = food.State, source = food.Source, portions, variants });
    }

    private async Task<string> BarcodeAsync(LookupBarcodeArgs args, TurnWorkspace ws, CancellationToken ct)
    {
        var code = args.Code.Trim();
        if (code.Length is < 8 or > 14 || !code.All(char.IsAsciiDigit)) { return AgentTools.Error("invalidArgs"); }
        // R1 security audit: only digits the user typed in this message, as a whole run, in a message that says it is a barcode.
        // A code the model composed (from a photo, a catalog name or a phone result), or any other number the user typed (a date,
        // a phone number), could carry private facts out to Open Food Facts, so it is never looked up, not even in the cache.
        if (!TypedByUser(code, ws.MessageText)) { return AgentTools.Error("notStated"); }
        if (user.UserId is not { } owner || await barcodes.LookupAsync(code, owner, ct) is not { } product) { return AgentTools.Result(new { ok = true, found = false }); }
        var basis = product.Basis == "100ml" ? "per 100 ml" : "per 100 g";
        // Packaged products are shown for answers; the card itself resolves by name (catalog or badged estimate).
        return AgentTools.Result(new
        {
            ok = true,
            found = true,
            name = product.Name,
            brand = product.Brand,
            checkLabel = product.CheckLabel,
            nutrients = product.Per100 is { } n ? ClaimSet.Nutrients(ws, new(n.Kcal, n.ProteinG, n.CarbsG, n.FatG, n.FiberG), "per100", null, $"{basis} of {product.Name ?? "this product"}") : null,
        });
    }

    // Whole words only: "ean" inside "lean" or "beans" is no barcode request.
    private static readonly System.Text.RegularExpressions.Regex BarcodeWords = new(
        @"(?<![\p{L}\p{N}])(bar ?codes?|barcod|barkod|upc|ean(-?(8|13))?|gtin|باركود|الباركود|باركد)(?![\p{L}])",
        System.Text.RegularExpressions.RegexOptions.IgnoreCase | System.Text.RegularExpressions.RegexOptions.CultureInvariant);

    /// <summary>Whether <paramref name="code"/> is one maximal run of ASCII digits in a user message that names a barcode.</summary>
    internal static bool TypedByUser(string code, string message)
    {
        if (!BarcodeWords.IsMatch(message)) { return false; }
        for (var start = message.IndexOf(code, StringComparison.Ordinal); start >= 0; start = message.IndexOf(code, start + 1, StringComparison.Ordinal))
        {
            var end = start + code.Length;
            if ((start == 0 || !char.IsAsciiDigit(message[start - 1])) && (end == message.Length || !char.IsAsciiDigit(message[end]))) { return true; }
        }
        return false;
    }

    private static string Compute(ComputeArgs args, TurnWorkspace ws)
    {
        if (args.Items is not { Length: > 0 and <= 20 }) { return AgentTools.Error("invalidArgs"); }
        var items = new List<object>(); var parts = new List<BuddyNutrients>();
        foreach (var item in args.Items)
        {
            if (Food(ws, item.Food) is not { } food) { items.Add(new { food = item.Food, error = "unknownHandle" }); continue; }
            if (CardMath.Grams(food, item.Amount, Name(item.Unit)) is not { } grams) { items.Add(new { food = item.Food, error = "unitNotConvertible" }); continue; }
            var n = CardMath.Scale(food.Nutrients, grams); parts.Add(n);
            items.Add(new
            {
                food = item.Food,
                grams = ws.AddClaim("grams", "item", null, ClaimSet.Round(grams, 1), null, "g", "of " + food.NameEn).Id,
                nutrients = ClaimSet.Nutrients(ws, n, "item", null, $"in {item.Amount} {Name(item.Unit)} of {food.NameEn}"),
            });
        }
        var total = parts.Count > 1 ? ClaimSet.Nutrients(ws, CardMath.Sum(parts), "total", null, "in total") : null;
        return AgentTools.Result(new { ok = true, items, total });
    }

    /// <summary>The facts behind an f or p handle.</summary>
    internal static BuddyCandidate? Food(TurnWorkspace ws, string? handle)
    {
        if (ws.Resolve(handle, "f") is { } f && ws.Foods.TryGetValue(f.Id, out var food)) { return food; }
        if (ws.Resolve(handle, "p") is { } p && ws.PersonalFoods.FirstOrDefault(x => x.Id.ToString() == p.Id) is { } mine)
        { return new(mine.Id.ToString(), mine.Names[0], null, mine.State, "personal", mine.Nutrients, null, mine.Servings, null, null); }
        return null;
    }

    private static object Describe(TurnWorkspace ws, BuddyCandidate food, string kind) => new
    {
        food = Register(ws, food),
        name = food.NameEn,
        nameAr = food.NameAr,
        state = food.State,
        kind,
        source = food.Source,
        // FD-081: a warning when the halal setting is on (names only; never a block).
        halal = ws.Halal && HalalCheck.Flags(food.NameEn, food.NameAr) is { Length: > 0 } flags ? flags.Select(HalalCheck.Code).ToArray() : null,
        per100 = ClaimSet.Nutrients(ws, food.Nutrients, "per100", null, "per 100 g of " + food.NameEn),
        servings = food.Servings.Where(s => s.G is not null).Take(6).Select(s => new
        {
            unit = s.UnitCode,
            grams = ws.AddClaim("grams", "serving", null, ClaimSet.Round(s.G!.Value, 1), null, "g", $"in one {s.UnitCode} of {food.NameEn}").Id,
        }).ToArray(),
    };

    private static string Register(TurnWorkspace ws, BuddyCandidate food)
    {
        ws.Foods[food.Key] = food;
        return ws.Handle("f", food.Key, food.NameEn);
    }

    private static BuddyCandidate From(FoodDetails f) => new(f.Key, f.NameEn, f.NameAr, f.State, f.Source,
        new(f.Nutrients.Kcal, f.Nutrients.ProteinG, f.Nutrients.CarbsG, f.Nutrients.FatG, f.Nutrients.FiberG),
        f.Ranges is { } r ? new(new(r.Low.Kcal, r.Low.ProteinG, r.Low.CarbsG, r.Low.FatG, r.Low.FiberG), new(r.High.Kcal, r.High.ProteinG, r.High.CarbsG, r.High.FatG, r.High.FiberG)) : null,
        f.Servings.Select(s => new BuddyServing(s.UnitCode, s.G, s.Ml, s.RangeLo, s.RangeHi, s.Source)).ToArray(), f.DensityGPerMl, f.YieldGroup);
}
