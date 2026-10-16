using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.BuildingBlocks.Persistence.Migrations;

[DbContext(typeof(OpsDbContext))]
[Migration("202610160003_QueueUserContext")]
internal sealed class QueueUserContext : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("ALTER TABLE ops.outbox ADD COLUMN user_id uuid; ALTER TABLE ops.jobs ADD COLUMN user_id uuid;");
    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("ALTER TABLE ops.outbox DROP COLUMN user_id; ALTER TABLE ops.jobs DROP COLUMN user_id;");
}
