using System.Text.Json;
using System.Text.Json.Serialization;

namespace FitnessBuddy.BuildingBlocks.Web.Http;

/// <summary>
/// The API's HTTP JSON rules, applied by the API role (<c>ConfigureHttpJsonOptions</c>) and used by tests
/// that bind request bodies the same way (A22 request vectors), so the two can't drift.
/// </summary>
public static class ApiJson
{
    /// <summary>Applies the rules to <paramref name="options"/>.</summary>
    public static JsonSerializerOptions Configure(JsonSerializerOptions options)
    {
        ArgumentNullException.ThrowIfNull(options);
        // Numbers are numbers: the web default (AllowReadingFromString) would document every
        // number as `number | string` and accept "12" on input (S02 research gotcha 4).
        options.NumberHandling = JsonNumberHandling.Strict;
        options.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.CamelCase));
        // A missing member or a null for a non-nullable one is an unreadable body (TD-043, S03 plan D1).
        options.RespectRequiredConstructorParameters = true;
        options.RespectNullableAnnotations = true;
        return options;
    }

    /// <summary>New web-default options with the API's rules.</summary>
    public static JsonSerializerOptions Create() => Configure(new JsonSerializerOptions(JsonSerializerDefaults.Web));
}
