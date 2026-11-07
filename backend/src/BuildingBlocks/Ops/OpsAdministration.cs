using FitnessBuddy.BuildingBlocks.Persistence;
using Npgsql;

namespace FitnessBuddy.BuildingBlocks.Ops;

/// <summary>A queue: background jobs or outbox events.</summary>
public enum QueueKind
{
    Job,
    Event,
}

/// <summary>One job type or event type: counts by state, the oldest due item and whether the console paused it.</summary>
public sealed record QueueSummary(QueueKind Kind, string Type, long Pending, long Due, long Done24h, long Dead, long Cancelled, DateTimeOffset? OldestDueAt, bool Paused);

/// <summary>A dead (or cancelled) item: its id, type, attempts and the exception type of its last failure. Never a payload or a user.</summary>
public sealed record FailedItem(Guid Id, QueueKind Kind, string Type, string State, int Attempts, string? ErrorType, DateTimeOffset CreatedAt);

/// <summary>A worker's last heartbeat and what it was running then (B23 R#11): a job or an event handler, of that type.</summary>
public sealed record WorkerBeat(Guid Instance, string Role, string Build, DateTimeOffset StartedAt, DateTimeOffset LastBeatAt, QueueKind? BusyKind,
    string? BusyType, DateTimeOffset? BusySince);

/// <summary>What a queue change actually did (B23b review): the console audits exactly this.</summary>
public enum QueueChangeOutcome
{
    /// <summary>Changed; <see cref="QueueChange.Previous"/> is the state it found.</summary>
    Changed,

    /// <summary>Already in the requested state; nothing written.</summary>
    Unchanged,

    /// <summary>Not in a state the change applies to (or not a pausable type); nothing written.</summary>
    Refused,

    /// <summary>A worker holds the item right now; skipped, never waited for.</summary>
    Busy,

    /// <summary>No such item.</summary>
    Missing,
}

/// <summary>The outcome and the state found under the row lock (<c>dead</c>, <c>pending</c>, … or <c>paused</c>/<c>running</c>), when known.</summary>
public sealed record QueueChange(QueueChangeOutcome Outcome, string? Previous);

public sealed record ServerErrorCount(string Role, int Status, long Errors);

/// <summary>
/// The console's view of the queues (AD-010, AD-014; B23 P4). Ops is BuildingBlocks infrastructure, so this is its public
/// contract. Reads and changes go through <c>ops.admin_*</c> functions only the console login can run (TD-118). Changes take
/// the caller's session, so the console commits each change with its audit row.
/// </summary>
public interface IOpsAdministration
{
    Task<IReadOnlyList<QueueSummary>> QueuesAsync(DateTimeOffset now, CancellationToken cancellationToken);

    Task<IReadOnlyList<FailedItem>> FailedAsync(int limit, CancellationToken cancellationToken);

    Task<IReadOnlyList<WorkerBeat>> HeartbeatsAsync(CancellationToken cancellationToken);

    Task<IReadOnlyList<ServerErrorCount>> ServerErrorsAsync(DateTimeOffset since, CancellationToken cancellationToken);

    /// <summary>A dead item back to pending with its attempts reset; refused when it isn't dead, busy when a worker holds it.</summary>
    Task<QueueChange> RetryAsync(DatabaseSession session, QueueKind kind, Guid id, DateTimeOffset now, CancellationToken cancellationToken);

    /// <summary>A pending or dead job to cancelled (jobs only); unchanged when already cancelled, busy when it is running.</summary>
    Task<QueueChange> CancelAsync(DatabaseSession session, Guid id, DateTimeOffset now, CancellationToken cancellationToken);

    /// <summary>Pauses or resumes a job type; unchanged when it already was, refused for a type that can't be paused.</summary>
    Task<QueueChange> SetPausedAsync(DatabaseSession session, string jobType, bool paused, string actor, DateTimeOffset now, CancellationToken cancellationToken);
}

