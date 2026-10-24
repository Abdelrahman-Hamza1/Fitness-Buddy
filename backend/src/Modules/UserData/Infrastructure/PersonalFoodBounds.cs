using System.Collections.Frozen;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

// A09 §3.0; pinned to the Dart-generated corpus in UserData.Tests (B17).
internal static class PersonalFoodBounds
{
    public const int Name = 80;
    public const int Brand = 60;
    public const int Aliases = 30;
    public const int Barcodes = 10;
    public const int Servings = 10;
    public const decimal Kcal = 920m;
    public const decimal Grams = 1000m;
    public const decimal Milligrams = 100000m;
    public const decimal MinServing = 0.1m;
    public const decimal MaxServing = 5000m;
    public const int CreatedFrom = 32;
    public const int JsonLength = 16384;

    public static readonly FrozenSet<string> Units = new[]
    {
        "piece", "loaf", "plate", "glass", "sandwich", "disc", "serving", "can", "cup", "tbsp", "tsp",
    }.ToFrozenSet(StringComparer.Ordinal);

    public static readonly FrozenSet<string> States = new[]
    {
        "raw", "cooked", "dry", "drained", "fried", "as_sold",
    }.ToFrozenSet(StringComparer.Ordinal);

    public static readonly FrozenSet<string> Bases = new[] { "g", "ml" }.ToFrozenSet(StringComparer.Ordinal);

    public static readonly FrozenDictionary<string, string> NutrientUnits = new Dictionary<string, string>(StringComparer.Ordinal)
    {
        ["sugar"] = "g",
        ["saturated_fat"] = "g",
        ["trans_fat"] = "g",
        ["sodium"] = "mg",
        ["cholesterol"] = "mg",
        ["alcohol"] = "g",
    }.ToFrozenDictionary(StringComparer.Ordinal);
}
