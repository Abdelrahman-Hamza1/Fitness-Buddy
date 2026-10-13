# S30 — Catalog service & online search

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P4 Buddy core | S13, S24 | M | ⬜ Not started |

**Goal.** The server-side food catalog: imported from the catalog release, searchable online with the same normalization as the phone, serving offline pack updates, and exposing the resolver interface Buddy needs.

**Spec:** FD-020 (online full search), FD-021, FD-023 (pack updates), FD-011, LC-050 · **Decisions:** TD-010, TD-030

## Scope
- **Schema `catalog`:** foods, names/aliases per language (raw + normalized), servings, portion words, yields, reference dishes (+ variants, portions, ranges), exercises, cities, pack releases, `off_cache` (created now, used in S38, licence-isolated).
- **`catalog import` command:** loads a release from `tools/catalog` output, idempotent, keyed by stable IDs. Run by the deploy pipeline when a new release is published.
- **C# normalization** passing **`contracts/testdata/normalization_cases.yaml`** (TD-030).
- **`GET /v1/foods/search`:** `pg_trgm` + alias matching over normalized names, ranking and de-duplication as on the phone (`07` §5.2, minus personal data), cursor paging, any authenticated user (anonymous allowed).
- **`GET /v1/foods/{id}`** and **`GET /v1/catalog/packs/latest`** (version, URL, checksum, size).
- **Pack publishing:** upload `catalog.db` per release to object storage, with public read via a signed or static URL.
- **`IFoodResolver`** public interface for the Buddy module: resolve a mention (canonical EN name, AR name, state, kind) → top candidates with scores.
- **App:** online search merged with local results (local first, de-duplicated by ID), and **pack update** in the background (download → verify checksum → atomic swap → reattach) per `07` §6.

## Out of scope
- Barcode/OFF (S38). Buddy's use of the resolver (S31).

## Fixed by the plan
- One normalization spec, two implementations (TD-030). Stable IDs.

## Decide in the low-level plan
- Index design (GIN trigram on normalized names, and per-language columns vs one alias table).
- How search ranking weights are shared or kept in sync with the Dart ranking (a shared fixture file of query → expected order).

## Notes from earlier steps
- **From S08:** C# normalization implements `contracts/testdata/README.md` exactly with explicit tables (no `FormD`, no `ToLower`/culture APIs) and must pass every case in `normalization_cases.yaml` (TD-030, TD-050).

## Exit criteria
- [ ] The golden normalization file passes in **both** test suites in CI.
- [ ] Search p95 < 150 ms server time on staging with the full catalog. Relevance fixtures pass (query → expected top results).
- [ ] The app merges online + offline results without duplicates (integration test).
- [ ] Pack update E2E: publish a new release → the app picks it up on next launch, verifies it, swaps it, and diary entries are unaffected.

## Read first
`07-food-data.md` §5–6 · `04-backend.md` §3 · S13 Outcome

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
