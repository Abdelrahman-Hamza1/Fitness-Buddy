using FitnessBuddy.Modules.Identity.Contracts;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Account.Api;

internal static class AccountEndpoints
{
    public static void Map(RouteGroupBuilder group) => group.MapGet("/me", (HttpContext context) =>
    {
        var session = context.Features.Get<IdentitySession>()!;
        return TypedResults.Ok(new CurrentAccount(session.UserId, session.IsAnonymous, "active"));
    }).WithName("getMe").RequireAuthorization("any-user").Produces<CurrentAccount>().ProducesProblem(401).ProducesProblem(403).ProducesProblem(501);
}
internal sealed record CurrentAccount(Guid UserId, bool IsAnonymous, string Status);
