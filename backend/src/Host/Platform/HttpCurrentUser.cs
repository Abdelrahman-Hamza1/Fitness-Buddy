using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.Modules.Identity.Contracts;

namespace FitnessBuddy.Host.Platform;

internal sealed class HttpCurrentUser(IHttpContextAccessor accessor) : ICurrentUser
{
    public Guid? UserId => accessor.HttpContext?.Features.Get<IdentitySession>()?.UserId;
    public Guid? SessionId => accessor.HttpContext?.Features.Get<IdentitySession>()?.SessionId;
    public bool IsAuthenticated => accessor.HttpContext?.User.Identity?.IsAuthenticated == true && UserId.HasValue;
}
