using System.Globalization;
using System.Security.Cryptography;
using System.Text.Json;
using FitnessBuddy.Modules.UserData.Domain;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

// Closed, build-validated contract vocabulary. No schema-controlled regexes, remote refs or runtime compilation.
internal static class SyncPayloads
{
    private static readonly JsonDocument Registry = JsonDocument.Parse(typeof(SyncPayloads).Assembly.GetManifestResourceStream(
        "FitnessBuddy.Modules.UserData.Infrastructure.Schemas.entities.json")!);

    public static string? InvalidReason(SyncVersion version)
    {
        if (version.DeletedAt is { } deleted && deleted.Ticks % 10 != 0) { return "invalidPayload"; }
        if (!Registry.RootElement.GetProperty("entities").TryGetProperty(version.Entity, out var versions) ||
            !versions.TryGetProperty(version.SchemaVersion.ToString(CultureInfo.InvariantCulture), out var schema)) { return "unsupported"; }
        try
        {
            if (!Representable(version.Payload, 0) || !Matches(schema, version.Payload)) { return "invalidPayload"; }
            if (version.Entity == "mealSlot")
            {
                var start = version.Payload.GetProperty("windowStartMin"); var end = version.Payload.GetProperty("windowEndMin");
                if ((start.ValueKind == JsonValueKind.Null) != (end.ValueKind == JsonValueKind.Null) ||
                    (start.ValueKind != JsonValueKind.Null && start.GetInt32() == end.GetInt32())) { return "invalidPayload"; }
            }
            if (TargetsPayloadValidator.Covers(version.Entity) && !TargetsPayloadValidator.Matches(version)) { return "invalidPayload"; }
            if (MeasurementPayloadValidator.Covers(version.Entity) && !MeasurementPayloadValidator.Matches(version)) { return "invalidPayload"; }
            var personalFood = version.Entity == "personalFood" && version.SchemaVersion == 1;
            if (personalFood && !PersonalFoodPayloadValidator.Matches(version.Payload)) { return "invalidPayload"; }
            foreach (var property in version.Payload.EnumerateObject())
            {
                if (property.Name.EndsWith("Json", StringComparison.Ordinal) && property.Value.ValueKind == JsonValueKind.String)
                {
                    using var nested = JsonDocument.Parse(property.Value.GetString()!, new JsonDocumentOptions { MaxDepth = 24 });
                    if (!Representable(nested.RootElement, 0) || personalFood && !PersonalFoodPayloadValidator.MatchesNested(property.Name, nested.RootElement)) { return "invalidPayload"; }
                }
            }
            return null;
        }
        catch (Exception error) when (error is JsonException or InvalidOperationException or FormatException or ArgumentException or KeyNotFoundException) { return "invalidPayload"; }
    }

    private static bool Representable(JsonElement value, int depth)
    {
        if (depth > 24) { return false; }
        return value.ValueKind switch
        {
            JsonValueKind.Object => value.EnumerateObject().Count() <= 128 && value.EnumerateObject().Select(p => p.Name).Distinct(StringComparer.Ordinal).Count() == value.EnumerateObject().Count()
                && value.EnumerateObject().All(p => p.Name.Length <= 256 && !p.Name.Contains('\0', StringComparison.Ordinal) && Representable(p.Value, depth + 1)),
            JsonValueKind.Array => value.GetArrayLength() <= 500 && value.EnumerateArray().All(item => Representable(item, depth + 1)),
            JsonValueKind.String => value.GetString() is { Length: <= 32768 } text && !text.Contains('\0', StringComparison.Ordinal),
            JsonValueKind.Number => value.TryGetDecimal(out var number) && NormalizeNumber(value.GetRawText()) == NormalizeNumber(number.ToString("G29", CultureInfo.InvariantCulture)),
            JsonValueKind.Null or JsonValueKind.True or JsonValueKind.False => true,
            _ => false,
        };
    }

