using System.Globalization;
using System.Text.Json;
using FitnessBuddy.Modules.Catalog.Application;

namespace FitnessBuddy.Modules.Catalog.Infrastructure;

/// <summary>Maps one OFF v2 <c>product</c> object to the bounded fields we cache. Code computes (kcal from kJ,
/// B22 repairs), text is trimmed and capped. Numbers may arrive as JSON strings.</summary>
internal static class OffMapper
{
    public const string Fields = "code,product_name,product_name_en,product_name_ar,brands,nutriments,serving_size,serving_quantity,"
        + "serving_quantity_unit,product_quantity_unit,ingredients_text,ingredients_text_en,ingredients_text_ar,labels_tags,ingredients_analysis_tags";

    public static OffProduct Map(JsonElement product, string code)
    {
        var nutriments = product.TryGetProperty("nutriments", out var n) && n.ValueKind == JsonValueKind.Object ? n : default;
        double? Value(string key) => Number(nutriments, key) is { } v && double.IsFinite(v) ? v : null;
        var ml = IsMl(Text(product, "product_quantity_unit", 16)) || IsMl(Text(product, "serving_quantity_unit", 16));
        var servingUnit = Text(product, "serving_quantity_unit", 16);
        double? serving = Number(product, "serving_quantity") is { } quantity && quantity is >= 0.1 and <= 5000
            && (servingUnit is null || string.Equals(servingUnit, ml ? "ml" : "g", StringComparison.OrdinalIgnoreCase)) ? Math.Round(quantity, 3) : null;
        // B22: repairs (kJ as kcal, per serving as per 100) happen here; rejecting impossible values is OffSanity.Check's job,
        // so the numbers are kept as published instead of being nulled out.
        var (per100, corrections) = OffSanity.Normalize(new OffRaw(
            Value("energy-kcal_100g"), Value("energy-kj_100g") ?? Value("energy_100g"),
            Value("proteins_100g"), Value("carbohydrates_100g"), Value("fat_100g"), Value("fiber_100g"), Value("alcohol_100g"),
            serving, Value("energy-kcal_serving"), Value("energy-kj_serving") ?? Value("energy_serving"),
            Value("proteins_serving"), Value("carbohydrates_serving"), Value("fat_serving"), Value("fiber_serving")));
        var labels = Tags(product, "labels_tags").Concat(Tags(product, "ingredients_analysis_tags")).Distinct(StringComparer.Ordinal).Take(64).ToArray();
        return new OffProduct(code,
            Text(product, "product_name_en", 200) ?? Text(product, "product_name", 200),
            Text(product, "product_name_ar", 200),
            Text(product, "brands", 200)?.Split(',')[0].Trim() is { Length: > 0 } brand ? Cap(brand, 60) : null,
            ml ? "ml" : "g",
            per100,
            serving,
            Text(product, "serving_size", 100),
            Text(product, "ingredients_text", 5000) ?? Text(product, "ingredients_text_en", 5000) ?? Text(product, "ingredients_text_ar", 5000),
            labels, corrections);
    }

    private static bool IsMl(string? unit) => string.Equals(unit, "ml", StringComparison.OrdinalIgnoreCase);

    private static double? Number(JsonElement parent, string name)
    {
        if (parent.ValueKind != JsonValueKind.Object || !parent.TryGetProperty(name, out var value)) { return null; }
        return value.ValueKind switch
        {
            JsonValueKind.Number when value.TryGetDouble(out var d) => d,
            JsonValueKind.String when double.TryParse(value.GetString(), NumberStyles.Float, CultureInfo.InvariantCulture, out var d) => d,
            _ => null,
        };
    }

    private static string? Text(JsonElement parent, string name, int max)
    {
        if (!parent.TryGetProperty(name, out var value) || value.ValueKind != JsonValueKind.String) { return null; }
        var text = new string(value.GetString()!.Where(c => !char.IsControl(c) || c is '\n' or '\t').ToArray()).Trim();
        return text.Length == 0 ? null : Cap(text, max);
    }

    private static string Cap(string text, int max)
    {
        if (text.Length <= max) { return text; }
        var end = char.IsHighSurrogate(text[max - 1]) ? max - 1 : max;
        return text[..end].TrimEnd();
    }

    private static IEnumerable<string> Tags(JsonElement parent, string name)
    {
        if (!parent.TryGetProperty(name, out var value) || value.ValueKind != JsonValueKind.Array) { yield break; }
        foreach (var item in value.EnumerateArray())
        {
            if (item.ValueKind == JsonValueKind.String && item.GetString() is { Length: > 0 and <= 100 } tag && !tag.Any(char.IsControl)) { yield return tag; }
        }
    }
}
