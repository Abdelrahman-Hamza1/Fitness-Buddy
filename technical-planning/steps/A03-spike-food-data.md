# A03 — Spike: food data

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | S08 ✅ | M | Claude | ✅ Done |

_Old ID: S11 (renumbered by TD-063, 2026-10-16)._

**Goal.** Prove the food-data strategy (TD-010) before building on it: can USDA basics + our reference dishes + Open Food Facts + label scan cover the owner's real food? Freeze the reference-dish format and measure how long authoring takes.

**Spec:** FD-001, FD-004, FD-031, FD-050, FD-051, AT-003 (feasibility), C-5 · **Decisions:** TD-010

## Scope
- **USDA FDC import prototype** (`tools/catalog`): download the bulk data, select a draft basics list, map nutrients to our model (kcal, P, C, F, fiber + extras), keep FDC IDs.
- **Reference dish format v1:** a JSON Schema for the YAML (`07` §4), validated by the tool.
- **5 dishes end to end:** maqluba, musakhan, falafel sandwich, chicken shawarma arabi, mloukhiyeh with rice. Recipe → per-100 g → portions with ranges → variants, each with ≥ 1 cited source.
- **Prototype `catalog.db`** with FTS5 (trigram) over normalized names, proving T07/T08/T12-style queries find them by EN, AR and Arabizi.
- **OFF coverage measurement (no owner input, TD-064):** a script over the **Open Food Facts data export** (not the rate-limited API) that counts products sold in Palestine, Jordan and Israel, and how many are complete (kcal, P, C, F, fiber). A sample of well-known local brands is checked by name. The real hit rate comes later from the app's on-device counter (A28). Read the export as Parquet (e.g. DuckDB) or as a stream (7 GB laptop); never commit OFF data (ODbL), and record the export date.
- **Time per dish** measured, for planning the dish batches (A04, A17–A19, A30, A32).

## Out of scope
- The production pipeline, CI workflow, full basics list (A05). Server catalog (B07).

## Fixed by the plan
- USDA (CC0) can be merged. OFF stays licence-isolated and is never merged (`07` §3). Unreviewed dishes don't ship.

## Decide in the low-level plan
- USDA dataset choice (Foundation vs SR Legacy vs Survey/FNDDS) for basics.
- How ingredient references in dish YAML point to catalog foods (stable IDs vs slugs).

## Exit criteria
- [x] 5 dishes validate, compute sane per-100 g values (sanity check passes), and resolve by EN, AR and Arabizi in the prototype pack.
- [x] OFF coverage for the region is recorded (product counts, complete %, local-brand sample) → a decision on how central the label-scan path is (`07` §7).
- [x] **TD-010 decided** (accepted or adjusted). The dish format v1 is frozen (JSON Schema committed).
- [x] An authoring time estimate per dish and a revised dish-batch plan are in the Outcome.

## Read first
`07-food-data.md` (all) · `spec/11-foods-and-data-quality.md` §1–6

## Owner involvement
Skim the 5 sample dishes ("does a plate look right?").

---

## Low-level plan
_Written in Phase B (2026-10-17, wave 1, lane F) by the step-planner. Facts checked on 2026-10-17 (sources under §7). A05's plan builds on the format and tool decided here; anything it must re-check after this step's Outcome is marked there._

### 1. Summary
After A03, `tools/catalog` (Dart package `fb_catalog`, pub workspace member) imports a curated USDA selection from the FDC bulk CSVs into a small committed extract, validates reference dishes against a committed **JSON Schema v1**, computes per-100 g values and ranges with `fb_domain`, runs the FD-012 sanity check, and writes a **prototype `catalog.db`** with an FTS5 trigram index over `fb_text` keys. Five dishes exist as `review.status: draft` YAML with cited sources and resolve by EN, AR and Arabizi. A stdlib Python script has measured Open Food Facts coverage for Palestine, Jordan and Israel from the bulk export. The Outcome records TD-010's verdict, time per dish and the revised batch plan.

### 2. Decisions

