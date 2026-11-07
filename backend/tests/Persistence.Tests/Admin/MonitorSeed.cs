using FitnessBuddy.BuildingBlocks.Persistence;

namespace FitnessBuddy.Persistence.Tests.Admin;

/// <summary>
/// Seeds a private database for the B23b monitor windows: one Google account full of canary content (diary, personal food,
/// chat, proposal, weigh-in and measurement payloads, its full email, Google subject and device id), one guest, sync counts with
/// rejects, AI usage, queue items and OFF data with a barcode canary. Every string the console must never show is in
/// <see cref="Canaries"/>.
/// </summary>
internal sealed class MonitorSeed
{
    public Guid Registered { get; } = Guid.CreateVersion7();
    public Guid Guest { get; } = Guid.CreateVersion7();
    public Guid Device { get; } = Guid.NewGuid();
    public Guid DeadJob { get; } = Guid.CreateVersion7();
    /// <summary>The account <see cref="SeedMetadataCanariesAsync"/> creates, whose device carries the app-version canary.</summary>
    public Guid Stranger { get; } = Guid.CreateVersion7();
    public Guid PendingJob { get; } = Guid.CreateVersion7();
    public Guid DeadEvent { get; } = Guid.CreateVersion7();
    public string Tag { get; } = Guid.NewGuid().ToString("N")[..8];
    public string Email => "Canary.Person." + Tag + "@Example.invalid";
    public string MaskedEmail => Email[..1] + "…@Example.invalid";
    public string Subject => "canary-subject-" + Tag;
    public string Barcode { get; } = "4006381" + Random.Shared.Next(100000, 999999).ToString(System.Globalization.CultureInfo.InvariantCulture);
    public List<string> Canaries { get; } = [];

    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    public static async Task<MonitorSeed> CreateAsync(ConfigDatabase database)
    {
        var seed = new MonitorSeed();
        await seed.SeedAsync(database);
        return seed;
    }

    private async Task SeedAsync(ConfigDatabase database)
    {
        const string number = "123.456789";
        Canaries.AddRange([Email, Email.ToLowerInvariant(), Subject, Device.ToString(), number, Barcode, "CANARY-JOB-PAYLOAD-" + Tag, "CANARY-EVENT-PAYLOAD-" + Tag]);
        await using var owner = DatabaseConfiguration.CreateSource(database.Migrator);
        await ExecuteAsync(owner, "INSERT INTO identity.users(id,anonymous,created_at) VALUES($1,false,now()-interval '3 days'),($2,true,now()-interval '1 day')", Registered, Guest);
        await ExecuteAsync(owner, "INSERT INTO identity.identities(provider,subject,user_id,email) VALUES('google',$1,$2,$3)", Subject, Registered, Email);
        await ExecuteAsync(owner, "INSERT INTO identity.devices(user_id,device_id,last_seen_at,app_version,platform) VALUES($1,$2,now(),'1.4.0','android')", Registered, Device);
        await ExecuteAsync(owner, "INSERT INTO identity.sessions(id,user_id,device_id,expires_at) VALUES(gen_random_uuid(),$1,$2,now()+interval '1 day')", Registered, Device);
        await ExecuteAsync(owner, """
            INSERT INTO userdata.sync_daily(user_id,day,pushes,pulls,changes_in,invalid_payload,last_push_at,last_pull_at) VALUES($1,current_date,3,2,7,2,now(),now())
            """, Registered);
        await ExecuteAsync(owner, """
            INSERT INTO ops.jobs(id,job_type,payload,created_at,available_at,attempts,state,last_error) VALUES
              ($1,'test.monitor',jsonb_build_object('secret',$3::text),now(),now(),5,'dead','InvalidOperationException'),
              ($2,'test.monitor',jsonb_build_object('secret',$3::text),now(),now()+interval '1 hour',0,'pending',NULL)
            """, DeadJob, PendingJob, "CANARY-JOB-PAYLOAD-" + Tag);
        await ExecuteAsync(owner, """
            INSERT INTO ops.outbox(id,event_type,payload,created_at,available_at,attempts,state,last_error)
            VALUES($1,'test.monitor-event',jsonb_build_object('secret',$2::text),now(),now(),5,'dead','TimeoutException')
            """, DeadEvent, "CANARY-EVENT-PAYLOAD-" + Tag);
        await ExecuteAsync(owner, """
            INSERT INTO catalog.off_cache(code,data,expires_at)
            VALUES($1,jsonb_build_object('v',1,'product',jsonb_build_object('code',$1::text,'name',$2::text)),now()+interval '3 days')
            """, Barcode, "CANARY-PRODUCT-" + Tag);
        await ExecuteAsync(owner, "INSERT INTO catalog.off_lookup_daily(day,outcome,rule,count) VALUES(current_date,'found-complete','',4),(current_date,'sanity-warn','energy-macros-mismatch',1)");
        Canaries.Add("CANARY-PRODUCT-" + Tag);

        await using var app = DatabaseConfiguration.CreateSource(database.App);
        await using var session = new DatabaseSession();
        await session.BeginAsync(app, Registered, Ct);
        (string Entity, string Field)[] content =
        [
            ("diaryEntry", "name"), ("personalFood", "name"), ("chatMessage", "text"), ("proposal", "summary"), ("weighIn", "note"), ("measurement", "note"),
        ];
        var counter = 0;
        foreach (var (entity, field) in content)
        {
            var canary = "CANARY-" + entity.ToUpperInvariant() + "-" + Tag;
            Canaries.Add(canary);
            await using var insert = session.Command("""
                INSERT INTO userdata.documents(user_id,entity,id,schema_version,hlc,device_id,payload)
                VALUES($1,$2,$3,1,$4,$5,jsonb_build_object($6::text,$7::text,'value',$8::numeric))
                """);
            insert.Parameters.AddWithValue(Registered);
            insert.Parameters.AddWithValue(entity);
            insert.Parameters.AddWithValue(Guid.NewGuid());
            insert.Parameters.AddWithValue("1760351234567-" + (++counter).ToString("D5", System.Globalization.CultureInfo.InvariantCulture) + "-" + Device);
            insert.Parameters.AddWithValue(Device);
            insert.Parameters.AddWithValue(field);
            insert.Parameters.AddWithValue(canary);
            insert.Parameters.AddWithValue(decimal.Parse(number, System.Globalization.CultureInfo.InvariantCulture));
            await insert.ExecuteNonQueryAsync(Ct);
        }
        await using (var usage = session.Command("INSERT INTO usage.daily(user_id,day,model,calls,messages,input_tokens,cached_input_tokens,output_tokens,estimated_usd) VALUES($1,current_date,'test-model',4,3,10,0,10,0.25)"))
        {
            usage.Parameters.AddWithValue(Registered);
            await usage.ExecuteNonQueryAsync(Ct);
        }
        await session.CommitAsync(Ct);
    }

