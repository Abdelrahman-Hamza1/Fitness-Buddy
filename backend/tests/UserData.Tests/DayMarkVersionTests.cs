using System.Text.Json;
using System.Text.Json.Nodes;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using FitnessBuddy.TestData;

namespace FitnessBuddy.UserData.Tests;

// A62b: dayMark v1 (A01) and v2 (v1 + estimateKcal + estimateOnly, DY-006) are each admitted only under their own
// schema version. Everything is in the schema (contracts/README.md § dayMark versions): no validator.
[Trait("Req", "DY-006")]
[Trait("Req", "AC-010")]
public sealed class DayMarkVersionTests
{
    private const string Entity = "dayMark";
    private static readonly bool[] LiveAndTombstone = [false, true];

    private static string? Admit(int version, string raw, bool tombstone)
    {
        using var payload = JsonDocument.Parse(raw);
        return SyncPayloads.InvalidReason(new SyncVersion(Entity, Guid.CreateVersion7(), version, "unused", Guid.NewGuid(),
            tombstone ? DateTimeOffset.UnixEpoch : null, payload.RootElement));
    }

    private static void AssertAdmission(bool valid, int version, string raw, string because)
    {
        foreach (var tombstone in LiveAndTombstone)
        { Assert.True((valid ? null : "invalidPayload") == Admit(version, raw, tombstone), $"{because} (tombstone={tombstone})"); }
    }

    [Fact, Trait("Rule", "A62.versions")]
    public void DayMark_v1_and_v2_are_each_admitted_only_by_their_own_schema()
    {
        var v1 = DiaryEstimateCases.Fixture(Entity, 1);
        var v2 = DiaryEstimateCases.Fixture(Entity, 2);
        AssertAdmission(true, 1, v1, "v1 fixture as v1");
        AssertAdmission(true, 2, v2, "v2 fixture as v2");
        AssertAdmission(false, 2, v1, "v1 payload sent as v2 (missing estimateKcal)");
        AssertAdmission(false, 1, v2, "v2 payload sent as v1 (extra field)");
        foreach (var raw in new[] { v1, v2 })
        {
            foreach (var version in new[] { 0, 3, 999 })
            { Assert.Equal("unsupported", Admit(version, raw, tombstone: false)); }
        }
    }

    [Fact, Trait("Rule", "A62.versions")]
    public void DY_006_estimateOnly_is_a_required_boolean()
    {
        // estimateOnly (A62b review fix): the mark exists only to hold the estimate; app-local
        // semantics, the server only checks its type.
        var v2 = DiaryEstimateCases.Fixture(Entity, 2);
        foreach (var (value, valid) in new (string, bool)[]
        {
            ("true", true), ("false", true), ("null", false), ("0", false), ("1", false), ("\"true\"", false), ("[]", false),
        })
        { AssertAdmission(valid, 2, BodyTargetsCases.WithRaw(v2, "estimateOnly", value), $"estimateOnly {value}"); }
        // A marked day with an estimate and a cleared estimate-only mark (its tombstone) are both v2 shapes.
        AssertAdmission(true, 2, BodyTargetsCases.With(BodyTargetsCases.With(v2, "estimateOnly", false), "incomplete", true), "marked + estimate");
        AssertAdmission(true, 2, BodyTargetsCases.WithRaw(v2, "estimateKcal", "null"), "estimate-only without estimate");
    }

    [Fact, Trait("Rule", "A62.versions")]
    public void DY_006_estimateKcal_is_null_or_a_number_from_1_to_20000()
    {
        var v2 = DiaryEstimateCases.Fixture(Entity, 2);
        foreach (var (value, valid) in new (string, bool)[]
        {
            ("null", true), ("1", true), ("1.0", true), ("2300.5", true), ("20000", true), ("20000.0", true),
            ("0", false), ("0.5", false), ("-1", false), ("20000.01", false), ("20001", false),
            ("\"2300\"", false), ("true", false), ("[]", false), ("{}", false),
        })
        { AssertAdmission(valid, 2, BodyTargetsCases.WithRaw(v2, "estimateKcal", value), $"estimateKcal {value}"); }
        // A cleared estimate keeps the row's other fields; the v1 flags stay required in v2.
        AssertAdmission(true, 2, BodyTargetsCases.With(BodyTargetsCases.WithRaw(v2, "estimateKcal", "null"), "incomplete", true), "cleared + incomplete");
        foreach (var field in new[] { "localDate", "incomplete", "notFasting", "estimateKcal", "estimateOnly" })
        {
            var payload = JsonNode.Parse(v2)!.AsObject();
            payload.Remove(field);
            AssertAdmission(false, 2, payload.ToJsonString(), $"v2 without {field}");
        }
    }
}
