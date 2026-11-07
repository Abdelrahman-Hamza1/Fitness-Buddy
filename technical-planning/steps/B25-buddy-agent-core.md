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
- 2026-11-06: handoff merged on main as 1efd7592 (coordinator added the two sync fixtures and fixed two app tests); branch rebased onto it.
- 2026-11-06: WP2 protocol (SSE writer, AES-GCM continuation, ledger + migration `202611060001_AgentLedger`, retry rule, Usage `ReserveMessageAsync`, `phone-server.py` seal key), WP3 loop and budget (`BuddyAgent`, `ChatClientAgentModel`, prompt `agent-v1`), WP4 context and tools, WP5 claims, guards, trace, logs and the two TD-128 tests committed.
- Decisions where 06 is silent or the code needed it (WP2–WP5):
  - D14 "Routing task `agent`": there is no routing layer yet; it is the `buddy.task=agent` tag on spans and metrics, with the fixed model.
  - D15 Server tools run one after another, not in parallel: they share the workspace (handles, claims) and the request's scoped catalog connection. Each is still capped at 5 s.
  - D16 `compute` converts amounts with the food's own servings (g, kg, ml/l with density, serving unit codes) and does no yield conversion (FD-060/062 stay in the phone's engine); an unconvertible unit is reported, never guessed.
  - D17 `lookup_barcode` answers with name, brand and per-100 claims; cards resolve by name (catalog or the badged estimate), because an OFF product isn't a candidate key the app can restore yet.
  - D18 Guards: replies and summaries get one rewrite then a template (the summary is dropped instead); a failing `ask_user` text becomes "Could you tell me a bit more?", failing options are dropped (fewer than two → plain text, `done answered`); a failing suggestion label becomes the option's food names. No rewrite mid-step.
  - D19 `propose_weigh_in` values and stated personal-food figures must appear literally in the message (TD-092), else the tool answers `notStated` / `statedNotLiteral`.
  - D20 A prior attempt's pending cards get card handles with revision 1 (the retry request doesn't carry revisions).
  - D21 Exit criterion 2's "the same proposal IDs" is superseded by the spec fix-check: a retry gets attempt-scoped IDs; the test and smoke assert that and the single message charge.
  - D22 Body limit: 1 MiB on the two turn routes (a 256 KiB continuation plus results, or a photo).
- 2026-11-06: local proof: `IdentityPrivacyTests.B25_agent_turns_stream_content_while_logs_telemetry_and_ledger_omit_it` (scripted model, real HTTP + Postgres) covers SSE ids, the phone round trip, attempt-scoped IDs, one message per turn across a retry, `error expired` (third attempt, old continuation), `error invalid`, 409, a code-rendered claim, and no content in logs, spans, metrics, Sentry, audit or ledger rows. `ConfirmationGuardTests` (Architecture.Tests) pin AQ-01. Live smoke `tools/scripts/buddy-agent-smoke.py --live` is ready for the owner's key (not run: no paid requests in this session).
- 2026-11-07: Codex code + security review: changes required, no blockers (6 + 5 majors, 2 minors). Fixed in three groups:
  - `259550c8` interpret's semantic rules moved to Domain (`ParsedIntentRules`) and applied by every action tool; personal matches win over a pinned catalog handle; `suggest_foods` takes `replaces`; portion units in the number guard.
  - `767a5f03` contract (additive, agreed with A66): `BuddyPriorCard.revision` (required; seeds the retry's open cards), the `unsupported` phone-tool result variant and error code; `priorAttempt.attempt` 1 on a first post runs as attempt 1. Nested start/result bounds (every annotation, no null elements, 200-char cap on unannotated strings) before any ledger change.
  - `52b8e822` attempt fencing (ledger + in-process), continuations bound to their producing attempt, ledger-held disclosure counters with a results digest per round, the turn deadline over model + tool + action work (→ `done limit`), projected input tokens checked before each send, a content-free failure boundary, claims listed in every tool result.
  - The ledger migration `202611060001_AgentLedger` was extended in place (it isn't on main yet): `disclosed_rows`, `disclosed_bytes`, `results_digest`.
  - D23 Shape violations inside phone results are 400 before streaming (like the row caps), not `error invalid`; `error invalid` stays for results that don't answer the pending calls, a superseded attempt's continuation, or a retry with different results.
  - 2026-11-07 fix-check: all resolved except S4; fixed: each send atomically reserves a conservative input bound (UTF-8 bytes ÷ 2, a photo a fixed 3,000) in `buddy.turns.reserved_input`; admission counts recorded input + every outstanding reservation + the new bound; the reservation is reconciled to the reported usage after the send, and a send with no reported usage keeps it as spent.
  - D24 Cross-process fencing is in the ledger (sends, completion, continuations); the in-process fence also stops a superseded attempt's events at once. Two API processes could still each emit one event between a retry's start and the old attempt's next send (R1 runs one process).

## Outcome

**Done (2026-11-07).** The server half of the agentic Buddy (D-100) is in, merged as a group with A66 stacked on this branch.

- **Contract** (handoff 1efd7592, plus the additive review change `767a5f03`): `POST /v1/buddy/turns` and `/turns/continue` streaming `BuddyTurnEvent`; start/continue bodies with history, summary, compaction, personal slice, profile, snapshot, `ackTurn` and `priorAttempt` (cards with revisions); phone-tool call/result unions with scope caps and the `unsupported` result; the frozen QueryPlan; four additive intent kinds; `buddySummary` / `memoryItem` sync admission.
- **Server**: SSE per round (ids, flush, heartbeat, no buffering); AES-256-GCM continuations bound to API version, user, turn, round and producing attempt; a content-free ledger (`buddy.turns`, `buddy.turn_rounds`: budget, attempts with fencing, acknowledgement, disclosure counters, results digest, reserved input); our own tool loop with one authoritative budget (deadline over all work, sends, phone rounds, reserved-then-reconciled input tokens, output tokens) and templated wrap-ups; server tools, every B25 action tool over interpret's resolvers and rules (personal slice first), phone-tool mapping with handles and claims; code-rendered claims with the bare-number / unknown-fact / banned-word guards (one rewrite, then a template); dev trace to the phone only; content-free logs and metrics.
- **Tests (TD-128)**: `ConfirmationGuardTests` (AQ-01) and the B25 canary + protocol test; the generic gates (conformance, layer rules, format) green.
- **Review**: Codex code + security (changes required, no blockers) → all fixed; fix-check resolved everything except S4, fixed in `1761220e` (last fix before merge, no further round).
- **Decisions** D1–D24 above (simplest sound options where 06 was silent, review-driven deviations).
- **Open**: exit criterion 2's live smoke on the laptop (`tools/scripts/buddy-agent-smoke.py --live`, owner's key; seal key via `phone-server.py configure-buddy`). Interpret stays until A66 switches; B26 retires it.

- **Live smoke (2026-11-07, laptop server on main 14f321db, 9 real sends over 5 turns, ~52k input / 650 output tokens):** `log` ✓ (1 send, card + templated line), `phone` ✓ (model chose readDiary; wrong call IDs → `error invalid` with no send; continue → text + done), `workout` ✓ (3 exercises, bench read by code as 3×8 at 80; the model left exerciseRef empty, so the app asks for a pick: prompt tuning item), `body` ✓ (measurement + 3-row import, `110k` kept for the app's unit flag), `weekly` ✓ (code header + 2 observations, no tools). `retry` and `label` not run live (budget; retry covered by the scripted Docker test, no label photo at hand).