    /// <summary>
    /// B23b security review: metadata a compromised API (or any queue writer) controls, each carrying a canary: queue and
    /// in-progress types, error types, a worker's role and build, a 5xx role, lookup outcome and rule codes, a sync entity code,
    /// an app version and an email domain. The console must show none of them (the reads map them to <c>other</c> or omit them).
    /// Not part of <see cref="CreateAsync"/>: it adds failures, a heartbeat and an account the other windows' tests don't expect.
    /// </summary>
    public async Task SeedMetadataCanariesAsync(ConfigDatabase database)
    {
        var tag = Tag;
        string[] metadata = ["canary.meta-job-" + tag, "canary.meta-event-" + tag, "CanaryMeta" + tag + "Exception", "canary meta error " + tag,
            "canaryrole", "canary-build-" + tag, "canary.meta-busy-" + tag, "canaryerrs", "canary-outcome", "canary-rule-" + tag, "canaryEntity" + tag,
            "canaryver" + tag, "canary domain " + tag];
        Canaries.AddRange(metadata);
        await using var owner = DatabaseConfiguration.CreateSource(database.Migrator);
        await ExecuteAsync(owner, "INSERT INTO ops.jobs(id,job_type,payload,created_at,available_at,attempts,state,last_error) VALUES(gen_random_uuid(),$1,'{}',now(),now(),5,'dead',$2)",
            metadata[0], metadata[2]);
        await ExecuteAsync(owner, "INSERT INTO ops.outbox(id,event_type,payload,created_at,available_at,attempts,state,last_error) VALUES(gen_random_uuid(),$1,'{}',now(),now(),5,'dead',$2)",
            metadata[1], metadata[3]);
        await ExecuteAsync(owner, "INSERT INTO ops.worker_heartbeats(instance,role,build,started_at,last_beat_at,busy_type,busy_since) VALUES(gen_random_uuid(),$1,$2,now(),now(),$3,now())",
            metadata[4], metadata[5], metadata[6]);
        await ExecuteAsync(owner, "INSERT INTO ops.http_errors_hourly(hour,role,status,count) VALUES(date_trunc('hour',now()),$1,500,1)", metadata[7]);
        await ExecuteAsync(owner, "INSERT INTO catalog.off_lookup_daily(day,outcome,rule,count) VALUES(current_date,$1,$2,2)", metadata[8], metadata[9]);
        var stranger = Stranger;
        await ExecuteAsync(owner, "INSERT INTO identity.users(id,anonymous,created_at) VALUES($1,false,now())", stranger);
        await ExecuteAsync(owner, "INSERT INTO identity.identities(provider,subject,user_id,email) VALUES('google',$1,$2,$3)", "canary-meta-subject-" + tag, stranger, "z@" + metadata[12]);
        await ExecuteAsync(owner, "INSERT INTO identity.devices(user_id,device_id,last_seen_at,app_version,platform) VALUES($1,$2,now(),$3,'android')", stranger, Guid.NewGuid(), metadata[11]);
        Canaries.Add("canary-meta-subject-" + tag);
        await using var app = DatabaseConfiguration.CreateSource(database.App);
        await using var session = new DatabaseSession();
        await session.BeginAsync(app, Registered, Ct);
        await using (var insert = session.Command("INSERT INTO userdata.documents(user_id,entity,id,schema_version,hlc,device_id,payload) VALUES($1,$2,$3,1,$4,$5,'{}'::jsonb)"))
        {
            insert.Parameters.AddWithValue(Registered);
            insert.Parameters.AddWithValue(metadata[10]);
            insert.Parameters.AddWithValue(Guid.NewGuid());
            insert.Parameters.AddWithValue("1760351234567-00099-" + Device);
            insert.Parameters.AddWithValue(Device);
            await insert.ExecuteNonQueryAsync(Ct);
        }
        await session.CommitAsync(Ct);
    }

    private static async Task ExecuteAsync(Npgsql.NpgsqlDataSource source, string sql, params object[] parameters)
    {
        await using var command = source.CreateCommand(sql);
        foreach (var parameter in parameters) { command.Parameters.AddWithValue(parameter); }
        await command.ExecuteNonQueryAsync(Ct);
    }
}