| # | Decision | Reason / source |
|---|---|---|
| D1 | **USDA datasets: SR Legacy (2018-04, final) is the main source for basics, Foundation Foods (2026-04-30) is used per item where it has the same food with all core five.** FNDDS is not used. Both are read from the **CSV** zips (SR Legacy 6.7 MB zip / 54 MB, Foundation 3.7 MB / 32 MB). Each selection entry names its FDC ID; the dataset follows from the ID | SR Legacy has ~7,800 foods with raw and cooked states, complete proximates and portion weights: what basics need. Foundation is newer analytical data but small (a few hundred foods) and often lacks nutrient 1008 (energy) or fiber. FNDDS is American mixed dishes "as eaten": overlaps with our reference dishes and would compete in search. CSV streams line by line (the SR Legacy JSON is 205 MB, too much for `jsonDecode` with ~1 GB free). CC0: free to merge (FDC site, 2026-10-17) |
| D2 | **Bulk data is never committed.** `tools/scripts/fetch-usda.sh <out-dir>` downloads the two pinned zips from `https://fdc.nal.usda.gov/fdc-datasets/` into a fresh temp dir and checks their sha256 against `data/usda/sources.yaml` (URL, release, download date, sha256, recorded on the first download in WP1). `fb_catalog import-usda` then writes **`data/usda/extract.jsonl`**: only the selected foods (one line per FDC ID, sorted, with the mapped nutrients and FDC portions). The extract is committed (CC0, small) | The catalog build (and CI) is then hermetic and offline. The download only happens when the selection changes (`make catalog-usda`) |
| D3 | **Nutrient mapping** (FDC `nutrient.id`, per 100 g): kcal = 1008, else 2048 (Atwater specific), else 2047 (Atwater general); protein 1003; fat 1004; carbs 1005 (by difference), else 1050 (by summation); fiber 1079. Extras: sugar 2000 or 1063, saturated fat 1258, trans fat 1257, sodium 1093, cholesterol 1253, alcohol 1018. A missing core nutrient fails the import unless the selection entry says `fiber_zero: true` (meat, oil, eggs, where USDA omits fiber) | The core five are required (FD-002). The fallbacks cover Foundation's energy and carb conventions. WP1 verifies every ID against `nutrient.csv` and fails loudly on an unknown one |
| D4 | **Catalog IDs: namespaced slugs**, `^(usda\|ref):[a-z0-9]+(_[a-z0-9]+)*(/[a-z0-9]+(_[a-z0-9]+)*)?$`, max 64 ASCII chars. `usda:<slug>` = a basic from the USDA selection, `ref:<slug>` = a reference item (dish or local single food), `ref:<slug>/<variant>` = a dish variant (the loggable food). **Dish ingredients reference catalog IDs**, never raw FDC IDs (`food: usda:rice_white_long_grain_raw`). The FDC ID is the `source_ref` of a basic, not its identity | Readable in YAML and reviews. Decoupled from FDC (a basic can move from SR Legacy to Foundation without changing its ID). The app treats IDs as **opaque strings** with a separate source kind (A06), so the scheme can grow (`ex:`, `city:` in A05). `07` §4's `ref.maqluba` becomes `ref:maqluba` (doc fix at close). A05 owns the stability rules |
| D5 | **Reference dish format v1** (`data/reference_dishes/<slug>.yaml`, schema `data/schema/reference_dish.v1.schema.json`, **JSON Schema draft-07**): `schema: 1`, `id`, `names` {en, ar, arabizi: non-empty lists, first = display}, `state` (FoodState code, usually `cooked`), `variants[]` {`id`, `default` (exactly one), `names?` (searchable variant names), **either** `recipe[]` {`food`, `grams`, `range?: [lo, hi]`} + `cooked_total_g` + `cooked_total_range?`, **or** `per_100g` {kcal, protein, carbs, fat, fiber, extras?} + `nutrient_source` (for local single foods like Nabulsi cheese or labaneh that aren't recipes)}, `portions` {portion code (`plate`, `sandwich`, `piece`, `bowl`, `loaf`, `glass`, `disc`, `small_plate`, `large_plate`, …): {`g`, `range: [lo, hi]`}, optionally per variant}, `review` {`status: draft\|reviewed`, `reviewed_by: claude-draft\|owner`, `sources` (≥ 1 URL or book), `notes`}, `time_min?` (authoring minutes, A03 and batches) | Covers FD-050 (names, recipe, portions per word, variants, range) and FD-051 (sources, review). The `per_100g` branch is needed by A04 (white cheeses, labaneh, freekeh). Draft-07 is what `json_schema` 5.2.2 (Dart) and the common C# validators support. YAML anchors are allowed for shared recipe parts. Frozen at the end of this step (exit criterion). `review.sources` and `nutrient_source` must not be Open Food Facts (ODbL isolation, `07` §3). The validator rejects any `openfoodfacts.` URL there |
| D6 | **Computation:** per-100 g = Σ(ingredient grams × ingredient per-100 g / 100) / `cooked_total_g` × 100, through `fb_domain` (`Nutrients.scale` / `+`, rounded once at storage precision, TD-048). **Range:** low/high per-100 g from every ingredient at its range low/high (others at typical) and `cooked_total_range` swapped accordingly (more weight → lower density). The pack stores per-100 g typical/low/high; the app multiplies by the portion range (A07/A21). Water-like ingredients aren't listed (the cooked weight already covers them) | One calculation (`07` §6, "reusing fb_domain's nutrition math"). The ingredient-range rule makes "oil varies 40–100 g" computable instead of a guessed ±% |
| D7 | **Sanity:** every basic and every variant runs `SanityCheck` with the default `SanityTolerance`. `fail` fails the build; `warn` is reported. An item may carry `sanity_override: {reason}` (reviewed in the diff). Tuning the thresholds is A05's (one constant, S08 note) | FD-012: failing foods aren't "verified" |
| D8 | **Draft dishes don't ship.** `build` excludes `review.status: draft` by default; `--include-drafts` (dev builds, tests, the AT-003 report) includes them and writes `includes_drafts=1` into the pack's `meta`. All 5 A03 dishes stay **draft** until the owner's skim; flipping to `reviewed` is a one-line follow-up commit per dish | "Unreviewed dishes don't ship" (Fixed by the plan, FD-051) while the owner is asleep. Owner check, not a blocker |
| D9 | **Prototype pack** (`build/catalog/catalog.db`, gitignored): tables `meta`, `foods`, `dishes`, `names`, `servings`, `names_fts` = `fts5(key, content='names', content_rowid='rowid', tokenize='trigram')`. Keys come from `fb_text` `normalizeKey` (TD-050), so the tool, the app and the server normalize identically. Prototype query: normalize → tokens of ≥ 3 chars are OR-ed as quoted FTS phrases, tokens of 1–2 chars do an exact lookup on `names.key`; results grouped by target, ordered by bm25. A05 finalises the schema (its D5); A07 owns ranking | Trigram can't match substrings shorter than 3 characters (رز, ful in "fu"), so short tokens need the exact path. SQLite in `package:sqlite3` 3.x is one bundled build (3.54.0 in 3.7.1) with FTS5 enabled, for both the Dart CLI and Android (build hooks), and the workspace resolves one version for tool and app |
| D10 | **Tool language: Dart** for everything shipped (`tools/catalog`). Dependencies: `fb_domain`, `fb_text` (workspace), `yaml`, `args`, `path`, `crypto` (versions already in the lockfile where possible), `sqlite3: ^3.7.1` (the same constraint as A01 PA6), `json_schema` 5.2.2 (dev-tool only, never in the app) | Same normalization and math as the app by construction. `json_schema` is Workiva's maintained draft-07 validator |
| D11 | **OFF measurement: a one-off stdlib Python script**, not DuckDB. `tools/scripts/off-coverage.sh` streams the official TSV export (`en.openfoodfacts.org.products.csv.gz`, ≈ 0.9 GB gz, tab-separated) through `gzip -dc` into `python3 -I tools/scripts/off_coverage.py` (`csv` with `delimiter='\t'`, `QUOTE_NONE`, raised field size limit). Constant memory, nothing installed, the gz is kept in a temp dir only for its sha256 and deleted. Records the export's `Last-Modified`, download date and sha256. Output is aggregates only, committed as `technical-planning/steps/evidence/A03-off-coverage.md` | The TSV has flat `*_100g` columns; the HF Parquet (`food.parquet`, 7.95 GB) stores nutrients as a nested list and needs a DuckDB install plus remote range reads whose memory use isn't bounded by `memory_limit`. Python + `python3 -I` is already the repo's convention for small scripts. Not shipped code. **Fallback:** DuckDB CLI over `hf://datasets/openfoodfacts/product-database/food.parquet` with only `code, countries_tags, brands_tags, nutriments` projected, `memory_limit='600MB'`, `threads=2` |
| D12 | **What the OFF script counts:** (1) discovery: every `countries_tags` value matching `palest\|jordan\|israel\|west-bank\|gaza`, with counts (the tag spelling is confirmed, not assumed); (2) products per country and for PS ∪ JO; (3) **complete-5** (kcal or kJ/4.184, protein, carbs, fat, fiber all numeric) and **complete-4** (no fiber; FD-033 lets a label scan complete fiber) as counts and %; (4) GS1 prefix split (Jordan 625, Israel 729 vs imported; Palestine's prefix checked in WP5); (5) the **local-product sample**: ≈ 30 specific products well known in West Bank shops (dairy, bread, snacks, drinks, canned goods; Palestinian, Jordanian, Turkish and international, FD-031), listed with a source in `data/sources/off_local_sample.yaml`, matched by brand tag + name words; found / complete-4 / complete-5 per product. **Rule for `07` §7:** if fewer than 40% of the sample is found with complete-4 data, the label scan is the main path and A28 optimises it first; otherwise barcode first, label as the fallback (both are R1 anyway) | The 40% threshold is `07` §7's. The sample is the closest offline proxy for the owner's hit rate until A28's on-device counter |
| D13 | **Time per dish** is measured by the data-curator: `date -u` at the start and end of each dish (research, YAML, validate-fix loop), written into the dish's `time_min` and the WP report. The Outcome adds the orchestrator's check time and extrapolates the A04/A17–A19/A30/A32 plan | Card exit criterion. `07` §4 assumes 15–25 dishes per session; this checks it |
| D14 | **TD-010 verdict, Orchestrator decision under the spike's mandate (TD-010 is Pending spike, not Accepted); owner FYI:** accept TD-010 with the refinements D1 (SR Legacy + Foundation, no FNDDS), the curated-basics size from A05 D4 (≈ 150–250 curated basics in R1 instead of `07` §1's "1–3k"), and the label-scan centrality from D12. If the measurement suggested a commercial API instead, that would be a new vendor and a hard ⚠️ OWNER stop (not expected) | TD-010 is Pending (not Accepted), so the orchestrator may accept it. The volume change and the OFF verdict are worth the owner's "ok" in the morning; work doesn't wait for it |

### 3. Design

**3.1 Files**
```
tools/catalog/                         package fb_catalog (workspace member, executable `catalog`)
  bin/catalog.dart                     subcommands: import-usda, validate, build, query, coverage
  lib/src/usda/csv_reader.dart         streaming RFC 4180 reader (quotes, doubled quotes), no dependency
  lib/src/usda/importer.dart           FDC food/food_nutrient/food_portion/nutrient CSVs → extract lines (D2, D3)
  lib/src/model/                       Basic, ReferenceDish, Variant, RecipeItem, Portion, Review (typed, immutable)
  lib/src/load/                        YAML → JSON-like map → schema check (json_schema) → model; error = file:path: message
  lib/src/validate/                    references resolve, one default variant, ranges ordered, ≥ 1 source,
                                       unique normalized names per language (across basics + dishes), sanity (D7)
  lib/src/compute/dish_nutrients.dart  D6, through fb_domain only
  lib/src/pack/pack_writer.dart        prototype DDL (D9), inserts in sorted order, VACUUM
  lib/src/pack/pack_query.dart         D9 prototype query (also used by `coverage`)
  test/…, test/fixtures/               tiny FDC CSVs, good and bad dish files
data/usda_selection.yaml               draft basics: ingredients of the 5 dishes + a few spec basics (≈ 60 entries)
data/usda/sources.yaml                 pinned zips: URL, release, download date, sha256 (D2)
data/usda/extract.jsonl                generated by import-usda, committed
data/schema/reference_dish.v1.schema.json, usda_selection.v1.schema.json
data/reference_dishes/{maqluba,musakhan,falafel_sandwich,chicken_shawarma_arabi,mloukhiyeh_rice}.yaml
data/must_cover.yaml                   every spec/11 §6 item → expected ID (or null) + EN/AR/Arabizi probe queries
data/sources/off_local_sample.yaml     the ≈ 30 local products for D12
data/README.md                         what each file is, how to add a dish, the ID rules (D4)
tools/scripts/fetch-usda.sh, off-coverage.sh, off_coverage.py
Makefile                               catalog-usda (download + import), catalog (validate + build + coverage report), off-coverage
```

**3.2 Selection entry** (`data/usda_selection.yaml`): `{id: usda:rice_white_long_grain_raw, fdc_id: <SR Legacy ID>, state: dry, yield_group: rice, names: {en: [...], ar: [...], arabizi: [...]}, servings: [{unit: cup, g: 185}], fiber_zero?: true, notes?}`. EN display names are short curated names, not USDA descriptions (kept as `source_ref` text). AR/Arabizi are optional in A03 and required from A04 (FD-004); the validator has a `--require-ar` switch that A05 turns on.

**3.3 Rules kept.** No app code changes. Bulk data never committed (D2, D11); OFF data never enters `data/` or the pack (only aggregate counts in the evidence file). Unreviewed dishes don't ship (D8). Normalization and math come from `fb_text`/`fb_domain`, nothing reimplemented.

### 4. Work packages (sequential, one folder; branch `step/A03-food-data-spike`)

| WP | Specialist | Content | Files | Done when |
|---|---|---|---|---|
| **WP1** USDA import | `flutter-engineer` | Package skeleton (workspace entry, analysis, executable). `fetch-usda.sh` (temp dir, sha256 pin, records `sources.yaml` on first run). CSV reader, importer, D3 mapping, unknown-ID failure. Draft selection (≈ 60: rice, bulgur, chicken thigh/breast, lamb, minced beef, onion, cauliflower, eggplant, potato, sumac, olive and vegetable oil, flour, pita/taboon proxy, tahini, chickpeas, garlic, tomato, cucumber, parsley, jute mallow (mloukhiyeh, USDA has it), pickles, garlic sauce ingredients, spices as zero-ish entries if needed). `make catalog-usda` | `tools/catalog/**`, `pubspec.yaml` (workspace), `pubspec.lock`, `data/usda*`, `tools/scripts/fetch-usda.sh`, `Makefile` | `make check-dart test-dart` green; `make catalog-usda` writes a sorted extract with every selected ID; fixture tests for every D3 fallback |
| **WP2** Format v1 + compute | `flutter-engineer` | JSON Schemas (dish + selection), loader with readable errors, semantic validation, D6 compute, D7 sanity, name uniqueness, `validate` command. Fixture dishes good/bad | `tools/catalog/lib/src/{model,load,validate,compute}/**`, `data/schema/**`, tests | Every bad fixture fails with its expected message; good fixture's per-100 g equals a hand calculation |
| **WP3** 5 dishes | `data-curator` | Author the 5 dishes (D5) as **draft**: typical home recipe (whole pot), ≥ 1 cited source (2 when they disagree), variants (maqluba: chicken default + cauliflower + eggplant; others as relevant), cooked weight, portions with ranges per local word, names EN/AR/Arabizi (≥ 3 Arabizi spellings for the T07/T08/T12 dishes), oil notes. Add missing basics to the selection and re-run `make catalog-usda`. Time each dish (D13) | `data/reference_dishes/*.yaml`, `data/usda_selection.yaml`, `data/usda/extract.jsonl` | `catalog validate` green; each dish's `time_min` filled; sanity ok or warn with a note |
| **WP4** Prototype pack + resolution | `flutter-engineer` | `build` (D8, D9), `query`, `coverage` (reads `must_cover.yaml`, reports each item: resolved by EN/AR/Arabizi, reviewed / draft / missing). `data/must_cover.yaml` for the whole spec list. `make catalog` | `tools/catalog/lib/src/pack/**`, `data/must_cover.yaml`, `data/README.md`, `Makefile`, tests | Tests in §5 green; `make catalog` prints the coverage table with the 5 dishes resolved (drafts included in the report) |
| **WP5** OFF coverage | `platform-engineer` (+ `data-curator` for the sample file) | Curator: `off_local_sample.yaml` (≈ 30 products, each with a shop or brand source). Platform: `off-coverage.sh` + `off_coverage.py` (D11, D12), unit test of the Python on a 20-line fixture TSV (`python3 -I -m unittest`), run once on the laptop (check ≥ 2 GB disk first), write the evidence file | `tools/scripts/off-coverage.sh`, `off_coverage.py`, `tools/scripts/testdata/off-coverage/`, `data/sources/off_local_sample.yaml`, `technical-planning/steps/evidence/A03-off-coverage.md`, `Makefile` (`off-coverage`, not in CI) | Evidence file has export date + sha256, discovered tags, counts, complete-4/5 %, prefix split, sample table, and the D12 verdict |

WP5 is independent of WP1–4 and may run first (the 0.9 GB download takes a while). Close (orchestrator): Outcome with TD-010 verdict (D14), time per dish, revised batch plan; `07` §4 example updated to D4/D5; `tools/README.md` row for `catalog/`; `12` TD-010 status.

### 5. Test list
- `FD-002 importer maps FDC nutrient ids to the core five and extras` · `energy falls back 1008 → 2048 → 2047` · `carbs fall back 1005 → 1050` · `missing fiber fails unless fiber_zero` · `unknown nutrient id fails with its id` · `csv reader handles quotes, doubled quotes and commas in fields` · `extract is sorted and deterministic (two runs, same bytes)`
- `FD-050 dish v1 schema accepts the full example and rejects: no names.ar, two default variants, recipe and per_100g together, range lo > hi, empty sources` (one fixture each, message asserted)
- `FD-050 recipe references must resolve to a selection id` · `ID grammar (D4) rejects uppercase, spaces, FDC numbers`
- `FD-050 per-100 g of a fixture dish equals the hand calculation` · `range: ingredient lows/highs give per-100 g low ≤ typical ≤ high` · `per_100g variant passes through unchanged`
- `FD-012 a dish whose numbers fail sanity fails validate; sanity_override with reason passes and is reported`
- `C-5 a dish citing an openfoodfacts URL fails validate`
- `FD-004 duplicate normalized name in one language fails (مقلوبة vs مقلوبه)`
- `FD-051 build excludes draft dishes by default; --include-drafts includes them and sets meta.includes_drafts`
- `FD-020 / AT-003 prototype pack resolves maqluba by "Maqluba", "مقلوبة", "maqlobe" and "ma2lube"` · `T07 "akalt sahen maqlobe 3nd sitti" returns ref:maqluba in the top 5` · `T08 "صحن ملوخية مع رز" returns ref:mloukhiyeh_rice in the top 5` · `T12 "شاورما دجاج عربي" returns ref:chicken_shawarma_arabi` · `short token "رز" matches by exact key` · `falafel sandwich by "falafel", "فلافل", "falafel sandwich"` · `musakhan by EN/AR/Arabizi`
- `coverage report lists every must_cover item as reviewed / draft / missing`
- `off_coverage: fixture TSV gives the expected counts, complete-4/5 and sample matches` (Python unittest)

### 6. Exit-criteria mapping

| Exit criterion | Shown by |
|---|---|
| 5 dishes validate, sane per-100 g, resolve by EN/AR/Arabizi | `make catalog` output (validate + sanity + coverage table) and the FD-020/AT-003 tests in WP4, in CI's `dart` job |
| OFF coverage recorded → label-scan decision | `evidence/A03-off-coverage.md` (D12 verdict), quoted in the Outcome |
| TD-010 decided; dish format v1 frozen | Outcome + `12` TD-010 row (D14); `data/schema/reference_dish.v1.schema.json` committed; `schema: 1` in every dish |
| Authoring time per dish + revised batch plan | `time_min` per dish, Outcome table, revised rows in `steps/dish-batches.md` |

### 7. Risks & unknowns
- **Owner skim pending (owner check, not a blocker):** the 5 dishes are drafts (D8) and don't ship until flipped. Collected in the wave's owner list.
- **USDA gaps** (freekeh, local cheeses, shrak, taboon): use the D5 `per_100g` branch with a cited source, or the closest USDA food with a note. Found gaps go to the Outcome for A04.
- **Trigram limits:** < 3-char tokens (D9 exact path); multi-word Arabic phrases with portion words ("صحن") pull noise. Fine for a prototype; A07 owns ranking.
- **OFF export shape** (column renamed, file moved, tag spelled differently): the discovery pass (D12) catches tags; the script fails on missing columns with their names; fallback D11 DuckDB. Download size checked before starting (~0.9 GB, laptop disk).
- **`sqlite3` build hook** downloads its prebuilt library at build time (CI and laptop need network on first build; cached after). If A01 pins a different `sqlite3`, the workspace resolution unifies it.
- **Arabizi spellings** come from the curator's web research; the owner can add spellings at the skim (every miss becomes a probe query in `must_cover.yaml`).
- **Sources (checked 2026-10-17):** FDC download page (Foundation 2026-04-30, SR Legacy 2018-04, FNDDS 2024-10-31; sizes above) https://fdc.nal.usda.gov/download-datasets/ · FDC licence CC0 1.0 https://fdc.nal.usda.gov/ · OFF data page (TSV ≈ 0.9 GB gz, tab-separated) https://world.openfoodfacts.org/data · OFF Parquet (`food.parquet` 7.95 GB, `countries_tags` list, `nutriments` list of structs) https://huggingface.co/datasets/openfoodfacts/product-database · `sqlite3` 3.7.1 bundles SQLite 3.54.0, default build has `SQLITE_ENABLE_FTS5` https://pub.dev/packages/sqlite3/changelog, https://pub.dev/documentation/sqlite3/latest/topics/hook-topic.html · FTS5 trigram tokenizer (SQLite ≥ 3.34) https://sqlite.org/fts5.html · drift 2.35.2 needs `sqlite3 ^3.4.0`; `sqlite3_flutter_libs` is EOL (0.6.0+eol) https://pub.dev/packages/drift, https://pub.dev/packages/sqlite3_flutter_libs · `json_schema` 5.2.2 (draft-07) https://pub.dev/packages/json_schema. Note for A01: `02` §1 still names `sqlite3_flutter_libs`; with sqlite3 3.x it isn't needed.

### 8. Size check
**M (~1.5 sessions):** WP1 0.3, WP2 0.35, WP3 0.3 (5 dishes), WP4 0.3, WP5 0.2 (mostly download time). No split needed. Natural seam if it runs long: WP5 (OFF) can close as a separate commit at any time.

### Plan review (architect, 2026-10-17, wave 1)
- PA1: D14 is an orchestrator decision under the spike's mandate (TD-010 Pending), owner FYI; the vendor hard-stop sentence stays.
- PA2: D10 `sqlite3: ^3.7.1` (same constraint as A01 PA6).
- PA3: D5 licence isolation (no Open Food Facts in `review.sources` / `nutrient_source`); validator rejects `openfoodfacts.` URLs; test `C-5 …` added.

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-17: Wave 1 (TD-068): plan written, architect group review approve-with-changes, amendments applied. Plan approved by the orchestrator under TD-037 (no blocking owner item). Next: implementation.
- 2026-10-17: WP5 OFF coverage: Palestine ∪ Jordan 1,869 products, complete-4 7.7% (Palestine only 4.9%); sample 24/31 complete-4 (77%, mostly international brands; purely local brands ~2/9) → by D12 barcode first, but the orchestrator keeps label scan equally prominent in A28 and lets the on-device counter decide (evidence/A03-off-coverage.md). WP1 USDA import: 73 basics, extract 36 KB (USDA gaps: sumac, freekeh, taboon, local cheeses, shrak). Next: WP2.
- 2026-10-17: WP2 dish format v1 + validate + compute; TD-074 (owner: basics first, dish batches deferred); WP3 five draft dishes (15–20 min each); WP4 prototype pack (139 KB, FTS5 trigram + exact key), coverage 115 items: 5 draft, 25 basic, 85 missing. Phase D (TD-073): one code review, 1 major (real dishes not checked in CI) + 7 minor + 4 nit, all fixed in 165b209. CI green on b8a1e01. Closed under TD-037.

## Outcome
**Built:** `tools/catalog` (`fb_catalog`): USDA import (SR Legacy + Foundation CSVs, sha256-pinned fetch, D3 fallbacks, unknown IDs fail), dish format v1 (JSON Schema + semantic validation, OFF URLs rejected), per-100 g compute through `fb_domain`, FD-012 sanity, prototype `catalog.db` (FTS5 trigram over `fb_text` keys + exact key for short tokens like رز, drafts excluded by default, deterministic), `query`, must-cover `coverage`. Data: 73 basics (`data/usda_selection.yaml`, `data/usda/extract.jsonl`, 36 KB), 5 draft dishes, `data/must_cover.yaml` (115 items). OFF coverage script + evidence.

**Evidence:** `make check`, `make test-dart` (catalog 71 tests), `make catalog` green; `real_data_test.dart` keeps the real dishes in CI: T07 "akalt sahen maqlobe 3nd sitti" → `ref:maqluba`, T08 "صحن ملوخية مع رز" → `ref:mloukhiyeh_rice`, T12 "شاورما دجاج عربي" → `ref:chicken_shawarma_arabi`, each #1, plus EN/AR/Arabizi for all five. OFF: `evidence/A03-off-coverage.md`.

**TD-010 verdict: accepted with refinements.** USDA SR Legacy (+ Foundation where complete) for basics; ≈ 150–250 curated basics in R1 instead of `07` §1's 1–3k. OFF (export 2026-10-16): Palestine ∪ Jordan 1,869 products, only 7.7% with kcal/P/C/F (Palestine alone 4.9%); the 31-product sample passes the D12 rule (77%) but only through international brands, purely local brands ~2/9 → **label scan stays as prominent as barcode scan in A28**; the on-device counter decides later. USDA gaps: sumac, freekeh, taboon, local cheeses, shrak (A04 handles them with cited `per_100g` entries or proxies).

**Dish format v1 frozen** (`data/schema/reference_dish.v1.schema.json`). **Authoring time:** 15–20 min per dish including research (5 dishes ≈ 85 min). **Revised batch plan:** TD-074 (owner) defers the dish batches to after A41; at ~20 min per dish a batch of 12–15 dishes is one session.

**Per-100 g (default variants, drafts):** maqluba 192 kcal · musakhan 308 · falafel sandwich 235 · shawarma arabi 240 · mloukhiyeh with rice 133. Main uncertainty: retained oil (no source gives it) and plate sizes; owner skim pending (deferred with the batches).

**Deviations:** OFF via a stdlib Python script (D11) · digit-only slugs rejected (stricter than D4) · `ref:mloukhiyeh_rice` instead of `…_with_rice` · `VACUUM` not run (the build is deterministic without it) · falafel pieces modelled as a variant of the sandwich (revisit at A18).

**Follow-ups (A04/A05):** basics gaps (freekeh, pasta, fish, ghee, fruit, nuts; raw jute fiber); spice sanity thresholds (6 warnings, 2 overrides); merge the two selection loaders; tracked `.pyc` removed and `__pycache__/` ignored.

**Metrics:** planned M (~1.5 sessions), actual ~1.2 · 5 WPs (two pairs in parallel) · 1 review round (1 major, 7 minor, 4 nit) · tests: catalog package 71, OFF script 4.
