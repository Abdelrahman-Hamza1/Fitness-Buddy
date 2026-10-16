using FitnessBuddy.BuildingBlocks.Clients;
using FitnessBuddy.BuildingBlocks.Web.Http;
using FitnessBuddy.BuildingBlocks.Web.Problems;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Host.Http;

/// <summary>
/// The client headers and the minimum-version gate, for endpoints with <see cref="ClientHeadersMetadata"/> (S03 plan D9):
/// <list type="number">
/// <item>A valid <c>X-App-Version</c> below <c>Clients:MinimumAppVersion</c> gets 426, unless the endpoint allows
/// outdated clients. Checked first, so the kill switch wins even over a malformed <c>X-Platform</c>.</item>
/// <item>Any missing or invalid header gets 400 <c>validation-failed</c>, keyed by the lowercase header name.</item>
/// <item>Otherwise the parsed <see cref="ClientInfo"/> goes into the request features.</item>
/// </list>
/// Header values are never echoed in messages (the device id must not leave the request, 09 §4).
/// </summary>
internal sealed class ClientHeadersMiddleware(
    RequestDelegate next,
    IOptionsMonitor<ClientCompatibilityOptions> compatibility,
    IProblemDetailsService problemDetails)
{
    public const string UpgradeRequiredDetail = "This app version is no longer supported. Update the app.";

    public async Task InvokeAsync(HttpContext context)
    {
        var metadata = context.GetEndpoint()?.Metadata;
        if (metadata?.GetMetadata<ClientHeadersMetadata>() is null)
        {
            await next(context);
            return;
        }

        var headers = context.Request.Headers;
        var hasVersion = AppVersion.TryParse(Single(headers, ClientHeadersMetadata.AppVersionHeader), out var version);
        if (hasVersion
            && version < compatibility.CurrentValue.GetMinimumAppVersion()
            && metadata.GetMetadata<AllowOutdatedClientsMetadata>() is null)
        {
            await WriteProblemAsync(context, StatusCodes.Status426UpgradeRequired, new ProblemDetails
            {
                Type = ProblemTypes.UpgradeRequired,
                Title = ProblemTitles.UpgradeRequired,
                Detail = UpgradeRequiredDetail,
            });
            return;
        }

        var errors = new Dictionary<string, string[]>(StringComparer.Ordinal);
        if (!hasVersion)
        {
            AddError(errors, headers, ClientHeadersMetadata.AppVersionHeader, "x-app-version", "must be MAJOR.MINOR.PATCH.");
        }

        if (!ClientPlatforms.TryParse(Single(headers, ClientHeadersMetadata.PlatformHeader), out var platform))
        {
            AddError(errors, headers, ClientHeadersMetadata.PlatformHeader, "x-platform", "must be android or ios.");
        }

        if (!Guid.TryParseExact(Single(headers, ClientHeadersMetadata.DeviceIdHeader), "D", out var deviceId))
        {
            AddError(errors, headers, ClientHeadersMetadata.DeviceIdHeader, "x-device-id", "must be a UUID.");
        }

        if (errors.Count > 0)
        {
            await WriteProblemAsync(context, StatusCodes.Status400BadRequest, new HttpValidationProblemDetails(errors));
            return;
        }

        context.SetClientInfo(new ClientInfo(version, platform, deviceId));
        await next(context);
    }

    // Exactly one value; a repeated header is invalid.
    private static string? Single(IHeaderDictionary headers, string name) =>
        headers.TryGetValue(name, out var values) && values.Count == 1 ? values[0] : null;

    // Keys are the lowercase header names, which the camelCase rewrite of validation keys leaves alone.
    private static void AddError(Dictionary<string, string[]> errors, IHeaderDictionary headers, string name, string key, string rule) =>
        errors[key] = [headers.ContainsKey(name) ? $"The {name} header {rule}" : $"The {name} header is required."];

    private async Task WriteProblemAsync(HttpContext context, int status, ProblemDetails problem)
    {
        problem.Status = status;
        context.Response.StatusCode = status;
        await problemDetails.TryWriteAsync(new ProblemDetailsContext { HttpContext = context, ProblemDetails = problem });
    }
}
