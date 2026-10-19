using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.UserData.Infrastructure.Migrations;

[DbContext(typeof(UserDataContext))]
[Migration("202610180002_ProductionSync")]
internal sealed class ProductionSync : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        ALTER TABLE userdata.documents ADD COLUMN accepted_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP;
        ALTER TABLE userdata.documents ADD COLUMN compacted boolean NOT NULL DEFAULT false;
        ALTER TABLE userdata.row_history ADD COLUMN compacted boolean NOT NULL DEFAULT false;
        GRANT SELECT ON userdata.document_seq,userdata.history_seq TO fb_app;
        CREATE INDEX documents_retention ON userdata.documents(accepted_at) WHERE deleted_at IS NOT NULL AND NOT compacted;
        CREATE TABLE userdata.dataset(singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),id uuid NOT NULL);
        INSERT INTO userdata.dataset VALUES(true,gen_random_uuid());
        GRANT SELECT ON userdata.dataset TO fb_app;
        CREATE TABLE userdata.version_receipts (
          user_id uuid NOT NULL,entity varchar(64) NOT NULL,id uuid NOT NULL,hlc text COLLATE "C" NOT NULL,
          fingerprint bytea NOT NULL CHECK(octet_length(fingerprint)=32),PRIMARY KEY(user_id,entity,id,hlc)
        );
        ALTER TABLE userdata.version_receipts ENABLE ROW LEVEL SECURITY;
        ALTER TABLE userdata.version_receipts FORCE ROW LEVEL SECURITY;
        CREATE POLICY user_isolation ON userdata.version_receipts TO fb_app
          USING(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid)
          WITH CHECK(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid);
        CREATE POLICY owner_maintenance ON userdata.documents TO fb_migrator USING(true) WITH CHECK(true);
        CREATE POLICY owner_maintenance ON userdata.row_history TO fb_migrator USING(true) WITH CHECK(true);
        CREATE POLICY owner_maintenance ON userdata.version_receipts TO fb_migrator USING(true) WITH CHECK(true);
        GRANT SELECT,INSERT,UPDATE,DELETE ON userdata.version_receipts TO fb_app;
        GRANT DELETE ON userdata.row_history TO fb_app;
        """);
    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        DROP TABLE userdata.version_receipts,userdata.dataset;
        DROP INDEX userdata.documents_retention;
        ALTER TABLE userdata.documents DROP COLUMN compacted,DROP COLUMN accepted_at;
        ALTER TABLE userdata.row_history DROP COLUMN compacted;
        """);
}
