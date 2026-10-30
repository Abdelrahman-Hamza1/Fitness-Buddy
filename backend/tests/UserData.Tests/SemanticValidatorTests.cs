using System.Collections.Frozen;
using System.Globalization;
using System.Text.Json;
using FitnessBuddy.Modules.UserData.Infrastructure;

namespace FitnessBuddy.UserData.Tests;

// B20 D10: every fail-closed semantic validator covers exactly its entities, and its versions are
// exactly the registry's, so registering a new schema version without the validator fails here (and
// every row of it fails admission). A new entity family (B21) adds one row.
[Trait("Req", "AC-010")]
public sealed class SemanticValidatorTests
{
    private static readonly (string Name, Func<string, bool> Covers, FrozenSet<int> Versions, string[] Entities)[] Validators =
    [
        ("Targets", TargetsPayloadValidator.Covers, TargetsPayloadValidator.Versions, ["profile", "goalPhase", "targetSettings"]),
        ("Measurement", MeasurementPayloadValidator.Covers, MeasurementPayloadValidator.Versions, ["measurementType", "measurement"]),
        ("Workout", WorkoutPayloadValidator.Covers, WorkoutPayloadValidator.Versions,
            ["customExercise", "workoutSession", "sessionExercise", "workoutSet", "workoutTemplate", "workoutTemplateItem", "weeklyPlanDay"]),
    ];

    [Fact, Trait("Rule", "B20.fail-closed-dispatch")]
    public void Fail_closed_validators_cover_exactly_their_registry_versions()
    {
        using var embedded = JsonDocument.Parse(typeof(SyncPayloads).Assembly.GetManifestResourceStream(
            "FitnessBuddy.Modules.UserData.Infrastructure.Schemas.entities.json")!);
        var entities = embedded.RootElement.GetProperty("entities");
        var registered = entities.EnumerateObject().Select(e => e.Name).ToArray();
        foreach (var (name, covers, versions, owned) in Validators)
        {
            Assert.Equal(owned.Order(StringComparer.Ordinal), registered.Where(covers).Order(StringComparer.Ordinal));
            foreach (var entity in owned)
            {
                Assert.Equal(versions.Order(), entities.GetProperty(entity).EnumerateObject()
                    .Select(p => int.Parse(p.Name, CultureInfo.InvariantCulture)).Order());
            }
            Assert.True(owned.Length > 0, name);
        }
        // No entity has two semantic validators.
        Assert.All(registered, entity => Assert.True(Validators.Count(v => v.Covers(entity)) <= 1, entity));
    }
}
