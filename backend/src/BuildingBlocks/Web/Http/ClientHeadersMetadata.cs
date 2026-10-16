namespace FitnessBuddy.BuildingBlocks.Web.Http;

/// <summary>
/// Endpoint metadata: the endpoint requires the client headers. Every <c>/v1</c> endpoint has it (set by
/// <see cref="V1Api"/>); the header middleware enforces it and the OpenAPI document declares the headers from it.
/// </summary>
public sealed class ClientHeadersMetadata
{
    public const string AppVersionHeader = "X-App-Version";
    public const string PlatformHeader = "X-Platform";
    public const string DeviceIdHeader = "X-Device-Id";

    public static ClientHeadersMetadata Instance { get; } = new();

    private ClientHeadersMetadata()
    {
    }
}

/// <summary>Endpoint metadata: the endpoint answers outdated apps instead of the 426 (see <see cref="EndpointBuilderExtensions.AllowOutdatedClients"/>).</summary>
public sealed class AllowOutdatedClientsMetadata
{
    public static AllowOutdatedClientsMetadata Instance { get; } = new();

    private AllowOutdatedClientsMetadata()
    {
    }
}
