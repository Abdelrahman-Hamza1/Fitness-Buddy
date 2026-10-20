using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.BuildingBlocks.Persistence.Migrations;

[DbContext(typeof(OpsDbContext))]
[Migration("202610190001_ErasureRecovery")]
internal sealed class ErasureRecovery : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        ALTER TABLE ops.idempotency ADD COLUMN user_id uuid;
        CREATE INDEX idempotency_user ON ops.idempotency(user_id);
        -- Pre-release replay cache only: hash-only legacy entries cannot be attributed safely.
        -- No product records are removed; clients retry the original operation against its own safeguards.
        DELETE FROM ops.idempotency;
        CREATE TABLE ops.recovery(singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),generation uuid);
        INSERT INTO ops.recovery(singleton) VALUES(true);
        REVOKE ALL ON ops.recovery FROM PUBLIC,fb_app;
        GRANT SELECT,UPDATE(generation) ON ops.recovery TO fb_app;
        """);
    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Recovery state must not be rolled back.");
}
