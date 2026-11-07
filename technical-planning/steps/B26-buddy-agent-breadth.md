# B26 — Buddy agent breadth (server): workouts, body, imports, label, weekly review, Ramadan; interpret retired

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B25, **A66** (for the interpret removal) | M–L | Claude (Opus build), Codex review | ✅ |

**Goal.** The rest of the server Buddy (spec 10 §4.6, §8, §11–§12, `15` §4, `14` §4, RM): the action tools and modes B25 left out, and the retirement of the one-shot interpret path (TD-128). Replaces the server halves of B10b, B11 and B12.

## Scope
1. `exercise_search` (library + aliases in the cached prompt part, custom names via `read_workouts`) and `propose_workout` (sets, per-dumbbell semantics hints, the deterministic set-notation parser cross-check WO-030–033) → `workout` intent.
2. `propose_measurement` → `measurement`; `propose_import` (pasted rows: date, value, unit?, original text) → `importRows`.
3. `check_fit` for suggestions; halal flag honoured in `search_foods`/`suggest_foods`.
4. `POST /v1/buddy/label`: one structured vision call → `LabelExtraction` (basis, serving, nutrients, name guess, per-field confidence), Usage-counted, content-free logs.
5. `mode: weeklyReview`: aggregates only, no phone tools, ≤ 2 observations, NumberGuard, banned words, optional attached check-in proposal passthrough.
6. Ramadan: `profile.ramadan` context and wording in `agent-v1` (suhoor/iftar slots, fasting-day phrasing).
7. **Retire interpret** once A66 is on `main`: remove `/v1/buddy/interpret` (contract, endpoint, prompt, parser, replay store columns no longer used via a forward migration), `tools/buddy_eval`, the CI `eval` job and `check-buddy-eval.py`; keep the resolvers.

## Exit criteria
1. Each new tool and mode produces its intent or event in a scripted laptop run (shared live budget with B25/A66, ≤ 3 requests).
2. CI green with interpret and buddy_eval gone; no dangling references (`cross-check`).
3. Codex review passed.

## Lane
Lane 1 (backend), after B25. Its contract additions for label/weeklyReview merge early if A68/A69 wait for them.

## Low-level plan

One engineer (TD-095), lane folder `fitness_buddy_2`, stacked on B25. One local commit per WP; WP1 (contract) is handed off first (TD-065). Files under `Modules/Buddy/{Api,Application,Domain,Infrastructure}/Agent/` plus a small Catalog contract.

