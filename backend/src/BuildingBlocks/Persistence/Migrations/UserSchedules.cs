using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.BuildingBlocks.Persistence.Migrations;

[DbContext(typeof(OpsDbContext))]
[Migration("202610180004_UserSchedules")]
internal sealed class UserSchedules : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("ALTER TABLE ops.schedules ADD COLUMN user_id uuid; CREATE INDEX schedules_owner ON ops.schedules(user_id) WHERE user_id IS NOT NULL;");
    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("ALTER TABLE ops.schedules DROP COLUMN user_id;");
}
