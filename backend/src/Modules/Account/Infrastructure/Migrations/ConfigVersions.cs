using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Account.Infrastructure.Migrations;

/// <summary>
/// B23 WP5: published remote-config versions (append-only; a rollback is a new version). The application login reads them for
/// <c>/v1/config</c> and the 426 gate; only the console login (fb_admin) can add a version. The migrate role seeds version 1.
/// </summary>
[DbContext(typeof(AccountContext))]
[Migration("202611060001_ConfigVersions")]
internal sealed class ConfigVersions : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE TABLE account.config_versions(
          version integer PRIMARY KEY CHECK(version > 0),
          document jsonb NOT NULL CHECK(jsonb_typeof(document)='object'),
          published_at timestamptz NOT NULL,
          published_by text NOT NULL CHECK(length(published_by) BETWEEN 1 AND 64),
          reason text NOT NULL CHECK(length(reason) BETWEEN 1 AND 500),
          rolled_back_from integer REFERENCES account.config_versions(version));
        CREATE FUNCTION account.config_append_only() RETURNS trigger LANGUAGE plpgsql SET search_path = pg_catalog, pg_temp AS $f$
          BEGIN RAISE EXCEPTION 'account.config_versions is append-only' USING ERRCODE = 'insufficient_privilege'; END $f$;
        REVOKE ALL ON FUNCTION account.config_append_only() FROM PUBLIC;
        CREATE TRIGGER config_no_change BEFORE UPDATE OR DELETE ON account.config_versions FOR EACH ROW EXECUTE FUNCTION account.config_append_only();
        CREATE TRIGGER config_no_truncate BEFORE TRUNCATE ON account.config_versions FOR EACH STATEMENT EXECUTE FUNCTION account.config_append_only();
        GRANT SELECT ON account.config_versions TO fb_app;
        GRANT USAGE ON SCHEMA account TO fb_admin;
        GRANT SELECT, INSERT ON account.config_versions TO fb_admin;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Published config versions are append-only; no down migration.");
}
