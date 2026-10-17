# tools/catalog (`fb_catalog`)

Food catalog tooling (A03). Dev tool only, a member of the pub workspace, never
part of the app.

```sh
make catalog-usda                      # download pinned USDA CSVs (temp dir), rewrite the extract
make catalog-usda USDA_DIR=/tmp/x/raw  # reuse an earlier download (sr_legacy/ + foundation/)
dart run tools/catalog/bin/catalog.dart import-usda --usda-dir <dir>
```

`import-usda` reads `data/usda_selection.yaml` (draft basics: catalog ID
`usda:<slug>`, FDC ID, `fiber_zero`) and writes `data/usda/extract.jsonl`: one
sorted JSON line per food with per-100 g nutrients, the FDC portions and which
fallback supplied kcal and carbs. The bulk data is never committed
(`tools/scripts/fetch-usda.sh` downloads it, sha256-pinned in
`data/usda/sources.yaml`). Nutrient mapping (A03 D3): kcal 1008 -> 2048 ->
2047, carbs 1005 -> 1050, protein 1003, fat 1004, fiber 1079. An unknown
nutrient id or a missing core nutrient fails the import.

| Exit code | Meaning |
|---|---|
| 0 | Extract written. |
| 1 | The data is wrong (message names the file, entry or FDC id). |
| 64 | Bad usage. |

## `catalog validate` (A03 WP2)

```sh
dart run tools/catalog/bin/catalog.dart validate [--require-ar] [--dishes data/reference_dishes]
```

Checks `data/usda_selection.yaml` and every `data/reference_dishes/<slug>.yaml`
against the JSON Schemas in `data/schema/` (draft-07), then the rules a schema
can't state: ingredient references resolve, exactly one default variant,
ordered ranges that contain the typical value, no Open Food Facts source (C-5),
unique normalized names per language (FD-004), file name = slug, no circular
recipes, and the FD-012 sanity check on every basic and variant (a `fail`
stops, a `warn` is printed; a reviewed `sanity_override: {reason}` waives a
fail and is printed as a note). Each error reads `file: /path/in/file: message`.
It prints each variant's per-100 g (typical value; the low/high bounds are in
`ValidationReport.computed`). Per-100 g = sum(grams x ingredient per 100 g) /
`cooked_total_g` x 100 through `fb_domain`; the low bound takes every ranged
ingredient at its low over the high end of `cooked_total_range`, the high bound
the reverse.

### Yields and portion words (A04 WP2)

`validate` also checks `data/yields.yaml` and `data/portion_words.yaml` when
they exist (`--yields`, `--portion-words`), against `data/schema/yields.v1.schema.json`
and `portion_words.v1.schema.json`. Both are `rows:` lists.

```yaml
# yields.yaml: grams of `to` per gram of `from`; one row per group + pair
rows:
  - {group: rice, from: dry, to: cooked, factor: 2.8, source: "USDA SR Legacy raw vs cooked"}
  - {group: chicken, from: raw, to: cooked, factor: 0.72, source: "USDA Table of Cooking Yields (2014)"}
# portion_words.yaml: exactly one of g / ml; optional range [lo, hi]
rows:
  - {food: "usda:egg_whole_raw", unit: piece, g: 50, range: [44, 58], source: "USDA SR Legacy portion"}
  - {food: "usda:cola", unit: can, ml: 330, source: "label"}
```

Rules: states are the `fb_domain` `FoodState` codes, `factor > 0`, `from` !=
`to`, no duplicate or inverse-duplicate rows, a basic's `yield_group` needs a
row (checked once `yields.yaml` exists), `food` resolves to a basic or dish,
`unit` is known to `fb_domain` (plus `can`, ahead of A05), the range contains
the value, no Open Food Facts source, `unit` is not a mass or volume code (`g`,
`ml`, ...), a basic's `state` is a from/to state of its yield group, and a
selection `servings` entry must equal the portion word with the same unit
(household units have one owner: `portion_words.yaml`).

## `catalog build` and `catalog check` (A05 WP1)

```sh
dart run tools/catalog/bin/catalog.dart build [--update] [--include-drafts] [--assets-dir <dir>] [--coverage]
dart run tools/catalog/bin/catalog.dart check [--base <git ref>]
```

`build` validates (Arabic names required), then writes `build/catalog/catalog.db`
(pack schema v1), `build/catalog/release/*.jsonl` and `manifest.json` (formats in
`contracts/catalog/`; every line is schema-checked). Sizes: fails at 10,000,000
bytes, warns from 8,000,000. It prints counts per kind and the FD-012 sanity
distribution. Without `--update` it never writes `data/`; a missing lock entry or a
changed content hash fails with "run `make catalog` and commit". With `--update`
(`make catalog`) it appends new released IDs to `data/catalog_ids.lock` and bumps
`data/catalog_release.yaml`. `--include-drafts` packs drafts too (never for release).

`check` is `build` without writing under `data/`, plus the ID lock compared with the
merge base (`CATALOG_BASE_REF`, else the merge-base with `origin/main`, on `main` the
previous commit): a removed or changed locked ID, a retired ID that is active again, a
released ID gone from the data, or a changed kind fails. It also prints the AT-003
table (resolved / draft / missing) and fails only if a reviewed must-cover item stops
resolving by EN, AR or Arabizi name.

| Exit code | Meaning |
|---|---|
| 0 | Ok. |
| 1 | The data, the lock, the size or the schemas are wrong (the message says which). |
| 64 | Bad usage. |
