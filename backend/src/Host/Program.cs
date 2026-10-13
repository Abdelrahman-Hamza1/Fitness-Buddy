// Composition root. Modules are added from S03 on.
// The generated Program class is public in .NET 10 (ASP0027), so tests can use typeof(Program).
// This code also runs at build time, when the OpenAPI document is generated (GetDocument.Insider):
// keep startup free of side effects, see backend/README.md "OpenAPI conventions".
using System.Text.Json;
using System.Text.Json.Serialization;
using FitnessBuddy.Host.Config;
using FitnessBuddy.Host.OpenApi;

var builder = WebApplication.CreateBuilder(args);

builder.Services.ConfigureHttpJsonOptions(options =>
{
    // Numbers are numbers: the web default (AllowReadingFromString) would document every
    // number as `number | string` and accept "12" on input (S02 research gotcha 4).
    options.SerializerOptions.NumberHandling = JsonNumberHandling.Strict;
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.CamelCase));
});

builder.Services.AddOpenApi("v1", options =>
{
    options.AddSchemaTransformer<ProblemDetailsSchemaTransformer>();
    options.AddOperationTransformer<ClientHeadersOperationTransformer>();
});

var app = builder.Build();

// The live document is for local development only. The build-time document
// (backend/artifacts/openapi/server.json) doesn't need this endpoint.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapConfigEndpoints();

await app.RunAsync();
