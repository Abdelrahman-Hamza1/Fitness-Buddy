using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Identity.Application;
using FitnessBuddy.Modules.Identity.Contracts;
using Npgsql;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

internal sealed class PostgresIdentityStore(NpgsqlDataSource source, TimeProvider clock) : IIdentityStore, FitnessBuddy.BuildingBlocks.Auth.IUserLifecycle
{
    public Task<IdentitySession?> CreateGuestAsync(Guid user, SessionMaterial m, CancellationToken ct) =>
        ReadAsync("SELECT * FROM identity.create_guest($1,$2,$3,$4,$5)", [user, m.SessionId, m.DeviceId, m.RefreshHash, Now], ct);
    public Task<IdentitySession?> GoogleSignInAsync(GoogleIdentity i, Guid user, SessionMaterial m, CancellationToken ct) =>
        ReadAsync("SELECT * FROM identity.sign_in_provider($1,$2,$3,$4,$5,$6,$7,$8)", ["google", i.Subject, i.Email, user, m.SessionId, m.DeviceId, m.RefreshHash, Now], ct);
    public Task<IdentitySession?> RotateAsync(byte[] oldHash, byte[] newHash, CancellationToken ct) =>
        ReadAsync("SELECT * FROM identity.rotate_refresh($1,$2,$3)", [oldHash, newHash, Now], ct);
    public Task<IdentitySession?> ReadSessionAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken) =>
        ReadAsync("SELECT * FROM identity.read_session($1,$2,$3)", [userId, sessionId, Now], cancellationToken);
    public async Task RevokeAsync(Guid user, Guid session, CancellationToken ct)
    {
        await using var command = Command("SELECT identity.revoke_session($1,$2,$3)", [user, session, Now]);
        await command.ExecuteNonQueryAsync(ct);
    }
    public async Task<bool> StartEmailAsync(Guid challenge, byte[] addressHash, byte[] codeHash, string purpose, IdentitySession? principal, byte[] ipHash, CancellationToken ct)
    {
        await using var command = Command("SELECT identity.start_email($1,$2,$3,$4,$5,$6,$7,$8)",
            [challenge, addressHash, codeHash, purpose, NullableId(principal?.UserId), NullableId(principal?.SessionId), ipHash, Now]);
        return (bool)(await command.ExecuteScalarAsync(ct))!;
    }
    public Task<IdentitySession?> ConsumeEmailAsync(Guid challenge, byte[] codeHash, string purpose, IdentitySession? principal, Guid user, SessionMaterial m, CancellationToken ct) =>
        ReadAsync("SELECT * FROM identity.consume_email($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)",
            [challenge, codeHash, purpose, NullableId(principal?.UserId), NullableId(principal?.SessionId), user, m.SessionId, m.DeviceId, m.RefreshHash, Now], ct);
    public Task<IdentitySession?> LinkGoogleAsync(IdentitySession p, GoogleIdentity i, SessionMaterial m, CancellationToken ct) =>
        ReadAsync("SELECT * FROM identity.link_google($1,$2,$3,$4,$5,$6,$7,$8)", [p.UserId, p.SessionId, i.Subject, i.Email, m.SessionId, m.DeviceId, m.RefreshHash, Now], ct);

    public async Task<bool> CheckActiveAsync(DatabaseSession session, Guid userId, Guid sessionId, bool registeredOnly, CancellationToken cancellationToken)
    {
        await using var command = session.Command("SELECT identity.check_active($1,$2,$3,$4)");
        command.Parameters.AddWithValue(userId); command.Parameters.AddWithValue(sessionId);
        command.Parameters.AddWithValue(registeredOnly); command.Parameters.AddWithValue(Now);
        return (bool)(await command.ExecuteScalarAsync(cancellationToken))!;
    }

    public async Task<bool> IsActiveAsync(DatabaseSession session, Guid? sessionId, CancellationToken cancellationToken)
    {
        if (session.UserId is not Guid user) { return false; }
        if (sessionId is Guid principal) { return await CheckActiveAsync(session, user, principal, false, cancellationToken); }
        await using var command = session.Command("SELECT identity.check_user_active($1)");
        command.Parameters.AddWithValue(user);
        return (bool)(await command.ExecuteScalarAsync(cancellationToken))!;
    }

    private DateTimeOffset Now => clock.GetUtcNow();
    private static NpgsqlParameter NullableId(Guid? id) => new() { NpgsqlDbType = NpgsqlDbType.Uuid, Value = (object?)id ?? DBNull.Value };
    private NpgsqlCommand Command(string sql, object[] values)
    {
        var command = source.CreateCommand(sql);
        foreach (var value in values)
        {
            command.Parameters.Add(value is NpgsqlParameter parameter ? parameter : new NpgsqlParameter { Value = value });
        }
        return command;
    }
    private async Task<IdentitySession?> ReadAsync(string sql, object[] values, CancellationToken ct)
    {
        try
        {
            await using var command = Command(sql, values);
            await using var reader = await command.ExecuteReaderAsync(ct);
            if (!await reader.ReadAsync(ct)) { return null; }
            return new IdentitySession(reader.GetGuid(0), reader.GetBoolean(1), reader.GetGuid(2), reader.GetFieldValue<DateTimeOffset>(3));
        }
        catch (PostgresException exception) when (exception.SqlState == "P0002") { throw new IdentityConflictException(); }
    }
}
