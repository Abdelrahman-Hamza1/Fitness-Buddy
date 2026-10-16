using System.Net;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;

namespace FitnessBuddy.Host.Tests.Infrastructure;

/// <summary>
/// Sets the connection's remote address from <c>X-Test-Peer</c>, before any app middleware, so the forwarded-header
/// and rate-limit tests choose their peer (and each test its own rate-limit partition).
/// </summary>
internal sealed class TestPeerStartupFilter : IStartupFilter
{
    public const string HeaderName = "X-Test-Peer";

    public Action<IApplicationBuilder> Configure(Action<IApplicationBuilder> next) => app =>
    {
        app.Use((context, nextMiddleware) =>
        {
            if (context.Request.Headers.TryGetValue(HeaderName, out var peer) && IPAddress.TryParse(peer, out var address))
            {
                context.Connection.RemoteIpAddress = address;
            }

            return nextMiddleware(context);
        });
        next(app);
    };
}