/// <summary>
/// The codes the console shows as they are (B23b security review): every queue writer (the API too) can put any text in a type,
/// error or build column, so the <c>ops.admin_*</c> reads return a value only when it is in these lists and <c>other</c> otherwise.
/// A new job handler, event or expected exception type is added here (a Host test checks every registered handler is).
/// </summary>
public sealed record QueueVocabulary(IReadOnlyList<string> JobTypes, IReadOnlyList<string> EventTypes, IReadOnlyList<string> ErrorTypes)
{
    public static QueueVocabulary Default { get; } = new(
        [Jobs.OpsCleanupJob.Type, "buddy.cleanup", "catalog.off-cache-expiry", "identity.cleanup", "userdata.cleanup"],
        [Messaging.UserErasure.EventType],
        ["ArgumentException", "ArgumentNullException", "ArgumentOutOfRangeException", "CryptographicException", "DbUpdateConcurrencyException",
         "DbUpdateException", "FormatException", "HttpRequestException", "InvalidCastException", "InvalidOperationException", "IOException",
         "JsonException", "KeyNotFoundException", "NotSupportedException", "NpgsqlException", "NullReferenceException", "ObjectDisposedException",
         "OperationCanceledException", "OverflowException", "PostgresException", "SocketException", "TaskCanceledException", "TimeoutException",
         "UnauthorizedAccessException"]);

    /// <summary>The default lists plus <paramref name="jobTypes"/> and <paramref name="eventTypes"/> (tests with their own handlers).</summary>
    public QueueVocabulary With(IEnumerable<string>? jobTypes = null, IEnumerable<string>? eventTypes = null) =>
        new([.. JobTypes, .. jobTypes ?? []], [.. EventTypes, .. eventTypes ?? []], ErrorTypes);
}

public static partial class OpsQueues
{
    /// <summary>Job types the console can pause: any but <c>ops.cleanup</c>, which expires everything else. Events never pause.</summary>
    public static bool IsPausable(string jobType) =>
        !string.IsNullOrEmpty(jobType) && jobType != Jobs.OpsCleanupJob.Type && jobType != Other && TypeCode().IsMatch(jobType);

    /// <summary>What the console reads instead of a code outside <see cref="QueueVocabulary"/>.</summary>
    public const string Other = "other";

    [System.Text.RegularExpressions.GeneratedRegex("^[a-z][a-z0-9._-]{0,199}$", System.Text.RegularExpressions.RegexOptions.CultureInvariant)]
    private static partial System.Text.RegularExpressions.Regex TypeCode();

    public static string Code(QueueKind kind) => kind == QueueKind.Job ? "job" : "event";

    public static QueueKind? Parse(string? code) => code switch { "job" => QueueKind.Job, "event" => QueueKind.Event, _ => null };
}

/// <summary>Runs on the admin role's data source (fb_admin); the application login can't execute these functions.</summary>
public sealed class PostgresOpsAdministration(NpgsqlDataSource source, QueueVocabulary? vocabulary = null) : IOpsAdministration
{
    private readonly QueueVocabulary codes = vocabulary ?? QueueVocabulary.Default;

