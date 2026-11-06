using FitnessBuddy.BuildingBlocks.Persistence;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23b security review: the worker has its own login (fb_worker), so a compromised API (fb_app) can't fake a healthy worker or
// erase the console's counters. fb_worker has exactly fb_app's privileges plus the worker-only grants, under the same RLS.
[Trait("Req", "AD-010")]
[Trait("Req", "AD-014")]
public sealed class WorkerLoginTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    /// <summary>What only the worker may do beyond fb_app: its heartbeats and expiring the console's global counters.</summary>
    private static readonly Dictionary<string, string> WorkerOnly = new(StringComparer.Ordinal)
    {
        ["catalog.off_lookup_daily"] = "SELECT,DELETE",
        ["ops.http_errors_hourly"] = "SELECT,DELETE",
        ["ops.worker_heartbeats"] = "SELECT,INSERT,UPDATE,DELETE",
    };

    [Fact]
    [Trait("Rule", "B23.P3-worker-login")]
    public async Task Fb_worker_has_fb_app_privileges_plus_only_the_worker_grants_and_cannot_become_fb_app()
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var tables = owner.CreateCommand("""
            SELECT n.nspname||'.'||c.relname,
                   array_to_string(ARRAY(SELECT p FROM unnest(ARRAY['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER']) AS p
                                         WHERE has_table_privilege('fb_worker', c.oid, p) AND NOT has_table_privilege('fb_app', c.oid, p)), ','),
                   array_to_string(ARRAY(SELECT p FROM unnest(ARRAY['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER']) AS p
                                         WHERE has_table_privilege('fb_app', c.oid, p) AND NOT has_table_privilege('fb_worker', c.oid, p)), ',')
            FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE c.relkind IN ('r','p','v','m') AND n.nspname IN ('account','admin','buddy','catalog','identity','ops','usage','userdata','testdata')
            """);
        var extra = new Dictionary<string, string>(StringComparer.Ordinal);
        await using (var reader = await tables.ExecuteReaderAsync(Ct))
        {
            while (await reader.ReadAsync(Ct))
            {
                if (reader.GetString(1).Length > 0) { extra[reader.GetString(0)] = reader.GetString(1); }
                Assert.True(reader.GetString(2).Length == 0, reader.GetString(0) + ": fb_worker lacks an fb_app privilege");
            }
        }
        Assert.Equal(WorkerOnly, extra);

        // The API login has no write on what the worker owns.
        foreach (var table in WorkerOnly.Keys)
        {
            Assert.False(await ScalarAsync<bool>(owner, $"SELECT has_table_privilege('fb_app','{table}','INSERT,UPDATE,DELETE,TRUNCATE')"), table);
        }
        Assert.False(await ScalarAsync<bool>(owner, "SELECT has_table_privilege('fb_app','ops.worker_heartbeats','SELECT')"));

        await using var role = owner.CreateCommand("""
            SELECT r.rolsuper, r.rolinherit, r.rolbypassrls, r.rolcreaterole, r.rolcreatedb, r.rolcanlogin,
                   (SELECT string_agg(g.rolname||':'||m.inherit_option::text||':'||m.set_option::text||':'||m.admin_option::text, ',') FROM pg_auth_members m
                    JOIN pg_roles g ON g.oid=m.roleid WHERE m.member=r.oid),
                   (SELECT count(*) FROM pg_auth_members m JOIN pg_roles a ON a.oid=m.member WHERE a.rolname='fb_app'),
                   (SELECT count(*) FROM pg_auth_members m WHERE m.roleid=r.oid)
            FROM pg_roles r WHERE r.rolname='fb_worker'
            """);
        await using (var reader = await role.ExecuteReaderAsync(Ct))
        {
            Assert.True(await reader.ReadAsync(Ct));
            Assert.False(reader.GetBoolean(0)); Assert.True(reader.GetBoolean(1)); Assert.False(reader.GetBoolean(2));
            Assert.False(reader.GetBoolean(3)); Assert.False(reader.GetBoolean(4)); Assert.True(reader.GetBoolean(5));
            Assert.Equal("fb_app:true:false:false", reader.GetString(6));
            Assert.Equal(0L, reader.GetInt64(7));
            Assert.Equal(0L, reader.GetInt64(8));
        }

        await using var worker = DatabaseConfiguration.CreateSource(postgres.WorkerConnection);
        await using var setRole = worker.CreateCommand("SET ROLE fb_app");
        Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => setRole.ExecuteNonQueryAsync(Ct))).SqlState);
    }

    [Fact]
    [Trait("Rule", "B23.P3-worker-login")]
    public async Task The_api_login_cannot_forge_heartbeats_or_erase_counters_and_counts_only_grow_for_its_own_role()
    {
        var hour = new DateTimeOffset(2026, 3, 4, 5, 0, 0, TimeSpan.Zero).AddHours(Random.Shared.Next(0, 5000));
        foreach (var sql in new[]
        {
            "INSERT INTO ops.worker_heartbeats(instance,role,build,started_at,last_beat_at) VALUES(gen_random_uuid(),'worker','1.0.0',now(),now())",
            "UPDATE ops.worker_heartbeats SET last_beat_at=now()",
            "DELETE FROM ops.worker_heartbeats",
            "SELECT count(*) FROM ops.worker_heartbeats",
            "DELETE FROM ops.http_errors_hourly",
            "UPDATE ops.http_errors_hourly SET count=0",
            "INSERT INTO ops.http_errors_hourly(hour,role,status,count) VALUES(now(),'worker',500,1)",
            "DELETE FROM catalog.off_lookup_daily",
            "UPDATE catalog.off_lookup_daily SET count=0",
            "INSERT INTO catalog.off_lookup_daily(day,outcome,rule,count) VALUES(current_date,'invalid','',1)",
        })
        {
            await using var command = postgres.App.CreateCommand(sql);
            var error = await Assert.ThrowsAsync<PostgresException>(() => command.ExecuteNonQueryAsync(Ct));
            Assert.True(error.SqlState == PostgresErrorCodes.InsufficientPrivilege, sql);
        }

        // Through the add-only function, the role is the calling login's and non-positive amounts are ignored.
        await CountErrorsAsync(postgres.App, hour, 500, 3);
        await CountErrorsAsync(postgres.App, hour, 500, -2);
        await CountErrorsAsync(postgres.App, hour, 500, 0);
        await CountErrorsAsync(postgres.Worker, hour, 500, 1);
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using (var read = owner.CreateCommand("SELECT string_agg(role||'='||count, ',' ORDER BY role) FROM ops.http_errors_hourly WHERE hour=$1"))
        {
            read.Parameters.AddWithValue(hour);
            Assert.Equal("api=3,worker=1", await read.ExecuteScalarAsync(Ct));
        }

        // The lookup counters are the API's alone; the console login runs none of the counting functions.
        await using (var lookups = postgres.Worker.CreateCommand("SELECT catalog.count_lookups(ARRAY[current_date],ARRAY['invalid'],ARRAY[''],ARRAY[1::bigint])"))
        {
            Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => lookups.ExecuteNonQueryAsync(Ct))).SqlState);
        }
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        await using (var count = admin.CreateCommand("SELECT ops.count_http_errors(ARRAY[now()],ARRAY[500],ARRAY[1::bigint])"))
        {
            Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => count.ExecuteNonQueryAsync(Ct))).SqlState);
        }

        await using var cleanup = owner.CreateCommand("DELETE FROM ops.http_errors_hourly WHERE hour=$1");
        cleanup.Parameters.AddWithValue(hour);
        await cleanup.ExecuteNonQueryAsync(Ct);
    }

    [Fact]
    [Trait("Rule", "04.6-rls")]
    public async Task The_worker_login_sees_and_writes_only_the_session_users_rows()
    {
        var (mine, other) = (Guid.NewGuid(), Guid.NewGuid());
        foreach (var user in new[] { mine, other })
        {
            await using var session = await postgres.SessionAsync(user);
            await using var insert = session.Command("INSERT INTO testdata.sample_rows(id,user_id,content,created_at) VALUES(gen_random_uuid(),$1,'worker-rls',now())");
            insert.Parameters.AddWithValue(user);
            await insert.ExecuteNonQueryAsync(Ct);
            await session.CommitAsync(Ct);
        }
        await using (var session = await postgres.WorkerSessionAsync(mine))
        {
            await using var visible = session.Command("SELECT count(*) FILTER (WHERE user_id=$1), count(*) FILTER (WHERE user_id=$2) FROM testdata.sample_rows");
            visible.Parameters.AddWithValue(mine);
            visible.Parameters.AddWithValue(other);
            await using (var reader = await visible.ExecuteReaderAsync(Ct))
            {
                Assert.True(await reader.ReadAsync(Ct));
                Assert.Equal(1L, reader.GetInt64(0));
                Assert.Equal(0L, reader.GetInt64(1));
            }
            await using var foreign = session.Command("INSERT INTO testdata.sample_rows(id,user_id,content,created_at) VALUES(gen_random_uuid(),$1,'worker-rls',now())");
            foreign.Parameters.AddWithValue(other);
            Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, (await Assert.ThrowsAsync<PostgresException>(() => foreign.ExecuteNonQueryAsync(Ct))).SqlState);
        }
        await using (var session = await postgres.WorkerSessionAsync())
        {
            await using var none = session.Command("SELECT count(*) FROM testdata.sample_rows");
            Assert.Equal(0L, await none.ExecuteScalarAsync(Ct));
        }
    }

    private static async Task CountErrorsAsync(NpgsqlDataSource source, DateTimeOffset hour, int status, long count)
    {
        await using var command = source.CreateCommand("SELECT ops.count_http_errors($1,$2,$3)");
        command.Parameters.AddWithValue(new[] { hour });
        command.Parameters.AddWithValue(new[] { status });
        command.Parameters.AddWithValue(new[] { count });
        await command.ExecuteNonQueryAsync(Ct);
    }

    private static async Task<T> ScalarAsync<T>(NpgsqlDataSource source, string sql)
    {
        await using var command = source.CreateCommand(sql);
        return (T)(await command.ExecuteScalarAsync(Ct))!;
    }
}
