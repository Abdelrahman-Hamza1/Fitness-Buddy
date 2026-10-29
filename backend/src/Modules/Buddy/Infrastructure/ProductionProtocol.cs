using System.Globalization;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Schema;
using System.Text.RegularExpressions;
using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

internal readonly record struct ProductionParse(ParsedMessage? Message, InvalidOutput? Invalid);

internal static partial class ProductionProtocol
{
    public const string Version = ParsedGrammar.Version;
    public const string SchemaName = "buddy_interpret_v2";
    public static string Prompt { get; } = Read();
    public static JsonElement Schema { get; } = JsonSerializer.SerializeToElement(InterpretProtocol.Json.GetJsonSchemaAsNode(typeof(ParsedMessage), new JsonSchemaExporterOptions
    {
        TreatNullObliviousAsNonNullable = true,
        TransformSchemaNode = (_, node) =>
        {
            if (node is JsonObject obj && obj["properties"] is JsonObject props)
            {
                obj["additionalProperties"] = false;
                obj["required"] = new JsonArray(props.Select(p => (JsonNode?)JsonValue.Create(p.Key)).ToArray());
            }
            return node;
        },
    }));

    // An allowlisted projection, never serialize the HTTP request or a principal into the provider message (AC-041).
    // List entries carry their position as `ref` (D6); IDs, grams, nutrients and activeProposal are never forwarded.
    public static string Input(InterpretInput input) => JsonSerializer.Serialize(new
    {
        input.Text,
        input.Now,
        input.TzOffsetMin,
        ramadan = new { input.Ramadan.Active, input.Ramadan.Fajr, input.Ramadan.Maghrib },
        slots = input.Slots.Select(s => new { s.Name, s.Window }),
        personalFoods = input.Context.PersonalFoods.Select(f => new { f.Names, f.Aliases, f.State }),
        memory = input.Context.Memory.Select(m => new { m.Kind, m.Key, m.Value }),
        recentEntries = input.Context.RecentEntries.Select((r, i) => new { @ref = i, r.Date, r.Slot, r.Name }),
        savedMeals = input.Context.SavedMeals.Select((r, i) => new { @ref = i, r.Name }),
        openBatches = input.Context.OpenBatches.Select((r, i) => new { @ref = i, r.Name }),
        customExercises = input.Context.CustomExercises.Select(r => r.Name),
        activeCard = input.Context.ActiveCard is { } card
            ? new { card.Slot, card.Time, lines = card.Lines.Select(l => new { l.Name, l.Amount, l.UnitCode, l.State }) }
            : null,
    }, InterpretProtocol.Json);

    public static ProductionParse Parse(string text, InterpretInput input)
    {
        if (text.Length > 64 * 1024) { return new(null, InvalidOutput.Bounds); }
        try
        {
            var parsed = JsonSerializer.Deserialize<ParsedMessage>(text, InterpretProtocol.Json);
            if (parsed is null) { return new(null, InvalidOutput.Shape); }
            return Validate(parsed, input) is { } code ? new(null, code) : new(parsed, null);
        }
        catch (JsonException) { return new(null, InvalidOutput.Shape); }
    }

    /// <summary>
    /// Semantic validation beyond the provider schema (D5/D6/D8/D9). An invalid output gets B08's single repair, then Clarify.
    /// Not invalid (PA8; the resolver clarifies <c>referenceNotFound</c> without a repair): a null <c>listRef</c>, any
    /// <c>listRef</c> into an empty list, and <c>create.fromActiveProposal</c> without a request activeProposal.
    /// </summary>
    public static InvalidOutput? Validate(ParsedMessage message, InterpretInput input)
    {
        if (!Enum.IsDefined(message.Language) || !Enum.IsDefined(message.Script) || message.Intents is null) { return InvalidOutput.Shape; }
        if (message.Intents.Length is 0 or > 10) { return InvalidOutput.Bounds; }
        foreach (var intent in message.Intents)
        {
            if (intent is null) { return InvalidOutput.Shape; }
            if (Validate(intent, input) is { } code) { return code; }
        }
        return null;
    }

