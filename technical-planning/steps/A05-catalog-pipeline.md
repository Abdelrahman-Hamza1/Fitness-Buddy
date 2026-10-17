# A05 — Catalog pipeline & offline pack v1

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A01, A03, A04 | L | Claude | ✅ Done |

_Old ID: S13 (renumbered by TD-063, 2026-10-16)._

**Goal.** A repeatable, CI-validated catalog build that turns the data in `data/` into a versioned release: the offline `catalog.db` bundled in the app now, and the server load files used in B07.

**Spec:** FD-001, FD-002, FD-003, FD-004, FD-010, FD-011, FD-012, FD-023 (pack contents), FD-060, LC-050, LC-051, AT-003 (test harness) · **Decisions:** TD-010, TD-005

## Scope
- **Data sources in the repo:** `data/usda_selection.yaml` (the curated basics list with FDC IDs + EN names, and AR names + Arabizi aliases for basics per FD-004), `data/reference_dishes/*.yaml` (from A04 on), `data/portion_words.yaml` (local portion words with grams per food, FD-003/LC-051), `data/yields.yaml` (FD-060 staples). Exercise and city data (`data/exercises.yaml`, `data/cities.*`) move to **A05b**; pack schema v1 keeps the empty `exercises` and `cities` tables, so A05b adds rows without a schema change.
- **`tools/catalog build`:** validates everything (dish JSON Schema, FD-012 sanity, unique normalized names per language, **ID stability vs the previous release**: IDs never reused or changed), computes reference-dish per-100 g + ranges, assigns `catalog_version`, and emits:
  1. `catalog.db` (read-only SQLite, FTS5 trigram over normalized names in all languages, < 10 MB),
  2. server load files (JSON lines) for B07,
  3. a release manifest (version, checksums, counts).
- **`catalog` CI workflow** (validate + build + size budget + AT-003 check over the dishes present).
- **App:** bundle `catalog.db` as an asset, copy it on first run, attach it read-only, and expose an `OfflineCatalog` data source (lookup by ID, by barcode, FTS query).
- Attribution data (USDA, GeoNames, OFF later) for About.

## Out of scope
- Exercise and city data (A05b, needed before A36 / A41). Search ranking and UI (A07). Server import and pack downloads (B07).

## Fixed by the plan
- Catalog IDs are stable forever. Unreviewed dishes are excluded. OFF data never enters the catalog (`07` §3).

## Decide in the low-level plan
- The ID scheme (prefix + slug vs opaque) and how the stability check stores the previous release.
- How much of the USDA selection is curated now vs grown in D batches.

