using FitnessBuddy.BuildingBlocks.Clients;
using Microsoft.AspNetCore.Http;

namespace FitnessBuddy.BuildingBlocks.Web.Http;

public static class HttpContextClientExtensions
{
    /// <summary>The validated client headers. Available on every <c>/v1</c> endpoint (the header middleware sets them).</summary>
    public static ClientInfo GetClientInfo(this HttpContext context)
    {
        ArgumentNullException.ThrowIfNull(context);
        return context.Features.Get<ClientInfo>()
            ?? throw new InvalidOperationException("No client headers on this request: the endpoint is outside /v1.");
    }

    public static void SetClientInfo(this HttpContext context, ClientInfo clientInfo)
    {
        ArgumentNullException.ThrowIfNull(context);
        context.Features.Set(clientInfo);
    }
}
