using System.Reflection;
using System.Text.Json;
using System.Text.Json.Nodes;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using FitnessBuddy.TestData;

namespace FitnessBuddy.UserData.Tests;

// B20: measurementType/measurement v1 admission is the schema plus exactly the README's measurement
// wire rules M1–M3 (MeasurementPayloadValidator), live and as full tombstones.
[Trait("Req", "WB-040")]
[Trait("Req", "WB-041")]
[Trait("Req", "WB-042")]
[Trait("Req", "AC-010")]
public sealed class MeasurementPayloadTests
{
    private static readonly bool[] LiveAndTombstone = [false, true];
    private static readonly string[] Asymmetries = ["schemaOnly", "generic", "decimalPrecision"];
    private static readonly string[] OneVersion = ["1"];
    private static readonly Lazy<Dictionary<string, MeasurementCase>> Matrix = new(() => MeasurementCases.All().ToDictionary(c => c.Id, StringComparer.Ordinal));
    private const string TypeId = "0199e3c2-5b1a-7c3d-8e4f-0123456789ab";

    private static JsonDocument Embedded() => JsonDocument.Parse(typeof(SyncPayloads).Assembly.GetManifestResourceStream(
        "FitnessBuddy.Modules.UserData.Infrastructure.Schemas.entities.json")!);

    private static string? Admit(string entity, Guid id, string raw, bool tombstone = false, int version = 1)
    {
        using var payload = JsonDocument.Parse(raw);
        return SyncPayloads.InvalidReason(new SyncVersion(entity, id, version, "unused", Guid.NewGuid(),
            tombstone ? DateTimeOffset.UnixEpoch : null, payload.RootElement));
    }

    // Live and as a full tombstone: tombstones carry the payload and get the same rules (D3, 05 §5.5).
    private static void AssertAdmission(bool valid, string entity, Guid id, string raw, string because)
    {
        foreach (var tombstone in LiveAndTombstone)
        { Assert.True((valid ? null : "invalidPayload") == Admit(entity, id, raw, tombstone), $"{because} (tombstone={tombstone})"); }
    }

