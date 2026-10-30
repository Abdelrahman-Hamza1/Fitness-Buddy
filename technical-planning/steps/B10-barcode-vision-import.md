# B10 — Barcode lookup, label & meal photos, paste import

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B10a: B07; B10b: B10a, B08 | B10a M + B10b L (split 2026-10-30) | Claude (TD-085) | ⬜ B10a (wave 3) · ⬜ B10b (phase 2) |

_Old ID: S38 and S39 server parts (renumbered by TD-063, 2026-10-16). The app sides are A28 and A29._

**Goal.** The server side of packaged food and pictures: barcode lookups through a licence-isolated Open Food Facts cache, nutrition-label reading, meal photos, and turning a pasted weight note into rows.

**Spec:** FD-030–033, FD-040–042 (extraction side), AI-011, AI-012, AI-052, AI-057, WB-030–032 (parse side), C-5, T17, T18, T33 · **Decisions:** TD-010, D-073

## Split (2026-10-30, TD-105)
- **B10a Barcode lookup** (phase 1, wave 3, no AI): the `GET /v1/foods/barcode/{code}` contract, the licence-isolated OFF cache and client, the expiry job, their tests. App side: A28a.
- **B10b Label & meal photos, paste import** (phase 2): `POST /v1/buddy/label`, image input on interpret, `POST /v1/buddy/import`, the `WeighIn`/`Measurement` intents, vision routing, scrubbers and the eval. App side: A28b and A29.

## Scope
- **Contract first** (one commit per endpoint, Progress-log line each): `GET /v1/foods/barcode/{code}`, `POST /v1/buddy/label` (`LabelExtraction`: basis per 100 / serving, serving size, nutrients, name guess, per-field confidence), image input on interpret (meal photo, the same `Interpretation`), `POST /v1/buddy/import` (rows: date, value, unit?, original text), and the `WeighIn` / `Measurement` intents.
- **Barcode lookup chain** (`07` §7): catalog → `off_cache` → OFF API (custom User-Agent, rate-limit aware, TTL ≈ 30 days, refreshed on access, **licence-isolated**: never merged into catalog tables, `07` §3). Worker job to expire the cache.
- **Vision tasks** via `ILlmClient` (the model chosen for vision in B02/B08 routing): label extraction and meal photos. Photos are never stored on the server; no image content in logs.
- **Paste import parse:** the model reads rows; unit inference and flags are computed by the app (A29).
- **Eval:** ≥ 10 label photos (Arabic and English, per-field accuracy), ≥ 10 meal photos (identification rate), import cases (the owner's note format + messy variants), T33.

## Out of scope
- Scanner, review screens, import review table (A28, A29). Halal checks (app side, A28).

## Exit criteria
- [ ] Contract conformance green; the Dart client regenerated.
- [ ] The OFF client respects rate limits and caches (integration test with a fake OFF). OFF rows never appear in catalog tables (test).
- [ ] An Arabic label photo produces correct core values in ≥ 90% of the label eval cases. Photo and import cases are reported; T33 passes.
- [ ] Scrubber tests: no image bytes, label text or note text in logs.

## Read first
`07-food-data.md` §3, §7 · `06-buddy-ai.md` §7 · `spec/11-foods-and-data-quality.md` §3–4 · B07, B08 Outcomes

## Owner involvement
Optional: photograph a few Arabic labels and share the weight-note format for the eval.

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: split into a/b (TD-105, owner).

## Outcome
_Written in Phase E._
