using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Catalog.Contracts;

namespace FitnessBuddy.Modules.Buddy.Application;

internal sealed class ResolveInterpretation(IFoodResolver catalog)
{
    public async Task<BuddyInterpretation> ResolveAsync(ParsedMessage parsed, InterpretInput input, CancellationToken ct)
    {
        var intents = new List<BuddyIntent>();
        var language = Name(parsed.Language); var script = Name(parsed.Script);
        foreach (var intent in parsed.Intents)
        {
            switch (intent.Kind)
            {
                case ParsedKind.FoodLog:
                    var items = new List<BuddyFoodItem>();
                    foreach (var food in intent.Items) { items.Add(await ResolveAsync(food, input.Context.PersonalFoods, ct)); }
                    if (items.Any(f => f.Match is null && f.Estimate is null)) { intents.Add(new BuddyClarify(language, script, "unmatchedFood")); }
                    else { intents.Add(new BuddyFoodLog(language, script, intent.TimeHint, intent.SlotHint, null, intent.DishGroup, items.ToArray())); }
                    break;
                case ParsedKind.WeighIn:
                    intents.Add(new BuddyWeighIn(language, script, (double)intent.WeighIn!.Value, intent.WeighIn.Unit, intent.TimeHint, null)); break;
                case ParsedKind.Medical: intents.Add(new BuddyMedical(language, script)); break;
                case ParsedKind.OutOfScope when intent.Reason == DeclineReason.Medical: intents.Add(new BuddyMedical(language, script)); break;
                case ParsedKind.OutOfScope: intents.Add(new BuddyOutOfScope(language, script, Name(intent.Reason!.Value))); break;
                default: intents.Add(new BuddyClarify(language, script, Name(intent.Reason!.Value))); break;
            }
        }
        return new("interpret-v1", "gpt-6-luna", intents.ToArray());
    }
    private async Task<BuddyFoodItem> ResolveAsync(ParsedFood food, PersonalFood[] personal, CancellationToken ct)
    {
        var matches = new List<BuddyCandidate>(); var state = food.State is { } value ? Name(value) : null;
        var keys = new[] { food.Mention, food.CanonicalNameEn, food.NameAr, Query(food) }.Where(s => s is not null).Select(s => FoodName.Normalize(s!)).Where(s => s.Length > 0).ToHashSet(StringComparer.Ordinal);
        int MatchLength(PersonalFood p) => p.Names.Concat(p.Aliases).Select(FoodName.Normalize)
            .Where(name => name.Length > 0 && keys.Any(key => (" " + key + " ").Contains(" " + name + " ", StringComparison.Ordinal)))
            .Select(name => name.Length).DefaultIfEmpty().Max();
        foreach (var candidate in personal.Where(p => MatchLength(p) > 0
            && (state is null || p.State == state)
            && p.Names.Concat(p.Aliases).Any(n => MatchesVariant(food, n)))
            .OrderByDescending(MatchLength).ThenBy(p => p.Id))
        {
            matches.Add(new(candidate.Id.ToString(), candidate.Names[0], null, candidate.State, "personal", candidate.Nutrients, null, candidate.Servings, null, null));
        }
        if (matches.Count == 0)
        {
            async Task<FoodCandidate[]> SearchAsync(string? requestedState)
            {
                var found = await catalog.ResolveAsync(new(Query(food), food.NameAr, requestedState, null), ct);
                var eligible = found.Where(c => MatchesVariant(food, c.NameEn)).ToArray();
                var basic = FoodName.Normalize(System.Text.RegularExpressions.Regex.Replace(food.CanonicalNameEn, @"[0-9]+(?:[.,][0-9]+)?\s*(?:%|percent\b)", ""));
                if (eligible.Length == 0 && basic.Length > 0 && basic != FoodName.Normalize(Query(food)))
                {
                    found = await catalog.ResolveAsync(new(basic, food.NameAr, requestedState, null), ct);
                    eligible = found.Where(c => MatchesVariant(food, c.NameEn)).ToArray();
                }
                return eligible;
            }
            var found = await SearchAsync(state);
            // Keep other-state facts to let the phone perform yield conversions; never relabel nutrients.
            if (found.Length == 0 && state is not null) { found = await SearchAsync(null); }
            foreach (var hit in Diverse(found, food))
            {
                if (await catalog.DetailsAsync(hit.CatalogKey, ct) is { } facts && MatchesVariant(food, facts.NameEn)) { matches.Add(From(facts)); }
            }
        }
        var distinct = matches.DistinctBy(c => c.Key).Take(4).ToArray();
        var dimensions = new List<BuddyDimension>();
        foreach (var kind in food.Ambiguities)
        {
            BuddyDimensionOption[] options = kind switch
            {
                AmbiguityKind.State or AmbiguityKind.Variant => distinct.Select(c => new BuddyDimensionOption(kind == AmbiguityKind.State ? c.State : c.NameEn, c.Key, null, null, c)).Distinct().ToArray(),
                AmbiguityKind.Portion => distinct.SelectMany(c => c.Servings.Select(s => new BuddyDimensionOption(s.UnitCode, c.Key, s.G ?? s.Ml, s.G is not null ? "g" : s.Ml is not null ? "ml" : null, c))).ToArray(),
                AmbiguityKind.Fat => await FatOptionsAsync(ct),
                _ => [],
            };
            dimensions.Add(new(Name(kind), kind == AmbiguityKind.State ? state : kind == AmbiguityKind.Variant ? food.Variant : null, options));
        }
        if (state is not null && distinct.Length > 0 && distinct.All(c => c.State != state) && dimensions.All(d => d.Kind != "state"))
        { dimensions.Add(new("state", state, distinct.Select(c => new BuddyDimensionOption(c.State, c.Key, null, null, c)).ToArray())); }
        if (food.Variant is not null && dimensions.All(d => d.Kind != "variant"))
        { dimensions.Add(new("variant", food.Variant, distinct.Select(c => new BuddyDimensionOption(c.NameEn, c.Key, null, null, c)).ToArray())); }
        return new(food.Mention, distinct.FirstOrDefault(), distinct.Skip(1).ToArray(), new(food.Amount is { } a ? (double)a : null,
            food.Unit is { } u ? Name(u) : null, food.AmountExplicit), food.Share is { } share ? new(share.Fraction is { } f ? (double)f : null, share.People) : null,
            dimensions.ToArray(), distinct.Length == 0 && food.Estimate is { } range ? new(range, "noCatalogMatch") : null);
    }
    private static bool MatchesVariant(ParsedFood food, string name)
    {
        // Retrieval is fuzzy, including Arabic aliases. A specific percentage must not silently
        // become another known food's nutrition; inability to verify it falls back to Clarify/estimate.
        const string pattern = @"([0-9]+(?:[.,][0-9]+)?)\s*(?:%|percent\b)";
        var stated = System.Text.RegularExpressions.Regex.Match(food.CanonicalNameEn + " " + food.Variant, pattern);
        if (stated.Success)
        {
            if (!decimal.TryParse(stated.Groups[1].Value.Replace(',', '.'), System.Globalization.NumberStyles.AllowDecimalPoint, System.Globalization.CultureInfo.InvariantCulture, out var percent)) { return false; }
            var literal = stated.Groups[1].Value.Replace(',', '.');
            var point = literal.IndexOf('.', StringComparison.Ordinal);
            var precision = point < 0 ? 0 : Math.Min(28, literal.Length - point - 1);
            // Match the precision the user stated (3% can use labelled 3.25% milk), while
            // preserving the actual source facts and stated-variant option for the phone.
            return System.Text.RegularExpressions.Regex.Matches(name, pattern).Any(m =>
                decimal.TryParse(m.Groups[1].Value.Replace(',', '.'), System.Globalization.NumberStyles.AllowDecimalPoint, System.Globalization.CultureInfo.InvariantCulture, out var actual) && decimal.Round(actual, precision, MidpointRounding.AwayFromZero) == percent);
        }
        if (food.Variant is null || food.Variant is "small" or "medium" or "large" or "big") { return true; }
        var phrase = FoodName.Normalize(food.Variant);
        return phrase.Length > 0 && (" " + FoodName.Normalize(name) + " ").Contains(" " + phrase + " ", StringComparison.Ordinal);
    }
    private static string Query(ParsedFood food)
    {
        var query = food.Variant is not null && !food.CanonicalNameEn.Contains(food.Variant, StringComparison.OrdinalIgnoreCase)
            ? food.CanonicalNameEn + " " + food.Variant : food.CanonicalNameEn;
        return query.Length <= 200 ? query : query[..200];
    }
    private static List<FoodCandidate> Diverse(FoodCandidate[] found, ParsedFood food)
    {
        var selected = new List<FoodCandidate>();
        if (found.Length > 0) { selected.Add(found[0]); }
        if (food.Ambiguities.Contains(AmbiguityKind.State))
        {
            foreach (var candidate in found.DistinctBy(c => c.State))
            { if (selected.All(s => s.CatalogKey != candidate.CatalogKey) && selected.Count < 4) { selected.Add(candidate); } }
        }
        if (food.Ambiguities.Contains(AmbiguityKind.Variant))
        {
            foreach (var candidate in found.DistinctBy(c => c.NameEn))
            { if (selected.All(s => s.CatalogKey != candidate.CatalogKey) && selected.Count < 4) { selected.Add(candidate); } }
        }
        foreach (var candidate in found)
        { if (selected.All(s => s.CatalogKey != candidate.CatalogKey) && selected.Count < 4) { selected.Add(candidate); } }
        return selected;
    }
    private async Task<BuddyDimensionOption[]> FatOptionsAsync(CancellationToken ct)
    {
        var hits = await catalog.ResolveAsync(new("olive oil", null, null, "basic"), ct);
        var hit = hits.Count == 0 ? null : hits[0];
        var facts = hit is not null ? await catalog.DetailsAsync(hit.CatalogKey, ct) : null;
        var oil = facts is null ? null : From(facts);
        return oil is null ? [new("none", null, 0, "tsp", null)]
            : [new("none", null, 0, "tsp", null), new("oil", oil.Key, 1, "tsp", oil), new("oil", oil.Key, 1, "tbsp", oil)];
    }
    private static BuddyCandidate From(FoodDetails f) => new(f.Key, f.NameEn, f.NameAr, f.State, f.Source, N(f.Nutrients),
        f.Ranges is { } r ? new(N(r.Low), N(r.High)) : null, f.Servings.Select(s => new BuddyServing(s.UnitCode, s.G, s.Ml, s.RangeLo, s.RangeHi, s.Source)).ToArray(), f.DensityGPerMl, f.YieldGroup);
    private static BuddyNutrients N(FoodNutrients n) => new(n.Kcal, n.ProteinG, n.CarbsG, n.FatG, n.FiberG);
    private static string Name<T>(T value) where T : Enum => System.Text.Json.JsonNamingPolicy.CamelCase.ConvertName(value.ToString());
}
