using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Usage.Infrastructure.Migrations;

/// <summary>
/// B24 (expand only): a per-account Buddy daily call limit set by an operator (AD-011). User data (erased with the account);
/// the application login reads only its own row (RLS) and has no direct write: it can remove the row only through
/// <c>erase_limit_override</c>, which refuses unless Identity reports the account is being erased (so a compromised api
/// process can't lift an operator's zero limit). Only the console login can set it,
/// through <c>admin_set_daily_limit</c>, which takes the user lifecycle lock first (the console also revalidates the account
/// with Identity under the same lock in the same transaction, so a finished deletion can't be followed by a new row).
/// </summary>
[DbContext(typeof(UsageContext))]
[Migration("202611080001_LimitOverrides")]
internal sealed class LimitOverrides : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE TABLE usage.limit_overrides(user_id uuid PRIMARY KEY, daily_calls integer NOT NULL CHECK(daily_calls BETWEEN 0 AND 1000), updated_at timestamptz NOT NULL);
        ALTER TABLE usage.limit_overrides ENABLE ROW LEVEL SECURITY;
        ALTER TABLE usage.limit_overrides FORCE ROW LEVEL SECURITY;
        CREATE POLICY user_isolation ON usage.limit_overrides TO fb_app
          USING(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid)
          WITH CHECK(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid);
        CREATE POLICY owner_access ON usage.limit_overrides TO fb_migrator USING(true) WITH CHECK(true);
        REVOKE ALL ON usage.limit_overrides FROM PUBLIC;
        GRANT SELECT ON usage.limit_overrides TO fb_app;

        CREATE FUNCTION usage.admin_daily_limit(p_user uuid) RETURNS integer
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,usage,pg_temp AS $f$
         SELECT o.daily_calls FROM usage.limit_overrides o WHERE o.user_id = p_user;
        $f$;
        -- Returns the previous limit (NULL = the default). NULL clears the override.
        CREATE FUNCTION usage.admin_set_daily_limit(p_user uuid, p_calls integer, p_now timestamptz) RETURNS integer
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,usage,pg_temp AS $f$
        DECLARE v_previous integer;
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         SELECT o.daily_calls INTO v_previous FROM usage.limit_overrides o WHERE o.user_id = p_user FOR UPDATE;
         IF p_calls IS NULL THEN
          DELETE FROM usage.limit_overrides o WHERE o.user_id = p_user;
         ELSE
          INSERT INTO usage.limit_overrides(user_id,daily_calls,updated_at) VALUES(p_user,p_calls,p_now)
           ON CONFLICT(user_id) DO UPDATE SET daily_calls = excluded.daily_calls, updated_at = excluded.updated_at;
         END IF;
         RETURN v_previous;
        END $f$;
        -- Erasure only: the caller's own account, and only while Identity says it's being erased (deleting, or already erased
        -- earlier in the same deletion transaction). Anything else is refused loudly, so a deletion never completes around it.
        -- The user lifecycle lock comes first and is held through the DELETE (re-entrant: the deletion coordinator already holds
        -- it, after the recovery lock), so no account creation or operator override can commit between the check and the delete.
        CREATE FUNCTION usage.erase_limit_override(p_user uuid) RETURNS void
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,usage,pg_temp AS $f$
        BEGIN
         PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,4603912));
         IF p_user IS DISTINCT FROM NULLIF(current_setting('app.user_id',true),'')::uuid OR NOT identity.erasure_in_progress(p_user) THEN
          RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='limit-override-not-erasable';
         END IF;
         DELETE FROM usage.limit_overrides o WHERE o.user_id = p_user;
        END $f$;
        REVOKE ALL ON FUNCTION usage.admin_daily_limit(uuid), usage.admin_set_daily_limit(uuid,integer,timestamptz), usage.erase_limit_override(uuid) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION usage.erase_limit_override(uuid) TO fb_app;
        GRANT USAGE ON SCHEMA usage TO fb_admin;
        GRANT EXECUTE ON FUNCTION usage.admin_daily_limit(uuid), usage.admin_set_daily_limit(uuid,integer,timestamptz) TO fb_admin;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        DROP FUNCTION usage.erase_limit_override(uuid), usage.admin_daily_limit(uuid), usage.admin_set_daily_limit(uuid,integer,timestamptz);
        DROP TABLE usage.limit_overrides;
        """);
}
