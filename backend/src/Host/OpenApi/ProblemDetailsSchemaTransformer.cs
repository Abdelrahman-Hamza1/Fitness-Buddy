using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace FitnessBuddy.Host.OpenApi;

/// <summary>
/// Rewrites the framework's <see cref="ProblemDetails"/> schema (every member nullable and optional)
/// into the contract's RFC 9457 shape (S02 D5, contract schema <c>ProblemDetails</c>):
/// <c>type</c> (uri-reference), <c>title</c> and <c>status</c> (int32) are required and non-null;
/// <c>detail</c> and <c>instance</c> (uri-reference) are optional. Extension members stay allowed.
/// The runtime side (every problem body sets type, title and status) is S03's error mapping.
/// </summary>
internal sealed class ProblemDetailsSchemaTransformer : IOpenApiSchemaTransformer
{
    public Task TransformAsync(OpenApiSchema schema, OpenApiSchemaTransformerContext context, CancellationToken cancellationToken)
    {
        if (!typeof(ProblemDetails).IsAssignableFrom(context.JsonTypeInfo.Type) || schema.Properties is not { } properties)
        {
            return Task.CompletedTask;
        }

        Reshape(properties, "type", JsonSchemaType.String, "uri-reference");
        Reshape(properties, "title", JsonSchemaType.String, format: null);
        Reshape(properties, "status", JsonSchemaType.Integer, "int32");
        Reshape(properties, "detail", JsonSchemaType.String, format: null);
        Reshape(properties, "instance", JsonSchemaType.String, "uri-reference");

        schema.Required ??= new HashSet<string>(StringComparer.Ordinal);
        schema.Required.Add("type");
        schema.Required.Add("title");
        schema.Required.Add("status");

        return Task.CompletedTask;
    }

    // Non-null type (drops the framework's `null` branch) and the contract's format.
    private static void Reshape(IDictionary<string, IOpenApiSchema> properties, string name, JsonSchemaType type, string? format)
    {
        if (properties.TryGetValue(name, out var property) && property is OpenApiSchema member)
        {
            member.Type = type;
            member.Format = format;
        }
    }
}
