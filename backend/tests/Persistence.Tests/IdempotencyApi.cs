using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.BuildingBlocks.Web.Idempotency;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace FitnessBuddy.Persistence.Tests;

internal sealed class IdempotencyApi(PostgresFixture database, TestClock clock) : WebApplicationFactory<Program>
{
    public IdempotencySignals Signals { get; } = new();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["RateLimiting:PerIp:PermitLimit"] = "10000",
            ["ConnectionStrings:Application"] = database.AppConnection,
            ["Recovery:Directory"] = database.RecoveryDirectory,
        }));
        builder.ConfigureTestServices(services =>
        {
            services.AddSingleton<TimeProvider>(clock);
            services.AddHttpContextAccessor();
            services.AddSingleton(Signals);
            services.RemoveAll<IUserLifecycle>();
            services.AddSingleton<IUserLifecycle, SyntheticLifecycle>();
            services.RemoveAll<ICurrentUser>();
            services.AddScoped<ICurrentUser, TestUser>();
            services.AddSingleton<IModule, TestModule>();
        });
    }
    private sealed class TestUser(IHttpContextAccessor accessor) : ICurrentUser
    {
        public Guid? UserId => Guid.TryParse(accessor.HttpContext?.Request.Headers["Test-User"], out var id) ? id : null;
        public Guid? SessionId => UserId.HasValue ? Guid.Parse("0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b") : null;
        public bool IsAuthenticated => UserId is not null;
    }
    private sealed class TestModule : IModule
    {
        public string Name => "PersistenceProbe";
        public FitnessBuddy.BuildingBlocks.Messaging.UserDataOwnership UserData => new([], [], null);
        public void AddServices(IServiceCollection services, IConfiguration configuration) { }
        public void MapEndpoints(RouteGroupBuilder group)
        {
            group.MapPost("/_persistence/{id:guid}", async (Guid id, HttpContext context, DatabaseSession session, IdempotencySignals signals) =>
            {
                await using var effect = session.Command("INSERT INTO testdata.effects VALUES($1,1) ON CONFLICT(id) DO UPDATE SET count=testdata.effects.count+1 RETURNING count");
                effect.Parameters.AddWithValue(id);
                var count = (int)(await effect.ExecuteScalarAsync(context.RequestAborted))!;
                if (context.Request.Query.ContainsKey("wait"))
                {
                    signals.Started.TrySetResult();
                    await Task.Delay(Timeout.InfiniteTimeSpan, context.RequestAborted);
                }
                if (context.Request.Query.ContainsKey("databaseError"))
                {
                    await using var fail = session.Command("SELECT \"CANARY-PRIVATE-FOOD-TEXT\"");
                    await fail.ExecuteScalarAsync(context.RequestAborted);
                }
                if (context.Request.Query.ContainsKey("throw")) { throw new InvalidOperationException("private-failure"); }
                if (context.Request.Query.ContainsKey("fail")) { return Results.Problem(statusCode: 500); }
                if (context.Request.Query.ContainsKey("large")) { return Results.Text(new string('x', IdempotencyMiddleware.MaxResponseBytes + 1)); }
                if (context.Request.Query.ContainsKey("reject")) { return Results.Problem(statusCode: 422); }
                context.Response.Headers.ETag = "\"version1\"";
                context.Response.Headers.SetCookie = "must-not-replay=secret";
                return Results.Json(new { count, user = context.Request.Headers["Test-User"].ToString(), id }, statusCode: 201);
            }).RequireIdempotency();
        }
    }
}

internal sealed class IdempotencySignals
{
    public TaskCompletionSource Started { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
}
