# B25 — Buddy agent core (server)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B08, B09a, B10a, B23 (Usage/ledger, config) | L | Claude (Opus build), Codex review (Risky) | ⬜ |

**Goal.** The server half of the agentic Buddy (D-100): the turn endpoints with SSE, our own tool loop over `IChatClient`, the sealed continuation for phone tools, the server tools, every action tool for the intents the app already knows or B09a defined, the guards on model text, summary, trace and per-step limits. Everything in `06` §2–§7, §9 except what B26 adds.

**Read first:** `spec/10-ai-assistant.md` §15, D-100, TD-124–TD-128, `06-buddy-ai.md`, `backend/src/Modules/Buddy/README.md`, B08/B09a cards.

## Scope (work packages, one commit each)
- **WP1 Contract handoff (TD-065), merged on its own so A66 can start:** `POST /v1/buddy/turns` and `/turns/continue` bodies (`06` §3.1–§3.2, incl. `compact`, `personal`, `profile.defaults`, `ackTurn`); the `BuddyTurnEvent` union with SSE ids, `proposalId` (UUIDv5 of turn, round, attempt, index)/`revision`/`replaces` and the `priorAttempt` retry block (§3.2–§3.4); the phone-tool call/result schemas with their scope caps (§4.2) and the **frozen QueryPlan grammar** (§6.3: metrics, ops incl. `last` for exerciseLastDate, valid combinations, periods ≤ 400 days, filters incl. `muscleGroup`, units, link targets, `unsupportedPlan`); facts as code-labelled claims (§4); additive intent kinds `measurement`, `workout`, `importRows`, `suggestion` (defined now, emitted by B26/A68); sync entities **`buddySummary`** and **`memoryItem`** with server admission (B05 rules). `make gen`, `501` stubs for the turn routes.
- **WP2 Protocol and ledger:** SSE writer (ids, flush per event, 10 s heartbeat, `X-Accel-Buffering: no`, no compression), sealed AES-256-GCM continuation (key file, 10-min TTL, bound to user/turn/round/API version, exact pending call IDs), ledger turn and round rows (content-free; started/completed/cancelled, attempts, acknowledgement by `continue`/`ackTurn`/10 min), the retry rule (started, disconnect-cancelled or unacknowledged rounds re-run once as attempt 2 without a new message charge; `priorAttempt` passed to the model as already handled/still open; `409 roundAlreadyRan`, `error expired`), laptop wiring for the seal key in `phone-server.py`.
- **WP3 Loop and budget (TD-124):** `BuddyAgent` with the one turn budget (60 s from first start, 10 sends incl. rewrites and summary, 3 phone rounds, 64k/8k tokens, ≤ 6 calls per step, result caps), deterministic wrap-up without a send at any limit or quota, cancellation on disconnect, Usage reservations (sends per step, one message per turn), routing task `agent`, prompt `agent-v1`.
- **WP4 Context and tools:** projection of history/summary/compact/personal/profile/snapshot (allowlist), handle map, compaction summary step (`summary` before `done`), server tools `search_foods`, `get_dish`, `lookup_barcode`, `compute`; action tools over the existing resolvers (personal slice first) with deterministic `proposalId`s and `replaces`: `propose_food_log`, `propose_diary_edit/delete/copy` (TD-091), `propose_saved_meal`, `propose_batch`, `propose_personal_food`, `propose_memory`, `propose_weigh_in`, `suggest_foods`; terminal `ask_user`, `decline`; fast-path one-liner.
- **WP5 Facts, guards, trace:** claim renderer (value + unit + code label) and bare-number check with the whitelist, banned words, one rewrite then template (replies, questions and options, suggestions, summaries), templated declines; `Buddy:Agent:TraceEnabled` trace events; content-free logs and metrics.
- **Tests (TD-128):** only the confirmation guard (an architecture rule that the Buddy module references no user-data write port) and what the generic gates need (contract conformance, layer rules, the log canary on the new routes). Interpret stays working until A66 switches.

## Out of scope
Label vision, weekly review mode, workouts/measurements/imports tools, exercise search, `check_fit`, interpret removal: B26.

## Exit criteria
1. Contract handoff merged first; the full step merges with CI green.
2. On the laptop server, a scripted turn (dev key, ≤ 3 live requests) logs "2 eggs" in one send, answers a phone-tool round trip, and streams `step`/`text`/`proposal`/`done`; a killed stream retried with the same request yields the same proposal IDs without a second message charge.
3. A replayed continuation of an acknowledged round gets 409 without a send; an expired one `error expired`; results for the wrong call IDs `error invalid`.
4. Logs and traces hold no message or tool content (existing canary tests extended to the turn endpoints).
5. Codex code + security review passed.

## Lane
Lane 1 (backend). A66 starts on lane 2 as soon as the contract handoff is on `main`.

## Low-level plan

