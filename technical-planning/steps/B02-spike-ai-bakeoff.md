# B02 — OpenAI interpretation spike & eval harness v0

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | S03 ✅, S08 ✅ | L | Codex | ✅ Done |

_Old ID: S10 (renumbered by TD-063, 2026-10-16)._

**Goal.** Build the Buddy parsing foundation using the owner's chosen **OpenAI GPT-6 Luna** (`gpt-6-luna`), with a small, offline-first eval harness. This is an integration spike, not a provider comparison or R1 AI-quality sign-off (TD-067).

**Spec:** AI-010, AI-016, AI-015, AI-070, AI-153, AC-041; parse-level precursors to AQ-02/03/06/07/11/12. **Decisions:** TD-008, TD-009, TD-035, TD-067, D-080.

## Scope (owner revised, 2026-10-16)
- Buddy module: task-level `ILlmClient` port, OpenAI Responses adapter on Microsoft.Extensions.AI `IChatClient`, structured schema, validation, bounded timeout/output, token/cost accounting and content-free diagnostics.
- Versioned interpret prompt + internal schema: FoodLog (mentions, EN/AR names, explicit amount/unit, state, fat, variant/portion ambiguity, share, time/slot hints), WeighIn, Workout, Clarify and OutOfScope; multiple intents and language/script detection. No nutrition values or database writes.
- Separate local CLI, no HTTP endpoint/public contract or app integration (B08).
- `tools/buddy_eval` v0: **three** synthetic YAML cases (EN/AR/Arabizi), deterministic parse graders, sanitized wire fixtures, Markdown/JSON reports. `make eval` is offline; live execution is explicit, at most three requests per invocation, no retries, no model judge.
- Report measured live smoke observations honestly; three samples cannot establish quality percentages, latency percentiles or AQ compliance. B08/B15 retain broader quality work.

## Out of scope
Other providers/models and fallback, 60-case bake-off, catalog resolution (B07/B08), ProposalEngine (A21), public interpret contract (B08), vision (B10), production usage budgets/auth/idempotency (B08).

## Exit criteria (revised by owner)
- [x] OpenAI adapter passes offline contract/failure/privacy tests through the real SDK and `IChatClient`.
- [x] `make eval` grades the three synthetic fixture cases and writes clearly labelled offline reports, without a key or external API traffic.
- [x] An explicit live smoke command makes at most three small requests, reports outcomes/tokens/cost/latency, stops on provider/protocol failure and never retries. Any provider access failure is recorded, not bypassed with another model.
- [x] TD-008/067 record owner-selected OpenAI/Luna, no automatic fallback, and the limits of this spike's evidence.
- [x] Prompt v0 and generated internal schema are committed/versioned; strict parsing rejects unknown/nutrition fields and invalid values.

## Read first
`06-buddy-ai.md` (all) · `spec/40-acceptance-criteria.md` §2–3 · `spec/10-ai-assistant.md` §2–3

## Owner involvement
Owner chose OpenAI/Luna and reduced paid testing to a few minor prompts. Key saved outside the repository at `~/.config/fitness-buddy/openai-api-key`, mode 0600 (checked without printing it). No more input needed to implement this revised scope.

---

## Low-level plan

### Design decisions
- **D1:** Preserve TD-035: Microsoft.Extensions.AI.OpenAI 10.10.1 + OpenAI 2.14.0 (MIT, stable, >7 days old). The official Responses client supplies native schema output and low reasoning effort, explicit `store:false`, with SDK retry count zero. No framework, tools, remote endpoint override, conversational history or identity fields. A CLI avoids adding an unauthenticated paid HTTP surface.
- **D2:** Internal immutable records generate the schema using .NET 10 JsonSchemaExporter. All properties required, nullable where appropriate; closed objects and semantic validation after strict deserialization. No catalog IDs/nutrition fields; explicit amounts are interpretation, never nutrient computation. Closed discriminators and shape rules prevent malformed output reaching callers.
- **D3:** Application port returns an explicit success/failure outcome, model/prompt version, elapsed time, token usage and estimated USD. Timeout/cancellation/refusal/incomplete/malformed/rate-limit/provider failures never expose provider exception bodies or content. Application delegates I/O to infrastructure; modules remain internal and architecture-tested.
- **D4:** CLI accepts only known synthetic case IDs for live runs, at most three, sequential. Key loaded in-process from external file only in live mode; fixtures cannot reach the network. No persistent user content; committed fixtures are synthetic. Logs/telemetry contain only allowlisted codes/counts. The production API registers the dark module without loading credentials or mapping endpoints.
- **D5:** Dart runner calls the CLI over JSONL, checks expected intents, canonical-name aliases, amount/unit/state and language/script. Exact numeric comparisons; names normalized lowercase/trim, aliases explicit. Failed checks fail the command; replay is plumbing evidence, not model quality. No changes in Claude's areas.

