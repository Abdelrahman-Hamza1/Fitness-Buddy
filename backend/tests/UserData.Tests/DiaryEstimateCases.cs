using System.Text.Json;

namespace FitnessBuddy.TestData;

// A62a: shared by the pure and the real HTTP tests so the diaryEntry/savedMealItem v1/v2 admission
// matrix cannot drift. Cases come from the Dart generator
// (contracts/testdata/sync/diary-estimate-validation-vectors.json, `make gen-diary-estimate-vectors`).
internal sealed record DiaryEstimateCase(string Id, string Entity, int SchemaVersion, string Raw, bool Valid, string? Rule, string? Asymmetry);

internal static class DiaryEstimateCases
{
    public const string CorpusFile = "diary-estimate-validation-vectors.json";
    public static readonly string[] Entities = ["diaryEntry", "savedMealItem"];

    // TD-114 (A62 D23): the entities whose lower schema versions are refused over a stored newer one.
    // dayMark joins in A62b (v2 estimateKcal); it has no row-local validator.
    public static readonly string[] DowngradeProtected = ["dayMark", "diaryEntry", "savedMealItem"];

    // An old client's edit of its v1 copy: same fields, another value.
    public static string EditedV1(string entity) => entity == "dayMark"
        ? BodyTargetsCases.With(Fixture(entity, 1), "incomplete", true)
        : BodyTargetsCases.With(Fixture(entity, 1), "kcal", 2.0m);

    private static readonly Lazy<IReadOnlyList<DiaryEstimateCase>> CorpusCases = new(LoadCorpus);

    public static JsonDocument Read(string file) => JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, file)));

    public static IReadOnlyList<DiaryEstimateCase> Corpus() => CorpusCases.Value;

    public static DiaryEstimateCase Case(string id) => Corpus().Single(c => c.Id == id);

    // Synthetic fixtures, one per entity and version (contracts/testdata/README.md).
    public static string Fixture(string entity, int version)
    {
        using var fixture = Read(version == 1 ? "entity-payloads.json" : $"entity-payloads-v{version}.json");
        return fixture.RootElement.GetProperty(entity).GetRawText();
    }

    private static DiaryEstimateCase[] LoadCorpus()
    {
        using var corpus = Read(CorpusFile);
        return corpus.RootElement.GetProperty("payloads").EnumerateArray().Select(item => new DiaryEstimateCase(
            item.GetProperty("id").GetString()!, item.GetProperty("entity").GetString()!, item.GetProperty("schemaVersion").GetInt32(),
            item.GetProperty("rawPayload").GetString()!, item.GetProperty("serverAccepts").GetBoolean(),
            item.TryGetProperty("rule", out var rule) ? rule.GetString() : null,
            item.TryGetProperty("asymmetry", out var asymmetry) ? asymmetry.GetString() : null)).ToArray();
    }
}