- **WP1 Contract** (`contracts/openapi/modules/buddy.yaml`, root paths, `make gen`): `POST /v1/buddy/label` (`extractBuddyLabel`: `BuddyLabelRequest {image}` → `BuddyLabelExtraction {found, basis, serving, name, nutrients (value + confidence each), others}`; 400/401/429/503), the optional `weekly` member on `BuddyTurnStart` (`BuddyWeeklySummary`: the app's `WeeklySummary` aggregates, workouts, `checkIn`), step code `searchingExercises`. Label answers 501 until WP5; `weeklyReview` stays 400 until WP6.
- **WP2 Workouts**: `IExerciseLibrary` (Catalog.Contracts, active `catalog.exercises` + names), the library in the static prompt part, `exercise_search`, `propose_workout` with the deterministic set-notation parser (WO-031) as cross-check.
- **WP3 Body and imports**: `propose_measurement`, `propose_import`.
- **WP4 Fit and halal**: `check_fit`; halal flags in `search_foods`, halal-only `suggest_foods`.
- **WP5 Label**: one structured vision call (`label-v1`), Usage message + send, content-free logs; the no-content canary for `/label`.
- **WP6 Weekly review and Ramadan**: `mode: weeklyReview`; Ramadan context and wording in `agent-v1`.
- **WP7 Interpret retired** (after A66 is on `main`, rebased): endpoint, contract, prompts, parser, ledger, `buddy.attempts` (forward migration), BuddySpike, `tools/buddy_eval`, the `eval` CI job, `check-buddy-eval.py`, interpret-only tests; resolvers kept; cross-check.
- **Smoke**: `tools/scripts/buddy-agent-smoke.py` gains `workout`, `body`, `import`, `label`, `weekly` scenarios (scripted, not run live here).

**Decisions where 06 is silent** (simplest sound option):
- D1 Label has no `Idempotency-Key`/replay: the generic replay middleware holds a transaction across the handler and caps bodies at 256 KiB, and a label read changes no data; a retry is the user's and costs one more message. Each read reserves one message and one send against the `Buddy:Agent` daily ceilings.
- D2 Label numbers are transcribed by the model; code converts kJ → kcal and salt → sodium, drops out-of-range values (the app's field maxima) and leaves the FD-012 sanity check to the app.
- D3 `weekly` is optional (absent = null) and required for `weeklyReview` (else 400). The review's factual line is a code template over the aggregates (AI-130), the model adds at most two observations (one per line; code keeps two, each guarded); no tools in that mode.
- D4 Check-in passthrough: `weekly.checkIn {currentKcal, proposedKcal}` become facts and the review says a new target is ready; the app attaches its own pending `targetChange` proposal (A38). No target-change intent from the server.
- D5 The exercise library comes from Catalog through `IExerciseLibrary`, cached per process and appended to the system prompt (static, prompt caching). `propose_workout` takes an `x` handle or a library code; custom exercises only as handles from `read_workouts`.
- D6 Set cross-check: each exercise may carry `notation` (its literal set text) and `sets`. Notation found in the message and parsed by the grammar wins over the model's sets (an assumption chip when they differed); otherwise every set number must be stated in the message (TD-092). "Same as last push but …" copies a session seen through `read_workouts` (`w` handle) with the stated changes.
- D7 Dumbbell exercises default to `perDumbbell: true` with an assumption; the model passes `false` only when the user stated a total.
- D8 `measurement` emits built-in kinds only (custom type IDs never reach the server); unit checked against the kind; the value must be stated.
- D9 Import rows: `original` is a literal piece of the message, its value and unit appear in it; dates as read (the app flags unclear ones, WB-031).
- D10 Halal on the server is a name keyword check (the `fb_domain` HalalCheck lists; the catalog has no ingredient text): `search_foods` marks flags as a warning, `suggest_foods` drops options with a flagged item when `profile.halal` (FD-082).
- D11 `check_fit`: resolved options against the snapshot's remaining kcal and protein (claims); unknown remaining → `fits: null`.
- D12 Ramadan: code adds `fastingNow` from `now`, `fajr` and `maghrib`; the wording lives in `agent-v1`.

## Progress log

- 2026-11-07: low-level plan written (WP1 contract first, handed off on its own).
- 2026-11-07: WP1 contract committed (additive): `POST /v1/buddy/label` (`extractBuddyLabel`, idempotency-exempt, 501 until WP5) with `BuddyLabelRequest` / `BuddyLabelExtraction`; optional `BuddyTurnStart.weekly` (`BuddyWeeklySummary`, workouts, `checkIn`); step code `searchingExercises`. `make gen`, check-contract (bundle, lint, selftest, breaking notice-free, conformance), fb_api_client analyze, Architecture.Tests green.
- 2026-11-07: WP2–WP4 committed together (they share `ActionTools`): `IExerciseLibrary` (Catalog.Contracts, cached 10 min) and the library in the static prompt part; `exercise_search`, `propose_workout` with `SetNotation` (WO-031 grammar; checked by hand on 16 notations, no committed test per TD-128), copy from a `read_workouts` session; `propose_measurement`, `propose_import`; `check_fit`; server `HalalCheck` (search flags, halal-only suggestions). Host builds clean.
- 2026-11-07: WP5 label committed: `ExtractLabel` (one message + one send in one ledger transaction, 429 before any call), `ChatClientLabelReader` (`label-v1`, JSON schema from `LabelReading`, no retries), `LabelRules` (kJ → kcal, salt → sodium, g ↔ mg, impossible values → null/low); the recovery lease is released for this handler like interpret's. `IdentityPrivacyTests.B26_label_read_returns_values_while_logs_and_telemetry_omit_photo_and_text` and the B25 canary green; conformance green.
- 2026-11-07: WP6 committed: `mode: weeklyReview` (weekly block required and checked; aggregates-only context; code header + ≤ 2 guarded observations, one rewrite; no tools); Ramadan `fastingNow` in the context and the RAMADAN section in `agent-v1`. Checked end to end with a throwaway scripted run (weekly, workout notation override, measurement, import), not committed (TD-128).
- 2026-11-07: rebased onto main ab9549e7 (B25 + A66 merged), clean.
- 2026-11-07: WP7 interpret retired: route, contract path and its 8 request/response schemas, prompts v0–v2 and schemas, parser/protocols, interpret ledger, `buddy.attempts` (forward migration `202611070001_RetireInterpret`, erasure/cleanup/ownership updated), `BuddyOptions` reduced to Enabled + ApiKeyFile, `backend/tools/BuddySpike`, `Buddy.Tests` (all interpret-bound), `BuddyPublicEvalTests`, `BuddyLedgerTests`, the B09 canary, `tools/buddy_eval`, `check-buddy-eval.py`, the frozen `contracts/testdata/buddy/interpret-requests.json`, the CI eval steps and `make eval*`. Kept: resolvers, `ParsedIntentRules`, the shared request shapes. The admin limit/race tests now use a label read (counting reader in the harness). Smoke gained `workout`, `body`, `weekly`, `label`. Cross-check below.

- 2026-11-07: Codex code + security review: changes required, no blockers (7 + 1 majors, 3 + 2 minors). Fixed in five commits, no further round (nothing structural):
  - `0c4d4263` migration: R1 deploys are not stop-the-world (`phone-server.py up` recreates `migrate` while the old api/worker containers still serve), so `buddy.attempts` stays with its erasure, cleanup and ownership; the drop is backlog #318.
  - `3d586b73` the turn streams release the request's recovery lease like label (the ledger rechecks recovery and fences the generation per transaction); weeklyReview rejects an image (400) and never attaches one; a denied observation send ends `done limit|quota` after the header.
  - `249b1098` label: full base64 + JPEG structure + ≤ 1024 px check before any reservation (400); conversions before bounds; `buddy.cleanup` scheduled in the label transaction.
  - `ba738411` numbers: whole-span literal checks (notation, import originals), unit-bound quantities per exercise segment, set multiplicity, copy-override units (notation → argument → profile), import dates parsed from the original or null, unit-resolved or rejected AxBxC.
  - docs commit: PROCESS.md, `02`, `13`, `contracts/testdata/README.md`.
  - Fix-check (Codex): resolved except two, fixed without a further round: repeated identical model sets need an explicit set count ("3 sets", "3x8", "3 times"), never a rep or load number; a label JPEG must carry a scan header with entropy data before EOI.
  - D13 Import dates come only from code (ISO or month-name with a four-digit year); the model's date argument is ignored.

## Outcome

**Done (2026-11-07).** The rest of the server Buddy is in and interpret is gone; Codex code + security review fixed in one round.

- **Contract** (`69bc25cd`, additive, ready to merge early for A68/A69): `POST /v1/buddy/label` → `BuddyLabelExtraction` (basis, serving, name guess, nutrients with per-field confidence, kJ/salt conversion flags, others); optional `BuddyTurnStart.weekly` (`BuddyWeeklySummary` + workouts + the phone's `checkIn`); step `searchingExercises`. The workout, measurement, importRows and suggestion intents were already in B25's handoff and are now emitted. WP7 then removes `/v1/buddy/interpret` and its 8 schemas (a breaking removal, owner-approved by TD-128; pre-release, so the breaking check reports it as a notice).
- **Tools**: `exercise_search`, `propose_workout` (library in the static prompt, code-read set notation wins over model sets, copy of a seen session, per-dumbbell default), `propose_measurement`, `propose_import`, `check_fit`, halal flags/filter. **Label read**: one vision call, one message + one send, code conversions, content-free log. **Weekly review**: aggregates-only context, code header + ≤ 2 guarded observations, no tools. **Ramadan**: `fastingNow` + `agent-v1` wording.
- **Retired** (TD-128): route, prompts, parser, ledger (its `buddy.attempts` table stays until backlog #318), B02 CLI, `Buddy.Tests`, interpret persistence tests and canary, `tools/buddy_eval`, `check-buddy-eval.py`, the frozen interpret corpus, the CI eval steps, `make eval*`.
- **Tests (TD-128)**: `IdentityPrivacyTests.B26_label_read_…` (new canary for `/label`); B25 canary, `ConfirmationGuardTests`, the admin limit/race tests (ported to a label read), PersistenceTests (migrations), deletion tests green locally. The set-notation grammar, halal check, exercise search and the weekly/workout/body/import paths were checked with throwaway scripted runs, not committed.
- **Decisions** D1–D13 above.
- **Open**: exit criterion 1 live (`buddy-agent-smoke.py --live --scenario workout|body|weekly|label`, owner's key; ≤ 3 requests shared with B25/A66); backlog #318 (drop `buddy.attempts`). Left to the orchestrator (instruction/config files and a spec line): `CLAUDE.md`, `AGENTS.md`, `.claude/agents/ai-engineer.md`, `.claude/agents/verifier.md`, `.claude/skills/cross-check/SKILL.md`, `spec/22` AD-013.

- **Live smoke (2026-11-07, laptop server on main 14f321db, 9 real sends over 5 turns, ~52k input / 650 output tokens):** `log` ✓ (1 send, card + templated line), `phone` ✓ (model chose readDiary; wrong call IDs → `error invalid` with no send; continue → text + done), `workout` ✓ (3 exercises, bench read by code as 3×8 at 80; the model left exerciseRef empty, so the app asks for a pick: prompt tuning item), `body` ✓ (measurement + 3-row import, `110k` kept for the app's unit flag), `weekly` ✓ (code header + 2 observations, no tools). `retry` and `label` not run live (budget; retry covered by the scripted Docker test, no label photo at hand).