    [Flags]
    private enum Group
    {
        None = 0, Time = 1, Slot = 2, Date = 4, Dish = 8, Items = 16, WeighIn = 32, Reason = 64, Reference = 128,
        Move = 256, ListRef = 512, Portion = 1024, Memory = 2048, Batch = 4096, Create = 8192, Stated = 16384,
    }
    private const Group Hints = Group.Time | Group.Slot | Group.Date;
    // Allowed and required members per kind. B08 kinds keep B08's leniency for time/slot/dishGroup; new members stay null.
    private static (Group Allowed, Group Required) Members(ParsedKind kind) => kind switch
    {
        ParsedKind.FoodLog => (Hints | Group.Dish | Group.Items, Group.Items),
        ParsedKind.WeighIn => (Hints | Group.Dish | Group.WeighIn, Group.WeighIn),
        ParsedKind.Medical => (Group.Time | Group.Slot | Group.Dish, Group.None),
        ParsedKind.Clarify or ParsedKind.OutOfScope => (Group.Time | Group.Slot | Group.Dish | Group.Reason, Group.Reason),
        ParsedKind.DiaryEdit => (Group.Reference | Group.Items | Group.Portion | Group.Move, Group.Reference),
        ParsedKind.DiaryDelete => (Group.Reference, Group.Reference),
        ParsedKind.DiaryCopy => (Hints | Group.Move, Group.None),
        ParsedKind.SavedMealLog => (Hints | Group.ListRef | Group.Portion, Group.None),
        ParsedKind.SavedMealCreate => (Group.Create | Group.Reference, Group.Create),
        ParsedKind.MemoryChange => (Group.Memory | Group.Items, Group.Memory),
        ParsedKind.Batch => (Hints | Group.Items | Group.Batch | Group.Portion, Group.Items | Group.Batch),
        ParsedKind.BatchPortion => (Hints | Group.ListRef | Group.Portion, Group.Portion),
        ParsedKind.BatchClose => (Group.ListRef, Group.None),
        ParsedKind.PersonalFoodCreate => (Group.Create | Group.Items | Group.Stated, Group.Create),
        _ => (Group.None, Group.None),
    };
    private static Group Present(ParsedIntent i)
    {
        var present = Group.None;
        void Add(bool condition, Group group) { if (condition) { present |= group; } }
        Add(i.TimeHint is not null, Group.Time); Add(i.SlotHint is not null, Group.Slot); Add(i.DateHint is not null, Group.Date);
        Add(i.DishGroup is not null, Group.Dish); Add(i.Items.Length > 0, Group.Items); Add(i.WeighIn is not null, Group.WeighIn);
        Add(i.Reason is not null, Group.Reason); Add(i.Reference is not null, Group.Reference); Add(i.Move is not null, Group.Move);
        Add(i.ListRef is not null, Group.ListRef); Add(i.Portion is not null, Group.Portion); Add(i.Memory is not null, Group.Memory);
        Add(i.Batch is not null, Group.Batch); Add(i.Create is not null, Group.Create); Add(i.Stated is not null, Group.Stated);
        return present;
    }

