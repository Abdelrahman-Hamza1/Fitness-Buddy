# A28 — Barcode & label scan (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A28a: A09a, A24, **B10a** (contract); A28b: A28a, A23b, **B10b** (contract) | A28a M + A28b M (split 2026-10-30) | Claude | ✅ A28a (closed, awaiting review/merge) · ⬜ A28b (phase 2) |

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
### B10a + A28a · Barcode lookup and scanning, no AI (phase 1, wave 3)

_Written 2026-10-30 against `main` at `fe1bd7e`, lane `~/work/fitness_buddy_3`, branch `step/B10a-A28a-barcode`. One combined step at the owner's request: one plan, one implementation, one Codex review (run by the orchestrator). Self-approved under TD-037: no spec change, no Accepted-TD change, no paid service (Open Food Facts is free and already decided, TD-010 / `07` §3, §7). B10's card points here._

**Tier: Risky** by PROCESS A2 (a new user-data write on the log path and a third-party call from the server). The orchestrator asked for one combined Codex review; it should cover security/privacy (OFF egress, logging, cache isolation) as well as code. Phase 2 stays out: label scan, `POST /v1/buddy/label`, anything AI (B10b/A28b). The card's "decide in the plan" item on vision routing moves to A28b.

#### 1. Summary
The input bar's barcode button opens a camera scanner (mobile_scanner). A scanned code goes through the lookup chain: **your foods by barcode → offline pack `barcodes` (empty today; A48 postponed) → `GET /v1/foods/barcode/{code}`**. The server answers from the licence-isolated `catalog.off_cache` or fetches Open Food Facts once (custom User-Agent, global and per-user budgets, single flight per code, negative caching), and a daily worker job expires old rows. The app shows the product in the existing food sheet with a product header (name, brand, per serving and per 100, "© Open Food Facts contributors", halal warnings when the setting is on); **Add** logs it as one direct action with Undo. Not found → "Add it yourself" (the personal-food form with the barcode filled in). Incomplete → the same form prefilled with what OFF knows. Offline / server unavailable → the scan waits in a small on-device list and is looked up again when the app comes back or the scanner reopens. A device-only counter (found / incomplete / not found) shows on About.

