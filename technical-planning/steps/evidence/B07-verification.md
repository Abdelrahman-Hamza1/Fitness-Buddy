# B07 verification

2026-10-20, private development laptop; all inputs synthetic or the committed A05 catalog.
No paid services/providers or owner credentials were used for tests.

## Automated acceptance

- `CatalogTests.Every_shared_golden_case_matches_and_is_a_fixed_point` loads all182 cases directly
  from `contracts/testdata/normalization_cases.yaml`; the existing `fb_text` suite loads the same
  bytes. Full Dart run passes with100% fb_text coverage.
- `CatalogTests.Import_search_paging_resolver_publication_and_security_boundaries`: actual Postgres
  and real Host; reviewed synthetic dish/default variant, EN/AR/Arabizi aliases, dedup/paging
  equivalence, query/release cursor mismatch, strict resolver state/kind, search/resolver priority
  equality, guest and registered access, all-route unauthenticated denial, encoded variant key,
  latest/download byte hash and size, read-only app grant, update/retirement/old pack retention,
  active/retired identity and first-version conflicts, rollback and global survival after erasure.
- `CatalogTests.Tampered_draft_unknown_schema_duplicate_and_pack_reuse_are_rejected` and
  `Invalid_records_duplicate_ids_basis_and_references_fail_before_publication`: version/pack
  reuse, tampered bytes, drafts, unsupported schema/path/unknown fields, duplicate stable keys,
  negative nutrients, incomplete ranges, unknown dish and unsupported per100ml basis fail closed.
- `CatalogTests.Full_shipped_release_import_and_warmed_search_latency`: entire current reviewed
  A05 release in an isolated real Postgres database, shared six-query relevance fixture and100
  warmed searches over10 EN/AR/Arabizi/typo probes. This is the current246-food/1216-name catalog,
  not a fabricated future bulk catalog. No reviewed dishes currently ship (TD-074); synthetic
  reviewed dishes cover their path. B14 must remeasure production latency.
- Existing `RecoveryServerTests` explicitly includes all four Catalog routes in stale-generation503
  checks. `IdentityPrivacyTests` now places catalog query/detail canaries through logs, Activities,
  meters, Sentry and database inspection. Account deletion inventory classifies all10 global
  Catalog tables and their actual foreign-key closure.
- `tools/sync_sim/test/catalog_client_test.dart`: the actual generated client preserves arbitrary
  non-UTF8 binary bytes via an offline Dio adapter. Wired into `make test-dotnet`; full Dart CI also
  runs it. The generation adapter is deterministic, one known binary operation only, and fails if
  upstream generator shape changes; generated package files were never hand-edited.
-32 operator Python tests include private read-only import overlay creation/removal on success
  and failure; import runs the existing recovery-fenced migrate role and opens no new port.

## Review

One fresh GPT-6.1 Sol plan review approved with changes (pack identity, all-ID first-version checks,
strict resolver semantics, synthetic dishes and paging equivalence), all incorporated. One fresh
whole-diff code/architecture reviewer found two majors: resolver source ordering and generated
binary UTF8 decoding. Both fixed with regressions; scoped re-review resolved both and found no
new issues. A separate fresh GPT-6.1 Sol security/privacy reviewer found no remaining issues and
suggested all-route auth/recovery tests, which were added. No extra verifier or implementer agents.

## Scope and operational limits

A24 owns Flutter online merge and atomic pack replacement. A07 ranking does not exist yet, so
shared relevance fixtures are a handoff, not a claim of Dart/server ranking parity. B08 consumes
`IFoodResolver`. OFF cache is empty and isolated until B10. Exercise/city schemas import but their
real data awaits A05b. HTTP nutrients currently mean per100g; per100ml release inputs are rejected
until the contract can explicitly represent that basis. Pack bytes remain in Postgres with immutable
versions, avoiding new writable runtime mounts/object-storage services. Retirement leaves stable
food details/servings addressable and old packs downloadable.

Final checks, measurements, exact merge CI and deployment receipts are recorded below at close.

## Final local results

- Initial `make check test`: full Dart suites plus329 backend tests passed. Final post-fix
  `make check-dotnet test-dotnet`:330 passed,0failed/skipped. Generated client/sync harness analysis
  is clean; non-UTF8 byte regression passes. `make gen-check` and conformance pass.
- Measurement:246 foods,1216 names,397312 pack bytes,100 warmed searches, **p95 6.9581ms**.
  Machine-readable local result: gitignored `backend/artifacts/catalog/measurement.json`.
- Final production image `sha256:dd843e2c1cb94216779176387480b6702e22cc927171bd7c2dd4f8240e8be521`:
  UID1654, migrate0/repeat0, worker0, config200, DB-down ready503/live200, stop0s/exit0.
  Engine180869606 bytes; gzipped image archive74495905 bytes (not registry transfer size).
- Same-image synthetic private stack passed identity/sync/deletion/recovery/hardening boundaries;
  protected backup and scratch restore36 module tables (one synthetic probe), state equality,
  scratch dataset rotation, other-user survival and no live provider calls.32 operator tests pass.
- Private local logs: `~/.local/state/b07-full.log`, `b07-final-backend.log`, `b07-final-check.log`,
  `b07-gen-check.log`, `b07-final-dart.log`, `b07-client-smoke.log`, `b07-final-image.log`,
  `b07-phone-smoke.log`, `b07-phone-unit.log`. These are local evidence, never committed secrets.

Exact squash CI is enforced by `tools/scripts/merge-step.sh` before main changes. After green main,
activation/import/backup/scratch-restore results live in the private operator B07 receipt; do not
commit private hostname, credentials, tailnet addresses or account tokens.