    private static InvalidOutput? Validate(ParsedIntent i, InterpretInput input)
    {
        if (!Enum.IsDefined(i.Kind) || i.Items is null || i.Items.Any(f => f is null) || i.Reference is { Refs: null } || i.Create is { Aliases: null }
            || i.Reference is { } r && !Enum.IsDefined(r.Scope) || i.Reason is { } reason && !Enum.IsDefined(reason)) { return InvalidOutput.Shape; }
        if (!Optional(i.TimeHint) || !Optional(i.SlotHint) || !Optional(i.DishGroup) || i.Items.Length > 30
            || i.Reference is { } reference && (!Short(reference.Mention) || !Optional(reference.SlotHint) || reference.Refs.Length > 30)
            || i.Move is { } move && (!Optional(move.SlotHint) || !Optional(move.TimeHint))
            || i.Create is { } create && (!Short(create.Name) || create.Aliases.Length > 5 || !create.Aliases.All(Short))
            || i.Memory is { } memory && (!Optional(memory.Subject) || !Optional(memory.Value))
            || i.Batch is { } batch && !Optional(batch.Name)) { return InvalidOutput.Bounds; }
        var (allowed, required) = Members(i.Kind); var present = Present(i);
        if ((present & ~allowed) != 0 || (required & ~present) != 0) { return InvalidOutput.MixedGroups; }
        if (!Day(i.DateHint) || !Day(i.Reference?.DateHint) || !Day(i.Move?.DateHint)) { return InvalidOutput.DayHint; }
        if (i.Items.Any(f => !Valid(f))) { return InvalidOutput.Food; }
        return i.Kind switch
        {
            ParsedKind.FoodLog or ParsedKind.Medical or ParsedKind.Clarify or ParsedKind.OutOfScope => null,
            ParsedKind.WeighIn => i.WeighIn is { Value: > 0 and <= 1000, Unit: "kg" or "lb" } ? null : InvalidOutput.Bounds,
            ParsedKind.DiaryEdit => Edit(i, input),
            ParsedKind.DiaryDelete => Refs(i.Reference!, input),
            ParsedKind.DiaryCopy => i.Move is { DateHint: null, SlotHint: null, TimeHint: null } ? InvalidOutput.MixedGroups : null,
            ParsedKind.SavedMealLog => ListRef(i.ListRef, input.Context.SavedMeals.Length)
                ?? (i.Portion is null || i.Portion is { Amount: null, Unit: null, Rest: false } p && (p.Fraction is null) != (p.People is null)
                    ? ShareRange(i.Portion) : InvalidOutput.MixedGroups),
            ParsedKind.SavedMealCreate => i.Create!.Aliases.Length > 0 || i.Create.FromActiveProposal == (i.Reference is not null)
                ? InvalidOutput.MixedGroups : i.Reference is { } source ? Refs(source, input) : null,
            ParsedKind.MemoryChange => Memory(i),
            ParsedKind.Batch => i.Batch!.Path is { } path && !Enum.IsDefined(path) ? InvalidOutput.Shape
                : !Amount(i.Batch.CookedAmount, i.Batch.CookedUnit) ? InvalidOutput.Bounds
                : i.Portion is null ? null : Portion(i.Portion),
            ParsedKind.BatchPortion => ListRef(i.ListRef, input.Context.OpenBatches.Length)
                ?? (i.Portion is { Rest: true, Amount: null, Unit: null, Fraction: null, People: null } ? null
                    : i.Portion!.Rest ? InvalidOutput.MixedGroups : Portion(i.Portion)),
            ParsedKind.BatchClose => ListRef(i.ListRef, input.Context.OpenBatches.Length),
            ParsedKind.PersonalFoodCreate => i.Create!.FromActiveProposal || i.Items.Length == 0 && i.Stated is null ? InvalidOutput.MixedGroups
                : i.Stated is null ? null : Stated(i.Stated, input.Text),
            _ => InvalidOutput.Shape,
        };
    }

    // diaryEdit patch (contract BuddyDiaryPatch): a replacement food, or a new absolute amount, and/or a move.
    private static InvalidOutput? Edit(ParsedIntent i, InterpretInput input)
    {
        if (i.Items.Length > 1 || i.Items.Length == 0 && i.Portion is null && i.Move is null || i.Items.Length == 1 && i.Portion is not null
            || i.Move is { DateHint: null, SlotHint: null, TimeHint: null }
            || i.Portion is { } p && (p.Amount is null || p.Fraction is not null || p.People is not null || p.Rest)) { return InvalidOutput.MixedGroups; }
        if (i.Portion is { } amount && !Amount(amount.Amount, amount.Unit)) { return InvalidOutput.Bounds; }
        return Refs(i.Reference!, input);
    }
    private static InvalidOutput? Refs(ParsedReference reference, InterpretInput input) =>
        reference.Refs.All(r => r >= 0 && r < input.Context.RecentEntries.Length) && reference.Refs.Distinct().Count() == reference.Refs.Length
            ? null : InvalidOutput.RefRange;
    // PA8: no match (null) or nothing to link to (empty list) is a clarify without a repair; a repair can't fix an empty list.
    private static InvalidOutput? ListRef(int? index, int count) =>
        index is null || count == 0 || index >= 0 && index < count ? null : InvalidOutput.RefRange;
    private static InvalidOutput? Portion(ParsedPortion p)
    {
        if (p.Rest || p.Amount is null && p.Unit is null && p.Fraction is null && p.People is null || p.Fraction is not null && p.People is not null)
        { return InvalidOutput.MixedGroups; }
        return Amount(p.Amount, p.Unit) ? ShareRange(p) : InvalidOutput.Bounds;
    }
    private static InvalidOutput? ShareRange(ParsedPortion? p) =>
        p is null || (p.Fraction is null or > 0 and <= 1) && (p.People is null or > 0 and <= 1000) ? null : InvalidOutput.Bounds;

