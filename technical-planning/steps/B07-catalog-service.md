# B07 — Catalog service & online search

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B04, **A05** | M | Codex | ✅ Done |

_Old ID: S30 server part (renumbered by TD-063, 2026-10-16)._

**Goal.** The server-side food catalog: imported from the catalog release, searchable online with the same normalization as the phone, serving offline pack updates, and exposing the resolver interface Buddy needs.

**Spec:** FD-020 (online full search), FD-021, FD-023 (pack updates), FD-011, LC-050 · **Decisions:** TD-010, TD-030

## Scope
- **Schema `catalog`:** foods, names/aliases per language (raw + normalized), servings, portion words, yields, reference dishes (+ variants, portions, ranges), exercises, cities, pack releases, `off_cache` (created now, used in B10, licence-isolated).
- **`catalog import` command:** loads a release from `tools/catalog` output, idempotent, keyed by stable IDs. Run by hand (or `make`) on the laptop server; by the deploy pipeline once B13/B14 exist.
- **C# normalization** passing **`contracts/testdata/normalization_cases.yaml`** (TD-030).
- **`GET /v1/foods/search`:** `pg_trgm` + alias matching over normalized names, ranking and de-duplication as on the phone (`07` §5.2, minus personal data), cursor paging, any authenticated user (anonymous allowed).
- **`GET /v1/foods/{id}`** and **`GET /v1/catalog/packs/latest`** (version, URL, checksum, size).
- **Pack publishing:** until production, the laptop server serves each release's `catalog.db` itself (behind the same `packs/latest` contract); object storage with a signed or static URL comes with B13/B14.
- **`IFoodResolver`** public interface for the Buddy module: resolve a mention (canonical EN name, AR name, state, kind) → top candidates with scores.

## Out of scope
- The app side: online search merge and pack updates (A24). Barcode/OFF (B10). Buddy's use of the resolver (B08).

## Fixed by the plan
- One normalization spec, two implementations (TD-030). Stable IDs.

## Decide in the low-level plan
- Index design (GIN trigram on normalized names, and per-language columns vs one alias table).
- How search ranking weights are shared or kept in sync with the Dart ranking (a shared fixture file of query → expected order).

## Notes from earlier steps
- **From S08:** C# normalization implements `contracts/testdata/README.md` exactly with explicit tables (no `FormD`, no `ToLower`/culture APIs) and must pass every case in `normalization_cases.yaml` (TD-030, TD-050).

## Exit criteria
- [x] The golden normalization file passes in **both** test suites in CI.
- [x] Search p95 < 150 ms server time on the laptop server with the full catalog (re-checked on production in B14). Relevance fixtures pass (query → expected top results).
- [x] Contract conformance green; the Dart client regenerated (A24 builds on it).
- [x] Publishing a new release makes `packs/latest` return it with a correct checksum (integration test).

## Read first
`07-food-data.md` §5–6 · `04-backend.md` §3 · A05 Outcome

## Owner involvement
None.

---

## Low-level plan
### 1. Approach and budget

Normal code step with a separate security review because authenticated downloads and operator import extend infrastructure exposure. Expected M (five sequential WPs). This session plans and implements; one fresh GPT-6.1 Sol plan review covers the new Catalog module/resolver seam, then one independent whole-diff review and a separate security review. No paid providers, extra implementer agents or milestone verifier.

### 2. Decisions

- Add Catalog with inward layers and explicit module registration. All its tables are global; `off_cache` is separate and empty until B10. Application role has SELECT only, no import capability. Import runs with migrator credentials under the existing recovery maintenance lock, before traffic resumes.
- `catalog import` is an operator Make target using the existing migrate role plus `Catalog:ImportDirectory`, rather than a fourth host role. Input is the A05 build root (`catalog.db` plus `release/`). Strictly validate all embedded `contracts/catalog` schemas, fixed filenames, byte/count/SHA256 and combined content hash; reject drafts, unknown schema, bad references/normalization, oversized releases and version rollback/content reuse. No URL fetching or path from the manifest. Read bounded bytes once, validate then transactionally publish. Same version+hash+pack SHA256/size/schema is a no-op; any conflicting metadata is rejected. Stable retired food IDs remain addressable; retired rows leave search. Every existing active or retired ID preserves kind/source/source_ref and first-appearance catalog_version; identity conflicts are rejected.
- Typed relational food/name/serving indexes plus retained schema-validated JSONB for full release records (dishes, recipes, ranges, yields, exercises, cities). GIN `gin_trgm_ops` on normalized aliases and GIN simple-language text search; one alias table handles all languages. Dish aliases resolve to default variant. Deduplicate by canonical ID then normalized display name+state+source; no personal data/OFF in this step.
- Ranking is explicit deterministic tiers: verified basics before reference dishes, within each source exact > prefix > token > substring > trigram, then score and stable ID. No usage/global-popularity input exists yet. A shared query/order fixture defines backend behavior for A07/A24 to consume; A07 ranking is not implemented yet, so do not claim cross-language ranking parity.
- Cursor is a bounded opaque token bound to release version, normalized query and last ranking tuple; invalid/stale/query-mismatched cursors return400. Reads use a consistent release snapshot. Limit1–50, query1–200 characters, empty normalized query returns an empty page. All catalog routes require any authenticated Identity user (guest allowed), existing recovery/version/rate-limit/client-header gates apply.
- Food detail returns stable ID, provenance/state/version, five per100g nutrients, optional nutrient ranges/extras/density/yield group and servings; no nutrition recomputation. Pack metadata returns version, relative download URL, SHA256, byte size and schema version. Pack download uses a fixed version route, same bearer authorization and gates. Store the <=10MB immutable pack bytes in Postgres in the release transaction: no additional writable mount, object storage or URL/host trust. Old published releases remain downloadable. B13/B14 may move delivery to object storage behind this contract.
- `Catalog.Contracts.IFoodResolver` accepts canonical EN/AR names, state and kind, returns bounded candidates with scores using the same index/normalizer. Supplied state and kind are strict filters, never equivalent raw/cooked guesses. EN/AR result sets union by ID with the best score. Global read-only service, no HTTP or Buddy dependency.

