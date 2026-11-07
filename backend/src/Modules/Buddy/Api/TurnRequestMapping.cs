using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Api;

/// <summary>Maps the public turn bodies to the Application inputs; and the checks the schema can't express (06 §3.1–§3.2).</summary>
internal static class TurnRequestMapping
{
    public static string? Invalid(BuddyTurnStart r)
    {
        if (!V7(r.TurnId)) { return "turnId"; }
        // B26 D3: the weekly aggregates come with weeklyReview and only with it, internally consistent.
        if ((r.Mode == BuddyTurnMode.WeeklyReview) != (r.Weekly is not null)) { return "weekly"; }
        // Aggregates only (B26 D3): a weekly review carries no photo.
        if (r.Mode == BuddyTurnMode.WeeklyReview && r.Message.Image is not null) { return "message"; }
        if (r.Weekly is { } w && (w.End != w.Start.AddDays(6) || w.CountedDays > w.ElapsedDays || w.TargetDays > w.CountedDays
            || w.DaysWithinTarget > w.TargetDays || w.ProteinTargetDays > w.CountedDays || w.ProteinDaysHit > w.ProteinTargetDays || !Bounded(w)))
        { return "weekly"; }
        if (string.IsNullOrWhiteSpace(r.Message.Text)) { return "message"; }
        if (r.Message.Image is { } image && !Jpeg(image)) { return "message"; }
        if (r.Snapshot is null || r.Profile is null || r.History is null || r.Personal is null) { return "snapshot"; }
        if (r.Personal.Select(p => p.Ref).Distinct().Count() != r.Personal.Length || r.Personal.Any(p => p.Ref == Guid.Empty)) { return "personal"; }
        if (r.Snapshot.OpenCards.Select(c => c.ProposalId).Distinct().Count() != r.Snapshot.OpenCards.Length) { return "snapshot"; }
        if (!Bounded(r.History) || !Bounded(r.Personal) || !Bounded(r.Profile) || !Bounded(r.Snapshot) || !Bounded(r.Compact) || !Bounded(r.PriorAttempt)) { return "body"; }
        return null;
    }

    public static string? Invalid(BuddyTurnContinue r)
    {
        if (!V7(r.TurnId)) { return "turnId"; }
        // The phone's scope caps, rechecked (the result data are polymorphic, so the generator can't reach them).
        foreach (var result in r.Results)
        {
            if (result is null) { return "results"; }
            if (result is BuddyUnsupportedResult) { if (result.Ok || result.Error != BuddyPhoneToolError.Unsupported) { return "results"; } continue; }
            var rows = Rows(result);
            if (rows is null || result.Ok != (rows >= 0) || result.Ok == result.Error.HasValue) { return "results"; }
            // Nested limits the polymorphic result data hide from the validation generator, checked before any ledger change.
            if (!Bounded(result)) { return "results"; }
        }
        return Bounded(r.PriorAttempt) ? null : "priorAttempt";
    }

    public static TurnStartInput ToInput(this BuddyTurnStart r) => new(r.TurnId, r.Mode == BuddyTurnMode.WeeklyReview, r.Message.Text, r.Message.Image,
        r.History.Select(History).ToArray(), r.Summary is { } s ? new(s.Text, s.Revision, s.Watermark) : null,
        r.Compact is { } c ? new(c.Evicted.Select(History).ToArray(), c.PreviousRevision) : null,
        r.Personal.Select(Personal).ToArray(),
        new(r.Profile.Memory.Select(m => new ContextMemory(m.Kind, m.Key, m.Value)).ToArray(), r.Profile.Defaults.Select(d => new TurnDefault(d.Kind, d.Subject, d.Value)).ToArray(),
            r.Profile.Halal, Code(r.Profile.Units.Mass), Code(r.Profile.Units.Length), new(r.Profile.Ramadan.Active, r.Profile.Ramadan.Fajr, r.Profile.Ramadan.Maghrib)),
        new(r.Snapshot.Now, r.Snapshot.TzOffsetMin, r.Snapshot.Slots.Select(s => new MealSlot(s.Id, s.Name, s.Window)).ToArray(),
            new(r.Snapshot.Today.Kcal, r.Snapshot.Today.ProteinG, r.Snapshot.Today.CarbsG, r.Snapshot.Today.FatG, r.Snapshot.Today.FiberG),
            r.Snapshot.Today.Targets is { } t ? new(t.Kcal, t.ProteinG, t.CarbsG, t.FatG, t.FiberG) : null,
            r.Snapshot.OpenCards.Select(o => new TurnOpenCard(o.ProposalId, o.Revision, o.Kind, o.Summary)).ToArray()),
        r.AckTurn?.TurnId, Prior(r.PriorAttempt), r.Trace, r.Weekly is { } w ? Weekly(w) : null);

