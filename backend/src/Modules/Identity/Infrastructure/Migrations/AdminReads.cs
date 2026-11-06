using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Identity.Infrastructure.Migrations;

/// <summary>
/// B23 WP8: content-free account reads for the console (AD-010 accounts by type, AD-011 list and detail). They return
/// pseudonymous ids, closed codes (type, status, platform, app version), counts, timestamps and <b>masked</b> emails (first
/// letter + domain, AD-002; an email sign-in account has no stored address, so its state says "not stored"); never a full
/// email, a Google subject or a device id. The email lookup is an exact match under Identity's normalization that returns ids
/// only; email sign-in accounts match by their keyed address hash, which the caller computes with the lookup key. Only the console login can run them (owner O1, TD-118).
/// </summary>
[DbContext(typeof(IdentityContext))]
[Migration("202611070001_AdminReads")]
internal sealed class AdminReads : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE FUNCTION identity.admin_account_type(p_user uuid, p_anonymous boolean) RETURNS text
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT CASE WHEN p_anonymous THEN 'guest'
                     WHEN EXISTS(SELECT 1 FROM identity.identities i WHERE i.user_id = p_user AND i.provider = 'google') THEN 'google'
                     WHEN EXISTS(SELECT 1 FROM identity.identities i WHERE i.user_id = p_user AND i.provider = 'email') THEN 'email'
                     ELSE 'registered' END;
        $f$;
        REVOKE ALL ON FUNCTION identity.admin_account_type(uuid,boolean) FROM PUBLIC;

        CREATE FUNCTION identity.admin_accounts_by_type() RETURNS TABLE(account_type text, status text, accounts bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT identity.admin_account_type(u.id, u.anonymous), u.status, count(*) FROM identity.users u GROUP BY 1, 2 ORDER BY 1, 2;
        $f$;

        -- Writer-controlled text (B23b security review): an app version reads as itself only in MAJOR.MINOR.PATCH form, else 'other'.
        CREATE FUNCTION identity.admin_version(p_version text) RETURNS text
        LANGUAGE sql IMMUTABLE SET search_path=pg_catalog,pg_temp AS $f$
         SELECT CASE WHEN p_version IS NULL THEN NULL WHEN p_version ~ '^[0-9]{1,9}\.[0-9]{1,9}\.[0-9]{1,9}$' THEN p_version ELSE 'other' END;
        $f$;
        REVOKE ALL ON FUNCTION identity.admin_version(text) FROM PUBLIC;
        CREATE OR REPLACE FUNCTION identity.admin_installs(p_since timestamptz) RETURNS TABLE(app_version text,platform text,installs bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
         SELECT identity.admin_version(d.app_version),d.platform,count(*) FROM identity.devices d JOIN identity.users u ON u.id=d.user_id
         WHERE u.status='active' AND d.last_seen_at>=p_since AND d.app_version IS NOT NULL AND d.platform IS NOT NULL
         GROUP BY 1,2;
        $f$;

        -- One page (newest first, keyset on the UUIDv7 id) or the given ids; the masked email prefers the Google identity. The
        -- mask is the first letter or digit + the domain, and only when the domain has a host-name shape (else null).
        CREATE FUNCTION identity.admin_accounts(p_type text, p_before uuid, p_limit integer, p_ids uuid[])
        RETURNS TABLE(user_id uuid, account_type text, masked_email text, email_state text, status text, created_at timestamptz,
                      last_seen_at timestamptz, app_version text, devices bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT u.id, t.account_type, m.masked_email,
                CASE WHEN m.masked_email IS NOT NULL THEN 'masked' WHEN m.stored THEN 'hidden'
                     WHEN EXISTS(SELECT 1 FROM identity.identities e WHERE e.user_id = u.id AND e.provider = 'email') THEN 'not-stored'
                     ELSE 'none' END,
                u.status, u.created_at, d.last_seen_at, identity.admin_version(d.app_version), coalesce(d.devices, 0)
         FROM identity.users u
         CROSS JOIN LATERAL (SELECT identity.admin_account_type(u.id, u.anonymous) AS account_type) t
         LEFT JOIN LATERAL (SELECT CASE WHEN x.first ~ '^[A-Za-z0-9]$' AND x.domain ~ '^[A-Za-z0-9-]{1,63}(\.[A-Za-z0-9-]{1,63}){1,8}$'
                                        THEN x.first || '…@' || x.domain END AS masked_email, true AS stored
                            FROM (SELECT left(btrim(i.email), 1) AS first, substring(btrim(i.email) from '^[^@]+@([^@]+)$') AS domain
                                  FROM identity.identities i WHERE i.user_id = u.id AND btrim(i.email) <> ''
                                  ORDER BY i.provider = 'google' DESC, i.provider LIMIT 1) x) m ON true
         LEFT JOIN LATERAL (SELECT count(*) AS devices, max(dv.last_seen_at) AS last_seen_at,
                                   (array_agg(dv.app_version ORDER BY dv.last_seen_at DESC NULLS LAST))[1] AS app_version
                            FROM identity.devices dv WHERE dv.user_id = u.id) d ON true
         WHERE (p_ids IS NULL OR u.id = ANY(p_ids[1:200])) AND (p_type IS NULL OR t.account_type = p_type) AND (p_before IS NULL OR u.id < p_before)
         ORDER BY u.id DESC LIMIT least(greatest(p_limit, 1), 200);
        $f$;

        -- Exact; no pattern semantics (=, not LIKE). Ids only. p_email is normalized by the caller like sign-in does; Google
        -- identities match their stored address, email sign-in identities their keyed address hash p_subject (null: not searched).
        CREATE FUNCTION identity.admin_find_by_email(p_email text, p_subject text) RETURNS TABLE(user_id uuid)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT DISTINCT i.user_id FROM identity.identities i
         WHERE length(p_email) BETWEEN 3 AND 320
           AND ((i.provider <> 'email' AND btrim(i.email) <> '' AND lower(btrim(i.email)) = p_email)
                OR (i.provider = 'email' AND p_subject ~ '^[0-9a-f]{64}$' AND i.subject = p_subject))
         LIMIT 5;
        $f$;

        -- Devices without their ids: platform, version, last seen and active sessions, most recent first.
        CREATE FUNCTION identity.admin_devices(p_user uuid, p_now timestamptz)
        RETURNS TABLE(platform text, app_version text, last_seen_at timestamptz, active_sessions bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT d.platform, identity.admin_version(d.app_version), d.last_seen_at,
                (SELECT count(*) FROM identity.sessions s WHERE s.user_id = d.user_id AND s.device_id = d.device_id AND NOT s.revoked AND s.expires_at > p_now)
         FROM identity.devices d WHERE d.user_id = p_user ORDER BY d.last_seen_at DESC NULLS LAST LIMIT 50;
        $f$;

        DO $body$ DECLARE f text; BEGIN
         FOREACH f IN ARRAY ARRAY['identity.admin_accounts_by_type()','identity.admin_accounts(text,uuid,integer,uuid[])',
                                  'identity.admin_find_by_email(text,text)','identity.admin_devices(uuid,timestamptz)'] LOOP
          EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', f);
          EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO fb_admin', f);
         END LOOP;
        END $body$;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Identity rollback requires verified recovery.");
}
