using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Identity.Infrastructure.Migrations;

/// <summary>
/// R1 security audit (expand only): the console's device controls read the app version through <c>identity.admin_version</c>,
/// like every other console read, so writer-controlled version text shows as <c>other</c> instead of verbatim.
/// </summary>
[DbContext(typeof(IdentityContext))]
[Migration("202611090003_DeviceKeyVersion")]
internal sealed class DeviceKeyVersion : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE OR REPLACE FUNCTION identity.admin_device_keys(p_user uuid, p_now timestamptz)
        RETURNS TABLE(device_key text, platform text, app_version text, last_seen_at timestamptz, active_sessions bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
         SELECT left(encode(sha256(convert_to(d.user_id::text || ':' || d.device_id::text, 'UTF8')), 'hex'), 32), d.platform, identity.admin_version(d.app_version), d.last_seen_at,
                (SELECT count(*) FROM identity.sessions s WHERE s.user_id = d.user_id AND s.device_id = d.device_id AND NOT s.revoked AND s.expires_at > p_now)
         FROM identity.devices d WHERE d.user_id = p_user ORDER BY d.last_seen_at DESC NULLS LAST, 1 LIMIT 50;
        $f$;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Identity rollback requires verified recovery.");
}
