# contracts/catalog/

The **catalog release format** (A05, TD-072): what `make catalog` produces for the server importer (B07) and the offline pack in the app. This folder is a meeting point between the app track (which writes the files) and the backend track (which imports them). Changes are additive; a breaking change raises `schema_version` and is noted in the step card's Progress log.

Nothing here is generated or committed output: the files below are the **contract** (JSON Schemas); the data they describe is built from `data/` into `build/catalog/` and is never committed.

| File | What |
|---|---|
| `foods.schema.json` | One line of `foods.jsonl`: a USDA basic or a variant of a reference dish. |
| `dishes.schema.json` | One line of `dishes.jsonl`: a reference dish with its variants, recipes (catalog IDs), portions and review record. |
| `names.schema.json` | One line of `names.jsonl`: a searchable name (raw and normalized `key`) of a food, dish, variant or exercise. |
| `servings.schema.json` | One line of `servings.jsonl`: grams or millilitres of one household unit of a food. |
| `yields.schema.json` | One line of `yields.jsonl`: a cooking yield factor (FD-060). |
| `exercises.schema.json`, `cities.schema.json` | Lines of `exercises.jsonl` and `cities.jsonl`. Filled by A05b. Exercises use six WO-004 type codes; equipment variants are separate IDs. `primary_muscle` and `secondary_muscles` (added by A37a, additive, `schema_version` stays 1) use the muscle vocabulary of `data/schema/exercises.v1.schema.json`; consumers read unknown codes tolerantly, and packs built before A37a have no `secondary_muscles` column and may carry the legacy primaries `back`, `core`, `full_body`. |
| `manifest.schema.json` | `manifest.json`: version, content hash, per-file checksums and counts, pack checksum. |

## The release

`make catalog` (or `tools/catalog build`) writes, under `build/catalog/`:

```
catalog.db                  the offline SQLite pack (schema_version 1, FTS5 trigram)
release/foods.jsonl         one JSON object per line, UTF-8, "\n" line ends,
release/dishes.jsonl        keys in a fixed order, rows sorted by ID
release/names.jsonl
release/servings.jsonl
release/yields.jsonl
release/exercises.jsonl
release/cities.jsonl
release/manifest.json
```

Every line is validated against its schema before it is written (a mismatch fails the build), and the files are written from the same records as the pack, so they cannot disagree.

## Rules for consumers

- **`catalog_version`** is a monotonic integer. A row carries the version it **first appeared in**; it does not change when the row's content changes. `manifest.catalog_version` is the version of the whole release. It goes up when `content_sha256` changes.
- **`content_sha256`** is the sha256 over the load files in the order foods, dishes, names, servings, yields, exercises, cities, each preceded by its table name without `.jsonl` and a NUL byte (matching the A05 builder). `git_commit` is informational and not part of the hash.
- **IDs are stable forever** (TD-071): `usda:<slug>`, `ref:<slug>` (a dish), `ref:<slug>/<variant>` (a loggable variant), `ex:<slug>`, `city:<geonameid>`; at most 64 ASCII characters. An ID is never reused or changed; an item is retired, not deleted. The importer may rely on that and upsert by ID.
- **Drafts are not in a release.** `includes_drafts` is `false` for every shipped release; only dev builds set it. Reject a manifest where it is `true` in production.
- Loggable rows are `foods` (basics and variants). A dish is a search/grouping target that resolves to its default variant (`default_variant_id`).
- Values are per 100 g (`basis: per_100g`). `kcal`, `protein_g`, `carbs_g`, `fat_g`, `fiber_g` are always present; `*_low` / `*_high` are the range bounds (variants only); `extras` holds sugar, saturated_fat, trans_fat, sodium, cholesterol, alcohol **only when known**.
- Nutrition numbers come from the data and `fb_domain` rules, never from a model (R1).
- Unknown fields are not allowed (`additionalProperties: false`): adding a field is a schema change, noted for the backend.

## Attribution

The pack's `meta.attribution` lists the data sources and licences (`data/attribution.yaml`): USDA FoodData Central (CC0) and GeoNames (CC BY 4.0), among the declared sources. Open Food Facts data never enters a release.
