namespace FitnessBuddy.Modules.Catalog.Contracts;

/// <summary>
/// The built-in exercise library of the current catalog release (WO-001/002, B26): shared data for the Buddy agent's
/// <c>exercise_search</c> and <c>propose_workout</c>, most popular first. Nothing personal; custom exercises live on the phone.
/// </summary>
public interface IExerciseLibrary
{
    Task<IReadOnlyList<LibraryExercise>> ListAsync(CancellationToken cancellationToken);
}

/// <summary>A library exercise: its code (<c>ex:…</c>), English display name, aliases, type, equipment and primary muscle group.</summary>
public sealed record LibraryExercise(string Id, string Name, string[] Aliases, string Type, string Equipment, string PrimaryMuscle);
