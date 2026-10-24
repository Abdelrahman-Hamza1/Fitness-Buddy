using System.Text.Json;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

// Schema/type/decimal/duplicate-key checks run first in SyncPayloads. These are
// only the A09 §3.0 rules the closed exporter cannot express (B17, TD-080).
internal static class PersonalFoodPayloadValidator
{
    public static bool Matches(JsonElement payload)
    {
        if (!Text(payload.GetProperty("nameEn").GetString()!, PersonalFoodBounds.Name) ||
            !OptionalText(payload.GetProperty("nameAr"), PersonalFoodBounds.Name) ||
            !OptionalText(payload.GetProperty("brand"), PersonalFoodBounds.Brand)) { return false; }
        var code = payload.GetProperty("createdFrom").GetString()!;
        if (code.Length is < 1 or > PersonalFoodBounds.CreatedFrom || code.Any(c => c is not (>= 'a' and <= 'z' or >= 'A' and <= 'Z'))) { return false; }
        var unit = payload.GetProperty("entryServingUnit");
        var amount = payload.GetProperty("entryServingAmount");
        return (unit.ValueKind == JsonValueKind.Null) == (amount.ValueKind == JsonValueKind.Null);
    }

    public static bool MatchesNested(string field, JsonElement value) => field switch
    {
        "aliasesJson" => Strings(value, PersonalFoodBounds.Aliases, alias: true),
        "barcodesJson" => Strings(value, PersonalFoodBounds.Barcodes, alias: false),
        "per100ExtrasJson" => Extras(value),
        "servingsJson" => Servings(value),
        _ => false,
    };

    private static bool OptionalText(JsonElement value, int maximum) => value.ValueKind == JsonValueKind.Null || Text(value.GetString()!, maximum);

    private static bool Text(string value, int maximum)
    {
        if (!WellFormed(value)) { return false; }
        var text = Trim(value);
        return text.Length >= 1 && text.Length <= maximum;
    }

    private static ReadOnlySpan<char> Trim(string value)
    {
        var start = 0; var end = value.Length;
        while (start < end && IsDartWhitespace(value[start])) { start++; }
        while (end > start && IsDartWhitespace(value[end - 1])) { end--; }
        return value.AsSpan(start, end - start);
    }

    // Fixed SDK-scanned set, tested against the shared corpus for every BMP unit.
    internal static bool IsDartWhitespace(char value) => value is >= '\u0009' and <= '\u000d' or '\u0020' or '\u0085' or '\u00a0' or '\u1680'
        or >= '\u2000' and <= '\u200a' or '\u2028' or '\u2029' or '\u202f' or '\u205f' or '\u3000' or '\ufeff';

    private static bool WellFormed(string value)
    {
        for (var i = 0; i < value.Length; i++)
        {
            if (value[i] == '\0') { return false; }
            if (!char.IsSurrogate(value[i])) { continue; }
            if (!char.IsHighSurrogate(value[i]) || i + 1 == value.Length || !char.IsLowSurrogate(value[++i])) { return false; }
        }
        return true;
    }

    private static bool Strings(JsonElement value, int maximum, bool alias)
    {
        if (value.ValueKind != JsonValueKind.Array || value.GetArrayLength() > maximum) { return false; }
        var seen = new HashSet<string>(StringComparer.Ordinal);
        foreach (var item in value.EnumerateArray())
        {
            if (item.ValueKind != JsonValueKind.String) { return false; }
            var text = item.GetString()!;
            if (alias)
            {
                if (!Text(text, PersonalFoodBounds.Name) || !seen.Add(Trim(text).ToString())) { return false; }
            }
            else if (!Gtin(text) || !seen.Add(text)) { return false; }
        }
        return true;
    }

    private static bool Gtin(string value)
    {
        if (value.Length is not (8 or 12 or 13 or 14)) { return false; }
        var sum = 0; var weight = 1;
        for (var i = value.Length - 1; i >= 0; i--)
        {
            if (value[i] is < '0' or > '9') { return false; }
            sum += (value[i] - '0') * weight;
            weight = 4 - weight;
        }
        return sum % 10 == 0;
    }

    private static bool Extras(JsonElement value)
    {
        if (value.ValueKind != JsonValueKind.Object) { return false; }
        foreach (var property in value.EnumerateObject())
        {
            if (!PersonalFoodBounds.NutrientUnits.TryGetValue(property.Name, out var unit) ||
                !Number(property.Value, 0, unit == "mg" ? PersonalFoodBounds.Milligrams : PersonalFoodBounds.Grams)) { return false; }
        }
        return true;
    }

    private static bool Servings(JsonElement value)
    {
        if (value.ValueKind != JsonValueKind.Array || value.GetArrayLength() > PersonalFoodBounds.Servings) { return false; }
        var seen = new HashSet<string>(StringComparer.Ordinal);
        foreach (var item in value.EnumerateArray())
        {
            if (item.ValueKind != JsonValueKind.Object || item.EnumerateObject().Count() != 2 ||
                !item.TryGetProperty("unit", out var unit) || unit.ValueKind != JsonValueKind.String ||
                !PersonalFoodBounds.Units.Contains(unit.GetString()!) || !seen.Add(unit.GetString()!) ||
                !item.TryGetProperty("amount", out var amount) || !Number(amount, PersonalFoodBounds.MinServing, PersonalFoodBounds.MaxServing)) { return false; }
        }
        return true;
    }

    private static bool Number(JsonElement value, decimal minimum, decimal maximum) =>
        value.ValueKind == JsonValueKind.Number && value.GetDecimal() >= minimum && value.GetDecimal() <= maximum;
}
