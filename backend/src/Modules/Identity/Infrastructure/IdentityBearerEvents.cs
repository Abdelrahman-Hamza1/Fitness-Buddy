using System.Security.Claims;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

internal sealed partial class IdentityBearerEvents(IIdentityTokens tokens, IIdentityAccess access, IDeviceActivity devices, IOptions<IdentityOptions> options,
    ILogger<IdentityBearerEvents> logger) : JwtBearerEvents
{
    public override async Task MessageReceived(MessageReceivedContext context)
    {
        var header = context.Request.Headers.Authorization.ToString();
        if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)) { context.NoResult(); return; }
        if (!options.Value.Enabled) { context.Fail("Authentication unavailable."); return; }
        try
        {
            var principal = await tokens.ValidateAsync(header[7..], context.HttpContext.RequestAborted);
            if (principal is null || !Guid.TryParse(principal.FindFirstValue("sub"), out var user) || !Guid.TryParse(principal.FindFirstValue("sid"), out var session))
            { context.Fail("Invalid credentials."); return; }
            var live = await access.ReadSessionAsync(user, session, context.HttpContext.RequestAborted);
            if (live is null) { context.Fail("Invalid credentials."); return; }
            context.HttpContext.Features.Set(live);
            context.Principal = principal;
            context.Success();
            await TouchDeviceAsync(context.HttpContext, user, session);
        }
        catch (OperationCanceledException) when (context.HttpContext.RequestAborted.IsCancellationRequested) { throw; }
        // Credential lookup or validation failures never fall back to an authenticated/anonymous user.
        catch (Exception) { context.Fail("Authentication unavailable."); }
    }
    /// <summary>
    /// B23: install activity for the console (last seen, app version). Best effort and outside any transaction: a failure is
    /// logged as its type and the request continues; cancellation still propagates.
    /// </summary>
    private async Task TouchDeviceAsync(HttpContext http, Guid user, Guid session)
    {
        if (http.Features.Get<FitnessBuddy.BuildingBlocks.Clients.ClientInfo>() is not { } client) { return; }
        try
        {
            var platform = client.Platform == FitnessBuddy.BuildingBlocks.Clients.ClientPlatform.Ios
                ? FitnessBuddy.BuildingBlocks.Clients.ClientPlatforms.Ios : FitnessBuddy.BuildingBlocks.Clients.ClientPlatforms.Android;
            await devices.TouchAsync(user, session, client.AppVersion.ToString(), platform, http.RequestAborted);
        }
        catch (OperationCanceledException) when (http.RequestAborted.IsCancellationRequested) { throw; }
        catch (Exception exception) { LogTouchFailed(logger, exception.GetType().Name); }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Device activity not recorded: {ErrorType}")]
    private static partial void LogTouchFailed(ILogger logger, string errorType);

    public override async Task Challenge(JwtBearerChallengeContext context)
    {
        context.HandleResponse();
        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
        context.Response.Headers.WWWAuthenticate = "Bearer";
        await WriteAsync(context.HttpContext, 401, "Invalid credentials", "/errors/unauthorized");
    }
    public override Task Forbidden(ForbiddenContext context) => WriteAsync(context.HttpContext, 403, "Forbidden", "/errors/forbidden");
    private static async Task WriteAsync(HttpContext context, int status, string title, string type)
    {
        context.Response.StatusCode = status;
        context.Response.Headers.CacheControl = "no-store";
        await context.RequestServices.GetRequiredService<IProblemDetailsService>().WriteAsync(new ProblemDetailsContext
        { HttpContext = context, ProblemDetails = new ProblemDetails { Status = status, Title = title, Type = type } });
    }
}
