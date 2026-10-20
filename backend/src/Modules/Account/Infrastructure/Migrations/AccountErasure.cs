using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Account.Infrastructure.Migrations;

[DbContext(typeof(AccountContext))]
[Migration("202610190001_AccountErasure")]
internal sealed class AccountErasure : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        REVOKE ALL ON SCHEMA account FROM PUBLIC;
        GRANT USAGE ON SCHEMA account TO fb_app;
        CREATE TABLE account.deletion_requests(user_id uuid PRIMARY KEY,event_id uuid NOT NULL,requested_at timestamptz NOT NULL);
        ALTER TABLE account.deletion_requests ENABLE ROW LEVEL SECURITY;
        ALTER TABLE account.deletion_requests FORCE ROW LEVEL SECURITY;
        CREATE POLICY own_user ON account.deletion_requests TO fb_app
          USING(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid)
          WITH CHECK(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid);
        CREATE POLICY owner_access ON account.deletion_requests TO fb_migrator USING(true) WITH CHECK(true);
        GRANT SELECT,INSERT,DELETE ON account.deletion_requests TO fb_app;
        """);
    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Account erasure rollback requires verified recovery.");
}
