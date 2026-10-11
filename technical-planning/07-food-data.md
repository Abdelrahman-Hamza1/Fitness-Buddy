# 07 — Food Data: Sources, Licensing, Catalog & Search

_Food data is half the product (D-011, D-046). This file decides where it comes from, how it's built, and how it's searched. It also satisfies C-5 (licensing is checked in technical planning)._

## 1. What we need (from `11-foods-and-data-quality.md`)

| Need | Volume (R1) | Source |
|---|---|---|
| Generic basics, raw/cooked (rice, chicken, oils, produce…) | ≈ 1–3k items | **USDA FoodData Central** (public domain), curated subset. Arabic names + Arabizi aliases on the basics list (FD-004) |
| Local & mixed dishes with portions (must-cover list) | ≈ 120 dishes, ≈ 200+ variants | **Our own reference dishes** (authored + reviewed, §4) |
| Raw ↔ cooked yield factors (FD-060) | ≈ 20 staples | Published yield tables (USDA), stored in the catalog |
| Local portion words with grams per food (FD-003, LC-051) | per food | Our own data, authored with the dishes |
| Branded / barcoded products (FD-030/031) | open-ended | **Open Food Facts** lookup (cached by the API) → **label scan** → the user's own foods |
| Exercise library (WO-001) | ≈ 100 | Our own list (English names + aliases), shipped in the pack |
| Cities for prayer times (LC-033) | a few thousand | GeoNames cities (CC BY 4.0, attribution in About) |

## 2. Provenance model

Every catalog row has `source` (usda / reference / off / user), `source_ref` (FDC ID, barcode, dish file), `verified`, `catalog_version`. These map directly to the badges ⓓ / ⓡ / ~ / ⓨ (FD-010). The FD-012 sanity check runs at build time for catalog data and at creation time for user data.

## 3. Licensing (C-5)

> Not legal advice. A proper review happens before R3.

| Source | Licence | What it allows | Our obligations / design |
|---|---|---|---|
| USDA FoodData Central | **CC0 1.0** | Any use | Credit "USDA FoodData Central" in About. Free to merge into our catalog |
| Open Food Facts | **ODbL** (database), DbCL (contents), **CC BY-SA** (images) | Commercial use with **attribution** and **share-alike** for adapted databases used publicly | **Keep OFF data isolated** in `catalog.off_cache`, never merged into our own catalog tables. Show "© Open Food Facts contributors" with a link wherever OFF data is displayed. Don't use OFF images. R3 idea: users opt in to contribute label scans back to OFF |
| Our reference dishes | Ours | — | Each YAML file cites the recipe sources used for review (FD-051). We derive numbers and never copy recipe text |
| GeoNames | CC BY 4.0 | Commercial use with attribution | Attribution in About |
| Commercial APIs (FatSecret, Nutritionix, Edamam…) | Per contract, often restricting caching | — | **Not in R1.** Only if the S11 measurement shows OFF + label scan isn't enough. Caching limits would conflict with offline use |

**OFF API rules:** ≈ 15 product reads/min and ≈ 10 searches/min per IP, a custom `User-Agent`, caching encouraged. → All barcode lookups go **through the API**, which caches results in `off_cache` (TTL ≈ 30 days, refreshed on access). The app never calls OFF directly.

## 4. Reference dishes: the authoring pipeline

Reference dishes are **source code for data**: reviewed YAML in the repo, validated by CI, built into the catalog.

```yaml
# data/reference_dishes/maqluba.yaml
id: ref.maqluba
names:
  en: [Maqluba, Maqloubeh]
  ar: [مقلوبة]
  arabizi: [maqlobe, ma2lube, maqloube, makloube]
variants:
  - id: chicken
    default: true
    recipe:                      # typical home recipe, whole pot
      - { food: usda:rice_white_long_grain_raw, grams: 500 }
      - { food: usda:chicken_thigh_raw_bone_in, grams: 1000 }
      - { food: usda:cauliflower_raw, grams: 400 }
      - { food: usda:oil_vegetable, grams: 60 }
      # ...
    cooked_total_g: 2400
  - id: eggplant
    recipe: [...]
portions:                        # cooked grams per portion word
  plate: { g: 400, range: [300, 550] }
  large_plate: { g: 550, range: [450, 700] }
review:
  status: reviewed               # draft | reviewed
  sources: ["<recipe url or book>", "<second source>"]
  reviewed_by: owner             # or claude-draft
  notes: "Oil varies a lot by household; range reflects 40–100 g."
```

