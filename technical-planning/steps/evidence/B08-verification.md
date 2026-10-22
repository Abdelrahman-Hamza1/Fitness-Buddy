# B08 verification

2026-10-21, private development laptop. Automated suites use synthetic inputs and recorded
provider fixtures. Only the separately authorized live smoke uses the owner's existing OpenAI
key, real catalog and real provider; its cumulative transport cap is ten physical sends.

## Acceptance and boundaries

- Contract-first public `POST /v1/buddy/interpret` and regenerated client; actual Host OpenAPI
  conformance is checked by `make contract-conformance` and `Contract.Tests`.
- `BuddyApiTests` exercises real authenticated HTTP, native OpenAI Responses SDK fixtures,
  valid/repair-success/invalid-twice Clarify, provider failure and timeout, pending replay,
  fingerprint conflict, concurrent same-key replay, per-user quotas and rejected-input
  zero-send behavior.
  Deletion while provider I/O is paused cannot resurrect Buddy rows (explicit SQL assertion).
  Usage no-recreation follows the same live-session/lifecycle transaction fence by inspection;
  registered Account deletion integration covers its atomic eraser. A denied repair
  after a dispatch stays pending503; the initial denied reservation is429 with no send.
- `BuddyLedgerTests` uses real Postgres to test crash/restart pending reservations, FORCE RLS,
  response expiry/cleanup, session revocation and UTC dispatch-day accounting.
  Recovery generation checks fence all post-provider writes; no database lock spans provider I/O.
- `ProductionTests` checks the versioned provider schema, context allowlist (no IDs, identity,
  nutrient facts or computed grams), personal-name priority/longest aliases, catalog facts,
  distinct alternatives, state diversity and explicit state/variant preservation. Wrong stated
  fat percentages are rejected even through fuzzy/Arabic retrieval. Numeric precision remains
  explicit:3% may select catalog3.25%;3.0% may not. Catalog facts are never relabelled.
  Only unmatched foods may carry bounded, badged per100g estimate ranges; real
  matches discard model nutrition. Impossible/reversed estimates return Clarify.
- `BuddyPublicEvalTests` runs a real loopback Kestrel/auth endpoint with offline Responses
  fixtures through the Dart public-eval CLI.26/26 cases pass, including10 Arabic/Arabizi cases.
  Independently specified assertions cover amounts/units/states, real matches, dimensions,
  dates/slots/groups, shares, explicitness and weigh-ins. Negative grader tests prove dropped
  or misplaced facts fail; fixtures are regression evidence, not model accuracy estimates.
  The new CI `eval` job validates the same-run report uploaded by `dotnet`; no paid CI.
- `BuddyApiTests` message-text canaries are absent from captured production endpoint logs.
  `ProductionTests` separately checks the allowlisted provider projection. Existing generic
  `TelemetryPrivacyTests` checks Host telemetry scrubbing; it does not exercise the new Buddy
  endpoint. Independent security inspection confirms Buddy Activities/metrics use only fixed
  metadata, without claiming an endpoint-level Activity/metric canary test. Provider requests
  use `store:false`, no tools/state, fixed GPT-6 Luna and no SDK retry/fallback. Server persists only fingerprints, attempt status and
  the24h replay response, plus90-day content-free daily Usage aggregates.
- 33 private operator tests include API-only read-only credential mount, private external key,
  exact overlay shape and exclusion from identity-recovery backups. No key value in env/argv/git.
- `PaidSmokeBudgetTests`: six offline checks prove reopen/exhaustion and malformed/truncated
  ledger refusal. The live transport appends and fsyncs reservations before network dispatch,
  never creates/reinitializes the ledger, and rejects missing/corrupt state. Existing8 sends
  were retained by atomic file replacement with file and parent-directory fsync before final2.

## Independent reviews

Fresh GPT-6.1 Sol plan review required durable pre-send quota reservations and auth checks on
all physical sends, including repair; incorporated before implementation. Fresh independent
whole-diff code review started at the first working endpoint. Its three early majors (variant
loss, state diversity after capping, impossible estimates) and two whole-diff majors (fuzzy
variant bypass, shallow grading) were fixed with regressions and independently rechecked.
A separate fresh GPT-6.1 Sol security review found a major in the opt-in live counter's old
truncate/write durability. Replaced with the append-only fence above; independent recheck
reports0 blockers/0 majors. Minor pending/quota/recovery error semantics were fixed as well.
Final independent exit-criterion recheck found0 code blockers/majors and corrected overbroad
coverage wording in this evidence file. Full final checks and squash CI remain required gates.

## Measurements and limits

Sanitized live evidence is `tools/buddy_eval/reports/B08-live.json`; original failures are kept
alongside reruns. This tiny authorized sample is not broad AQ acceptance. Cooked chicken
passes in English, Arabic and Arabizi against the real catalog. Initial milk3%/catalog3.25%
and prepared-dish fallback misses led to guarded resolver and prompt fixes, then bounded reruns. T07 passed as a badged estimate; T06 still clarifies because the shipped
`Milk, whole` name has no verified percentage label. An offline real-catalog HTTP regression
checks both this conservative Clarify and a generic-milk match; backlog#82 owns catalog metadata.
Exactly10 sends were used; final p90 is5007ms, initial8 p90 was5194ms (backlog#83).
No further paid execution is authorized.
Server p90 is measured on this laptop, including real provider/network time; owner-location
end-to-end M3 and broad150-case AQ acceptance require the app/ProposalEngine and later eval.
No nutrition totals, diary writes, commercial entitlement, image or workout interpretation
are added. A21 owns amount-to-grams/policy/proposals; A23 owns the pending-message UI.
Unknown dispatched results remain pending for24h to prevent accidental duplicate charges.
Known token/cost metrics are operational estimates, not invoice-grade accounting.

## Final gates

Local logs remain private under `~/.local/state/`: `b08-full-check.log`,
`b08-variant-tests.log`, `b08-budget-tests.log`, `b08-phone-check.log`,
`b08-live.log`, `b08-live-recheck.log`. Exact squash CI is enforced by
`tools/scripts/merge-step.sh` before main changes. Deployment uses only a green main archive;
image revision/readiness receipts stay in private operator state, never in git with tailnet data.

Final whole run passed all Dart/static/contract checks and found one catalog test-isolation
failure (synthetic releases already advanced the shared DB version). The real-release regression
now uses an isolated scratch catalog database while retaining actual HTTP/auth/SDK/resolver
integration; the entire backend suite passed after that test-only fix:361 succeeded,0failed/skipped.
Final `make check-dotnet test-dotnet eval phone-server-check` passed; earlier whole run
passed all Dart suites, formatting/analysis and contract checks. Public fixture gate26/26,
operator checks33/33 and offline SDK replay3/3 are green. Private final logs:
`b08-final-check.log` (Dart/static/contracts), `b08-final-backend.log` (final backend/eval/operator).
