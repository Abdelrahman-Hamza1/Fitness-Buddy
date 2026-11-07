using FitnessBuddy.Modules.Catalog.Contracts;
using Npgsql;

namespace FitnessBuddy.Modules.Catalog.Infrastructure;

/// <summary>
/// The active <c>catalog.exercises</c> rows with their English names (B26). A release changes only on import, so the list is
/// held for ten minutes per process; the agent puts it in the static part of its prompt.
/// </summary>
internal sealed class PostgresExerciseLibrary(NpgsqlDataSource source, TimeProvider clock) : IExerciseLibrary, IDisposable
{
    private static readonly TimeSpan Fresh = TimeSpan.FromMinutes(10);
    private readonly SemaphoreSlim gate = new(1, 1);
    private (DateTimeOffset At, IReadOnlyList<LibraryExercise> List)? cached;

    public async Task<IReadOnlyList<LibraryExercise>> ListAsync(CancellationToken cancellationToken)
    {
        if (cached is { } hit && clock.GetUtcNow() - hit.At < Fresh) { return hit.List; }
        await gate.WaitAsync(cancellationToken);
        try
        {
            if (cached is { } again && clock.GetUtcNow() - again.At < Fresh) { return again.List; }
            await using var command = source.CreateCommand("""
                SELECT e.id,e.data->>'name_en',e.data->>'type',e.data->>'equipment',e.data->>'primary_muscle',
                  coalesce(array(SELECT n.name FROM catalog.names n WHERE n.target_id=e.id AND n.lang='en' AND n.name<>(e.data->>'name_en') ORDER BY n.name),'{}')
                FROM catalog.exercises e WHERE e.active ORDER BY coalesce((e.data->>'popularity')::int,1000),e.id
                """);
            var list = new List<LibraryExercise>();
            await using (var row = await command.ExecuteReaderAsync(cancellationToken))
            {
                while (await row.ReadAsync(cancellationToken))
                {
                    list.Add(new(row.GetString(0), row.GetString(1), row.GetFieldValue<string[]>(5), row.GetString(2), row.GetString(3), row.GetString(4)));
                }
            }
            cached = (clock.GetUtcNow(), list);
            return list;
        }
        finally { gate.Release(); }
    }

    public void Dispose() => gate.Dispose();
}
