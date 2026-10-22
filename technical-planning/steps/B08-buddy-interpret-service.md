# B08 — Buddy interpret service

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B02, B07 | L | Codex | ✅ Done |

_Old ID: S31 (renumbered by TD-063, 2026-10-16)._

**Goal.** The production `POST /v1/buddy/interpret`: turns a message plus minimal context into typed, validated intents whose food items carry real catalog matches, alternatives and ambiguity dimensions. It's fast, cheap, private and measured by the eval suite in CI.

**Spec:** AI-010, LC-001, LC-006, AI-015, AI-016, AI-020, AI-021, AI-022, AI-023 (interpretation side), AI-070, AI-071, AI-072, AI-151 (estimate fallback), AI-003/SF-030 (intents), AC-041, AC-042, MN-005, AQ-02, AQ-03, AQ-10, AQ-12 · **Decisions:** TD-008, TD-009, TD-030

## Scope
- **Public contract** (`04` §4.3, `06` §3): `InterpretRequest`, `Interpretation` with the intents `FoodLog`, `Clarify`, `OutOfScope`, `Medical` (others are added by their steps), `FoodItem` with `match`, `alternatives` (≤ 3, distinct), `amount`, `share`, `dimensions`, `estimate`. Detected language/script on each intent.
- **Pipeline:** validate + bound the context (limits per list) → prompt (registry v1, versioned files, cached prefix) → `ILlmClient` per the routing table (the B02 winner + fallback) → **JSON-schema validation + one repair retry** → **resolver** (personal candidates from the request first, then `IFoodResolver`: catalog → reference dishes) → AI estimate with a range only when nothing matches (badged) → map to public DTOs.
- **Optional rerank call** behind a flag (enabled only if the eval shows a gain).
- **Idempotency:** `Idempotency-Key` = message ID, so no double billing on retries.
- **Usage module (minimal):** per-user daily counters + per-model token/cost metrics. Fair-use limits are R2 (MN-020).
- **Privacy:** no identity in prompts, **no content in logs**, request size limits, image path stubbed for B10.
- **Rate limits** per user (anonymous allowed with tighter limits).
- **`buddy_eval` upgraded:** runs the public endpoint, and the **`eval` CI workflow** with thresholds on the M3 cases (parse-level metrics now; full AQ metrics in B09, once A21's ProposalEngine exists).

## Out of scope
- The ProposalEngine (A21), UI (A22), other intents (B09, B11, B12), vision (B10).

## Fixed by the plan
- The model never produces numbers except the labelled estimate fallback. Interpretation responses have no write semantics (`03` §5.3).

## Decide in the low-level plan
- The routing table values (model, effort, max tokens, timeouts) from the B02 data.
- How personal candidates are matched against mentions on the server (simple normalized match vs model linking by ID).

## Exit criteria
- [x] Contract conformance green. The Dart client regenerated.
- [x] Integration tests with recorded LLM fixtures: valid output, invalid → repair → success, invalid twice → `Clarify` fallback, provider timeout → pending 503 (no provider fallback, TD-067), idempotent replay.
- [x] The eval in CI passes the M3 parse thresholds on T01–T16, T19, T39–T41 (+ AR/Arabizi variants).
- [x] Server-side p90 measured on the laptop server (re-measured on production in B15). A log scrubber test proves no message text is logged.

## Read first
`06-buddy-ai.md` §1–4, §9–11 · B02 Outcome · `04-backend.md` §4

## Owner involvement
None (the eval is the judge). Optional: add new real messages as cases.

---

## Low-level plan

**Tier: Risky. Expected size: L, 6 work packages, roughly 1,500–2,500 implementation/test lines.** Owner authorized autonomous delivery and at most **10 physical OpenAI requests**, including repair attempts (2026-10-21). No other provider, paid judge or automatic nightly live run. Plans self-approved under PROCESS A6 after independent plan review; independent code review starts at the first working endpoint, with a separate final security review.

### Design decisions
D1. Contract-first `POST /v1/buddy/interpret`, any live authenticated user including guests, message UUIDv7 equals `Idempotency-Key`. Public discriminated intents: FoodLog, Clarify, OutOfScope, Medical, plus WeighIn to preserve T39's multi-intent interpretation (B02 already parses it). Workout remains unsupported until B12. Each intent carries language/script; response carries model/prompt version. No writes/proposals or calculated totals.
D2. B08 bounds every context list/string and total payload. Text ≤1,000 characters. Explicit typed request context includes personal candidates (≤30), memory (≤20), recent entries (≤30), saved meals/open batches/custom exercises (≤20 each), slots (≤12), now/tz, Ramadan and optional active proposal reference. Images are rejected/unsupported until B10. Provider projection excludes request ID, candidate IDs, account/device IDs and nutrition numbers; use ephemeral candidate indexes if needed. No unknown context property pass-through. Strict validation before paid reservation.
D3. New embedded `interpret-v1` prompt/schema, retaining v0 and its offline smoke unchanged. One low-effort GPT-6 Luna Responses call, native strict schema plus local closed-schema/semantic checks; at most one fresh repair call only for invalid output, with a fixed repair instruction (never echo raw output). SDK transport retries disabled; provider failures/timeouts return 503 pending (no fallback under TD-067). Rerank disabled because no evidence justifies another call. Static prefix first, volatile minimized JSON last; `store:false`, no tools/conversations/content telemetry.
D4. Resolve personal name/alias matches from the supplied candidates first (deterministic normalized matching), then Catalog's `IFoodResolver`. Extend Catalog's public contract with read-only complete food details so Buddy never consumes Catalog internals or queries its tables. Return real nutrients, servings, state/source, up to three distinct alternatives and typed ambiguity dimensions (candidate/portion/fat options as applicable). No nutrition arithmetic on the server; original amount/share/time/slot hints remain parser facts, client resolves policy and computes. Do not silently choose a wrong cooking state; when an exact-state search misses, include other-state candidates and a state dimension for A21 yield handling.
D5. Estimates are a separately identified nullable model range in the internal grammar, validated and **exposed only when personal/catalog resolution is empty**, with fixed reason/badge metadata. Model nutrients never override a real match. No unbadged guessed nutrition. Missing/invalid estimate becomes Clarify rather than a fabricated match. Reference dish source/ranges remain catalog facts.
D6. Paid-call idempotency uses a Buddy-owned durable attempt ledger, **not** the S04 transaction-only replay middleware: an external charge cannot roll back with Postgres. Claim `(user,messageId)` and fingerprint before any network call; concurrent/replayed messages never launch a second pipeline. Successful response replays for 24 hours; changed input conflicts. In-flight/crashed/unknown calls return pending 503 and are never retried for that key within retention. This favors no double billing over automatic recovery after an ambiguous charge. Failed keys likewise remain pending; app retains message/manual path (AI-153). Request text/context never persisted; only fingerprint, response and content-free status. Expired rows removed by per-user scheduled jobs; erasure deletes ledger atomically. Lifecycle/recovery locks and live-session checks on claim and completion prevent late resurrection after deletion; no database lock held during provider I/O.
D7. Minimal Usage module owns per-user UTC-day/model counters (calls, tokens, estimated cost), with RLS and eraser. Buddy calls its small Contracts port in the same transaction as result accounting; replay does not increment. Provider metadata remains content-free. Known token usage recorded for both valid/invalid attempts. Ambiguous transport/crash charges cannot be reconstructed and are explicitly not invoice-grade. Per-user daily hard operational ceilings plus guest tighter ceiling enforced transactionally before each pipeline; no R2 commercial allowance. Concurrency bounded globally, timeout bounded; authentication and host IP limit remain.
D8. Offline public-endpoint integration/eval covers T01–T16, T19, T39–T41, with ≥¼ Arabic/Arabizi variants, recorded synthetic provider fixtures and exact deterministic parse/resolution graders. CI never loads a key. Report parse-only thresholds separately from A21's future full proposal/AQ metrics. Live measurement uses a bounded synthetic subset, ≤10 transport sends including repairs, durable local count, no raw content/credentials in reports. Report measured p90 honestly; tiny samples are not production acceptance. Retain failures and improvements in evidence, never weaken assertions to hide them.

### Review amendments
PA1. Fresh GPT-6.1 Sol plan review found two majors, accepted: authorize **every physical dispatch**, including repair, under recovery/lifecycle locks and expected ledger attempt state; reserve quota durably **before dispatch**, not on completion. Deletion/revocation between invalid output and repair must suppress the repair and all late recreation. Concurrent distinct keys, crash-after-reservation and replay must prove ceilings.
PA2. Defaults: low effort, 1,600 output tokens, 20-second per-call timeout, process-wide concurrency 2 (zero-wait rejection before claim); UTC daily physical-send ceiling 100 registered / 30 guest. A repair reserves a second allowance. Configuration validates bounded values. Explicit live budget counter commits before every transport send; no SDK retry, rerank or judge. Failure before dispatch (invalid request, disabled service, saturation) does not claim a message; failures after durable dispatch reservation remain ambiguous/pending. Initial limit rejection consumes no send/claim and may be retried with the same key after the daily boundary. A denied repair follows an already-dispatched call, so returns pending 503 (not 429), keeping the reserved key pending until its 24-hour expiry.
PA3. Reviewer approved the remaining architecture; clarified synthetic fixtures are regression evidence, not measured model-quality acceptance. The stale fallback-provider criterion is corrected to pending 503.

### Files and tests
- `contracts/openapi/modules/buddy.yaml`, root path/tag, bundle and generated Dart client (own commit before server code); API conformance and generated client check.
- Buddy Api/Application/Domain/Infrastructure, v1 prompt/schema, migration/RLS/replay/erasure/cleanup; Catalog Contracts details adapter; Usage module/migration/eraser, Host module catalog/Docker restore list.
- `backend/tests/Buddy.Tests`: closed output/schema, repair once/twice, privacy canaries, resolver precedence/states/alternatives/estimate-only fallback, multi-intent/language.
- `backend/tests/Persistence.Tests`: real public endpoint/auth/validation, durable replay/conflict/concurrent/ambiguous attempt, per-user limits/UTC counts, RLS cross-user isolation, expiry/cleanup, delete-during-call/no resurrection, logs free of private canaries.
- `tools/buddy_eval`, fixture cases/reports and CI eval job: public endpoint fixture regression, EN/AR/Arabizi breakdown, transport-capped live subset.
- Card, board, evidence/B08-verification.md, module/backend/eval guides and dated research note.

### Work packages
1. [x] WP1: plan review, contract + regeneration/handoff commit.
2. [x] WP2: v1 provider/parser + resolver, semantic/privacy tests; early independent code review.
3. [x] WP3: durable paid attempt ledger, Usage, RLS/lifecycle/cleanup/erasers and authenticated endpoint.
4. [x] WP4: public-endpoint fixture eval, integration/concurrency/privacy coverage, CI offline gate.
5. [x] WP5: bounded live smoke/latency, ≤10 physical calls total, inspect and address findings.
6. [x] WP6: full checks/eval, independent whole-diff + separate security review, fixes/rechecks, evidence/Outcome and CI-gated merge.

### Risks and acceptance boundaries
- B02's English cooked-state defect must be exercised explicitly in v1 regression/live cases.
- No provider fallback despite the old card wording: TD-067 is authoritative. No paid broad eval or production-quality claim from ≤10 calls.
- T41 offline queue/reconnect and all question/number policy are app/A21/A23 work; B08 proves replay/pending semantics and parse inputs only.
- Standard provider retention accepted for R1/R2 remains as recorded by TD-067; `store:false` is not ZDR. No new security trade-off or vendor.

## Progress log
- 2026-10-21: Started from clean main `3a52d1a`; B02/B07 dependencies complete. Owner authorized autonomous B08, ≤10 physical OpenAI calls, and an early reviewer. Read working agreement/process/card/backend/AI contracts and inspected existing replay/erasure/catalog seams. Wrote Risky plan; no paid calls yet.

- 2026-10-21: Independent plan review completed (0 blockers, 2 majors addressed in PA1–PA3). Self-approved under PROCESS A6; proceeding contract first. Paid sends: 0/10.

- 2026-10-21 WP1: Added public interpret contract (typed discriminated intents, bounded request context, full food facts/ranges/options, replay/pending semantics) and regenerated Dart client. `make gen`, bundle freshness, Spectral lint and additive breaking gate passed. Contract-only handoff precedes all server implementation; conformance intentionally follows WP3. Paid sends: 0/10.

- 2026-10-21 early WP2 review: Fresh independent GPT-6.1 Sol found two food-resolution majors: preserve stated variant through retrieval/output; choose candidates covering ambiguous states/variants before truncating. Fixing with regressions. Also strengthening dimension options with embedded food facts so fat/portion taps need no network. Contract amendment precedes its server implementation. Paid sends: 0/10.

- 2026-10-21 WP2/WP3: v1 parser/resolver and authenticated ledger/Usage endpoint built. Early review’s three majors fixed with variant/state-diversity and physically bounded estimate regressions. Real HTTP replay/repair/quota/deletion tests pass; RLS, expiry, revocation and UTC-day tests added. Security early pass: 0 blockers/majors; three minor semantics clarified (repair-quota denial is pending 503, unrelated recovery epoch change is 503, only initial quota denial has no claim). Host recovery lease released for external I/O; each transaction rechecks lifecycle and claim generation. Public multilingual runner now passes 26/26 cases after fixing UTF-8 byte writes. Normalizing nullable object refs to the existing contract oneOf style (equivalent null-or-object shape) before final conformance. Paid sends: 0/10.

- 2026-10-21 WP4: Public fixture eval passes 26/26 (10 Arabic/Arabizi), with real HTTP/auth/native SDK/parser/resolver and a Dart grader; added a separate lightweight CI eval gate reusing the dotnet report. Counts distinguish logical messages from physical sends; dispatch-day accounting spans UTC midnight. Added RLS/expiry/crashed-claim/revocation/log-canary tests and a committed v1 schema snapshot. Full `make check test eval` is running before the code checkpoint; no paid calls yet.

- 2026-10-21 review follow-up: Whole-diff review found variant matching still too permissive after fuzzy/Arabic lookup and parse grading too shallow. Added exact stated-percentage/name guards (including personal candidates), wrong-only/correct-match regressions, per-item dimensions/options and explicit/share/time/slot/group/weigh-in graders with negative tests. Added a real provider-timeout→pending/replay and denied-repair regression. Restored the whole .NET solution after introducing Usage; earlier full run’s missing-assembly failures were stale dependency assets, not a CI bypass. Targeted Buddy tests: 39/39; grader negatives: 5/5. Paid sends: 0/10.

- 2026-10-21 WP2–WP4 checkpoint: `make check test eval` passed after full solution restore, including contract conformance, all Dart packages and backend tests; 26/26 strict public endpoint fixtures and CI report gate passed. Recorded provider timeout, repair-quota denial, deletion-in-flight, replay/conflict, UTC rollover, RLS and expiry regressions are green. Personal aliases inside amount phrases now use longest whole-phrase matching before generic catalog retrieval. Independent reviewer rechecked both whole-diff majors: 0 remaining. Code checkpoint pushed before live measurement. Paid sends: 0/10.

- 2026-10-21 WP5 deployment preparation: Added opt-in private phone-server Buddy configuration from the existing owner key, mounted read-only to the API only (no key value in env/argv/git, no worker/migrator access). Configuration/deploy performs no paid probe. Main deployment will follow the CI merge gate; the isolated laptop live smoke is running under the durable 10-send fence.

- 2026-10-21 WP5 initial live measurement: 8/10 physical sends used, all HTTP200; EN/AR/Arabizi cooked chicken regression passed with real matches. Initial p90 5,194ms (small sample, above target; broad AQ/latency remains B15). Live found milk3% versus catalog3.25% and missing prepared-dish estimate fallback. Adjusted numeric variant eligibility to the precision explicitly stated (actual source facts unchanged), added guarded generic-name retry, and instructed v1 to include nullable fallback ranges for prepared dishes before resolution. New regressions keep 1% from matching3% and distinguish 3% from3.0%. Last two calls reserved for T06/T07; original measurements retained. Private operator configuration tests pass (33).

- 2026-10-21 WP5 security recheck found a major in the opt-in live counter: in-place truncate could lose reservations after a crash. Replaced it with a pre-provisioned append-only ledger, strict fail-closed validation and fsync before dispatch; existing8 reservations migrated atomically with file and parent-directory fsync. Six offline exhaustion/reopen/corruption checks pass. No extra paid call made while reviewing the fix.

- 2026-10-21 WP5 complete: exactly10/10 physical sends, all HTTP200, no paid scope remains. Final T07 rerun returns a badged prepared-dish estimate; T06 remains Clarify. Offline catalog inspection identifies why: shipped `Milk, whole` does not carry a verified percentage label, so accepting it would invent variant metadata. Added real-catalog/offline-provider HTTP regression for explicit-percentage Clarify and generic-milk match; catalog follow-up#82. Original failures retained; final ten-sample p90 5,007ms, above target (follow-up#83), not full AQ acceptance. Code and separate security rechecks report0 remaining blockers/majors.

- 2026-10-21 WP6 verification: final whole check passed formatting/analysis/contracts/all Dart suites, then caught one new test-isolation failure: shipped catalog import shared a DB with higher synthetic versions. Isolated that real-release catalog in a scratch database via the existing upgrade-DB helper (no production change); re-running the full backend suite, offline eval and operator checks.

- 2026-10-22 WP6 closeout: all local gates green after isolated-catalog test fix:361 backend tests, all Dart suites (fb_domain100% coverage),26/26 public fixture eval,33 operator tests, format/analysis/build/contracts and offline SDK replay. Independent code and separate security reviews rechecked fixes and evidence:0 remaining blockers/majors. Self-approved under PROCESS A6; all work pushed before CI-gated merge. Private main-image rollout follows only green squash CI, with pre-upgrade backup saved and no paid probe.

## Outcome
Built authenticated Buddy interpretation with contract/generated client, versioned GPT-6 Luna parsing,
real personal/catalog facts and ambiguity options, badged estimate fallback, durable24h replay and
pre-dispatch paid quotas, Usage/RLS/deletion integration, and a strict offline CI eval gate. Private
laptop configuration mounts the existing OpenAI key read-only to the API only. No new vendor,
spec change or TD. WeighIn remains supported from B02 for T39; other feature intents stay in later
steps. No nutrition totals or diary writes are produced.

Actual size: roughly4,900 added backend/harness/operator lines including cases/schema, around
2,400 implementation/test lines; generated API models and OpenAPI excluded. Larger than the
initial estimate mainly because durable dispatch fencing, public endpoint evaluation and full
independent fact assertions required integration coverage.

Fresh GPT-6.1 Sol plan review's2 majors, code review's3 early +2 whole-diff majors, and separate
security review's1 live-counter durability major were fixed and independently rechecked. Final
reviewers report0 blockers/majors. Cheap semantics/evidence minors fixed. No cross-review by
Claude is required for this backend step. Evidence: [B08 verification](evidence/B08-verification.md).

Live budget fully consumed:10 physical sends, all HTTP200. EN/AR/Arabizi cooked-state regression
passes, T07 prepared-dish fallback passes on rerun; original misses remain in the sanitized report.
T06 conservatively clarifies because published milk has no verified percentage label (backlog#82).
Small-sample laptop p90 5,007ms versus initial8 p90 5,194ms; performance follow-up#83 remains for
M3/B15, with no claim of broad AQ or owner-location latency acceptance. New paid tests require
new owner scope. A21/A23 still own policy, proposals, offline queue and confirmation/UI.

Final local gates and CI-controlled merge are recorded in the Progress log/evidence. Rollout
uses the green main archive, retains the pre-upgrade private backup and performs no paid probe.

## B02 handoff (2026-10-16)
OpenAI `gpt-6-luna` only (owner, TD-008/067), no fallback for now. The internal port/schema/prompt and offline harness are ready; there is no public endpoint yet. Three synthetic live calls checked connectivity, not R1 quality: EN cooked-state mismatch, AR/Arabizi pass (backlog #58). B08 must resolve this before production acceptance. Broad eval/ProposalEngine integration remains B08/B15/A21; obtain a new explicit owner budget before further paid tests. Do not infer auth, usage enforcement, repair retries or production routing from the spike.
