# B07 — Catalog service & online search

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B04, **A05** | M | Codex | ⬜ Not started |

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
- [ ] The golden normalization file passes in **both** test suites in CI.
- [ ] Search p95 < 150 ms server time on the laptop server with the full catalog (re-checked on production in B14). Relevance fixtures pass (query → expected top results).
- [ ] Contract conformance green; the Dart client regenerated (A24 builds on it).
- [ ] Publishing a new release makes `packs/latest` return it with a correct checksum (integration test).

## Read first
`07-food-data.md` §5–6 · `04-backend.md` §3 · A05 Outcome

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
