using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Usage.Contracts;

namespace FitnessBuddy.Modules.Usage.Infrastructure;

internal sealed class PostgresUsageRecorder(TimeProvider clock) : IUsageRecorder
{
    public async Task<UsageReservation> ReserveAsync(DatabaseSession session, string model, int defaultCeiling, DateOnly day, bool newMessage, CancellationToken cancellationToken)
    {
        var user = session.UserId ?? throw new InvalidOperationException("Missing usage owner.");
        var ceiling = defaultCeiling;
        await using (var limit = session.Command("SELECT daily_calls FROM usage.limit_overrides WHERE user_id=$1"))
        {
            limit.Parameters.AddWithValue(user);
            if (await limit.ExecuteScalarAsync(cancellationToken) is int calls) { ceiling = calls; }
        }
        // The first call of a day inserts unconditionally below (only the conflict update checks the ceiling), so refuse first.
        if (ceiling <= 0) { return new UsageReservation(false, 0); }
        await using var command = session.Command("""
            INSERT INTO usage.daily(user_id,day,model,calls,messages,input_tokens,cached_input_tokens,output_tokens,estimated_usd)
            VALUES($1,$2,$3,1,$5,0,0,0,0) ON CONFLICT(user_id,day,model) DO UPDATE SET calls=usage.daily.calls+1,messages=usage.daily.messages+excluded.messages
            WHERE usage.daily.calls<$4 RETURNING calls
            """);
        command.Parameters.AddWithValue(user); command.Parameters.AddWithValue(day);
        command.Parameters.AddWithValue(model); command.Parameters.AddWithValue(ceiling); command.Parameters.AddWithValue(newMessage ? 1 : 0);
        return new UsageReservation(await command.ExecuteScalarAsync(cancellationToken) is not null, ceiling);
    }
    public async Task RecordAsync(DatabaseSession session, UsageCharge charge, CancellationToken cancellationToken)
    {
        await using var command = session.Command("""
            UPDATE usage.daily SET input_tokens=input_tokens+$4,cached_input_tokens=cached_input_tokens+$5,
              output_tokens=output_tokens+$6,estimated_usd=estimated_usd+$7
            WHERE user_id=$1 AND day=$2 AND model=$3
            """);
        command.Parameters.AddWithValue(session.UserId!.Value); command.Parameters.AddWithValue(charge.Day);
        command.Parameters.AddWithValue(charge.Model); command.Parameters.AddWithValue(charge.InputTokens); command.Parameters.AddWithValue(charge.CachedInputTokens);
        command.Parameters.AddWithValue(charge.OutputTokens); command.Parameters.AddWithValue(charge.EstimatedUsd);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
    public async Task CleanupAsync(DatabaseSession session, CancellationToken cancellationToken)
    {
        await using var command = session.Command("DELETE FROM usage.daily WHERE user_id=$1 AND day<$2");
        command.Parameters.AddWithValue(session.UserId!.Value); command.Parameters.AddWithValue(DateOnly.FromDateTime(clock.GetUtcNow().UtcDateTime).AddDays(-90));
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
