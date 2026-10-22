using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Buddy.Infrastructure.Migrations;

[DbContext(typeof(BuddyContext))]
[Migration("202610210001_InitialBuddy")]
internal sealed class InitialBuddy : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        REVOKE ALL ON SCHEMA buddy FROM PUBLIC;
        GRANT USAGE ON SCHEMA buddy TO fb_app;
        CREATE TABLE buddy.attempts (user_id uuid NOT NULL,message_id uuid NOT NULL,fingerprint text NOT NULL,created_at timestamptz NOT NULL,dispatched_at timestamptz NOT NULL,expires_at timestamptz NOT NULL,attempts integer NOT NULL DEFAULT 1,recorded integer NOT NULL DEFAULT 0,response jsonb,PRIMARY KEY(user_id,message_id));
        CREATE INDEX attempts_expiry ON buddy.attempts(user_id,expires_at);
        ALTER TABLE buddy.attempts ENABLE ROW LEVEL SECURITY;
        ALTER TABLE buddy.attempts FORCE ROW LEVEL SECURITY;
        CREATE POLICY user_isolation ON buddy.attempts TO fb_app
          USING(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid)
          WITH CHECK(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid);
        GRANT SELECT,INSERT,UPDATE,DELETE ON buddy.attempts TO fb_app;
        REVOKE ALL ON buddy.__ef_migrations_history FROM fb_app;
        """);
    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("DROP TABLE buddy.attempts;");
}
