# data/

The food catalog's source data (A03). Everything here is reviewed in diffs;
bulk downloads are never committed. Tooling: `tools/catalog/` (`make catalog`).

| Path | What |
|---|---|
| `usda_selection.yaml` | The chosen USDA basics: catalog ID `usda:<slug>`, FDC ID, state, EN/AR/Arabizi names. Edited by hand. |
| `usda/extract.jsonl` | Per-100 g values of the selection, written by `make catalog-usda` (sorted, deterministic). `usda/sources.yaml` pins the downloads by sha256. |
| `reference_dishes/<slug>.yaml` | One reference dish each (format v1, `schema/reference_dish.v1.schema.json`): names, variants (recipe or `per_100g`), portions with ranges, review status and sources. New dishes start as `draft`. |
| `must_cover.yaml` | The spec's must-cover list (`spec/11` section 6, FD-052) with EN, AR and Arabizi names. `catalog coverage` reports how each item resolves. |
| `yields.yaml` | Cooking yield factors (FD-060): grams of `to` per gram of `from`, one row per group and pair (`yields.v1.schema.json`). The only owner of yield factors. |
| `portion_words.yaml` | What one loaf, piece, glass, can, tbsp or tsp of a food weighs or holds (FD-003, `portion_words.v1.schema.json`). The only owner of household units: a `servings` entry in the selection with the same unit must agree (the validator checks). |
| `attribution.yaml` | Data sources and licences for About and the pack's `meta.attribution` (A05 D18). Includes the open Matvaretabellen licence question (backlog #64). |
| `catalog_ids.lock` | Append-only list of every released catalog ID (TD-071). Written by `make catalog` only; never edit or delete a line. Drafts are never in it. |
| `catalog_release.yaml` | The current `catalog_version` and content hash. Written by `make catalog` only. |
| `schema/` | JSON Schemas for the selection, the reference dishes, yields and portion words. |
| `sources/` | Small curated samples used as evidence (e.g. `off_local_sample.yaml`). |

USDA FoodData Central is CC0 (citation requested). Matvaretabellen (Norwegian Food Composition Table, Mattilsynet) is cited as a source in `reference_dishes/halloumi.yaml`. Its licence is not CC BY 4.0 as far as we could verify: mattilsynet.no says the values may not be published without a reference, data.norge.no lists it only as "open license", and matvaretabellen.no states no licence (it asks to be cited). Cite as "Norwegian Food Composition Table 2024. The Norwegian Food Safety Authority. www.matvaretabellen.no"; confirm terms with matvaretabellen@mattilsynet.no before R2/R3. Open Food Facts (ODbL) data never enters `data/`: `sources/off_local_sample.yaml` only names products.

## Commands

```sh
make catalog        # validate, lock new IDs, bump the version, build build/catalog/ + app assets, print coverage. Commit what changed (the lock and catalog_release.yaml).
make catalog-pack   # non-mutating: the same build without writing data/; fails with "run make catalog" when stale (used by Android builds)
make catalog-check  # CI: read-only checks incl. the ID lock against the merge base (CATALOG_BASE_REF)
dart run tools/catalog/bin/catalog.dart validate
dart run tools/catalog/bin/catalog.dart query "maqlobe"
```

After any change under `data/` run `make catalog` and commit `catalog_ids.lock` and
`catalog_release.yaml` with it. Reviewed dishes and basics get an ID in the lock
once; renaming or deleting a released ID is refused (retire it in the lock instead).
Draft dishes are excluded from the release and from the lock, so they can still be
renamed. `CATALOG_DRAFTS=1 make catalog` also packs drafts for dev runs.
The release format is documented in `contracts/catalog/`.

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
