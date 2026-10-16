using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Schema;
using System.Text.Json.Serialization;
using System.Text.Json.Serialization.Metadata;
using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

internal static class InterpretProtocol
{
    public const string PromptVersion = "interpret-v0";
    public const int MaximumTextLength = 1000;
    public static JsonSerializerOptions Json { get; } = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        AllowDuplicateProperties = false,
        UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow,
        RespectRequiredConstructorParameters = true,
        RespectNullableAnnotations = true,
        NumberHandling = JsonNumberHandling.Strict,
        TypeInfoResolver = new DefaultJsonTypeInfoResolver(),
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase, allowIntegerValues: false) },
    };

    public static string Prompt { get; } = ReadPrompt();
    public static JsonElement Schema { get; } = GenerateSchema();

    public static Interpretation? Parse(string text)
    {
        if (text.Length > 64 * 1024) return null;
        try
        {
            // The native schema is a first boundary; distrust providers/fixtures equally at our boundary.
            var value = JsonSerializer.Deserialize<Interpretation>(text, Json);
            return value is not null && Valid(value) ? value : null;
        }
        catch (JsonException) { return null; }
    }

    private static bool Valid(Interpretation value) => Enum.IsDefined(value.Language) && Enum.IsDefined(value.Script)
        && value.Intents is { Length: > 0 and <= 10 } && value.Intents.All(intent => intent is not null && Valid(intent));

    private static bool Valid(Intent intent)
    {
        if (!Enum.IsDefined(intent.Kind) || !ShortOrNull(intent.TimeHint) || !ShortOrNull(intent.SlotHint)
            || intent.Items is null || intent.Exercises is null || intent.Items.Length > 30 || intent.Exercises.Length > 20)
            return false;
        return intent.Kind switch
        {
            IntentKind.FoodLog => intent.Items.Length > 0 && intent.Items.All(item => item is not null && Valid(item))
                && intent.WeighIn is null && intent.Exercises.Length == 0 && intent.Reason is null,
            IntentKind.WeighIn => intent.Items.Length == 0 && intent.Exercises.Length == 0 && intent.Reason is null
                && intent.WeighIn is { Value: > 0 and <= 1000, Unit: "kg" or "lb" },
            IntentKind.Workout => intent.Items.Length == 0 && intent.WeighIn is null && intent.Reason is null
                && intent.Exercises.Length > 0 && intent.Exercises.All(exercise => exercise is not null && Short(exercise.Name)
                    && exercise.Sets is { Length: > 0 and <= 30 } && exercise.Sets.All(set => set is not null
                        && set.Count is > 0 and <= 100 && set.Reps is > 0 and <= 1000
                        && (set.Weight is null ? set.Unit is null : set.Weight is >= 0 and <= 2000 && set.Unit is "kg" or "lb"))),
            IntentKind.Clarify or IntentKind.OutOfScope => intent.Items.Length == 0 && intent.WeighIn is null
                && intent.Exercises.Length == 0 && intent.Reason is not null && Enum.IsDefined(intent.Reason.Value),
            _ => false,
        };
    }

    private static bool Valid(FoodItem item) => Short(item.Mention) && Short(item.CanonicalNameEn)
        && ShortOrNull(item.NameAr) && ShortOrNull(item.Variant)
        && (item.State is null || Enum.IsDefined(item.State.Value))
        && item.Ambiguities is { Length: <= 4 } && item.Ambiguities.All(Enum.IsDefined)
        && item.Ambiguities.Distinct().Count() == item.Ambiguities.Length
        && (item.Amount is null ? item.Unit is null && !item.AmountExplicit : item.Amount is > 0 and <= 100000 && item.Unit is not null && Enum.IsDefined(item.Unit.Value))
        && (item.Share is null || (item.Share.Fraction is > 0 and <= 1 && item.Share.People is null)
            || (item.Share.People is > 0 and <= 1000 && item.Share.Fraction is null));

    private static bool Short(string? value) => !string.IsNullOrWhiteSpace(value) && value.Length <= 300;
    private static bool ShortOrNull(string? value) => value is null || Short(value);

    private static JsonElement GenerateSchema()
    {
        var schema = Json.GetJsonSchemaAsNode(typeof(Interpretation), new JsonSchemaExporterOptions
        {
            TreatNullObliviousAsNonNullable = true,
            TransformSchemaNode = (_, node) =>
            {
                if (node is JsonObject obj && obj["properties"] is JsonObject properties)
                {
                    obj["additionalProperties"] = false;
                    obj["required"] = new JsonArray(properties.Select(pair => (JsonNode?)JsonValue.Create(pair.Key)).ToArray());
                }
                return node;
            },
        });
        return JsonSerializer.SerializeToElement(schema);
    }

    private static string ReadPrompt()
    {
        using var stream = typeof(InterpretProtocol).Assembly.GetManifestResourceStream(
            "FitnessBuddy.Modules.Buddy.Prompts.interpret-v0.txt")!;
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }
}
