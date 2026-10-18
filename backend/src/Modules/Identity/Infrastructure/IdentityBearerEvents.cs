using System.Security.Claims;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

internal sealed class IdentityBearerEvents(IIdentityTokens tokens, IIdentityAccess access, IOptions<IdentityOptions> options) : JwtBearerEvents
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
        }
        catch (OperationCanceledException) when (context.HttpContext.RequestAborted.IsCancellationRequested) { throw; }
        // Credential lookup or validation failures never fall back to an authenticated/anonymous user.
        catch (Exception) { context.Fail("Authentication unavailable."); }
    }
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
