using Cronos;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Persistence;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.BuildingBlocks.Jobs;

/// <summary>A UTC five-field cron schedule. Missed ticks coalesce into one durable job on the next worker tick.</summary>
public sealed record JobSchedule(string Name, string Cron, string JobType, string Payload = "{}");

/// <summary>Persists schedule cursors and creates uniquely keyed jobs atomically, safe with multiple workers.</summary>
public sealed class JobScheduler(NpgsqlDataSource source, TimeProvider clock, IIdGenerator ids)
{
    public async Task RegisterAsync(JobSchedule schedule, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(schedule);
        var expression = CronExpression.Parse(schedule.Cron);
        var next = expression.GetNextOccurrence(clock.GetUtcNow(), TimeZoneInfo.Utc) ?? throw new InvalidOperationException("Schedule has no next occurrence.");
        await using var command = source.CreateCommand("""
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
    }

    public async Task<bool> TickAsync(CancellationToken cancellationToken)
    {
        await using var session = new DatabaseSession();
        await session.BeginAsync(source, null, cancellationToken);
        var now = clock.GetUtcNow();
        string name, cron, jobType, payload;
        DateTimeOffset due;
        await using (var claim = session.Command("SELECT name,cron,job_type,payload::text,next_due FROM ops.schedules WHERE next_due <= $1 ORDER BY next_due,name FOR UPDATE SKIP LOCKED LIMIT 1"))
        {
            claim.Parameters.AddWithValue(now);
            await using var reader = await claim.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken)) { return false; }
            name = reader.GetString(0); cron = reader.GetString(1); jobType = reader.GetString(2); payload = reader.GetString(3); due = reader.GetFieldValue<DateTimeOffset>(4);
        }
        var next = CronExpression.Parse(cron).GetNextOccurrence(now, TimeZoneInfo.Utc) ?? throw new InvalidOperationException("Schedule has no next occurrence.");
        await using var insert = session.Command("INSERT INTO ops.jobs(id,job_type,payload,created_at,available_at,dedup_key) VALUES($1,$2,$3,$4,$4,$5) ON CONFLICT(dedup_key) DO NOTHING");
        insert.Parameters.AddWithValue(ids.NewId());
        insert.Parameters.AddWithValue(jobType);
        insert.Parameters.AddWithValue(NpgsqlDbType.Jsonb, payload);
        insert.Parameters.AddWithValue(now);
        insert.Parameters.AddWithValue(name + ":" + due.ToUnixTimeSeconds().ToString(System.Globalization.CultureInfo.InvariantCulture));
        await insert.ExecuteNonQueryAsync(cancellationToken);
        await using var advance = session.Command("UPDATE ops.schedules SET next_due=$2 WHERE name=$1");
        advance.Parameters.AddWithValue(name);
        advance.Parameters.AddWithValue(next);
        await advance.ExecuteNonQueryAsync(cancellationToken);
        await session.CommitAsync(cancellationToken);
        return true;
    }
}
