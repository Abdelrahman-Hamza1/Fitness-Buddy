using System.Text.Json;
using System.Text.RegularExpressions;
using FitnessBuddy.BuildingBlocks.Web.Problems;
using FitnessBuddy.Host.Tests.Infrastructure;

namespace FitnessBuddy.Host.Tests.Problems;

// Rule 04 §4.2 "Errors": the server's problem bodies are the golden bodies in contracts/testdata/problems/, which
// the app's Failure mapping tests read too. Pass rule: contracts/testdata/README.md "problems/".
public sealed partial class GoldenProblemTests
{
    private static readonly string ContractsDirectory = FindContractsDirectory();

    public static TheoryData<string> Files => [.. ProblemTypes.All.Select(type => type["/errors/".Length..])];

    [Theory]
    [MemberData(nameof(Files))]
    [Trait("Rule", "04.4.2-errors")]
    public async Task Server_problem_bodies_match_contracts_testdata_problems(string slug)
    {
        using var golden = JsonDocument.Parse(await File.ReadAllTextAsync(Path.Combine(ContractsDirectory, "testdata", "problems", $"{slug}.json"), Api.Ct));
        var expected = golden.RootElement;

        var actual = await ServerProblemAsync(slug, expected.GetProperty("status").GetInt32());

        Assert.Equal(Api.MemberNames(expected), Api.MemberNames(actual));
        foreach (var member in new[] { "type", "title", "detail" })
        {
            Assert.Equal(Text(expected, member), Text(actual, member));
        }

        Assert.Equal(expected.GetProperty("status").GetInt32(), actual.GetProperty("status").GetInt32());
        Assert.Matches(Api.TraceIdRegex(), actual.GetProperty("traceId").GetString());
        if (expected.TryGetProperty("errors", out _))
        {
            Assert.Equal(Api.ErrorKeys(expected), Api.ErrorKeys(actual));
        }
    }

    [Fact]
    [Trait("Rule", "04.4.2-errors")]
    public void Every_catalogue_type_has_a_golden_file_and_a_ProblemTypes_constant()
    {
        var readme = File.ReadAllText(Path.Combine(ContractsDirectory, "README.md"));
        var catalogue = CatalogueRow().Matches(readme).Select(m => m.Groups[1].Value).Order(StringComparer.Ordinal).ToList();
        var files = Directory.GetFiles(Path.Combine(ContractsDirectory, "testdata", "problems"), "*.json")
            .Select(path => $"/errors/{Path.GetFileNameWithoutExtension(path)}")
            .Order(StringComparer.Ordinal)
            .ToList();

        Assert.NotEmpty(catalogue);
        Assert.Equal(catalogue, files);
        Assert.Equal(catalogue, ProblemTypes.All.Order(StringComparer.Ordinal));
    }

    private static async Task<JsonElement> ServerProblemAsync(string slug, int status)
    {
        await using var factory = ApiFactory.With(new Dictionary<string, string?> { ["RateLimiting:PerIp:PermitLimit"] = "1" });
        using var client = factory.CreateClient();
        HttpRequestMessage Request() => slug switch
        {
            "unauthorized" => Api.Get("/v1/_probe/identity-required"),
            "forbidden" => Api.Get("/v1/_probe/identity-forbidden"),
            "identity-conflict" => Api.Get("/v1/_probe/identity-conflict"),
            "validation-failed" => Api.Request(HttpMethod.Post, "/v1/_probe/validate", """{"name":"","items":[{"qty":0}],"child":{"code":"ab"}}"""),
            "upgrade-required" => Api.Get("/v1/_probe/ok", appVersion: "0.0.9"),
            "rate-limited" => Api.Get("/v1/_probe/ok"),
            "version-conflict" => Api.Get("/v1/_probe/conflict"),
            _ => throw new ArgumentOutOfRangeException(nameof(slug), slug, "No server request for this golden file."),
        };

        if (slug == "rate-limited")
        {
            using var first = await client.FetchAsync(Request());
        }

        using var response = await client.FetchAsync(Request());
        return await Api.ProblemAsync(response, status);
    }

    private static string? Text(JsonElement element, string member) =>
        element.TryGetProperty(member, out var value) ? value.GetString() : null;

    private static string FindContractsDirectory()
    {
        for (var directory = new DirectoryInfo(AppContext.BaseDirectory); directory is not null; directory = directory.Parent)
        {
            var candidate = Path.Combine(directory.FullName, "contracts", "testdata", "problems");
            if (Directory.Exists(candidate))
            {
                return Path.Combine(directory.FullName, "contracts");
            }
        }

        throw new DirectoryNotFoundException("contracts/testdata/problems not found above the test output directory.");
    }

    // A catalogue table row: | `/errors/<slug>` | <status> | ...
    [GeneratedRegex(@"^\| `(/errors/[a-z0-9-]+)` \|", RegexOptions.Multiline)]
    private static partial Regex CatalogueRow();
}
