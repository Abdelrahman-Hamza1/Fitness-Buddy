using FitnessBuddy.Modules.Identity.Api;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace FitnessBuddy.Host.OpenApi;

/// <summary>B04 auth scheme and email format missing from the framework's annotation inference.</summary>
internal sealed class IdentityContractTransformer : IOpenApiOperationTransformer, IOpenApiSchemaTransformer
{
    public Task TransformAsync(OpenApiOperation operation, OpenApiOperationTransformerContext context, CancellationToken cancellationToken)
    {
        if (operation.OperationId is "getMe" or "deleteAccount" or "logoutSession" or "linkIdentity" or "pushSync" or "pullSync" or "getSyncHistory" or "getItemSyncHistory")
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
        return Task.CompletedTask;
    }

    public Task TransformAsync(OpenApiSchema schema, OpenApiSchemaTransformerContext context, CancellationToken cancellationToken)
    {
        if (context.JsonTypeInfo.Type == typeof(EmailStartRequest) && schema.Properties?["email"] is OpenApiSchema email)
        {
            email.Format = "email";
        }
        return Task.CompletedTask;
    }
}
