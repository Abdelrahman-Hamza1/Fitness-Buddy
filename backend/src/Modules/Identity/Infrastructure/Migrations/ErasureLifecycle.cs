using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Identity.Infrastructure.Migrations;

[DbContext(typeof(IdentityContext))]
[Migration("202610190001_ErasureLifecycle")]
internal sealed class ErasureLifecycle : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE OR REPLACE FUNCTION identity.new_session(p_user uuid,p_session uuid,p_device uuid,p_hash bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         PERFORM 1 FROM identity.users u WHERE u.id=p_user AND u.status='active' FOR UPDATE;
         IF NOT FOUND THEN RETURN; END IF;
         INSERT INTO identity.devices VALUES(p_user,p_device) ON CONFLICT DO NOTHING;
         INSERT INTO identity.sessions VALUES(p_session,p_user,p_device,p_now+interval '30 days',false);
         INSERT INTO identity.refresh_tokens VALUES(p_hash,p_session,false);
         RETURN QUERY SELECT u.id,u.anonymous,p_session,p_now+interval '30 days' FROM identity.users u WHERE u.id=p_user;
        END $f$;
        CREATE OR REPLACE FUNCTION identity.create_guest(p_user uuid,p_session uuid,p_device uuid,p_hash bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         INSERT INTO identity.users VALUES(p_user,true,'active',p_now);
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('guest-created',p_user,p_session,p_now);
         RETURN QUERY SELECT * FROM identity.new_session(p_user,p_session,p_device,p_hash,p_now);
        END $f$;
        CREATE OR REPLACE FUNCTION identity.sign_in_provider(p_provider text,p_subject text,p_email text,p_new_user uuid,p_session uuid,p_device uuid,p_hash bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_user uuid;
        BEGIN
         -- Google proof is validated by the application adapter before this capability is invoked.
         IF p_provider <> 'google' OR p_subject='' THEN RETURN; END IF;
         PERFORM pg_advisory_xact_lock(hashtextextended(p_provider||':'||p_subject,0));
         SELECT i.user_id INTO v_user FROM identity.identities i WHERE i.provider=p_provider AND i.subject=p_subject;
         IF v_user IS NULL THEN
          INSERT INTO identity.users VALUES(p_new_user,false,'active',p_now);
          INSERT INTO identity.identities VALUES(p_provider,p_subject,p_new_user,p_email);
          v_user:=p_new_user;
         END IF;
         PERFORM pg_advisory_xact_lock(hashtextextended(v_user::text,4603912));
         PERFORM 1 FROM identity.users u JOIN identity.identities i ON i.user_id=u.id
           WHERE u.id=v_user AND u.status='active' AND i.provider=p_provider AND i.subject=p_subject FOR UPDATE OF u;
         IF NOT FOUND THEN RETURN; END IF;
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('provider-sign-in',v_user,p_session,p_now);
         RETURN QUERY SELECT * FROM identity.new_session(v_user,p_session,p_device,p_hash,p_now);
        END $f$;
        CREATE OR REPLACE FUNCTION identity.revoke_session(p_user uuid,p_session uuid,p_now timestamptz) RETURNS void
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         UPDATE identity.sessions SET revoked=true WHERE id=p_session AND user_id=p_user;
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) SELECT 'logout',p_user,p_session,p_now WHERE EXISTS(SELECT 1 FROM identity.sessions WHERE id=p_session AND user_id=p_user);
        END $f$;
        CREATE OR REPLACE FUNCTION identity.rotate_refresh(p_old bytea,p_new bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_session identity.sessions; v_consumed boolean;
        BEGIN
         SELECT s.* INTO v_session FROM identity.sessions s JOIN identity.refresh_tokens t ON t.session_id=s.id WHERE t.hash=p_old;
         IF NOT FOUND THEN RETURN; END IF;
         PERFORM pg_advisory_xact_lock(hashtextextended(v_session.user_id::text,4603912));
         PERFORM 1 FROM identity.users u WHERE u.id=v_session.user_id AND u.status='active' FOR SHARE;
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
         IF NOT EXISTS(SELECT 1 FROM identity.users u WHERE u.id=v_session.user_id AND u.status='active') THEN RETURN; END IF;
         UPDATE identity.refresh_tokens SET consumed=true WHERE hash=p_old;
         INSERT INTO identity.refresh_tokens VALUES(p_new,v_session.id,false);
         RETURN QUERY SELECT * FROM identity.read_session(v_session.user_id,v_session.id,p_now);
        END $f$;
        CREATE OR REPLACE FUNCTION identity.start_email(p_id uuid,p_address bytea,p_code bytea,p_purpose text,p_user uuid,p_session uuid,p_ip bytea,p_now timestamptz) RETURNS boolean
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_user uuid;
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended('email:'||encode(p_address,'hex'),0));
         IF p_purpose='link' THEN v_user:=p_user;
         ELSE SELECT i.user_id INTO v_user FROM identity.identities i WHERE i.provider='email' AND i.subject=encode(p_address,'hex'); END IF;
         IF v_user IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(hashtextextended(v_user::text,4603912));
          PERFORM 1 FROM identity.users u WHERE u.id=v_user AND u.status='active' FOR SHARE;
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
          PERFORM 1 FROM identity.users u WHERE u.id=v_user AND u.status='active' FOR UPDATE;
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
        CREATE OR REPLACE FUNCTION identity.link_google(p_user uuid,p_old_session uuid,p_subject text,p_email text,p_session uuid,p_device uuid,p_hash bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_user uuid;
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended('google:'||p_subject,0));
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         PERFORM 1 FROM identity.users u WHERE u.id=p_user FOR UPDATE;
         PERFORM 1 FROM identity.sessions s WHERE s.id=p_old_session AND s.user_id=p_user FOR UPDATE;
         IF NOT EXISTS(SELECT 1 FROM identity.read_session(p_user,p_old_session,p_now) s WHERE s.anonymous) THEN RETURN; END IF;
         SELECT i.user_id INTO v_user FROM identity.identities i WHERE i.provider='google' AND i.subject=p_subject;
         IF v_user IS NOT NULL AND v_user<>p_user THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='identity-conflict'; END IF;
         INSERT INTO identity.identities VALUES('google',p_subject,p_user,p_email) ON CONFLICT DO NOTHING;
         UPDATE identity.users AS u SET anonymous=false WHERE u.id=p_user AND u.anonymous AND u.status='active';
          IF NOT FOUND THEN RETURN; END IF;
         UPDATE identity.sessions AS s SET revoked=true WHERE s.user_id=p_user;
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('identity-linked',p_user,p_session,p_now);
         RETURN QUERY SELECT * FROM identity.new_session(p_user,p_session,p_device,p_hash,p_now);
        END $f$;

        CREATE FUNCTION identity.check_user_active(p_user uuid) RETURNS boolean
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $$
        BEGIN
         PERFORM 1 FROM identity.users u WHERE u.id=p_user AND u.status='active' FOR SHARE;
         RETURN FOUND;
        END $$;
        CREATE FUNCTION identity.begin_deletion(p_user uuid,p_session uuid,p_now timestamptz) RETURNS boolean
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $$
        BEGIN
         IF p_user IS DISTINCT FROM NULLIF(current_setting('app.user_id',true),'')::uuid THEN RETURN false; END IF;
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         IF NOT identity.check_active(p_user,p_session,false,p_now) THEN RETURN false; END IF;
         UPDATE identity.users SET status='deleting' WHERE id=p_user;
         UPDATE identity.sessions SET revoked=true WHERE user_id=p_user;
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('deletion-pending',p_user,p_session,p_now);
         RETURN true;
        END $$;
        CREATE FUNCTION identity.erasure_identifiers(p_user uuid) RETURNS TABLE(provider text,subject text,email text)
        LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $$
         SELECT i.provider,i.subject,i.email FROM identity.identities i
          WHERE i.user_id=p_user AND p_user=NULLIF(current_setting('app.user_id',true),'')::uuid
          AND EXISTS(SELECT 1 FROM identity.users u WHERE u.id=p_user AND u.status='deleting')
         UNION
         SELECT 'challenge',encode(c.address_hash,'hex'),'' FROM identity.email_challenges c
          WHERE c.user_id=p_user AND p_user=NULLIF(current_setting('app.user_id',true),'')::uuid
          AND EXISTS(SELECT 1 FROM identity.users u WHERE u.id=p_user AND u.status='deleting');
        $$;
        CREATE FUNCTION identity.erase_user(p_user uuid,p_addresses bytea[]) RETURNS void
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
         DELETE FROM identity.users u WHERE u.id=p_user;
        END $$;
        REVOKE ALL ON FUNCTION identity.check_user_active(uuid),identity.begin_deletion(uuid,uuid,timestamptz),identity.erasure_identifiers(uuid),identity.erase_user(uuid,bytea[]) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION identity.check_user_active(uuid),identity.begin_deletion(uuid,uuid,timestamptz),identity.erasure_identifiers(uuid),identity.erase_user(uuid,bytea[]) TO fb_app;

        """);
    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Identity lifecycle fencing cannot be rolled back.");
}
