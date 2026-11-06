using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Admin.Infrastructure.Migrations;

/// <summary>
/// B23 P3: console sessions, single-use sign-in challenges, the append-only audit log and the config draft.
/// Only the console login fb_admin has grants; fb_app and PUBLIC get nothing, so the public API can't forge a
/// session or rewrite the audit. The fb_admin role is provisioned outside migrations (like fb_app); this fails closed without it.
/// </summary>
[DbContext(typeof(AdminContext))]
[Migration("202611060001_InitialAdmin")]
internal sealed class InitialAdmin : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        REVOKE ALL ON SCHEMA admin FROM PUBLIC;
        GRANT USAGE ON SCHEMA admin TO fb_admin;
        CREATE TABLE admin.sessions(
          id uuid PRIMARY KEY,
          token_hash bytea NOT NULL UNIQUE CHECK(octet_length(token_hash)=32),
          handle text NOT NULL CHECK(length(handle) BETWEEN 1 AND 64),
          google_subject text NOT NULL CHECK(length(google_subject) BETWEEN 1 AND 255),
          created_at timestamptz NOT NULL, authenticated_at timestamptz NOT NULL,
          expires_at timestamptz NOT NULL, revoked_at timestamptz);
        CREATE TABLE admin.challenges(
          id uuid PRIMARY KEY,
          purpose text NOT NULL CHECK(purpose IN ('signin','reauth')),
          admin_session_id uuid REFERENCES admin.sessions(id) ON DELETE CASCADE,
          nonce_hash bytea NOT NULL CHECK(octet_length(nonce_hash)=32),
          expires_at timestamptz NOT NULL, used_at timestamptz,
          CHECK((purpose='reauth') = (admin_session_id IS NOT NULL)));
        CREATE TABLE admin.audit_log(
          id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
          occurred_at timestamptz NOT NULL,
          actor text NOT NULL CHECK(length(actor) BETWEEN 1 AND 64),
          area text NOT NULL CHECK(length(area) BETWEEN 1 AND 32),
          action text NOT NULL CHECK(length(action) BETWEEN 1 AND 64),
          target text CHECK(length(target) <= 128),
          before jsonb, after jsonb,
          reason text CHECK(length(reason) <= 500),
          outcome text NOT NULL CHECK(length(outcome) BETWEEN 1 AND 64));
        CREATE INDEX audit_time ON admin.audit_log(occurred_at DESC, id DESC);
        CREATE INDEX audit_area ON admin.audit_log(area, occurred_at DESC);
        CREATE INDEX audit_actor ON admin.audit_log(actor, occurred_at DESC);
        CREATE FUNCTION admin.audit_append_only() RETURNS trigger LANGUAGE plpgsql SET search_path = pg_catalog, pg_temp AS $f$
          BEGIN RAISE EXCEPTION 'admin.audit_log is append-only' USING ERRCODE = 'insufficient_privilege'; END $f$;
        REVOKE ALL ON FUNCTION admin.audit_append_only() FROM PUBLIC;
        CREATE TRIGGER audit_no_change BEFORE UPDATE OR DELETE ON admin.audit_log FOR EACH ROW EXECUTE FUNCTION admin.audit_append_only();
        CREATE TRIGGER audit_no_truncate BEFORE TRUNCATE ON admin.audit_log FOR EACH STATEMENT EXECUTE FUNCTION admin.audit_append_only();
        CREATE TABLE admin.config_draft(
          singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
          base_version integer NOT NULL, revision bigint NOT NULL,
          document jsonb NOT NULL, document_sha256 bytea NOT NULL CHECK(octet_length(document_sha256)=32),
          updated_by text NOT NULL, updated_at timestamptz NOT NULL);
        GRANT SELECT, INSERT ON admin.audit_log TO fb_admin;
        GRANT SELECT, INSERT, UPDATE, DELETE ON admin.sessions, admin.challenges, admin.config_draft TO fb_admin;
        REVOKE ALL ON admin.__ef_migrations_history FROM fb_admin;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("The admin audit log is append-only; no down migration.");
}
