using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Identity.Infrastructure.Migrations;

/// <summary>
/// B24 (expand only): operator account controls for the console (AD-011, TD-121/TD-122 candidates).
/// <list type="bullet">
/// <item><c>users.disabled_at</c>: a disable flag checked by every session and sign-in function (<c>read_session</c>,
/// <c>check_active</c>, <c>new_session</c>, <c>rotate_refresh</c>, and the email paths <c>start_email</c> and
/// <c>consume_email</c> before any challenge effect). It is deliberately not a lifecycle status:
/// <c>check_user_active</c> (queue workers) stays true, so a reversible disable never erases the user's queued work.</item>
/// <item><c>operator_deletions</c>: the operator's deletion intent. Only the console login can create it; the deletion
/// capability <c>begin_operator_deletion</c> requires it committed and due, under the user lifecycle lock.</item>
/// <item>Every mutating function takes the lifecycle lock first and revalidates the account before writing anything.</item>
/// </list>
/// </summary>
[DbContext(typeof(IdentityContext))]
[Migration("202611080001_OperatorControls")]
internal sealed class OperatorControls : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        ALTER TABLE identity.users ADD COLUMN disabled_at timestamptz;
        CREATE TABLE identity.operator_deletions(
          user_id uuid PRIMARY KEY REFERENCES identity.users,
          requested_at timestamptz NOT NULL,
          attempts integer NOT NULL DEFAULT 0 CHECK(attempts >= 0),
          available_at timestamptz NOT NULL,
          last_error text CHECK(last_error IN ('recovery-unavailable','unavailable','failed')));
        ALTER TABLE identity.operator_deletions ENABLE ROW LEVEL SECURITY;
        ALTER TABLE identity.operator_deletions FORCE ROW LEVEL SECURITY;
        CREATE POLICY identity_owner ON identity.operator_deletions TO fb_migrator USING(true) WITH CHECK(true);
        REVOKE ALL ON identity.operator_deletions FROM PUBLIC, fb_app;

        -- The four session/sign-in gates: unchanged signatures and bodies plus the disable flag.
        CREATE OR REPLACE FUNCTION identity.read_session(p_user uuid,p_session uuid,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
         SELECT u.id,u.anonymous,s.id,s.expires_at FROM identity.sessions s JOIN identity.users u ON u.id=s.user_id
         WHERE s.id=p_session AND s.user_id=p_user AND NOT s.revoked AND s.expires_at>p_now AND u.status='active' AND u.disabled_at IS NULL;
        $f$;
        CREATE OR REPLACE FUNCTION identity.check_active(p_user uuid,p_session uuid,p_registered boolean,p_now timestamptz)
        RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $$
        BEGIN
          PERFORM 1 FROM identity.users u WHERE u.id=p_user AND u.status='active' AND u.disabled_at IS NULL
            AND (NOT p_registered OR NOT u.anonymous) FOR SHARE;
          IF NOT FOUND THEN RETURN false; END IF;
          PERFORM 1 FROM identity.sessions s WHERE s.id=p_session AND s.user_id=p_user
            AND NOT s.revoked AND s.expires_at>p_now FOR SHARE;
          RETURN FOUND;
        END $$;
        CREATE OR REPLACE FUNCTION identity.new_session(p_user uuid,p_session uuid,p_device uuid,p_hash bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         PERFORM 1 FROM identity.users u WHERE u.id=p_user AND u.status='active' AND u.disabled_at IS NULL FOR UPDATE;
         IF NOT FOUND THEN RETURN; END IF;
         INSERT INTO identity.devices VALUES(p_user,p_device) ON CONFLICT DO NOTHING;
         INSERT INTO identity.sessions VALUES(p_session,p_user,p_device,p_now+interval '30 days',false);
         INSERT INTO identity.refresh_tokens VALUES(p_hash,p_session,false);
         RETURN QUERY SELECT u.id,u.anonymous,p_session,p_now+interval '30 days' FROM identity.users u WHERE u.id=p_user;
        END $f$;
        CREATE OR REPLACE FUNCTION identity.rotate_refresh(p_old bytea,p_new bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_session identity.sessions; v_consumed boolean;
        BEGIN
         SELECT s.* INTO v_session FROM identity.sessions s JOIN identity.refresh_tokens t ON t.session_id=s.id WHERE t.hash=p_old;
         IF NOT FOUND THEN RETURN; END IF;
         PERFORM pg_advisory_xact_lock(hashtextextended(v_session.user_id::text,4603912));
         PERFORM 1 FROM identity.users u WHERE u.id=v_session.user_id AND u.status='active' AND u.disabled_at IS NULL FOR SHARE;
         IF NOT FOUND THEN RETURN; END IF;
         SELECT s.* INTO v_session FROM identity.sessions s JOIN identity.refresh_tokens t ON t.session_id=s.id
           WHERE t.hash=p_old FOR UPDATE OF s;
         IF NOT FOUND OR v_session.revoked OR v_session.expires_at<=p_now THEN RETURN; END IF;
         SELECT t.consumed INTO v_consumed FROM identity.refresh_tokens t WHERE t.hash=p_old;
         IF v_consumed THEN
          UPDATE identity.sessions SET revoked=true WHERE id=v_session.id;
          INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('refresh-reuse',v_session.user_id,v_session.id,p_now);
          RETURN;
         END IF;
         IF NOT EXISTS(SELECT 1 FROM identity.users u WHERE u.id=v_session.user_id AND u.status='active' AND u.disabled_at IS NULL) THEN RETURN; END IF;
         UPDATE identity.refresh_tokens SET consumed=true WHERE hash=p_old;
         INSERT INTO identity.refresh_tokens VALUES(p_new,v_session.id,false);
         RETURN QUERY SELECT * FROM identity.read_session(v_session.user_id,v_session.id,p_now);
        END $f$;

        -- The email paths: unchanged signatures and bodies, plus the disable flag on the account lookup, so a disabled account
        -- gets no code (no throttle, no challenge) and verifying leaves its challenge unconsumed with no audit row (review minor 1).
        CREATE OR REPLACE FUNCTION identity.start_email(p_id uuid,p_address bytea,p_code bytea,p_purpose text,p_user uuid,p_session uuid,p_ip bytea,p_now timestamptz) RETURNS boolean
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_user uuid;
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended('email:'||encode(p_address,'hex'),0));
         IF p_purpose='link' THEN v_user:=p_user;
         ELSE SELECT i.user_id INTO v_user FROM identity.identities i WHERE i.provider='email' AND i.subject=encode(p_address,'hex'); END IF;
         IF v_user IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(hashtextextended(v_user::text,4603912));
          PERFORM 1 FROM identity.users u WHERE u.id=v_user AND u.status='active' AND u.disabled_at IS NULL FOR SHARE;
          IF NOT FOUND THEN RETURN false; END IF;
         END IF;
         IF p_purpose='link' AND NOT EXISTS(SELECT 1 FROM identity.read_session(p_user,p_session,p_now) s WHERE s.anonymous) THEN RETURN false; END IF;
         IF NOT identity.take_throttle(p_ip,30,0,p_now) THEN RETURN false; END IF;
         IF NOT identity.take_throttle(p_address,5,60,p_now) THEN RETURN false; END IF;
         UPDATE identity.email_challenges SET consumed=true WHERE address_hash=p_address AND purpose=p_purpose AND user_id IS NOT DISTINCT FROM p_user AND NOT consumed;
         INSERT INTO identity.email_challenges VALUES(p_id,p_address,p_code,p_purpose,p_user,p_session,p_now,p_now+interval '10 minutes',0,false);
         RETURN true;
        END $f$;
        CREATE OR REPLACE FUNCTION identity.consume_email(p_id uuid,p_code bytea,p_purpose text,p_user uuid,p_old_session uuid,p_new_user uuid,p_session uuid,p_device uuid,p_hash bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v identity.email_challenges; v_user uuid; v_subject text;
        BEGIN
         -- Discover, then serialize identity/user, then lock and revalidate the challenge.
         SELECT * INTO v FROM identity.email_challenges WHERE id=p_id;
         IF NOT FOUND THEN RETURN; END IF;
         v_subject:=encode(v.address_hash,'hex');
         PERFORM pg_advisory_xact_lock(hashtextextended('email:'||v_subject,0));
         IF p_purpose='link' THEN v_user:=p_user;
         ELSE SELECT i.user_id INTO v_user FROM identity.identities i WHERE i.provider='email' AND i.subject=v_subject; END IF;
         IF v_user IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(hashtextextended(v_user::text,4603912));
          PERFORM 1 FROM identity.users u WHERE u.id=v_user AND u.status='active' AND u.disabled_at IS NULL FOR UPDATE;
          IF NOT FOUND THEN RETURN; END IF;
         END IF;
         IF p_purpose='link' THEN
          PERFORM 1 FROM identity.sessions s WHERE s.id=p_old_session AND s.user_id=p_user FOR UPDATE;
          IF NOT EXISTS(SELECT 1 FROM identity.read_session(p_user,p_old_session,p_now) s WHERE s.anonymous) THEN RETURN; END IF;
         END IF;
         SELECT * INTO v FROM identity.email_challenges WHERE id=p_id FOR UPDATE;
         IF NOT FOUND OR v.consumed OR v.expires_at<=p_now OR v.attempts>=5 OR v.purpose<>p_purpose OR v.user_id IS DISTINCT FROM p_user OR v.session_id IS DISTINCT FROM p_old_session OR encode(v.address_hash,'hex')<>v_subject THEN RETURN; END IF;
         UPDATE identity.email_challenges SET attempts=attempts+1 WHERE id=p_id;
         IF NOT identity.constant_equal(v.code_hash,p_code) THEN RETURN; END IF;
         IF p_purpose='link' THEN
          IF EXISTS(SELECT 1 FROM identity.identities i WHERE i.provider='email' AND i.subject=v_subject AND i.user_id<>p_user)
            THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='identity-conflict'; END IF;
          UPDATE identity.users AS u SET anonymous=false WHERE u.id=p_user AND u.anonymous AND u.status='active';
          IF NOT FOUND THEN RETURN; END IF;
          INSERT INTO identity.identities VALUES('email',v_subject,p_user,'') ON CONFLICT DO NOTHING;
          UPDATE identity.sessions AS s SET revoked=true WHERE s.user_id=p_user;
         ELSE
          IF v_user IS NULL THEN
           v_user:=p_new_user;
           PERFORM pg_advisory_xact_lock(hashtextextended(v_user::text,4603912));
           INSERT INTO identity.users VALUES(v_user,false,'active',p_now);
           INSERT INTO identity.identities VALUES('email',v_subject,v_user,'');
          END IF;
         END IF;
         UPDATE identity.email_challenges SET consumed=true WHERE id=p_id;
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('email-verified',v_user,p_session,p_now);
         RETURN QUERY SELECT * FROM identity.new_session(v_user,p_session,p_device,p_hash,p_now);
        END $f$;
        -- Erasure also removes the operator intent (before the user row it references).
        CREATE OR REPLACE FUNCTION identity.erase_user(p_user uuid,p_addresses bytea[]) RETURNS void
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $$
        DECLARE owned_addresses bytea[];
        BEGIN
         IF p_user IS DISTINCT FROM NULLIF(current_setting('app.user_id',true),'')::uuid OR
           NOT EXISTS(SELECT 1 FROM identity.users u WHERE u.id=p_user AND u.status='deleting') THEN RETURN; END IF;
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         -- A challenge linked to another account or another email credential is not this user's data.
         owned_addresses:=ARRAY(SELECT DISTINCT address FROM unnest(p_addresses) address WHERE octet_length(address)=32
           AND NOT EXISTS(SELECT 1 FROM identity.identities i WHERE i.provider='email' AND i.subject=encode(address,'hex') AND i.user_id<>p_user)
           AND NOT EXISTS(SELECT 1 FROM identity.email_challenges c WHERE c.address_hash=address AND c.user_id IS NOT NULL AND c.user_id<>p_user));
         DELETE FROM identity.email_challenges c WHERE c.user_id=p_user OR c.session_id IN(SELECT s.id FROM identity.sessions s WHERE s.user_id=p_user)
           OR (c.user_id IS NULL AND c.address_hash=ANY(owned_addresses));
         DELETE FROM identity.throttles t WHERE t.bucket=ANY(owned_addresses);
         DELETE FROM identity.audit a WHERE a.user_id=p_user OR a.session_id IN(SELECT s.id FROM identity.sessions s WHERE s.user_id=p_user);
         DELETE FROM identity.refresh_tokens t WHERE t.session_id IN(SELECT s.id FROM identity.sessions s WHERE s.user_id=p_user);
         DELETE FROM identity.sessions s WHERE s.user_id=p_user;
         DELETE FROM identity.devices d WHERE d.user_id=p_user;
         DELETE FROM identity.identities i WHERE i.user_id=p_user;
         DELETE FROM identity.operator_deletions o WHERE o.user_id=p_user;
         DELETE FROM identity.users u WHERE u.id=p_user;
        END $$;

        -- Asked by other modules' erasure-only definer functions (Usage's limit override): is this account being erased in the
        -- current deletion? True while it's 'deleting' and after identity.erase removed it earlier in the same transaction; never
        -- for an active (or disabled) account. Granted to no login: only migrator-owned definer functions call it.
        CREATE FUNCTION identity.erasure_in_progress(p_user uuid) RETURNS boolean
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
         SELECT NOT EXISTS(SELECT 1 FROM identity.users u WHERE u.id = p_user AND u.status = 'active');
        $f$;
        REVOKE ALL ON FUNCTION identity.erasure_in_progress(uuid) FROM PUBLIC;

        -- Console (fb_admin) reads: codes, timestamps, counts and an account-scoped opaque device key; never device ids.
        CREATE FUNCTION identity.admin_control_state(p_user uuid)
        RETURNS TABLE(status text, anonymous boolean, disabled_at timestamptz, deletion_requested_at timestamptz, deletion_attempts integer,
                      deletion_available_at timestamptz, deletion_last_error text)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
         SELECT u.status, u.anonymous, u.disabled_at, o.requested_at, o.attempts, o.available_at, o.last_error
         FROM identity.users u LEFT JOIN identity.operator_deletions o ON o.user_id = u.id WHERE u.id = p_user;
        $f$;
        CREATE FUNCTION identity.admin_device_keys(p_user uuid, p_now timestamptz)
        RETURNS TABLE(device_key text, platform text, app_version text, last_seen_at timestamptz, active_sessions bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
         SELECT left(encode(sha256(convert_to(d.user_id::text || ':' || d.device_id::text, 'UTF8')), 'hex'), 32), d.platform, d.app_version, d.last_seen_at,
                (SELECT count(*) FROM identity.sessions s WHERE s.user_id = d.user_id AND s.device_id = d.device_id AND NOT s.revoked AND s.expires_at > p_now)
         FROM identity.devices d WHERE d.user_id = p_user ORDER BY d.last_seen_at DESC NULLS LAST, 1 LIMIT 50;
        $f$;

        -- Console (fb_admin) controls. Each takes the lifecycle lock first, then revalidates the account (active, not deleting)
        -- and returns no row, writing nothing, when it's gone. The lock is held until the console's transaction commits.
        CREATE FUNCTION identity.admin_lock_account(p_user uuid) RETURNS TABLE(is_disabled boolean, deletion_pending boolean)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         RETURN QUERY SELECT u.disabled_at IS NOT NULL, EXISTS(SELECT 1 FROM identity.operator_deletions o WHERE o.user_id = u.id)
           FROM identity.users u WHERE u.id = p_user AND u.status = 'active' FOR UPDATE OF u;
        END $f$;
        CREATE FUNCTION identity.admin_revoke_sessions(p_user uuid, p_device_key text, p_now timestamptz)
        RETURNS TABLE(device_found boolean, revoked_sessions integer)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_device uuid; v_count integer;
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         PERFORM 1 FROM identity.users u WHERE u.id = p_user AND u.status = 'active' FOR UPDATE;
         IF NOT FOUND THEN RETURN; END IF;
         IF p_device_key IS NOT NULL THEN
          SELECT d.device_id INTO v_device FROM identity.devices d
           WHERE d.user_id = p_user AND left(encode(sha256(convert_to(d.user_id::text || ':' || d.device_id::text, 'UTF8')), 'hex'), 32) = p_device_key;
          IF v_device IS NULL THEN RETURN QUERY SELECT false, 0; RETURN; END IF;
         END IF;
         UPDATE identity.sessions s SET revoked = true WHERE s.user_id = p_user AND NOT s.revoked AND (v_device IS NULL OR s.device_id = v_device);
         GET DIAGNOSTICS v_count = ROW_COUNT;
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('operator-revoked',p_user,NULL,p_now);
         RETURN QUERY SELECT true, v_count;
        END $f$;
        CREATE FUNCTION identity.admin_set_disabled(p_user uuid, p_disabled boolean, p_now timestamptz)
        RETURNS TABLE(was_disabled boolean, revoked_sessions integer, outcome text)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_was boolean; v_count integer := 0;
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         SELECT u.disabled_at IS NOT NULL INTO v_was FROM identity.users u WHERE u.id = p_user AND u.status = 'active' FOR UPDATE;
         IF NOT FOUND THEN RETURN; END IF;
         IF NOT p_disabled AND EXISTS(SELECT 1 FROM identity.operator_deletions o WHERE o.user_id = p_user) THEN
          RETURN QUERY SELECT v_was, 0, 'deletion-pending'::text; RETURN;
         END IF;
         IF p_disabled THEN
          UPDATE identity.users u SET disabled_at = coalesce(u.disabled_at, p_now) WHERE u.id = p_user;
          -- Every session ends, so enabling later never brings an old one back.
          UPDATE identity.sessions s SET revoked = true WHERE s.user_id = p_user AND NOT s.revoked;
          GET DIAGNOSTICS v_count = ROW_COUNT;
         ELSE
          UPDATE identity.users u SET disabled_at = NULL WHERE u.id = p_user;
         END IF;
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at)
           VALUES(CASE WHEN p_disabled THEN 'operator-disabled' ELSE 'operator-enabled' END,p_user,NULL,p_now);
         RETURN QUERY SELECT v_was, v_count, 'ok'::text;
        END $f$;
        CREATE FUNCTION identity.admin_request_deletion(p_user uuid, p_now timestamptz)
        RETURNS TABLE(was_disabled boolean, revoked_sessions integer, created boolean)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_was boolean; v_count integer; v_created integer;
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         SELECT u.disabled_at IS NOT NULL INTO v_was FROM identity.users u WHERE u.id = p_user AND u.status = 'active' FOR UPDATE;
         IF NOT FOUND THEN RETURN; END IF;
         UPDATE identity.users u SET disabled_at = coalesce(u.disabled_at, p_now) WHERE u.id = p_user;
         UPDATE identity.sessions s SET revoked = true WHERE s.user_id = p_user AND NOT s.revoked;
         GET DIAGNOSTICS v_count = ROW_COUNT;
         INSERT INTO identity.operator_deletions(user_id,requested_at,available_at) VALUES(p_user,p_now,p_now) ON CONFLICT DO NOTHING;
         GET DIAGNOSTICS v_created = ROW_COUNT;
         IF v_created = 1 THEN
          INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('operator-deletion-requested',p_user,NULL,p_now);
         END IF;
         RETURN QUERY SELECT v_was, v_count, v_created = 1;
        END $f$;

        -- The api role's runner (fb_app). Discovery returns ids only; the capability needs the committed, due intent.
        CREATE FUNCTION identity.due_operator_deletions(p_now timestamptz, p_limit integer) RETURNS SETOF uuid
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
         SELECT o.user_id FROM identity.operator_deletions o WHERE o.available_at <= p_now
         ORDER BY o.available_at, o.user_id LIMIT least(greatest(p_limit, 1), 50);
        $f$;
        CREATE FUNCTION identity.begin_operator_deletion(p_user uuid, p_now timestamptz) RETURNS boolean
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        BEGIN
         IF p_user IS DISTINCT FROM NULLIF(current_setting('app.user_id',true),'')::uuid THEN RETURN false; END IF;
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         PERFORM 1 FROM identity.operator_deletions o WHERE o.user_id = p_user AND o.available_at <= p_now FOR UPDATE;
         IF NOT FOUND THEN RETURN false; END IF;
         PERFORM 1 FROM identity.users u WHERE u.id = p_user AND u.status = 'active' FOR UPDATE;
         IF NOT FOUND THEN RETURN false; END IF;
         UPDATE identity.users SET status = 'deleting' WHERE id = p_user;
         UPDATE identity.sessions SET revoked = true WHERE user_id = p_user;
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('deletion-pending',p_user,NULL,p_now);
         RETURN true;
        END $f$;
        CREATE FUNCTION identity.record_operator_deletion_failure(p_user uuid, p_code text, p_now timestamptz) RETURNS boolean
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        BEGIN
         IF p_user IS DISTINCT FROM NULLIF(current_setting('app.user_id',true),'')::uuid
           OR p_code IS NULL OR p_code NOT IN ('recovery-unavailable','unavailable','failed') THEN RETURN false; END IF;
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         -- Only while the intent still exists: after a committed deletion this changes nothing and recreates nothing.
         UPDATE identity.operator_deletions o SET attempts = least(o.attempts + 1, 1000), last_error = p_code,
           available_at = p_now + least(interval '1 minute' * power(2, least(o.attempts, 10)), interval '1 hour')
         WHERE o.user_id = p_user;
         RETURN FOUND;
        END $f$;

        DO $body$ DECLARE f text; BEGIN
         FOREACH f IN ARRAY ARRAY['identity.admin_control_state(uuid)','identity.admin_device_keys(uuid,timestamptz)',
                                  'identity.admin_lock_account(uuid)','identity.admin_revoke_sessions(uuid,text,timestamptz)',
                                  'identity.admin_set_disabled(uuid,boolean,timestamptz)','identity.admin_request_deletion(uuid,timestamptz)'] LOOP
          EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', f);
          EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO fb_admin', f);
         END LOOP;
         FOREACH f IN ARRAY ARRAY['identity.due_operator_deletions(timestamptz,integer)','identity.begin_operator_deletion(uuid,timestamptz)',
                                  'identity.record_operator_deletion_failure(uuid,text,timestamptz)'] LOOP
          EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', f);
          EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO fb_app', f);
         END LOOP;
        END $body$;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Identity rollback requires verified recovery.");
}
