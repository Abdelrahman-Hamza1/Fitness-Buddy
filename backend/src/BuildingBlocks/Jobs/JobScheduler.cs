using Cronos;
using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.BuildingBlocks.Recovery;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Persistence;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.BuildingBlocks.Jobs;

/// <summary>A UTC five-field cron schedule. Missed ticks coalesce into one durable job on the next worker tick.</summary>
public sealed record JobSchedule(string Name, string Cron, string JobType, string Payload = "{}");

/// <summary>Persists schedule cursors and creates uniquely keyed jobs atomically, safe with multiple workers.</summary>
public sealed class JobScheduler(NpgsqlDataSource source, TimeProvider clock, IIdGenerator ids, IUserLifecycle lifecycle, RecoveryBarrier recovery)
{
    public async Task RegisterAsync(JobSchedule schedule, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(schedule);
        var expression = CronExpression.Parse(schedule.Cron);
        var next = expression.GetNextOccurrence(clock.GetUtcNow(), TimeZoneInfo.Utc) ?? throw new InvalidOperationException("Schedule has no next occurrence.");
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, null, cancellationToken);
        await RecoveryBarrier.LockAsync(session, exclusive: false, cancellationToken);
        await recovery.VerifyAsync(session, cancellationToken);
        await using var command = session.Command("""
            INSERT INTO ops.schedules(name,cron,job_type,payload,next_due) VALUES($1,$2,$3,$4,$5)
            ON CONFLICT(name) DO UPDATE SET cron=excluded.cron,job_type=excluded.job_type,payload=excluded.payload,
                next_due=CASE WHEN ops.schedules.cron=excluded.cron THEN ops.schedules.next_due ELSE excluded.next_due END
            """);
        command.Parameters.AddWithValue(schedule.Name);
        command.Parameters.AddWithValue(schedule.Cron);
        command.Parameters.AddWithValue(schedule.JobType);
        command.Parameters.AddWithValue(NpgsqlDbType.Jsonb, schedule.Payload);
        command.Parameters.AddWithValue(next);
        await command.ExecuteNonQueryAsync(cancellationToken);
        await session.CommitAsync(cancellationToken);
    }

    private sealed record Candidate(string Name, Guid? UserId);

    public async Task<bool> TickAsync(CancellationToken cancellationToken)
    {
        var candidates = new List<Candidate>();
        await using (var discover = source.CreateCommand("SELECT name,user_id FROM ops.schedules WHERE next_due <= $1 ORDER BY next_due,name LIMIT 32"))
        {
            discover.Parameters.AddWithValue(clock.GetUtcNow());
            await using var reader = await discover.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            { candidates.Add(new Candidate(reader.GetString(0), reader.IsDBNull(1) ? null : reader.GetGuid(1))); }
        }
        foreach (var candidate in candidates)
        { if (await TryTickAsync(candidate, cancellationToken)) { return true; } }
        return false;
    }

    private async Task<bool> TryTickAsync(Candidate candidate, CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, candidate.UserId, cancellationToken);
        await RecoveryBarrier.LockAsync(session, exclusive: false, cancellationToken);
        await recovery.VerifyAsync(session, cancellationToken);
        if (candidate.UserId is Guid owner && !await UserLifecycleLock.TryAcquireAsync(session, owner, cancellationToken)) { return false; }
        var now = clock.GetUtcNow();
        string name, cron, jobType, payload;
        DateTimeOffset due;
        Guid? userId;
        await using (var claim = session.Command("SELECT name,cron,job_type,payload::text,next_due,user_id FROM ops.schedules WHERE name=$1 AND next_due <= $2 AND user_id IS NOT DISTINCT FROM $3 FOR UPDATE SKIP LOCKED"))
        {
            claim.Parameters.AddWithValue(candidate.Name); claim.Parameters.AddWithValue(now);
            claim.Parameters.AddWithValue(NpgsqlDbType.Uuid, (object?)candidate.UserId ?? DBNull.Value);
            await using var reader = await claim.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken)) { return false; }
            name = reader.GetString(0); cron = reader.GetString(1); jobType = reader.GetString(2); payload = reader.GetString(3); due = reader.GetFieldValue<DateTimeOffset>(4); userId = reader.IsDBNull(5) ? null : reader.GetGuid(5);
        }
        if (userId.HasValue && !await lifecycle.IsActiveAsync(session, null, cancellationToken))
        {
            await OpsErasure.DeleteUserAsync(session, cancellationToken);
            await session.CommitAsync(cancellationToken);
            return true;
        }
        var next = CronExpression.Parse(cron).GetNextOccurrence(now, TimeZoneInfo.Utc) ?? throw new InvalidOperationException("Schedule has no next occurrence.");
        await using var insert = session.Command("INSERT INTO ops.jobs(id,job_type,payload,created_at,available_at,dedup_key,user_id) VALUES($1,$2,$3,$4,$4,$5,$6) ON CONFLICT(dedup_key) DO NOTHING");
        insert.Parameters.AddWithValue(ids.NewId());
        insert.Parameters.AddWithValue(jobType);
        insert.Parameters.AddWithValue(NpgsqlDbType.Jsonb, payload);
        insert.Parameters.AddWithValue(now);
        insert.Parameters.AddWithValue(name + ":" + due.ToUnixTimeSeconds().ToString(System.Globalization.CultureInfo.InvariantCulture));
        insert.Parameters.AddWithValue(NpgsqlDbType.Uuid, (object?)userId ?? DBNull.Value);
        await insert.ExecuteNonQueryAsync(cancellationToken);
        await using var advance = session.Command("UPDATE ops.schedules SET next_due=$2 WHERE name=$1");
        advance.Parameters.AddWithValue(name);
        advance.Parameters.AddWithValue(next);
        await advance.ExecuteNonQueryAsync(cancellationToken);
        await session.CommitAsync(cancellationToken);
        return true;
    }
}
