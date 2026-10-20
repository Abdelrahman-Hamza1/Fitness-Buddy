using FitnessBuddy.BuildingBlocks.Messaging;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Identity.Application;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using FitnessBuddy.Modules.Identity.Contracts;
using NpgsqlTypes;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

/// <summary>Owns all Identity erasure and address-HMAC resolution; no secrets or content leave the module.</summary>
internal sealed class IdentityErasure : IIdentityDeletion, IOutboxHandler, IDisposable
{
    private readonly TimeProvider clock;
    private readonly byte[]? pepper;
    public IdentityErasure(IOptions<IdentityOptions> options, TimeProvider clock)
    {
        this.clock = clock;
        // DI constructs the participant before the coordinator opens its transaction. Handler effects
        // remain database-only; they never consult a file/network adapter while holding locks.
        if (options.Value.Enabled) { pepper = IdentitySecrets.ReadKey(options.Value.PepperFile); }
    }

    public string EventType => UserErasure.EventType;
    public string Name => "identity.erase";

    public async Task<bool> BeginAsync(DatabaseSession session, Guid sessionId, CancellationToken cancellationToken)
    {
        var user = session.UserId ?? throw new InvalidOperationException("Missing erasure owner.");
        await using var command = session.Command("SELECT identity.begin_deletion($1,$2,$3)");
        command.Parameters.AddWithValue(user); command.Parameters.AddWithValue(sessionId); command.Parameters.AddWithValue(clock.GetUtcNow());
        return (bool)(await command.ExecuteScalarAsync(cancellationToken))!;
    }

    public async Task HandleAsync(QueueMessage message, DatabaseSession session, CancellationToken cancellationToken)
    {
        if (session.UserId is not Guid user || message.UserId != user) { throw new InvalidOperationException("Invalid erasure scope."); }
        var addresses = new Dictionary<string, byte[]>(StringComparer.Ordinal);
        await using (var command = session.Command("SELECT provider,subject,email FROM identity.erasure_identifiers($1)"))
        {
            command.Parameters.AddWithValue(user);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                byte[]? hash = reader.GetString(0) switch
                {
                    "email" or "challenge" => Convert.FromHexString(reader.GetString(1)),
                    "google" when !string.IsNullOrWhiteSpace(reader.GetString(2)) => HMACSHA256.HashData(pepper ?? throw new InvalidOperationException("Identity lookup material unavailable."), Encoding.UTF8.GetBytes("email-address\0" + reader.GetString(2).Trim().ToLowerInvariant())),
                    _ => null,
                };
                if (hash is not null) { addresses[Convert.ToHexStringLower(hash)] = hash; }
            }
        }
        await using var erase = session.Command("SELECT identity.erase_user($1,$2)");
        erase.Parameters.AddWithValue(user);
        erase.Parameters.AddWithValue(NpgsqlDbType.Array | NpgsqlDbType.Bytea, addresses.Values.ToArray());
        await erase.ExecuteNonQueryAsync(cancellationToken);
    }

    public void Dispose() { if (pepper is not null) { CryptographicOperations.ZeroMemory(pepper); } }
}
