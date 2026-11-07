using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Identity.Infrastructure.Migrations;

/// <summary>
/// R1 security audit (expand only): a new email-code request no longer invalidates earlier live codes, so an unauthenticated
/// caller who knows an address can't cancel the code its owner is about to type. Delivery throttling (per IP and per address)
/// stays as it was and only decides whether a new code is sent; at most five challenges are live per address. Guessing stays
/// bounded per challenge (five attempts, each verification names its challenge), so wrong guesses on one challenge never
/// lock out another, and the address total (5 codes an hour x 5 attempts) is the same as before.
/// </summary>
[DbContext(typeof(IdentityContext))]
[Migration("202611090001_EmailChallengeBudget")]
internal sealed class EmailChallengeBudget : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE INDEX email_address_live ON identity.email_challenges(address_hash,expires_at) WHERE NOT consumed;

        -- OperatorControls' body, minus the invalidation of earlier challenges, plus the live-challenge cap.
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
         IF (SELECT count(*) FROM identity.email_challenges c WHERE c.address_hash=p_address AND NOT c.consumed AND c.expires_at>p_now)>=5 THEN RETURN false; END IF;
         INSERT INTO identity.email_challenges VALUES(p_id,p_address,p_code,p_purpose,p_user,p_session,p_now,p_now+interval '10 minutes',0,false);
         RETURN true;
        END $f$;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Identity rollback requires verified recovery.");
}
