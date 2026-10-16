using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace FitnessBuddy.Buddy.Tests;

// The real private CLI in offline mode. No test is allowed to pass --live.
[Trait("Rule", "B02.D4-paid-call-boundary")]
public sealed class CliBoundaryTests
{
    [Theory]
    [InlineData("unknown", 0)]
    [InlineData("changed", 0)]
    [InlineData("duplicate", 1)]
    public async Task Unknown_changed_or_duplicate_prompts_stop_before_another_call(string variant, int delivered)
    {
        var response = JsonNode.Parse(await OpenAIContractTests.FixtureAsync("en-eggs"));
        var input = JsonSerializer.Serialize(new { id = variant == "unknown" ? "other" : "en-eggs", text = variant == "changed" ? "other text" : "2 boiled eggs", response });
        var lines = variant == "duplicate" ? input + "\n" + input : input;
        var (exitCode, output, error) = await RunAsync(lines);
        Assert.Equal(65, exitCode);
        Assert.Equal(delivered, output.Split('\n', StringSplitOptions.RemoveEmptyEntries).Length);
        Assert.Empty(error);
    }

    [Fact]
    public async Task Three_known_prompts_replay_without_reading_a_key()
    {
        var lines = new List<string>();
        foreach (var (id, text) in new[] { ("en-eggs", "2 boiled eggs"), ("ar-eggs", "أكلت بيضتين مسلوقتين"), ("az-eggs", "akalt 2 bayd masloo2") })
            lines.Add(JsonSerializer.Serialize(new { id, text, response = JsonNode.Parse(await OpenAIContractTests.FixtureAsync(id)) }));
        var (exitCode, output, error) = await RunAsync(string.Join('\n', lines));
        Assert.Equal(0, exitCode);
        Assert.Equal(3, output.Split('\n', StringSplitOptions.RemoveEmptyEntries).Length);
        Assert.DoesNotContain("unavailable", output, StringComparison.Ordinal);
        Assert.Empty(error);
    }

    private static async Task<(int ExitCode, string Output, string Error)> RunAsync(string input)
    {
        var root = new DirectoryInfo(AppContext.BaseDirectory);
        while (root is not null && !File.Exists(Path.Combine(root.FullName, "AGENTS.md"))) root = root.Parent;
        Assert.NotNull(root);
        var dotnet = Path.GetFullPath("../../../" + (OperatingSystem.IsWindows() ? "dotnet.exe" : "dotnet"), RuntimeEnvironment.GetRuntimeDirectory());
        using var process = new Process
        {
            StartInfo = new ProcessStartInfo(dotnet)
            {
                RedirectStandardInput = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                ArgumentList = { Path.Combine(root.FullName, "backend/tools/BuddySpike/bin/Release/net10.0/FitnessBuddy.BuddySpike.dll") },
            },
        };
        process.Start();
        var ct = TestContext.Current.CancellationToken;
        var output = process.StandardOutput.ReadToEndAsync(ct);
        var error = process.StandardError.ReadToEndAsync(ct);
        await process.StandardInput.WriteLineAsync(input.AsMemory(), ct);
        process.StandardInput.Close();
        await process.WaitForExitAsync(ct);
        return (process.ExitCode, await output, await error);
    }
}
