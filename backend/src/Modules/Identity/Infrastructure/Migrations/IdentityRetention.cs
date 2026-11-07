using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Identity.Infrastructure.Migrations;

/// <summary>
/// R1 security audit (expand only): bounded Identity retention, run by the worker's <c>identity.cleanup</c> job. Removes expired
/// email challenges (abandoned sign-ins included: erasure can't reach them without an account), throttle buckets idle for a full
/// window (deleting one is the same as its reset), and session families past their absolute expiry with their refresh hashes.
/// Consumed refresh hashes stay as long as their family lives, so reuse detection is unchanged. Only the worker login can run it.
/// </summary>
[DbContext(typeof(IdentityContext))]
[Migration("202611090002_IdentityRetention")]
internal sealed class IdentityRetention : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE INDEX email_challenges_expires ON identity.email_challenges(expires_at);
        CREATE INDEX throttles_last ON identity.throttles(last_at);
        CREATE INDEX sessions_expires ON identity.sessions(expires_at);

        -- At most p_limit rows of each kind per call (≤ 5000); rows a live transaction holds are skipped until the next run.
        CREATE FUNCTION identity.cleanup(p_now timestamptz, p_limit integer) RETURNS void
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_limit integer := least(greatest(p_limit, 1), 5000); v_sessions uuid[];
        BEGIN
         DELETE FROM identity.email_challenges c WHERE c.id IN(
           SELECT x.id FROM identity.email_challenges x WHERE x.expires_at <= p_now ORDER BY x.expires_at LIMIT v_limit FOR UPDATE SKIP LOCKED);
         DELETE FROM identity.throttles t WHERE t.bucket IN(
           SELECT x.bucket FROM identity.throttles x WHERE x.last_at <= p_now - interval '1 hour' AND x.started_at <= p_now - interval '1 hour'
           ORDER BY x.last_at LIMIT v_limit FOR UPDATE SKIP LOCKED);
         v_sessions := ARRAY(SELECT s.id FROM identity.sessions s WHERE s.expires_at <= p_now ORDER BY s.expires_at LIMIT v_limit FOR UPDATE SKIP LOCKED);
         DELETE FROM identity.email_challenges c WHERE c.session_id = ANY(v_sessions);
         DELETE FROM identity.refresh_tokens t WHERE t.session_id = ANY(v_sessions);
         DELETE FROM identity.sessions s WHERE s.id = ANY(v_sessions);
        END $f$;
        REVOKE ALL ON FUNCTION identity.cleanup(timestamptz,integer) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION identity.cleanup(timestamptz,integer) TO fb_worker;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Identity rollback requires verified recovery.");
}
