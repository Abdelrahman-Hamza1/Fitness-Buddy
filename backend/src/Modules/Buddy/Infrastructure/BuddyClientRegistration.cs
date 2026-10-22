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
        var file = new FileInfo(options.ApiKeyFile);
        if (!file.Exists || file.LinkTarget is not null || file.Length is < 10 or > 512
            || !OperatingSystem.IsWindows() && (File.GetUnixFileMode(file.FullName) & (UnixFileMode)63) != 0)
        { throw new InvalidOperationException("Buddy API credential is missing or not private."); }
        var key = File.ReadAllText(file.FullName).Trim();
        if (key.Length is < 10 or > 512 || key.Any(char.IsWhiteSpace)) { throw new InvalidOperationException("Invalid Buddy credential file."); }
        return OpenAIClientFactory.Create(key, services.GetRequiredService<IHttpClientFactory>().CreateClient("buddy-openai"));
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