## Notes from earlier steps
- **From S08:** tune the `SanityCheck` thresholds (one tolerance value in `fb_domain`) on real catalog data. Yield factors feed `YieldConverter` (direct row or inverse, no chaining). Resolve علبة (backlog #26).

## Exit criteria
- [x] `make catalog` builds the pack locally. CI builds it on every `data/` change and fails on a sanity violation, a duplicate name or a changed ID (tests with fixtures).
- [x] `catalog.db` < 10 MB. Counts per kind in the Outcome.
- [x] The app opens the bundled pack. An FTS query for an A04 dish by EN/AR/Arabizi returns it (integration test).
- [x] The AT-003 check runs and reports the dishes present.

## Read first
`07-food-data.md` §1–6 · `steps/dish-batches.md` · `05-data-and-sync.md` §3

## Owner involvement
None (the A04 skim happens in its own batch).

---

## Low-level plan
_Written in Phase B (2026-10-17, wave 1, lane F) by the step-planner. Builds on A03's plan (tool `fb_catalog`, IDs D4, dish format v1 D5, drafts D8, prototype pack D9) and A04's data, and on A01's drift setup and catalog attach point. **Re-check at the start of A05:** A03's Outcome (frozen schema, any format change), A01's Outcome (where the database opens, how the attach hook looks), and the pack size A03 measured._

### 1. Summary
After A05, `make catalog` turns `data/` into one **versioned catalog release** in `build/catalog/`: `catalog.db` (read-only SQLite, FTS5 trigram, < 10 MB), JSON Lines load files for B07 and a manifest with version, checksums and counts. The build validates everything, enforces **ID stability** against a committed append-only lock file, and reports AT-003 coverage. A `catalog` CI job gates every push. The app bundles the pack, installs it on first run, attaches it read-only as `catalog`, and exposes `OfflineCatalog` (by ID, by barcode, FTS query). Pack schema v1 includes empty `exercises` and `cities` tables (their data is A05b).

### 2. Decisions

| # | Decision | Reason / source |
|---|---|---|
| D1 | **ID scheme = A03 D4, extended:** `usda:<slug>`, `ref:<slug>`, `ref:<slug>/<variant>`, `ex:<slug>`, `city:<geonameid>`. A logged catalog food is stored as A06's `FoodRef(kind: catalog, id: <catalog id>, version: <meta.catalog_version>)`. The display badge comes from `foods.source`: `usda` → `database`, `reference` → `reference`. `CatalogFood` exposes `badge` and `packVersion` so A07 fills both. The full ID grammar: `^(usda|ref):<slug>(/<slug>)?$`, `^ex:<slug>$`, `^city:[0-9]+$`, ≤ 64 ASCII chars. Loggable foods are basics and dish **variants**; a dish ID (`ref:maqluba`) is a search/grouping target that resolves to its default variant | Opaque-compatible (A06 can treat it as a string), readable in YAML, decoupled from FDC IDs. GeoNames IDs are already stable |
| D2 | **Stability: committed lock `data/catalog_ids.lock`**, one sorted line per released ID: `<id>\t<kind>\t<first_version>\t<status>` (`kind` = food, dish, variant, exercise, city; `status` = active, retired). `make catalog` appends new released IDs (drafts aren't released, so they can still be renamed). The build fails if: a lock line from the **base** is missing or changed (only active → retired is allowed), a retired ID is back in the data, or a released ID in the data isn't in the lock (stale lock: "run make catalog and commit"). Base = `CATALOG_BASE_REF`, else the merge-base with `origin/main`, on `main` itself `HEAD^` (same pattern as `contract-breaking.sh`); read with `git show <base>:data/catalog_ids.lock` | "IDs never reused or changed" becomes a mechanical check, reviewable in the diff, with no release server needed. Retiring is explicit |
| D3 | **`catalog_version`:** an integer in `data/catalog_release.yaml` with the **content hash** (sha256 over the canonical load files). `make catalog` bumps the version when the hash changes; CI fails if the file is stale. The manifest adds the git commit (not part of the hash). Every pack row carries the version it first appeared in (`07` §2) | Monotonic, deterministic, no manual bump. The checksum of `catalog.db` itself is in the manifest for the download path (A24/B07) |
| D4 | **Curated now vs grown:** R1 ships **curated basics only** (≈ 150–250 from A04, all with AR + Arabizi, `--require-ar` on). Later batches add basics as their dishes need them; A32 fills gaps from dogfooding. No bulk EN-only USDA layer in the offline pack. A wider online set is B07's option, not planned | FD-004 needs Arabic on basics; thousands of SR Legacy descriptions ("Beef, chuck, arm pot roast, …") would crowd search (PR-5). `07` §1's "1–3k" volume is updated at close (A03 D14 records it for the owner) |
| D5 | **Pack schema v1** (`tools/catalog/lib/src/pack/schema.sql`, `meta.schema_version = 1`): `meta(key PK, value)` (schema_version, catalog_version, content_sha256, includes_drafts, attribution JSON) · `foods(id PK, kind, source, source_ref, dish_id, name_en, name_ar, state, basis, kcal, protein_g, carbs_g, fat_g, fiber_g, kcal_low, kcal_high, protein_low, … fiber_high [NULL for basics], extras_json, density_g_per_ml, yield_group, verified, review_status, sanity, catalog_version)` · `dishes(id PK, name_en, name_ar, default_variant_id, catalog_version)` · `names(rowid, target_id, lang ∈ en/ar/arabizi, name, key, is_display)` + index on `key` · `names_fts` (fts5, external content on `names.key`, `tokenize='trigram'`) · `servings(food_id, unit_code, g, ml, range_lo, range_hi, source)` (USDA portions, portion words, dish portions; dish portions are stored on every variant) · `yields(yield_group, from_state, to_state, factor, source)` · `barcodes(code PK, food_id)` (empty in R1, FD-030 path ready) · `exercises(id PK, name_en, type, equipment, primary_muscle, catalog_version)` + their names in `names` · `cities(id PK, name_en, name_ar, country_code, admin1, lat, lon, timezone, population)`. Inserts in ID order, `page_size=4096`, `VACUUM` at the end, `PRAGMA user_version = 1` | One read-only file for everything the phone needs offline (`05` §3). Typed columns for the core five (FD-002); extras as JSON keep the schema small. Exercises share the FTS index |
| D6 | **Server load files** (`build/catalog/release/`): `foods.jsonl`, `dishes.jsonl` (variants, recipes with catalog IDs, portions, ranges, review), `names.jsonl` (raw + normalized key), `servings.jsonl`, `yields.jsonl`, `exercises.jsonl`, `cities.jsonl` (both empty until A05b), `manifest.json` (`catalog_version`, `schema_version`, `content_sha256`, `git_commit`, per file sha256 + count, pack sha256 + bytes, counts per kind, `includes_drafts`). Format documented with JSON Schemas in **`contracts/catalog/`** (`README.md` + `*.schema.json`) and a test that validates every emitted line. **TD candidate** (cross-track contract, B07 imports it) | The B07 importer (Codex) needs a stable, versioned format it can validate. `contracts/` is where both tracks meet. Codex is told through the Progress log (CLAUDE.md) |
| D7 | **`catalog.db` is generated, not committed.** `catalog-pack` writes `apps/mobile/assets/catalog/catalog.db` + `catalog_manifest.json` (gitignored). `make build-android`, `run-dev`, `build-it`, `test-it` and `make setup` depend on a **non-mutating** `catalog-pack` target (validate + build + copy to assets). It never writes `data/` and fails with "run make catalog and commit" when the lock, `catalog_release.yaml` or the fixture SQL are stale. Only an explicit `make catalog` updates the lock and version. App unit/widget tests use a **committed fixture SQL** `apps/mobile/test/fixtures/catalog_fixture.sql`, emitted by `fb_catalog build --emit-sql` from `tools/catalog/test/fixtures/data/` and checked fresh by `catalog-check` | A 3–8 MB binary changing with every data commit would bloat git history by hundreds of MB over R1. Text SQL is diffable and deterministic; tests don't need the real data |
| D8 | **Release builds never include drafts.** Default build = reviewed only. `CATALOG_DRAFTS=1 make catalog` includes drafts for dev runs. `build-android.sh` with `MODE=release` always rebuilds the pack without drafts and fails if the bundled manifest says `includes_drafts: true` | A03 D8 / FD-051 enforced at the one place a shippable APK is made |
| D9 | **Install + attach (app):** `CatalogPackInstaller` (core) never runs inside database open. `currentPackPath()` only returns an **already installed** `<app support>/catalog/catalog-<version>.db` (a file check) or `null`. Install (copy from the asset to a temp name, rename, delete older versions) runs **after the first frame** in the background, then calls A01's `reattachCatalog(path)`. Until then search shows personal foods and history. It reads only the tiny `catalog_manifest.json` asset to know the version (no network, TD rule 3). The installer implements A01's seam `CatalogPackSource.currentPackPath()` (A01 plan D14, `core/db/catalog/`), and A01's `beforeOpen` attaches it as `catalog` (`file:<path>?mode=ro&immutable=1`); the fallback is A01 PA5's separate read-only connection. A24 later swaps packs with A01's `reattachCatalog`. If `meta.schema_version` isn't 1 or the file is broken, the app runs without the pack (search still has personal foods and history) and reports a non-content error | The copy is a few MB once, off the startup path by design. Versioned names prepare A24's atomic swap |
| D10 | **`OfflineCatalog`** in `apps/mobile/lib/core/catalog/` (shared infrastructure: food search A07, barcode A28, Buddy context A21 all use it): `Future<CatalogFood?> byId(String id)`, `Future<CatalogFood?> byBarcode(String code)`, `Future<List<CatalogHit>> search(String query, {int limit = 30})` (normalize with `fb_text`, D9-style FTS from A03, grouped by target; ranking stays A07's), `Future<List<CatalogServing>> servings(String foodId)`, `Future<List<YieldFactor>> yields()` (feeds `fb_domain` `YieldConverter`), `CatalogInfo info()` (version, attribution for About). `CatalogFood` maps to `fb_domain` `Nutrients`, `FoodState`, `FoodMeasures`. Raw drift `customSelect` on the attached schema (no generated drift tables for a foreign file) | Narrow read-only port, nothing writes the pack (single writer applies to user data only). `core/` is where `app_check` allows `drift`/`sqlite3` imports |
| D11 | **CI: a `catalog` job in `ci.yml`**, added to `ci.needs` (the ruleset stays unchanged): `make deps-dart catalog-check` = validate (drafts too) → release build → size budget → stability (D2, `fetch-depth: 0`) → freshness (lock, `catalog_release.yaml`, fixture SQL) → AT-003 report into the job summary; uploads `build/catalog/` as an artifact (30 days). Runs on every push (cheap, ~2 min). The `changes` job's Android regex gains `^data/` and `^tools/catalog/` (the APK bundles the pack) | Same make target locally and in CI (S01 rule). One required check `ci` (S01 A1) |
| D12 | **Size budget:** fail at ≥ 10,000,000 bytes, warn at ≥ 8,000,000, printed with counts per kind | Card: < 10 MB |
| D13 | **Sanity tuning (S08 note):** the build prints the sanity distribution (ok/warn/fail, deviation histogram) over all basics and variants. `SanityTolerance` defaults change **only** if real USDA data shows systematic false fails, with the numbers in the Outcome; single items use `sanity_override` with a reason | One constant, tuned on evidence (S08 D5) |
| D14 | **علبة (backlog #26):** `fb_text` maps علبة/علبه/`can`/`tin` → unit code `can`; `fb_domain` adds `can` to the known food-specific codes (no default grams: a food without a `can` serving gives `UnknownServingUnit`, so the UI or Buddy asks). Grams/ml per food come from `portion_words.yaml` (cola 330 ml, tuna 160 g drained, hummus 400 g). Golden/parser tests added; backlog #26 closed | The word means a different amount per food; per-food data is the FD-003 mechanism |
| D15 | **(A05b)** **Exercises** (`data/exercises.yaml`, ≈ 100, data-curator): `{id: ex:barbell_bench_press, names: {en: [...]}, type: weight_reps\|bodyweight_reps\|duration\|distance_duration, equipment: barbell\|dumbbell\|machine\|cable\|bodyweight\|kettlebell\|band\|other, primary_muscle}`; equipment variants are **separate** entries (WO-002). EN names + aliases only (WO-001). **Re-check with A36's plan** (it may add fields) | WO-001/002. Shares the FTS index and the uniqueness check |
| D16 | **(A05b)** **Cities** (`data/cities.tsv`, generated by `fb_catalog import-cities` from GeoNames `cities1000.zip` + `cities15000.zip`, CC BY 4.0; download date + sha256 in `data/geonames/sources.yaml`; bulk not committed): all PS and JO places from cities1000, region countries (IL, LB, SY, EG, SA, IQ, Gulf, TR) from cities15000, rest of the world with population ≥ 1,000,000. Arabic name from the Arabic-script entry in `alternatenames` for PS/JO when present. Expected ≈ 2–4k rows | LC-033 needs the owner's city and travel; "a few thousand" (`07` §1). The heuristic AR name is display only (English UI) |
| D17 | **AT-003 check** (`fb_catalog coverage`, used by `catalog-check`): for every `data/must_cover.yaml` item: **resolved** (reviewed target found by an EN, an AR and an Arabizi probe in the release pack), **draft** (found only with drafts), **missing**. CI **fails** only if a reviewed item no longer resolves (regression) or a probe points at an unknown ID; missing/draft items are reported. A32 turns "missing = 0" into a hard gate | Card: "the AT-003 check runs and reports the dishes present". AT-003 goes green only after A32 |
| D18 | **Attribution** (`data/attribution.yaml` → `meta.attribution`): USDA FoodData Central (CC0, credit requested), GeoNames (CC BY 4.0, link), "© Open Food Facts contributors" reserved for A28/B10 (OFF never in the pack) | `07` §3, C-5 |

No ⚠️ OWNER item in A05 itself (the D4 volume change is carried by A03 D14). TD candidates: D1–D2 (ID grammar and stability lock, TD-071), D3/D6/D7 (catalog release format, TD-072).

### 3. Design

**3.1 Tool** (`tools/catalog`, from A03): adds `lib/src/release/` (lock D2, version D3, load files D6, manifest), `lib/src/pack/schema.sql` + writer for the full D5 schema (exercise and city tables empty until A05b), `lib/src/data/` loaders for `yields`, `portion_words`, `attribution` (reusing A04's schemas); A05b adds the `exercises` and `cities` loaders and `import-cities` (D16), `--emit-sql` (D7), size budget (D12), sanity report (D13), coverage (D17). Commands: `validate`, `build [--include-drafts] [--out]`, `check --base <ref>`, `coverage`, `import-usda`, `import-cities`, `query`.

**3.2 Data flow.** `data/*` → load + schema → validate (refs, uniqueness per language across foods/dishes/exercises, sanity, `--require-ar` for basics and dishes) → compute (A03 D6) → filter (drafts unless flagged) → canonical records → (a) load files + content hash, (b) `catalog.db`, (c) lock + version update (`make catalog` only, `check` never writes) → manifest.

**3.3 App.** `apps/mobile/pubspec.yaml` declares `assets/catalog/`. `core/catalog/{catalog_pack_installer.dart, offline_catalog.dart, catalog_models.dart, catalog.dart (barrel)}` + a Riverpod provider for `OfflineCatalog` built on A01's database provider. The attach call lives in A01's `core/db` setup; A05 overrides `catalogPackSourceProvider` with the installer (A01 D14) and reads with `customSelect('… FROM catalog.<t>')`.

**3.4 Make.** `catalog` (validate + build + lock/version update + copy to app assets + coverage), `catalog-check` (CI: read-only checks), `catalog-usda` (A03), `catalog-cities` (download + import, local only). Rules kept: OFF never enters the build (no loader for it exists); unreviewed dishes excluded by default and blocked for release APKs (D8); IDs stable (D2); `fb_text`/`fb_domain` do all normalization and math.

### 4. Work packages (sequential; branch `step/A05-catalog-pipeline`)

| WP | Specialist | Content | Files | Done when |
|---|---|---|---|---|
| **WP1** Release build | `flutter-engineer` | D2, D3, D5, D6, D12, D13, D17, D18: full pack schema, load files + JSON Schemas in `contracts/catalog/`, manifest, lock + version, `check`, coverage, sanity report. Bad fixtures for each failure | `tools/catalog/**`, `contracts/catalog/**`, `data/catalog_ids.lock`, `data/catalog_release.yaml`, `data/attribution.yaml`, `Makefile` | §5 tool tests green; `make catalog` builds from A04's data; `make catalog-check` passes on a clean tree |
| **WP2 (now A05b)** Exercises + cities data | `data-curator` (exercises), `flutter-engineer` (`import-cities` + D16 filter) | `data/exercises.yaml` (≈ 100, D15), `data/cities.tsv` + sources | `data/exercises.yaml`, `data/cities.tsv`, `data/geonames/sources.yaml`, `tools/catalog/lib/src/data/**` | Validate green; counts in the report; owner's city present. **Moved to A05b** (`steps/A05b-exercises-cities-data.md`); its low-level plan is this WP2 section with D15/D16 |
| **WP3** علبة + sanity tuning | `flutter-engineer` | D14 parser + domain code, golden/parser tests, `portion_words.yaml` `can` rows; D13 run, tolerance change only with evidence | `packages/fb_text/**`, `packages/fb_domain/**`, `contracts/testdata/normalization_cases.yaml` (if a case is added), `data/portion_words.yaml`, `steps/backlog.md` (#26) | `make check-dart test-dart` green (coverage ≥ 95% kept) |
| **WP4** CI | `platform-engineer` | D11: `catalog` job + `ci.needs`, `changes` regex, artifact upload, job summary; `build-android.sh` drafts guard (D8) and pack dependency (D7) in the Makefile targets | `.github/workflows/ci.yml`, `tools/scripts/build-android.sh`, `Makefile`, `tools/README.md` | CI green on the branch; a pushed scratch commit with a changed ID fails `catalog` (then reverted), evidence in the report |
| **WP5** App bundle + `OfflineCatalog` | `flutter-engineer` | D7, D9, D10: assets, installer, attach via A01's seam, `OfflineCatalog`, fixture SQL, unit tests on the fixture; one Patrol integration test on the real bundled pack | `apps/mobile/lib/core/catalog/**`, `apps/mobile/pubspec.yaml`, `apps/mobile/android/app/src/main/res/xml/{data_extraction_rules,backup_rules}.xml` (exclude `domain="file" path="catalog/"` in every section, if A01 PA4 hasn't already), `apps/mobile/test/core/catalog/**`, `apps/mobile/test/fixtures/catalog_fixture.sql`, `apps/mobile/patrol_test/catalog_test.dart`, `.gitignore` | `make check-dart test-dart` green; `android-it` green with the catalog test |

### 5. Test list
**Tool** (`tools/catalog/test/`)
- `FD-012 a basic that fails sanity fails the build (fixture)` · `warn is reported, not failed` · `sanity_override needs a reason`
- `FD-004 duplicate normalized name across a basic and a dish fails (fixture)` · `basics and dishes without an AR name fail with --require-ar`
- `ID stability: a base lock line missing in head fails` · `an ID whose kind changed fails` · `retired ID back in data fails` · `active → retired passes` · `released ID not in the lock fails as stale` · `drafts are never locked`
- `catalog_version bumps when the content hash changes, not otherwise` · `two builds give identical load files and an identical catalog.db sha256`
- `FD-051 release build has no draft rows and includes_drafts = 0` · `--include-drafts sets 1`
- `FD-001 every food row has EN name, state, basis, core five, source, verified, catalog_version` · `FD-002 extras only when present` · `FD-003 / LC-051 servings carry food-specific grams for loaf/plate/piece/glass/can`
- `FD-060 yields load and every FD-060 staple group has a factor` · `FD-010 source column is usda or reference for every row`
- (A05b) `WO-001 ≈ 100 exercises with EN aliases, searchable` · `WO-002 equipment variants are separate ids` · `LC-033 cities have coordinates and a valid IANA zone`
- `load files validate against contracts/catalog schemas` · `manifest counts and checksums match the files`
- `size budget fails a fixture over the limit (limit injected)` · `AT-003 coverage: resolved / draft / missing classification; a reviewed item that stops resolving fails`
- `OFF data never enters the pack: the loader set has no OFF source and the pack has no source = off row`

**App** (`apps/mobile/test/core/catalog/`, on the fixture SQL)
- `FD-023 search finds a fixture dish by EN, AR and Arabizi` · `short query uses exact key` · `byId returns a variant with Nutrients, FoodState and servings` · `byBarcode returns null on an empty barcode table and the food when present` · `yields feed YieldConverter (FD-060)` · `installer copies once per version, atomically, and removes older versions` · `wrong schema_version → no pack, app keeps working`
- **Patrol** `catalog_test`: `the bundled pack opens and an A04 item resolves by EN, AR and Arabizi` (uses an A04 item that is reviewed; if the owner hasn't skimmed yet, the dev-flavor build uses `CATALOG_DRAFTS=1`, see Risks)

### 6. Exit-criteria mapping

| Exit criterion | Shown by |
|---|---|
| `make catalog` builds locally; CI builds on every `data/` change and fails on sanity, duplicate name, changed ID | WP1 fixture tests; WP4 `catalog` job on every push; scratch-commit failure evidence in the WP4 report |
| `catalog.db` < 10 MB, counts per kind in the Outcome | D12 budget in `catalog-check`; manifest counts copied into the Outcome |
| The app opens the bundled pack; FTS by EN/AR/Arabizi returns an A04 item | Patrol `catalog_test` in `android-it`; fixture unit tests |
| AT-003 check runs and reports | D17 table in the `catalog` job summary and in `make catalog` |

### 7. Risks & unknowns
- **A01 seam** (A01 plan D14: `CatalogPackSource`, `beforeOpen` attach, `reattachCatalog`): A05 relies on it as planned; if A01's WP2 spike changed it (e.g. `mode=ro` not honoured), use A01's recorded fallback (PA5: separate read-only connection). The installer never runs inside database open (D9): `currentPackPath()` is a file check that must resolve without the asset bundle inside the background isolate (path computed on the main isolate and passed in). Re-check at the start.
- **Draft A04 items at integration-test time:** if the owner hasn't skimmed A04 yet, no A04 dish is in the release pack. The Patrol test then targets an A04 **basic** (shipped without a skim) for the EN/AR/Arabizi proof, plus a draft dish via the dev-flavor pack. Owner check, not a blocker.
- **Byte-identical `catalog.db`** across runs depends on fixed insert order and the one bundled SQLite; if it isn't stable, the manifest keeps the pack checksum but determinism tests compare a `.dump` instead.
- **First-run install** (D9) runs after the first frame by design; WP5 measures the copy on the A55 and the time until the pack is attached (search shows personal foods and history until then).
- **B07 format coupling:** Codex builds the importer against `contracts/catalog/`; any later format change bumps `schema_version` and is noted in the Progress log for Codex.
- **GeoNames Arabic names** (A05b) are heuristic (alternatenames has no language tag in the cities files); display only.
- **`build-android` now needs the pack:** every Android build runs the non-mutating `catalog-pack` target first (seconds). CI's `android` job gets the same dependency through the Makefile.

### 8. Size check
**L (~1.85 sessions) after the split:** WP1 0.7, WP3 0.25, WP4 0.3, WP5 0.6. **A05b** (S, ~0.4 session) takes WP2 (exercises + cities data, needed before A36 / A41). Split now per the plan review.

### Plan review (architect, 2026-10-17, wave 1)
- PA1: Depends on A01, A03, A04 (header and board).
- PA2: D1 seam with A06: `FoodRef(kind: catalog, id, version: catalog_version)`, badge from `foods.source`, full ID grammar.
- PA3: D9 install runs after the first frame, never inside database open; `currentPackPath()` is a file check; `0444` dropped; §7 risk updated.
- PA4: D7 `catalog-pack` is a non-mutating target; only `make catalog` updates the lock and version.
- PA5: WP5 files add the backup XMLs excluding `catalog/` in every section.
- PA6: Size L, split now: A05 = WP1, WP3, WP4, WP5; A05b = WP2 (exercises and cities data). Pack schema v1 keeps the empty tables.

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-17: Wave 1 (TD-068): plan written, architect group review approve-with-changes, amendments applied. Plan approved by the orchestrator under TD-037 (no blocking owner item). Next: implementation.
- 2026-10-17: Owner: every A05 part on Sonnet (implementation and review). WP3 (c1b8340): علبة/3elbe/can → `can` unit (backlog #26); sanity tolerance unchanged (16 flagged foods are spices/acids, explained). WP1 (1105761): release build, `data/catalog_ids.lock` (v1, 246 IDs), content-hash `catalog_version`, `make catalog` / non-mutating `catalog-pack` / `catalog-check`; release pack 397 KB (246 basics, 0 dishes: all drafts). **Contract note for Codex (B07):** new additive `contracts/catalog/` (JSON Lines schemas for foods, dishes, names, servings, yields, exercises, cities + manifest; README there) is the catalog release format B07 imports (TD-072). Next: WP4 CI + WP5 app bundle.
- 2026-10-17: WP4 (0c9f325): `catalog` CI job (fetch-depth 0, in `ci.needs`, artifact, summary), Android targets depend on `catalog-pack`, release drafts guard; scratch proof: editing a locked ID → `catalog-check` fails "locked ID usda:allspice_ground changed". WP5 (4185b94): bundled pack, `CatalogPackInstaller` (after first frame, atomic copy, old versions deleted), `OfflineCatalog`, fixture SQL + freshness, Patrol `catalog_test`. Review (Sonnet, owner direction): approve with 8 minor + 4 nit; fixed in efbe84e (fixture freshness in catalog-check, `info()` for About, error reporting by type only, corrupt pack reads as absent); rest to backlog. CI fully green on 4185b94 incl. android-it. Closed under TD-037.

## Outcome
**Built:** release build in `tools/catalog` (pack schema v1, append-only `data/catalog_ids.lock` checked against the merge base, content-hash `catalog_version`, load files + manifest in the new `contracts/catalog/` for B07, attribution) · `make catalog` (updates lock/version, fixture SQL), non-mutating `make catalog-pack`, `make catalog-check` · `catalog` CI job + drafts guard on release builds · علبة/3elbe/can → `can` unit (backlog #26) · app: bundled pack, `CatalogPackInstaller` (after the first frame), read-only attach via A01's seam, `OfflineCatalog` (`byId`, `byBarcode`, `search`, `yieldFactors`, `info`), corrupt or missing pack reads as absent.

**Evidence:** `make check`, `make test-dart` green; CI green on 4185b94 (catalog, dart, android, android-it with `patrol_test/catalog_test.dart`: installs, attaches and finds rice by `rice`, `رز`, `ruz`). Tool tests: ID lock (removed, changed, reused, stale), determinism, size budget, sanity and duplicate-name failures. Scratch proof of the lock in the Progress log.

**Counts (release pack v1, 397,312 bytes, budget 10 MB):** 246 basics, 0 dishes (all 12 refs are drafts until the owner skim), 1,216 names, 198 servings, 12 yield rows, 0 exercises/cities (A05b). Sanity: 230 ok, 13 warn, 3 overridden; tolerance unchanged (the flagged foods are spices and acids). AT-003: 115 must-cover items: 42 basic, 10 draft, 63 missing (dishes deferred, TD-074).

**Deviations:** the A04-dish FTS exit criterion is proven on basics (no reviewed dish exists yet; TD-074) · pack DDL lives in Dart, not a `.sql` file · `density_g_per_ml` always NULL for now · `search` returns `CatalogFood` with servings embedded (D10 named `CatalogHit`) · `deleteSync` in the installer because app_check rule 11 matches `delete(` lexically (documented) · every A05 part ran on Sonnet, including the review (owner direction).

**Follow-ups:** backlog #66–#70.

**Metrics:** planned L (~2.25 sessions), actual ~1 session · 4 WPs (two pairs in parallel), all Sonnet · 1 review round (0 major, 8 minor, 4 nit) · agent tokens ≈ 170k + 43k + 56k + 127k (implementation) + 91k (review) + 62k (fixes).