    private static string? NormalizeNumber(string text, bool bounded = true)
    {
        if (bounded && text.Length > 128) { return null; }
        var parts = text.ToLowerInvariant().Split('e');
        var exponent = 0;
        if (parts.Length > 1 && (!int.TryParse(parts[1], NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out exponent) || bounded && (exponent is < -1000 or > 1000))) { return null; }
        var negative = parts[0].StartsWith('-'); var significand = parts[0].TrimStart('-');
        var point = significand.IndexOf('.', StringComparison.Ordinal);
        if (point >= 0) { exponent -= significand.Length - point - 1; }
        var digits = significand.Replace(".", "", StringComparison.Ordinal).TrimStart('0');
        if (digits.Length == 0) { return "0"; }
        var trimmed = digits.TrimEnd('0');
        exponent += digits.Length - trimmed.Length;
        digits = trimmed;
        return (negative ? "-" : "") + digits + "e" + exponent.ToString(CultureInfo.InvariantCulture);
    }

    private static bool Matches(JsonElement schema, JsonElement value)
    {
        var actual = value.ValueKind switch
        {
            JsonValueKind.Object => "object",
            JsonValueKind.Array => "array",
            JsonValueKind.String => "string",
            JsonValueKind.Number => "number",
            JsonValueKind.True or JsonValueKind.False => "boolean",
            _ => "null",
        };
        var type = schema.GetProperty("type");
        bool Has(string name) => type.ValueKind == JsonValueKind.Array ? type.EnumerateArray().Any(t => t.GetString() == name) : type.GetString() == name;
        if (!(Has(actual) || actual == "number" && Has("integer") && value.GetDecimal() == decimal.Truncate(value.GetDecimal()))) { return false; }
        if (actual == "null") { return true; }
        if (schema.TryGetProperty("enum", out var allowed) && !allowed.EnumerateArray().Any(item => item.GetString() == value.GetString())) { return false; }
        if (actual == "object")
        {
            var properties = schema.GetProperty("properties");
            return value.EnumerateObject().Count() == properties.EnumerateObject().Count() && properties.EnumerateObject().All(p => value.TryGetProperty(p.Name, out var child) && Matches(p.Value, child));
        }
        if (actual == "array") { return value.GetArrayLength() <= schema.GetProperty("maxItems").GetInt32() && value.EnumerateArray().All(item => Matches(schema.GetProperty("items"), item)); }
        if (actual == "number")
        {
            var number = value.GetDecimal();
            return (!schema.TryGetProperty("minimum", out var min) || number >= min.GetDecimal()) && (!schema.TryGetProperty("maximum", out var max) || number <= max.GetDecimal());
        }
        if (actual == "string")
        {
            var text = value.GetString()!;
            if (schema.TryGetProperty("maxLength", out var max) && text.Length > max.GetInt32()) { return false; }
            if (schema.TryGetProperty("format", out var format))
            {
                return format.GetString() switch
                {
                    "uuid" => Guid.TryParseExact(text, "D", out var id) && id.ToString() == text,
                    "date" => DateOnly.TryParseExact(text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out _),
                    _ => false,
                };
            }
        }
        return true;
    }

    public static byte[] Fingerprint(SyncVersion version)
    {
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream))
        {
            writer.WriteStartArray(); writer.WriteNumberValue(version.SchemaVersion); writer.WriteStringValue(version.DeviceId);
            if (version.DeletedAt is { } at) { writer.WriteStringValue(at.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture)); } else { writer.WriteNullValue(); }
            Canonical(writer, version.Payload); writer.WriteEndArray();
        }
        return SHA256.HashData(stream.ToArray());
    }

    private static void Canonical(Utf8JsonWriter writer, JsonElement value)
    {
        switch (value.ValueKind)
        {
            case JsonValueKind.Object:
                writer.WriteStartObject();
                foreach (var p in value.EnumerateObject().OrderBy(p => p.Name, StringComparer.Ordinal)) { writer.WritePropertyName(p.Name); Canonical(writer, p.Value); }
                writer.WriteEndObject(); break;
            case JsonValueKind.Array:
                writer.WriteStartArray(); foreach (var item in value.EnumerateArray()) { Canonical(writer, item); }
                writer.WriteEndArray(); break;
            case JsonValueKind.Number: writer.WriteRawValue(NormalizeNumber(value.GetRawText(), bounded: false)!); break;
            default: value.WriteTo(writer); break;
        }
    }
}
