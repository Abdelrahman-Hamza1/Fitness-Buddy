using System.Net;
using System.Text.Json;
using FitnessBuddy.Modules.Catalog.Application;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Catalog.Infrastructure;

/// <summary>Open Food Facts v2 product read (B10a D6): our User-Agent, no identity, no cookies, no redirects, a short
/// timeout and a 1 MB body cap. Logs carry only an outcome code, never the barcode (D7).</summary>
internal sealed partial class OpenFoodFactsClient(IHttpClientFactory factory, IOptions<OffOptions> options, TimeProvider clock, ILogger<OpenFoodFactsClient> logger) : IOffClient
{
    public const string HttpClientName = "catalog-off";
    private const int MaxBytes = 1 << 20;

    public async Task<OffFetch> FetchAsync(string code, CancellationToken cancellationToken)
    {
        var settings = options.Value;
        if (!settings.Enabled) { return new(OffFetchStatus.Unavailable); }
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(TimeSpan.FromSeconds(settings.TimeoutSeconds));
        try
        {
            var http = factory.CreateClient(HttpClientName);
            using var request = new HttpRequestMessage(HttpMethod.Get, new Uri(settings.BaseUrl, "api/v2/product/" + code + "?fields=" + OffMapper.Fields));
            request.Headers.TryAddWithoutValidation("User-Agent", settings.UserAgent);
            request.Headers.Accept.ParseAdd("application/json");
            using var response = await http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, timeout.Token);
            if (response.StatusCode is HttpStatusCode.TooManyRequests or HttpStatusCode.ServiceUnavailable)
            {
                LogStatus(logger, (int)response.StatusCode);
                return new(OffFetchStatus.Unavailable, RetryAfter: RetryAfter(response.Headers.RetryAfter, clock.GetUtcNow()));
            }
            if (response.StatusCode != HttpStatusCode.OK && response.StatusCode != HttpStatusCode.NotFound)
            {
                LogStatus(logger, (int)response.StatusCode);
                return new(OffFetchStatus.Unavailable);
            }
            if (response.Content.Headers.ContentLength > MaxBytes) { Log(logger, "too-large"); return new(OffFetchStatus.Unavailable); }
            await using var stream = await response.Content.ReadAsStreamAsync(timeout.Token);
            using var buffer = new MemoryStream();
            var chunk = new byte[16 * 1024];
            int read;
            while ((read = await stream.ReadAsync(chunk, timeout.Token)) > 0)
            {
                if (buffer.Length + read > MaxBytes) { Log(logger, "too-large"); return new(OffFetchStatus.Unavailable); }
                buffer.Write(chunk, 0, read);
            }
            using var document = JsonDocument.Parse(buffer.ToArray());
            var root = document.RootElement;
            var found = root.ValueKind == JsonValueKind.Object && root.TryGetProperty("status", out var status)
                && status.ValueKind == JsonValueKind.Number && status.GetInt32() == 1
                && root.TryGetProperty("product", out var product) && product.ValueKind == JsonValueKind.Object;
            if (!found)
            {
                Log(logger, "not-found");
                return new(OffFetchStatus.NotFound);
            }
            Log(logger, "found");
            return new(OffFetchStatus.Found, OffMapper.Map(root.GetProperty("product"), code));
        }
        catch (Exception error) when (error is HttpRequestException or JsonException or InvalidOperationException or FormatException
            || error is OperationCanceledException && !cancellationToken.IsCancellationRequested)
        {
            Log(logger, error is OperationCanceledException ? "timeout" : "failed");
            return new(OffFetchStatus.Unavailable);
        }
    }

    /// <summary>Retry-After as seconds or an HTTP date (against the injected clock), bounded to 1 s – 1 h; 60 s when absent.</summary>
    internal static TimeSpan RetryAfter(System.Net.Http.Headers.RetryConditionHeaderValue? header, DateTimeOffset now)
    {
        var wait = header?.Delta ?? (header?.Date is { } date ? date - now : TimeSpan.FromSeconds(60));
        return wait < TimeSpan.FromSeconds(1) ? TimeSpan.FromSeconds(1) : wait > TimeSpan.FromHours(1) ? TimeSpan.FromHours(1) : wait;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Open Food Facts read answered {Status}")]
    private static partial void LogStatus(ILogger logger, int status);

    [LoggerMessage(Level = LogLevel.Information, Message = "Open Food Facts read ended with {Outcome}")]
    private static partial void Log(ILogger logger, string outcome);
}