    private static TurnWeekly Weekly(BuddyWeeklySummary w) => new(w.Start, w.End, w.ElapsedDays, w.CountedDays, w.TargetDays, w.DaysWithinTarget,
        w.ProteinTargetDays, w.ProteinDaysHit, w.AverageKcal, w.AverageTargetKcal, w.AverageFiberG, w.TrendChangeKg,
        w.Workouts is { } x ? new(x.Sessions, x.Planned, x.Prs) : null, w.Estimated, w.CheckIn is { } c ? new(c.CurrentKcal, c.ProposedKcal) : null);

    public static TurnContinueInput ToInput(this BuddyTurnContinue r, JsonSerializerOptions json) => new(r.TurnId, r.Round, r.Continuation,
        r.Results.Select(x => new PhoneResultInput(x.CallId, Name(x), x.Ok, x.Error is { } e ? Code(e) : null, Data(x, json), Rows(x) ?? 0)).ToArray(),
        Prior(r.PriorAttempt));

    private static TurnHistoryEntry History(BuddyHistoryEntry h) => new(h.MessageId, Code(h.Role), h.Text,
        h.Outcomes.Select(o => new TurnOutcome(o.ProposalId, o.Kind, Code(o.Status), o.Label)).ToArray());
    private static TurnPersonalItem Personal(BuddyPersonalItem p) => new(p.Ref, Code(p.Kind), p.Names, p.Aliases, p.State, Nutrients(p.Per100),
        p.Servings.Select(s => new BuddyServing(s.UnitCode, s.G, s.Ml, s.RangeLo, s.RangeHi, s.Source)).ToArray(),
        p.Portions.Select(x => new TurnPortion(x.Label, x.G, Nutrients(x.Nutrients)!)).ToArray());
    private static BuddyNutrients? Nutrients(BuddyNutrientsRequest? n) => n is null ? null : new(n.Kcal, n.ProteinG, n.CarbsG, n.FatG, n.FiberG);
    private static TurnPriorAttempt? Prior(BuddyPriorAttempt? p) => p is null ? null
        : new(p.Attempt, p.Cards.Select(c => new TurnPriorCard(c.ProposalId, Code(c.Status), c.Revision, c.Line)).ToArray());

