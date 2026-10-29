using System.Collections;
using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using FitnessBuddy.BuildingBlocks.Web.Http;
using FitnessBuddy.Modules.Buddy.Api;

namespace FitnessBuddy.Buddy.Tests;

// A22 D18 / TD-093: the app's real InterpretRequestBuilder writes
// contracts/testdata/buddy/interpret-requests.json (default UUIDv5 slots, Arabic, Arabizi,
// a personal food at every bound, maximum list sizes). Every vector must bind and validate
// on the server, so a phone-built request never meets a 400.
public sealed class InterpretRequestVectorTests
{
    // The API role's HTTP JSON rules (ApiJson, also used by ApiRole.cs).
    private static readonly JsonSerializerOptions HostJson = ApiJson.Create();

    public static TheoryData<string> Cases()
    {
        var data = new TheoryData<string>();
        foreach (var c in Corpus().RootElement.GetProperty("cases").EnumerateArray()) { data.Add(c.GetProperty("id").GetString()!); }
        return data;
    }

    [Theory]
    [MemberData(nameof(Cases))]
    [Trait("Req", "AC-041")]
    [Trait("Rule", "A22 request-vectors")]
    public void Every_app_interpret_request_vector_binds_and_validates(string id)
    {
        using var corpus = Corpus();
        var raw = corpus.RootElement.GetProperty("cases").EnumerateArray().Single(c => c.GetProperty("id").GetString() == id).GetProperty("request").GetRawText();
        var request = JsonSerializer.Deserialize<InterpretRequest>(raw, HostJson);
        Assert.NotNull(request);
        var errors = Validate(request).Select(e => string.Join(",", e.MemberNames) + ": " + e.ErrorMessage).ToList();
        Assert.Empty(errors);
        Assert.True(request.ToInput().Slots.Length > 0);
    }

    [Fact]
    [Trait("Rule", "A22 request-vectors")]
    public void The_request_corpus_covers_the_planned_cases()
    {
        using var corpus = Corpus();
        Assert.Equal(1, corpus.RootElement.GetProperty("version").GetInt32());
        var ids = corpus.RootElement.GetProperty("cases").EnumerateArray().Select(c => c.GetProperty("id").GetString()).ToArray();
        Assert.Superset(new HashSet<string?> { "default-slots", "arabic-message", "arabizi-message", "personal-food-at-bounds", "maximum-list-sizes" }, ids.ToHashSet());
    }

    private static JsonDocument Corpus() => JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "interpret-requests.json")));

    // Data annotations and IValidatableObject on the request and every nested request record,
    // as the endpoint's validation does.
    private static List<ValidationResult> Validate(object root)
    {
        var results = new List<ValidationResult>();
        var pending = new Stack<object>([root]);
        while (pending.TryPop(out var value))
        {
            Validator.TryValidateObject(value, new ValidationContext(value), results, validateAllProperties: true);
            foreach (var property in value.GetType().GetProperties())
            {
                if (property.GetIndexParameters().Length > 0) { continue; }
                var child = property.GetValue(value);
                if (child is string || child is null) { continue; }
                if (child is IEnumerable items) { foreach (var item in items) { if (Nested(item)) { pending.Push(item!); } } }
                else if (Nested(child)) { pending.Push(child); }
            }
        }
        return results;
    }

    private static bool Nested(object? value) => value?.GetType().Namespace == typeof(InterpretRequest).Namespace;
}
