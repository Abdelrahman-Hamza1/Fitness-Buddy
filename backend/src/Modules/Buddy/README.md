# Buddy

B08 exposes `POST /v1/buddy/interpret` to live authenticated sessions, including guests. It returns typed proposal **inputs**, never writes to the diary or computes nutrition totals. The app's A21 ProposalEngine applies policy and A23 owns pending messages.

The pipeline validates bounded context, durably reserves a paid send, calls GPT-6 Luna, validates the closed `interpret-v2` schema and semantics (B09a: flat intent plus grouped nullable members, list `ref` indexes instead of IDs, the closed day grammar, the stated-figure literal guard), resolves personal/catalog foods, and saves the result for replay. Native Responses uses low effort, 1,600 output tokens, a 20-second deadline, `store:false`, no tools, provider fallback or SDK retries. Invalid output gets at most one separately reserved repair using a fixed instruction that names only the closed invalid-output code (`shape`, `bounds`, `mixedGroups`, `refRange`, `dayHint`, `statedNotLiteral`, `closedValue`, `food`); invalid twice returns typed Clarify. Nothing to link to (no matching saved meal or batch, an empty list, "save this" without an active proposal) is a Clarify `referenceNotFound` without a repair. Refusal, timeout and provider failure return pending 503. Rerank is disabled.

Personal names/aliases are resolved before the catalog; returned food facts and serving data come from those sources. Distinct alternatives and dimension options include the facts needed for offline taps. State mismatches retain both the source state and a stated-state dimension for client yield conversion. Only an unmatched item can expose a physically bounded, explicitly badged AI nutrient range **per 100 g**. An unmatched item without a valid range returns Clarify. No model nutrients replace a real match.

## Agent turns (B25)

`POST /v1/buddy/turns` and `/turns/continue` (`technical-planning/06-buddy-ai.md` §2–§7, TD-124–TD-128) are the agentic Buddy. Interpret keeps working until A66 switches the app (B26 removes it).

