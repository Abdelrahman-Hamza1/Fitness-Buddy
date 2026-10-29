using FitnessBuddy.BuildingBlocks.Web.Http;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Host.Http;
using FitnessBuddy.Host.OpenApi;
using FitnessBuddy.Host.Platform;
using FitnessBuddy.Host.Observability;

namespace FitnessBuddy.Host.Roles;

/// <summary>The <c>api</c> role: stateless HTTP.</summary>
internal static class ApiRole
{
    public static async Task<int> RunAsync(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);
        builder.AddFbPlatform();
        builder.AddFbPersistence();
        builder.AddFbObservability("api");
        builder.AddFbHttp();

        // Strict numbers, camelCase enums, required members and nullable annotations (ApiJson).
        builder.Services.ConfigureHttpJsonOptions(options => ApiJson.Configure(options.SerializerOptions));

        builder.Services.AddOpenApi("v1", options =>
        {
            options.AddDocumentTransformer<BuddyContractTransformer>();
            options.AddSchemaTransformer<ProblemDetailsSchemaTransformer>();
            options.AddSchemaTransformer<IdentityContractTransformer>();
            options.AddSchemaTransformer<SyncContractTransformer>();
            options.AddOperationTransformer<IdentityContractTransformer>();
            options.AddOperationTransformer<SyncContractTransformer>();
            options.AddOperationTransformer<ClientHeadersOperationTransformer>();
            options.AddOperationTransformer<ResponseHeadersOperationTransformer>();
        });

        var app = builder.Build();
        app.UseFbHttpPipeline();
        app.MapFbHealth();

        // The live document is for local development only. The build-time document
        // (backend/artifacts/openapi/server.json) doesn't need this endpoint.
        if (app.Environment.IsDevelopment())
        {
            app.MapOpenApi();
        }

        FitnessBuddy.Modules.Identity.IdentityModule.MapPublicEndpoints(app);
        var v1 = V1Api.MapV1(app);
        foreach (var module in app.Services.GetServices<IModule>())
        {
            V1Api.MapModuleGroup(v1, module);
        }

        await app.RunAsync();
        return 0;
    }
}
