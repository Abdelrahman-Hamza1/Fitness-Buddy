using System.Text.Json;
using System.Text.Json.Serialization;
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
        builder.AddFbObservability("api");
        builder.AddFbHttp();

        builder.Services.ConfigureHttpJsonOptions(options =>
        {
            // Numbers are numbers: the web default (AllowReadingFromString) would document every
            // number as `number | string` and accept "12" on input (S02 research gotcha 4).
            options.SerializerOptions.NumberHandling = JsonNumberHandling.Strict;
            options.SerializerOptions.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.CamelCase));
            // A missing member or a null for a non-nullable one is an unreadable body (TD-043, S03 plan D1).
            options.SerializerOptions.RespectRequiredConstructorParameters = true;
            options.SerializerOptions.RespectNullableAnnotations = true;
        });

        builder.Services.AddOpenApi("v1", options =>
        {
            options.AddSchemaTransformer<ProblemDetailsSchemaTransformer>();
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

        var v1 = V1Api.MapV1(app);
        foreach (var module in app.Services.GetServices<IModule>())
        {
            V1Api.MapModuleGroup(v1, module);
        }

        await app.RunAsync();
        return 0;
    }
}
