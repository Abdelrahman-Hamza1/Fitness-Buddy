using FitnessBuddy.Modules.UserData.Api;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace FitnessBuddy.Host.OpenApi;

/// <summary>Preserves the optional nullable dataset discovery parameter in the generated document.</summary>
internal sealed class SyncContractTransformer : IOpenApiOperationTransformer, IOpenApiSchemaTransformer
{
    public Task TransformAsync(OpenApiOperation operation, OpenApiOperationTransformerContext context, CancellationToken cancellationToken)
    {
        if (operation.OperationId is "pullSync" or "getSyncHistory" or "getItemSyncHistory")
        {
            foreach (var parameter in operation.Parameters ?? [])
            {
                if (parameter.Name == "datasetId" && parameter.Schema is OpenApiSchema schema) { schema.Type = JsonSchemaType.String | JsonSchemaType.Null; }
            }
        }
        return Task.CompletedTask;
    }
    public Task TransformAsync(OpenApiSchema schema, OpenApiSchemaTransformerContext context, CancellationToken cancellationToken)
    {
        if (context.JsonTypeInfo.Type == typeof(SyncChange) && schema.Properties?["payload"] is OpenApiSchema payload)
        {
            payload.Type = JsonSchemaType.Object;
            payload.AdditionalProperties = new OpenApiSchema();
        }
        return Task.CompletedTask;
    }

}
