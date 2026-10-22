using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace FitnessBuddy.Host.OpenApi;

/// <summary>The runtime emits exactly one kind. Normalize .NET's polymorphic anyOf/names to the contract union.</summary>
internal sealed class BuddyContractTransformer : IOpenApiDocumentTransformer
{
    public Task TransformAsync(OpenApiDocument document, OpenApiDocumentTransformerContext context, CancellationToken cancellationToken)
    {
        var schemas = document.Components?.Schemas;
        if (schemas is null || !schemas.TryGetValue("BuddyIntent", out var value) || value is not OpenApiSchema union || union.AnyOf is null) { return Task.CompletedTask; }
        var mapping = new Dictionary<string, OpenApiSchemaReference>(StringComparer.Ordinal);
        var references = new List<IOpenApiSchema>();
        foreach (var (kind, path) in union.Discriminator!.Mapping!)
        {
            var oldName = path.Reference.Id!;
            var name = oldName["BuddyIntent".Length..];
            var variant = (OpenApiSchema)schemas[oldName];
            variant.Type = JsonSchemaType.Object;
            variant.Required ??= new HashSet<string>(StringComparer.Ordinal); variant.Required.Add("kind");
            schemas[name] = variant; schemas.Remove(oldName);
            mapping[kind] = new OpenApiSchemaReference(name, document); references.Add(new OpenApiSchemaReference(name, document));
        }
        union.AnyOf = null; union.OneOf = references; union.Type = null; union.Required = null;
        union.Discriminator.Mapping = mapping;
        return Task.CompletedTask;
    }
}
