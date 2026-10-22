# Buddy

B08 exposes `POST /v1/buddy/interpret` to live authenticated sessions, including guests. It returns typed proposal **inputs**, never writes to the diary or computes nutrition totals. The app's A21 ProposalEngine applies policy and A23 owns pending messages.

The pipeline validates bounded context, durably reserves a paid send, calls GPT-6 Luna, validates the closed `interpret-v1` schema and semantics, resolves personal/catalog foods, and saves the result for replay. Native Responses uses low effort, 1,600 output tokens, a 20-second deadline, `store:false`, no tools, provider fallback or SDK retries. Invalid output gets at most one separately reserved repair using a fixed instruction; invalid twice returns typed Clarify. Refusal, timeout and provider failure return pending 503. Rerank is disabled.

Personal names/aliases are resolved before the catalog; returned food facts and serving data come from those sources. Distinct alternatives and dimension options include the facts needed for offline taps. State mismatches retain both the source state and a stated-state dimension for client yield conversion. Only an unmatched item can expose a physically bounded, explicitly badged AI nutrient range **per 100 g**. An unmatched item without a valid range returns Clarify. No model nutrients replace a real match.

## Replay, limits and deletion

`requestId` must be a UUIDv7 equal to `Idempotency-Key`. Freeze the complete original request (including `now` and context) when queueing a message; retries with changed input return 409. The app must retain that snapshot across reconnects. Concurrent copies and completed replays make no extra provider calls.

The Buddy ledger commits its claim and Usage reservation **before** dispatch; Postgres cannot roll back a remote charge. A crash, cancellation or unknown provider result therefore leaves the key pending for the 24-hour replay window. No automatic retry of an ambiguous send occurs in that window. After expiry the key may be used again. This is conservative charge protection, not exactly-once remote execution. Pre-claim validation, disabled-service and concurrency rejection do not reserve a key. An initial quota denial is 429 with no provider call; a denied repair is pending 503 because its first call already happened.

Only hashes, attempt state and the replay response are persisted; no request/context text. Expired responses are inaccessible at 24 h and removed at the next five-minute user cleanup sweep. Usage retains content-free daily aggregates for 90 days. Both schemas force RLS and participate in atomic account erasure. Each dispatch/accounting/completion transaction rechecks live session and recovery generation. No database lock spans provider I/O; an old in-flight response cannot recreate deleted data.

Physical sends and logical messages are separate counters: a repair reserves another send, but does not count as another message. Replay increments neither. Token/cost accounting uses the dispatch UTC day, including across midnight. Missing provider usage or a crashed response cannot be reconstructed; estimated USD is not an invoice. The rate snapshot remains B02's dated 2026-10-16 standard short-context rates.

## Configuration

Buddy is disabled by default and loads no key until explicitly enabled. Configure the private server externally:

```json
{
  "Buddy": {
    "Enabled": true,
    "ApiKeyFile": "/run/secrets/openai-api-key",
    "MaxOutputTokens": 1600,
    "TimeoutSeconds": 20,
    "Concurrency": 2,
    "RegisteredDailyCalls": 100,
    "GuestDailyCalls": 30
  }
}
```

For the existing private phone server, `python3 tools/scripts/phone-server.py configure-buddy`
prepares an API-only read-only mount from the existing external owner key. The worker/migrator
receive no OpenAI key. It takes effect on the next CI-verified main-image deployment (`up`).
A plain server stays disabled until configured; no paid probe is part of configuration/deploy.

The API key file must be private, absolute and not a symlink. Mount it read-only outside the repo; never put its value in app settings, the app, argv or logs. The fixed OpenAI transport does not follow redirects. The concurrency bound is per process; daily operational safety ceilings are shared in Postgres. These are not R3 commercial allowances. Context forwarded to the provider excludes IDs, account/device fields and food nutrients. Logs/traces contain only model/version, outcome, timing, tokens and estimated cost. `store:false` does not claim provider zero retention (R1/R2 terms remain as accepted).

## Verification

`make check test eval` is offline: v0 SDK replay stays unchanged, while Persistence.Tests starts a real authenticated HTTP API, replays 26 synthetic M3 cases through the native SDK and v1 pipeline, and invokes the Dart public-endpoint grader. The `eval` CI gate checks the uploaded `backend/artifacts/buddy/B08-offline.json`; no key or paid call occurs. These fixtures prove regressions, not model quality or full proposal AQ metrics. Full quantities/question policy awaits A21.

`make eval-schema` regenerates both versioned internal schemas. Keep the snapshot and prompt version together. The old B02 CLI remains isolated; `--schema-v1` only exports the new schema.

B08's separately authorized live test has a durable local **10-send total fence**, including repairs. It is absent from make/CI targets and requires the exact owner scope flag recorded in the card. The scope ledger is pre-provisioned outside the test with an fsynced file and parent directory; its `B08-max10\n` header is followed by one ASCII `1` per reserved physical send. The transport only opens existing state, appends and fsyncs before dispatch, and rejects missing/malformed state. Do not recreate or reset it without new owner authorization after that scope is consumed.
