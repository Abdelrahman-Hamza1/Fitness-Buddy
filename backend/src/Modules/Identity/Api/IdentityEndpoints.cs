using System.ComponentModel.DataAnnotations;
using FitnessBuddy.BuildingBlocks.Web.Http;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;

using Microsoft.Extensions.DependencyInjection;

namespace FitnessBuddy.Modules.Identity.Api;

internal static class IdentityEndpoints
{
    public static void MapIdentityEndpoints(this RouteGroupBuilder group)
    {
        var auth = group.MapGroup("/auth").RequireRateLimiting("auth");
        auth.AddEndpointFilter(async (context, next) =>
        {
            context.HttpContext.Response.Headers.CacheControl = "no-store";
            context.HttpContext.Response.Headers.Pragma = "no-cache";
            if (!context.HttpContext.RequestServices.GetRequiredService<IdentityService>().Enabled) { return Stub(); }
            try { return await next(context); }
            catch (IdentityConflictException) { return TypedResults.Problem(statusCode: 409, title: "Identity already linked", type: "/errors/identity-conflict"); }
        });
        Configure(auth.MapPost("/anonymous", async (HttpContext context, IdentityService service, CancellationToken ct) =>
            Result(await service.GuestAsync(context.GetClientInfo().DeviceId, ct))), "createAnonymous");
        Configure(auth.MapPost("/google", async (GoogleSignInRequest request, HttpContext context, IdentityService service, CancellationToken ct) =>
            Result(await service.GoogleAsync(request.IdToken, context.GetClientInfo().DeviceId, ct))), "signInGoogle");
        Configure(auth.MapPost("/email/verify", async (EmailVerifyRequest request, HttpContext context, IdentityService service, CancellationToken ct) =>
            Result(await service.VerifyEmailAsync(request.ChallengeId, request.Code, context.GetClientInfo().DeviceId, ct))), "verifyEmailSignIn");
        Configure(auth.MapPost("/refresh", async (RefreshRequest request, IdentityService service, CancellationToken ct) =>
            Result(await service.RefreshAsync(request.RefreshToken, ct))), "refreshSession");
        Configure(auth.MapPost("/link/{provider}", async ([RegularExpression("^(google|email)$")] string provider, LinkIdentityRequest request, HttpContext context, IdentityService service, CancellationToken ct) =>
        {
            var principal = context.Features.Get<IdentitySession>();
            return principal is null ? Unauthorized() : Result(await service.LinkAsync(principal, provider, request.IdToken, request.ChallengeId, request.Code, context.GetClientInfo().DeviceId, ct));
        }).RequireAuthorization("any-user"), "linkIdentity");
        auth.MapPost("/email/start", async (EmailStartRequest request, HttpContext context, IdentityService service, CancellationToken ct) =>
        {
            var challenge = await service.StartEmailAsync(request.Email, request.Purpose, context.Features.Get<IdentitySession>(), Peer(context.Connection.RemoteIpAddress), ct);
            return TypedResults.Ok(new EmailChallenge(challenge.Id, challenge.Expires));
        }).WithName("startEmailSignIn").Produces<EmailChallenge>().ProducesProblem(401).ProducesProblem(403).ProducesProblem(409).ProducesProblem(501);
        auth.MapPost("/logout", async (HttpContext context, IIdentityStore store, CancellationToken ct) =>
        {
            var principal = context.Features.Get<IdentitySession>()!;
            await store.RevokeAsync(principal.UserId, principal.SessionId, ct);
            return TypedResults.NoContent();
        }).RequireAuthorization("any-user").WithName("logoutSession").Produces(204).ProducesProblem(401).ProducesProblem(403).ProducesProblem(409).ProducesProblem(501);
    }
    public static void MapPublicEndpoints(IEndpointRouteBuilder app) =>
        app.MapGet("/.well-known/jwks.json", async (IIdentityTokens tokens, IdentityService service, CancellationToken ct) =>
        {
            if (!service.Enabled) { return (IResult)Stub(); }
            var keys = await tokens.PublicKeysAsync(ct);
            return TypedResults.Ok(new JsonWebKeySet(keys.Select(key => new JsonWebKey(key.Kty, key.Crv, key.Kid, key.X, key.Y, key.Alg, key.Use)).ToArray()));
        }).WithName("getJwks").WithTags("Identity").Produces<JsonWebKeySet>().ProducesProblem(500).ProducesProblem(501);

    private static void Configure(RouteHandlerBuilder endpoint, string name) => endpoint.WithName(name).Produces<AuthTokens>()
        .ProducesProblem(401).ProducesProblem(403).ProducesProblem(409).ProducesProblem(501);
    private static IResult Result(IssuedTokens? tokens) => tokens is null ? Unauthorized() : TypedResults.Ok(new AuthTokens(tokens.UserId, tokens.IsAnonymous, tokens.AccessToken, tokens.RefreshToken, tokens.ExpiresAt, tokens.RefreshExpiresAt));
    private static ProblemHttpResult Unauthorized() => TypedResults.Problem(statusCode: 401, title: "Invalid credentials", type: "/errors/unauthorized");
    private static string Peer(System.Net.IPAddress? ip)
    {
        if (ip is null) { return "unknown"; }
        if (ip.IsIPv4MappedToIPv6) { ip = ip.MapToIPv4(); }
        if (ip.AddressFamily == System.Net.Sockets.AddressFamily.InterNetworkV6)
        {
            var bytes = ip.GetAddressBytes(); bytes.AsSpan(8).Clear(); return new System.Net.IPAddress(bytes).ToString();
        }
        return ip.ToString();
    }
    internal static ProblemHttpResult Stub() => TypedResults.Problem(statusCode: 501, title: "Not implemented");
}
