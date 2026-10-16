using System.Text.Json.Nodes;
using FitnessBuddy.BuildingBlocks.Clients;
using FitnessBuddy.BuildingBlocks.Web.Http;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace FitnessBuddy.Host.OpenApi;

/// <summary>
/// Declares the client headers (contract parameters <c>AppVersion</c>, <c>Platform</c>, <c>DeviceId</c>) on every
/// operation with <see cref="ClientHeadersMetadata"/>, the same metadata the header middleware enforces.
/// </summary>
internal sealed class ClientHeadersOperationTransformer : IOpenApiOperationTransformer
{
    public Task TransformAsync(OpenApiOperation operation, OpenApiOperationTransformerContext context, CancellationToken cancellationToken)
    {
        if (!context.Description.ActionDescriptor.EndpointMetadata.OfType<ClientHeadersMetadata>().Any())
        {
            return Task.CompletedTask;
        }

        operation.Parameters ??= [];
        Add(operation.Parameters, ClientHeadersMetadata.AppVersionHeader, new OpenApiSchema { Type = JsonSchemaType.String });
        Add(operation.Parameters, ClientHeadersMetadata.PlatformHeader, new OpenApiSchema
        {
            Type = JsonSchemaType.String,
            Enum = [.. ClientPlatforms.WireNames.Select(name => (JsonNode)JsonValue.Create(name))],
        });
        Add(operation.Parameters, ClientHeadersMetadata.DeviceIdHeader, new OpenApiSchema { Type = JsonSchemaType.String, Format = "uuid" });

        return Task.CompletedTask;
    }

    private static void Add(IList<IOpenApiParameter> parameters, string name, OpenApiSchema schema)
    {
        if (parameters.Any(p => p.In == ParameterLocation.Header && string.Equals(p.Name, name, StringComparison.OrdinalIgnoreCase)))
        {
            return;
        }

        parameters.Add(new OpenApiParameter
        {
            Name = name,
            In = ParameterLocation.Header,
            Required = true,
            Schema = schema,
        });
    }
}
