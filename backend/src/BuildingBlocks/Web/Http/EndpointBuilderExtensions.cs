using Microsoft.AspNetCore.Builder;

namespace FitnessBuddy.BuildingBlocks.Web.Http;

public static class EndpointBuilderExtensions
{
    /// <summary>
    /// Exempts the endpoint from the minimum-version gate (no 426), e.g. <c>getConfig</c>, which is how an outdated
    /// app learns the minimum. The client headers are still required.
    /// </summary>
    public static TBuilder AllowOutdatedClients<TBuilder>(this TBuilder builder)
        where TBuilder : IEndpointConventionBuilder =>
        builder.WithMetadata(AllowOutdatedClientsMetadata.Instance);
}
