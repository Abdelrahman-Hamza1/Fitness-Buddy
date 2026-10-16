using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace FitnessBuddy.Host.OpenApi;

/// <summary>
/// Declares the response headers the pipeline sends (contract <c>components/headers.yaml</c>): <c>X-Request-Id</c> on
/// every response, and <c>Retry-After</c>, <c>RateLimit</c>, <c>RateLimit-Policy</c> on 429.
/// </summary>
internal sealed class ResponseHeadersOperationTransformer : IOpenApiOperationTransformer
{
    public Task TransformAsync(OpenApiOperation operation, OpenApiOperationTransformerContext context, CancellationToken cancellationToken)
    {
        if (operation.Responses is not { } responses)
        {
            return Task.CompletedTask;
        }

        foreach (var (status, response) in responses)
        {
            if (response is not OpenApiResponse concrete)
            {
                continue;
            }

            concrete.Headers ??= new Dictionary<string, IOpenApiHeader>(StringComparer.OrdinalIgnoreCase);
            concrete.Headers["X-Request-Id"] = Header(new OpenApiSchema
            {
                Type = JsonSchemaType.String,
                Pattern = ProblemDetailsSchemaTransformer.TraceIdPattern,
            });

            if (status == "429")
            {
                concrete.Headers["Retry-After"] = Header(new OpenApiSchema { Type = JsonSchemaType.Integer, Minimum = "0" });
                concrete.Headers["RateLimit"] = Header(new OpenApiSchema { Type = JsonSchemaType.String });
                concrete.Headers["RateLimit-Policy"] = Header(new OpenApiSchema { Type = JsonSchemaType.String });
            }
        }

        return Task.CompletedTask;
    }

    private static OpenApiHeader Header(OpenApiSchema schema) => new() { Schema = schema };
}
