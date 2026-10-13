using System.Text.Json.Nodes;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace FitnessBuddy.Host.OpenApi;

/// <summary>
/// Documents the contract's client headers (<c>X-App-Version</c>, <c>X-Platform</c>,
/// <c>X-Device-Id</c>, contract components/parameters) on every <c>/v1/</c> operation (S02 D10).
/// Documentation only: S03 adds the middleware that enforces them, and both should then derive
/// from one definition (a <c>/v1</c> route group with endpoint metadata, S02 A8).
/// </summary>
internal sealed class ClientHeadersOperationTransformer : IOpenApiOperationTransformer
{
    public Task TransformAsync(OpenApiOperation operation, OpenApiOperationTransformerContext context, CancellationToken cancellationToken)
    {
        if (context.Description.RelativePath?.StartsWith("v1/", StringComparison.Ordinal) != true)
        {
            return Task.CompletedTask;
        }

        operation.Parameters ??= [];
        Add(operation.Parameters, "X-App-Version", new OpenApiSchema { Type = JsonSchemaType.String });
        Add(operation.Parameters, "X-Platform", new OpenApiSchema
        {
            Type = JsonSchemaType.String,
            Enum = [JsonValue.Create("android"), JsonValue.Create("ios")],
        });
        Add(operation.Parameters, "X-Device-Id", new OpenApiSchema { Type = JsonSchemaType.String, Format = "uuid" });

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
