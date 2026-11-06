using System.Text.Json;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using FitnessBuddy.TestData;

namespace FitnessBuddy.UserData.Tests;

// A62a: diaryEntry/savedMealItem v1 admission is the schema; v2 is the schema plus exactly the
// README's wire rules W1–W3 (DiaryEstimatePayloadValidator), live and as full tombstones.
[Trait("Req", "DY-005")]
[Trait("Req", "AC-010")]
public sealed class DiaryEstimatePayloadTests
{
    private static readonly bool[] LiveAndTombstone = [false, true];
    private static readonly string[] V2Fields = ["userEstimate", "proteinKnown", "carbsKnown", "fatKnown", "fiberKnown"];

    private static JsonDocument Embedded() => JsonDocument.Parse(typeof(SyncPayloads).Assembly.GetManifestResourceStream(
        "FitnessBuddy.Modules.UserData.Infrastructure.Schemas.entities.json")!);

    private static string? Admit(string entity, int version, string raw, bool tombstone = false)
    {
        using var payload = JsonDocument.Parse(raw);
        return SyncPayloads.InvalidReason(new SyncVersion(entity, Guid.CreateVersion7(), version, "unused", Guid.NewGuid(),
            tombstone ? DateTimeOffset.UnixEpoch : null, payload.RootElement));
    }

    private static void AssertAdmission(bool valid, string entity, int version, string raw, string because)
    {
        foreach (var tombstone in LiveAndTombstone)
        { Assert.True((valid ? null : "invalidPayload") == Admit(entity, version, raw, tombstone), $"{because} (tombstone={tombstone})"); }
    }

    [Fact, Trait("Rule", "A62.shared-vectors")]
    public void Every_corpus_case_is_admitted_exactly_when_serverAccepts()
    {
        var cases = DiaryEstimateCases.Corpus();
        Assert.NotEmpty(cases);
        foreach (var test in cases) { AssertAdmission(test.Valid, test.Entity, test.SchemaVersion, test.Raw, test.Id); }
        // Each rule is rejected for both entities, and each entity has accepted v1 and v2 cases.
        using var corpus = DiaryEstimateCases.Read(DiaryEstimateCases.CorpusFile);
        var rules = corpus.RootElement.GetProperty("rules").EnumerateArray().Select(r => r.GetProperty("readme").GetString()!).ToArray();
        Assert.Equal(["W1", "W2", "W3"], corpus.RootElement.GetProperty("rules").EnumerateArray().Select(r => r.GetProperty("id").GetString()!));
        foreach (var entity in DiaryEstimateCases.Entities)
        {
            foreach (var rule in rules) { Assert.Contains(cases, c => c.Entity == entity && c.Rule == rule && !c.Valid); }
            Assert.Contains(cases, c => c.Entity == entity && c.SchemaVersion == 1 && c.Valid);
            Assert.Contains(cases, c => c.Entity == entity && c.SchemaVersion == 2 && c.Valid);
        }
        // The only asymmetry: wire-valid payloads that the declared version's schema rejects.
        Assert.All(cases.Where(c => c.Asymmetry is not null), c => Assert.Equal(("schemaOnly", false), (c.Asymmetry, c.Valid)));
    }

    [Fact, Trait("Rule", "A62.embedded-schema-equals-contract")]
    public void V2_is_v1_plus_five_required_booleans_and_the_registry_is_the_contract()
    {
        using var embedded = Embedded();
        using var contract = DiaryEstimateCases.Read("sync-entities.json");
        using var corpus = DiaryEstimateCases.Read(DiaryEstimateCases.CorpusFile);
        Assert.Equal(V2Fields, corpus.RootElement.GetProperty("constants").GetProperty("v2Fields").EnumerateArray().Select(v => v.GetString()!));
        foreach (var entity in DiaryEstimateCases.Entities)
        {
            var schema = embedded.RootElement.GetProperty("entities").GetProperty(entity);
            Assert.True(JsonElement.DeepEquals(contract.RootElement.GetProperty("entities").GetProperty(entity), schema), entity);
            Assert.Equal(["1", "2"], schema.EnumerateObject().Select(p => p.Name));
            var v1 = schema.GetProperty("1"); var v2 = schema.GetProperty("2");
            string[] Required(JsonElement version) => [.. version.GetProperty("required").EnumerateArray().Select(v => v.GetString()!)];
            string[] expected = [.. Required(v1), .. V2Fields];
            Assert.Equal(expected, Required(v2));
            Assert.Equal(v2.GetProperty("properties").EnumerateObject().Select(p => p.Name), Required(v2));
            Assert.False(v2.GetProperty("additionalProperties").GetBoolean());
            foreach (var field in v1.GetProperty("properties").EnumerateObject())
            { Assert.True(JsonElement.DeepEquals(field.Value, v2.GetProperty("properties").GetProperty(field.Name)), $"{entity}.{field.Name}"); }
            foreach (var field in V2Fields)
            { Assert.Equal("boolean", v2.GetProperty("properties").GetProperty(field).GetProperty("type").GetString()); }
        }
    }

