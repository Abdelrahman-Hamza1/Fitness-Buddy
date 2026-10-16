using System.Text.Json;

namespace FitnessBuddy.Host.Http;

/// <summary>
/// Turns validation keys (C# member paths such as <c>Items[0].Qty</c>) into the JSON names clients know
/// (<c>items[0].qty</c>), segment by segment, with the serializer's own camelCase policy. Header keys are
/// already lowercase and stay as they are.
/// </summary>
internal static class ValidationKeyCasing
{
    public static Dictionary<string, string[]> ToCamelCase(IDictionary<string, string[]> errors)
    {
        var result = new Dictionary<string, string[]>(errors.Count, StringComparer.Ordinal);
        foreach (var (key, messages) in errors)
        {
            var name = ToCamelCase(key);
            result[name] = result.TryGetValue(name, out var existing) ? [.. existing, .. messages] : messages;
        }

        return result;
    }

    public static string ToCamelCase(string key) =>
        string.Join('.', key.Split('.').Select(JsonNamingPolicy.CamelCase.ConvertName));
}
