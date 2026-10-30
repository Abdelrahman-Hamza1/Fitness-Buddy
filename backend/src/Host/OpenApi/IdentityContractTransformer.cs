using FitnessBuddy.Modules.Identity.Api;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace FitnessBuddy.Host.OpenApi;

/// <summary>B04 auth scheme and email format missing from the framework's annotation inference.</summary>
internal sealed class IdentityContractTransformer : IOpenApiOperationTransformer, IOpenApiSchemaTransformer
{
    public Task TransformAsync(OpenApiOperation operation, OpenApiOperationTransformerContext context, CancellationToken cancellationToken)
    {
        if (operation.OperationId is "getMe" or "deleteAccount" or "logoutSession" or "linkIdentity" or "startEmailLink" or "pushSync" or "pullSync" or "getSyncHistory" or "getItemSyncHistory"
            or "interpretMessage" or "searchFoods" or "getFood" or "getFoodByBarcode" or "getLatestCatalogPack" or "downloadCatalogPack")
        {
            context.Document!.Components ??= new OpenApiComponents();
            context.Document!.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>(StringComparer.Ordinal);
            context.Document!.Components.SecuritySchemes["bearerAuth"] = new OpenApiSecurityScheme
            {
                Type = SecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT",
            };
            operation.Security = [new OpenApiSecurityRequirement { [new OpenApiSecuritySchemeReference("bearerAuth", context.Document!)] = [] }];
        }
        if (operation.OperationId == "searchFoods")
        {
            // Optional query strings bind null when absent; the framework omits the nullable branch.
            foreach (var parameter in operation.Parameters ?? [])
            { if (parameter.Name == "cursor" && parameter.Schema is OpenApiSchema schema) { schema.Type |= JsonSchemaType.Null; } }
        }
        if (operation.OperationId == "downloadCatalogPack")
        {
            // FileContentHttpResult does not advertise a success body; bytes are sent verbatim, not base64 JSON.
            operation.Responses!["200"] = new OpenApiResponse
            {
                Description = "Immutable offline pack.",
                Headers = new Dictionary<string, IOpenApiHeader>(StringComparer.Ordinal)
                {
                    ["X-Request-Id"] = new OpenApiHeader { Schema = new OpenApiSchema { Type = JsonSchemaType.String, Pattern = ProblemDetailsSchemaTransformer.TraceIdPattern } },
                },
                Content = new Dictionary<string, OpenApiMediaType>(StringComparer.Ordinal)
                { ["application/octet-stream"] = new() { Schema = new OpenApiSchema { Type = JsonSchemaType.String, Format = "binary" } } },
            };
        }
        return Task.CompletedTask;
    }

    public Task TransformAsync(OpenApiSchema schema, OpenApiSchemaTransformerContext context, CancellationToken cancellationToken)
    {
        if ((context.JsonTypeInfo.Type == typeof(EmailStartRequest) || context.JsonTypeInfo.Type == typeof(EmailLinkStartRequest))
            && schema.Properties?["email"] is OpenApiSchema email)
        {
            email.Format = "email";
        }
        return Task.CompletedTask;
    }
}
