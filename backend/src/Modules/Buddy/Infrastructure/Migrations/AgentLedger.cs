using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Buddy.Infrastructure.Migrations;

/// <summary>B25 (TD-125): content-free agent turn and round rows: counts, states, attempts, the turn's disclosed phone rows/bytes and
/// a SHA-256 digest of a round's phone results (a retry must repeat them). Additive (expand only); interpret's table is untouched.</summary>
[DbContext(typeof(BuddyContext))]
[Migration("202611060001_AgentLedger")]
internal sealed class AgentLedger : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE TABLE buddy.turns (user_id uuid NOT NULL,turn_id uuid NOT NULL,started_at timestamptz NOT NULL,expires_at timestamptz NOT NULL,
          sends integer NOT NULL DEFAULT 0,input_tokens bigint NOT NULL DEFAULT 0,output_tokens bigint NOT NULL DEFAULT 0,rounds integer NOT NULL DEFAULT 0,
          message_charged boolean NOT NULL DEFAULT false,
          disclosed_rows integer NOT NULL DEFAULT 0,disclosed_bytes integer NOT NULL DEFAULT 0,reserved_input bigint NOT NULL DEFAULT 0,PRIMARY KEY(user_id,turn_id));
        CREATE INDEX turns_expiry ON buddy.turns(user_id,expires_at);
        CREATE TABLE buddy.turn_rounds (user_id uuid NOT NULL,turn_id uuid NOT NULL,round integer NOT NULL CHECK(round BETWEEN 0 AND 3),
          state text NOT NULL CHECK(state IN ('started','completed','cancelled')),attempts integer NOT NULL DEFAULT 1,completed_at timestamptz,
          acknowledged boolean NOT NULL DEFAULT false,results_digest text,PRIMARY KEY(user_id,turn_id,round),
          FOREIGN KEY(user_id,turn_id) REFERENCES buddy.turns(user_id,turn_id) ON DELETE CASCADE);
        ALTER TABLE buddy.turns ENABLE ROW LEVEL SECURITY;
        ALTER TABLE buddy.turns FORCE ROW LEVEL SECURITY;
        CREATE POLICY user_isolation ON buddy.turns TO fb_app
          USING(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid)
          WITH CHECK(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid);
        ALTER TABLE buddy.turn_rounds ENABLE ROW LEVEL SECURITY;
        ALTER TABLE buddy.turn_rounds FORCE ROW LEVEL SECURITY;
        CREATE POLICY user_isolation ON buddy.turn_rounds TO fb_app
          USING(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid)
          WITH CHECK(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid);
        GRANT SELECT,INSERT,UPDATE,DELETE ON buddy.turns TO fb_app;
        GRANT SELECT,INSERT,UPDATE,DELETE ON buddy.turn_rounds TO fb_app;
        """);
    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("DROP TABLE buddy.turn_rounds; DROP TABLE buddy.turns;");
}