    [Fact, Trait("Rule", "A62.validator-constants")]
    public void Validator_constants_equal_corpus()
    {
        using var corpus = DiaryEstimateCases.Read(DiaryEstimateCases.CorpusFile);
        var constants = corpus.RootElement.GetProperty("constants");
        Assert.Equal(DiaryEstimatePayloadValidator.FoodKind, constants.GetProperty("foodKind").GetString());
        Assert.Equal(DiaryEstimatePayloadValidator.Source, constants.GetProperty("source").GetString());
        Assert.Equal(DiaryEstimateCases.Entities, constants.GetProperty("entities").EnumerateArray().Select(v => v.GetString()!));
        Assert.Equal(DiaryEstimatePayloadValidator.Versions.Order(), constants.GetProperty("versions").EnumerateArray().Select(v => v.GetInt32()));
        Assert.Equal(DiaryEstimatePayloadValidator.Nutrients, constants.GetProperty("nutrients").EnumerateArray().Select(n =>
            (n.GetProperty("known").GetString()!, n.GetProperty("snapshot").GetString()!, n.GetProperty("per100").GetString()!)));
    }

    [Fact, Trait("Rule", "A62.fail-closed-dispatch")]
    public void Validator_fails_closed_for_unregistered_versions_and_other_entities()
    {
        foreach (var entity in DiaryEstimateCases.Entities)
        {
            foreach (var version in new[] { 1, 2 })
            {
                using var payload = JsonDocument.Parse(DiaryEstimateCases.Fixture(entity, version));
                var row = new SyncVersion(entity, Guid.CreateVersion7(), version, "unused", Guid.NewGuid(), null, payload.RootElement);
                Assert.True(DiaryEstimatePayloadValidator.Matches(row), $"{entity} v{version}");
                foreach (var unknown in new[] { 0, 3, -1, int.MaxValue })
                { Assert.False(DiaryEstimatePayloadValidator.Matches(row with { SchemaVersion = unknown }), $"{entity} v{unknown}"); }
                // Through admission an unregistered version is unsupported before any rule runs.
                Assert.Equal("unsupported", SyncPayloads.InvalidReason(row with { SchemaVersion = 3 }));
                Assert.False(DiaryEstimatePayloadValidator.Matches(row with { Entity = "weighIn" }));
            }
        }
        foreach (var other in new[] { "weighIn", "dayMark", "dishGroup", "savedMeal", "personalFood", "DiaryEntry", "diaryEntries", "" })
        { Assert.False(DiaryEstimatePayloadValidator.Covers(other), other); }
    }

    [Fact, Trait("Rule", "A62.versions")]
    public void Fixtures_are_admitted_only_under_their_own_version()
    {
        foreach (var entity in DiaryEstimateCases.Entities)
        {
            AssertAdmission(true, entity, 1, DiaryEstimateCases.Fixture(entity, 1), $"{entity} v1 fixture");
            AssertAdmission(true, entity, 2, DiaryEstimateCases.Fixture(entity, 2), $"{entity} v2 fixture");
            AssertAdmission(false, entity, 2, DiaryEstimateCases.Fixture(entity, 1), $"{entity} v1 as 2");
            AssertAdmission(false, entity, 1, DiaryEstimateCases.Fixture(entity, 2), $"{entity} v2 as 1");
        }
    }

    [Fact, Trait("Rule", "A62.downgrade-refusal"), Trait("Req", "DY-006")]
    public void Downgrade_refusal_covers_exactly_the_estimate_entities()
    {
        Assert.Equal(DiaryEstimateCases.DowngradeProtected.Order(StringComparer.Ordinal), SyncRules.DowngradeProtected.Order(StringComparer.Ordinal));
        foreach (var entity in DiaryEstimateCases.DowngradeProtected)
        {
            Assert.True(SyncRules.IsRefusedDowngrade(entity, 1, 2));
            Assert.False(SyncRules.IsRefusedDowngrade(entity, 2, 2));
            Assert.False(SyncRules.IsRefusedDowngrade(entity, 2, 1));
            Assert.False(SyncRules.IsRefusedDowngrade(entity, 1, 1));
        }
        // weighIn keeps last-write-wins across versions (B19); other entities have one version.
        Assert.False(SyncRules.IsRefusedDowngrade("weighIn", 1, 2));
        Assert.False(SyncRules.IsRefusedDowngrade("DiaryEntry", 1, 2));
    }
}
