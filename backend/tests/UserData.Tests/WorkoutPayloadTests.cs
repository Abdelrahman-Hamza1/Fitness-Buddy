using System.Reflection;
using System.Text.Json;
using FitnessBuddy.Modules.UserData.Domain;
using FitnessBuddy.Modules.UserData.Infrastructure;
using FitnessBuddy.TestData;

namespace FitnessBuddy.UserData.Tests;

// B21: the seven workout entities v1 are admitted by the schema plus exactly the README's workout
// wire rules W1–W5 (WorkoutPayloadValidator), live and as full tombstones.
[Trait("Req", "WO-003")]
[Trait("Req", "WO-004")]
[Trait("Req", "WO-010")]
[Trait("Req", "WO-020")]
[Trait("Req", "WO-021")]
[Trait("Req", "AC-010")]
public sealed class WorkoutPayloadTests
{
    private static readonly bool[] LiveAndTombstone = [false, true];
    private static readonly string[] Asymmetries = ["schemaOnly", "generic", "wholeNumberInteger"];
    private static readonly string[] OneVersion = ["1"];
    private static readonly Lazy<Dictionary<string, WorkoutCase>> Matrix = new(() => WorkoutCases.All().ToDictionary(c => c.Id, StringComparer.Ordinal));
    private const string CustomExerciseId = "0199e3c2-5b1a-7c3d-8e4f-0123456789c4";

    private static JsonDocument Embedded() => JsonDocument.Parse(typeof(SyncPayloads).Assembly.GetManifestResourceStream(
        "FitnessBuddy.Modules.UserData.Infrastructure.Schemas.entities.json")!);

    private static string? Admit(string entity, Guid id, string raw, bool tombstone = false, int version = 1)
    {
        using var payload = JsonDocument.Parse(raw);
        return SyncPayloads.InvalidReason(new SyncVersion(entity, id, version, "unused", Guid.NewGuid(),
            tombstone ? DateTimeOffset.UnixEpoch : null, payload.RootElement));
    }

    // Live and as a full tombstone: tombstones carry the payload and get the same rules (D5, 05 §5.5).
    private static void AssertAdmission(bool valid, string entity, Guid id, string raw, string because)
    {
        foreach (var tombstone in LiveAndTombstone)
        { Assert.True((valid ? null : "invalidPayload") == Admit(entity, id, raw, tombstone), $"{because} (tombstone={tombstone})"); }
    }

    private static void AssertAdmission(bool valid, string entity, string raw, string because) =>
        AssertAdmission(valid, entity, WorkoutCases.NewId(entity), raw, because);

