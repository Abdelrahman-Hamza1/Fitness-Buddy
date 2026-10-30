# A28 — Barcode & label scan (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A28a: A09a, A24, **B10a** (contract); A28b: A28a, A23b, **B10b** (contract) | A28a M + A28b M (split 2026-10-30) | Claude | ⬜ A28a (wave 3) · ⬜ A28b (phase 2) |

_Old ID: S38 app part (renumbered by TD-063, 2026-10-16)._

**Goal.** Packaged food in seconds: scan a barcode → product → amount → logged. When the product is unknown or incomplete, photograph the nutrition label (Arabic or English) → review → saved as your food, linked to the barcode for next time.

**Spec:** FD-030, FD-031, FD-032, FD-033, FD-040, FD-041, FD-042, FD-081, AI-012, UX-006, OF-02 (barcode part), C-5, T17, T18 · **Decisions:** TD-010, D-073

## Split (2026-10-30, TD-105)
- **A28a Barcode scanning** (phase 1, wave 3, no AI): scanner, the lookup chain (personal foods → offline pack incl. A48 brands → `GET /v1/foods/barcode/{code}` from B10a), product card → amount → direct action with undo (T17), OFF attribution, halal warnings, the coverage counter. Not found → add the product by form as a personal food linked to the barcode. The plan decides what an offline scan of an unknown code does (keep it for a later lookup, or offer the form).
- **A28b Label scan** (phase 2): "Scan the label instead" → `POST /v1/buddy/label` (B10b) → review screen (proposal) → personal food linked to the barcode (T18).

## Scope
- **Scanner** (mobile_scanner) from the input bar's barcode button.
- **Lookup chain** (`07` §7): personal foods by barcode → offline pack → `GET /v1/foods/barcode/{code}` (B10: catalog → `off_cache` → OFF). Attribution "© Open Food Facts contributors" wherever OFF data shows.
- **Found:** a product card (name, brand, per serving and per 100 g) → amount picker → **direct action with undo** (≤ 3 taps after the scan, UX-006, T17).
- **Not found / incomplete** (FD-032/033): "Scan the label instead" → camera → `POST /v1/buddy/label` (B10's `LabelExtraction`: basis, serving size, nutrients, name guess, per-field confidence) → **review screen** (a proposal, FD-041) with uncertain or sanity-failed fields highlighted (FD-012) → confirm → a **personal food linked to the barcode** (FD-042) → log an amount (T18).
- **Offline:** the scan is queued as pending and processed on reconnect (OF-02).
- **Halal warnings** (FD-081): ingredient/flag check on scan results, search results and proposal cards. Wording "unknown" ≠ "non-halal". A warning, never a block.
- **Coverage counter** (TD-064, replaces the owner's barcode list): the app counts barcode lookups found / incomplete / not found, **on the device only**, shown on a debug line in About. It gives the real OFF hit rate from daily use (`07` §7).

## Out of scope
- Food photos (A29). Contributing to OFF (R3 idea).

## Fixed by the plan
- OFF data is never merged into our catalog (`07` §3). Label scans become private personal foods (D-048).

## Decide in the low-level plan
- The vision model routing (same provider vs best-scoring for labels, `06` §9).
- The ingredient keyword lists for halal flags (EN + AR), reviewed by the owner.

## Exit criteria
- [ ] T17 and T18 pass (E2E with recorded fixtures). (Label read accuracy is B10's eval.)
- [ ] The second scan of a label-created product is found instantly (local).
- [ ] An offline scan → pending → processed on reconnect.
- [ ] Halal warning tests (pork/alcohol/gelatin-unknown cases).

## Read first
`07-food-data.md` §3, §7 · `06-buddy-ai.md` §8 · `spec/11-foods-and-data-quality.md` §4–5, §9

## Owner involvement
Use barcode and label scan in daily logging. Optional: photograph a few Arabic labels for B10's eval.

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: split into a/b (TD-105, owner).

## Outcome
_Written in Phase E._