### Work packages / files / tests
1. **WP0 — plan/research:** revised card/board, TD-067, TD-008 and dated research; owner-approved scope recorded. Self-review against 03/04/09/10: no writes, no public contract, clean layers, identity-free payload and offline CI.
2. **WP1 — Buddy adapter/schema:** `backend/src/Modules/Buddy/{Domain,Application,Infrastructure,Prompts}`, CLI under `backend/tools/BuddySpike`, focused `backend/tests/Buddy.Tests`; solution, central packages, Host catalogue/project and Docker restore list. Offline tests: native request privacy/shape, prompt/schema drift, multi-intent/malformed/unknown/nutrition/refusal/incomplete responses, usage/cost, timeout/cancellation/429/500 and zero retries (AI-010/015/016/070/153, AC-041; 06.9-adapter/09.4-logging/04.3-module-boundaries).
3. **WP2 — eval:** `tools/buddy_eval` cases/fixtures/runner/graders/tests/README/reports, workspace registration and Make targets. Dart tests validate graders and CLI failures; `make eval` in server CI (no key) and locally. Three live calls maximum total in this session, no repair calls; report failures without retry. No unproved percentile/quality claims.
4. **WP3 — independent whole-diff review/security, fixes, verification, close:** agent mandated by AGENTS Review, evidence file, Outcome/board/backlog and affected backend/AI docs. Full `make check test`, gen-check, contract conformance, Docker smoke. Squash/CI gate on exact SHA, fast-forward main, clean/pushed handoff.

### Risks / exit evidence
- Account/model access may fail; one failed call stops live checks. SDK wire tests isolate integration bugs without paid retries.
- Three samples are weak evidence: defer broad quality/performance assessment; no R1 thresholds relaxed. Future task routes only added with their owning step.
- SDK diagnostics may expose content: no content logging/GenAI content instrumentation, sanitized failures and canary tests; `store:false` does not imply provider ZDR.
- SDK pinned versions checked against NuGet metadata/cooldown; build/audit verify compatibility.
- Evidence maps each revised exit to named tests + `make eval` output + live report; review covers secret loading, network boundary, logs and spend controls.

## Progress log
- 2026-10-16 · A/B/WP0: started clean from origin/main ca08708 after B01; read agreement, two-track board/process, S03/S08 outcomes and AI/spec/architecture/privacy rules. Owner chose OpenAI GPT-6 Luna only, saved the key, and requested only a few minor prompts. Scope revised under that explicit authorization (TD-067): three synthetic cases, offline default, ≤3 live calls, no retries/fallback; no public contract change. Plan self-reviewed and approved under TD-037; implementation next.

- 2026-10-16 · C/WP1: Buddy dark module, internal interpretation records/generated closed schema, versioned prompt, OpenAI Responses/IChatClient adapter and isolated JSONL CLI built. Offline SDK tests found and fixed native Completed/null generic finish reason and omitted native strict flag; 24 Buddy cases + six module architecture cases pass (237 .NET total), no warnings. No paid requests yet. CLI bound to three fixed synthetic prompts, no retries/fallback or HTTP surface. Full combined checks in progress; WP2 harness next.

