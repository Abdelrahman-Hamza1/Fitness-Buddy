using System.ClientModel;
using System.ClientModel.Primitives;
using Microsoft.Extensions.AI;
using OpenAI;

namespace FitnessBuddy.Modules.Buddy.Infrastructure;

internal static class OpenAIClientFactory
{
    public const string Model = "gpt-6-luna";

    // The official SDK's Responses surface is still marked experimental; pin and wire-test it (TD-035).
#pragma warning disable OPENAI001
    public static IChatClient Create(string apiKey, HttpClient httpClient)
    {
        var client = new OpenAIClient(new ApiKeyCredential(apiKey), new OpenAIClientOptions
        {
            RetryPolicy = new ClientRetryPolicy(0),
            Transport = new HttpClientPipelineTransport(httpClient),
        });
        return client.GetResponsesClient().AsIChatClient(Model);
    }
#pragma warning restore OPENAI001
}
