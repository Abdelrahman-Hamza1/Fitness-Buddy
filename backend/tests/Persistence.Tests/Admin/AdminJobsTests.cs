using System.Net;
using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23 WP10 (T13, T14): Jobs & sync and Catalog render from a private database; retry, cancel and pause change the queue and
// write exactly one audit row in the same transaction; refusals change nothing and are audited as refused; a failed audit
// insert rolls the change back; a viewer can't change anything.
[Trait("Req", "AD-014")]
[Trait("Req", "AD-015")]
[Trait("Req", "AD-005")]
public sealed class AdminJobsTests(PostgresFixture postgres)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Fact]
    public async Task Jobs_and_catalog_windows_show_queues_failures_sync_and_releases()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        await MonitorSeed.CreateAsync(database);
        await ExecuteAsync(database, """
            INSERT INTO catalog.pack_releases(version,content_sha256,pack_sha256,schema_version,pack,manifest) VALUES
              (1,repeat('a',64),repeat('b',64),1,'\x0001'::bytea,'{"files":{"foods.jsonl":{"count":12}}}'),
              (2,repeat('c',64),repeat('d',64),1,'\x000102'::bytea,'{"files":{"foods.jsonl":{"count":15}}}');
            INSERT INTO catalog.current_release(version) VALUES(2);
            """);
        await using var admin = await StartAsync(database);
        using var owner = await SignInAsync(admin);
        var (status, jobs, _) = await owner.GetAsync("/admin/jobs");
        Assert.Equal(HttpStatusCode.OK, status);
        foreach (var expected in new[] { "test.monitor", "test.monitor-event", "InvalidOperationException", "TimeoutException", "Invalid payload", "diaryEntry", "Retry" })
        {
            Assert.Contains(expected, jobs, StringComparison.Ordinal);
        }
        var (catalogStatus, catalog, _) = await owner.GetAsync("/admin/catalog");
        Assert.Equal(HttpStatusCode.OK, catalogStatus);
        foreach (var expected in new[] { "current", "+3", "dddddddddddd", "1 cached products", "found-complete", "energy-macros-mismatch" })
        {
            Assert.Contains(expected, WebUtility.HtmlDecode(catalog), StringComparison.Ordinal);
        }
    }

    [Fact]
    public async Task Retry_cancel_and_pause_change_the_queue_with_one_audit_row_and_refusals_change_nothing()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        var seed = await MonitorSeed.CreateAsync(database);
        await using var admin = await StartAsync(database);
        using var owner = await SignInAsync(admin);
        await owner.GetAsync("/admin/jobs");

        Assert.EndsWith("result=retried", await PostAsync(owner, "/admin/jobs/retry", new() { ["kind"] = "job", ["id"] = seed.DeadJob.ToString() }));
        Assert.Equal("pending/0", await StateAsync(database, "jobs", seed.DeadJob));
        Assert.EndsWith("result=refused", await PostAsync(owner, "/admin/jobs/retry", new() { ["kind"] = "job", ["id"] = seed.DeadJob.ToString() }));
        Assert.EndsWith("result=retried", await PostAsync(owner, "/admin/jobs/retry", new() { ["kind"] = "event", ["id"] = seed.DeadEvent.ToString() }));
        Assert.Equal("pending/0", await StateAsync(database, "outbox", seed.DeadEvent));

        Assert.EndsWith("result=cancelled", await PostAsync(owner, "/admin/jobs/cancel", new() { ["id"] = seed.PendingJob.ToString() }));
        Assert.Equal("cancelled/0", await StateAsync(database, "jobs", seed.PendingJob));
        // A replayed form is a no-op, audited as such with the state it found (B23b review), never as a second change.
        Assert.EndsWith("result=unchanged", await PostAsync(owner, "/admin/jobs/cancel", new() { ["id"] = seed.PendingJob.ToString() }));
        Assert.EndsWith("result=refused", await PostAsync(owner, "/admin/jobs/cancel", new() { ["id"] = Guid.NewGuid().ToString() }));

        Assert.EndsWith("result=paused", await PostAsync(owner, "/admin/jobs/pause", new() { ["type"] = "test.monitor", ["paused"] = "1" }));
        Assert.Equal(1L, await ScalarAsync(database, "SELECT count(*) FROM ops.queue_pauses WHERE job_type='test.monitor' AND paused_by='owner'"));
        Assert.EndsWith("result=unchanged", await PostAsync(owner, "/admin/jobs/pause", new() { ["type"] = "test.monitor", ["paused"] = "1" }));
        Assert.EndsWith("result=refused", await PostAsync(owner, "/admin/jobs/pause", new() { ["type"] = "ops.cleanup", ["paused"] = "1" }));
        Assert.EndsWith("result=resumed", await PostAsync(owner, "/admin/jobs/pause", new() { ["type"] = "test.monitor", ["paused"] = "0" }));
        Assert.EndsWith("result=unchanged", await PostAsync(owner, "/admin/jobs/pause", new() { ["type"] = "test.monitor", ["paused"] = "0" }));
        Assert.Equal(0L, await ScalarAsync(database, "SELECT count(*) FROM ops.queue_pauses"));

        Assert.Equal(2L, await AuditAsync(database, "retry", "ok"));
        Assert.Equal(1L, await AuditAsync(database, "retry", "refused"));
        Assert.Equal(1L, await AuditAsync(database, "cancel", "ok"));
        Assert.Equal(1L, await AuditAsync(database, "cancel", "no-op"));
        Assert.Equal(1L, await AuditAsync(database, "cancel", "refused"));
        Assert.Equal(1L, await AuditAsync(database, "pause", "ok"));
        Assert.Equal(1L, await AuditAsync(database, "pause", "no-op"));
        Assert.Equal(1L, await AuditAsync(database, "pause", "refused"));
        Assert.Equal(1L, await AuditAsync(database, "resume", "ok"));
        Assert.Equal(1L, await AuditAsync(database, "resume", "no-op"));
        // Each row records the state actually found under the lock.
        Assert.Equal(1L, await ScalarAsync(database, $"SELECT count(*) FROM admin.audit_log WHERE action='retry' AND outcome='ok' AND target='job {seed.DeadJob}' AND before->>'state'='dead' AND after->>'state'='pending'"));
        Assert.Equal(1L, await ScalarAsync(database, $"SELECT count(*) FROM admin.audit_log WHERE action='retry' AND outcome='refused' AND before->>'state'='pending'"));
        Assert.Equal(1L, await ScalarAsync(database, $"SELECT count(*) FROM admin.audit_log WHERE action='cancel' AND outcome='ok' AND before->>'state'='pending' AND after->>'state'='cancelled'"));
        Assert.Equal(1L, await ScalarAsync(database, $"SELECT count(*) FROM admin.audit_log WHERE action='cancel' AND outcome='no-op' AND before->>'state'='cancelled'"));
        Assert.Equal(1L, await ScalarAsync(database, "SELECT count(*) FROM admin.audit_log WHERE action='pause' AND outcome='ok' AND (before->>'paused')::boolean=false AND (after->>'paused')::boolean"));
        Assert.Equal(1L, await ScalarAsync(database, "SELECT count(*) FROM admin.audit_log WHERE action='pause' AND outcome='no-op' AND (before->>'paused')::boolean"));
        Assert.Equal(1L, await ScalarAsync(database, "SELECT count(*) FROM admin.audit_log WHERE action='resume' AND outcome='no-op' AND (before->>'paused')::boolean=false"));
    }

    [Fact]
    public async Task A_failed_audit_insert_rolls_the_change_back_and_a_viewer_changes_nothing()
    {
        await using var database = await ConfigDatabase.CreateAsync(postgres);
        var seed = await MonitorSeed.CreateAsync(database);
        await ExecuteAsync(database, """
            CREATE FUNCTION admin.test_fail_audit() RETURNS trigger LANGUAGE plpgsql AS $f$ BEGIN RAISE EXCEPTION 'test-only audit failure'; END $f$;
            CREATE TRIGGER test_fail_audit BEFORE INSERT ON admin.audit_log FOR EACH ROW WHEN (NEW.area = 'jobs' AND NEW.outcome = 'ok') EXECUTE FUNCTION admin.test_fail_audit();
            """);
        await using var admin = await StartAsync(database);
        using var owner = await SignInAsync(admin);
        await owner.GetAsync("/admin/jobs");
        var (status, _, _) = await owner.PostAsync("/admin/jobs/retry", new Dictionary<string, string?> { ["kind"] = "job", ["id"] = seed.DeadJob.ToString() });
        Assert.Equal(HttpStatusCode.InternalServerError, status);
        Assert.Equal("dead/5", await StateAsync(database, "jobs", seed.DeadJob));

        using var reader = admin.NewBrowser();
        await reader.SignInAsync("sub-reader", "reader@example.invalid");
        var (page, body, _) = await reader.GetAsync("/admin/jobs");
        Assert.Equal(HttpStatusCode.OK, page);
        Assert.DoesNotContain("/admin/jobs/retry", body, StringComparison.Ordinal);
        foreach (var (path, form) in new (string, Dictionary<string, string?>)[]
        {
            ("/admin/jobs/retry", new() { ["kind"] = "job", ["id"] = seed.DeadJob.ToString() }),
            ("/admin/jobs/cancel", new() { ["id"] = seed.PendingJob.ToString() }),
            ("/admin/jobs/pause", new() { ["type"] = "test.monitor", ["paused"] = "1" }),
        })
        {
            Assert.Equal(HttpStatusCode.Forbidden, (await reader.PostAsync(path, form)).Status);
        }
        Assert.Equal("dead/5", await StateAsync(database, "jobs", seed.DeadJob));
        Assert.Equal("pending/0", await StateAsync(database, "jobs", seed.PendingJob));
        Assert.Equal(0L, await ScalarAsync(database, "SELECT count(*) FROM ops.queue_pauses"));
    }

    private static async Task<string> PostAsync(AdminApp.Browser browser, string path, Dictionary<string, string?> form)
    {
        var (status, _, response) = await browser.PostAsync(path, form);
        Assert.Equal(HttpStatusCode.Redirect, status);
        return response.Headers.Location!.OriginalString;
    }

    private async Task<AdminApp> StartAsync(ConfigDatabase database) =>
        await AdminApp.StartAsync(postgres, new Dictionary<string, string?> { ["ConnectionStrings:Admin"] = database.Admin });

    private static async Task<AdminApp.Browser> SignInAsync(AdminApp admin)
    {
        var browser = admin.NewBrowser();
        await browser.SignInAsync("sub-owner", "owner@example.invalid");
        await browser.GetAsync("/admin");
        return browser;
    }

    private static async Task<string> StateAsync(ConfigDatabase database, string table, Guid id)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.Migrator);
        await using var command = owner.CreateCommand($"SELECT state||'/'||attempts FROM ops.{table} WHERE id=$1");
        command.Parameters.AddWithValue(id);
        return (string)(await command.ExecuteScalarAsync(Ct))!;
    }

    private static Task<long> AuditAsync(ConfigDatabase database, string action, string outcome) =>
        ScalarAsync(database, $"SELECT count(*) FROM admin.audit_log WHERE area='jobs' AND action='{action}' AND outcome='{outcome}'");

    private static async Task<long> ScalarAsync(ConfigDatabase database, string sql)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.Migrator);
        await using var command = owner.CreateCommand(sql);
        return Convert.ToInt64(await command.ExecuteScalarAsync(Ct), System.Globalization.CultureInfo.InvariantCulture);
    }

    private static async Task ExecuteAsync(ConfigDatabase database, string sql)
    {
        await using var owner = DatabaseConfiguration.CreateSource(database.Migrator);
        await using var command = owner.CreateCommand(sql);
        await command.ExecuteNonQueryAsync(Ct);
    }
}