    private static readonly string[] States = ["raw", "cooked", "dry", "drained", "fried"];
    private static readonly string[] Fats = ["none", "oil"];
    // D11: memoryKind/dimension/value are validated per kind; the server never applies a memory (TD-032).
    private static InvalidOutput? Memory(ParsedIntent i)
    {
        var m = i.Memory!;
        if (!Enum.IsDefined(m.Operation) || !Enum.IsDefined(m.MemoryKind) || m.Dimension is { } d && !Enum.IsDefined(d)) { return InvalidOutput.Shape; }
        if (!Amount(m.Amount, m.Unit)) { return InvalidOutput.Bounds; }
        if (i.Items.Length > 1 || m.Subject is null && i.Items.Length == 0 || m.Dimension is not null && m.MemoryKind != ParsedMemoryKind.Default)
        { return InvalidOutput.MixedGroups; }
        // Forget needs no value, but a value it does carry is still from the closed state/fat lists.
        if (m.Operation == ParsedMemoryOperation.Forget)
        {
            return m.Value is { } forgotten && (m.Dimension == ParsedMemoryDimension.State && !States.Contains(forgotten)
                || m.Dimension == ParsedMemoryDimension.Fat && !Fats.Contains(forgotten)) ? InvalidOutput.ClosedValue : null;
        }
        return m.MemoryKind switch
        {
            ParsedMemoryKind.Default => m.Dimension switch
            {
                ParsedMemoryDimension.State => m.Amount is not null ? InvalidOutput.MixedGroups : m.Value is { } state && States.Contains(state) ? null : InvalidOutput.ClosedValue,
                ParsedMemoryDimension.Fat => m.Value is not { } fat || !Fats.Contains(fat) ? InvalidOutput.ClosedValue
                    : m.Amount is not null && m.Value != "oil" ? InvalidOutput.MixedGroups : null,
                ParsedMemoryDimension.Variant => m.Value is null || m.Amount is not null ? InvalidOutput.MixedGroups : null,
                ParsedMemoryDimension.Portion => m.Value is null && m.Amount is null ? InvalidOutput.MixedGroups : null,
                _ => InvalidOutput.MixedGroups,
            },
            ParsedMemoryKind.Portion => m.Amount is null ? InvalidOutput.MixedGroups : null,
            _ => m.Value is null || m.Amount is not null ? InvalidOutput.MixedGroups : null,
        };
    }

    // D9/TD-092: stated nutrients are the user's own numbers. Each non-null value must equal a numeric token of the message.
    private static InvalidOutput? Stated(ParsedStated s, string text)
    {
        if (!Enum.IsDefined(s.Basis)) { return InvalidOutput.Shape; }
        decimal?[] nutrients = [s.Kcal, s.ProteinG, s.CarbsG, s.FatG, s.FiberG];
        if (nutrients.All(v => v is null)) { return InvalidOutput.MixedGroups; }
        if (nutrients.Any(v => v is < 0 or > 10000) || new[] { s.ServingG, s.ServingMl }.Any(v => v is <= 0 or > 100000)) { return InvalidOutput.Bounds; }
        var literals = Numbers(text);
        return nutrients.Append(s.ServingG).Append(s.ServingMl).All(v => v is null || literals.Contains(v.Value)) ? null : InvalidOutput.StatedNotLiteral;
    }
    /// <summary>
    /// The numbers a message states. Arabic-Indic digits and the Arabic decimal/thousands separators are normalized;
    /// a single comma is also a decimal comma (<c>1,5</c> = 1.5), and thousands grouping reads without commas (<c>1,200</c> = 1200 or 1.2); unit-glued tokens split (<c>40g</c> = 40).
    /// </summary>
    internal static HashSet<decimal> Numbers(string text)
    {
        var normalized = new StringBuilder(text.Length);
        foreach (var c in text)
        {
            normalized.Append(c switch
            {
                >= '٠' and <= '٩' => (char)('0' + (c - '٠')),
                >= '۰' and <= '۹' => (char)('0' + (c - '۰')),
                '٫' => '.',
                '٬' => ',',
                _ => c,
            });
        }
        var values = new HashSet<decimal>();
        foreach (Match token in NumberToken().Matches(normalized.ToString()))
        {
            var t = token.Value;
            List<string> readings = [];
            // The comma-removed reading only for real thousands grouping (1,200 or 12,345.5), so "1,2,3" never reads as 123.
            if (!t.Contains(',', StringComparison.Ordinal) || ThousandsGrouping().IsMatch(t)) { readings.Add(t.Replace(",", "", StringComparison.Ordinal)); }
            if (t.Count(c => c == ',') == 1 && !t.Contains('.', StringComparison.Ordinal)) { readings.Add(t.Replace(',', '.')); }
            foreach (var reading in readings)
            {
                if (decimal.TryParse(reading, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out var value)) { values.Add(value); }
            }
        }
        return values;
    }
    [GeneratedRegex("[0-9]+(?:[.,][0-9]+)*")] private static partial Regex NumberToken();
    [GeneratedRegex(@"^[0-9]{1,3}(?:,[0-9]{3})+(?:\.[0-9]+)?$")] private static partial Regex ThousandsGrouping();