- 2026-10-16 · C/WP2: Dart three-case YAML/fixture harness, exact parse graders, deterministic offline reports, explicit paid command and offline server-CI gate complete. `make eval` 3/3, focused Dart analysis and six harness tests pass. Exactly three live calls used: transport 3/3, parse 2/3 (EN cooked-state check failed; AR/Arabizi pass), 4.959/3.378/3.617 s, estimated total $0.0005437. No more paid calls; #58/B08 carries the cooking-state issue. Whole-root local Dart analyzer hit laptop RAM/swap exhaustion; all local .NET/contract/Dart tests and focused harness analysis pass; full CI remains mandatory before merge.
- 2026-10-16 · D/r1: fresh independent reviewer found 0 blockers, 2 majors (child cleanup on fixture error; unconstrained food units) and 2 minors (Make SDK working directory; stale AI-doc scope/latency claims). Fixed all: preload fixtures, bounded finally cleanup + process regression tests; closed FoodUnit enum + nutrient/unknown/duplicate-property tests; build under backend/global.json; align 06.9–11. Schema regenerated; live report records pre-hardening schema blob and no paid retest. Scoped re-review next, then formal verification/close.

- 2026-10-16 · D/r2: independent reviewer approved fixes at 40d50a2, no open blockers/majors. E: five revised exits verified; 244 .NET cases, six harness tests, all eight Dart workspace suites, strict offline replay, conformance/gen-check and hardened image pass. Real Docker sync regression 50/50 + faults + 5000 rows pass. Full root Dart analysis/tests also passed the branch CI step (local root analyzer had exhausted laptop RAM). Close docs/evidence/board and #58/B08 handoff complete. Preparing CI-verified squash; main moves only after every required job passes on the exact candidate SHA.

## Outcome
_Written 2026-10-16, Phase E._

**Built.** Dark Buddy module with a task-level internal `ILlmClient`, OpenAI Responses adapter over TD-035 `IChatClient`, owner-selected `gpt-6-luna`/low effort, strict generated interpretation schema + semantic validation, embedded prompt v0, bounded timeout/output, safe outcomes/tokens/cost and content-free diagnostics. No nutrition properties, write operations, public endpoint or credentials in ordinary Host startup. Local CLI + `tools/buddy_eval` provide three synthetic scripts, deterministic parse graders, replay and clearly separated live/offline reports. CI runs offline only.

**Owner-directed deviations (TD-067).** One provider/model, no automatic fallback or retry, three short prompts instead of a three-provider/60-case bake-off. B02 is integration evidence, not R1 AI acceptance. TD-035 abstraction/official SDK retained; native Responses options enforce strict output and storage off. Standard provider retention remains, not ZDR. No public API contract changed.

**Evidence.** [Verification](evidence/B02-verification.md), [live smoke](../../tools/buddy_eval/reports/B02-live.md), offline report. **244 .NET cases** (31 Buddy + six module architecture additions), six Dart harness tests; all eight workspace suites pass. Gen-check/conformance and image smoke pass. Local whole-root Dart analyzer crashed under exhausted 7 GB RAM/4 GB swap; focused analysis passed and the full analysis/test step passed on the branch CI runner. The exact squash must have every CI job green before fast-forward.

**Live observations.** Exactly **three** calls, no retries: all returned validated interpretations; AR/Arabizi all checks pass, EN failed only the cooked-state check. Individual elapsed times **4.959 / 3.378 / 3.617 s**; 2602 input + 567 output tokens, no cache hits, **$0.0005437 estimated** total (not billing). No p90, language-quality or proposal-path claim. Subsequent closed-unit hardening was offline-tested only; report preserves initial schema provenance. No further paid calls authorized by this step.

**Review.** Fresh independent whole-diff correctness/design/security review: **two rounds**, 0 blockers, **two majors + two minors**, all fixed; r2 approved. Majors were process cleanup and arbitrary food units; regressions prove fixture preloading/no child, bounded kill/reap, and native/runtime unit restrictions.

**Follow-ups.** #58/B08: English cooked-state mismatch; keep the strict grader, inspect normalization before production acceptance under a new owner-approved paid-test scope. B08/B15/A21 retain broader language/quality/latency and real ProposalEngine evaluation; production auth, usage/routing/repair/idempotency remain B08. B03 laptop test server is next when Tailscale is ready.

**TDs / metrics.** TD-008 owner-selected OpenAI/Luna Accepted; TD-067 records scope and paid-call policy. Original size L, actual M in this session, four packages (WP0–3), two review rounds. Image UID 1654, **179259007 bytes**, gzip archive **73909670 bytes**, migrate/repeat/worker exit 0, DB-down ready503/live200, stop1s/exit0. B01 regression 50/50 seeds + faults; 5000-row push3083ms/fresh-pull206ms on Docker loopback (not Wi-Fi). No app-owned files changed; client regeneration has no drift.
