using System.Reflection;
using System.Text.Json;
using System.Text.Json.Nodes;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using FitnessBuddy.TestData;

namespace FitnessBuddy.UserData.Tests;

// B19: profile/goalPhase/targetSettings v1 admission is the schema plus exactly the README's targets
// wire rules (TargetsPayloadValidator); weighIn v1 and v2 are each admitted by their own schema.
[Trait("Req", "TG-001")]
[Trait("Req", "TG-012")]
[Trait("Req", "TG-040")]
[Trait("Req", "WB-001")]
[Trait("Req", "WB-003")]
[Trait("Req", "AC-010")]
public sealed class BodyTargetsPayloadTests
{
    private static readonly bool[] LiveAndTombstone = [false, true];
    private static readonly string[] Asymmetries = ["schemaOnly", "generic", "rowId", "wholeNumberInteger", "decimalPrecision"];
    private static readonly string[] WeighInVersions = ["1", "2"];
    private static readonly string[] OneVersion = ["1"];
    private static readonly string[] V2Fields = ["tzOffsetMin", "inputValue", "inputUnit", "preferredForDay"];
    private static readonly Lazy<Dictionary<string, BodyTargetsCase>> Matrix = new(() => BodyTargetsCases.All().ToDictionary(c => c.Id, StringComparer.Ordinal));
    private static readonly Guid V4 = new("3b241101-e2bb-4255-8caf-4136c566a962");
    private static readonly Guid V5 = new("4e5d373d-7494-53a9-b84b-facb16b0cb21"); // naturalId('profile', 'other')