    // D8: the closed day grammar; date: must be a valid month/day, and a valid calendar date when a year is given.
    internal static bool Day(string? hint)
    {
        if (hint is null) { return true; }
        // Regex `$` also matches before a final newline; the hint must be exactly the grammar.
        if (!DayPattern().IsMatch(hint) || hint.EndsWith('\n')) { return false; }
        if (!hint.StartsWith("date:", StringComparison.Ordinal)) { return true; }
        var parts = hint[5..].Split('-').Select(p => int.Parse(p, CultureInfo.InvariantCulture)).ToArray();
        var (year, month, day) = parts.Length == 3 ? (parts[0], parts[1], parts[2]) : (2024, parts[0], parts[1]); // a leap year admits 02-29
        return year >= 1 && day <= DateTime.DaysInMonth(year, month);
    }
    [GeneratedRegex(BuddyDayHints.Pattern)] private static partial Regex DayPattern();

    private static bool Valid(ParsedFood f) => Short(f.Mention) && Short(f.CanonicalNameEn) && Optional(f.NameAr) && Optional(f.Variant)
        && (f.State is null || Enum.IsDefined(f.State.Value))
        && (f.Amount is null ? f.Unit is null && !f.AmountExplicit : f.Amount is > 0 and <= 100000 && f.Unit is not null && Enum.IsDefined(f.Unit.Value))
        && f.Ambiguities is { Length: <= 4 } && f.Ambiguities.All(Enum.IsDefined) && f.Ambiguities.Distinct().Count() == f.Ambiguities.Length
        && (f.Share is null || f.Share is { Fraction: > 0 and <= 1, People: null } or { People: > 0 and <= 1000, Fraction: null })
        && (f.Estimate is null || ValidRange(f.Estimate));
    private static bool Amount(decimal? amount, FoodUnit? unit) =>
        amount is null ? unit is null : amount is > 0 and <= 100000 && unit is { } u && Enum.IsDefined(u);
    internal static bool ValidRange(BuddyRange range)
    {
        if (range.Low is null || range.High is null) { return false; }
        var lo = new[] { range.Low.Kcal, range.Low.ProteinG, range.Low.CarbsG, range.Low.FatG, range.Low.FiberG };
        var hi = new[] { range.High.Kcal, range.High.ProteinG, range.High.CarbsG, range.High.FatG, range.High.FiberG };
        return lo.Zip(hi).All(p => double.IsFinite(p.First) && double.IsFinite(p.Second) && p.First >= 0 && p.Second >= p.First && p.Second <= 1000) && range.High.Kcal > 0
            && new[] { range.Low, range.High }.All(n => n.ProteinG <= 100 && n.CarbsG <= 100 && n.FatG <= 100 && n.FiberG <= 100
                && n.ProteinG + n.CarbsG + n.FatG <= 105);
    }
    private static bool Short(string? s) => !string.IsNullOrWhiteSpace(s) && s.Length <= 200;
    private static bool Optional(string? s) => s is null || Short(s);
    private static string Read()
    {
        using var stream = typeof(ProductionProtocol).Assembly.GetManifestResourceStream("FitnessBuddy.Modules.Buddy.Prompts.interpret-v2.txt")!;
        using var reader = new StreamReader(stream); return reader.ReadToEnd();
    }
}
