namespace FitnessBuddy.Host.Config;

/// <summary>
/// <c>GET /v1/config</c> (contract operation <c>getConfig</c>, tag <c>Account</c>).
/// A temporary exception to 04 §3: it moves into the Account module when that module exists,
/// with the same operationId and tag (S02 A6).
/// </summary>
internal static class ConfigEndpoints
{
    public static IEndpointRouteBuilder MapConfigEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/v1/config", () => TypedResults.Ok(ClientConfig.Defaults))
            .WithName("getConfig")
            .WithTags("Account")
            .ProducesProblem(StatusCodes.Status500InternalServerError);

        return app;
    }
}
