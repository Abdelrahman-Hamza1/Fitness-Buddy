using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Identity.Infrastructure.Migrations;

[DbContext(typeof(IdentityContext))]
[Migration("202610180001_InitialIdentity")]
internal sealed class InitialIdentity : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql(
        """
        -- TD-077: only named credential capabilities cross the pre-auth boundary.
        REVOKE ALL ON SCHEMA identity FROM PUBLIC;
        GRANT USAGE ON SCHEMA identity TO fb_app;
        CREATE TABLE identity.users(id uuid PRIMARY KEY, anonymous boolean NOT NULL, status text NOT NULL DEFAULT 'active' CHECK(status IN ('active','deleting','deleted')), created_at timestamptz NOT NULL);
        CREATE TABLE identity.identities(provider text NOT NULL CHECK(provider IN ('google','email')), subject text NOT NULL, user_id uuid NOT NULL REFERENCES identity.users, email text NOT NULL, PRIMARY KEY(provider,subject));
        CREATE TABLE identity.devices(user_id uuid NOT NULL REFERENCES identity.users, device_id uuid NOT NULL, PRIMARY KEY(user_id,device_id));
        CREATE TABLE identity.sessions(id uuid PRIMARY KEY, user_id uuid NOT NULL REFERENCES identity.users, device_id uuid NOT NULL, expires_at timestamptz NOT NULL, revoked boolean NOT NULL DEFAULT false);
        CREATE TABLE identity.refresh_tokens(hash bytea PRIMARY KEY CHECK(octet_length(hash)=32), session_id uuid NOT NULL REFERENCES identity.sessions, consumed boolean NOT NULL DEFAULT false);
        CREATE TABLE identity.email_challenges(id uuid PRIMARY KEY, address_hash bytea NOT NULL, code_hash bytea NOT NULL CHECK(octet_length(code_hash)=32), purpose text NOT NULL CHECK(purpose IN ('signIn','link')), user_id uuid REFERENCES identity.users, session_id uuid REFERENCES identity.sessions, created_at timestamptz NOT NULL, expires_at timestamptz NOT NULL, attempts integer NOT NULL DEFAULT 0, consumed boolean NOT NULL DEFAULT false, CHECK((purpose='signIn' AND user_id IS NULL AND session_id IS NULL) OR (purpose='link' AND user_id IS NOT NULL AND session_id IS NOT NULL)));
        CREATE INDEX email_address_created ON identity.email_challenges(address_hash,created_at);
        CREATE TABLE identity.throttles(bucket bytea PRIMARY KEY, started_at timestamptz NOT NULL, last_at timestamptz NOT NULL, count integer NOT NULL);
        CREATE TABLE identity.signing_keys(kid text PRIMARY KEY, public_jwk jsonb NOT NULL, ciphertext bytea NOT NULL, nonce bytea NOT NULL CHECK(octet_length(nonce)=12), tag bytea NOT NULL CHECK(octet_length(tag)=16), wrapping_version text NOT NULL, active boolean NOT NULL, validate_until timestamptz NOT NULL);
        CREATE UNIQUE INDEX signing_active ON identity.signing_keys(active) WHERE active;
        CREATE TABLE identity.audit(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, event text NOT NULL, user_id uuid, session_id uuid, occurred_at timestamptz NOT NULL);
        -- No app-role direct table grants; owner path is limited to these schema-owned functions.
        DO $body$ DECLARE t text; BEGIN
         FOREACH t IN ARRAY ARRAY['users','identities','devices','sessions','email_challenges','audit','refresh_tokens','signing_keys','throttles'] LOOP
          EXECUTE format('ALTER TABLE identity.%I ENABLE ROW LEVEL SECURITY',t);
          EXECUTE format('ALTER TABLE identity.%I FORCE ROW LEVEL SECURITY',t);
          EXECUTE format('CREATE POLICY identity_owner ON identity.%I TO fb_migrator USING(true) WITH CHECK(true)',t);
         END LOOP;
        END $body$;
        CREATE POLICY own_user ON identity.users TO fb_app USING(id=NULLIF(current_setting('app.user_id',true),'')::uuid) WITH CHECK(id=NULLIF(current_setting('app.user_id',true),'')::uuid);
        DO $body$ DECLARE t text; BEGIN
         FOREACH t IN ARRAY ARRAY['identities','devices','sessions','email_challenges','audit'] LOOP
          EXECUTE format('CREATE POLICY own_user ON identity.%I TO fb_app USING(user_id=NULLIF(current_setting(''app.user_id'',true),'''')::uuid) WITH CHECK(user_id=NULLIF(current_setting(''app.user_id'',true),'''')::uuid)',t);
         END LOOP;
        END $body$;
        CREATE FUNCTION identity.new_session(p_user uuid,p_session uuid,p_device uuid,p_hash bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        BEGIN
         IF NOT EXISTS(SELECT 1 FROM identity.users u WHERE u.id=p_user AND u.status='active') THEN RETURN; END IF;
         INSERT INTO identity.devices VALUES(p_user,p_device) ON CONFLICT DO NOTHING;
         INSERT INTO identity.sessions VALUES(p_session,p_user,p_device,p_now+interval '30 days',false);
         INSERT INTO identity.refresh_tokens VALUES(p_hash,p_session,false);
         RETURN QUERY SELECT u.id,u.anonymous,p_session,p_now+interval '30 days' FROM identity.users u WHERE u.id=p_user;
        END $f$;
        CREATE FUNCTION identity.create_guest(p_user uuid,p_session uuid,p_device uuid,p_hash bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        BEGIN
         INSERT INTO identity.users VALUES(p_user,true,'active',p_now);
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('guest-created',p_user,p_session,p_now);
         RETURN QUERY SELECT * FROM identity.new_session(p_user,p_session,p_device,p_hash,p_now);
        END $f$;
        CREATE FUNCTION identity.sign_in_provider(p_provider text,p_subject text,p_email text,p_new_user uuid,p_session uuid,p_device uuid,p_hash bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
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
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('provider-sign-in',v_user,p_session,p_now);
         RETURN QUERY SELECT * FROM identity.new_session(v_user,p_session,p_device,p_hash,p_now);
        END $f$;
        CREATE FUNCTION identity.read_session(p_user uuid,p_session uuid,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
         SELECT u.id,u.anonymous,s.id,s.expires_at FROM identity.sessions s JOIN identity.users u ON u.id=s.user_id
         WHERE s.id=p_session AND s.user_id=p_user AND NOT s.revoked AND s.expires_at>p_now AND u.status='active';
        $f$;
        CREATE FUNCTION identity.revoke_session(p_user uuid,p_session uuid,p_now timestamptz) RETURNS void
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        BEGIN
         UPDATE identity.sessions SET revoked=true WHERE id=p_session AND user_id=p_user;
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) SELECT 'logout',p_user,p_session,p_now WHERE EXISTS(SELECT 1 FROM identity.sessions WHERE id=p_session AND user_id=p_user);
        END $f$;
        CREATE FUNCTION identity.rotate_refresh(p_old bytea,p_new bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_session identity.sessions; v_consumed boolean;
        BEGIN
         SELECT s.* INTO v_session FROM identity.sessions s JOIN identity.refresh_tokens t ON t.session_id=s.id WHERE t.hash=p_old FOR UPDATE OF s;
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
        CREATE FUNCTION identity.take_throttle(p_bucket bytea,p_limit integer,p_gap_seconds integer,p_now timestamptz) RETURNS boolean
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v identity.throttles;
        BEGIN
         INSERT INTO identity.throttles VALUES(p_bucket,p_now,p_now-interval '1 hour',0) ON CONFLICT DO NOTHING;
         SELECT * INTO v FROM identity.throttles WHERE bucket=p_bucket FOR UPDATE;
         IF v.last_at>p_now-make_interval(secs=>p_gap_seconds) THEN RETURN false; END IF;
         IF v.started_at<=p_now-interval '1 hour' THEN v.count:=0;v.started_at:=p_now; END IF;
         IF v.count>=p_limit THEN RETURN false; END IF;
         UPDATE identity.throttles SET started_at=v.started_at,last_at=p_now,count=v.count+1 WHERE bucket=p_bucket;
         RETURN true;
        END $f$;
        CREATE FUNCTION identity.start_email(p_id uuid,p_address bytea,p_code bytea,p_purpose text,p_user uuid,p_session uuid,p_ip bytea,p_now timestamptz) RETURNS boolean
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        BEGIN
         IF p_purpose='link' AND NOT EXISTS(SELECT 1 FROM identity.read_session(p_user,p_session,p_now) s WHERE s.anonymous) THEN RETURN false; END IF;
         IF NOT identity.take_throttle(p_ip,30,0,p_now) THEN RETURN false; END IF;
         IF NOT identity.take_throttle(p_address,5,60,p_now) THEN RETURN false; END IF;
         UPDATE identity.email_challenges SET consumed=true WHERE address_hash=p_address AND purpose=p_purpose AND NOT consumed;
         INSERT INTO identity.email_challenges VALUES(p_id,p_address,p_code,p_purpose,p_user,p_session,p_now,p_now+interval '10 minutes',0,false);
         RETURN true;
        END $f$;
        CREATE FUNCTION identity.constant_equal(a bytea,b bytea) RETURNS boolean
        LANGUAGE plpgsql SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE d integer:=0; n integer;
        BEGIN
         IF a IS NULL OR b IS NULL OR octet_length(a)<>32 OR octet_length(b)<>32 THEN RETURN false; END IF;
         FOR n IN 0..31 LOOP d:=d|(get_byte(a,n)#get_byte(b,n)); END LOOP;
         RETURN d=0;
        END $f$;
        -- Email proof consumption and the account/session mutation are one database transaction.
        CREATE FUNCTION identity.consume_email(p_id uuid,p_code bytea,p_purpose text,p_user uuid,p_old_session uuid,p_new_user uuid,p_session uuid,p_device uuid,p_hash bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v identity.email_challenges; v_user uuid; v_subject text;
        BEGIN
         SELECT * INTO v FROM identity.email_challenges WHERE id=p_id FOR UPDATE;
         IF NOT FOUND OR v.consumed OR v.expires_at<=p_now OR v.attempts>=5 OR v.purpose<>p_purpose OR v.user_id IS DISTINCT FROM p_user OR v.session_id IS DISTINCT FROM p_old_session THEN RETURN; END IF;
         UPDATE identity.email_challenges SET attempts=attempts+1 WHERE id=p_id;
         IF NOT identity.constant_equal(v.code_hash,p_code) THEN RETURN; END IF;
         v_subject:=encode(v.address_hash,'hex');
         PERFORM pg_advisory_xact_lock(hashtextextended('email:'||v_subject,0));
         SELECT i.user_id INTO v_user FROM identity.identities i WHERE i.provider='email' AND i.subject=v_subject;
         IF p_purpose='link' THEN
          PERFORM 1 FROM identity.users u WHERE u.id=p_user FOR UPDATE;
         PERFORM 1 FROM identity.sessions s WHERE s.id=p_old_session AND s.user_id=p_user FOR UPDATE;
          IF NOT EXISTS(SELECT 1 FROM identity.read_session(p_user,p_old_session,p_now) s WHERE s.anonymous) THEN RETURN; END IF;
          IF v_user IS NOT NULL AND v_user<>p_user THEN RAISE EXCEPTION USING ERRCODE='P0002',MESSAGE='identity-conflict'; END IF;
          v_user:=p_user;
          UPDATE identity.users AS u SET anonymous=false WHERE u.id=p_user AND u.anonymous AND u.status='active';
          IF NOT FOUND THEN RETURN; END IF;
          INSERT INTO identity.identities VALUES('email',v_subject,p_user,'') ON CONFLICT DO NOTHING;
          UPDATE identity.sessions AS s SET revoked=true WHERE s.user_id=p_user;
         ELSE
          IF v_user IS NULL THEN
           v_user:=p_new_user;
           INSERT INTO identity.users VALUES(v_user,false,'active',p_now);
           INSERT INTO identity.identities VALUES('email',v_subject,v_user,'');
          END IF;
         END IF;
         UPDATE identity.email_challenges SET consumed=true WHERE id=p_id;
         INSERT INTO identity.audit(event,user_id,session_id,occurred_at) VALUES('email-verified',v_user,p_session,p_now);
         RETURN QUERY SELECT * FROM identity.new_session(v_user,p_session,p_device,p_hash,p_now);
        END $f$;
        CREATE FUNCTION identity.link_google(p_user uuid,p_old_session uuid,p_subject text,p_email text,p_session uuid,p_device uuid,p_hash bytea,p_now timestamptz) RETURNS TABLE(user_id uuid,anonymous boolean,session_id uuid,expires_at timestamptz)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$
        DECLARE v_user uuid;
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended('google:'||p_subject,0));
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
        CREATE FUNCTION identity.read_keyring() RETURNS SETOF identity.signing_keys
        LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog,identity,pg_temp AS $f$ SELECT * FROM identity.signing_keys; $f$;
        REVOKE ALL ON ALL TABLES IN SCHEMA identity FROM PUBLIC,fb_app;
        REVOKE ALL ON ALL FUNCTIONS IN SCHEMA identity FROM PUBLIC,fb_app;
        GRANT EXECUTE ON FUNCTION identity.create_guest(uuid,uuid,uuid,bytea,timestamptz),identity.sign_in_provider(text,text,text,uuid,uuid,uuid,bytea,timestamptz),identity.read_session(uuid,uuid,timestamptz),identity.revoke_session(uuid,uuid,timestamptz),identity.rotate_refresh(bytea,bytea,timestamptz),identity.start_email(uuid,bytea,bytea,text,uuid,uuid,bytea,timestamptz),identity.consume_email(uuid,bytea,text,uuid,uuid,uuid,uuid,uuid,bytea,timestamptz),identity.link_google(uuid,uuid,text,text,uuid,uuid,bytea,timestamptz),identity.read_keyring() TO fb_app;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) =>
        throw new NotSupportedException("Identity rollback requires an explicit recovery plan.");
}
