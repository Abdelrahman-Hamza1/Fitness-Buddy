# data/

The food catalog's source data (A03). Everything here is reviewed in diffs;
bulk downloads are never committed. Tooling: `tools/catalog/` (`make catalog`).

| Path | What |
|---|---|
| `usda_selection.yaml` | The chosen USDA basics: catalog ID `usda:<slug>`, FDC ID, state, EN/AR/Arabizi names. Edited by hand. |
| `usda/extract.jsonl` | Per-100 g values of the selection, written by `make catalog-usda` (sorted, deterministic). `usda/sources.yaml` pins the downloads by sha256. |
| `reference_dishes/<slug>.yaml` | One reference dish each (format v1, `schema/reference_dish.v1.schema.json`): names, variants (recipe or `per_100g`), portions with ranges, review status and sources. New dishes start as `draft`. |
| `must_cover.yaml` | The spec's must-cover list (`spec/11` section 6, FD-052) with EN, AR and Arabizi names. `catalog coverage` reports how each item resolves. |
| `schema/` | JSON Schemas for the dishes and the selection. |
| `sources/` | Small curated samples used as evidence (e.g. `off_local_sample.yaml`). |

USDA FoodData Central is CC0 (citation requested). Open Food Facts (ODbL) data never enters `data/`: `sources/off_local_sample.yaml` only names products.

## Commands

```sh
make catalog                         # validate + build (drafts included) + coverage table
dart run tools/catalog/bin/catalog.dart validate
dart run tools/catalog/bin/catalog.dart build [--include-drafts] [--out build/catalog/catalog.db]
dart run tools/catalog/bin/catalog.dart query "maqlobe"
dart run tools/catalog/bin/catalog.dart coverage
```

`build` writes a prototype `catalog.db` (SQLite, FTS5 trigram over
`fb_text` normalized name keys) under `build/catalog/`, which is gitignored.
Draft dishes are left out unless `--include-drafts` (they don't ship). The
pack is a spike artefact: A05 finalises the schema, A07 owns ranking.

## `must_cover.yaml`

```yaml
groups:
  - id: main
    items:
      - id: maqluba                 # catalog slug: matches ref:maqluba, ref:maqluba/..., ref:maqluba_...
        names: {en: ["Maqluba"], ar: ["مقلوبة"], arabizi: ["maqluba"]}
        match: [ref:maqluba]        # optional: replaces the default (ref:<id>, usda:<id>)
```

An item resolves in a language when a name in that language finds a matching
catalog ID in the top 5. Status: `reviewed` or `draft` (a dish), `basic` (a
USDA food), `missing`.
