# S13 — Catalog pipeline & offline pack v1

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P1 Manual tracker | S11, D1 | M | ⬜ Not started |

**Goal.** A repeatable, CI-validated catalog build that turns the data in `data/` into a versioned release: the offline `catalog.db` bundled in the app now, and the server load files used in S30.

**Spec:** FD-001, FD-002, FD-003, FD-004, FD-010, FD-011, FD-012, FD-023 (pack contents), FD-060, LC-050, LC-051, LC-033 (city data), WO-001, WO-002 (exercise data), AT-003 (test harness) · **Decisions:** TD-010, TD-005

## Scope
- **Data sources in the repo:** `data/usda_selection.yaml` (the curated basics list with FDC IDs + EN names, and AR names + Arabizi aliases for basics per FD-004), `data/reference_dishes/*.yaml` (from D1 on), `data/portion_words.yaml` (local portion words with grams per food, FD-003/LC-051), `data/yields.yaml` (FD-060 staples), `data/exercises.yaml` (≈ 100 exercises with types, equipment variants, EN aliases), `data/cities.yaml` (a GeoNames subset: Palestine, Jordan, region + major world cities, with coordinates and time zones).
- **`tools/catalog build`:** validates everything (dish JSON Schema, FD-012 sanity, unique normalized names per language, **ID stability vs the previous release**: IDs never reused or changed), computes reference-dish per-100 g + ranges, assigns `catalog_version`, and emits:
  1. `catalog.db` (read-only SQLite, FTS5 trigram over normalized names in all languages, < 10 MB),
  2. server load files (JSON lines) for S30,
  3. a release manifest (version, checksums, counts).
- **`catalog` CI workflow** (validate + build + size budget + AT-003 check over the dishes present).
- **App:** bundle `catalog.db` as an asset, copy it on first run, attach it read-only, and expose an `OfflineCatalog` data source (lookup by ID, by barcode, FTS query).
- Attribution data (USDA, GeoNames, OFF later) for About.

## Out of scope
- Search ranking and UI (S15). Server import and pack downloads (S30).

## Fixed by the plan
- Catalog IDs are stable forever. Unreviewed dishes are excluded. OFF data never enters the catalog (`07` §3).

## Decide in the low-level plan
- The ID scheme (prefix + slug vs opaque) and how the stability check stores the previous release.
- How much of the USDA selection is curated now vs grown in D batches.

## Notes from earlier steps
- **From S08:** tune the `SanityCheck` thresholds (one tolerance value in `fb_domain`) on real catalog data. Yield factors feed `YieldConverter` (direct row or inverse, no chaining). Resolve علبة (backlog #26).

## Exit criteria
- [ ] `make catalog` builds the pack locally. CI builds it on every `data/` change and fails on a sanity violation, a duplicate name or a changed ID (tests with fixtures).
- [ ] `catalog.db` < 10 MB. Counts per kind in the Outcome.
- [ ] The app opens the bundled pack. An FTS query for a D1 dish by EN/AR/Arabizi returns it (integration test).
- [ ] The AT-003 check runs and reports the dishes present.

## Read first
`07-food-data.md` §1–6 · `steps/D-reference-dish-batches.md` · `05-data-and-sync.md` §3

## Owner involvement
None (D1 skim happens in its own batch).

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
