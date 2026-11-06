using System.Net;
using FitnessBuddy.BuildingBlocks.Persistence;
using FitnessBuddy.Modules.Admin.Domain;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23 WP3 (AD-016): the audit window filters, pages and exports CSV safely; the export itself is audited.
[Trait("Req", "AD-016")]
[Trait("Req", "AD-005")]
public sealed class AuditLogTests(PostgresFixture postgres)
{
    [Theory]
    [InlineData("plain", "plain")]
    [InlineData("=HYPERLINK(\"x\")", "\"'=HYPERLINK(\"\"x\"\")\"")]
    [InlineData("+1", "'+1")]
    [InlineData("-1", "'-1")]
    [InlineData("@SUM(A1)", "'@SUM(A1)")]
    [InlineData("a,b", "\"a,b\"")]
    [InlineData("line\nbreak", "\"line\nbreak\"")]
    [InlineData("", "")]
    public void Csv_fields_are_quoted_and_never_start_a_formula(string value, string expected) =>
        Assert.Equal(expected, AuditCsv.Field(value));

    [Fact]
    public async Task A_viewer_filters_pages_and_exports_the_log_and_the_export_is_audited()
    {
        var actor = "t-" + Guid.NewGuid().ToString("N")[..10];
        await using (var source = DatabaseConfiguration.CreateSource(postgres.AdminConnection))
        {
            for (var i = 0; i < 55; i++)
            {
                await using var insert = source.CreateCommand("INSERT INTO admin.audit_log(occurred_at,actor,area,action,outcome,reason) VALUES(now(),$1,'config','publish','ok',$2)");
                insert.Parameters.AddWithValue(actor);
                insert.Parameters.AddWithValue(i == 54 ? "=cmd|' /C calc'!A0" : "reason " + i);
                await insert.ExecuteNonQueryAsync(TestContext.Current.CancellationToken);
            }
        }
        await using var admin = await AdminApp.StartAsync(postgres);
        using var viewer = admin.NewBrowser();
        await viewer.SignInAsync("sub-reader", "reader@example.invalid");

        var (status, body, _) = await viewer.GetAsync("/admin/audit?actor=" + actor);
        Assert.Equal(HttpStatusCode.OK, status);
        Assert.Contains("reason 53", body, StringComparison.Ordinal);
        Assert.DoesNotContain("reason 3<", body, StringComparison.Ordinal);
        Assert.Contains("cursor=", body, StringComparison.Ordinal);
        Assert.DoesNotContain("sub-reader", body, StringComparison.Ordinal);

        var (filtered, filteredBody, _) = await viewer.GetAsync("/admin/audit?actor=" + actor + "&area=auth");
        Assert.Equal(HttpStatusCode.OK, filtered);
        Assert.Contains("No entries.", filteredBody, StringComparison.Ordinal);

        var (invalid, invalidBody, _) = await viewer.GetAsync("/admin/audit?actor=DROP%20TABLE&from=yesterday");
        Assert.Equal(HttpStatusCode.OK, invalid);
        Assert.Contains("ignored", invalidBody, StringComparison.Ordinal);

        var (exported, csv, response) = await viewer.GetAsync("/admin/audit/export.csv?actor=" + actor);
        Assert.Equal(HttpStatusCode.OK, exported);
        Assert.StartsWith("text/csv", response.Content.Headers.ContentType!.ToString(), StringComparison.Ordinal);
        Assert.StartsWith("id,occurred_at_utc,actor,area,action,target,outcome,reason,before,after\r\n", csv, StringComparison.Ordinal);
        Assert.Equal(56, csv.Split("\r\n", StringSplitOptions.RemoveEmptyEntries).Length);
        Assert.Contains(",'=cmd|' /C calc'!A0,", csv, StringComparison.Ordinal);

        await using var owner = DatabaseConfiguration.CreateSource(postgres.MigratorConnection);
        await using var count = owner.CreateCommand("SELECT count(*) FROM admin.audit_log WHERE actor='reader' AND area='audit' AND action='export' AND target='55 rows'");
        Assert.True((long)(await count.ExecuteScalarAsync(TestContext.Current.CancellationToken))! >= 1);
    }
}