#### 2. Decisions
- **D1 Server chain = `off_cache` → OFF.** The server catalog has no barcode table (the release format carries none; the offline pack has an empty `barcodes` table). "Catalog first" happens on the phone (pack lookup before the API). A server-side catalog barcode step comes with the first release that ships barcodes (backlog).
- **D2 Contract:** `GET /v1/foods/barcode/{code}` (tag Catalog, `getFoodByBarcode`, any authenticated account incl. guests). `code` = 8–14 digits. 200 `BarcodeProduct` {`code` (normalized), `source` ("off" today; open vocabulary, the app shows OFF attribution for "off"), `complete` (all five core nutrients present), `name`, `nameAr`, `brand` (nullable), `basis` ("g"/"ml"), `per100` (`BarcodeNutrients`: kcal, proteinG, carbsG, fatG, fiberG, each nullable), `servingQuantity` (nullable, on the basis unit), `servingLabel` (OFF's free text, nullable), `ingredientsText` (nullable), `labels` (OFF label + ingredient-analysis tags, e.g. `en:halal`, `en:vegan`)}. 400 invalid code (not GTIN-8/12/13/14 with a valid check digit), 404 not known to OFF, 429 per-user budget, 503 OFF unavailable / global budget exhausted (`Retry-After`). `Cache-Control: no-store` like the other catalog reads.
- **D3 Normalization:** digits only; GTIN check digit required; GTIN-12 → 13 digits with a leading 0, GTIN-14 with a leading 0 → 13 digits (OFF's canonical form). The app expands UPC-E to UPC-A before lookup (`Gtin.normalize` in fb_domain, shared rules with the server; both tested against the same small vector list in the tests).
- **D4 Cache (licence isolation, `07` §3):** rows stay in `catalog.off_cache(code, data, expires_at)`, which already exists (B07 reserved it); `data` holds our mapped OFF fields or a not-found marker. Found rows live 30 days, not-found rows 1 day. A read of an expired row refetches ("refreshed on access"); if OFF is down, an expired row up to 7 days old is served (stale-if-error). Nothing ever copies OFF data into `catalog.foods`/`names`/`servings`, and release import never touches `off_cache` (test). **Migration `202610300001_OffCacheWrites`:** grants `fb_app` INSERT/UPDATE/DELETE on `catalog.off_cache` (today SELECT only) and adds an `expires_at` index. Deploy note: a normal forward migration, run by the migrate role.
- **D5 Expiry job:** `catalog.off-cache-expiry`, daily (`17 3 * * *` UTC), deletes rows whose `expires_at` is more than 7 days past (the stale-if-error window). Module schedules are DI-registered `JobSchedule`s that `DatabaseWorker` registers next to `ops.cleanup` (a small, general building-block change).
- **D6 OFF client:** `https://world.openfoodfacts.org/api/v2/product/{code}?fields=…` (only the fields we map), `User-Agent: FitnessBuddy/<version> (<contact>)` from `Catalog:OpenFoodFacts:UserAgent` (default names the GitHub repo; the owner may set a contact email), 5 s timeout, no redirects, response capped at 1 MB. Budgets: a process-wide token bucket (default 10 OFF reads/min, `07` §3 says ≈ 15), a cool-down after an OFF 429/503 (its `Retry-After`, else 60 s), a per-user limit on upstream fetches (30/hour; cache hits are free), single flight per code. Kcal from kJ (÷ 4.184) when OFF has only energy in kJ: code computes, never a model. Values outside our bounds (negative, NaN, kcal > 920, gram nutrients > 100 per 100) become null; text is trimmed and capped (name 200, brand 60, serving label 100, ingredients 5,000, ≤ 64 labels).
- **D7 Privacy:** no barcode or OFF text in logs; log lines carry only an outcome code (hit / miss / upstream status). Outbound HTTP client spans drop `url.full`/`url.path`/`url.query` (the code is in OFF's path); server spans are already route-only. OFF requests carry no user identity, no device id, no cookies.
- **D8 Logging an OFF product = one atomic direct action:** `[CreatePersonalFood(newId, draft{createdFrom: 'off', barcodes: [code], brand, servings}), LogEntries([entry → personal newId])]` through `ChangeSetApplier`, one Undo entry that removes both. Why a personal food: the next scan is found instantly and offline (step 1 of the chain), recents and quick add keep working, and it's the user's private copy in user data, never our catalog (`07` §3 holds). The food sheet loads the not-yet-saved choice from an in-memory scanned-food registry (same pattern as A24's online-food cache). Badge stays ⓨ (your copy); the personal-food form shows the OFF attribution for `createdFrom == 'off'`.
- **D9 Loggable vs incomplete:** the app needs a name and kcal, protein, carbs, fat that pass FD-012's hard sanity. Missing fiber only: loggable with fiber 0 and a visible note ("Fiber isn't listed; counted as 0"); the counter still records it as incomplete (the server's `complete`). Otherwise the card shows what OFF has and offers "Add the missing values" → the personal-food form prefilled (name, brand, barcode, known values, serving).
- **D10 Offline scan (the card's open question):** both. The code joins a pending list (device-only, `shared_preferences`, ≤ 20 codes, dropped after 14 days) **and** the screen offers "Add it yourself" right away. Pending codes are looked up again when the scanner opens, when the app returns to the front, and after any successful lookup; each ends as ready (product found → tap to log), not found (→ form) or still waiting. Nothing is logged without the user. A personal food added for that barcode removes it from the list. No network on the startup path: processing runs only on those triggers.
- **D11 Halal (FD-081), keyword lists in `fb_domain` (`HalalCheck`), drafted here for the owner to review by use:** three flags, worded as warnings, "unknown" as unknown, never a block, shown only when the Halal setting is on. Word-boundary matching on lower-cased text, Arabic letters normalized (alef forms, taa marbuta, diacritics stripped).
  - *pork (likely contains):* EN pork, pig, swine, porcine, bacon, ham, lard, prosciutto, pancetta, jambon, saindoux, domuz · AR خنزير، لحم خنزير، شحم الخنزير، دهن الخنزير، بيكون، جامبون، لارد. Not flagged: turkey/chicken/beef/halal ham or bacon. Salami, pepperoni and chorizo are left out on purpose (local halal beef versions are common, and a name-only check would mislabel them).
  - *alcohol (likely contains):* EN alcohol, ethanol, ethyl alcohol, wine, beer, liqueur, liquor, rum, brandy, whisky, whiskey, vodka, cognac, gin, sherry, marsala, kirsch, mirin · AR كحول، كحولي، إيثانول، ايثانول، نبيذ، خمر، بيرة، مشروب كحولي، براندي، ويسكي، فودكا. Not flagged: sugar alcohol(s), alcohol-free, non-alcoholic, 0% alcohol, wine vinegar, root beer, ginger beer, خالي من الكحول، بدون كحول، كحول سكري.
  - *unknown source:* gelatin/gelatine, E441, E471, E472 (a–f), E422, E470, E481, E482, E542, E920, mono- and diglycerides, monoglycerides, glycerol/glycerin(e), animal fat, rennet, pepsin, L-cysteine · AR جيلاتين، جلاتين، مستحلب حيواني، أحادي وثنائي الجليسريد، جليسرين، جلسرين، منفحة، دهن حيواني. Not flagged: microbial/vegetable rennet, vegetable glycerin, soy lecithin (E322). Dropped when the product's tags include `en:halal`, `en:vegan` or `en:vegetarian` (pork and alcohol never are).
  - Where: scan results (ingredients + name + tags) and food search rows (name and Arabic name only: catalog and personal foods carry no ingredients). Proposal cards → backlog (Buddy surface, phase 2).
- **D12 Coverage counter (TD-064):** `core/catalog/barcode_coverage.dart`, three integers in `shared_preferences` (`fb.barcode_coverage.v1`), incremented once per resolved lookup (local hits count as found), shown on About as one muted debug line. Never synced, never sent.
- **D13 Scanner:** `mobile_scanner` **7.4.2** (BSD-3, 2026-09-14), formats EAN-13, EAN-8, UPC-A, UPC-E only, bundled ML Kit model (`com.google.mlkit:barcode-scanning` 17.3.0, ≈ 2–3 MB per ABI) so the first scan works offline without a Play-services model download. **New permission: `android.permission.CAMERA`** (from the plugin's manifest; `android.hardware.camera` `required=false`), asked at first use by the plugin, with a denied state that offers "Type the code" instead. `tools/scripts/apk_hardening_check.py` is a deny-list (biometric permissions only), so CAMERA needs no change there; noted in the Outcome. Manual entry ("Type the code") is always available (emulator, damaged labels).
- **D14 Navigation:** `BarcodeScanRoute` `/today/scan?date=&slot=` nested in the Today tab; the input bar's barcode button opens it in every flavor (the camera button stays dev-only "coming soon", A22). After a log, the scanner closes and the Undo snackbar shows on the root messenger (as search does).

#### 3. Design
**Contract** `contracts/openapi/modules/catalog.yaml` (+ path line in `openapi/openapi.yaml`) → `make gen` → `packages/fb_api_client` (generated, committed).

**Server** (`backend/src/Modules/Catalog/`):
- `Domain/Gtin.cs`: validate + normalize (D3).
- `Application/BarcodeLookup.cs`: chain over ports `IOffCache` and `IOffClient`, TTL/stale rules, single flight, budgets via `OffBudget`; returns `Found(product, complete)` / `NotFound` / `Unavailable(retryAfter)` / `UserLimited`. `Application/OffProduct.cs` record.
- `Infrastructure/OpenFoodFactsClient.cs` (named `HttpClient`, mapping + bounds), `Infrastructure/PostgresOffCache.cs` (writes under `DatabaseSession` + recovery barrier, like `JobScheduler`), `Infrastructure/OffCacheExpiryJob.cs`, `Infrastructure/OffOptions.cs`, `Infrastructure/Migrations/OffCacheWrites.cs` (+ snapshot unchanged: raw SQL migrations).
- `Api/CatalogEndpoints.cs` + `Api/CatalogModels.cs`: the route and DTOs. `CatalogModule.cs`: registrations + `JobSchedule`.
- Building blocks / Host: `DatabaseWorker` registers DI `JobSchedule`s; `HttpActivityPrivacy` scrubs client-span URLs.

**App** (`apps/mobile/lib/`):
- `packages/fb_domain`: `Gtin.normalize`/`expandUpcE`; `food/halal_check.dart` (`HalalCheck`, `HalalFlag`).
- `core/catalog/barcode_coverage.dart` (counter), `core/navigation/app_route.dart` (`BarcodeScanRoute`), `core/storage/preferences.dart` (two keys).
- `features/foods/data/barcode_api.dart` (generated client → `BarcodeApiResult`: found / notFound / unavailable, never throws), `features/foods/data/pending_scans_store.dart`, `PersonalFoodRepository.byBarcode`.
- `features/foods/application/barcode_lookup.dart` (the chain, pure over ports; maps OFF → `PersonalFoodDraft`, D9), `scanned_food_registry.dart`, `pending_scans.dart` (processor), `food_choice.dart` (`ScannedProduct` + `pendingCreate`), `log_food.dart` (atomic create + log), `foods_providers.dart`.
- `features/foods/presentation/barcode/barcode_scan_screen.dart` (camera, manual entry, pending list, result states), `scanned_product_header.dart` (in the food sheet), `halal_warning.dart`; `food_result_row.dart` shows the halal note; personal-food form attribution.
- `features/today/presentation/today_screen.dart` (button), `features/settings/presentation/about_screen.dart` (OFF credit + counter line), ARB strings, Android manifest comment.

#### 4. Work packages (one commit each, local only)
1. Plan (this text). 2. Contract + `make gen`. 3. Server: Gtin, OFF client, cache, lookup, endpoint, migration, expiry job, telemetry scrub, tests. 4. Domain: Gtin normalize, HalalCheck, tests. 5. App data/application: API port, chain, registry, atomic log, pending store/processor, counter, tests. 6. App UI: scanner route/screen, sheet header, halal notes, About, form attribution, ARB. 7. Close: cross-check, Outcomes, board, backlog, `make progress`.

#### 5. Test list (TD-104 lean: logic and risk, one happy path per new screen, no copy assertions)
- **Server, `Persistence.Tests/BarcodeLookupTests.cs` (Testcontainers + fake OFF `HttpMessageHandler`):** found → cached → second call makes no OFF request; not-found negative cache; expired row refetch; stale-if-error within 7 days, 503 after; OFF 429 → cool-down (no further calls) → 503 with Retry-After; global budget → 503; per-user budget → 429; invalid code → 400; unauthenticated → 401; User-Agent header sent and no auth/cookie headers; **release import leaves `off_cache` alone and OFF rows never appear in `catalog.foods`/`names`/`servings`**; expiry job deletes only rows past the window; captured logs never contain the code.
- **Server, unit (`Buddy.Tests`-style project not needed): `Persistence.Tests` covers mapping** (kJ → kcal, out-of-bounds → null, ml basis, caps) with recorded OFF JSON fixtures.
- **Domain:** `gtin_test.dart` (normalize/UPC-E), `halal_check_test.dart` (pork / alcohol / gelatin-unknown, exclusions, Arabic, halal/vegan tags).
- **App:** `barcode_lookup_test.dart` (chain order: personal hit skips pack and API; pack hit skips API; API found complete / missing fiber / incomplete; not found; offline → pending; counter increments), `log_scanned_food_test.dart` (one change set creates the personal food and the entry; Undo removes both; second scan finds the personal food locally), `pending_scans_test.dart` (queue, cap, expiry, processed on trigger, removed when a personal food has the code), `barcode_scan_screen_test.dart` (happy path with manual entry and a fake lookup → sheet → Add → Undo snackbar).

#### 6. Exit-criteria mapping
- B10 "Contract conformance green; Dart client regenerated" → `make check-contract`, `make gen-app`/`gen-dart` with no diff.
- B10 "OFF client respects rate limits and caches (fake OFF); OFF rows never in catalog tables" → `BarcodeLookupTests`.
- B10 label/photo/scrubber criteria → B10b (phase 2), except "no barcode in logs" (log capture test).
- A28 "T17" (scan → product → amount → logged with undo, ≤ 3 taps) → `barcode_scan_screen_test` + `log_scanned_food_test` (scan, Add = 1 tap with the default serving). "T18" is the label flow → A28b.
- A28 "second scan of a label-created product found instantly (local)" → label creation is A28b; the same property is tested for OFF-created and form-created products (`log_scanned_food_test`, `barcode_lookup_test`).
- A28 "offline scan → pending → processed on reconnect" → `pending_scans_test` (reconnect = the next trigger, D10).
- A28 "halal warning tests (pork/alcohol/gelatin-unknown)" → `halal_check_test`.

#### 7. Risks
- ML Kit sends Google anonymous usage metrics about the API (no images or barcode values, per Google's docs). Same class as the Play-services stack; named in the Outcome for the owner.
- OFF's real hit rate for local products may be low (A03 measured it); the not-found path and the counter make that visible.
- Contract enum style: if ASP.NET's document can't express `basis` as an enum cleanly, it stays a documented string (the app validates).

#### 8. Size
M + M as carded, ≈ one long session including one fix round.

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: split into a/b (TD-105, owner).
- 2026-10-30: B10a + A28a planned as one combined step (owner), self-approved (TD-037); branch `step/B10a-A28a-barcode`, lane 3.
- 2026-10-30: implemented (contract, server, domain, app); cross-check run; closed, awaiting the Codex review and merge.
- 2026-10-30: Codex review round 1 CHANGES-REQUIRED (4 majors, 4 minors); all fixed, cross-check rerun; awaiting the fix-check.
- 2026-10-30: fix-check: 2–8 fixed; round 2 closes the remaining profile race (epoch rechecked after every await, test holds the next profile's store load), shows the OFF credit on the new prefill form and sharpens the ML Kit wording.

## Outcome
### B10a + A28a (2026-10-30, before the Codex review; CI evidence comes from the merge run, TD-108)

**Built.** The input bar's barcode button (now in every flavor; the camera button stays dev-only) opens the scanner: mobile_scanner 7.4.2 reading EAN-13/EAN-8/UPC-A/UPC-E with the bundled ML Kit model, plus "Type the code" when the camera is off or denied. Chain: your foods by barcode (GTIN-normalized match) → offline pack (empty today) → `GET /v1/foods/barcode/{code}`. A found product opens the existing food sheet with a product header (brand, one serving's values, halal note when the setting is on, fiber note, "© Open Food Facts contributors"). **Add** is one tap with the default serving; for an OFF product it creates the personal food (`createdFrom: off`, barcode linked) and the entry in one change set, so one Undo removes both and the next scan is local. Incomplete or unknown products open the new-food form (nested route `/today/scan/new-food`) prefilled with the barcode and whatever OFF has. A lookup that can't run waits in a device-only list (≤ 20, 14 days), shown under the camera and retried when the scanner opens, when the app resumes and after a successful lookup. About gains the OFF credit and the on-device coverage line. The server side (B10a) is described in B10's Outcome.

**Commits:** `docs(B10a,A28a): combined low-level plan` · `feat(contracts)` · `feat(catalog)` (server) · `feat(domain)` (GTIN + halal) · `feat(foods)` (app) · `fix(foods)` (pending processing never breaks its trigger; tests follow) · `test(foods)` (rename) · close docs.

**What the user sees.** Scan → food sheet with the product → Add → back on Today with "Added … · Undo". Not found: "We don't know this product yet" + Add it yourself / Scan another. Incomplete: "Some values are missing" + Add the missing values. Offline or server down: "Can't look it up right now" + Add it yourself; the code shows under "Scanned earlier" and turns into "Found · tap to log" or "Not found · tap to add it yourself" later. Bad code: a snackbar.

**New permission and dependency.** `android.permission.CAMERA` from mobile_scanner's manifest (`android.hardware.camera` `required=false`), asked at first use; documented in the app manifest. `tools/scripts/apk_hardening_check.py` is a deny-list (biometric permissions only), so it needed no change; `make apk-hardening-selftest` and `build-android-selftest.sh` pass. ML Kit (bundled) may send Google anonymous API usage metrics (no images or barcode values); decoding is on the phone.

**Tests (TD-104 lean).** fb_domain: `gtin_test.dart` (normalize, UPC-E), `halal_check_test.dart` (pork / alcohol / gelatin-unknown, exclusions, Arabic, tags). App: `test/features/foods/barcode/barcode_lookup_test.dart` (chain order, coverage, OFF → draft rules, atomic log + Undo + local second scan, pending scans), `barcode_scan_screen_test.dart` (happy path: typed code → sheet → one Add → scanner closed, Undo shown, entry stored; coverage counter). Updated: router test (two routes), Today test (barcode button in every flavor), About test (OFF credited by the app), goldens `today_empty_day`, `today_full_day`, `today_targets_under` (barcode button) and `about` (OFF credit).

**Exit criteria.** T17 → the scan-screen happy path + atomic log test (T18 is A28b's label flow). "Second scan found instantly (local)" → proven for OFF-created foods (label-created foods are A28b). "Offline scan → pending → processed on reconnect" → pending tests (reconnect = the next trigger, D10). Halal tests → `halal_check_test.dart`.

**Deviations.** (1) The pack/catalog step on the server is a no-op until a release carries barcodes (D1; backlog #225). (2) Halal notes on Buddy proposal cards are left to phase 2 (#226). (3) Salami/pepperoni/chorizo are not flagged (halal beef versions are common locally). (4) A form-completed OFF product keeps `createdFrom: form` (#227). (5) The whole-repo `dart analyze` crashed locally (analysis server, memory with other lanes busy); `dart analyze --fatal-infos apps packages tools` is clean, as are format, app-check, frozen migrations and `make gen-app`/`gen-dart` (no diff).

**Follow-ups:** backlog #225, #226, #228, #229 (#227 done in the fix round). **Size:** about the planned M + M in one session plus one fix round.

**Codex review round 1 (CHANGES-REQUIRED: 4 majors, 4 minors, no blockers) — all fixed:**
1. *Pending scans leaked across accounts* → one list per environment and local profile (`fb.pending_scans.v1|<flavor|api>|<profileKey>`), rebuilt on each profile switch, deleted with the profile (`OpenProfileHost.onDeleted`); processing started for an older profile never writes into the new one. Tests: profile switch/race/deletion in `barcode_lookup_test.dart`, `open_profile_host_test.dart`.
2. *OFF provenance lost after saving* → `OffOrigin` (fb_domain) encodes OFF origin, the fiber-0 mark and the scan's halal flags in the existing `createdFrom` code (`off[F][P][A][U]`, letters only, within the wire rule: no sync or drift change). The second scan shows the same halal note, fiber note and credit; a form completed from an OFF prefill keeps the origin (typing fiber clears the mark); pending names found in OFF show the credit. Tests: second scan and form path in `barcode_lookup_test.dart`, `off_origin_test.dart`.
3. *Pending scans dropped too early* → removed only after a log, a saved food (form, normalized barcodes) or an explicit dismissal. Tests: dismissed sheet and opened-but-unsaved form in `barcode_scan_screen_test.dart`.
4. *Ambiguous typed UPC-E/EAN-8* → a code valid as both asks which (`BarcodeLookup.typedReadings`). Tests: `01000009` (unit + widget).
5. *HTTP-date Retry-After* → read against the injected clock, then bounded. Test: both forms × 429/503 through the real client.
6. *Single flight ended before the cache write* → the shared operation includes publishing; a cancelled caller only stops waiting. Test with a delayed write and a cancelled waiter.
7. *Not-found didn't replace a stale product* → always negative-cached; stale serving only for OFF errors. Test.
8. *ML Kit disclosure* → a factual line on About (ARB), Google's disclosure address in the text (About has no external links); no patrol test uses the copy.
Also added: rollback when the log write fails (nothing saved) and an OFF scan → Add → Undo widget flow (both removed). About golden updated.