    [Fact, Trait("Rule", "B21.embedded-schema-equals-corpus")]
    public void Embedded_schema_vocabularies_and_bounds_equal_contract_and_corpus()
    {
        using var corpus = WorkoutCases.ReadCorpus();
        using var embedded = Embedded();
        using var contract = WorkoutCases.Read("sync-entities.json");
        var constants = corpus.RootElement.GetProperty("constants");
        Assert.Equal(["maxAliases", "maxCatalogIdLength", "maxInteger", "maxNameLength", "maxNumber", "maxOriginLength", "maxSecondaries", "planDayIds"],
            constants.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
        var maxInteger = constants.GetProperty("maxInteger").GetDecimal();
        var maxNumber = constants.GetProperty("maxNumber").GetDecimal();
        Assert.Equal(9007199254740991m, maxInteger);
        Assert.Equal(1000000000000m, maxNumber);
        foreach (var entity in WorkoutCases.Entities)
        {
            // The server enforces the embedded registry; it must be the contract, in meaning.
            var schema = embedded.RootElement.GetProperty("entities").GetProperty(entity);
            Assert.True(JsonElement.DeepEquals(contract.RootElement.GetProperty("entities").GetProperty(entity), schema), entity);
            Assert.Equal(OneVersion, schema.EnumerateObject().Select(p => p.Name));
            var version = schema.GetProperty("1");
            Assert.False(version.GetProperty("additionalProperties").GetBoolean());
            Assert.Equal(version.GetProperty("properties").EnumerateObject().Select(p => p.Name),
                version.GetProperty("required").EnumerateArray().Select(v => v.GetString()!));
            var properties = version.GetProperty("properties");
            AssertRange(properties.GetProperty("createdAtMs"), 0m, maxInteger);
            Assert.Equal(constants.GetProperty("maxOriginLength").GetInt32(), properties.GetProperty("origin").GetProperty("maxLength").GetInt32());
            // Every integer and number field is bounded: integers by 2^53 − 1 (or tighter), numbers by 1e12.
            foreach (var field in properties.EnumerateObject())
            {
                var types = Types(field.Value);
                if (types.Contains("integer")) { Assert.True(field.Value.GetProperty("maximum").GetDecimal() <= maxInteger, $"{entity}.{field.Name}"); }
                if (types.Contains("number")) { AssertRange(field.Value, 0m, maxNumber); }
                if (types.Contains("string") && !field.Value.TryGetProperty("enum", out _)) { Assert.True(field.Value.TryGetProperty("maxLength", out _), $"{entity}.{field.Name}"); }
            }
        }
        var maxName = constants.GetProperty("maxNameLength").GetInt32();
        Assert.Equal(maxName, Properties(embedded, "customExercise").GetProperty("name").GetProperty("maxLength").GetInt32());
        Assert.Equal(maxName, Properties(embedded, "workoutSession").GetProperty("name").GetProperty("maxLength").GetInt32());
        Assert.Equal(maxName, Properties(embedded, "workoutTemplate").GetProperty("name").GetProperty("maxLength").GetInt32());
        // exerciseId fits "ex:" + the longest catalog ID.
        Assert.True(Properties(embedded, "sessionExercise").GetProperty("exerciseId").GetProperty("maxLength").GetInt32() >= 3 + constants.GetProperty("maxCatalogIdLength").GetInt32());
        AssertRange(Properties(embedded, "weeklyPlanDay").GetProperty("weekday"), 1m, 7m);
        AssertRange(Properties(embedded, "workoutSession").GetProperty("startMinute"), 0m, 1439m);
        foreach (var field in new[] { "targetSets", "targetReps" }) { AssertRange(Properties(embedded, "workoutTemplateItem").GetProperty(field), 1m, maxInteger); }
        foreach (var (entity, field) in new[] { ("workoutSession", "templateId"), ("sessionExercise", "sessionId"), ("workoutSet", "sessionExerciseId"), ("workoutTemplateItem", "templateId"), ("weeklyPlanDay", "templateId") })
        { Assert.Equal("uuid", Properties(embedded, entity).GetProperty(field).GetProperty("format").GetString()); }
        // Closed codes in contract order; a nullable enum lists null last.
        var words = corpus.RootElement.GetProperty("vocabularies");
        Assert.Equal(["equipment", "exerciseType", "inputUnit", "muscle"], words.EnumerateObject().Select(p => p.Name).Order(StringComparer.Ordinal));
        var exercise = Properties(embedded, "customExercise");
        Assert.Equal(Strings(words.GetProperty("exerciseType")), Strings(exercise.GetProperty("exerciseType").GetProperty("enum")));
        Assert.Equal(Strings(words.GetProperty("equipment")), Strings(exercise.GetProperty("equipment").GetProperty("enum")));
        Assert.Equal(Strings(words.GetProperty("muscle")).Append(null), Strings(exercise.GetProperty("primaryMuscle").GetProperty("enum")));
        Assert.Equal(Strings(words.GetProperty("inputUnit")).Append(null), Strings(Properties(embedded, "workoutSet").GetProperty("inputUnit").GetProperty("enum")));
    }

    private static void AssertRange(JsonElement property, decimal minimum, decimal maximum)
    {
        Assert.Equal(minimum, property.GetProperty("minimum").GetDecimal());
        Assert.Equal(maximum, property.GetProperty("maximum").GetDecimal());
    }

    [Fact, Trait("Rule", "B21.validator-constants")]
    public void Validator_constants_equal_corpus()
    {
        using var corpus = WorkoutCases.ReadCorpus();
        var constants = corpus.RootElement.GetProperty("constants");
        Assert.Equal(WorkoutPayloadValidator.MaxSecondaries, constants.GetProperty("maxSecondaries").GetInt32());
        Assert.Equal(WorkoutPayloadValidator.MaxAliases, constants.GetProperty("maxAliases").GetInt32());
        Assert.Equal(WorkoutPayloadValidator.MaxCatalogIdLength, constants.GetProperty("maxCatalogIdLength").GetInt32());
        Assert.Equal<Guid>(WorkoutPayloadValidator.PlanDayIds, constants.GetProperty("planDayIds").EnumerateArray().Select(v => Guid.Parse(v.GetString()!)));
        Assert.Equal<string?>(WorkoutPayloadValidator.MuscleCodes, Strings(corpus.RootElement.GetProperty("vocabularies").GetProperty("muscle")));
        Assert.Equal(WorkoutPayloadValidator.MuscleCodes.Length, WorkoutPayloadValidator.Muscles.Count);
        // SyncTestIds' plan-day ID is the fixture weekday's natural ID.
        using var fixtures = WorkoutCases.Read("entity-payloads.json");
        var weekday = fixtures.RootElement.GetProperty("weeklyPlanDay").GetProperty("weekday").GetInt32();
        Assert.Equal(WorkoutPayloadValidator.PlanDayIds[weekday - 1], SyncTestIds.SaturdayPlanDayRowId);
        Assert.Equal(SyncTestIds.SaturdayPlanDayRowId, SyncTestIds.For("weeklyPlanDay"));
    }

    [Fact, Trait("Rule", "B21.fail-closed-dispatch")]
    public void Workout_validator_fails_closed_for_unregistered_versions_and_other_entities()
    {
        foreach (var entity in WorkoutCases.Entities)
        {
            using var payload = JsonDocument.Parse(WorkoutCases.Baseline(entity));
            var version = new SyncVersion(entity, WorkoutCases.NewId(entity), 1, "unused", Guid.NewGuid(), null, payload.RootElement);
            Assert.True(WorkoutPayloadValidator.Covers(entity), entity);
            Assert.True(WorkoutPayloadValidator.Matches(version), entity);
            foreach (var unknown in new[] { 0, 2, 3, -1, int.MaxValue })
            { Assert.False(WorkoutPayloadValidator.Matches(version with { SchemaVersion = unknown }), $"{entity} v{unknown}"); }
            // Through admission an unregistered version is unsupported before any rule runs.
            Assert.Equal("unsupported", SyncPayloads.InvalidReason(version with { SchemaVersion = 2 }));
            // An entity the validator doesn't own never matches.
            Assert.False(WorkoutPayloadValidator.Matches(version with { Entity = "weighIn" }));
        }
        foreach (var other in new[] { "weighIn", "measurement", "profile", "personalFood", "CustomExercise", "workoutSets", "exercise", "" })
        { Assert.False(WorkoutPayloadValidator.Covers(other), other); }
    }

    [Fact, Trait("Rule", "B21.readme-rules")]
    public void Readme_workout_rules_equal_corpus_rules_and_each_has_accept_and_reject_cases()
    {
        var readme = File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "contracts-README.md")).ReplaceLineEndings("\n");
        var section = readme.Split("## Workout semantic rules (customExercise, workoutSession, sessionExercise, workoutSet, workoutTemplate, workoutTemplateItem, weeklyPlanDay)\n", StringSplitOptions.None)[1];
        section = section[..section.IndexOf("\n## ", StringComparison.Ordinal)];
        // The wire-rule bullets only: "Not wire rules" is the exclusion bullet.
        var labels = section.Split('\n').Where(line => line.StartsWith("- **", StringComparison.Ordinal))
            .Select(line => line[4..line.IndexOf(":**", StringComparison.Ordinal)]).Where(label => label != "Not wire rules").ToArray();
        Assert.Equal(["W1 muscles", "W2 aliases shape", "W3 set shape", "W4 exercise reference", "W5 plan-day row ID"], labels);
        using var corpus = WorkoutCases.ReadCorpus();
        var rules = corpus.RootElement.GetProperty("rules").EnumerateArray().ToArray();
        Assert.Equal(labels, rules.Select(r => r.GetProperty("readme").GetString()!));
        Assert.Equal(["W1", "W2", "W3", "W4", "W5"], rules.Select(r => r.GetProperty("id").GetString()!));
        var tagged = WorkoutCases.Corpus().Where(c => c.Rule is not null).ToArray();
        Assert.All(tagged, c => Assert.Contains(c.Rule!, labels));
        foreach (var label in labels)
        {
            Assert.Contains(tagged, c => c.Rule == label && c.Valid);
            Assert.Contains(tagged, c => c.Rule == label && !c.Valid);
            // Each declared outcome holds on the server.
            Assert.All(tagged.Where(c => c.Rule == label), c => AssertAdmission(c.Valid, c.Entity, WorkoutCases.IdOf(c), c.Raw, c.Id));
        }
    }

    [Fact, Trait("Rule", "B21.corpus-agreement")]
    public void Corpus_declarations_agree_with_admission_and_derived_lists()
    {
        using var corpus = WorkoutCases.ReadCorpus();
        var root = corpus.RootElement;
        Assert.Equal(1, root.GetProperty("version").GetInt32());
        var items = root.GetProperty("payloads").EnumerateArray().ToArray();
        var cases = WorkoutCases.Corpus();
        Assert.Equal(321, cases.Count);
        Assert.Equal(cases.Count, cases.Select(c => c.Id).Distinct(StringComparer.Ordinal).Count());
        Assert.All(items, i => Assert.Equal(1, i.GetProperty("schemaVersion").GetInt32()));
        Assert.Equal(WorkoutCases.Entities.Order(StringComparer.Ordinal), cases.Select(c => c.Entity).Distinct().Order(StringComparer.Ordinal));
        // Closed asymmetry set: wholeNumberInteger marks a server acceptance, the others rejections.
        Assert.All(cases.Where(c => c.Asymmetry is not null), c => Assert.Contains(c.Asymmetry!, Asymmetries));
        Assert.All(cases.Where(c => c.Asymmetry is not null), c => Assert.Equal(c.Asymmetry == "wholeNumberInteger", c.Valid));
        // Session and template have no wire rules: no case of theirs carries a rule, and each rejection is
        // the schema's or generic (tagged, or a member Dart can't decode either, such as a number name).
        Assert.All(cases.Where(c => c.Entity is "workoutSession" or "workoutTemplate"), c => Assert.Null(c.Rule));
        // Every plan-day case names its row ID (W5).
        Assert.All(cases.Where(c => c.Entity == "weeklyPlanDay"), c => Assert.NotNull(c.RowId));
        // <id>-tombstone repeats <id>'s payload as a tombstone.
        foreach (var tombstone in cases.Where(c => c.Id.EndsWith("-tombstone", StringComparison.Ordinal)))
        {
            var live = WorkoutCases.Case(tombstone.Id[..^"-tombstone".Length]);
            Assert.True(tombstone.Deleted && !live.Deleted, tombstone.Id);
            Assert.Equal((live.Raw, live.Entity, live.RowId, live.Valid, live.Rule), (tombstone.Raw, tombstone.Entity, tombstone.RowId, tombstone.Valid, tombstone.Rule));
        }
        Assert.Equal(Strings(root.GetProperty("serverRejectsAppTolerates")),
            items.Where(c => !c.GetProperty("serverAccepts").GetBoolean() && c.GetProperty("appReads").GetBoolean()).Select(c => c.GetProperty("id").GetString()));
        Assert.Equal(Strings(root.GetProperty("serverAcceptsAppSkips")),
            items.Where(c => c.GetProperty("serverAccepts").GetBoolean() && !c.GetProperty("appReads").GetBoolean()).Select(c => c.GetProperty("id").GetString()));
        // Scrubbed tombstones (D10): admissible while W3's null pattern holds.
        foreach (var id in new[] { "customExercise-tombstone-scrubbed", "workoutSession-tombstone-scrubbed", "workoutTemplate-tombstone-scrubbed", "workoutSet-tombstone-scrubbed", "workoutSet-tombstone-scrubbed-cardio" })
        { Assert.True(WorkoutCases.Case(id).Valid && WorkoutCases.Case(id).Deleted, id); }
        Assert.False(WorkoutCases.Case("workoutSet-tombstone-scrubbed-nulls").Valid);
        foreach (var writer in root.GetProperty("writerCases").EnumerateArray())
        {
            var payload = WorkoutCases.Case(writer.GetProperty("payloadId").GetString()!);
            Assert.True(payload.Valid); Assert.Equal(writer.GetProperty("entity").GetString(), payload.Entity);
        }
        // One readable failure listing every disagreeing case, live or tombstone.
        var disagreements = cases
            .SelectMany(c => LiveAndTombstone.Where(t => (c.Valid ? null : "invalidPayload") != Admit(c.Entity, WorkoutCases.IdOf(c), c.Raw, t))
                .Select(t => $"{c.Id}{(t ? " (tombstone)" : "")}"))
            .ToArray();
        Assert.Empty(disagreements);
    }

    public static TheoryData<string> Payloads() => new(Matrix.Value.Keys);

    [Theory, MemberData(nameof(Payloads)), Trait("Rule", "05.5-payload-validation")]
    public void Payload_matrix_matches_admission_for_live_and_tombstone(string id)
    {
        var test = Matrix.Value[id];
        AssertAdmission(test.Valid, test.Entity, WorkoutCases.IdOf(test), test.Raw, id);
    }

    [Fact, Trait("Rule", "05.5-payload-validation")]
    public void Schema_matrix_covers_every_field_and_fixture()
    {
        using var embedded = Embedded();
        var ids = Matrix.Value.Keys.ToHashSet(StringComparer.Ordinal);
        foreach (var entity in WorkoutCases.Entities)
        {
            foreach (var field in Properties(embedded, entity).EnumerateObject())
            {
                foreach (var shape in new[] { "missing", "null", "type-array", "type-object", "type-scalar" })
                { Assert.Contains($"{entity}-schema-{shape}-{field.Name}", ids); }
            }
            Assert.Contains($"{entity}-schema-extra-field", ids);
            Assert.Contains($"fixture-{entity}", ids);
        }
    }

    public static TheoryData<string> WireRules() => new("W1", "W2", "W3", "W4", "W5");

    // Hand-built from the corpus bases, independent of the generator's declarations.
    [Theory, MemberData(nameof(WireRules)), Trait("Rule", "B21.wire-rules")]
    public void Wire_rules_accept_valid_and_reject_each_violation(string rule)
    {
        var cases = WireRuleCases(rule);
        Assert.Contains(cases, c => c.Valid);
        Assert.Contains(cases, c => !c.Valid);
        foreach (var (name, entity, id, raw, valid) in cases) { AssertAdmission(valid, entity, id, raw, $"{rule}: {name}"); }
    }

    private static List<(string Name, string Entity, Guid Id, string Raw, bool Valid)> WireRuleCases(string rule)
    {
        var cases = new List<(string Name, string Entity, Guid Id, string Raw, bool Valid)>();
        void Add(string name, string entity, string raw, bool valid, Guid? id = null) => cases.Add((name, entity, id ?? WorkoutCases.NewId(entity), raw, valid));
        var exercise = WorkoutCases.Baseline("customExercise");
        string Muscles(string? primary, string json) =>
            WorkoutCases.With(WorkoutCases.With(exercise, "primaryMuscle", primary), "secondaryMusclesJson", json);
        switch (rule)
        {
            case "W1":
                // Every code alone is valid, unless it is the primary.
                foreach (var code in WorkoutPayloadValidator.MuscleCodes)
                {
                    Add($"{code} with primary chest", "customExercise", Muscles("chest", $"[\"{code}\"]"), code != "chest");
                    Add($"{code} without primary", "customExercise", Muscles(null, $"[\"{code}\"]"), true);
                }
                Add("four", "customExercise", Muscles("chest", "[\"abs\",\"calves\",\"traps\",\"glutes\"]"), true);
                Add("five", "customExercise", Muscles(null, "[\"abs\",\"calves\",\"traps\",\"glutes\",\"biceps\"]"), false);
                Add("empty", "customExercise", Muscles("chest", "[]"), true);
                Add("duplicate", "customExercise", Muscles(null, "[\"abs\",\"abs\"]"), false);
                Add("escaped duplicate", "customExercise", Muscles(null, "[\"abs\",\"\\u0061bs\"]"), false);
                Add("escaped code", "customExercise", Muscles("chest", "[\"\\u0061bs\"]"), true);
                Add("escaped primary", "customExercise", Muscles("chest", "[\"\\u0063hest\"]"), false);
                foreach (var bad in new[] { "back", "core", "full_body", "Chest", "ABS", " abs", "abs ", "upper-back", "" })
                { Add($"code '{bad}'", "customExercise", Muscles(null, JsonSerializer.Serialize(new[] { bad })), false); }
                break;
            case "W2":
                string Aliases(int n) => WorkoutCases.With(exercise, "aliasesJson", JsonSerializer.Serialize(Enumerable.Range(0, n).Select(i => $"a{i}")));
                foreach (var n in new[] { 0, 1, 10 }) { Add($"{n} aliases", "customExercise", Aliases(n), true); }
                foreach (var n in new[] { 11, 40 }) { Add($"{n} aliases", "customExercise", Aliases(n), false); }
                // No trimming, length or uniqueness rule: the app's.
                Add("blank and duplicate", "customExercise", WorkoutCases.With(exercise, "aliasesJson", "[\"\",\" \",\" \"]"), true);
                foreach (var bad in new[] { "[1]", "[null]", "[[]]", "[{}]", "[true]", "{}", "\"a\"", "null", "1" })
                { Add($"aliases {bad}", "customExercise", WorkoutCases.With(exercise, "aliasesJson", bad), false); }
                break;
            case "W3":
                var set = WorkoutCases.Baseline("workoutSet");
                string Set(int? reps, double? kg, double? input, string? unit, int? duration, double? distance)
                {
                    var raw = WorkoutCases.With(set, "reps", reps);
                    raw = WorkoutCases.With(raw, "kg", kg);
                    raw = WorkoutCases.With(raw, "inputValue", input);
                    raw = WorkoutCases.With(raw, "inputUnit", unit);
                    raw = WorkoutCases.With(raw, "durationSeconds", duration);
                    return WorkoutCases.With(raw, "distanceMeters", distance);
                }
                // All 2^6 null patterns; the rule decides each.
                for (var mask = 0; mask < 64; mask++)
                {
                    bool On(int bit) => (mask & (1 << bit)) != 0;
                    var (reps, kg, input, unit, duration, distance) = (On(0), On(1), On(2), On(3), On(4), On(5));
                    var valid = reps != duration && (!kg || reps) && (!distance || duration) && kg == input && kg == unit;
                    Add($"pattern {mask:b6}", "workoutSet",
                        Set(reps ? 8 : null, kg ? 80 : null, input ? 176 : null, unit ? "lb" : null, duration ? 60 : null, distance ? 100 : null), valid);
                }
                break;
            case "W4":
                foreach (var entity in new[] { "sessionExercise", "workoutTemplateItem" })
                {
                    var baseline = WorkoutCases.Baseline(entity);
                    foreach (var (id, valid) in new[]
                    {
                        ("ex:a", true), ("ex:bench_press", true), ("ex:3_4_sit_up", true), ("ex:" + new string('z', 60), true), ("ex:_", true),
                        (CustomExerciseId, true), ("00000000-0000-0000-0000-000000000000", true),
                        ("ex:", false), ("ex:" + new string('z', 61), false), ("ex:Bench", false), ("ex:bench-press", false), ("ex:bench press", false),
                        ("ex:bench\n", false), ("ex:bench\u0000", false), ("ex:bénch", false), ("EX:bench", false), ("Ex:bench", false), (" ex:bench", false),
                        ("ex;bench", false), ("bench_press", false), (CustomExerciseId.ToUpperInvariant(), false), (CustomExerciseId.Replace("-", "", StringComparison.Ordinal), false),
                        ("{" + CustomExerciseId + "}", false), (" " + CustomExerciseId, false), (CustomExerciseId + " ", false), ("", false),
                    })
                    { Add($"{entity} '{id}'", entity, WorkoutCases.With(baseline, "exerciseId", id), valid); }
                }
                break;
            case "W5":
                var day = WorkoutCases.Baseline("weeklyPlanDay");
                for (var weekday = 1; weekday <= 7; weekday++)
                {
                    var raw = WorkoutCases.With(day, "weekday", weekday);
                    for (var other = 1; other <= 7; other++)
                    { Add($"weekday {weekday} with day {other}'s ID", "weeklyPlanDay", raw, weekday == other, WorkoutPayloadValidator.PlanDayIds[other - 1]); }
                    Add($"weekday {weekday} whole-number double", "weeklyPlanDay", WorkoutCases.WithRaw(day, "weekday", $"{weekday}.0"), true, WorkoutPayloadValidator.PlanDayIds[weekday - 1]);
                    foreach (var id in new[] { Guid.NewGuid(), Guid.CreateVersion7(), Guid.Empty, Guid.AllBitsSet, SyncTestIds.ProfileRowId })
                    { Add($"weekday {weekday} with {id}", "weeklyPlanDay", raw, false, id); }
                }
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(rule), rule, "unknown rule");
        }
        return cases;
    }

    // W1/W2 nested JSON: never an exception or a 500, always the bare invalidPayload; this also covers
    // the ill-formed UTF-16 cases the generic Utf16Cases skip for these fields (D13).
    [Fact, Trait("Rule", "B18.well-formed-utf16")]
    public void Nested_json_fields_reject_non_arrays_non_strings_and_ill_formed_utf16()
    {
        var exercise = WorkoutCases.Baseline("customExercise");
        foreach (var field in new[] { "secondaryMusclesJson", "aliasesJson" })
        {
            var control = field == "aliasesJson" ? "[\"db \\ud83d\\ude00\"]" : "[\"abs\"]";
            AssertAdmission(true, "customExercise", WorkoutCases.With(exercise, field, control), $"{field} control");
            foreach (var bad in new[]
            {
                "", " ", "[", "[\"abs\"", "[\"abs\"]]", "[\"abs\"] x", "{}", "{\"abs\":1}", "\"abs\"", "null", "true", "1", "[1]", "[null]", "[[\"abs\"]]",
                "[\"\\ud800\"]", "[\"abs\\udc00\"]", "[\"\\ude00\\ud83d\"]", "[\"abs\\u0000\"]", "[\"a\",\"a\",\"a\",\"a\",\"a\",\"a\",\"a\",\"a\",\"a\",\"a\",1]",
                new string('[', 30) + new string(']', 30), "[\"abs\",]", "['abs']",
            })
            { AssertAdmission(false, "customExercise", WorkoutCases.With(exercise, field, bad), $"{field} = {bad}"); }
            // A lone unit in the field string itself (the generic pass).
            AssertAdmission(false, "customExercise", WorkoutCases.WithRaw(exercise, field, "\"[\\\"abs\\ud800\\\"]\""), $"{field} outer lone surrogate");
        }
        foreach (var entity in new[] { "sessionExercise", "workoutTemplateItem" })
        {
            AssertAdmission(false, entity, WorkoutCases.WithRaw(WorkoutCases.Baseline(entity), "exerciseId", "\"ex:a\\ud800\""), $"{entity} exerciseId lone surrogate");
            AssertAdmission(false, entity, WorkoutCases.WithRaw(WorkoutCases.Baseline(entity), "exerciseId", "\"ex:a\\ud83d\\ude00\""), $"{entity} exerciseId pair");
        }
    }

    // D4: cross-row ownership, app write bounds, names and other row-ID versions are not wire rules.
    // The validator sees one SyncVersion and holds no state, so it cannot reject a row because of
    // another (TD-089).
    [Fact, Trait("Rule", "B21.not-wire-rules")]
    public void Not_wire_rules_are_admitted()
    {
        var outliers = WorkoutCases.Corpus().Where(c => c.Id.StartsWith("notWire-", StringComparison.Ordinal)).ToArray();
        Assert.True(outliers.Length >= 20, $"{outliers.Length}");
        Assert.All(outliers, test => AssertAdmission(true, test.Entity, WorkoutCases.IdOf(test), test.Raw, test.Id));
        var session = WorkoutCases.Baseline("workoutSession");
        var set = WorkoutCases.Baseline("workoutSet");
        var item = WorkoutCases.Baseline("workoutTemplateItem");
        var exercise = WorkoutCases.Baseline("customExercise");
        var maxInteger = 9007199254740991m;
        foreach (var (name, entity, raw) in new[]
        {
            ("reps 0", "workoutSet", WorkoutCases.With(set, "reps", 0)),
            ("reps 2^53 − 1", "workoutSet", WorkoutCases.With(set, "reps", maxInteger)),
            ("kg 1e12", "workoutSet", WorkoutCases.With(WorkoutCases.With(set, "kg", 1000000000000m), "inputValue", 1000000000000m)),
            ("kg 0", "workoutSet", WorkoutCases.With(set, "kg", 0)),
            ("lb typed value far from kg", "workoutSet", WorkoutCases.With(set, "inputValue", 1)),
            ("weight on a bodyweight-style set", "workoutSet", WorkoutCases.With(set, "kg", 999)),
            ("position 2^53 − 1", "workoutSet", WorkoutCases.With(set, "position", maxInteger)),
            ("orphan set", "workoutSet", WorkoutCases.With(set, "sessionExerciseId", Guid.NewGuid().ToString())),
            ("session duration 0", "workoutSession", WorkoutCases.With(session, "durationMinutes", 0)),
            ("session duration 2^53 − 1", "workoutSession", WorkoutCases.With(session, "durationMinutes", maxInteger)),
            ("future session", "workoutSession", WorkoutCases.With(session, "localDate", "9999-12-31")),
            ("blank session name", "workoutSession", WorkoutCases.With(session, "name", "   ")),
            ("unknown template", "workoutSession", WorkoutCases.With(session, "templateId", Guid.NewGuid().ToString())),
            ("target sets 1000", "workoutTemplateItem", WorkoutCases.With(item, "targetSets", 1000)),
            ("target reps 2^53 − 1", "workoutTemplateItem", WorkoutCases.With(item, "targetReps", maxInteger)),
            ("item in another template", "workoutTemplateItem", WorkoutCases.With(item, "templateId", Guid.NewGuid().ToString())),
            ("unknown custom exercise", "workoutTemplateItem", WorkoutCases.With(item, "exerciseId", Guid.NewGuid().ToString())),
            ("empty exercise name", "customExercise", WorkoutCases.With(exercise, "name", "")),
            ("emoji name", "customExercise", WorkoutCases.With(exercise, "name", "💪")),
            ("type and muscles that don't match", "customExercise", WorkoutCases.With(WorkoutCases.With(exercise, "exerciseType", "distance_duration"), "equipment", "kettlebell")),
        })
        { AssertAdmission(true, entity, raw, name); }
        // Row IDs: any UUID for the six entities without a row-ID rule.
        foreach (var entity in WorkoutCases.Entities.Where(e => e != "weeklyPlanDay"))
        {
            foreach (var id in new[] { Guid.NewGuid(), Guid.CreateVersion7(), Guid.Empty, Guid.AllBitsSet, WorkoutPayloadValidator.PlanDayIds[0] })
            { AssertAdmission(true, entity, id, WorkoutCases.Baseline(entity), $"{entity} row ID {id}"); }
        }
        var matches = typeof(WorkoutPayloadValidator).GetMethod(nameof(WorkoutPayloadValidator.Matches), BindingFlags.Public | BindingFlags.Static)!;
        Assert.Equal([typeof(SyncVersion)], matches.GetParameters().Select(p => p.ParameterType));
        Assert.All(typeof(WorkoutPayloadValidator).GetFields(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static), f => Assert.True(f.IsLiteral || f.IsInitOnly, f.Name));
    }

    private static JsonElement Properties(JsonDocument registry, string entity) =>
        registry.RootElement.GetProperty("entities").GetProperty(entity).GetProperty("1").GetProperty("properties");

    private static string[] Types(JsonElement schema)
    {
        var type = schema.GetProperty("type");
        return type.ValueKind == JsonValueKind.Array ? [.. type.EnumerateArray().Select(t => t.GetString()!)] : [type.GetString()!];
    }

    private static IEnumerable<string?> Strings(JsonElement value) => value.EnumerateArray().Select(v => v.GetString());
}