    [Fact, Trait("Rule", "B20.embedded-schema-equals-corpus")]
    public void Embedded_schema_vocabularies_and_bounds_equal_contract_and_corpus()
    {
        using var corpus = MeasurementCases.ReadCorpus();
        using var embedded = Embedded();
        using var contract = MeasurementCases.Read("sync-entities.json");
        var constants = corpus.RootElement.GetProperty("constants");
        Assert.Equal(["customKind", "maxMeasuredAtUtc", "maxNameLength", "maxOriginLength", "maxPercent", "maxValue", "percentKind", "percentUnit", "tzOffsetMax", "tzOffsetMin"],
            constants.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
        var maxInstant = constants.GetProperty("maxMeasuredAtUtc").GetDecimal();
        Assert.Equal(9007199254740991m, maxInstant);
        foreach (var entity in MeasurementCases.Entities)
        {
            // The server enforces the embedded registry; it must be the contract, in meaning.
            var schema = embedded.RootElement.GetProperty("entities").GetProperty(entity);
            Assert.True(JsonElement.DeepEquals(contract.RootElement.GetProperty("entities").GetProperty(entity), schema), entity);
            Assert.Equal(OneVersion, schema.EnumerateObject().Select(p => p.Name));
            var version = schema.GetProperty("1");
            Assert.False(version.GetProperty("additionalProperties").GetBoolean());
            Assert.Equal(version.GetProperty("properties").EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal),
                version.GetProperty("required").EnumerateArray().Select(v => v.GetString()!).Order(StringComparer.Ordinal));
            // Metadata bounds (plan review round 1): createdAtMs 0 … 2^53−1, origin ≤ maxOriginLength.
            var properties = version.GetProperty("properties");
            AssertRange(properties.GetProperty("createdAtMs"), 0m, maxInstant);
            Assert.Equal(constants.GetProperty("maxOriginLength").GetInt32(), properties.GetProperty("origin").GetProperty("maxLength").GetInt32());
        }
        var type = Properties(embedded, "measurementType");
        Assert.Equal(constants.GetProperty("maxNameLength").GetInt32(), type.GetProperty("name").GetProperty("maxLength").GetInt32());
        var measurement = Properties(embedded, "measurement");
        AssertRange(measurement.GetProperty("measuredAtUtc"), 0m, maxInstant);
        AssertRange(measurement.GetProperty("tzOffsetMin"), constants.GetProperty("tzOffsetMin").GetDecimal(), constants.GetProperty("tzOffsetMax").GetDecimal());
        AssertRange(measurement.GetProperty("value"), 0m, constants.GetProperty("maxValue").GetDecimal());
        AssertRange(measurement.GetProperty("inputValue"), 0m, constants.GetProperty("maxValue").GetDecimal());
        Assert.Equal("uuid", measurement.GetProperty("customTypeId").GetProperty("format").GetString());
        // Closed codes in contract order.
        var words = corpus.RootElement.GetProperty("vocabularies");
        Assert.Equal(["inputUnit", "kind"], words.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
        foreach (var field in new[] { "kind", "inputUnit" })
        { Assert.Equal(Strings(words.GetProperty(field)), Strings(measurement.GetProperty(field).GetProperty("enum"))); }
    }

    private static void AssertRange(JsonElement property, decimal minimum, decimal maximum)
    {
        Assert.Equal(minimum, property.GetProperty("minimum").GetDecimal());
        Assert.Equal(maximum, property.GetProperty("maximum").GetDecimal());
    }

    [Fact, Trait("Rule", "B20.validator-constants")]
    public void Validator_constants_equal_corpus()
    {
        using var corpus = MeasurementCases.ReadCorpus();
        var constants = corpus.RootElement.GetProperty("constants");
        Assert.Equal(MeasurementPayloadValidator.MaxPercent, constants.GetProperty("maxPercent").GetDecimal());
        Assert.Equal(MeasurementPayloadValidator.CustomKind, constants.GetProperty("customKind").GetString());
        Assert.Equal(MeasurementPayloadValidator.PercentKind, constants.GetProperty("percentKind").GetString());
        Assert.Equal(MeasurementPayloadValidator.PercentUnit, constants.GetProperty("percentUnit").GetString());
        var words = corpus.RootElement.GetProperty("vocabularies");
        Assert.Contains(MeasurementPayloadValidator.CustomKind, Strings(words.GetProperty("kind")));
        Assert.Contains(MeasurementPayloadValidator.PercentKind, Strings(words.GetProperty("kind")));
        Assert.Contains(MeasurementPayloadValidator.PercentUnit, Strings(words.GetProperty("inputUnit")));
    }

    [Fact, Trait("Rule", "B20.fail-closed-dispatch")]
    public void Measurement_validator_fails_closed_for_unregistered_versions_and_other_entities()
    {
        foreach (var entity in MeasurementCases.Entities)
        {
            using var payload = JsonDocument.Parse(MeasurementCases.Baseline(entity));
            var version = new SyncVersion(entity, MeasurementCases.NewId(entity), 1, "unused", Guid.NewGuid(), null, payload.RootElement);
            Assert.True(MeasurementPayloadValidator.Matches(version), entity);
            foreach (var unknown in new[] { 0, 2, 3, -1, int.MaxValue })
            { Assert.False(MeasurementPayloadValidator.Matches(version with { SchemaVersion = unknown }), $"{entity} v{unknown}"); }
            // Through admission an unregistered version is unsupported before any rule runs.
            Assert.Equal("unsupported", SyncPayloads.InvalidReason(version with { SchemaVersion = 2 }));
            // An entity the validator doesn't own never matches.
            Assert.False(MeasurementPayloadValidator.Matches(version with { Entity = "weighIn" }));
        }
        foreach (var other in new[] { "weighIn", "profile", "personalFood", "chatMessage", "Measurement", "measurements", "" })
        { Assert.False(MeasurementPayloadValidator.Covers(other), other); }
    }

    [Fact, Trait("Rule", "B20.readme-rules")]
    public void Readme_measurement_rules_equal_corpus_rules_and_each_has_accept_and_reject_cases()
    {
        var readme = File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "contracts-README.md")).ReplaceLineEndings("\n");
        var section = readme.Split("## Measurement semantic rules (measurementType, measurement)\n", StringSplitOptions.None)[1];
        section = section[..section.IndexOf("\n## ", StringComparison.Ordinal)];
        // The wire-rule bullets only: "Not wire rules" is the exclusion bullet.
        var labels = section.Split('\n').Where(line => line.StartsWith("- **", StringComparison.Ordinal))
            .Select(line => line[4..line.IndexOf(":**", StringComparison.Ordinal)]).Where(label => label != "Not wire rules").ToArray();
        Assert.Equal(["M1 custom type", "M2 unit fits kind", "M3 percent bound"], labels);
        using var corpus = MeasurementCases.ReadCorpus();
        var rules = corpus.RootElement.GetProperty("rules").EnumerateArray().ToArray();
        Assert.Equal(labels, rules.Select(r => r.GetProperty("readme").GetString()!));
        Assert.Equal(["M1", "M2", "M3"], rules.Select(r => r.GetProperty("id").GetString()!));
        var tagged = MeasurementCases.Corpus().Where(c => c.Rule is not null).ToArray();
        Assert.All(tagged, c => Assert.Contains(c.Rule!, labels));
        Assert.All(tagged, c => Assert.Equal("measurement", c.Entity));
        foreach (var label in labels)
        {
            Assert.Contains(tagged, c => c.Rule == label && c.Valid);
            Assert.Contains(tagged, c => c.Rule == label && !c.Valid);
            // Each declared outcome holds on the server.
            Assert.All(tagged.Where(c => c.Rule == label), c => AssertAdmission(c.Valid, c.Entity, MeasurementCases.IdOf(c), c.Raw, c.Id));
        }
    }

    [Fact, Trait("Rule", "B20.corpus-agreement")]
    public void Corpus_declarations_agree_with_admission_and_derived_lists()
    {
        using var corpus = MeasurementCases.ReadCorpus();
        var root = corpus.RootElement;
        Assert.Equal(1, root.GetProperty("version").GetInt32());
        var items = root.GetProperty("payloads").EnumerateArray().ToArray();
        var cases = MeasurementCases.Corpus();
        Assert.Equal(185, cases.Count);
        Assert.Equal(cases.Count, cases.Select(c => c.Id).Distinct(StringComparer.Ordinal).Count());
        Assert.All(items, i => Assert.Equal(1, i.GetProperty("schemaVersion").GetInt32()));
        Assert.All(cases, c => Assert.Contains(c.Entity, MeasurementCases.Entities));
        // Closed asymmetry set; every tagged case is a server rejection.
        Assert.All(cases.Where(c => c.Asymmetry is not null), c => Assert.Contains(c.Asymmetry!, Asymmetries));
        Assert.All(cases.Where(c => c.Asymmetry is not null), c => Assert.False(c.Valid, c.Id));
        // measurementType has no wire rules: every rejection is the schema's or generic.
        Assert.All(cases.Where(c => c.Entity == "measurementType"), c => Assert.Equal(c.Valid, c.Asymmetry is null));
        // rowId only on the v4 row-ID case, which is admitted (no row-ID rule).
        Assert.Equal(["notWire-convention-rowId-v4"], cases.Where(c => c.RowId is not null).Select(c => c.Id));
        // <id>-tombstone repeats <id>'s payload as a tombstone.
        foreach (var tombstone in cases.Where(c => c.Id.EndsWith("-tombstone", StringComparison.Ordinal)))
        {
            var live = MeasurementCases.Case(tombstone.Id[..^"-tombstone".Length]);
            Assert.True(tombstone.Deleted && !live.Deleted, tombstone.Id);
            Assert.Equal((live.Raw, live.Entity, live.RowId, live.Valid, live.Rule), (tombstone.Raw, tombstone.Entity, tombstone.RowId, tombstone.Valid, tombstone.Rule));
        }
        Assert.Equal(Strings(root.GetProperty("serverRejectsAppTolerates")),
            items.Where(c => !c.GetProperty("serverAccepts").GetBoolean() && c.GetProperty("appReads").ValueKind == JsonValueKind.True).Select(c => c.GetProperty("id").GetString()!));
        Assert.Equal(Strings(root.GetProperty("serverAcceptsAppSkips")),
            items.Where(c => c.GetProperty("serverAccepts").GetBoolean() && c.GetProperty("appReads").ValueKind == JsonValueKind.False).Select(c => c.GetProperty("id").GetString()!));
        // Scrubbed tombstones (D8): admissible while they keep the M1–M3 pairing.
        foreach (var id in new[] { "measurementType-tombstone-scrubbed", "measurement-tombstone-scrubbed-waist", "measurement-tombstone-scrubbed-bodyFat", "measurement-tombstone-scrubbed-custom" })
        { Assert.True(MeasurementCases.Case(id).Valid && MeasurementCases.Case(id).Deleted, id); }
        Assert.False(MeasurementCases.Case("measurement-tombstone-scrubbed-custom-null-type").Valid);
        foreach (var writer in root.GetProperty("writerCases").EnumerateArray())
        {
            var payload = MeasurementCases.Case(writer.GetProperty("payloadId").GetString()!);
            Assert.True(payload.Valid); Assert.Equal(writer.GetProperty("entity").GetString(), payload.Entity);
        }
        // One readable failure listing every disagreeing case, live or tombstone.
        var disagreements = cases
            .SelectMany(c => LiveAndTombstone.Where(t => (c.Valid ? null : "invalidPayload") != Admit(c.Entity, MeasurementCases.IdOf(c), c.Raw, t))
                .Select(t => $"{c.Id}{(t ? " (tombstone)" : "")}"))
            .ToArray();
        Assert.Empty(disagreements);
    }

    public static TheoryData<string> Payloads() => new(Matrix.Value.Keys);

    [Theory, MemberData(nameof(Payloads)), Trait("Rule", "05.5-payload-validation")]
    public void Payload_matrix_matches_admission_for_live_and_tombstone(string id)
    {
        var test = Matrix.Value[id];
        AssertAdmission(test.Valid, test.Entity, MeasurementCases.IdOf(test), test.Raw, id);
    }

    [Fact, Trait("Rule", "05.5-payload-validation")]
    public void Schema_matrix_covers_every_field_fixture_and_variant()
    {
        using var embedded = Embedded();
        var ids = Matrix.Value.Keys.ToHashSet(StringComparer.Ordinal);
        foreach (var entity in MeasurementCases.Entities)
        {
            foreach (var field in Properties(embedded, entity).EnumerateObject())
            {
                foreach (var shape in new[] { "missing", "null", "type-array", "type-object", "type-scalar" })
                { Assert.Contains($"{entity}-schema-{shape}-{field.Name}", ids); }
            }
            Assert.Contains($"{entity}-schema-extra-field", ids);
            Assert.Contains($"fixture-{entity}", ids);
        }
        Assert.Equal(3, ids.Count(id => id.StartsWith("variant-", StringComparison.Ordinal)));
    }

    public static TheoryData<string> WireRules() => new("M1", "M2", "M3");

    // Hand-built from the corpus bases, independent of the generator's declarations.
    [Theory, MemberData(nameof(WireRules)), Trait("Rule", "B20.wire-rules")]
    public void Wire_rules_accept_valid_and_reject_each_violation(string rule)
    {
        var cases = WireRuleCases(rule);
        Assert.Contains(cases, c => c.Valid);
        Assert.Contains(cases, c => !c.Valid);
        foreach (var (name, raw, valid) in cases) { AssertAdmission(valid, "measurement", MeasurementCases.NewId("measurement"), raw, $"{rule}: {name}"); }
    }

    private static string[] Kinds()
    {
        using var corpus = MeasurementCases.ReadCorpus();
        return Strings(corpus.RootElement.GetProperty("vocabularies").GetProperty("kind")).ToArray();
    }

    // A waist-based row of [kind] with [unit], a type ID exactly for custom, and [value] for both numbers.
    private static string Row(string kind, string unit, string value, bool? typed = null)
    {
        var raw = MeasurementCases.With(MeasurementCases.Baseline("measurement"), "kind", kind);
        raw = MeasurementCases.With(raw, "inputUnit", unit);
        raw = MeasurementCases.With(raw, "customTypeId", JsonValue.Create((typed ?? kind == "custom") ? TypeId : null));
        return MeasurementCases.WithRaw(MeasurementCases.WithRaw(raw, "value", value), "inputValue", value);
    }

    private static List<(string Name, string Raw, bool Valid)> WireRuleCases(string rule)
    {
        var cases = new List<(string Name, string Raw, bool Valid)>();
        string UnitOf(string kind) => kind == "bodyFat" ? "percent" : "cm";
        switch (rule)
        {
            case "M1":
                foreach (var kind in Kinds())
                {
                    foreach (var typed in new[] { false, true })
                    { cases.Add(($"{kind} typed={typed}", Row(kind, UnitOf(kind), "18.4", typed), typed == (kind == "custom"))); }
                }
                break;
            case "M2":
                foreach (var kind in Kinds())
                {
                    foreach (var unit in new[] { "cm", "in", "percent" })
                    { cases.Add(($"{kind} {unit}", Row(kind, unit, "18.4"), (unit == "percent") == (kind == "bodyFat"))); }
                }
                break;
            case "M3":
                foreach (var field in new[] { "value", "inputValue" })
                {
                    foreach (var (value, valid) in new[]
                    {
                        ("0", true), ("-0.0", true), ("18.4", true), ("100", true), ("100.0", true), ("100.000", true), ("1e2", true),
                        ("100.0000001", false), ("100.0000000000000001", false), ("100.01", false), ("101", false), ("1000000", false),
                    })
                    { cases.Add(($"bodyFat {field}={value}", MeasurementCases.WithRaw(Row("bodyFat", "percent", "18.4"), field, value), valid)); }
                }
                // M3 bounds body fat only.
                foreach (var kind in Kinds().Where(k => k != "bodyFat"))
                {
                    foreach (var value in new[] { "100.01", "150", "1000000" })
                    { cases.Add(($"{kind} {value} cm", Row(kind, "cm", value), true)); }
                }
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(rule), rule, "unknown rule");
        }
        return cases;
    }

    [Fact, Trait("Rule", "05.5-payload-validation")]
    public void Numbers_reject_nan_infinity_overflow_and_unrepresentable()
    {
        string[] bad = ["\"NaN\"", "\"Infinity\"", "\"-Infinity\"", "1e400", "-1e400", "1e-400", "1e-29", "1.000000000000000000000000000001", "79228162514264337593543950336"];
        using var embedded = Embedded();
        var checkedFields = 0;
        foreach (var (entity, baseline) in new[]
        {
            ("measurementType", MeasurementCases.Baseline("measurementType")),
            ("measurement", MeasurementCases.Baseline("measurement")),
            ("measurement", MeasurementCases.Raw("measurement-base-bodyFat")),
        })
        {
            foreach (var field in Properties(embedded, entity).EnumerateObject())
            {
                var type = field.Value.GetProperty("type");
                if (type.ValueKind != JsonValueKind.String || type.GetString() is not ("number" or "integer")) { continue; }
                checkedFields++;
                foreach (var value in bad)
                {
                    // Never an exception or a 500: always the bare invalidPayload.
                    AssertAdmission(false, entity, MeasurementCases.NewId(entity), MeasurementCases.WithRaw(baseline, field.Name, value), $"{entity} {field.Name}={value}");
                }
            }
        }
        Assert.Equal(11, checkedFields);
    }

    // D3: plausibility, the unit factor, the local date, the type reference and the row-ID version are
    // not wire rules. The validator sees one SyncVersion and holds no state, so it cannot reject a
    // row because of another (TD-089).
    [Fact, Trait("Rule", "B20.no-plausibility")]
    public void Not_wire_rules_are_admitted()
    {
        var outliers = MeasurementCases.Corpus().Where(c => c.Id.StartsWith("notWire-", StringComparison.Ordinal)).ToArray();
        Assert.True(outliers.Length >= 13, $"{outliers.Length}");
        Assert.All(outliers, test => AssertAdmission(true, test.Entity, MeasurementCases.IdOf(test), test.Raw, test.Id));
        var waist = MeasurementCases.Baseline("measurement");
        var bodyFat = MeasurementCases.Raw("measurement-base-bodyFat");
        var custom = MeasurementCases.Raw("measurement-base-custom-cm");
        var type = MeasurementCases.Baseline("measurementType");
        foreach (var (name, entity, raw) in new[]
        {
            ("waist 0.1 cm", "measurement", MeasurementCases.WithRaw(MeasurementCases.WithRaw(waist, "value", "0.1"), "inputValue", "0.1")),
            ("waist 1e6 cm", "measurement", MeasurementCases.WithRaw(MeasurementCases.WithRaw(waist, "value", "1000000"), "inputValue", "1000000")),
            ("body fat 0.5 %", "measurement", MeasurementCases.WithRaw(MeasurementCases.WithRaw(bodyFat, "value", "0.5"), "inputValue", "0.5")),
            ("body fat 99.9 %", "measurement", MeasurementCases.WithRaw(MeasurementCases.WithRaw(bodyFat, "value", "99.9"), "inputValue", "99.9")),
            ("inches without the factor", "measurement", MeasurementCases.With(waist, "inputUnit", "in")),
            ("local date far from the instant", "measurement", MeasurementCases.With(waist, "localDate", "1999-12-31")),
            ("another type", "measurement", MeasurementCases.With(custom, "customTypeId", Guid.NewGuid().ToString())),
            ("max type ID", "measurement", MeasurementCases.With(custom, "customTypeId", "ffffffff-ffff-ffff-ffff-ffffffffffff")),
            ("blank name", "measurementType", MeasurementCases.With(type, "name", "   ")),
            ("duplicate-looking name", "measurementType", MeasurementCases.With(type, "name", "LEFT ARM")),
            ("emoji name", "measurementType", MeasurementCases.With(type, "name", "💪")),
        })
        { AssertAdmission(true, entity, MeasurementCases.NewId(entity), raw, name); }
        foreach (var id in new[] { Guid.NewGuid(), Guid.CreateVersion7(), Guid.Empty, Guid.AllBitsSet, new Guid("4e5d373d-7494-53a9-b84b-facb16b0cb21") })
        {
            AssertAdmission(true, "measurement", id, waist, $"row ID {id}");
            AssertAdmission(true, "measurementType", id, type, $"type row ID {id}");
        }
        var matches = typeof(MeasurementPayloadValidator).GetMethod(nameof(MeasurementPayloadValidator.Matches), BindingFlags.Public | BindingFlags.Static)!;
        Assert.Equal([typeof(SyncVersion)], matches.GetParameters().Select(p => p.ParameterType));
        Assert.All(typeof(MeasurementPayloadValidator).GetFields(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static), f => Assert.True(f.IsLiteral || f.IsInitOnly, f.Name));
    }

    private static JsonElement Properties(JsonDocument registry, string entity) =>
        registry.RootElement.GetProperty("entities").GetProperty(entity).GetProperty("1").GetProperty("properties");

    private static IEnumerable<string> Strings(JsonElement value) => value.EnumerateArray().Select(v => v.GetString()!);
}
