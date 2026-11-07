using System.Text;
using FitnessBuddy.Modules.Catalog.Contracts;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>
/// The shared exercise library for one request (B26 D5): read once from Catalog, put in the static part of the system prompt
/// (one line per exercise, most popular first, so it caches), searched by <c>exercise_search</c> and checked by
/// <c>propose_workout</c>. Shared data only: custom exercises reach the model as handles from <c>read_workouts</c>.
/// </summary>
internal sealed class Exercises(IExerciseLibrary library)
{
    private IReadOnlyList<LibraryExercise>? list;

    public async Task<IReadOnlyList<LibraryExercise>> ListAsync(CancellationToken ct) => list ??= await library.ListAsync(ct);

    /// <summary>The prompt block: code, name, aliases, equipment, muscle group.</summary>
    public static string PromptBlock(IReadOnlyList<LibraryExercise> exercises)
    {
        if (exercises.Count == 0) { return ""; }
        var sb = new StringBuilder("\n\nEXERCISE LIBRARY (code: name; other names; equipment, muscle group). Use these codes as exercise in propose_workout:\n");
        foreach (var e in exercises)
        {
            sb.Append(e.Id).Append(": ").Append(e.Name);
            if (e.Aliases.Length > 0) { sb.Append("; ").AppendJoin(", ", e.Aliases); }
            sb.Append("; ").Append(e.Equipment).Append(", ").Append(e.PrimaryMuscle.Replace('_', ' ')).Append('\n');
        }
        return sb.ToString();
    }

    /// <summary>Token-overlap match of a query against every name and alias (catalog normalization); best first.</summary>
    public static IEnumerable<LibraryExercise> Search(IReadOnlyList<LibraryExercise> exercises, string query, int limit)
    {
        var q = Tokens(query);
        if (q.Count == 0) { return []; }
        return exercises.Select(e => (e, Score: e.Aliases.Prepend(e.Name).Max(n => Score(q, Tokens(n)))))
            .Where(x => x.Score >= 0.34).OrderByDescending(x => x.Score).Take(limit).Select(x => x.e);
    }

    /// <summary>Whether the user's words already name the exercise (else the card says what it matched, WO-030).</summary>
    public static bool Names(LibraryExercise exercise, string mention)
    {
        var key = FoodName.Normalize(mention);
        return exercise.Aliases.Prepend(exercise.Name).Any(n => FoodName.Normalize(n) == key);
    }

    private static HashSet<string> Tokens(string text) =>
        [.. FoodName.Normalize(text).Split(' ', StringSplitOptions.RemoveEmptyEntries)];

    private static double Score(HashSet<string> q, HashSet<string> name)
    {
        if (name.Count == 0) { return 0; }
        if (q.SetEquals(name)) { return 2; }
        var shared = q.Count(name.Contains);
        return (double)shared / (q.Count + name.Count - shared);
    }
}
