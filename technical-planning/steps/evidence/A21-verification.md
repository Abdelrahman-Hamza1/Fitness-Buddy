# A21 verification (2026-10-24)

Tier **Risky** (AI proposals, `PROCESS.md` A.2). Built by Codex across WP1–WP5 and three fix rounds; Claude orchestrates, reviews, commits and owns CI/merge. This records local evidence, not merge approval or device acceptance.

## Exit criteria → evidence → status

| Exit criterion / property | Evidence | Status |
|---|---|---|
| Never more than two questions; idempotent recompute; totals equal lines; remove/re-add restores totals | `packages/fb_domain/test/proposals/`: engine/recompute/property/codec suites; nine generated properties, 1,000 cases each, including multi-card operation streams and restore; lifetime issued budget remains bounded | Met locally |
| T01–T06 and T09/T10 style scenarios | Recorded-format synthetic scenarios, real B08 T06 Clarify separate from verified-milk fixture; explicit/generated oil, raw/cooked yields, defaults, shares, reference/estimate ranges; Buddy real-applier parity | Met locally |
| AQ-04/05/06/07/08/10 scenario rules | Domain scenario/property tests and production-identical `ProposalEval`; B09/M3 owns population thresholds/language breakdowns | Met for A21 scenario scope |
| Six-item recompute ≤50 ms on Samsung A55 | Shared six-line workload and UI-free profile harness; command/protocol in A21 §6 | **Pending owner/Claude device measurement** |
| Read-only load/recompute; confirmation through existing applier | Buddy loader/parity tests: no outbox changes on reads; `readSnapshot` grants no write authority; duplicate confirmation/stale personal versions reject atomically | Met locally |
| Trusted restore, bounded input and content-free issues | Codec requires independent `TrustedFoodFacts`; current personal/installed-pack snapshot verifies source/version/nutrients/measures/yields. Tampering isolates blocked cards; explicit rebuild discards untrusted overrides. Round 3 tests deep message/card JSON, lazy endless cards and cumulative ASCII/non-ASCII/escaped size before copy/encoding | Met locally |
| Independent code/security and app architecture reviews | Findings and dispositions below; round 3 final verification remains with Claude | Fixes implemented; final review pending |

## Tests and gates

Round 2 baseline: focused proposals **127/127**, Buddy **24/24**, full domain **445/445**; domain **4324/4324**, proposals **1825/1825**, loader **125/125** executable lines covered. Round 3: focused proposals **129/129**, Buddy **25/25**, full domain coverage run **447/447**, all with no skips. Coverage: own domain lib **4348/4348**, proposals **1849/1849**, loader **126/126** executable lines (**100%**), including every added production line. These are final totals, not additions to the baseline. Artifacts: `packages/fb_domain/build/coverage/a21-r3-final.lcov`, `apps/mobile/coverage/lcov.info`; logs `/tmp/a21-r3-{proposals,buddy,domain-coverage}.log`.

Final serial gates **PASS** (`check-dart` zero issues; trace 137/319 R1, existing scanner-fixture `ZZ-060` warning only; no generated drift): `make gen-app`, `make catalog-pack`, `make check-dart`, focused domain proposals and Buddy tests, `make trace`, `git diff --check`. Coverage is measured without lowering thresholds or exclusions. **Full `make test-dart` is the CI gate on the merge commit**, not claimed green by this focused run. Docker/.NET/CI, paid calls and device runs are not part of this worker close-out.

Earlier host full-suite runs hit unrelated A08 cold perf (10.947 ms; retry 11.36 ms vs <10) and A07 typing burst (184.397 ms vs <150). Isolated retries passed (A08 5.08 ms cold / 8.94 ms write-visible; A07 136.36 ms). No thresholds or skips were changed. CI on the exact merge commit must supply the full-suite result.

## Performance

WP5 single quiet-host run, pinned Flutter 3.47.7/Dart 3.13.5, Dart JIT/Linux, Intel i5-1035G1, eight logical CPUs, 7,453 MiB RAM; pre-run load 0.32/0.54/0.73. `a21-six-lines-weekly-v1`: **200 warmups, 1,000 samples; median 0.284 ms, p95 0.713 ms, max 8.849 ms; checksum 13201**. Host p95 ≤10 ms passed. Excludes load/JSON/SQL/network/widgets; includes reducer, question allocation, ops/diff and A12 preview. This is historical WP5 evidence, not a round 3 rerun and not an A55 result. A55 engine p95 and A22 rendered-tap/jank evidence remain pending owner/Claude.

## Reviews and trust boundary

- Code: **6 major**; security: **3 major + 1 minor**; app architecture: **2 major + 7 minor**. Accepted findings fixed in rounds 1–2; architecture's A13 seam is an explicit handoff.
- Re-check: **1 new major**, B2 restore robustness; fixed in round 3 with shared preflight before copying/encoding and bounded card enumeration at both public restore entry points. Final re-check belongs to Claude.
- **B1 remains disputed**, not counted as an accepted fix: approved absent-pack embedded backend facts remain eligible. Residual risk: without a pack the wire supplies **no authenticated provenance**; A22/B09 callers must feed the engine only trusted backend responses. Serialized restore facts never establish their own trust. This restriction must survive future caches/imports/eval adapters.
- TD-081–TD-084 remain **Proposed**. No Accepted TD, spec, API shape, persistence table or writer was changed by this close-out.

## Handoffs

A22 owns ARB rendering, save-before-send chat messages, trusted response admission, one assistant budget, selected-card confirmation and follow-up UI; A23 owns proposal persistence/migration, atomic resolution/outcome/message-budget updates and B18 sync consumption. B18 is contract-first bounded opaque envelope admission, not cross-row validation; cards are selected by current `budgetMessageId`, preserving immutable origin and departed-message history. B09 uses the production `ProposalEval` seam and source facts, with new owner scope before any paid calls. A13 owns `targetKcalFor(date, ctx)`; loader reports unavailable targets until that read seam exists. Cooking-fat metadata remains optional/empty until a reviewed catalog manifest emits stable IDs.
