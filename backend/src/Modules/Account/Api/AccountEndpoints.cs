using FitnessBuddy.Modules.Account.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Account.Api;

internal static class AccountEndpoints
{
    public static void Map(RouteGroupBuilder group)
    {
        group.MapGet("/me", (HttpContext context) =>
        {
            var session = context.Features.Get<IdentitySession>()!;
            return TypedResults.Ok(new CurrentAccount(session.UserId, session.IsAnonymous, "active"));
        }).WithName("getMe").RequireAuthorization("any-user").Produces<CurrentAccount>()
            .ProducesProblem(401).ProducesProblem(403).ProducesProblem(501).ProducesProblem(503);
        group.MapDelete("/me", DeleteAsync).WithName("deleteAccount").RequireAuthorization("any-user")
            .Produces(204).ProducesProblem(401).ProducesProblem(503);
    }

    private static async Task<IResult> DeleteAsync(HttpContext context, DeleteAccount deletion, CancellationToken cancellationToken)
    {
        context.Response.Headers.CacheControl = "no-store";
        if (context.Request.ContentLength is > 0 || context.Request.Headers.ContainsKey("Transfer-Encoding"))
        { return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["body"] = ["This operation takes no request body."] }); }
        var principal = context.Features.Get<IdentitySession>()!;
        var result = await deletion.ExecuteAsync(principal.UserId, principal.SessionId, cancellationToken);
        return result switch
        {
            DeletionResult.Deleted => TypedResults.NoContent(),
            DeletionResult.Unauthorized => TypedResults.Problem(statusCode: 401, type: "/errors/unauthorized", title: "Invalid credentials"),
            _ => TypedResults.Problem(statusCode: 503),
        };
    }
}
internal sealed record CurrentAccount(Guid UserId, bool IsAnonymous, string Status);
