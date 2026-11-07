using Anthropic;
using Anthropic.Core;
using Microsoft.Extensions.AI;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

/// <summary>
/// The official Claude SDK's <see cref="IChatClient"/> over the Beta Messages surface (TD-129; Beta because the optional
/// server-side fallback lives only there). No SDK retries (TD-067), our pinned HttpClient, the SDK's own telemetry off
/// (content capture stays ours: off), an explicit base URL and key so no environment variable is read.
/// </summary>
internal static class AnthropicClientFactory
{
    public static IChatClient Create(string apiKey, HttpClient httpClient, TimeSpan timeout)
    {
        var client = new AnthropicClient(new ClientOptions
        {
            ApiKey = apiKey,
            BaseUrl = "https://api.anthropic.com",
            HttpClient = httpClient,
            MaxRetries = 0,
            Timeout = timeout,
            OpenTelemetry = false,
        });
        return client.Beta.AsIChatClient(AnthropicProvider.ModelId);
    }
}
