using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Catalog.Infrastructure.Migrations;

/// <summary>
/// B23 WP8 (expand only): daily Open Food Facts lookup outcomes and B22 sanity rules for the console (AD-015). Global and
/// content-free: closed outcome and rule codes with a count, never a barcode. Kept 90 days (the OFF expiry job). The
/// <c>admin_*</c> functions return counts, versions, sizes and a hash prefix; only the console login can run them (O1, TD-118).
/// </summary>
[DbContext(typeof(CatalogContext))]
[Migration("202611070001_LookupCounters")]
internal sealed class LookupCounters : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE TABLE catalog.off_lookup_daily(
          day date NOT NULL, outcome text NOT NULL CHECK(outcome ~ '^[a-z][a-z-]{0,31}$'), rule text NOT NULL DEFAULT '' CHECK(rule ~ '^[a-z0-9-]{0,40}$'),
          count bigint NOT NULL CHECK(count >= 0), PRIMARY KEY(day, outcome, rule));
        -- The API only adds counts (catalog.count_lookups); the worker's expiry job deletes old days (B23b security review).
        GRANT SELECT, DELETE ON catalog.off_lookup_daily TO fb_worker;
        CREATE FUNCTION catalog.count_lookups(p_days date[], p_outcomes text[], p_rules text[], p_counts bigint[]) RETURNS void
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
        BEGIN
          IF session_user <> 'fb_app' THEN RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'counter-role'; END IF;
          IF cardinality(p_days) > 1000 OR cardinality(p_days) IS DISTINCT FROM cardinality(p_outcomes) OR cardinality(p_days) IS DISTINCT FROM cardinality(p_rules)
             OR cardinality(p_days) IS DISTINCT FROM cardinality(p_counts) THEN RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'counter-shape'; END IF;
          INSERT INTO catalog.off_lookup_daily AS l(day, outcome, rule, count)
          SELECT t.d, t.o, t.r, sum(t.c) FROM unnest(p_days, p_outcomes, p_rules, p_counts) AS t(d, o, r, c) WHERE t.c > 0 GROUP BY 1, 2, 3
          ON CONFLICT(day, outcome, rule) DO UPDATE SET count = l.count + excluded.count;
        END;
        $f$;
        REVOKE ALL ON FUNCTION catalog.count_lookups(date[],text[],text[],bigint[]) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION catalog.count_lookups(date[],text[],text[],bigint[]) TO fb_app;
        GRANT USAGE ON SCHEMA catalog TO fb_admin;

        CREATE FUNCTION catalog.admin_releases()
        RETURNS TABLE(version integer, schema_version integer, foods integer, pack_bytes integer, sha_prefix text, is_current boolean)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT r.version, r.schema_version, (r.manifest->'files'->'foods.jsonl'->>'count')::integer, octet_length(r.pack), left(r.pack_sha256, 12),
                r.version IS NOT DISTINCT FROM (SELECT c.version FROM catalog.current_release c)
         FROM catalog.pack_releases r ORDER BY r.version DESC LIMIT 50;
        $f$;

        CREATE FUNCTION catalog.admin_off_cache(p_now timestamptz) RETURNS TABLE(products bigint, unknown_codes bigint, expiring_7d bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT count(*) FILTER (WHERE jsonb_typeof(o.data->'product') = 'object'),
                count(*) FILTER (WHERE jsonb_typeof(o.data->'product') IS DISTINCT FROM 'object'),
                count(*) FILTER (WHERE o.expires_at > p_now AND o.expires_at <= p_now + interval '7 days')
         FROM catalog.off_cache o;
        $f$;

        -- Outcome and rule codes only when they are in the caller's closed lists (B23b security review); anything else reads 'other'.
        CREATE FUNCTION catalog.admin_lookups(p_since date, p_outcomes text[], p_rules text[]) RETURNS TABLE(day date, outcome text, rule text, lookups bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT l.day, CASE WHEN l.outcome = ANY(p_outcomes) THEN l.outcome ELSE 'other' END,
                CASE WHEN l.rule = '' OR l.rule = ANY(p_rules) THEN l.rule ELSE 'other' END, sum(l.count)::bigint
         FROM catalog.off_lookup_daily l WHERE l.day >= p_since GROUP BY 1, 2, 3 ORDER BY 1 DESC, 2, 3;
        $f$;

        REVOKE ALL ON FUNCTION catalog.admin_releases(), catalog.admin_off_cache(timestamptz), catalog.admin_lookups(date,text[],text[]) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION catalog.admin_releases(), catalog.admin_off_cache(timestamptz), catalog.admin_lookups(date,text[],text[]) TO fb_admin;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => throw new NotSupportedException("Catalog rollback uses a verified recovery procedure.");
}
