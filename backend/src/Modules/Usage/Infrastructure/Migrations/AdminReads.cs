using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.Modules.Usage.Infrastructure.Migrations;

/// <summary>
/// B23 WP8: content-free AI usage totals for the console (AD-010 spend, AD-011 AI uses). The owner gets a SELECT-only policy
/// so the definer functions can aggregate across accounts; only the console login can run them (owner O1, TD-118).
/// </summary>
[DbContext(typeof(UsageContext))]
[Migration("202611070001_AdminReads")]
internal sealed class AdminReads : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE POLICY admin_reads ON usage.daily FOR SELECT TO fb_migrator USING(true);
        GRANT USAGE ON SCHEMA usage TO fb_admin;
        CREATE FUNCTION usage.admin_spend(p_from date, p_to date) RETURNS TABLE(calls bigint, messages bigint, estimated_usd numeric)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT coalesce(sum(d.calls), 0)::bigint, coalesce(sum(d.messages), 0)::bigint, coalesce(sum(d.estimated_usd), 0)
         FROM usage.daily d WHERE d.day BETWEEN p_from AND p_to;
        $f$;
        CREATE FUNCTION usage.admin_uses(p_users uuid[], p_since date) RETURNS TABLE(user_id uuid, calls bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT d.user_id, sum(d.calls)::bigint FROM usage.daily d WHERE d.user_id = ANY(p_users[1:200]) AND d.day >= p_since GROUP BY d.user_id;
        $f$;
        REVOKE ALL ON FUNCTION usage.admin_spend(date,date), usage.admin_uses(uuid[],date) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION usage.admin_spend(date,date), usage.admin_uses(uuid[],date) TO fb_admin;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        DROP FUNCTION usage.admin_spend(date,date), usage.admin_uses(uuid[],date);
        DROP POLICY admin_reads ON usage.daily;
        """);
}