- `tools/catalog` computes per-100 g nutrients from the recipe (catalog ingredients + yields), runs the sanity checks, checks that every name is unique after normalization, and fails CI on errors.
- **Ranges** (D-045, AI-032) come from the portion range × recipe variation.
- **Workflow (data batches D1–D6, `steps/D-reference-dish-batches.md`):** Claude drafts a batch with sources → CI validates → the owner skims (D-075: skim, not blocking) → status `reviewed` → shipped as ⓡ. Unreviewed dishes are **excluded** from the build, so Buddy falls back to `~ estimate` for them (FD-051). (TQ-08: the owner may name family recipes to use as the reference.)
- **Throughput target:** ≈ 15–25 dishes per session. The must-cover list takes 6 batches spread over P1–P5.
- **AT-003 check:** a CI test asserts every must-cover item resolves by an English, an Arabic and an Arabizi query.

## 5. Search & matching

### 5.1 Normalization (TD-030: implemented in Dart and C#, one shared spec)

- **Arabic:** strip diacritics (tashkeel) and tatweel; unify alef forms (أ إ آ ٱ → ا); ة → ه; ى → ي; ؤ ئ → ء-forms; Arabic-Indic and Persian digits → ASCII.
- **Latin:** lowercase, strip accents, collapse repeated letters ("chiiicken").
- **Arabizi (R1):** the **curated alias list per food** is the mechanism (FD-020). **R2 (FD-024):** a "skeleton" key for unlisted spellings: digit-letters mapped (2→ء/q, 3→ع, 5→خ, 7→ح, 8→غ/q, 9→ق/ص), vowels dropped, doubled consonants collapsed.
- **Numbers & units** (Dart only, for manual entry and cross-checking the model): EN/AR number words, fractions ("نص", "ربع", "half"), unit words.

The single specification is `contracts/testdata/normalization_cases.yaml`. **Both** `fb_text` (Dart) and the Catalog module (C#) run it in their test suites. Every bug becomes a case.

### 5.2 Ranking & de-duplication (FD-021, PR-5)

Order: **your foods & recent foods → verified catalog → reference dishes → OFF cached products**. Dedup by canonical identity (same catalog ID, or same normalized name + state + brand), so each distinct food appears once. Ties are broken by the user's usage count, then global popularity.

### 5.3 Where search runs

| Path | Engine |
|---|---|
| Offline / instant (FD-023) | SQLite FTS5 (trigram) over the **offline pack** + personal foods + history |
| Online full search (FD-020) | `GET /v1/foods/search` → Catalog module: Postgres `pg_trgm` + full-text over normalized names and aliases. The client merges results, local first |
| Buddy matching | Catalog's `IFoodResolver`, called in process by the Buddy module (same normalization and ranking, plus the model's canonical names) |

Embeddings (`pgvector`) are **not** planned unless the eval shows misses that aliases can't fix.

## 6. Catalog builds & the offline pack

`tools/catalog build` (Dart, reusing `fb_domain`'s nutrition math) produces **one versioned catalog release**:
1. **Server load files** (JSON/CSV) imported into `catalog.*` by the Catalog module's `catalog import` command (S30). The import is idempotent and keyed by stable IDs.
2. **`catalog.db`**: a small read-only SQLite (target < 10 MB) with basics, all reviewed reference dishes, yields, portion words, exercises and cities. It's **bundled in the app** and **published to object storage** with a version and checksum.

The app checks `GET /v1/catalog/packs/latest` in the background, downloads a newer pack, verifies the checksum and swaps it atomically. Diary entries are unaffected (snapshots). **Catalog IDs are stable forever** (never reused), so references from entries, memory and saved meals stay valid.

## 7. Barcode flow (FD-030–033, T17/T18)

```
scan → personal foods by barcode (local) → offline pack by barcode (local)
     → online? GET /v1/foods/barcode/{code}: catalog → off_cache → OFF API (stored in cache)
       → found: product card → amount picker → direct action with undo
       → not found / incomplete: "Scan the label instead" → label flow → personal food linked to barcode
     → offline: queue the lookup as pending (OF-02)
```

**S11 measurement (→ TR-02):** the owner scans ~30 products from their own kitchen. We record the OFF hit rate and data completeness. Below about 40%, the label-scan path is the main experience and gets optimised first (it's already R1).
