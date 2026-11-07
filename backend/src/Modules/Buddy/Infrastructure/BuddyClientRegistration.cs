using FitnessBuddy.Modules.Buddy.Application;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

internal static class BuddyClientRegistration
{
    public static IChatClient Create(IServiceProvider services)
    {
        var options = services.GetRequiredService<IOptions<BuddyOptions>>().Value;
        if (!options.Enabled) { return new DisabledChatClient(); }
        // Only the active provider's key is read (TD-129); both files get the same private-file checks.
        var key = ReadKey(options.KeyFile);
        var http = services.GetRequiredService<IHttpClientFactory>();
        if (options.Provider == BuddyOptions.Anthropic)
        {
            // The SDK's own timeout sits behind the step timeout, so a slow step ends as Timeout, not as a transport error.
            var step = services.GetRequiredService<IOptions<BuddyAgentOptions>>().Value.StepTimeoutSeconds;
            return AnthropicClientFactory.Create(key, http.CreateClient("buddy-anthropic"), TimeSpan.FromSeconds(step + 5));
        }
        return OpenAIClientFactory.Create(key, http.CreateClient("buddy-openai"));
    }

    private static string ReadKey(string path)
    {
        var file = new FileInfo(path);
        if (!file.Exists || file.LinkTarget is not null || file.Length is < 10 or > 512
            || !OperatingSystem.IsWindows() && (File.GetUnixFileMode(file.FullName) & (UnixFileMode)63) != 0)
        { throw new InvalidOperationException("Buddy API credential is missing or not private."); }
        var key = File.ReadAllText(file.FullName).Trim();
        if (key.Length is < 10 or > 512 || key.Any(char.IsWhiteSpace)) { throw new InvalidOperationException("Invalid Buddy credential file."); }
        return key;
    }

    private sealed class DisabledChatClient : IChatClient
    {
        public void Dispose() { }
        public object? GetService(Type serviceType, object? serviceKey = null) => null;
        public Task<ChatResponse> GetResponseAsync(IEnumerable<ChatMessage> messages, ChatOptions? options = null, CancellationToken cancellationToken = default)
            => throw new InvalidOperationException("Buddy is disabled.");
        public IAsyncEnumerable<ChatResponseUpdate> GetStreamingResponseAsync(IEnumerable<ChatMessage> messages, ChatOptions? options = null, CancellationToken cancellationToken = default)
            => throw new InvalidOperationException("Buddy streaming is disabled.");
    }
}
