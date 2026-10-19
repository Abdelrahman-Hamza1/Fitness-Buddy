# Sync operations (B05)

The phone remains the source of truth. Production sync requires a registered Identity session;
there is no spike-key bypass. Back up before deployment, apply expand-only migrations using the
migrator role, and start the API/worker without migrator credentials. The current app engine is A34.

Contract payload schemas live in `contracts/openapi/sync-entities.json`; `make gen` embeds the bounded
registry, and `make gen-check` verifies freshness. Additive entity/version schemas and generated-client
handoffs precede app uploads. Examples are synthetic in `contracts/testdata/sync/entity-payloads.json`.

## Dataset discovery and restore

A new client pulls from cursor0 without a dataset binding, then sends the returned dataset UUID.
Unbound or mismatched pushes return invalid/datasetMismatch and **must leave the exact outbox pending**.
A changed epoch requires a full pull/merge before re-uploading surviving local versions. Do not
manufacture newer HLCs for old rows and do not use push responses as pull cursors. Recovery status,
rows, pull cursor and epoch must commit together on the app (A34).

Ordinary restart and faithful data transfer retain the epoch. A fresh database receives a new one.
After restoring an older snapshot, keep API/worker traffic stopped and explicitly rotate before
serving it with the **migrate role only**:

```text
migrate --Sync:RotateDataset=true
```

Run that command through the existing private compose/operator environment, not with a database
password in shell history. A scratch restore check never opens the restored database to traffic.
Never infer a valid rollback recovery merely from an old cursor being below the current sequence.
B06 adds a separate deletion-safe recovery barrier: an epoch alone does not prevent restoring an
erased account. B14 preserves both recovery mechanisms when moving to production.

Owner-data reset/destructive restore remains an owner-gated operation. The B05 harness uses only
isolated synthetic databases. Do not reset the owner's phone server to exercise this procedure.

## Retention and clocks

Recurring user-scoped schedules persist in Ops, so idle owners are cleaned without a new push.
The migrate role seeds schedules for existing UserData; the API has no elevated cleanup enumeration.
History reads only expose the last30days; worker jobs purge old payloads in bounded batches and
backfill receipts for pre-B05 rows. Tombstone compaction uses server acceptance time. Its retained
HLC/deletion marker is necessary for an old offline phone, and its empty payload must not be parsed
as a live entity. Receipts contain fingerprints, not recoverable historical content; they and fences
remain user-owned until B06 erasure. Do not manually truncate either to save space.

An HLC over five minutes ahead is invalid/clockDrift, retaining the queued version. Correct the
phone clock/wait for admission; an explicit replacement must come from the app's single writer.
The backend never rewrites HLC identity. Nullable deletion instants use microsecond-or-coarser
precision; current phone times are milliseconds.

## Checks and measurements

`make check test`, `make gen-check`, `make contract-conformance`, `make sync-spike`, `make image-smoke`
and the isolated `make phone-server-smoke` are offline/provider-free. The real sync harness provisions
a synthetic email identity inside the shipped Production image; no Google/OpenAI live call is made.
Its10,000-row benchmark is Docker loopback on the laptop, not a phone/Wi-Fi result. A34 measures
actual SQLite restart and phone networking; B14 repeats production timing.

Sync metrics have fixed operation tags, counts and latency. Optional category-specific Debug logs
emit only operation/duration for the synthetic benchmark. Never enable ASP.NET request-body/query
logging, Npgsql statement/parameter tracing, or content-bearing schema diagnostics.
