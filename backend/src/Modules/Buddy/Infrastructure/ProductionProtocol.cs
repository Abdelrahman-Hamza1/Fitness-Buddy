using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Schema;
using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

internal static class ProductionProtocol
{
    public const string Version = "interpret-v1";
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
    // An allowlisted projection, never serialize the HTTP request or a principal into the provider message.
    public static string Input(InterpretInput input) => JsonSerializer.Serialize(new
    {
        input.Text,
        input.Now,
        input.TzOffsetMin,
        input.Ramadan,
        slots = input.Slots.Select(s => new { s.Name, s.Window }),
        personalFoods = input.Context.PersonalFoods.Select(f => new { f.Names, f.Aliases, f.State }),
        memory = input.Context.Memory,
        recentEntries = input.Context.RecentEntries.Select(r => new { r.Date, r.Slot, r.Name }),
        savedMeals = input.Context.SavedMeals.Select(r => r.Name),
        openBatches = input.Context.OpenBatches.Select(r => r.Name),
        customExercises = input.Context.CustomExercises.Select(r => r.Name),
    }, InterpretProtocol.Json);

    public static ParsedMessage? Parse(string text)
    {
        if (text.Length > 64 * 1024) { return null; }
        try
        {
            var parsed = JsonSerializer.Deserialize<ParsedMessage>(text, InterpretProtocol.Json);
            return parsed is not null && Enum.IsDefined(parsed.Language) && Enum.IsDefined(parsed.Script)
                && parsed.Intents is { Length: > 0 and <= 10 } && parsed.Intents.All(i => i is not null && Valid(i)) ? parsed : null;
        }
        catch (JsonException) { return null; }
    }
    private static bool Valid(ParsedIntent i)
    {
        if (!Enum.IsDefined(i.Kind) || !Optional(i.TimeHint) || !Optional(i.SlotHint) || !Optional(i.DishGroup) || i.Items is null || i.Items.Length > 30) { return false; }
        return i.Kind switch
        {
            ParsedKind.FoodLog => i.Items.Length > 0 && i.Items.All(f => f is not null && Valid(f)) && i.WeighIn is null && i.Reason is null,
            ParsedKind.WeighIn => i.Items.Length == 0 && i.WeighIn is { Value: > 0 and <= 1000, Unit: "kg" or "lb" } && i.Reason is null,
            ParsedKind.Medical => i.Items.Length == 0 && i.WeighIn is null && i.Reason is null,
            ParsedKind.Clarify or ParsedKind.OutOfScope => i.Items.Length == 0 && i.WeighIn is null && i.Reason is not null && Enum.IsDefined(i.Reason.Value),
            _ => false,
        };
    }
    private static bool Valid(ParsedFood f) => Short(f.Mention) && Short(f.CanonicalNameEn) && Optional(f.NameAr) && Optional(f.Variant)
        && (f.State is null || Enum.IsDefined(f.State.Value))
        && (f.Amount is null ? f.Unit is null && !f.AmountExplicit : f.Amount is > 0 and <= 100000 && f.Unit is not null && Enum.IsDefined(f.Unit.Value))
        && f.Ambiguities is { Length: <= 4 } && f.Ambiguities.All(Enum.IsDefined) && f.Ambiguities.Distinct().Count() == f.Ambiguities.Length
        && (f.Share is null || f.Share is { Fraction: > 0 and <= 1, People: null } or { People: > 0 and <= 1000, Fraction: null })
        && (f.Estimate is null || ValidRange(f.Estimate));
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
        using var stream = typeof(ProductionProtocol).Assembly.GetManifestResourceStream("FitnessBuddy.Modules.Buddy.Prompts.interpret-v1.txt")!;
        using var reader = new StreamReader(stream); return reader.ReadToEnd();
    }
}
