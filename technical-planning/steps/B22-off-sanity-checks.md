# B22 — Sanity checks on Open Food Facts products

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend (+ a small app note) | B10a, A28a | S–M | Claude | ✅ built locally, awaiting review/merge |

**Goal.** OFF data is crowd-sourced (kJ stored as kcal, per-serving values stored as per 100 g, missing macros, energy that doesn't fit the macros, impossible values). Numbers must be trustworthy, so a wrong product is repaired when the mistake is provable, flagged when doubtful, and held back when impossible. It is never shown silently. Source: the packaged-foods research, section 4 ("OFF quality").

**Spec:** FD-012 (energy vs macros), FD-030, FD-041. **Thresholds are FD-012's** (`SanityTolerance` in `fb_domain`: ok 15 kcal / 15 %, max 920 kcal per 100, max 105 g of macros per 100 g), not new numbers.

## Rules (`OffSanity`, pure; `backend/src/Modules/Catalog/Application/OffSanity.cs`)
| Rule | Where | What it does |
|---|---|---|
| `kj-converted` | Normalize | Only `energy-kj` is published: kcal = kJ / 4.184 (correction recorded). |
| `kj-in-kcal` | Normalize | The kcal field holds the kJ number (equals the kJ field within 2 %, or is 4.184 × the macro energy within 10 %, macro energy at least 20): kcal = kJ / 4.184. |
| `per-serving-scaled` | Normalize | Only per-serving values exist and the serving is in g/ml: scaled to per 100. Flags "check the label". |
| `per-serving-in-per100` | Normalize | The "per 100" values equal the per-serving ones of a serving that isn't 100 ± 10: rescaled. Flags "check the label". |
| `negative-value`, `missing-energy`, `missing-macros`, `energy-too-high`, `macros-too-heavy` | Check | Hard reject: the answer is 404 (the app offers label scan / create the food), and the row is cached as "unknown" (1 day). |
| `energy-macros-mismatch` | Check | FD-012 deviation above ok (both fiber conventions, alcohol at 7): served with `checkLabel: true`. |

## Where it runs
- **On ingest:** `OffMapper` runs `Normalize`; `BarcodeLookup.FetchAndPublishAsync` runs `Check` before caching.
- **On serve:** `BarcodeLookup.Serve` runs `Check` for every answer (fresh, cached, stale), so rows cached before B22 are checked too. No migration; the corrections list rides in the cached JSON.
- Logs carry rule names and counts only, never a barcode or a name.

## Contract and app
- Optional `checkLabel` boolean on `BarcodeProduct` (non-breaking). Dart client regenerated.
- App: `OffProduct.checkLabel` → `ScannedProduct.checkLabel` → a muted note on the food sheet header: "Check these numbers against the label."

## Tests
`OffSanityTests` (every rule, OFF-shaped payloads, no network) · `BarcodeLookupTests.Lookup_rejects_impossible_products_flags_doubtful_ones_and_rechecks_cached_rows` · mapper test updated · app: `barcode_lookup_test` (flag reaches the header data), `barcode_scan_screen_test` (note shown).

## Not done (backlog)
- The note isn't kept on a personal food saved from the scan; later scans of it rely on the app's own FD-012 check.
- No sugar ≤ carbs, saturated ≤ fat, salt/sodium or identity (placeholder name) checks from the research list.
- No "per 100 looks like per serving without serving proof" flag (nothing to prove it with).

## Progress log
- 2026-10-31: checker, mapper, lookup gate, contract field, app note and tests built locally.

## Outcome
Built; pending Codex review and merge.
