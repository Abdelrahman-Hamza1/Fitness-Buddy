using System.Security.Cryptography;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Identity;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Rule", "04.5-tokens")]
[Trait("Rule", "04.6-authz")]
public sealed class IdentityKeyBoundaryTests(PostgresFixture postgres)
{
    private static readonly string[] CapabilityNames = ["check_active", "consume_email", "create_guest", "link_google", "read_keyring", "read_session", "revoke_session", "rotate_refresh", "sign_in_provider", "start_email"];

    [Fact]
    public async Task Capability_inventory_and_force_rls_match_the_reviewed_boundary_exactly()
    {
        await using var command = postgres.App.CreateCommand("SELECT p.proname,p.prosecdef,r.rolname,array_to_string(p.proconfig,',') FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles r ON r.oid=p.proowner WHERE n.nspname='identity' AND has_function_privilege('fb_app',p.oid,'EXECUTE') ORDER BY p.proname");
        await using var reader = await command.ExecuteReaderAsync(TestContext.Current.CancellationToken);
        var names = new List<string>();
        while (await reader.ReadAsync(TestContext.Current.CancellationToken))
        {
            names.Add(reader.GetString(0)); Assert.True(reader.GetBoolean(1)); Assert.Equal("fb_migrator", reader.GetString(2));
            Assert.Equal("search_path=pg_catalog,identity,pg_temp", reader.GetString(3).Replace(" ", "", StringComparison.Ordinal));
        }
        Assert.Equal(CapabilityNames, names);
        await reader.DisposeAsync();
        await using var policy = postgres.App.CreateCommand("SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='identity' AND c.relkind='r' AND c.relname<>'__ef_migrations_history' AND (NOT c.relrowsecurity OR NOT c.relforcerowsecurity OR has_table_privilege('fb_app',c.oid,'SELECT,INSERT,UPDATE,DELETE'))");
        Assert.Equal(0L, await policy.ExecuteScalarAsync(TestContext.Current.CancellationToken));
        await using var roles = postgres.App.CreateCommand("SELECT has_schema_privilege('fb_app','identity','CREATE') OR pg_has_role('fb_app','fb_migrator','MEMBER')");
        Assert.False((bool)(await roles.ExecuteScalarAsync(TestContext.Current.CancellationToken))!);
    }
    [Fact]
    public async Task Ciphertext_nonce_tag_aad_and_wrong_full_length_wrapping_key_all_fail_closed()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        var guest = await h.GuestAsync();
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        string kid; string version; byte[] cipher; byte[] nonce; byte[] tag;
        await using (var read = owner.CreateCommand("SELECT kid,wrapping_version,ciphertext,nonce,tag FROM identity.signing_keys WHERE active"))
        {
            await using var reader = await read.ExecuteReaderAsync(TestContext.Current.CancellationToken); Assert.True(await reader.ReadAsync(TestContext.Current.CancellationToken));
            kid = reader.GetString(0); version = reader.GetString(1); cipher = (byte[])reader[2]; nonce = (byte[])reader[3]; tag = (byte[])reader[4];
        }
        foreach (var (column, original) in new[] { ("ciphertext", cipher), ("nonce", nonce), ("tag", tag) })
        {
            var changed = original.ToArray(); changed[0] ^= 1;
            try { await UpdateBytes(column, changed); await Assert.ThrowsAsync<AuthenticationTagMismatchException>(() => h.Tokens.SignAsync(guest, TestContext.Current.CancellationToken)); }
            finally { await UpdateBytes(column, original); }
        }
        var keyFile = Path.Combine(h.DirectoryPath, version + ".key"); var originalKey = await File.ReadAllBytesAsync(keyFile, TestContext.Current.CancellationToken);
        try
        {
            await File.WriteAllBytesAsync(keyFile, RandomNumberGenerator.GetBytes(32), TestContext.Current.CancellationToken);
            await Assert.ThrowsAsync<AuthenticationTagMismatchException>(() => h.Tokens.SignAsync(guest, TestContext.Current.CancellationToken));
        }
        finally { await File.WriteAllBytesAsync(keyFile, originalKey, TestContext.Current.CancellationToken); }
        // Changing kid changes authenticated associated data, even with untouched ciphertext/tag.
        try
        {
            await using var change = owner.CreateCommand("UPDATE identity.signing_keys SET kid=$1 WHERE kid=$2"); change.Parameters.AddWithValue(kid + "-changed"); change.Parameters.AddWithValue(kid); await change.ExecuteNonQueryAsync(TestContext.Current.CancellationToken);
            await Assert.ThrowsAsync<AuthenticationTagMismatchException>(() => h.Tokens.SignAsync(guest, TestContext.Current.CancellationToken));
        }
        finally
        {
            await using var restore = owner.CreateCommand("UPDATE identity.signing_keys SET kid=$1 WHERE kid=$2"); restore.Parameters.AddWithValue(kid); restore.Parameters.AddWithValue(kid + "-changed"); await restore.ExecuteNonQueryAsync(TestContext.Current.CancellationToken);
        }
        Assert.NotNull(await h.Tokens.ValidateAsync(await h.Tokens.SignAsync(guest, TestContext.Current.CancellationToken), TestContext.Current.CancellationToken));
        async Task UpdateBytes(string column, byte[] value)
        {
            await using var update = owner.CreateCommand($"UPDATE identity.signing_keys SET {column}=$1 WHERE kid=$2"); update.Parameters.AddWithValue(value); update.Parameters.AddWithValue(kid); await update.ExecuteNonQueryAsync(TestContext.Current.CancellationToken);
        }
    }
    [Fact]
    public async Task Interrupted_rewrap_keeps_every_row_recoverable_and_can_be_retried()
    {
        await using var h = new IdentityHarness(postgres); await h.InitializeAsync();
        await IdentityModule.MaintainSigningKeysAsync(postgres.MigratorConnection, h.DirectoryPath, "v1", "rewrap", h.Clock, TestContext.Current.CancellationToken);
        await IdentityModule.MaintainSigningKeysAsync(postgres.MigratorConnection, h.DirectoryPath, "v1", "rotate", h.Clock, TestContext.Current.CancellationToken);
        var guest = await h.GuestAsync(); var token = await h.Tokens.SignAsync(guest, TestContext.Current.CancellationToken);
        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using (var trigger = owner.CreateCommand("CREATE FUNCTION identity.test_rewrap_failure() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF EXISTS(SELECT 1 FROM identity.signing_keys WHERE wrapping_version=NEW.wrapping_version) THEN RAISE EXCEPTION 'synthetic-interrupted-rewrap'; END IF; RETURN NEW; END $$; CREATE TRIGGER test_rewrap_failure BEFORE UPDATE OF wrapping_version ON identity.signing_keys FOR EACH ROW EXECUTE FUNCTION identity.test_rewrap_failure()"))
        { await trigger.ExecuteNonQueryAsync(TestContext.Current.CancellationToken); }
        try { await Assert.ThrowsAsync<Npgsql.PostgresException>(() => IdentityModule.MaintainSigningKeysAsync(postgres.MigratorConnection, h.DirectoryPath, "v2", "rewrap", h.Clock, TestContext.Current.CancellationToken)); }
        finally
        {
            await using var drop = owner.CreateCommand("DROP TRIGGER test_rewrap_failure ON identity.signing_keys; DROP FUNCTION identity.test_rewrap_failure()"); await drop.ExecuteNonQueryAsync(TestContext.Current.CancellationToken);
        }
        Assert.NotNull(await h.Tokens.ValidateAsync(token, TestContext.Current.CancellationToken));
        Assert.NotNull(await h.Tokens.ValidateAsync(await h.Tokens.SignAsync(guest, TestContext.Current.CancellationToken), TestContext.Current.CancellationToken));
        await IdentityModule.MaintainSigningKeysAsync(postgres.MigratorConnection, h.DirectoryPath, "v2", "rewrap", h.Clock, TestContext.Current.CancellationToken);
        Assert.NotNull(await h.Tokens.ValidateAsync(token, TestContext.Current.CancellationToken));
    }
}
