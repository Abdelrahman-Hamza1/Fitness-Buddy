using System.Text.Json;
using System.Text.RegularExpressions;

namespace FitnessBuddy.Modules.Catalog.Infrastructure;

// Only this closed embedded draft-07 vocabulary is supported; no runtime/remote refs or dependencies.
internal static class ReleaseSchemas
{
    private static readonly Dictionary<string, JsonElement> Schemas = Load();
    private static Dictionary<string, JsonElement> Load()
    {
        var assembly = typeof(ReleaseSchemas).Assembly;
        using var document = JsonDocument.Parse(assembly.GetManifestResourceStream("FitnessBuddy.Modules.Catalog.Infrastructure.Schemas.release.json")!);
        foreach (var schema in document.RootElement.EnumerateObject()) { CheckVocabulary(schema.Value); }
        return document.RootElement.EnumerateObject().ToDictionary(p => p.Name, p => p.Value.Clone(), StringComparer.Ordinal);
    }
    private static void CheckVocabulary(JsonElement schema)
    {
        foreach (var keyword in schema.EnumerateObject())
        {
            if (keyword.Name is not ("$schema" or "$id" or "title" or "description" or "type" or "properties" or "required" or "additionalProperties"
                or "anyOf" or "oneOf" or "const" or "enum" or "minimum" or "maximum" or "exclusiveMinimum" or "minLength" or "maxLength" or "pattern" or "propertyNames" or "items"))
            { throw new InvalidOperationException("Unsupported catalog schema keyword."); }
            if (keyword.Name == "properties") { foreach (var child in keyword.Value.EnumerateObject()) { CheckVocabulary(child.Value); } }
            if (keyword.Name is "additionalProperties" or "propertyNames" or "items" && keyword.Value.ValueKind == JsonValueKind.Object) { CheckVocabulary(keyword.Value); }
            if (keyword.Name is "anyOf" or "oneOf") { foreach (var child in keyword.Value.EnumerateArray()) { CheckVocabulary(child); } }
        }
    }
    public static void Validate(string name, JsonElement value)
    {
        if (!Safe(value, 0) || !Matches(Schemas[name], value)) { throw new InvalidDataException("Invalid catalog release record."); }
    }
    private static bool Safe(JsonElement v, int depth) => depth <= 24 && v.ValueKind switch
    {
        JsonValueKind.Object => v.EnumerateObject().Count() <= 128 && v.EnumerateObject().Select(p => p.Name).Distinct(StringComparer.Ordinal).Count() == v.EnumerateObject().Count()
            && v.EnumerateObject().All(p => !p.Name.Contains('\0', StringComparison.Ordinal) && Safe(p.Value, depth + 1)),
        JsonValueKind.Array => v.GetArrayLength() <= 10000 && v.EnumerateArray().All(c => Safe(c, depth + 1)),
        JsonValueKind.String => v.GetString() is { Length: <= 32768 } text && !text.Contains('\0', StringComparison.Ordinal),
        JsonValueKind.Number => v.TryGetDecimal(out _),
        JsonValueKind.True or JsonValueKind.False or JsonValueKind.Null => true,
        _ => false,
    };
    private static bool Equal(JsonElement a, JsonElement b) => JsonElement.DeepEquals(a, b);
    private static bool Matches(JsonElement s, JsonElement v)
    {
        if (s.TryGetProperty("anyOf", out var any) && !any.EnumerateArray().Any(c => Matches(c, v))) { return false; }
        if (s.TryGetProperty("oneOf", out var one) && one.EnumerateArray().Count(c => Matches(c, v)) != 1) { return false; }
        if (s.TryGetProperty("const", out var constant) && !Equal(constant, v)) { return false; }
        if (s.TryGetProperty("enum", out var allowed) && !allowed.EnumerateArray().Any(c => Equal(c, v))) { return false; }
        if (s.TryGetProperty("type", out var type))
        {
            var actual = v.ValueKind switch
            {
                JsonValueKind.Object => "object",
                JsonValueKind.Array => "array",
                JsonValueKind.String => "string",
                JsonValueKind.Number => "number",
                JsonValueKind.True or JsonValueKind.False => "boolean",
                _ => "null"
            };
            if (type.GetString() != actual && !(type.GetString() == "integer" && actual == "number" && v.GetDecimal() == decimal.Truncate(v.GetDecimal()))) { return false; }
        }
        if (v.ValueKind == JsonValueKind.Object)
        {
            if (s.TryGetProperty("required", out var required) && required.EnumerateArray().Any(n => !v.TryGetProperty(n.GetString()!, out _))) { return false; }
            var hasProperties = s.TryGetProperty("properties", out var properties);
            foreach (var p in v.EnumerateObject())
            {
                if (s.TryGetProperty("propertyNames", out var names) && !Matches(names, JsonSerializer.SerializeToElement(p.Name))) { return false; }
                if (hasProperties && properties.TryGetProperty(p.Name, out var child)) { if (!Matches(child, p.Value)) { return false; } }
                else if (s.TryGetProperty("additionalProperties", out var extra) && (extra.ValueKind == JsonValueKind.False || extra.ValueKind == JsonValueKind.Object && !Matches(extra, p.Value))) { return false; }
            }
        }
        if (v.ValueKind == JsonValueKind.Array && s.TryGetProperty("items", out var items) && v.EnumerateArray().Any(c => !Matches(items, c))) { return false; }
        if (v.ValueKind == JsonValueKind.Number)
        {
            var number = v.GetDecimal();
            if (s.TryGetProperty("minimum", out var min) && number < min.GetDecimal() || s.TryGetProperty("maximum", out var max) && number > max.GetDecimal()
                || s.TryGetProperty("exclusiveMinimum", out var exclusive) && number <= exclusive.GetDecimal()) { return false; }
        }
        if (v.ValueKind == JsonValueKind.String)
        {
            var text = v.GetString()!;
            if (s.TryGetProperty("minLength", out var min) && text.Length < min.GetInt32() || s.TryGetProperty("maxLength", out var max) && text.Length > max.GetInt32()
                || s.TryGetProperty("pattern", out var pattern) && !Regex.IsMatch(text, pattern.GetString()!, RegexOptions.CultureInvariant, TimeSpan.FromMilliseconds(100))) { return false; }
        }
        return true;
    }
}
