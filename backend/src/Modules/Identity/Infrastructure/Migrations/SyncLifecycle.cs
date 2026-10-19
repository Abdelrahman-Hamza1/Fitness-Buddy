using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Identity.Infrastructure.Migrations;

[DbContext(typeof(IdentityContext))]
[Migration("202610180002_SyncLifecycle")]
internal sealed class SyncLifecycle : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE FUNCTION identity.check_active(p_user uuid,p_session uuid,p_registered boolean,p_now timestamptz)
        RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $$
        BEGIN
          PERFORM 1 FROM identity.users u WHERE u.id=p_user AND u.status='active'
            AND (NOT p_registered OR NOT u.anonymous) FOR SHARE;
          IF NOT FOUND THEN RETURN false; END IF;
          PERFORM 1 FROM identity.sessions s WHERE s.id=p_session AND s.user_id=p_user
            AND NOT s.revoked AND s.expires_at>p_now FOR SHARE;
          RETURN FOUND;
        END $$;
        REVOKE ALL ON FUNCTION identity.check_active(uuid,uuid,boolean,timestamptz) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION identity.check_active(uuid,uuid,boolean,timestamptz) TO fb_app;
        """);
    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("DROP FUNCTION identity.check_active(uuid,uuid,boolean,timestamptz)");
}
