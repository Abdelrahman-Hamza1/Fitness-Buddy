using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Identity.Infrastructure.Migrations;

/// <summary>
/// B23 WP4 (expand only): when a device was last seen and with which app version, for the console's install counts and the
/// minimum-version ceiling. <c>touch_device</c> has the same proof model as <c>check_active</c> (an active session of that user,
/// from a validated token) and writes at most once an hour per device unless the version changes. <c>admin_installs</c> is a
/// content-free count only the console login can run (owner O1, TD-118).
/// </summary>
[DbContext(typeof(IdentityContext))]
[Migration("202611060001_DeviceActivity")]
internal sealed class DeviceActivity : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        ALTER TABLE identity.devices
          ADD COLUMN last_seen_at timestamptz,
          ADD COLUMN app_version text CHECK(length(app_version) BETWEEN 5 AND 32),
          ADD COLUMN platform text CHECK(platform IN ('android','ios'));
        CREATE INDEX devices_last_seen ON identity.devices(last_seen_at) WHERE last_seen_at IS NOT NULL;
        CREATE FUNCTION identity.touch_device(p_user uuid,p_session uuid,p_version text,p_platform text,p_now timestamptz) RETURNS void
        LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
         UPDATE identity.devices d SET last_seen_at=p_now,app_version=p_version,platform=p_platform
         FROM identity.sessions s JOIN identity.users u ON u.id=s.user_id
         WHERE s.id=p_session AND s.user_id=p_user AND NOT s.revoked AND s.expires_at>p_now AND u.status='active'
           AND d.user_id=s.user_id AND d.device_id=s.device_id
           AND (d.last_seen_at IS NULL OR d.last_seen_at<p_now-interval '1 hour'
                OR d.app_version IS DISTINCT FROM p_version OR d.platform IS DISTINCT FROM p_platform);
        $f$;
        REVOKE ALL ON FUNCTION identity.touch_device(uuid,uuid,text,text,timestamptz) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION identity.touch_device(uuid,uuid,text,text,timestamptz) TO fb_app;
        CREATE FUNCTION identity.admin_installs(p_since timestamptz) RETURNS TABLE(app_version text,platform text,installs bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
         SELECT d.app_version,d.platform,count(*) FROM identity.devices d JOIN identity.users u ON u.id=d.user_id
         WHERE u.status='active' AND d.last_seen_at>=p_since AND d.app_version IS NOT NULL AND d.platform IS NOT NULL
         GROUP BY d.app_version,d.platform;
        $f$;
        REVOKE ALL ON FUNCTION identity.admin_installs(timestamptz) FROM PUBLIC;
        GRANT USAGE ON SCHEMA identity TO fb_admin;
        GRANT EXECUTE ON FUNCTION identity.admin_installs(timestamptz) TO fb_admin;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Identity rollback requires verified recovery.");
}
