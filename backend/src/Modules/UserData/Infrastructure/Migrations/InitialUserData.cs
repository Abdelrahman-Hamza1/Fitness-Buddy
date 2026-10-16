using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.UserData.Infrastructure.Migrations;

[DbContext(typeof(UserDataContext))]
[Migration("202610160001_InitialUserData")]
internal sealed class InitialUserData : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("""
            REVOKE ALL ON SCHEMA userdata FROM PUBLIC;
            GRANT USAGE ON SCHEMA userdata TO fb_app;
            CREATE SEQUENCE userdata.document_seq CACHE 1;
            CREATE SEQUENCE userdata.history_seq CACHE 1;
            CREATE TABLE userdata.documents (
                user_id uuid NOT NULL, entity varchar(64) NOT NULL, id uuid NOT NULL,
                schema_version integer NOT NULL, hlc text COLLATE "C" NOT NULL, device_id uuid NOT NULL,
                deleted_at timestamptz, payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
                server_seq bigint NOT NULL DEFAULT nextval('userdata.document_seq'),
                PRIMARY KEY(user_id, entity, id)
            );
            CREATE INDEX documents_pull ON userdata.documents(user_id, server_seq);
            CREATE TABLE userdata.row_history (
                user_id uuid NOT NULL, entity varchar(64) NOT NULL, id uuid NOT NULL,
                schema_version integer NOT NULL, hlc text COLLATE "C" NOT NULL, device_id uuid NOT NULL,
                deleted_at timestamptz, payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
                server_seq bigint NOT NULL DEFAULT nextval('userdata.history_seq'), replaced_at timestamptz NOT NULL,
                PRIMARY KEY(user_id, entity, id, hlc)
            );
            CREATE INDEX history_pull ON userdata.row_history(user_id, server_seq);
            CREATE INDEX history_retention ON userdata.row_history(replaced_at);
            ALTER TABLE userdata.documents ENABLE ROW LEVEL SECURITY;
            ALTER TABLE userdata.documents FORCE ROW LEVEL SECURITY;
            ALTER TABLE userdata.row_history ENABLE ROW LEVEL SECURITY;
            ALTER TABLE userdata.row_history FORCE ROW LEVEL SECURITY;
            CREATE POLICY user_isolation ON userdata.documents TO fb_app
                USING(user_id = NULLIF(current_setting('app.user_id', true), '')::uuid)
                WITH CHECK(user_id = NULLIF(current_setting('app.user_id', true), '')::uuid);
            CREATE POLICY user_isolation ON userdata.row_history TO fb_app
                USING(user_id = NULLIF(current_setting('app.user_id', true), '')::uuid)
                WITH CHECK(user_id = NULLIF(current_setting('app.user_id', true), '')::uuid);
            GRANT SELECT, INSERT, UPDATE, DELETE ON userdata.documents TO fb_app;
            GRANT SELECT, INSERT ON userdata.row_history TO fb_app;
            GRANT USAGE ON ALL SEQUENCES IN SCHEMA userdata TO fb_app;
            REVOKE ALL ON userdata.__ef_migrations_history FROM fb_app;
            """);
    }

    protected override void Down(MigrationBuilder migrationBuilder) =>
        migrationBuilder.Sql("DROP TABLE userdata.row_history, userdata.documents; DROP SEQUENCE userdata.history_seq, userdata.document_seq;");
}
