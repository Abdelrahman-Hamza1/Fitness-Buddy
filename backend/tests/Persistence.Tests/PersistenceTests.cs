using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Persistence;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests;

// Real-role tests for schema migrations and the second authorization wall (04 §6).
public sealed class PersistenceTests(PostgresFixture database)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    [Trait("Rule", "04.6-migrations")]
    public async Task Migrations_are_repeatable_and_concurrent_runners_serialize()
    {
        await Task.WhenAll(database.Runner.RunAsync(database.MigratorConnection, Ct), database.Runner.RunAsync(database.MigratorConnection, Ct));
        await using var source = DatabaseConfiguration.CreateSource(database.MigratorConnection);
        await using var command = source.CreateCommand("SELECT count(*) FROM ops.__ef_migrations_history UNION ALL SELECT count(*) FROM testdata.__ef_migrations_history");
        await using var reader = await command.ExecuteReaderAsync(Ct);
        Assert.True(await reader.ReadAsync(Ct));
        Assert.Equal(4, reader.GetInt64(0));
        Assert.True(await reader.ReadAsync(Ct));
        Assert.Equal(1, reader.GetInt64(0));
    }

    [Fact]
    [Trait("Rule", "04.3.3-module-schemas")]
    public async Task Application_login_cannot_bypass_rls_own_schemas_or_read_migration_history()
    {
        await using var command = database.App.CreateCommand("SELECT rolsuper, rolbypassrls, rolcreaterole, pg_has_role(current_user, 'fb_migrator', 'MEMBER') FROM pg_roles WHERE rolname=current_user");
        await using (var reader = await command.ExecuteReaderAsync(Ct))
        {
            Assert.True(await reader.ReadAsync(Ct));
            for (var i = 0; i < 4; i++) { Assert.False(reader.GetBoolean(i)); }
        }
        await using var forbidden = database.App.CreateCommand("CREATE TABLE testdata.forbidden(id int)");
        Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => forbidden.ExecuteNonQueryAsync(Ct))).SqlState);
        await using var history = database.App.CreateCommand("SELECT * FROM ops.__ef_migrations_history");
        Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => history.ExecuteNonQueryAsync(Ct))).SqlState);
    }

    [Fact]
    [Trait("Rule", "04.6-rls")]
    public async Task Unfiltered_EF_query_reads_only_current_user_and_uses_shared_conventions()
    {
        var userA = Guid.CreateVersion7();
        var userB = Guid.CreateVersion7();
        await InsertAsync(userA, "A");
        await InsertAsync(userB, "B");
        await using var session = await database.SessionAsync(userA);
        await using var context = new SampleContext(DatabaseConfiguration.ContextOptions<SampleContext>(session.Connection, "testdata"));
        await session.EnlistAsync(context, Ct);
        var rows = await context.SampleRows.ToListAsync(Ct);
        var row = Assert.Single(rows);
        Assert.Equal(userA, row.UserId);
        Assert.Equal("A", row.Content);
        Assert.Equal(TimeSpan.Zero, row.CreatedAt.Offset);
        Assert.Equal(7, row.Id.Version);
    }

    [Fact]
    [Trait("Rule", "04.6-rls")]
    public async Task Unfiltered_updates_deletes_and_cross_user_insert_are_blocked()
    {
        var owner = Guid.CreateVersion7();
        var stranger = Guid.CreateVersion7();
        var id = await InsertAsync(owner, "private");
        await using var session = await database.SessionAsync(stranger);
        await using var update = session.Command("UPDATE testdata.sample_rows SET content='stolen' WHERE id=$1");
        update.Parameters.AddWithValue(id);
        Assert.Equal(0, await update.ExecuteNonQueryAsync(Ct));
        await using var delete = session.Command("DELETE FROM testdata.sample_rows WHERE id=$1");
        delete.Parameters.AddWithValue(id);
        Assert.Equal(0, await delete.ExecuteNonQueryAsync(Ct));
        await using var insert = session.Command("INSERT INTO testdata.sample_rows VALUES($1,$2,'forbidden',now())");
        insert.Parameters.AddWithValue(Guid.CreateVersion7());
        insert.Parameters.AddWithValue(owner);
        Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => insert.ExecuteNonQueryAsync(Ct))).SqlState);
    }

    [Fact]
    [Trait("Rule", "04.6-rls")]
    public async Task Identity_does_not_leak_when_a_pooled_connection_is_reused_after_commit_or_rollback()
    {
        var user = Guid.CreateVersion7();
        await InsertAsync(user, "pool-canary");
        var settings = new NpgsqlConnectionStringBuilder(database.AppConnection) { MaxPoolSize = 1 };
        await using var source = DatabaseConfiguration.CreateSource(settings.ConnectionString);
        int backendPid;
        await using (var session = new DatabaseSession())
        {
            await session.BeginAsync(source, user, Ct);
            await using var pid = session.Command("SELECT pg_backend_pid()");
            backendPid = (int)(await pid.ExecuteScalarAsync(Ct))!;
            await session.CommitAsync(Ct);
        }
        await using (var connection = await source.OpenConnectionAsync(Ct))
        {
            await using var query = new NpgsqlCommand("SELECT pg_backend_pid(), (SELECT count(*) FROM testdata.sample_rows)", connection);
            await using var reader = await query.ExecuteReaderAsync(Ct);
            Assert.True(await reader.ReadAsync(Ct));
            Assert.Equal(backendPid, reader.GetInt32(0));
            Assert.Equal(0, reader.GetInt64(1));
        }
        await using (var rolledBack = new DatabaseSession()) { await rolledBack.BeginAsync(source, user, Ct); }
        await using var noUser = new DatabaseSession();
        await noUser.BeginAsync(source, null, Ct);
        await using var read = noUser.Command("SELECT count(*) FROM testdata.sample_rows");
        Assert.Equal(0L, await read.ExecuteScalarAsync(Ct));
    }

    [Fact]
    [Trait("Rule", "04.6-rls")]
    public async Task Rls_with_check_prevents_transferring_an_owned_row_to_another_user()
    {
        var user = Guid.CreateVersion7();
        var row = await InsertAsync(user, "owned");
        await using var session = await database.SessionAsync(user);
        await using var transfer = session.Command("UPDATE testdata.sample_rows SET user_id=$1 WHERE id=$2");
        transfer.Parameters.AddWithValue(Guid.CreateVersion7());
        transfer.Parameters.AddWithValue(row);
        Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => transfer.ExecuteNonQueryAsync(Ct))).SqlState);
    }

    private async Task<Guid> InsertAsync(Guid user, string content)
    {
        await using var session = await database.SessionAsync(user);
        await using var context = new SampleContext(DatabaseConfiguration.ContextOptions<SampleContext>(session.Connection, "testdata"));
        await session.EnlistAsync(context, Ct);
        var row = new SampleRow { Id = new UuidV7IdGenerator(TimeProvider.System).NewId(), UserId = user, Content = content, CreatedAt = TimeProvider.System.GetUtcNow() };
        context.Add(row);
        await context.SaveChangesAsync(Ct);
        await session.CommitAsync(Ct);
        return row.Id;
    }
}
