namespace FitnessBuddy.BuildingBlocks.Clients;

/// <summary>
/// The validated client headers of a <c>/v1</c> request. <see cref="DeviceId"/> is a random install ID; it must
/// never reach logs or telemetry (09 §4).
/// </summary>
public sealed record ClientInfo(AppVersion AppVersion, ClientPlatform Platform, Guid DeviceId);
