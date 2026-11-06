using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace FitnessBuddy.BuildingBlocks.Persistence.Migrations;

/// <summary>
/// B23 WP8 (expand only): what the console's Overview and Jobs &amp; sync windows read. Worker heartbeats with the job type in
/// progress, hourly server-error counts, paused job types (the worker skips them), and the job state <c>cancelled</c>.
/// The <c>admin_*</c> functions are content-free (ids, closed codes, counts, timestamps; never a payload or a user id) and
/// only the console login can run them (owner O1, TD-118). The three write functions are the console's only changes here.
/// Every text a writer controls (queue and in-progress types, error types, worker role and build, 5xx role) is returned only
/// when it is in the caller's allowed list or has the version shape; anything else reads <c>other</c> (B23b security review).
/// </summary>
[DbContext(typeof(OpsDbContext))]
[Migration("202611070001_AdminOps")]
internal sealed class AdminOps : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        CREATE TABLE ops.worker_heartbeats(
          instance uuid PRIMARY KEY, role text NOT NULL CHECK(role ~ '^[a-z]{1,16}$'), build text NOT NULL CHECK(length(build) <= 64),
          started_at timestamptz NOT NULL, last_beat_at timestamptz NOT NULL, busy_kind text CHECK(busy_kind IN ('job','event')), busy_type varchar(200),
          busy_since timestamptz);
        CREATE INDEX worker_heartbeats_beat ON ops.worker_heartbeats(last_beat_at);
        CREATE TABLE ops.http_errors_hourly(
          hour timestamptz NOT NULL, role text NOT NULL CHECK(role ~ '^[a-z]{1,16}$'), status integer NOT NULL CHECK(status BETWEEN 500 AND 599),
          count bigint NOT NULL CHECK(count >= 0), PRIMARY KEY(hour, role, status));
        CREATE TABLE ops.queue_pauses(job_type varchar(200) PRIMARY KEY, paused_at timestamptz NOT NULL, paused_by text NOT NULL CHECK(length(paused_by) <= 64));
        CREATE INDEX jobs_dead ON ops.jobs(created_at) WHERE state IN ('dead','cancelled');
        CREATE INDEX outbox_dead ON ops.outbox(created_at) WHERE state = 'dead';
        -- Only the worker login writes heartbeats and expires the counters (B23b security review): a compromised API can't fake
        -- a healthy worker or erase recorded server errors. The API only adds to its own counters, through ops.count_http_errors.
        GRANT SELECT, INSERT, UPDATE, DELETE ON ops.worker_heartbeats TO fb_worker;
        GRANT SELECT, DELETE ON ops.http_errors_hourly TO fb_worker;
        GRANT SELECT ON ops.queue_pauses TO fb_app;
        GRANT USAGE ON SCHEMA ops TO fb_admin;

        -- Adds server-error counts for the calling login's role (fb_app: api, fb_worker: worker); counts only grow.
        CREATE FUNCTION ops.count_http_errors(p_hours timestamptz[], p_statuses integer[], p_counts bigint[]) RETURNS void
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
        DECLARE v_role text := CASE session_user WHEN 'fb_app' THEN 'api' WHEN 'fb_worker' THEN 'worker' END;
        BEGIN
          IF v_role IS NULL THEN RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'counter-role'; END IF;
          IF cardinality(p_hours) > 1000 OR cardinality(p_hours) IS DISTINCT FROM cardinality(p_statuses)
             OR cardinality(p_hours) IS DISTINCT FROM cardinality(p_counts) THEN RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'counter-shape'; END IF;
          INSERT INTO ops.http_errors_hourly(hour, role, status, count)
          SELECT date_trunc('hour', t.h), v_role, t.s, sum(t.c) FROM unnest(p_hours, p_statuses, p_counts) AS t(h, s, c)
          WHERE t.c > 0 GROUP BY 1, 3
          ON CONFLICT(hour, role, status) DO UPDATE SET count = ops.http_errors_hourly.count + excluded.count;
        END;
        $f$;
        REVOKE ALL ON FUNCTION ops.count_http_errors(timestamptz[],integer[],bigint[]) FROM PUBLIC;
        GRANT EXECUTE ON FUNCTION ops.count_http_errors(timestamptz[],integer[],bigint[]) TO fb_app;

        CREATE FUNCTION ops.admin_queues(p_now timestamptz, p_job_types text[], p_event_types text[])
        RETURNS TABLE(kind text, type text, pending bigint, due bigint, done_24h bigint, dead bigint, cancelled bigint, oldest_due_at timestamptz, paused boolean)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         WITH q AS (
           SELECT 'job'::text AS kind, CASE WHEN j.job_type = ANY(p_job_types) THEN j.job_type::text ELSE 'other' END AS type,
                  j.state, j.available_at, j.completed_at FROM ops.jobs j
           UNION ALL
           SELECT 'event'::text, CASE WHEN o.event_type = ANY(p_event_types) THEN o.event_type::text ELSE 'other' END,
                  o.state, o.available_at, o.completed_at FROM ops.outbox o)
         SELECT q.kind, q.type,
                count(*) FILTER (WHERE q.state = 'pending'),
                count(*) FILTER (WHERE q.state = 'pending' AND q.available_at <= p_now),
                count(*) FILTER (WHERE q.state = 'done' AND q.completed_at > p_now - interval '24 hours'),
                count(*) FILTER (WHERE q.state = 'dead'),
                count(*) FILTER (WHERE q.state = 'cancelled'),
                min(q.available_at) FILTER (WHERE q.state = 'pending' AND q.available_at <= p_now),
                q.kind = 'job' AND EXISTS(SELECT 1 FROM ops.queue_pauses p WHERE p.job_type = q.type)
         FROM q GROUP BY q.kind, q.type
         UNION ALL
         SELECT 'job', p.job_type::text, 0, 0, 0, 0, 0, NULL, true FROM ops.queue_pauses p
         WHERE p.job_type = ANY(p_job_types) AND NOT EXISTS(SELECT 1 FROM ops.jobs j WHERE j.job_type = p.job_type)
         ORDER BY 1, 2;
        $f$;

        CREATE FUNCTION ops.admin_failed(p_limit integer, p_job_types text[], p_event_types text[], p_error_types text[])
        RETURNS TABLE(id uuid, kind text, type text, state text, attempts integer, error_type text, created_at timestamptz)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT f.id, f.kind,
                CASE WHEN f.type = ANY(CASE f.kind WHEN 'job' THEN p_job_types ELSE p_event_types END) THEN f.type ELSE 'other' END,
                f.state, f.attempts,
                CASE WHEN f.last_error IS NULL THEN NULL WHEN f.last_error = ANY(p_error_types) THEN f.last_error ELSE 'other' END,
                f.created_at
         FROM (
           SELECT j.id, 'job'::text AS kind, j.job_type::text AS type, j.state::text AS state, j.attempts, j.last_error::text AS last_error, j.created_at
           FROM ops.jobs j WHERE j.state IN ('dead','cancelled')
           UNION ALL
           SELECT o.id, 'event'::text, o.event_type::text, o.state::text, o.attempts, o.last_error::text, o.created_at FROM ops.outbox o WHERE o.state = 'dead'
         ) f
         ORDER BY f.state = 'dead' DESC, f.created_at DESC LIMIT least(greatest(p_limit, 1), 200);
        $f$;

        -- The build is the informational version (MAJOR.MINOR.PATCH, optionally +commit hash) or 'unknown'.
        CREATE FUNCTION ops.admin_heartbeats(p_job_types text[], p_event_types text[])
        RETURNS TABLE(instance uuid, role text, build text, started_at timestamptz, last_beat_at timestamptz, busy_kind text, busy_type text, busy_since timestamptz)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT h.instance, CASE WHEN h.role = 'worker' THEN 'worker' ELSE 'other' END,
                CASE WHEN h.build ~ '^[0-9]{1,6}\.[0-9]{1,6}\.[0-9]{1,6}(\+[0-9a-f]{7,40})?$' OR h.build = 'unknown' THEN h.build ELSE 'other' END,
                h.started_at, h.last_beat_at, h.busy_kind,
                CASE WHEN h.busy_type IS NULL THEN NULL
                     WHEN h.busy_type = ANY(CASE h.busy_kind WHEN 'job' THEN p_job_types WHEN 'event' THEN p_event_types END) THEN h.busy_type::text
                     ELSE 'other' END,
                h.busy_since
         FROM ops.worker_heartbeats h ORDER BY h.last_beat_at DESC LIMIT 50;
        $f$;

        CREATE FUNCTION ops.admin_http_errors(p_since timestamptz)
        RETURNS TABLE(role text, status integer, errors bigint)
        LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
         SELECT CASE WHEN e.role IN ('api', 'worker') THEN e.role ELSE 'other' END, e.status, sum(e.count)::bigint
         FROM ops.http_errors_hourly e WHERE e.hour >= date_trunc('hour', p_since) GROUP BY 1, 2 ORDER BY 1, 2;
        $f$;

        -- The console's only queue changes. Each locks its row (a row a worker holds is skipped, never waited for: 'busy') and
        -- returns what actually happened with the state it found: 'changed', 'unchanged' (already so), 'refused' (not in a state
        -- the change applies to), 'busy' or 'missing'. The console audits exactly that (B23b review).
        CREATE FUNCTION ops.admin_retry(p_kind text, p_id uuid, p_now timestamptz) RETURNS TABLE(outcome text, previous text)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
        DECLARE v_state text;
        BEGIN
          IF p_kind = 'job' THEN
            SELECT j.state::text INTO v_state FROM ops.jobs j WHERE j.id = p_id FOR UPDATE SKIP LOCKED;
            IF NOT FOUND THEN
              RETURN QUERY SELECT CASE WHEN EXISTS(SELECT 1 FROM ops.jobs j WHERE j.id = p_id) THEN 'busy' ELSE 'missing' END, NULL::text; RETURN;
            END IF;
            IF v_state <> 'dead' THEN RETURN QUERY SELECT 'refused'::text, v_state; RETURN; END IF;
            UPDATE ops.jobs SET state='pending', attempts=0, available_at=p_now, last_error=NULL, completed_at=NULL WHERE id = p_id;
          ELSIF p_kind = 'event' THEN
            SELECT o.state::text INTO v_state FROM ops.outbox o WHERE o.id = p_id FOR UPDATE SKIP LOCKED;
            IF NOT FOUND THEN
              RETURN QUERY SELECT CASE WHEN EXISTS(SELECT 1 FROM ops.outbox o WHERE o.id = p_id) THEN 'busy' ELSE 'missing' END, NULL::text; RETURN;
            END IF;
            IF v_state <> 'dead' THEN RETURN QUERY SELECT 'refused'::text, v_state; RETURN; END IF;
            UPDATE ops.outbox SET state='pending', attempts=0, available_at=p_now, last_error=NULL, completed_at=NULL WHERE id = p_id;
          ELSE
            RETURN QUERY SELECT 'refused'::text, NULL::text; RETURN;
          END IF;
          RETURN QUERY SELECT 'changed'::text, v_state;
        END;
        $f$;

        CREATE FUNCTION ops.admin_cancel(p_id uuid, p_now timestamptz) RETURNS TABLE(outcome text, previous text)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
        DECLARE v_state text;
        BEGIN
          SELECT j.state::text INTO v_state FROM ops.jobs j WHERE j.id = p_id FOR UPDATE SKIP LOCKED;
          IF NOT FOUND THEN
            RETURN QUERY SELECT CASE WHEN EXISTS(SELECT 1 FROM ops.jobs j WHERE j.id = p_id) THEN 'busy' ELSE 'missing' END, NULL::text; RETURN;
          END IF;
          IF v_state = 'cancelled' THEN RETURN QUERY SELECT 'unchanged'::text, v_state; RETURN; END IF;
          IF v_state NOT IN ('pending', 'dead') THEN RETURN QUERY SELECT 'refused'::text, v_state; RETURN; END IF;
          UPDATE ops.jobs SET state='cancelled', completed_at=p_now WHERE id = p_id;
          RETURN QUERY SELECT 'changed'::text, v_state;
        END;
        $f$;

        -- ops.cleanup is never paused: it is what expires everything else. previous is 'paused' or 'running'.
        CREATE FUNCTION ops.admin_set_paused(p_type text, p_paused boolean, p_actor text, p_now timestamptz) RETURNS TABLE(outcome text, previous text)
        LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $f$
        DECLARE v_done boolean;
        BEGIN
          IF p_type IS NULL OR p_type = 'ops.cleanup' OR p_type !~ '^[a-z][a-z0-9._-]{0,199}$' THEN RETURN QUERY SELECT 'refused'::text, NULL::text; RETURN; END IF;
          IF p_paused THEN
            INSERT INTO ops.queue_pauses(job_type, paused_at, paused_by) VALUES(p_type, p_now, p_actor) ON CONFLICT(job_type) DO NOTHING;
            v_done := FOUND;
            RETURN QUERY SELECT CASE WHEN v_done THEN 'changed' ELSE 'unchanged' END, CASE WHEN v_done THEN 'running' ELSE 'paused' END;
          ELSE
            DELETE FROM ops.queue_pauses WHERE job_type = p_type;
            v_done := FOUND;
            RETURN QUERY SELECT CASE WHEN v_done THEN 'changed' ELSE 'unchanged' END, CASE WHEN v_done THEN 'paused' ELSE 'running' END;
          END IF;
        END;
        $f$;

        DO $body$ DECLARE f text; BEGIN
         FOREACH f IN ARRAY ARRAY['ops.admin_queues(timestamptz,text[],text[])','ops.admin_failed(integer,text[],text[],text[])',
                                  'ops.admin_heartbeats(text[],text[])','ops.admin_http_errors(timestamptz)',
                                  'ops.admin_retry(text,uuid,timestamptz)','ops.admin_cancel(uuid,timestamptz)','ops.admin_set_paused(text,boolean,text,timestamptz)'] LOOP
          EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', f);
          EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO fb_admin', f);
         END LOOP;
        END $body$;
        """);

    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.Sql("""
        DROP FUNCTION ops.count_http_errors(timestamptz[],integer[],bigint[]);
        DROP FUNCTION ops.admin_queues(timestamptz,text[],text[]), ops.admin_failed(integer,text[],text[],text[]), ops.admin_heartbeats(text[],text[]),
          ops.admin_http_errors(timestamptz),
          ops.admin_retry(text,uuid,timestamptz), ops.admin_cancel(uuid,timestamptz), ops.admin_set_paused(text,boolean,text,timestamptz);
        DROP INDEX ops.jobs_dead, ops.outbox_dead;
        DROP TABLE ops.worker_heartbeats, ops.http_errors_hourly, ops.queue_pauses;
        """);
}
