# B10 — Barcode lookup, label & meal photos, paste import

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B10a: B07; B10b: B10a, B08 | B10a M + B10b L (split 2026-10-30) | Claude (TD-085) | ✅ B10a (closed, awaiting review/merge) · ⬜ B10b (phase 2) |

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
**B10a:** planned and built together with A28a as one step (owner, 2026-10-30). The full plan is in [A28's card](A28-barcode-label-scan.md#low-level-plan) (§2 D1–D7 are the server decisions: contract, normalization, `off_cache` + migration, expiry job, OFF client budgets, privacy). **B10b:** written in its own Phase B (phase 2).

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: split into a/b (TD-105, owner).
- 2026-10-30: B10a planned with A28a as one combined step; plan in A28's card.
- 2026-10-30: B10a implemented; closed, awaiting the Codex review and merge.
- 2026-10-30: review round 1 server fixes: the single flight covers the cache write, an OFF not-found always negative-caches (stale only for OFF errors), HTTP-date Retry-After read against the clock; tests in `BarcodeLookupTests` (11).

## Outcome
### B10a (2026-10-30, built with A28a as one step; before the Codex review; CI evidence comes from the merge run)

**Built.** `GET /v1/foods/barcode/{code}` (Catalog tag, `getFoodByBarcode`, any live principal incl. guests): GTIN-8/12/13/14 with a valid check digit, keyed in OFF's 13-digit form; 200 `BarcodeProduct` (OFF data, nullable nutrients, `complete`, basis g/ml, serving, ingredients, label tags), 400 invalid, 404 unknown, 429 per-account budget, 503 + `Retry-After` when OFF can't be asked. `BarcodeLookup` reads `catalog.off_cache` (products 30 days, unknown codes 1 day), else one OFF v2 read via `OpenFoodFactsClient` (User-Agent from `Catalog:OpenFoodFacts:UserAgent`, no identity or cookies, no redirects, 5 s, 1 MB cap, kcal from kJ by code). `OffGate`: process-wide 10 reads/min, cool-down after OFF 429/503, 30 upstream fetches per account per hour (cache hits free), one in-flight read per code. Expired products are served 7 more days while OFF is down (stale-if-error). Daily job `catalog.off-cache-expiry` (03:17 UTC) deletes rows past that window; module schedules are now DI-registered `JobSchedule`s that `DatabaseWorker` registers.

**Migration: yes** — `202610300001_OffCacheWrites` (Catalog): `GRANT SELECT, INSERT, UPDATE, DELETE ON catalog.off_cache TO fb_app` and an `expires_at` index. Forward-only, run by the migrate role on deploy; release tables stay SELECT-only for the app role (tested). The server now calls `world.openfoodfacts.org` over HTTPS (the laptop phone server too).

**Privacy (D7).** No barcode in logs: our log lines carry outcome codes only, and the framework's HttpClient request logs are removed for this client (the test caught them printing the product path). Outbound client spans keep only the origin (`HttpActivityPrivacy.SanitizeClient`). OFF rows never reach `catalog.foods`/`names`/`servings` (tested).

**Tests.** `Persistence.Tests/BarcodeLookupTests` (5, Testcontainers + fake OFF handler): mapping, cache, single flight, User-Agent/no identity, negative cache, refresh after expiry, stale-if-error, cool-down, global and per-account budgets, 400/401, isolation from catalog tables and grants, expiry job, no barcode in captured logs. `Host.Tests/TelemetryPrivacyTests` +1 (client span scrub). Contract conformance, lint, self-test and breaking checks pass; `make check-dotnet` and the architecture tests pass.

**Exit criteria (B10a part).** Conformance green and Dart client regenerated ✓. OFF client respects rate limits and caches (fake OFF) ✓; OFF rows never in catalog tables ✓. Label/photo/import/eval criteria → B10b.

**Follow-ups:** backlog #225 (server catalog barcode step), #228 (set an OFF contact in the User-Agent on deploy).
