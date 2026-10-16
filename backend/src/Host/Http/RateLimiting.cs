using System.Globalization;
using System.Net;
using System.Net.Sockets;
using System.Threading.RateLimiting;
using FitnessBuddy.BuildingBlocks.Web.Http;
using FitnessBuddy.BuildingBlocks.Web.Problems;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Host.Http;

/// <summary>
/// The <c>per-ip</c> policy of the <c>/v1</c> group (S03 plan D10): a fixed window per client address (after the
/// forwarded headers), IPv6 grouped by /64. A rejection is a 429 <c>/errors/rate-limited</c> problem with
/// <c>Retry-After</c>, <c>RateLimit</c> and <c>RateLimit-Policy</c> (draft-ietf-httpapi-ratelimit-headers-11),
/// on 429 only: the built-in limiters don't expose what remains on a success.
/// </summary>
internal static class RateLimiting
{
    public static IServiceCollection AddFbRateLimiting(this IServiceCollection services)
    {
        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.AddPolicy(V1Api.RateLimitPolicy, context =>
            {
                var limits = Limits(context);
                return RateLimitPartition.GetFixedWindowLimiter(
                    PartitionKey(context.Connection.RemoteIpAddress),
                    _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = limits.PermitLimit,
                        Window = TimeSpan.FromSeconds(limits.WindowSeconds),
                        QueueLimit = 0,
                    });
            });
            options.OnRejected = OnRejectedAsync;
        });
        return services;
    }

    /// <summary>The full IPv4 address, the /64 prefix of an IPv6 address (one IPv6 subscriber usually has a whole /64), or <c>unknown</c>.</summary>
    public static string PartitionKey(IPAddress? address)
    {
        if (address is null)
        {
            return "unknown";
        }

        if (address.IsIPv4MappedToIPv6)
        {
            address = address.MapToIPv4();
        }

        if (address.AddressFamily != AddressFamily.InterNetworkV6)
        {
            return address.ToString();
        }

        Span<byte> bytes = stackalloc byte[16];
        address.TryWriteBytes(bytes, out _);
        bytes[8..].Clear();
        return string.Create(CultureInfo.InvariantCulture, $"{new IPAddress(bytes)}/64");
    }

    private static PerIpRateLimitOptions Limits(HttpContext context) =>
        context.RequestServices.GetRequiredService<IOptions<PerIpRateLimitOptions>>().Value;

    private static async ValueTask OnRejectedAsync(OnRejectedContext rejected, CancellationToken cancellationToken)
    {
        var context = rejected.HttpContext;
        var limits = Limits(context);
        var retryAfter = rejected.Lease.TryGetMetadata(MetadataName.RetryAfter, out var wait)
            ? (int)Math.Ceiling(wait.TotalSeconds)
            : limits.WindowSeconds;

        var headers = context.Response.Headers;
        headers.RetryAfter = retryAfter.ToString(CultureInfo.InvariantCulture);
        headers["RateLimit-Policy"] = string.Create(
            CultureInfo.InvariantCulture, $"\"{V1Api.RateLimitPolicy}\";q={limits.PermitLimit};w={limits.WindowSeconds}");
        headers["RateLimit"] = string.Create(CultureInfo.InvariantCulture, $"\"{V1Api.RateLimitPolicy}\";r=0;t={retryAfter}");

        await context.RequestServices.GetRequiredService<IProblemDetailsService>().TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = context,
            ProblemDetails = new ProblemDetails
            {
                Status = StatusCodes.Status429TooManyRequests,
                Type = ProblemTypes.RateLimited,
                Title = ProblemTitles.RateLimited,
            },
        });
    }
}