### 3. Work packages

| WP | Changes | Verification |
|---|---|---|
| WP1 contract | Add search/detail/latest/download schemas and paths; regenerate Dart client; shared relevance fixture; contract handoff note | Bundle/lint/generated checks; contract-only commit before code |
| WP2 import | Catalog module/schema, embedded release schemas, strict bounded validator, migrator import, atomic publication/retirement and pack storage; Make operator target | Real Postgres valid/idempotent/update/reject/rollback/permissions tests |
| WP3 search | Explicit-table C# normalization; search/detail/paging, resolver and authenticated routes | Every golden case/fixed point; relevance/aliases/dedup/paging/staleness/resolver/HTTP conformance |
| WP4 operations | Import/publish runbook, laptop operator integration, full-catalog search benchmark; update backup/erasure inventory assumptions for global tables | Full release publication/download SHA256; laptop p95<150ms; image/operator checks relevant to changes |
| WP5 close | Full checks, independent whole-diff and security reviews, cheap fixes/backlog, evidence/Outcome/board; merge via script; activate laptop if safely supported | `make check test`, generated/conformance/architecture and exact merge CI green |

### 4. Test and acceptance details

Use the existing one shared Testcontainers Postgres fixture, no extra concurrent build processes. Build the existing release non-mutating with `make catalog-pack`; exercise importer against it and versioned synthetic fixture mutations. Verify authenticated guest and registered access, anonymous401, no query/food private canaries in telemetry, no arbitrary filesystem/download path, corrupt/missing/tampered release rejected before DB effects, current release unaffected by failure, global data survives account erasure. Synthetic reviewed dishes prove default-variant mapping and strict state/kind behavior; concatenated cursor pages equal unpaged deduplicated order, including aliases and ties. Measure warmed parameterized searches over the entire shipped release on this laptop (record actual counts/size/p95, no fabricated production scale). Both golden suites run in CI. Reviews check every exit criterion and explicitly record any limitations.

## Progress log

- 2026-10-20: Started from clean `main` f307411, fetched origin; B04/A05 dependencies complete. Read working agreement/process/card/release contract. Planned five WPs, no owner gates or paid calls.

## Outcome
**Built:** the global Catalog module/schema with strict idempotent A05 release import, stable identity/first-version protection and retirement; shared C# normalization; authenticated food search/detail and versioned offline pack metadata/binary delivery; `IFoodResolver` for B08; the private laptop import command and runbook. Additive contract and regenerated client are ready for A24.

**Validation:** `make check test` passed all Dart suites and329 backend tests before review fixes. Final `make check-dotnet test-dotnet` passed330 backend tests with no skips, including both regressions and additional invalid-release/identity cases. Post-fix generated client/harness analysis, non-UTF8 binary test, conformance and `make gen-check` passed. All182 normalization cases pass in both suites. Entire shipped release:246 basics,1216 names,198 servings,12 yields,397312-byte pack; reviewed dish/exercise/city counts remain0 (TD-074/A05b).100 warmed parameterized searches: **p95 6.9581ms**, including connection/roundtrip costs, below150ms. Shared six-query relevance probes pass; synthetic reviewed dishes cover default mapping and strict filters.

**Runtime:** final hardened image `sha256:dd843e2c1cb94216779176387480b6702e22cc927171bd7c2dd4f8240e8be521` passed UID1654, repeat migrations, worker, readiness failure/liveness, graceful stop and hardened private-stack tests. Image180869606 bytes, gzip archive74495905 bytes. Private synthetic Production backup/scratch restore passed with36 module tables (includes the synthetic probe), matching recovery state and dataset rotation.32 operator unit tests pass. No paid calls or owner data deletion.

