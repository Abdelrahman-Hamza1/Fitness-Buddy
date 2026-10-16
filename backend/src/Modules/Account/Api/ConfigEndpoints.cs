using FitnessBuddy.BuildingBlocks.Web.Http;
using FitnessBuddy.Modules.Account.Application;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;

namespace FitnessBuddy.Modules.Account.Api;

internal static class ConfigEndpoints
{
    public static void MapConfigEndpoints(this RouteGroupBuilder group) =>
        group.MapGet("/config", GetConfig)
            .WithName("getConfig")
            .AllowOutdatedClients();

    private static Ok<ClientConfig> GetConfig(GetClientConfig handler) =>
        TypedResults.Ok(ClientConfig.From(handler.Handle()));
}
