using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Schema;
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

    // B25: the semantic rules moved to Domain (ParsedIntentRules) so the agent's action tools apply the same ones.
    private static InvalidOutput? Validate(ParsedIntent i, InterpretInput input) => ParsedIntentRules.Validate(i, input);
    internal static bool Day(string? hint) => ParsedIntentRules.Day(hint);
    internal static bool ValidRange(BuddyRange range) => ParsedIntentRules.ValidRange(range);
    internal static HashSet<decimal> Numbers(string text) => ParsedIntentRules.Numbers(text);

    private static string Read()
    {
        using var stream = typeof(ProductionProtocol).Assembly.GetManifestResourceStream("FitnessBuddy.Modules.Buddy.Prompts.interpret-v2.txt")!;
        using var reader = new StreamReader(stream); return reader.ReadToEnd();
    }
}