    public async Task<IReadOnlyList<QueueSummary>> QueuesAsync(DateTimeOffset now, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT kind,type,pending,due,done_24h,dead,cancelled,oldest_due_at,paused FROM ops.admin_queues($1,$2,$3)");
        command.Parameters.AddWithValue(now);
        AddTypes(command);
        var rows = new List<QueueSummary>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new QueueSummary(Kind(reader.GetString(0)), reader.GetString(1), reader.GetInt64(2), reader.GetInt64(3), reader.GetInt64(4), reader.GetInt64(5),
                reader.GetInt64(6), reader.IsDBNull(7) ? null : reader.GetFieldValue<DateTimeOffset>(7), reader.GetBoolean(8)));
        }
        return rows;
    }

    public async Task<IReadOnlyList<FailedItem>> FailedAsync(int limit, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT id,kind,type,state,attempts,error_type,created_at FROM ops.admin_failed($1,$2,$3,$4)");
        command.Parameters.AddWithValue(limit);
        AddTypes(command);
        command.Parameters.AddWithValue(codes.ErrorTypes.ToArray());
        var rows = new List<FailedItem>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new FailedItem(reader.GetGuid(0), Kind(reader.GetString(1)), reader.GetString(2), reader.GetString(3), reader.GetInt32(4),
                reader.IsDBNull(5) ? null : reader.GetString(5), reader.GetFieldValue<DateTimeOffset>(6)));
        }
        return rows;
    }

    public async Task<IReadOnlyList<WorkerBeat>> HeartbeatsAsync(CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT instance,role,build,started_at,last_beat_at,busy_kind,busy_type,busy_since FROM ops.admin_heartbeats($1,$2)");
        AddTypes(command);
        var rows = new List<WorkerBeat>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            rows.Add(new WorkerBeat(reader.GetGuid(0), reader.GetString(1), reader.GetString(2), reader.GetFieldValue<DateTimeOffset>(3), reader.GetFieldValue<DateTimeOffset>(4),
                reader.IsDBNull(5) ? null : OpsQueues.Parse(reader.GetString(5)), reader.IsDBNull(6) ? null : reader.GetString(6),
                reader.IsDBNull(7) ? null : reader.GetFieldValue<DateTimeOffset>(7)));
        }
        return rows;
    }

    public async Task<IReadOnlyList<ServerErrorCount>> ServerErrorsAsync(DateTimeOffset since, CancellationToken cancellationToken)
    {
        await using var command = source.CreateCommand("SELECT role,status,errors FROM ops.admin_http_errors($1)");
        command.Parameters.AddWithValue(since);
        var rows = new List<ServerErrorCount>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) { rows.Add(new ServerErrorCount(reader.GetString(0), reader.GetInt32(1), reader.GetInt64(2))); }
        return rows;
    }

    public async Task<QueueChange> RetryAsync(DatabaseSession session, QueueKind kind, Guid id, DateTimeOffset now, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        await using var command = session.Command("SELECT outcome,previous FROM ops.admin_retry($1,$2,$3)");
        command.Parameters.AddWithValue(OpsQueues.Code(kind));
        command.Parameters.AddWithValue(id);
        command.Parameters.AddWithValue(now);
        return await ChangeAsync(command, cancellationToken);
    }

    public async Task<QueueChange> CancelAsync(DatabaseSession session, Guid id, DateTimeOffset now, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        await using var command = session.Command("SELECT outcome,previous FROM ops.admin_cancel($1,$2)");
        command.Parameters.AddWithValue(id);
        command.Parameters.AddWithValue(now);
        return await ChangeAsync(command, cancellationToken);
    }

    public async Task<QueueChange> SetPausedAsync(DatabaseSession session, string jobType, bool paused, string actor, DateTimeOffset now, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);
        await using var command = session.Command("SELECT outcome,previous FROM ops.admin_set_paused($1,$2,$3,$4)");
        command.Parameters.AddWithValue(jobType);
        command.Parameters.AddWithValue(paused);
        command.Parameters.AddWithValue(actor);
        command.Parameters.AddWithValue(now);
        return await ChangeAsync(command, cancellationToken);
    }

    private static async Task<QueueChange> ChangeAsync(NpgsqlCommand command, CancellationToken cancellationToken)
    {
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken)) { return new QueueChange(QueueChangeOutcome.Refused, null); }
        var outcome = reader.GetString(0) switch
        {
            "changed" => QueueChangeOutcome.Changed,
            "unchanged" => QueueChangeOutcome.Unchanged,
            "busy" => QueueChangeOutcome.Busy,
            "missing" => QueueChangeOutcome.Missing,
            _ => QueueChangeOutcome.Refused,
        };
        return new QueueChange(outcome, reader.IsDBNull(1) ? null : reader.GetString(1));
    }

    private static QueueKind Kind(string code) => code == "job" ? QueueKind.Job : QueueKind.Event;

    private void AddTypes(NpgsqlCommand command)
    {
        command.Parameters.AddWithValue(codes.JobTypes.ToArray());
        command.Parameters.AddWithValue(codes.EventTypes.ToArray());
    }
}
