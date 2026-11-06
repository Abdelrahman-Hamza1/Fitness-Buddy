using System.Text.Json;
using FitnessBuddy.Modules.Admin.Application;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Admin.Infrastructure;

/// <summary>Probes the API's <c>/health/ready</c> with a short timeout; any failure is "not ready". The body is never read.</summary>
internal sealed class HttpApiHealth(IHttpClientFactory clients, IOptions<AdminOptions> options) : IApiHealth
{
    public const string ClientName = "admin-api-ready";

    public async Task<bool?> ReadyAsync(CancellationToken cancellationToken)
    {
        var url = options.Value.ApiReadyUrl;
        if (url.Length == 0) { return null; }
        try
        {
            using var response = await clients.CreateClient(ClientName).GetAsync(new Uri(new Uri(url), "/health/ready"), HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch (Exception exception) when (exception is HttpRequestException or TaskCanceledException && !cancellationToken.IsCancellationRequested)
        {
            return false;
        }
    }
}

/// <summary>Reads the controller's <c>{completedAt, ok}</c> file (at most 4 KB); a missing or bad file reads as "unknown".</summary>
internal sealed class FileBackupStatus(IOptions<AdminOptions> options) : IBackupStatus
{
    private sealed record Status(DateTimeOffset? CompletedAt, bool Ok);

    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    public BackupState? Read()
    {
        var path = options.Value.BackupStatusFile;
        if (path.Length == 0) { return null; }
        try
        {
            var file = new FileInfo(path);
            if (!file.Exists || file.Length > 4096) { return new BackupState(null, false); }
            var status = JsonSerializer.Deserialize<Status>(File.ReadAllText(path), Json);
            return new BackupState(status?.CompletedAt, status?.Ok == true);
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException or JsonException)
        {
            return new BackupState(null, false);
        }
    }
}
