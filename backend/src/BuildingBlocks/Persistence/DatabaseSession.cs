using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace FitnessBuddy.BuildingBlocks.Persistence;

/// <summary>One database transaction shared by module contexts, outbox writes and request replay storage.
/// Disposing an uncommitted session rolls back. User identity is transaction-local, including with pooling.</summary>
public sealed class DatabaseSession : IAsyncDisposable
{
    private NpgsqlConnection? connection;
    private NpgsqlTransaction? transaction;

    public NpgsqlConnection Connection => connection ?? throw new InvalidOperationException("No active database session.");
    public NpgsqlTransaction Transaction => transaction ?? throw new InvalidOperationException("No active database transaction.");
    public bool IsActive => transaction is not null;
    public Guid? UserId { get; private set; }

    public async Task BeginAsync(NpgsqlDataSource source, Guid? userId, CancellationToken cancellationToken)
    {
        if (connection is not null) { throw new InvalidOperationException("Database session already opened."); }
        connection = await source.OpenConnectionAsync(cancellationToken);
        transaction = await connection.BeginTransactionAsync(cancellationToken);
        await SetUserAsync(userId, cancellationToken);
    }

    internal async Task SetUserAsync(Guid? userId, CancellationToken cancellationToken)
    {
        await using var command = Command("SELECT set_config('app.user_id', $1, true)");
        command.Parameters.AddWithValue(userId?.ToString() ?? "");
        await command.ExecuteNonQueryAsync(cancellationToken);
        UserId = userId;
    }

    /// <summary>Creates a parameterized command inside this transaction. Never put user input in SQL text.</summary>
    public NpgsqlCommand Command(string sql) => new(sql, Connection, Transaction);

    /// <summary>Attach a context configured with this session's Connection. Never open another transaction.</summary>
    public async Task EnlistAsync(DbContext context, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(context);
        if (!ReferenceEquals(context.Database.GetDbConnection(), Connection))
        {
            throw new InvalidOperationException("A context must use the session connection.");
        }
        await context.Database.UseTransactionAsync(Transaction, cancellationToken);
    }

    public async Task CommitAsync(CancellationToken cancellationToken) => await Transaction.CommitAsync(cancellationToken);

    public async ValueTask DisposeAsync()
    {
        if (transaction is not null) { await transaction.DisposeAsync(); }
        if (connection is not null) { await connection.DisposeAsync(); }
        transaction = null;
        connection = null;
    }
}
