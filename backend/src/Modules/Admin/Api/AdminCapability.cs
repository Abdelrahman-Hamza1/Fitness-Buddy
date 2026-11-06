using Microsoft.AspNetCore.Builder;

namespace FitnessBuddy.Modules.Admin.Api;

/// <summary>
/// What an endpoint needs (B23 P2, R#10). Every console endpoint declares exactly one; a test enumerates them.
/// <see cref="Anonymous"/>: sign-in, assets, health. <see cref="Session"/>: any allow-listed admin (every read, sign-out,
/// re-auth, POST-based reads). <see cref="Operate"/>: operators only (every change).
/// </summary>
internal enum AdminCapability
{
    Anonymous,
    Session,
    Operate,
}

internal sealed record AdminCapabilityMetadata(AdminCapability Capability);

internal static class AdminPolicies
{
    public const string Session = "admin-session";
    public const string Operate = "admin-operate";

    public static TBuilder WithCapability<TBuilder>(this TBuilder builder, AdminCapability capability) where TBuilder : IEndpointConventionBuilder
    {
        builder.WithMetadata(new AdminCapabilityMetadata(capability));
        return capability switch
        {
            AdminCapability.Anonymous => builder.AllowAnonymous(),
            AdminCapability.Session => builder.RequireAuthorization(Session),
            _ => builder.RequireAuthorization(Operate),
        };
    }
}
