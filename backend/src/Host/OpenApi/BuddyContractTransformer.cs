using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace FitnessBuddy.Host.OpenApi;

/// <summary>The runtime emits exactly one kind. Normalize .NET's polymorphic anyOf/names to the contract union, and type Buddy string enums.</summary>
internal sealed class BuddyContractTransformer : IOpenApiDocumentTransformer
{
    public Task TransformAsync(OpenApiDocument document, OpenApiDocumentTransformerContext context, CancellationToken cancellationToken)
    {
        var schemas = document.Components?.Schemas;
        if (schemas is null) { return Task.CompletedTask; }
        // String enums (JsonStringEnumConverter) are emitted without a type, and with a null value when some use is
        // nullable. The contract types them as strings; a nullable use is the null-wrap at the property.
        // Entry ID lists name each entry once (no attribute for uniqueItems).
        foreach (var (name, schema) in schemas)
        {
            if (!name.StartsWith("Buddy", StringComparison.Ordinal) || schema is not OpenApiSchema concrete) { continue; }
            if (concrete is { Type: null, Enum.Count: > 0 })
            {
                concrete.Type = JsonSchemaType.String;
                concrete.Enum = concrete.Enum.Where(v => v is not null && v.GetValueKind() != System.Text.Json.JsonValueKind.Null).ToList();
            }
            foreach (var list in new[] { "targets", "candidates" })
            {
                if (concrete.Properties?.TryGetValue(list, out var ids) == true && ids is OpenApiSchema { Type: JsonSchemaType.Array } array) { array.UniqueItems = true; }
            }
        }
        if (!schemas.TryGetValue("BuddyIntent", out var value) || value is not OpenApiSchema union || union.AnyOf is null) { return Task.CompletedTask; }
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
