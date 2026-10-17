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
