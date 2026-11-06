using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.UserData.Infrastructure.Migrations;

/// <summary>
/// B23 WP8 (expand only): per-user, per-day sync counts by outcome and reject reason for the console (AD-011 sync health,
/// AD-014). User-owned like <c>documents</c> (ENABLE + FORCE RLS, erased with the account, 90 days). The owner gets a
/// SELECT-only policy so the <c>admin_*</c> definer functions can aggregate; they return counts, sizes, closed entity codes,
/// timestamps and pseudonymous ids, never a payload (owner O1, TD-118).
/// </summary>
[DbContext(typeof(UserDataContext))]
[Migration("202611070001_SyncDaily")]
internal sealed class SyncDaily : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE TABLE userdata.sync_daily(
          user_id uuid NOT NULL, day date NOT NULL,
          pushes integer NOT NULL DEFAULT 0, pulls integer NOT NULL DEFAULT 0, changes_in integer NOT NULL DEFAULT 0, stale integer NOT NULL DEFAULT 0,
          clock_drift integer NOT NULL DEFAULT 0, version_conflict integer NOT NULL DEFAULT 0, unsupported integer NOT NULL DEFAULT 0,
          invalid_payload integer NOT NULL DEFAULT 0, dataset_mismatch integer NOT NULL DEFAULT 0, cursor_invalid integer NOT NULL DEFAULT 0,
          last_push_at timestamptz, last_pull_at timestamptz,
          PRIMARY KEY(user_id, day));
        CREATE INDEX sync_daily_day ON userdata.sync_daily(day);
        ALTER TABLE userdata.sync_daily ENABLE ROW LEVEL SECURITY;
        ALTER TABLE userdata.sync_daily FORCE ROW LEVEL SECURITY;
        CREATE POLICY user_isolation ON userdata.sync_daily TO fb_app
          USING(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid)
          WITH CHECK(user_id=NULLIF(current_setting('app.user_id',true),'')::uuid);
        CREATE POLICY owner_maintenance ON userdata.sync_daily TO fb_migrator USING(true) WITH CHECK(true);
        -- User data the API owns (B23b security review): written in the push/pull transactions and erased in the deletion
        -- request, so the API login keeps its writes; the worker inherits them for retention. Not a worker-health signal.
        GRANT SELECT, INSERT, UPDATE, DELETE ON userdata.sync_daily TO fb_app;
        GRANT USAGE ON SCHEMA userdata TO fb_admin;

        -- Per account: live documents, stored bytes (documents + history), rejects since a day, last push/pull.
        CREATE FUNCTION userdata.admin_user_stats(p_users uuid[], p_since date)
        RETURNS TABLE(user_id uuid, documents bigint, storage_bytes bigint, rejects bigint, last_push_at timestamptz, last_pull_at timestamptz)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT u.id, coalesce(d.documents, 0), coalesce(d.bytes, 0) + coalesce(h.bytes, 0), coalesce(s.rejects, 0), s.last_push, s.last_pull
         FROM (SELECT DISTINCT x.id FROM unnest(p_users[1:200]) AS x(id)) u
         LEFT JOIN LATERAL (SELECT count(*) FILTER (WHERE dd.deleted_at IS NULL) AS documents, sum(pg_column_size(dd.payload))::bigint AS bytes
                            FROM userdata.documents dd WHERE dd.user_id = u.id) d ON true
         LEFT JOIN LATERAL (SELECT sum(pg_column_size(hh.payload))::bigint AS bytes FROM userdata.row_history hh WHERE hh.user_id = u.id) h ON true
         LEFT JOIN LATERAL (SELECT sum(ss.clock_drift + ss.version_conflict + ss.unsupported + ss.invalid_payload + ss.dataset_mismatch + ss.cursor_invalid)
                                     FILTER (WHERE ss.day >= p_since)::bigint AS rejects,
                                   max(ss.last_push_at) AS last_push, max(ss.last_pull_at) AS last_pull
                            FROM userdata.sync_daily ss WHERE ss.user_id = u.id) s ON true;
        $f$;

        -- Most rejects first, keyset-paged after (p_after_rejects, p_after_user) so the console can page and filter (B23b review).
        CREATE FUNCTION userdata.admin_users_with_issues(p_since date, p_limit integer, p_after_rejects bigint, p_after_user uuid)
        RETURNS TABLE(user_id uuid, rejects bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT t.user_id, t.rejects FROM (
           SELECT s.user_id, sum(s.clock_drift + s.version_conflict + s.unsupported + s.invalid_payload + s.dataset_mismatch + s.cursor_invalid)::bigint AS rejects
           FROM userdata.sync_daily s WHERE s.day >= p_since GROUP BY s.user_id) t
         WHERE t.rejects > 0 AND (p_after_rejects IS NULL OR (t.rejects, t.user_id) < (p_after_rejects, p_after_user))
         ORDER BY t.rejects DESC, t.user_id DESC LIMIT least(greatest(p_limit, 1), 200);
        $f$;

        CREATE FUNCTION userdata.admin_sync_summary(p_since date)
        RETURNS TABLE(pushes bigint, pulls bigint, changes_in bigint, stale bigint, clock_drift bigint, version_conflict bigint, unsupported bigint,
                      invalid_payload bigint, dataset_mismatch bigint, cursor_invalid bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT coalesce(sum(s.pushes), 0)::bigint, coalesce(sum(s.pulls), 0)::bigint, coalesce(sum(s.changes_in), 0)::bigint, coalesce(sum(s.stale), 0)::bigint,
                coalesce(sum(s.clock_drift), 0)::bigint, coalesce(sum(s.version_conflict), 0)::bigint, coalesce(sum(s.unsupported), 0)::bigint,
                coalesce(sum(s.invalid_payload), 0)::bigint, coalesce(sum(s.dataset_mismatch), 0)::bigint, coalesce(sum(s.cursor_invalid), 0)::bigint
         FROM userdata.sync_daily s WHERE s.day >= p_since;
        $f$;

        -- Documents by entity code and schema version, for one account or (null) everyone. An entity outside the caller's closed
        -- sync set (the contract registry) reads 'other' (B23b security review).
        CREATE FUNCTION userdata.admin_documents(p_user uuid, p_entities text[])
        RETURNS TABLE(entity text, schema_version integer, documents bigint, deleted bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT CASE WHEN d.entity = ANY(p_entities) THEN d.entity::text ELSE 'other' END, d.schema_version,
                count(*) FILTER (WHERE d.deleted_at IS NULL), count(*) FILTER (WHERE d.deleted_at IS NOT NULL)
         FROM userdata.documents d WHERE p_user IS NULL OR d.user_id = p_user
         GROUP BY 1, 2 ORDER BY 1, 2;
        $f$;

        DO $body$ DECLARE f text; BEGIN
         FOREACH f IN ARRAY ARRAY['userdata.admin_user_stats(uuid[],date)','userdata.admin_users_with_issues(date,integer,bigint,uuid)',
                                  'userdata.admin_sync_summary(date)','userdata.admin_documents(uuid,text[])'] LOOP
          EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', f);
          EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO fb_admin', f);
         END LOOP;
        END $body$;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        DROP FUNCTION userdata.admin_user_stats(uuid[],date), userdata.admin_users_with_issues(date,integer,bigint,uuid), userdata.admin_sync_summary(date),
          userdata.admin_documents(uuid,text[]);
        DROP TABLE userdata.sync_daily;
        """);
}
