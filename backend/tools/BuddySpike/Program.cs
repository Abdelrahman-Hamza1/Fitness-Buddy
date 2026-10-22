using System.Net;
using System.Text;
using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Infrastructure;
using Microsoft.Extensions.Logging.Abstractions;

// A private JSONL pipe, not a public HTTP contract. No listener, database, app identity or telemetry sinks.
if (args is ["--schema-v1"])
{
    Console.WriteLine(JsonSerializer.Serialize(ProductionProtocol.Schema, new JsonSerializerOptions { WriteIndented = true }));
    return 0;
}

if (args is ["--schema"])
{
    Console.WriteLine(JsonSerializer.Serialize(InterpretProtocol.Schema, new JsonSerializerOptions { WriteIndented = true }));
    return 0;
}

if (args.Length > 1 || (args.Length == 1 && args[0] != "--live"))
{
    await Console.Error.WriteLineAsync("Usage: BuddySpike [--live | --schema | --schema-v1]");
    return 64;
}

var live = args.Length == 1;
var synthetic = new Dictionary<string, string>(StringComparer.Ordinal)
{
    ["en-eggs"] = "2 boiled eggs",
    ["ar-eggs"] = "أكلت بيضتين مسلوقتين",
    ["az-eggs"] = "akalt 2 bayd masloo2",
};
var seen = new HashSet<string>(StringComparer.Ordinal);
try
{
    var key = live ? await LoadKeyAsync() : "offline-placeholder";
    using var replay = new ReplayHandler();
    using var http = live
        ? new HttpClient(new HttpClientHandler { AllowAutoRedirect = false })
        : new HttpClient(replay);
    http.Timeout = TimeSpan.FromSeconds(25);
    using var chat = OpenAIClientFactory.Create(key, http);
    var client = new OpenAILlmClient(chat, TimeProvider.System, NullLogger<OpenAILlmClient>.Instance, TimeSpan.FromSeconds(20));
    while (await Console.In.ReadLineAsync() is { } line)
    {
        if (line.Length > 128 * 1024) return 65;
        var request = JsonSerializer.Deserialize<SpikeInput>(line, InterpretProtocol.Json);
        if (request is null || !synthetic.TryGetValue(request.Id, out var text) || text != request.Text
            || !seen.Add(request.Id) || seen.Count > 3) return 65;
        if (!live) replay.Response = request.Response.GetRawText();
        var outcome = await client.InterpretAsync(text, CancellationToken.None);
        Console.WriteLine(JsonSerializer.Serialize(new SpikeOutput(request.Id, live ? "live" : "fixture", outcome), InterpretProtocol.Json));
        if (outcome.Status != LlmStatus.Success) return 1;
    }
    return seen.Count == 0 ? 65 : 0;
}
catch (Exception)
{
    // SDK errors and file errors can contain credentials/content. The private CLI prints only a stable code.
    await Console.Error.WriteLineAsync("buddy-spike: configuration or protocol failure; no retry performed.");
    return 1;
}

static async Task<string> LoadKeyAsync()
{
    var path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".config", "fitness-buddy", "openai-api-key");
    if (!OperatingSystem.IsWindows() && (File.GetUnixFileMode(path) & (UnixFileMode.GroupRead | UnixFileMode.GroupWrite
        | UnixFileMode.GroupExecute | UnixFileMode.OtherRead | UnixFileMode.OtherWrite | UnixFileMode.OtherExecute)) != 0)
        throw new InvalidOperationException("Secret permissions invalid.");
    var key = (await File.ReadAllTextAsync(path)).Trim();
    if (key.Length < 20 || key.Any(char.IsWhiteSpace)) throw new InvalidOperationException("Secret invalid.");
    return key;
}

internal sealed record SpikeInput(string Id, string Text, JsonElement Response);
internal sealed record SpikeOutput(string Id, string Mode, LlmOutcome Outcome);

internal sealed class ReplayHandler : HttpMessageHandler
{
    public string Response { get; set; } = "{}";

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) =>
        Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(Response, Encoding.UTF8, "application/json"),
        });
}
