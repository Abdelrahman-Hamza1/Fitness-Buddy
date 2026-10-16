using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.BuildingBlocks.Persistence.Migrations;

[DbContext(typeof(OpsDbContext))]
[Migration("202610160001_InitialOps")]
internal sealed class InitialOps : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("""
            CREATE EXTENSION IF NOT EXISTS pg_trgm;
            REVOKE ALL ON SCHEMA ops FROM PUBLIC;
            GRANT USAGE ON SCHEMA ops TO fb_app;
            CREATE TABLE ops.outbox (
                id uuid PRIMARY KEY, event_type varchar(200) NOT NULL, payload jsonb NOT NULL,
                created_at timestamptz NOT NULL, available_at timestamptz NOT NULL,
                attempts integer NOT NULL DEFAULT 0, state varchar(16) NOT NULL DEFAULT 'pending',
                completed_at timestamptz, last_error varchar(200)
            );
            CREATE INDEX outbox_pending ON ops.outbox(available_at, id) WHERE state = 'pending';
            CREATE TABLE ops.processed_messages (
                message_id uuid NOT NULL, handler varchar(200) NOT NULL, processed_at timestamptz NOT NULL,
                PRIMARY KEY(message_id, handler)
            );
            CREATE TABLE ops.jobs (
                id uuid PRIMARY KEY, job_type varchar(200) NOT NULL, payload jsonb NOT NULL,
                created_at timestamptz NOT NULL, available_at timestamptz NOT NULL,
                attempts integer NOT NULL DEFAULT 0, state varchar(16) NOT NULL DEFAULT 'pending',
                completed_at timestamptz, last_error varchar(200), dedup_key varchar(300) UNIQUE
            );
            CREATE INDEX jobs_pending ON ops.jobs(available_at, id) WHERE state = 'pending';
            CREATE TABLE ops.schedules (
                name varchar(200) PRIMARY KEY, cron varchar(100) NOT NULL, job_type varchar(200) NOT NULL,
                payload jsonb NOT NULL, next_due timestamptz NOT NULL
            );
            CREATE TABLE ops.idempotency (
                scope_hash varchar(64) NOT NULL, key_hash varchar(64) NOT NULL, fingerprint varchar(64) NOT NULL,
                status integer NOT NULL, content_type text, body bytea NOT NULL, headers jsonb NOT NULL,
                created_at timestamptz NOT NULL, expires_at timestamptz NOT NULL,
                PRIMARY KEY(scope_hash, key_hash)
            );
            CREATE INDEX idempotency_expiry ON ops.idempotency(expires_at);
            GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ops TO fb_app;
            REVOKE ALL ON ops.__ef_migrations_history FROM fb_app;
            """);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("DROP TABLE ops.idempotency, ops.schedules, ops.jobs, ops.processed_messages, ops.outbox;");
    }
}
