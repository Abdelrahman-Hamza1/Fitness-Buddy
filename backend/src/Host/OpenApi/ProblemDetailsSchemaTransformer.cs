using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace FitnessBuddy.Host.OpenApi;

/// <summary>
/// Rewrites the framework's problem schemas (every member nullable and optional) into the contract's
/// <c>ProblemDetails</c> and <c>ValidationProblemDetails</c>: <c>type</c> (uri-reference), <c>title</c> and
/// <c>status</c> (int32) required and non-null; <c>detail</c>, <c>instance</c> (uri-reference) and <c>traceId</c>
/// optional; on validation problems a required, non-null <c>errors</c> map.
/// </summary>
internal sealed class ProblemDetailsSchemaTransformer : IOpenApiSchemaTransformer
{
    /// <summary>The contract's <c>traceId</c> pattern: a W3C trace id.</summary>
    internal const string TraceIdPattern = "^[0-9a-f]{32}$";

    public Task TransformAsync(OpenApiSchema schema, OpenApiSchemaTransformerContext context, CancellationToken cancellationToken)
    {
        var type = context.JsonTypeInfo.Type;
        if (!typeof(ProblemDetails).IsAssignableFrom(type) || schema.Properties is not { } properties)
        {
            return Task.CompletedTask;
        }

        Reshape(properties, "type", JsonSchemaType.String, "uri-reference");
        Reshape(properties, "title", JsonSchemaType.String, format: null);
        Reshape(properties, "status", JsonSchemaType.Integer, "int32");
        Reshape(properties, "detail", JsonSchemaType.String, format: null);
        Reshape(properties, "instance", JsonSchemaType.String, "uri-reference");
        properties["traceId"] = new OpenApiSchema { Type = JsonSchemaType.String, Pattern = TraceIdPattern };

        schema.Required ??= new HashSet<string>(StringComparer.Ordinal);
        schema.Required.Add("type");
        schema.Required.Add("title");
        schema.Required.Add("status");

        if (typeof(HttpValidationProblemDetails).IsAssignableFrom(type))
        {
            properties["errors"] = new OpenApiSchema
            {
                Type = JsonSchemaType.Object,
                AdditionalProperties = new OpenApiSchema
                {
                    Type = JsonSchemaType.Array,
                    Items = new OpenApiSchema { Type = JsonSchemaType.String },
                },
            };
            schema.Required.Add("errors");
        }

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