    private static JsonDocument Read(string file) => JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, file)));

    private static JsonDocument Embedded() => JsonDocument.Parse(typeof(SyncPayloads).Assembly.GetManifestResourceStream(
        "FitnessBuddy.Modules.UserData.Infrastructure.Schemas.entities.json")!);

    private static string? Admit(string entity, int version, Guid id, string raw, bool tombstone = false)
    {
        using var payload = JsonDocument.Parse(raw);
        return SyncPayloads.InvalidReason(new SyncVersion(entity, id, version, "unused", Guid.NewGuid(),
            tombstone ? DateTimeOffset.UnixEpoch : null, payload.RootElement));
    }

    // Live and as a full tombstone: tombstones carry the payload and get the same rules (D3, 05 §5.5).
    private static void AssertAdmission(bool valid, string entity, int version, Guid id, string raw, string because)
    {
        foreach (var tombstone in LiveAndTombstone)
        { Assert.True((valid ? null : "invalidPayload") == Admit(entity, version, id, raw, tombstone), $"{because} (tombstone={tombstone})"); }
    }

    [Fact, Trait("Rule", "B19.embedded-schema-equals-corpus")]
    public void Embedded_schema_bounds_and_vocabularies_equal_contract_and_corpus()
    {
        using var corpus = BodyTargetsCases.ReadCorpus();
        using var embedded = Embedded();
        using var contract = Read("sync-entities.json");
        var constants = corpus.RootElement.GetProperty("constants");
        var words = corpus.RootElement.GetProperty("vocabularies");
        Assert.Equal(["maxNameLength", "maxNumber", "maxPercent", "maxRevision", "profileRowId", "tzOffsetMax", "tzOffsetMin"],
            constants.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
        var maxNumber = constants.GetProperty("maxNumber").GetDecimal();
        foreach (var entity in new[] { "profile", "goalPhase", "targetSettings", "weighIn" })
        {
            // The server enforces the embedded registry; it must be the contract, in meaning.
            var schema = embedded.RootElement.GetProperty("entities").GetProperty(entity);
            Assert.True(JsonElement.DeepEquals(contract.RootElement.GetProperty("entities").GetProperty(entity), schema), entity);
            Assert.Equal(entity == "weighIn" ? WeighInVersions : OneVersion, schema.EnumerateObject().Select(p => p.Name));
            foreach (var version in schema.EnumerateObject().Select(p => p.Value))
            {
                Assert.False(version.GetProperty("additionalProperties").GetBoolean());
                Assert.Equal(version.GetProperty("properties").EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal),
                    version.GetProperty("required").EnumerateArray().Select(v => v.GetString()!).Order(StringComparer.Ordinal));
            }
        }
        // Technical bounds of the targets entities: every number is within 0 … maxNumber (the
        // signed rates within −maxNumber … maxNumber), revisions within 1 … maxRevision.
        foreach (var entity in BodyTargetsCases.TargetsEntities)
        {
            foreach (var field in Properties(embedded, entity, 1).EnumerateObject())
            {
                var types = field.Value.GetProperty("type");
                var type = types.ValueKind == JsonValueKind.Array ? types.EnumerateArray().First(t => t.GetString() != "null").GetString() : types.GetString();
                if (type == "number")
                {
                    Assert.Equal(maxNumber, field.Value.GetProperty("maximum").GetDecimal());
                    Assert.Equal(field.Name is "kgPerWeek" or "monthKg" ? -maxNumber : 0m, field.Value.GetProperty("minimum").GetDecimal());
                }
                if (field.Name == "revision")
                {
                    Assert.Equal(1m, field.Value.GetProperty("minimum").GetDecimal());
                    Assert.Equal(constants.GetProperty("maxRevision").GetDecimal(), field.Value.GetProperty("maximum").GetDecimal());
                }
            }
        }
        Assert.Equal(constants.GetProperty("maxNameLength").GetInt32(), Properties(embedded, "goalPhase", 1).GetProperty("name").GetProperty("maxLength").GetInt32());
        var v2 = Properties(embedded, "weighIn", 2);
        Assert.Equal(constants.GetProperty("tzOffsetMin").GetDecimal(), v2.GetProperty("tzOffsetMin").GetProperty("minimum").GetDecimal());
        Assert.Equal(constants.GetProperty("tzOffsetMax").GetDecimal(), v2.GetProperty("tzOffsetMin").GetProperty("maximum").GetDecimal());
        // Closed codes in contract order.
        var vocabularies = new (string Word, string Entity, int Version, string Field)[]
        {
            ("sex", "profile", 1, "sex"), ("heightInputUnit", "profile", 1, "heightInputUnit"), ("activity", "profile", 1, "activity"),
            ("goalType", "goalPhase", 1, "goalType"), ("expressionKind", "goalPhase", 1, "expressionKind"), ("weightInputUnit", "goalPhase", 1, "weightInputUnit"),
            ("mode", "targetSettings", 1, "mode"), ("inputUnit", "weighIn", 2, "inputUnit"),
        };
        Assert.Equal(vocabularies.Select(v => v.Word).Order(StringComparer.Ordinal), words.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
        foreach (var (word, entity, version, field) in vocabularies)
        { Assert.Equal(Strings(words.GetProperty(word)), Strings(Properties(embedded, entity, version).GetProperty(field).GetProperty("enum"))); }
        // S2: weighIn v2 is v1's properties (identical sub-schemas, same order) plus exactly the four A14 columns.
        var v1 = Properties(embedded, "weighIn", 1).EnumerateObject().ToArray();
        var v2Props = v2.EnumerateObject().ToArray();
        Assert.Equal(v1.Select(p => p.Name).Concat(V2Fields), v2Props.Select(p => p.Name));
        for (var i = 0; i < v1.Length; i++) { Assert.True(JsonElement.DeepEquals(v1[i].Value, v2Props[i].Value), v1[i].Name); }
    }

    [Fact, Trait("Rule", "B19.validator-constants")]
    public void Validator_constants_equal_corpus()
    {
        using var corpus = BodyTargetsCases.ReadCorpus();
        var constants = corpus.RootElement.GetProperty("constants");
        Assert.Equal(TargetsPayloadValidator.MaxPercent, constants.GetProperty("maxPercent").GetDecimal());
        var profileRowId = constants.GetProperty("profileRowId").GetGuid();
        Assert.Equal(profileRowId, TargetsPayloadValidator.ProfileRowId);
        Assert.Equal(profileRowId, SyncTestIds.ProfileRowId);
        Assert.Equal("f0b8e132-056c-5b98-8c9b-ff9a6dc1bb96", constants.GetProperty("profileRowId").GetString());
    }

    // D2 + S3: the targets dispatch fails closed, so its versions must be exactly the registry's;
    // B17's personalFood dispatch (SchemaVersion == 1) fails open, so its registry stays at {1}.
    [Fact, Trait("Rule", "B19.fail-closed-dispatch")]
    public void Registry_versions_equal_validator_versions_and_personalFood_stays_v1()
    {
        using var embedded = Embedded();
        var entities = embedded.RootElement.GetProperty("entities");
        foreach (var entity in BodyTargetsCases.TargetsEntities)
        {
            Assert.True(TargetsPayloadValidator.Covers(entity));
            Assert.Equal(TargetsPayloadValidator.Versions.Order(), entities.GetProperty(entity).EnumerateObject().Select(p => int.Parse(p.Name, System.Globalization.CultureInfo.InvariantCulture)).Order());
        }
        Assert.Equal(BodyTargetsCases.TargetsEntities.Order(StringComparer.Ordinal), entities.EnumerateObject().Select(e => e.Name).Where(TargetsPayloadValidator.Covers).Order(StringComparer.Ordinal));
        Assert.Equal(["1"], entities.GetProperty("personalFood").EnumerateObject().Select(p => p.Name));
    }

    [Fact, Trait("Rule", "B19.fail-closed-dispatch")]
    public void Targets_validator_fails_closed_for_unregistered_versions()
    {
        foreach (var entity in BodyTargetsCases.TargetsEntities)
        {
            using var payload = JsonDocument.Parse(BodyTargetsCases.Baseline(entity));
            var version = new SyncVersion(entity, BodyTargetsCases.NewId(entity), 1, "unused", Guid.NewGuid(), null, payload.RootElement);
            Assert.True(TargetsPayloadValidator.Matches(version), entity);
            foreach (var unknown in new[] { 0, 2, 3, -1, int.MaxValue })
            { Assert.False(TargetsPayloadValidator.Matches(version with { SchemaVersion = unknown }), $"{entity} v{unknown}"); }
            // Through admission an unregistered version is unsupported before any rule runs.
            Assert.Equal("unsupported", SyncPayloads.InvalidReason(version with { SchemaVersion = 2 }));
            // An entity the validator doesn't own never matches.
            Assert.False(TargetsPayloadValidator.Matches(version with { Entity = "weighIn" }));
        }
        foreach (var other in new[] { "weighIn", "personalFood", "chatMessage", "proposal", "mealSlot", "Profile", "" })
        { Assert.False(TargetsPayloadValidator.Covers(other), other); }
    }

    [Fact, Trait("Rule", "B19.readme-rules")]
    public void Readme_targets_rules_equal_corpus_rules_and_each_has_accept_and_reject_cases()
    {
        var readme = File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "contracts-README.md")).ReplaceLineEndings("\n");
        var section = readme.Split("## Targets semantic rules (profile, goalPhase, targetSettings)\n", StringSplitOptions.None)[1];
        section = section[..section.IndexOf("\n## ", StringComparison.Ordinal)];
        // The wire-rule bullets only: Tombstones/Corpus are paragraphs, "Not wire rules" is the exclusion bullet.
        var labels = section.Split('\n').Where(line => line.StartsWith("- **", StringComparison.Ordinal))
            .Select(line => line[4..line.IndexOf(":**", StringComparison.Ordinal)]).Where(label => label != "Not wire rules").ToArray();
        Assert.Equal(["Positive numbers", "Expression fields", "Maintain", "Phase dates", "Macro pairs", "Acknowledgement", "Row IDs"], labels);
        using var corpus = BodyTargetsCases.ReadCorpus();
        var rules = corpus.RootElement.GetProperty("rules").EnumerateArray().ToArray();
        Assert.Equal(labels, rules.Select(r => r.GetProperty("readme").GetString()!));
        Assert.Equal(["positiveNumbers", "expressionFields", "maintain", "phaseDates", "macroPairs", "acknowledgement", "rowIds"], rules.Select(r => r.GetProperty("id").GetString()!));
        var tagged = BodyTargetsCases.Corpus().Where(c => c.Rule is not null).ToArray();
        Assert.All(tagged, c => Assert.Contains(c.Rule!, labels));
        Assert.All(tagged, c => Assert.Contains(c.Entity, BodyTargetsCases.TargetsEntities));
        foreach (var label in labels)
        {
            Assert.Contains(tagged, c => c.Rule == label && c.Valid);
            Assert.Contains(tagged, c => c.Rule == label && !c.Valid);
            // Each declared outcome holds on the server.
            Assert.All(tagged.Where(c => c.Rule == label), c => AssertAdmission(c.Valid, c.Entity, c.SchemaVersion, BodyTargetsCases.IdOf(c), c.Raw, c.Id));
        }
    }

    [Fact, Trait("Rule", "B19.corpus-agreement")]
    public void Corpus_declarations_agree_with_admission_and_derived_lists()
    {
        using var corpus = BodyTargetsCases.ReadCorpus();
        var root = corpus.RootElement;
        Assert.Equal(1, root.GetProperty("version").GetInt32());
        var items = root.GetProperty("payloads").EnumerateArray().ToArray();
        var cases = BodyTargetsCases.Corpus();
        Assert.Equal(389, cases.Count);
        Assert.Equal(cases.Count, cases.Select(c => c.Id).Distinct(StringComparer.Ordinal).Count());
        Assert.All(cases, c => Assert.Contains((c.Entity, c.SchemaVersion), BodyTargetsCases.Pairs));
        // Closed asymmetry set; only the whole-number-integer spelling is server-accepted.
        Assert.All(cases.Where(c => c.Asymmetry is not null), c => Assert.Contains(c.Asymmetry!, Asymmetries));
        Assert.All(cases.Where(c => c.Asymmetry is not null), c => Assert.Equal(c.Asymmetry == "wholeNumberInteger", c.Valid));
        Assert.All(cases.Where(c => c.Asymmetry == "rowId"), c => Assert.Equal("Row IDs", c.Rule));
        // The rowId tag means the ID is the only reason: the same payload under the entity's default ID is admitted.
        var rowIdCases = cases.Where(c => c.Asymmetry == "rowId").ToArray();
        Assert.NotEmpty(rowIdCases);
        Assert.All(rowIdCases, c => AssertAdmission(true, c.Entity, c.SchemaVersion, BodyTargetsCases.NewId(c.Entity), c.Raw, $"{c.Id} with a default ID"));
        // rowId only where the row ID is the point.
        Assert.All(cases.Where(c => c.RowId is not null), c => Assert.Equal("Row IDs", c.Rule));
        Assert.All(cases.Where(c => c.Rule == "Row IDs"), c => Assert.NotNull(c.RowId));
        // <id>-tombstone repeats <id>'s payload as a tombstone.
        foreach (var tombstone in cases.Where(c => c.Id.EndsWith("-tombstone", StringComparison.Ordinal) && cases.Any(l => l.Id == c.Id[..^"-tombstone".Length])))
        {
            var live = BodyTargetsCases.Case(tombstone.Id[..^"-tombstone".Length]);
            Assert.True(tombstone.Deleted && !live.Deleted, tombstone.Id);
            Assert.Equal((live.Raw, live.Entity, live.SchemaVersion, live.RowId, live.Valid), (tombstone.Raw, tombstone.Entity, tombstone.SchemaVersion, tombstone.RowId, tombstone.Valid));
        }
        Assert.Equal(Strings(root.GetProperty("serverRejectsAppTolerates")),
            items.Where(c => !c.GetProperty("serverAccepts").GetBoolean() && c.GetProperty("appReads").ValueKind == JsonValueKind.True).Select(c => c.GetProperty("id").GetString()!));
        Assert.Equal(Strings(root.GetProperty("serverAcceptsAppSkips")),
            items.Where(c => c.GetProperty("serverAccepts").GetBoolean() && c.GetProperty("appReads").ValueKind == JsonValueKind.False).Select(c => c.GetProperty("id").GetString()!));
        Assert.Contains("weighIn2-tombstone-scrubbed", Strings(root.GetProperty("serverAcceptsAppSkips")));
        Assert.True(BodyTargetsCases.Case("weighIn2-tombstone-scrubbed").Valid);
        foreach (var writer in root.GetProperty("writerCases").EnumerateArray())
        {
            var payload = BodyTargetsCases.Case(writer.GetProperty("payloadId").GetString()!);
            Assert.True(payload.Valid); Assert.Equal(writer.GetProperty("entity").GetString(), payload.Entity);
        }
        // One readable failure listing every disagreeing case, live or tombstone.
        var disagreements = cases
            .SelectMany(c => LiveAndTombstone.Where(t => (c.Valid ? null : "invalidPayload") != Admit(c.Entity, c.SchemaVersion, BodyTargetsCases.IdOf(c), c.Raw, t))
                .Select(t => $"{c.Id}{(t ? " (tombstone)" : "")}"))
            .ToArray();
        Assert.Empty(disagreements);
    }

    public static TheoryData<string> Payloads() => new(Matrix.Value.Keys);

    [Theory, MemberData(nameof(Payloads)), Trait("Rule", "05.5-payload-validation")]
    public void Payload_matrix_matches_admission_for_live_and_tombstone(string id)
    {
        var test = Matrix.Value[id];
        AssertAdmission(test.Valid, test.Entity, test.SchemaVersion, BodyTargetsCases.IdOf(test), test.Raw, id);
    }

    [Fact, Trait("Rule", "05.5-payload-validation")]
    public void Schema_matrix_covers_every_field_of_the_five_entity_versions()
    {
        using var embedded = Embedded();
        var ids = Matrix.Value.Keys.ToHashSet(StringComparer.Ordinal);
        Assert.Equal(Matrix.Value.Count, BodyTargetsCases.All().Count);
        foreach (var (entity, version) in BodyTargetsCases.Pairs)
        {
            var label = BodyTargetsCases.Label(entity, version);
            foreach (var field in Properties(embedded, entity, version).EnumerateObject())
            {
                foreach (var shape in new[] { "missing", "null", "type-array", "type-object", "type-scalar" })
                { Assert.Contains($"{label}-schema-{shape}-{field.Name}", ids); }
            }
            Assert.Contains($"{label}-schema-extra-field", ids);
        }
    }

    public static TheoryData<string> WireRules() => new("R1-positive", "R2-expression-fields", "R3-target-rate-speed", "R4-maintain", "R5-phase-dates", "R6-macro-pairs", "R7-acknowledgement", "R8-row-ids");

    // Hand-built from the corpus bases, independent of the generator's declarations.
    [Theory, MemberData(nameof(WireRules)), Trait("Rule", "B19.wire-rules")]
    public void Wire_rules_accept_valid_and_reject_each_violation(string rule)
    {
        var cases = WireRuleCases(rule);
        Assert.Contains(cases, c => c.Valid);
        Assert.Contains(cases, c => !c.Valid);
        foreach (var (name, entity, id, raw, valid) in cases) { AssertAdmission(valid, entity, 1, id, raw, $"{rule}: {name}"); }
    }

    private static List<(string Name, string Entity, Guid Id, string Raw, bool Valid)> WireRuleCases(string rule)
    {
        var cases = new List<(string Name, string Entity, Guid Id, string Raw, bool Valid)>();
        var profile = BodyTargetsCases.Baseline("profile");
        var settings = BodyTargetsCases.Baseline("targetSettings");
        string Phase(string kind) => BodyTargetsCases.Raw($"goalPhase-base-{kind}");
        void Add(string name, string entity, string raw, bool valid, Guid? id = null) => cases.Add((name, entity, id ?? BodyTargetsCases.NewId(entity), raw, valid));
        switch (rule)
        {
            case "R1-positive":
                foreach (var (entity, raw, field) in new[] { ("profile", profile, "heightCm"), ("targetSettings", settings, "baseKcal"), ("targetSettings", settings, "basisWeightKg"), ("goalPhase", Phase("targetDate"), "targetKg"), ("goalPhase", Phase("targetRate"), "targetKg") })
                {
                    foreach (var (value, valid) in new[] { ("0", false), ("0.0", false), ("-0.0", false), ("-1.5", false), ("1e-28", true), ("0.0000000000000000000000000001", true), ("72.5", true) })
                    { Add($"{entity}.{field}={value}", entity, BodyTargetsCases.WithRaw(raw, field, value), valid); }
                }
                Add("goalPhase weekly targetKg null", "goalPhase", Phase("weekly"), true);
                break;
            case "R2-expression-fields":
                var present = new Dictionary<string, string> { ["targetKg"] = "70.0", ["targetDate"] = "\"2027-01-01\"", ["kgPerWeek"] = "0.5", ["monthKg"] = "1.0", ["month"] = "\"2026-12-01\"" };
                foreach (var kind in new[] { "targetDate", "targetRate", "weekly", "monthly" })
                {
                    var raw = Phase(kind);
                    Add($"{kind} exact", "goalPhase", raw, true);
                    using var parsed = JsonDocument.Parse(raw);
                    foreach (var (field, value) in present)
                    {
                        var toggled = parsed.RootElement.GetProperty(field).ValueKind == JsonValueKind.Null ? value : "null";
                        Add($"{kind} {field}={toggled}", "goalPhase", BodyTargetsCases.WithRaw(raw, field, toggled), false);
                    }
                }
                break;
            case "R3-target-rate-speed":
                foreach (var (value, valid) in new[] { ("0", false), ("-0.0", false), ("-0.5", false), ("0.5", true), ("1e-28", true) })
                { Add($"targetRate kgPerWeek={value}", "goalPhase", BodyTargetsCases.WithRaw(Phase("targetRate"), "kgPerWeek", value), valid); }
                // The target sets the direction: a gain goal still has a positive speed.
                Add("gain targetRate 0.5", "goalPhase", BodyTargetsCases.With(Phase("targetRate"), "goalType", "gain"), true);
                break;
            case "R4-maintain":
                var maintain = BodyTargetsCases.With(Phase("weekly"), "goalType", "maintain");
                foreach (var (value, valid) in new[] { ("0", true), ("0.0", true), ("-0.0", true), ("0e5", true), ("0.1", false), ("-0.1", false), ("1e-28", false) })
                { Add($"maintain weekly {value}", "goalPhase", BodyTargetsCases.WithRaw(maintain, "kgPerWeek", value), valid); }
                foreach (var kind in new[] { "targetDate", "targetRate", "monthly" })
                { Add($"maintain {kind}", "goalPhase", BodyTargetsCases.With(Phase(kind), "goalType", "maintain"), false); }
                break;
            case "R5-phase-dates":
                foreach (var (end, valid) in new[] { ("null", true), ("\"2026-10-28\"", true), ("\"2026-10-29\"", true), ("\"2026-10-27\"", false), ("\"2025-12-31\"", false), ("\"0001-01-01\"", false), ("\"9999-12-31\"", true) })
                { Add($"endDate {end}", "goalPhase", BodyTargetsCases.WithRaw(Phase("weekly"), "endDate", end), valid); }
                break;
            case "R6-macro-pairs":
                foreach (var macro in new[] { "protein", "fat", "carbs" })
                {
                    foreach (var (value, flag, valid) in new[]
                    {
                        ("null", "null", true), ("50.0", "null", false), ("null", "true", false), ("null", "false", false),
                        ("0", "true", true), ("100", "true", true), ("100.0", "true", true), ("100.000001", "true", false), ("100.0000000000000001", "true", false), ("101", "true", false),
                        ("5000", "false", true), ("100.5", "false", true),
                    })
                    { Add($"{macro} value={value} isPercent={flag}", "targetSettings", BodyTargetsCases.WithRaw(BodyTargetsCases.WithRaw(settings, $"{macro}Value", value), $"{macro}IsPercent", flag), valid); }
                }
                break;
            case "R7-acknowledgement":
                foreach (var (manual, acknowledged) in new[] { (false, false), (false, true), (true, false), (true, true) })
                { Add($"manual={manual} acknowledged={acknowledged}", "targetSettings", BodyTargetsCases.With(BodyTargetsCases.With(settings, "manual", manual), "acknowledged", acknowledged), !acknowledged || manual); }
                break;
            case "R8-row-ids":
                foreach (var (name, id, valid) in new[] { ("natural", SyncTestIds.ProfileRowId, true), ("v4", V4, false), ("other natural", V5, false), ("v7", Guid.CreateVersion7(), false), ("nil", Guid.Empty, false), ("max", Guid.AllBitsSet, false) })
                { Add($"profile id {name}", "profile", profile, valid, id); }
                foreach (var entity in new[] { "goalPhase", "targetSettings" })
                {
                    var raw = entity == "goalPhase" ? Phase("weekly") : settings;
                    foreach (var (name, id, valid) in new[]
                    {
                        ("v7", Guid.CreateVersion7(), true), ("v7 variant 8", new Guid("0199e3c2-5b1a-7c3d-8e4f-0123456789ae"), true), ("v7 variant b", new Guid("0199e3c2-5b1a-7c3d-bf4f-0123456789ae"), true),
                        ("v7 variant c", new Guid("0199e3c2-5b1a-7c3d-cf4f-0123456789ae"), false), ("v7 variant 0", new Guid("0199e3c2-5b1a-7c3d-0f4f-0123456789ae"), false),
                        ("v7 variant e", new Guid("0199e3c2-5b1a-7c3d-ef4f-0123456789ae"), false), ("v4", V4, false), ("v5", V5, false), ("natural profile", SyncTestIds.ProfileRowId, false),
                        ("nil", Guid.Empty, false), ("max", Guid.AllBitsSet, false),
                    })
                    { Add($"{entity} id {name}", entity, raw, valid, id); }
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
        foreach (var (entity, version) in BodyTargetsCases.Pairs)
        {
            var baseline = BodyTargetsCases.Baseline(entity, version);
            foreach (var field in Properties(embedded, entity, version).EnumerateObject())
            {
                var types = field.Value.GetProperty("type");
                var numeric = types.ValueKind == JsonValueKind.Array ? types.EnumerateArray().Any(t => t.GetString() is "number" or "integer") : types.GetString() is "number" or "integer";
                if (!numeric) { continue; }
                checkedFields++;
                foreach (var value in bad)
                {
                    // Never an exception or a 500: always the bare invalidPayload.
                    AssertAdmission(false, entity, version, BodyTargetsCases.NewId(entity), BodyTargetsCases.WithRaw(baseline, field.Name, value), $"{entity} v{version} {field.Name}={value}");
                }
            }
        }
        Assert.True(checkedFields >= 30, $"{checkedFields}");
    }

    [Fact, Trait("Rule", "B19.no-plausibility")]
    public void App_only_plausibility_outliers_are_admitted()
    {
        var outliers = BodyTargetsCases.Corpus().Where(c => c.Id.StartsWith("plausibility-", StringComparison.Ordinal)).ToArray();
        Assert.True(outliers.Length >= 15, $"{outliers.Length}");
        foreach (var test in outliers)
        {
            Assert.True(test.Valid, test.Id);
            AssertAdmission(true, test.Entity, test.SchemaVersion, BodyTargetsCases.IdOf(test), test.Raw, test.Id);
        }
        // Hand-built: ranges and conventions that only the app's TargetRules.input enforces.
        var profile = BodyTargetsCases.Baseline("profile");
        var settings = BodyTargetsCases.Baseline("targetSettings");
        var weekly = BodyTargetsCases.Raw("goalPhase-base-weekly");
        foreach (var (name, entity, raw) in new[]
        {
            ("birth year 1", "profile", BodyTargetsCases.With(profile, "birthYear", 1)),
            ("birth year 9999", "profile", BodyTargetsCases.With(profile, "birthYear", 9999)),
            ("height 1e6", "profile", BodyTargetsCases.WithRaw(profile, "heightCm", "1000000")),
            ("weekly -5000", "goalPhase", BodyTargetsCases.WithRaw(weekly, "kgPerWeek", "-5000")),
            ("lose while gaining", "goalPhase", BodyTargetsCases.WithRaw(weekly, "kgPerWeek", "2.5")),
            ("blank name", "goalPhase", BodyTargetsCases.With(weekly, "name", "   ")),
            ("manual 1 kcal", "targetSettings", BodyTargetsCases.WithRaw(BodyTargetsCases.With(settings, "manual", true), "baseKcal", "1")),
            ("shift 9", "targetSettings", BodyTargetsCases.WithRaw(settings, "shiftMon", "9")),
            ("shift 0", "targetSettings", BodyTargetsCases.WithRaw(settings, "shiftTue", "0")),
            ("fiber 1e6", "targetSettings", BodyTargetsCases.WithRaw(settings, "fiberG", "1000000")),
            ("basis 0.001 kg", "targetSettings", BodyTargetsCases.WithRaw(settings, "basisWeightKg", "0.001")),
        })
        { AssertAdmission(true, entity, 1, BodyTargetsCases.NewId(entity), raw, name); }
    }

    // TD-089: overlaps between rows are the app's read projection. The validator sees one SyncVersion
    // and holds no state, so it cannot reject a row because of another.
    [Fact, Trait("Rule", "B19.no-cross-row-validation")]
    public void Cross_row_conflicts_are_not_validated()
    {
        var matches = typeof(TargetsPayloadValidator).GetMethod(nameof(TargetsPayloadValidator.Matches), BindingFlags.Public | BindingFlags.Static)!;
        Assert.Equal([typeof(SyncVersion)], matches.GetParameters().Select(p => p.ParameterType));
        Assert.All(typeof(TargetsPayloadValidator).GetFields(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static), f => Assert.True(f.IsLiteral || f.IsInitOnly, f.Name));
        var weekly = BodyTargetsCases.Raw("goalPhase-base-weekly");
        var overlapping = BodyTargetsCases.With(BodyTargetsCases.With(weekly, "startDate", "2026-10-01"), "endDate", "2026-12-31");
        var gain = BodyTargetsCases.With(BodyTargetsCases.With(weekly, "goalType", "gain"), "kgPerWeek", 0.25m);
        var settings = BodyTargetsCases.Baseline("targetSettings");
        var sameDate = BodyTargetsCases.With(BodyTargetsCases.With(settings, "baseKcal", 1800.0m), "revision", 1);
        foreach (var (entity, raw) in new[] { ("goalPhase", weekly), ("goalPhase", overlapping), ("goalPhase", gain), ("targetSettings", settings), ("targetSettings", sameDate) })
        { AssertAdmission(true, entity, 1, BodyTargetsCases.NewId(entity), raw, $"{entity} {raw.Length}"); }
    }

    [Fact, Trait("Rule", "B19.weighIn-versions")]
    public void WeighIn_v1_and_v2_are_each_admitted_only_by_their_own_schema()
    {
        using var v1Fixtures = Read("entity-payloads.json");
        using var v2Fixtures = Read("entity-payloads-v2.json");
        var v1 = v1Fixtures.RootElement.GetProperty("weighIn").GetRawText();
        var v2 = v2Fixtures.RootElement.GetProperty("weighIn").GetRawText();
        // weighIn has no row-ID rule: any UUID.
        foreach (var id in new[] { Guid.NewGuid(), Guid.CreateVersion7(), V5 })
        {
            AssertAdmission(true, "weighIn", 1, id, v1, "v1 fixture as v1");
            AssertAdmission(true, "weighIn", 2, id, v2, "v2 fixture as v2");
        }
        AssertAdmission(false, "weighIn", 2, Guid.NewGuid(), v1, "v1 payload sent as v2 (missing fields)");
        AssertAdmission(false, "weighIn", 1, Guid.NewGuid(), v2, "v2 payload sent as v1 (extra fields)");
        foreach (var raw in new[] { v1, v2 })
        {
            using var payload = JsonDocument.Parse(raw);
            foreach (var version in new[] { 0, 3, 999 })
            { Assert.Equal("unsupported", SyncPayloads.InvalidReason(new SyncVersion("weighIn", Guid.NewGuid(), version, "unused", Guid.NewGuid(), null, payload.RootElement))); }
        }
        foreach (var (field, value, valid) in new (string, string, bool)[]
        {
            ("tzOffsetMin", "-720", true), ("tzOffsetMin", "840", true), ("tzOffsetMin", "0", true), ("tzOffsetMin", "-721", false), ("tzOffsetMin", "841", false),
            ("tzOffsetMin", "60.5", false), ("tzOffsetMin", "\"60\"", false), ("tzOffsetMin", "60.0", true),
            ("inputUnit", "\"kg\"", true), ("inputUnit", "\"lb\"", true), ("inputUnit", "\"KG\"", false), ("inputUnit", "\"st\"", false), ("inputUnit", "\"\"", false), ("inputUnit", "null", false),
            ("inputValue", "0", true), ("inputValue", "-0.1", false), ("inputValue", "1000000000000", true), ("inputValue", "1000000000001", false),
            ("preferredForDay", "true", true), ("preferredForDay", "\"true\"", false), ("preferredForDay", "null", false),
            ("kg", "-0.1", false), ("note", "\"ملاحظة\"", true),
        })
        { AssertAdmission(valid, "weighIn", 2, Guid.NewGuid(), BodyTargetsCases.WithRaw(v2, field, value), $"v2 {field}={value}"); }
        foreach (var field in V2Fields)
        {
            var absent = JsonNode.Parse(v2)!.AsObject(); absent.Remove(field);
            AssertAdmission(false, "weighIn", 2, Guid.NewGuid(), absent.ToJsonString(), $"v2 missing {field}");
            AssertAdmission(false, "weighIn", 1, Guid.NewGuid(), BodyTargetsCases.WithRaw(v1, field, "0"), $"v1 with {field}");
        }
    }

    private static JsonElement Properties(JsonDocument registry, string entity, int version) =>
        registry.RootElement.GetProperty("entities").GetProperty(entity).GetProperty($"{version}").GetProperty("properties");

    private static IEnumerable<string> Strings(JsonElement value) => value.EnumerateArray().Select(v => v.GetString()!);
}
