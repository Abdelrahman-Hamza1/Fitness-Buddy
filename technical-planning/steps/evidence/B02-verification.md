# B02 verification — OpenAI interpretation spike

Verified 2026-10-16 against code `40d50a2` (docs-only close follows). Revised owner scope: TD-008/067, OpenAI `gpt-6-luna` only, three short synthetic live prompts maximum, no retries/fallback. No spec acceptance threshold has been relaxed.

## Revised exit criteria

| Criterion | Evidence | Result |
|---|---|---|
| OpenAI adapter offline contract/failure/privacy suite | `OpenAIContractTests.Adapter_native_request_and_three_script_responses_obey_port` (EN/AR/Arabizi): real SDK → IChatClient → ILlmClient, native `/v1/responses`, `store:false`, native strict schema, low effort, output cap 1200; exact typed parse/usage/cost. No identity/history/tools/key in request body; canary absent from logs and activity tags. | PASS |
| Failures bounded, content-free, never retried | `Provider_failure_is_content_free_and_never_retried` (401/429/500), `Non_success_model_output_never_escapes_as_interpretation` (malformed/unknown/refusal/incomplete), `Deadline_and_caller_cancellation_are_bounded_and_not_retried`; one transport call maximum. Error bodies are not reported; safe HTTP status only. | PASS |
| `make eval` offline reports, no key/paid traffic | Three hand-authored synthetic fixture responses run through the real .NET SDK/adapter and Dart exact graders; `reports/B02-offline.{md,json}` explicitly distinguish replay from model quality. Offline JSON is deterministic and omits synthetic latency/cost measurements. Six Dart harness tests pass; changed tool analyzes with zero issues. Server CI runs offline mode only. | PASS |
| Explicit live smoke ≤3 calls, outcomes/cost/latency, no retries | `CliBoundaryTests.Unknown_changed_or_duplicate_prompts_stop_before_another_call` and `Three_known_prompts_replay_without_reading_a_key`; unknown/changed/duplicate IDs rejected, unique fixed set has only three prompts. The one authorized live run made three requests, all structurally valid: EN cooked-state check failed, AR/Arabizi passed. Report persisted, no retry, no fallback or further live verification. | PASS (integration observation, not quality sign-off) |
| Owner selection and evidence limits recorded | TD-008/067 Accepted by explicit owner instruction; 06 §§9–11 and B08 handoff align. No automatic fallback. Backlog #58 retains the English state miss and broader evaluation remains B08/B15/A21. | PASS |
| Versioned prompt/generated schema; validation rejects invalid data | `Generated_closed_schema_matches_committed_snapshot`, `Untrusted_output_is_validated_beyond_the_native_provider_schema` (13 variants incl unknown/nutrient unit, null entries, missing fields, duplicates, integer enums, nutrition property), `Multi_intent_weights_workout_and_ambiguity_are_interpretations_only`. Closed FoodUnit enum in native schema and runtime. Domain has no nutrition or write operation. | PASS |

## Review

Fresh independent reviewer `b02_independent_review`, separate from implementation, reviewed the whole base `ca08708` diff plus pending harness changes, correctness/design and security. R1: **0 blockers, 2 majors, 2 minors**. Majors: process left waiting on fixture error, and arbitrary food units accepted. Fixed with preloading + timeout/finally child cleanup + three lifecycle regressions, and closed FoodUnit enum + invalid-unit tests. Minors fixed: build under backend/global.json and remove stale multi-provider/latency/full-runner claims. R2 scoped review at `40d50a2`: **approved**, no open blocker/major; no extra paid testing needed.

Dart process regressions prove missing fixtures start no child (marker), early exit drops diagnostic canary, and hung child is killed/reaped. Reviewer ran read-only inspection; parent owns test evidence.

## Automated gates

- `make check test` on unchanged B01 baseline: PASS (207 .NET cases). After changes, local root `dart analyze` exhausted the 7 GB laptop's RAM and 4 GB swap and the analysis server crashed; this is recorded, not reported as a pass. Focused new-tool analysis passes. Full repository analysis/test step passed on the [branch CI runner](https://github.com/Abdelrahman-Hamza1/Fitness-Buddy/actions/runs/38960008300/job/117172389736); the exact squash still requires every job green before merge.
- Final local `make check-dotnet test-dotnet`: **244 passed, 0 failed/skipped**, zero build warnings/errors (31 Buddy + six architecture cases added versus B01). `make check-contract` including conformance: PASS; public contract/generated API types unchanged.
- Local full `make test-dart`: all eight workspace packages pass, including sync's 1000-seed simulation. New tool: six tests pass. `make eval`: 3/3 replay pass, no key.
- `make gen-check`: PASS, no generated app/client drift.
- `make image-smoke`: PASS, image sha256:cd979c2105bb47436326c243f85955d0273917ad422ef8ca8e2ebd52f03a449a, UID1654, config200, migrate/repeat/worker0, DB-down ready503/live200, stop1s/exit0, 179259007 bytes, gzip archive73909670 bytes. Trace5d2a4747b24a5c82443aae875b18305c.
- B01 Docker sync regression on the new image: PASS, actual partial-body socket drop + ack/retry/crash/concurrent edit faults, 50/50 randomized seeds, 5000 documents independently counted; push3083ms/fresh-pull206ms on loopback.
- Exact squash SHA and required CI: recorded in final handoff/commit status; must be green before main fast-forward.

## Live observations (only these three calls)

| Case | Structural/provider result | Parse | Elapsed ms | Input / cached / output tokens | Estimated USD |
|---|---|---|---:|---|---:|
| en-eggs | success | cooked-state check failed | 4958.7062 | 863 / 0 / 168 | 0.0001703 |
| ar-eggs | success | all checks pass | 3378.1171 | 870 / 0 / 194 | 0.0001840 |
| az-eggs | success | all checks pass | 3616.9468 | 869 / 0 / 205 | 0.0001894 |

Total **$0.0005437 estimated**, 2602 input + 567 output tokens, no cache hits. Standard short-context published rates dated 2026-10-16, not an invoice; reasoning tokens are included in output usage. Single laptop/network, three simple prompts, no model judge, no percentile/quality claim and no end-to-end proposal path. Native food-unit enum hardening followed the smoke and was tested offline only; the live report records the pre-hardening schema blob. No production auth, catalog, per-user usage limit, repair policy, public endpoint or phone integration is claimed.