**Review/budget:** actual M; five planned WPs, tightly coupled WP2/3 verified/committed together, operations separate. This session implemented; one fresh GPT-6.1 Sol plan review, one fresh whole-diff code/architecture review plus scoped major-fix recheck, one separate fresh security review. Two code majors (source ranking and binary generator output) fixed with regressions; no remaining blocker/major/minor or security finding. No extra implementer or milestone-verifier agents.

**Decisions/deviations:** no new TD/spec change. Pack bytes live in Postgres for atomic laptop publication; B13/B14 may change delivery behind the same immutable checksum contract. Import is a migrate-role option and Make/controller command, keeping three host roles. Current API nutrients are per100g, so per100ml releases are explicitly rejected pending a representable basis. The A05 content hash uses extensionless table prefixes; consumer README clarified, producer unchanged. Generated-client workaround is a narrow deterministic adapter before retrofit, never a hand edit. Small offline binary test reuses the backend-owned sync harness dependencies.

**Handoffs/follow-ups:** A24 owns app online/local result merge and atomic pack install; A07/A24 consume the shared relevance fixture (Dart ranking parity is not claimed yet). B08 consumes the resolver. OFF remains empty/licence-isolated for B10; real exercises/cities await A05b and dishes follow TD-074. B14 remeasures production latency and plans pack retention/delivery. No owner action required. Exact squash CI gates main; private-laptop activation/receipt follows that merge. See `evidence/B07-verification.md`.

- 2026-10-20: Independent GPT-6.1 Sol plan review approved with changes: immutable pack identity, all-ID/source/first-version checks, strict resolver constraints, synthetic dishes, paging equivalence. Incorporated all before code; self-approved under PROCESS.md A6 (no owner item).

- 2026-10-20: WP1 contract handoff: additive `searchFoods`, `getFood`, `getLatestCatalogPack`, `downloadCatalogPack` and typed nutrients/ranges/servings schemas. Relative authenticated pack URL; bounded version/query cursor semantics. A24 consumes regenerated client.

- 2026-10-20: WP1 follow-up: release source_ref is nullable (A05 schema); preserved that null in HTTP sourceRef before the server implementation commit. Clarified release README hash prefix is the extensionless table name, matching the existing A05 builder bytes; no format change.

- 2026-10-20: WP2 implemented: global Catalog schema and SELECT-only app grants, embedded closed release schemas, bounded hash/count/reference validation, atomic idempotent publication with identity/first-version and pack reuse checks, retirement, operator migrate import. Full current A05 release imported in isolated Postgres. Actual builder content hash prefixes omit `.jsonl`; clarified consumer docs to match unchanged producer.
- 2026-10-20: WP3 implemented: explicit-table normalization passes all shared cases/fixed points; parameterized trigram/token/alias ranking, dedup before release/query-bound keyset paging, strict EN/AR resolver filters, authenticated details/latest/binary. Focused four catalog facts green (real Postgres + HTTP); tested synthetic reviewed dish, repeat/update/failure/retirement, guest and registered access, download digest and account-erasure survival. WP2/WP3 integration is verified together to avoid duplicate fixture/build work; implementation will be committed together after full gates.
- 2026-10-20: WP4 implemented: non-mutating release prerequisite for backend tests, reuse existing Flutter setup in dotnet CI, private one-shot read-only phone import mount, backup inventory includes Catalog, runbook/module docs. 32 operator tests green. Separate fresh GPT-6.1 Sol security review: no remaining findings; added its suggested all-route unauthenticated/recovery rejection coverage. Full checks and code review next.

- 2026-10-20: Independent whole-diff code/architecture review found two majors: resolver re-sorted without source priority, and swagger_parser's binary client decoded SQLite as UTF8. Fixed source-first score/ordering with regression; deterministic narrowly scoped generation adapter emits `Future<List<int>>`/bytes before retrofit, no hand-edited package code. Offline generated-client non-UTF8 regression lives in the existing backend-owned `tools/sync_sim` harness (reuses dependencies, no new workspace package). Reviewer rechecked both fixes and approved with no new findings, subject to final checks/CI. Full initial `make check test` passed329 backend tests and all Dart suites; post-fix focused/catalog client/conformance checks passed. Added explicit stable first-version/retired identity and invalid-record tests before final gate.

- 2026-10-20: Final backend gate green330 tests (0 skipped), including expanded first-version/retired-ID/invalid-input regressions and all-route privacy/recovery coverage. Full release measurement100 warmed searches: p95 6.9581ms,246 foods/1216 names/397312 pack bytes. Scoped generated-client/sync harness analysis and binary test green. Final conformance green; full original Dart suites green.

- 2026-10-20: WP5 local acceptance complete: final330 backend tests, full original Dart suites, generated freshness, conformance, code/security review and hardened image/private synthetic restore green. Outcome/evidence/board written; proceeding only through merge-step.sh exact-commit CI, then private laptop activation.
