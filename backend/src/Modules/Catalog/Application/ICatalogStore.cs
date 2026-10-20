using System.Text.Json;

namespace FitnessBuddy.Modules.Catalog.Application;

internal sealed record FoodRecord(JsonElement Data, JsonElement[] Servings);
internal sealed record RankedFood(FoodRecord Food, int SourceRank, int MatchRank, double Score);
internal sealed record SearchPosition(int Version, string QueryHash, int SourceRank, int MatchRank, double Score, string Key);
internal sealed record SearchResult(RankedFood[] Items, string? NextCursor);
internal sealed record PackRecord(int Version, string Sha256, int SizeBytes, int SchemaVersion, byte[]? Bytes);
internal interface ICatalogStore
{
    Task<SearchResult> SearchAsync(string key, int limit, string? cursor, string? state, string? kind, CancellationToken ct);
    Task<FoodRecord?> GetAsync(string id, CancellationToken ct);
    Task<PackRecord?> PackAsync(int? version, CancellationToken ct);
}
