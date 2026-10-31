# data/

The food catalog's source data (A03). Everything here is reviewed in diffs;
bulk downloads are never committed. Tooling: `tools/catalog/` (`make catalog`).

| Path | What |
|---|---|
| `usda_selection.yaml` | The chosen USDA basics: catalog ID `usda:<slug>`, FDC ID, state, EN/AR/Arabizi names. Edited by hand. |
| `usda_selection.yaml` growth (A54) | Most basics after A47 were proposed by `tools/scripts/catalog_expand/` (`expand.py` + the name files in `names/*.tsv`, `gen_meats.py`, `sanity_fix.py`): it reads the pinned USDA SR Legacy and Foundation CSVs (CC0, outside the repo), picks one USDA row per food and state, and writes selection entries with EN, AR and Arabizi names and USDA-only servings. It never writes a number. See `technical-planning/steps/A54-catalog-expansion.md` for the rules and the run order. |
| `usda/extract.jsonl` | Per-100 g values of the selection, written by `make catalog-usda` (sorted, deterministic). `usda/sources.yaml` pins the downloads by sha256. |
| `reference_dishes/<slug>.yaml` | One reference dish each (format v1, `schema/reference_dish.v1.schema.json`): names, variants (recipe or `per_100g`), portions with ranges, review status and sources. New dishes start as `draft`. `review.reviewed_by` is `claude-draft`, `ai-verified` (numbers checked against cited sources by an AI, owner-delegated 2026-10-30, A47) or `owner` (strongest). |
| `must_cover.yaml` | The spec's must-cover list (`spec/11` section 6, FD-052) with EN, AR and Arabizi names. `catalog coverage` reports how each item resolves. |
| `yields.yaml` | Cooking yield factors (FD-060): grams of `to` per gram of `from`, one row per group and pair (`yields.v1.schema.json`). The only owner of yield factors. |
| `portion_words.yaml` | What one loaf, piece, glass, can, tbsp or tsp of a food weighs or holds (FD-003, `portion_words.v1.schema.json`). The only owner of household units: a `servings` entry in the selection with the same unit must agree (the validator checks). |
| `attribution.yaml` | Data sources and licences for About and the pack's `meta.attribution` (A05 D18). Includes the open Matvaretabellen licence question (backlog #64). |
| `exercises.yaml` | Authored built-in exercise library (WO-001/002/004): EN display names/aliases, separate equipment variants, six logging types and primary muscles. Names only, no coaching/media. |
| `cities.tsv` | Generated GeoNames subset (LC-033), with stable IDs, coordinates and IANA zones. Import with `make catalog-cities`; never hand-edit. |
| `geonames/sources.yaml` | JSON-compatible YAML pins (download date, archive/text SHA256), selection policy and IANA snapshot provenance. Daily URLs change; retain the matching raw files outside the repo. |
| `schema/iana_timezones.txt` | IANA tzdata2026e Zone + Link names, including backward aliases, used for deterministic offline validation. Public-domain source archive/hash in the file and sources.yaml. To refresh: derive names from the listed source files, review the diff and provenance together. |
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

## City refreshes (A05b)

`make catalog-cities GEONAMES_DIR=/path/to/retained/dumps` verifies the pinned
text checksums and regenerates the TSV without network access. Without
`GEONAMES_DIR`, the target downloads the city and per-country alternate-name archives to an external temporary
directory and verifies archive and text checksums. A changed daily download
fails closed: refresh `geonames/sources.yaml` explicitly in a reviewed data
change, retaining the exact downloaded archives/extracts for reproducibility.
Normal `make catalog`, builds, tests and CI use only committed data.

Selection: all PS/JO entries from cities1000; IL/LB/SY/EG/SA/IQ/AE/BH/KW/OM/QA/YE/TR
from cities15000; other countries only at population >=1,000,000. Explicit IDs
in `geonames/excluded_cities.tsv` exclude settlements under the owner's
2026-10-22 decision; neither country nor time zone triggers exclusion. Their
lock entries remain with status `retired` and may never be reused.

For PS/JO and every regional country, pinned `alternatenames/<CC>.zip` supplies
language-tagged names: preferred `en`, otherwise GeoNames asciiname;
preferred `ar`, otherwise another current `ar` name, otherwise blank.
Only display-valid names are eligible: English uses plain ASCII Latin letters,
digits, spaces and simple punctuation (apostrophe, hyphen, dot, comma); Arabic
uses Arabic letters, spaces and diacritics. Invalid tagged transliterations are
skipped; no usable Arabic name means blank. Apostrophe/dash variants normalize
to simple punctuation; invalid preferred English falls back to asciiname. These
rules also validate the committed TSV during catalog checks. Historical
and ended names are ignored; equal-rank ties use lexical name order. Untagged
Arabic-script alternates are never used. Persian/Kurdish kaf, yeh and heh forms
normalize to Arabic, retaining diacritics. Three reviewed, ID-specific missing-name
fallbacks (both Karak records and the released Ramallah spelling) and their
rationale live in `sources.yaml`. Original coordinates/zones are retained.
GeoNames is CC BY 4.0; attribution is active in the pack/About metadata.
A10 shows only the GeoNames `credit`, never the internal `note`; city ranking
may sort by population but must not filter out zero-population rows.