    internal static string Name(BuddyPhoneToolResult r) => r switch
    {
        BuddyFindMyFoodsResult => "findMyFoods",
        BuddyReadDiaryResult => "readDiary",
        BuddyReadBodyResult => "readBody",
        BuddyReadWorkoutsResult => "readWorkouts",
        BuddyReadMemoryResult => "readMemory",
        BuddyQueryDataResult => "queryData",
        BuddyUnsupportedResult => "unsupported",
        _ => "",
    };
    /// <summary>Row count within the tool's scope cap; -1 for no data; null when a cap is broken.</summary>
    private static int? Rows(BuddyPhoneToolResult r)
    {
        static int? Cap(int rows, int cap) => rows <= cap ? rows : null;
        return r switch
        {
            BuddyFindMyFoodsResult { Data: { } d } => Cap(d.Items.Length, 20),
            BuddyReadDiaryResult { Data: { } d } => Cap(d.Entries.Length, 40),
            BuddyReadBodyResult { Data: { } d } => Cap(d.Values.Length, 31) is { } n ? n + (d.Trend is null ? 0 : 1) : null,
            BuddyReadWorkoutsResult { Data: { } d } => d.Sessions.Length <= 15 && d.Prs.Length <= 20 && d.Sessions.All(s => s.Exercises.Length <= 30 && s.Exercises.All(e => e.Sets.Length <= 50))
                ? d.Sessions.Length + d.Prs.Length : null,
            BuddyReadMemoryResult { Data: { } d } => Cap(d.Items.Length, 30),
            BuddyQueryDataResult { Data: { } d } => Cap(d.Claims.Length, 20),
            { Ok: false } => -1,
            _ => -1,
        };
    }
    private static JsonElement? Data(BuddyPhoneToolResult r, JsonSerializerOptions json) => r switch
    {
        BuddyFindMyFoodsResult { Data: { } d } => JsonSerializer.SerializeToElement(d, json),
        BuddyReadDiaryResult { Data: { } d } => JsonSerializer.SerializeToElement(d, json),
        BuddyReadBodyResult { Data: { } d } => JsonSerializer.SerializeToElement(d, json),
        BuddyReadWorkoutsResult { Data: { } d } => JsonSerializer.SerializeToElement(d, json),
        BuddyReadMemoryResult { Data: { } d } => JsonSerializer.SerializeToElement(d, json),
        BuddyQueryDataResult { Data: { } d } => JsonSerializer.SerializeToElement(d, json),
        _ => null,
    };
    /// <summary>
    /// Every data annotation of every nested record and list element (the generator stops at polymorphic members), no null
    /// elements, and a 200-character cap with real content on every other string (names, aliases, slots, memory, units).
    /// </summary>
    internal static bool Bounded(object? value, int depth = 0)
    {
        if (value is null) { return true; }
        if (depth > 12) { return false; }
        if (value is string text) { return text.Length <= 200; }
        if (value is System.Collections.IEnumerable list)
        {
            foreach (var item in list)
            {
                if (item is null || item is string s && (s.Length is 0 or > 200 || string.IsNullOrWhiteSpace(s)) || item is not string && !Bounded(item, depth + 1)) { return false; }
            }
            return true;
        }
        var type = value.GetType();
        if (type.IsPrimitive || type.IsEnum || value is Guid or DateOnly or DateTimeOffset or decimal) { return true; }
        if (type.Namespace != typeof(BuddyTurnStart).Namespace) { return true; }
        if (!System.ComponentModel.DataAnnotations.Validator.TryValidateObject(value, new(value), null, validateAllProperties: true)) { return false; }
        foreach (var property in type.GetProperties())
        {
            if (property.GetIndexParameters().Length > 0 || property.Name == "EqualityContract") { continue; }
            var child = property.GetValue(value);
            var annotated = property.GetCustomAttributes(typeof(System.ComponentModel.DataAnnotations.MaxLengthAttribute), true).Length > 0;
            if (child is string && annotated) { continue; }
            if (child is double d && !double.IsFinite(d)) { return false; }
            if (!Bounded(child, depth + 1)) { return false; }
        }
        return true;
    }

    private static string Code<T>(T value) where T : Enum => JsonNamingPolicy.CamelCase.ConvertName(value.ToString());
    private static bool V7(Guid id) => id.ToString("D")[14] == '7' && "89ab".Contains(id.ToString("D")[19], StringComparison.Ordinal);
    internal static bool Jpeg(string base64)
    {
        if (base64.Length < 8) { return false; }
        Span<byte> head = stackalloc byte[3];
        return Convert.TryFromBase64String(base64[..4], head, out var n) && n == 3 && head[0] == 0xFF && head[1] == 0xD8 && head[2] == 0xFF;
    }
}
