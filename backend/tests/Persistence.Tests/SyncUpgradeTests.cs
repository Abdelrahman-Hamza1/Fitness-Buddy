using FitnessBuddy.Modules.UserData.Infrastructure.Migrations;
using FitnessBuddy.BuildingBlocks.Ids;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.UserData;
using FitnessBuddy.Modules.UserData.Infrastructure;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Persistence.Tests;

[Trait("Req", "AC-012")]
[Trait("Rule", "05.7-retention")]
public sealed class SyncUpgradeTests(PostgresFixture database)
{
    [Fact]
    public async Task Pre_B05_numeric_payloads_survive_upgrade_and_can_expire_without_poisoning_cleanup()
    {
        var ct = TestContext.Current.CancellationToken; var name = "fb_upgrade_" + Guid.NewGuid().ToString("N");
        var connection = await database.CreateUpgradeDatabaseAsync(name);
        try
        {
            await using var owner = DatabaseConfiguration.CreateSource(connection);
            await using (var schema = owner.CreateCommand("CREATE SCHEMA userdata AUTHORIZATION fb_migrator")) { await schema.ExecuteNonQueryAsync(ct); }
            await using (var conn = await owner.OpenConnectionAsync(ct))
            await using (var context = new UserDataContext(DatabaseConfiguration.ContextOptions<UserDataContext>(conn, "userdata")))
            {
                await using var command = conn.CreateCommand();
                command.CommandText = context.GetService<IHistoryRepository>().GetCreateIfNotExistsScript(); await command.ExecuteNonQueryAsync(ct);
                foreach (var operation in context.GetService<IMigrationsSqlGenerator>().Generate(new InitialUserData().UpOperations, context.Model))
                { command.CommandText = operation.CommandText; await command.ExecuteNonQueryAsync(ct); }
                command.CommandText = "INSERT INTO userdata.__ef_migrations_history(\"MigrationId\",\"ProductVersion\") VALUES('202610160001_InitialUserData','10.0.13')";
                await command.ExecuteNonQueryAsync(ct);
            }
            var user = Guid.NewGuid(); var device = Guid.NewGuid(); var clock = new TestClock();
            // Initial FORCE RLS has no owner policy; the fixture administrator seeds exactly the old data shape.
            await using (var disable = owner.CreateCommand("ALTER TABLE userdata.documents NO FORCE ROW LEVEL SECURITY; ALTER TABLE userdata.row_history NO FORCE ROW LEVEL SECURITY")) { await disable.ExecuteNonQueryAsync(ct); }
            await using (var seed = owner.CreateCommand("""
                WITH inserted AS (
                  INSERT INTO userdata.documents(user_id,entity,id,schema_version,hlc,device_id,deleted_at,payload)
                  VALUES($1,'weighIn',$2,1,$3,$4,CURRENT_TIMESTAMP,'{"legacy":1e100}'::jsonb) RETURNING user_id
                )
                INSERT INTO userdata.row_history(user_id,entity,id,schema_version,hlc,device_id,deleted_at,payload,replaced_at)
                SELECT $1,'weighIn',$2,1,$5,$4,NULL,'{"legacy":1e-100}'::jsonb,CURRENT_TIMESTAMP-interval '40 days' FROM inserted;
                """))
            {
                seed.Parameters.AddWithValue(user); seed.Parameters.AddWithValue(Guid.NewGuid()); seed.Parameters.AddWithValue($"1760351234567-00001-{device}"); seed.Parameters.AddWithValue(device); seed.Parameters.AddWithValue($"1760351234567-00000-{device}"); await seed.ExecuteNonQueryAsync(ct);
            }
            await using (var force = owner.CreateCommand("ALTER TABLE userdata.documents FORCE ROW LEVEL SECURITY; ALTER TABLE userdata.row_history FORCE ROW LEVEL SECURITY")) { await force.ExecuteNonQueryAsync(ct); }
            var runner = new MigrationRunner([
                new ModuleMigration("ops", c => new OpsDbContext(DatabaseConfiguration.ContextOptions<OpsDbContext>(c, "ops"))),
                new ModuleMigration("userdata", c => new UserDataContext(DatabaseConfiguration.ContextOptions<UserDataContext>(c, "userdata"))),
            ]);
            await runner.RunAsync(connection, ct);
            await UserDataModule.SeedLegacyCleanupAsync(connection, clock, new UuidV7IdGenerator(clock), ct);
            await using (var count = owner.CreateCommand("SELECT count(*) FROM ops.schedules WHERE user_id=$1")) { count.Parameters.AddWithValue(user); Assert.Equal(1L, await count.ExecuteScalarAsync(ct)); }
            clock.Advance(TimeSpan.FromDays(40));
            await using var session = new DatabaseSession(); await session.BeginAsync(owner, user, ct);
            await new SyncRetentionJob(clock, new UuidV7IdGenerator(clock)).HandleAsync(new(Guid.NewGuid(), "userdata.cleanup", "{}", user, 1), session, ct); await session.CommitAsync(ct);
            await using var result = owner.CreateCommand("SELECT (SELECT count(*) FROM userdata.row_history),(SELECT count(*) FROM userdata.version_receipts),(SELECT compacted AND payload='{}'::jsonb FROM userdata.documents)");
            await using var reader = await result.ExecuteReaderAsync(ct); Assert.True(await reader.ReadAsync(ct)); Assert.Equal(0L, reader.GetInt64(0)); Assert.Equal(2L, reader.GetInt64(1)); Assert.True(reader.GetBoolean(2));
        }
        finally { await database.DropUpgradeDatabaseAsync(name); }
    }
}
