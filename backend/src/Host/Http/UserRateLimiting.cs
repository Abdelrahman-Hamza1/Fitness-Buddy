using System.Threading.RateLimiting;
using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.AspNetCore.Mvc;

namespace FitnessBuddy.Host.Http;

/// <summary>Authenticated accounts share one budget across IP addresses; framework partitions expire when idle.</summary>
internal sealed class UserRequestLimiter : IDisposable
{
    private readonly PartitionedRateLimiter<Guid> limiter = PartitionedRateLimiter.Create<Guid, Guid>(user =>
        RateLimitPartition.GetFixedWindowLimiter(user, _ => new FixedWindowRateLimiterOptions
        { PermitLimit = 100, Window = TimeSpan.FromMinutes(1), QueueLimit = 0, AutoReplenishment = true }));
    public RateLimitLease Acquire(Guid user) => limiter.AttemptAcquire(user);
    public void Dispose() => limiter.Dispose();
}
internal sealed class UserRateLimiting(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context, UserRequestLimiter limiter)
    {
        var session = context.Features.Get<IdentitySession>();
        if (session is null) { await next(context); return; }
        using var lease = limiter.Acquire(session.UserId);
        if (lease.IsAcquired) { await next(context); return; }
        context.Response.StatusCode = 429;
        context.Response.Headers.RetryAfter = "60";
        context.Response.Headers["RateLimit-Policy"] = "\"per-user\";q=100;w=60";
        context.Response.Headers["RateLimit"] = "\"per-user\";r=0;t=60";
        await context.RequestServices.GetRequiredService<IProblemDetailsService>().WriteAsync(new ProblemDetailsContext
        { HttpContext = context, ProblemDetails = new ProblemDetails { Status = 429, Title = "Too many requests", Type = "/errors/rate-limited" } });
    }
}