- **Layers.** `Api/` maps the public bodies (`BuddyTurnRequests.cs`, public records and enums for the validation generator) to Application inputs and writes the stream (`SseTurnWriter`: `id: {turnId}:{round}:{seq}`, one `data:` JSON per event, flush per event, `: ping` heartbeat, `Cache-Control: no-cache`, `X-Accel-Buffering: no`, no buffering). `Application/Agent/` holds the use cases (`RunTurn`), the loop (`BuddyAgent`), tools (`ServerTools`, `ActionTools`, `PhoneTools`, `ToolRunner`), the context projection (`TurnContextBuilder`) and the user-visible text (`ReplyWriter`). `Domain/Agent/` holds the events, phone-tool calls, the QueryPlan, claims, proposal IDs, card arithmetic and the guards (`ReplyGuard`). `Infrastructure/Agent/` holds the ledger, the sealer and the model adapter.
- **Problems before the stream, events after.** 400 (validation, `Idempotency-Key` ≠ `turnId`, `mode: weeklyReview` until B26), 401, 409 (an acknowledged round), 429 (the turn's one message denied), 503 (disabled, no seal key, recovery). After the headers only events: `error invalid` (continuation or results don't match), `error expired` (> 10 min, or a third attempt), `error unavailable|timeout`.
- **Ledger** (`buddy.turns`, `buddy.turn_rounds`; RLS, erasure, 24 h cleanup): content-free counts and states only. A new turn reserves one Usage message (`ReserveMessageAsync`); each physical send reserves one Usage call. A round is completed when its terminal event was flushed, else cancelled; started, cancelled or unacknowledged rounds re-run once as attempt 2; `continue` for round r+1, `ackTurn` or 10 minutes acknowledge. Sends and completion are fenced by attempt (a superseded attempt stops; an in-process fence cancels it at once), and a continuation is void once a newer attempt of its round started. The turn row also holds the disclosed phone rows/bytes (120 / 48 KiB per turn); a round's first continue records a digest of its results, and a retry must repeat them.
- **Continuation**: AES-256-GCM over the workspace (transcript without images, handles, claims, cards, the personal data seen), bound to API version, user, turn and round; valid 10 minutes. The phone holds it; the server keeps nothing between rounds.
- **Budget** (`Buddy:Agent`, authoritative in the ledger): 60 s from the first start (covering model, tool and action work), 10 sends (rewrites and the summary step count), 3 phone rounds, 64k/8k tokens (each send's projected input is checked first), ≤ 6 calls per step, ≤ 8 KiB per tool result. At any limit or quota: a templated wrap-up without a send (`done limit|quota`).
- **Claims and guards**: every number the model may mention is a claim `{id, metric, operation, period, value, unit, label}`; the model writes `{fact:k3}` and code renders value, unit and label. Bare numbers outside the whitelist, unknown claim IDs and moral food words get one rewrite (closed issue codes only), then a template. Declines are templates.
- **Action tools** validate with interpret's own rules (`Domain/ParsedIntentRules`) before resolving; a tool's dependency failure is the closed result `unavailable`, any other failure after the headers ends with `error unavailable`.
- **Deviations from 06** (B25 card, Progress log): server tools run one after another (they share the workspace and the scoped catalog connection); barcode products answer questions but cards resolve by name; `compute` converts amounts with the food's own servings and leaves yields to the phone's engine; question options that fail the guard are dropped (no rewrite).

```json
{ "Buddy": { "Agent": { "SealKeyFile": "/run/secrets/buddy-agent-seal-key", "TraceEnabled": false,
  "RegisteredDailyMessages": 100, "RegisteredDailySends": 400, "GuestDailyMessages": 30, "GuestDailySends": 120 } } }
```

The seal key is base64 of 32 random bytes in a private file (0600, not a symlink). `phone-server.py configure-buddy` creates it once (and upgrades a B08-era overlay on the next `up`), with `TraceEnabled` on for the owner's server. Logs carry a hash of the turn ID, round, attempt, outcome code, send count, tool names, card count and prompt version; spans and metrics carry task, model, prompt version, outcome and tokens; the dev `trace` event goes only to the phone. Live check: `tools/scripts/buddy-agent-smoke.py --live` (paid; scenarios `log`, `phone`, `retry`).

## Intents and resolution (B09a)

The response carries sixteen public kinds (`technical-planning/06-buddy-ai.md` §3.2). `Application/ResolveInterpretation` dispatches each validated parsed intent to one of three resolvers:
- `ResolveFoods`: B08's personal → catalog → badged-estimate food resolution, unchanged. It serves foodLog items, diary-edit replacements, batch ingredients, personal-food components and memory subject foods (memory keeps a real match only).
- `ResolveReferences`: diaryEdit, diaryDelete, ambiguousReference, diaryCopy, savedMealLog and savedMealCreate.
- `ResolveCreations`: memoryChange, batch, batchPortion, batchClose and personalFoodCreate.

The model links mentions to list positions. The server maps them to request IDs and **decides ambiguity** (TD-091), in this order:
1. no link: `targets: []` when the reference has a date or slot hint (the app looks it up locally), otherwise clarify `referenceNotFound`;
2. scope all, or one link: those entries are the targets;
3. several links with a date/slot qualifier: `ambiguousReference` carrying the operation and the patch;
4. several unqualified links: the newest (date, slot) group, which is the target when it has one entry and otherwise asks.

`ambiguousReference` never comes from the model. A copy without a source slot and an ambiguous save are clarify `unclear`. An unmatched food without an estimate turns its whole intent into clarify `unmatchedFood`. Stated personal-food figures are emitted exactly as validated against the message (TD-092) and never filled or computed. Day hints use the closed grammar `today | yesterday | daysAgo:N | lastWeekday:… | date:[YYYY-]MM-DD`, which the app resolves locally. **Every UUID in a response comes from the request context** (recentEntries, savedMeals, openBatches, personalFoods, activeProposal). This PA5 invariant is asserted in the unit tests and by the public eval's `provenance` check.

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

The API key file must be private, absolute and not a symlink. Mount it read-only outside the repo; never put its value in app settings, the app, argv or logs. The fixed OpenAI transport does not follow redirects. The concurrency bound is per process; daily operational safety ceilings are shared in Postgres. These are not R3 commercial allowances. Context forwarded to the provider is an allowlisted projection: list positions (`ref`) instead of IDs, no grams, account/device fields or food nutrients; the active card forwards only its slot, time and line name/amount/unitCode/state. Logs/traces contain only model/version, outcome, the closed invalid-output code, timing, tokens and estimated cost. `store:false` does not claim provider zero retention (R1/R2 terms remain as accepted).

## Verification

`make check test eval` is offline. The v0 SDK replay stays unchanged. Persistence.Tests starts a real authenticated HTTP API, replays the synthetic fixtures through the native SDK and v2 pipeline, and invokes the Dart public-endpoint grader for two case files:
- the 26 M3 cases → `backend/artifacts/buddy/B08-offline.json`;
- the 53 B09 intent cases (17 Arabic/Arabizi) → `B09-offline.json`;
- B09b's engine-level AQ runs (`Real_catalog_runs_write_engine_level_AQ_reports_for_M3_and_B09`): a scratch database with the generated release (`build/catalog`) imported, the real `CatalogQueries` resolver, the same recorded outputs, and the Dart CLI's AQ mode running fb_domain's `ProposalEngine` on every response → `B09b-aq-m3.json` (all 26 M3 cases) and `B09b-aq-b09.json` (the plain B09 cases, T03 and T24 included). The test asserts the harness only: exit 0, every row 200, rows = the cases with an `aq` block, the imported catalog version, no repair send.

The `eval` CI gate (`tools/scripts/check-buddy-eval.py`) checks the two interpretation reports for required IDs, per-case check sets, the PA5 provenance check, the Arabic/Arabizi quarter and the `en`/`ar`/`arabizi` breakdown, then (after its `--selftest`) gates the two AQ reports: AQ-02 ≥ 95 %, AQ-03 ≥ 98 %, AQ-04 ≥ 95 %, AQ-06/07 ≥ 90 %, AQ-08 0 cases, AQ-10 100 % on the overall values (per-language reported, AQ-11), AQ-05 `n/a` until reference dishes ship (TD-074), with the shrink-only known-miss baseline `tools/buddy_eval/cases/aq_known_misses.json` (B09b PA19). Failures are annotations naming case#item, metric and closed codes, never content. No key or paid call is involved. These fixtures prove the pipeline and the engine on recorded interpretations, not model quality; edits, memory and batches are measured in A25–A27. Privacy (`IdentityPrivacyTests.B09_interpret_context_and_intents_leave_no_content_in_logs_and_telemetry`), the per-list bounds and the replay of every new kind are covered in Persistence.Tests.

`make eval-schema` regenerates the v0 and production (`interpret-v2`) internal schemas. Keep the snapshot and prompt version together. `interpret-v1.*` are frozen history. The old B02 CLI remains isolated; `--schema-v2` only exports the production schema, and a test pins it inside OpenAI's strict-mode limits and our budget (depth ≤ 5, ≤ ~150 properties).

B08's separately authorized live test has a durable local **10-send total fence**, including repairs. It is absent from make/CI targets and requires the exact owner scope flag recorded in the card. The scope ledger is pre-provisioned outside the test with an fsynced file and parent directory; its `B08-max10\n` header is followed by one ASCII `1` per reserved physical send. The transport only opens existing state, appends and fsyncs before dispatch, and rejects missing/malformed state. Do not recreate or reset it without new owner authorization after that scope is consumed.