One engineer (TD-095), lane folder `fitness_buddy_2`, stacked on the agentic-Buddy spec. One commit per WP; WP1 is handed off on its own (TD-065).

**WP1 contract handoff** (`contracts/openapi/modules/buddy.yaml`, root `paths`, `sync-entities.json`, fixtures, `make gen`):
- Paths `POST /v1/buddy/turns` (`startBuddyTurn`) and `POST /v1/buddy/turns/continue` (`continueBuddyTurn`): `200 text/event-stream` with `BuddyTurnEvent`, problems 401/409/503 (+ shared 400/426/429/500). `Idempotency-Key` required and equal to `turnId` on both (the ledger, not the replay middleware, dedupes: a stream can't be buffered for replay).
- Requests `BuddyTurnStart` / `BuddyTurnContinue` with `priorAttempt`; events union `BuddyTurnEvent` (discriminator `type`); phone tools as two unions discriminated by `name` (`BuddyPhoneToolCall` in `phoneTools`, `BuddyPhoneToolResult` in `continue`), with per-tool args/data schemas carrying the §4.2 caps as `maxItems`; `BuddyQueryPlan` frozen grammar (flat, nullable members; valid combinations in the description, enforced by the phone's QueryEngine → `unsupportedPlan`); query results as claims without IDs or labels (the server assigns IDs and renders labels, §7).
- Intent kinds `measurement`, `workout`, `importRows`, `suggestion` added to `BuddyIntent` (not emitted until B26/A68).
- Sync entities `buddySummary` v1 and `memoryItem` v1: envelope-only admission (B18 pattern) and the embedded export; their `entity-payloads.json` fixtures come with the app tables (A66, A67), because the app's sync-engine test pins one fixture per app table.
- Server: C# records for every schema (requests public in `Api/`, events and tool args internal in `Domain/Agent/`), the BuddyContractTransformer generalized to the new unions, two endpoints returning `501` until WP2, per-route body limit 1 MiB (continuation ≤ 256 KiB + results).

**WP2–WP5** follow the Scope list; files under `Modules/Buddy/{Application,Domain,Infrastructure}/Agent/`, one new Buddy migration (ledger turn/round tables, RLS, erasure), migration-count assertions updated.

**Decisions where 06 is silent** (simplest sound option):
- D1 Discriminator values are camelCase (`findMyFoods`, `readDiary`, …) like every other code in the contract; the model-facing tool names stay snake_case inside the server.
- D2 `callId` is a server-minted UUID (the provider's call IDs never reach the phone).
- D3 Personal slice `ref` and every local reference are non-nil UUIDs (a `usual` item uses the ID of its saved meal or representative row; the phone decides).
- D4 Quota: a denied send inside a turn ends with `done reason quota` (06 §2) — TD-128's "error quota" wording is read as this; a denied message reservation at start is the usual 429 before streaming.
- D5 `mode: weeklyReview` is in the enum now; the `weekly` block arrives with B26 (additive, optional request member); until then the server answers 400 for that mode.
- D6 `profile.units`: mass kg|lb, length cm|in, energy kcal only (LC-012).
- D7 Query link targets are explicit nullable members (`date`, `from`, `to`, `exerciseRef`, `workoutId`) instead of a free `params` map.
- D8 Claims on the wire use canonical units (kcal, g, kg, cm, percent, count, date); the server renders them in the profile's units.
- D9 Rounds: the start request runs round 0; a `phoneTools` event announces round 1–3, which `continue` runs. SSE ids use the same numbers.
- D10 `409 roundAlreadyRan` uses the framework's default Conflict problem `type` (as interpret's 409); it is the only 409 cause on these routes, so no new problem type.
- D11 Request-side nutrients keep their own schema `BuddyNutrientsRequest` (oasdiff compares `oneOf` members by name, and the response `BuddyNutrients` is internal); servings reuse `BuddyServing` as interpret's request does.
- D12 The architecture rule's public-surface exception widens from public Api records to public Api enums (request enums must be public for the validation generator); `ApiJson` allows out-of-order union discriminators (a client may send `name` after other members).
- D13 The measurement intent's kind enum is `BuddyBodyMeasurementKind` (the generator already names the `kind` discriminator enum `BuddyMeasurementKind`).

## Progress log

- 2026-11-06: low-level plan written (WP1 first, handed off on its own).
- 2026-11-06: rebased on the spec fix-check (bf0283d9: attempt-scoped proposal IDs + `priorAttempt`, claim-labelled facts, QueryPlan `last` + `muscleGroup`, link target `workout`), reflected in WP1.
- 2026-11-06: WP1 contract handoff committed: both turn routes (501 stubs), 104 new Buddy schemas, 4 additive intent kinds, `buddySummary`/`memoryItem` v1 admission. Conformance, lint, selftest, breaking (report: none), Dart client analyze/test, Architecture/Contract/Buddy/UserData/BuildingBlocks/Host tests green. Next: WP2 after the handoff merges.

## Outcome
