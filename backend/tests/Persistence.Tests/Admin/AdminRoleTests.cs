using System.Net;
using FitnessBuddy.BuildingBlocks.Persistence;
using Npgsql;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23 WP1: the admin role runs on the fb_admin login, maps no /v1 route, and that login can't reach user data.
[Trait("Req", "AD-001")]
[Trait("Req", "AD-003")]
public sealed class AdminRoleTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task The_admin_role_is_ready_on_its_own_login_and_serves_no_public_api()
    {
        await using var admin = await AdminApp.StartAsync(postgres);
        using var browser = admin.NewBrowser();
        Assert.Equal(HttpStatusCode.OK, (await browser.GetAsync("/health/ready")).Status);
        await browser.SignInAsync("sub-owner", "owner@example.invalid");
        foreach (var path in new[] { "/v1/config", "/v1/me", "/v1/sync/pull", "/.well-known/jwks.json" })
        {
            Assert.Equal(HttpStatusCode.NotFound, (await browser.GetAsync(path)).Status);
        }
    }

    [Fact]
    public async Task The_admin_role_refuses_to_start_without_its_login()
    {
        await Assert.ThrowsAnyAsync<Exception>(async () =>
        {
            await using var admin = await AdminApp.StartAsync(postgres, new Dictionary<string, string?> { ["ConnectionStrings:Admin"] = "" });
        });
    }

    [Fact]
    [Trait("Rule", "B23.P3-admin-privileges")]
    public async Task Fb_admin_reaches_only_the_admin_schema_and_fb_app_none_of_it()
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        // has_*_privilege includes PUBLIC grants and role memberships, so these are effective privileges; the column check
        // also catches column-level grants, which has_table_privilege doesn't see.
        await using var tables = owner.CreateCommand("""
            SELECT n.nspname||'.'||c.relname,
                   array_to_string(ARRAY(SELECT p FROM unnest(ARRAY['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER']) AS p
                                         WHERE has_table_privilege('fb_admin', c.oid, p)), ','),
                   has_any_column_privilege('fb_admin', c.oid, 'SELECT,INSERT,UPDATE,REFERENCES'),
                   has_table_privilege('fb_app', c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
            FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
            WHERE c.relkind IN ('r','p','v','m') AND n.nspname IN ('account','admin','buddy','catalog','identity','ops','usage','userdata')
            """);
        var adminTables = new Dictionary<string, string>(StringComparer.Ordinal);
        await using (var reader = await tables.ExecuteReaderAsync(Ct))
        {
            while (await reader.ReadAsync(Ct))
            {
                var name = reader.GetString(0);
                var privileges = reader.GetString(1);
                if (privileges.Length > 0) { adminTables[name] = privileges; }
                else { Assert.False(reader.GetBoolean(2), name + ": fb_admin has a column grant"); }
                if (name.StartsWith("admin.", StringComparison.Ordinal)) { Assert.False(reader.GetBoolean(3), name); }
            }
        }
        // Its own schema, plus the one explicit grant outside it: publishing a remote-config version (read + append, B23 P1).
        Assert.Equal(["account.config_versions", "admin.audit_log", "admin.challenges", "admin.config_draft", "admin.sessions"], adminTables.Keys.Order(StringComparer.Ordinal));
        Assert.Equal("SELECT,INSERT", adminTables["account.config_versions"]);

        await using var role = owner.CreateCommand("""
            SELECT r.rolsuper, r.rolinherit, r.rolbypassrls, r.rolcreaterole, r.rolcreatedb,
                   (SELECT count(*) FROM pg_auth_members m WHERE m.member=r.oid)
            FROM pg_roles r WHERE r.rolname='fb_admin'
            """);
        await using (var reader = await role.ExecuteReaderAsync(Ct))
        {
            Assert.True(await reader.ReadAsync(Ct));
            Assert.False(reader.GetBoolean(0)); Assert.False(reader.GetBoolean(1)); Assert.False(reader.GetBoolean(2));
            Assert.False(reader.GetBoolean(3)); Assert.False(reader.GetBoolean(4)); Assert.Equal(0L, reader.GetInt64(5));
        }

        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        foreach (var sql in new[] { "SELECT count(*) FROM userdata.documents", "SELECT count(*) FROM identity.users", "SELECT count(*) FROM ops.jobs" })
        {
            await using var command = admin.CreateCommand(sql);
            var error = await Assert.ThrowsAsync<PostgresException>(async () => await command.ExecuteScalarAsync(Ct));
            Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, error.SqlState);
        }
    }

    /// <summary>The result columns every admin_* function may return (B23 P3): counts, codes, versions, timestamps; never content.</summary>
    private static readonly HashSet<string> AllowedColumns = new(StringComparer.Ordinal) { "app_version", "platform", "installs" };

    [Fact]
    [Trait("Rule", "B23.P3-admin-functions")]
    public async Task Fb_admin_can_run_only_reviewed_content_free_admin_functions()
    {
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        // Effective privileges (PUBLIC grants included), only where fb_admin can also use the schema.
        await using var functions = owner.CreateCommand("""
            SELECT n.nspname, p.proname, p.prosecdef, r.rolname, coalesce(array_to_string(p.proconfig, ','), ''),
                   coalesce(array_to_string(ARRAY(SELECT name FROM unnest(p.proargnames, p.proargmodes) AS a(name, mode) WHERE mode IN ('t','o')), ','), '')
            FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles r ON r.oid=p.proowner
            WHERE n.nspname IN ('account','admin','buddy','catalog','identity','ops','usage','userdata')
              AND has_function_privilege('fb_admin', p.oid, 'EXECUTE') AND has_schema_privilege('fb_admin', n.oid, 'USAGE')
            ORDER BY 1, 2
            """);
        var names = new List<string>();
        await using (var reader = await functions.ExecuteReaderAsync(Ct))
        {
            while (await reader.ReadAsync(Ct))
            {
                var name = reader.GetString(0) + "." + reader.GetString(1);
                names.Add(name);
                Assert.True(reader.GetString(1).StartsWith("admin_", StringComparison.Ordinal), name);
                Assert.True(reader.GetBoolean(2), name + " must be SECURITY DEFINER");
                Assert.Equal("fb_migrator", reader.GetString(3));
                Assert.StartsWith("search_path=pg_catalog", reader.GetString(4).Replace(" ", "", StringComparison.Ordinal), StringComparison.Ordinal);
                foreach (var column in reader.GetString(5).Split(',', StringSplitOptions.RemoveEmptyEntries)) { Assert.Contains(column, AllowedColumns); }
            }
        }
        Assert.Contains("identity.admin_installs", names);
    }

    [Fact]
    [Trait("Req", "AD-005")]
    public async Task The_audit_log_is_append_only_for_the_console_login()
    {
        await using var admin = DatabaseConfiguration.CreateSource(postgres.AdminConnection);
        await using (var insert = admin.CreateCommand("INSERT INTO admin.audit_log(occurred_at,actor,area,action,outcome) VALUES(now(),'test','test','probe','ok') RETURNING id"))
        {
            Assert.IsType<long>(await insert.ExecuteScalarAsync(Ct));
        }
        foreach (var sql in new[] { "UPDATE admin.audit_log SET outcome='changed'", "DELETE FROM admin.audit_log", "TRUNCATE admin.audit_log" })
        {
            await using var command = admin.CreateCommand(sql);
            var error = await Assert.ThrowsAsync<PostgresException>(async () => await command.ExecuteNonQueryAsync(Ct));
            Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, error.SqlState);
        }
        // Even the schema owner is stopped by the trigger.
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var ownerDelete = owner.CreateCommand("DELETE FROM admin.audit_log");
        await Assert.ThrowsAsync<PostgresException>(async () => await ownerDelete.ExecuteNonQueryAsync(Ct));
    }
}
