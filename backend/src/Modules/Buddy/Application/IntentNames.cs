namespace FitnessBuddy.Modules.Buddy.Application;

internal static class IntentNames
{
    /// <summary>The contract's camelCase name of an internal enum value.</summary>
    public static string Name<T>(T value) where T : Enum => System.Text.Json.JsonNamingPolicy.CamelCase.ConvertName(value.ToString());
}
