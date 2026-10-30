# A24 — Online search & pack updates (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A07, **B07** | M | Claude (TD-085; was Codex, TD-078) | ✅ Done |

_Old ID: S30 app part (renumbered by TD-063, 2026-10-16). The server side is B07._

**Goal.** Search finds everything the server catalog has when online, without ever slowing the local results, and the offline pack updates itself safely in the background.

**Spec:** FD-020 (online full search), FD-021, FD-023 (pack updates) · **Decisions:** TD-005, TD-010

## Scope
- **Online search merged with local results:** local results first, online results appended when they arrive, de-duplicated by catalog ID (`07` §5.2). Offline: local only, no error state.
- **Pack update** in the background (`07` §6): `GET /v1/catalog/packs/latest` → download → verify checksum → atomic swap → reattach `catalog.db`. Never on the startup path; a failed or partial download leaves the current pack in use.

## Out of scope
- The server catalog and pack publishing (B07). Barcode lookups (A28).

## Exit criteria
- [x] The app merges online + offline results without duplicates (integration test): Patrol `patrol_test/online_search_test.dart`.
- [x] Pack update E2E: host integration test through the generated client with real pack bytes and real ATTACH (diary entries unaffected); the laptop-server run is owner/A55 check #185.
- [x] A corrupted download is rejected and the old pack stays (test): unit + host integration tests, incl. a valid SQLite file with the right hash but no catalog tables.

## Read first
`07-food-data.md` §5–6 · `05-data-and-sync.md` §3 · A05, B07 Outcomes

## Owner involvement
- **Owner/A55 check (can't run in CI):** pack update end to end against the laptop server: publish a new catalog release (B07 runbook) → relaunch the app on the A55 (guest session online) → About shows the new pack version; Today's diary entries unchanged; airplane mode afterwards still searches the new pack. Host evidence in CI: `test/core/catalog/catalog_pack_update_integration_test.dart` (generated client, fake HTTP transport, real pack bytes, real ATTACH).

---

## Low-level plan
_Written 2026-10-29 by the A24 engineer (time-boxed session; architecture + code review follow later)._

**Design**
- **D1 Online search is additive, never blocking.** `FoodSearchController` publishes local results exactly as today. After a local result for a non-empty query is published, it schedules an online search (300 ms debounce, latest query only, revision-guarded) through `OnlineFoodSearch` (features/foods/data) → generated `CatalogClient.searchFoods(query, limit: 20)`. Any failure (offline, no session, 4xx/5xx, timeout) yields "no online rows": no error state, nothing logged or reported (query text is user content).
- **D2 Merge = local first, online appended, dedup.** `FoodSearchService.appendOnline(local, online)` appends online foods after the local rows, skipping any whose identity keys (`catalog:<id>`, `dish:<id>`, strict name+state key, the same keys A07 dedups by, `07` §5.2) are already present; server order kept for the appended part; cap 20 appended rows. Quantity-carried queries search the name part only.
- **D3 Mapping.** API `CatalogFood` → app `CatalogFood` in `catalog_api_mapping.dart` (core/catalog): `catalogKey` is the stable catalog ID; `usda`/`reference` sources only (unknown sources, e.g. future OFF, are dropped); per 100 g (B07 rejects per-100 ml releases); servings with g/ml and ranges; `dishId` derived from `ref:<dish>/<variant>`; `packVersion = catalogVersion`.
- **D4 Online-only food selection.** An in-memory, keep-alive `OnlineFoodCache` remembers the mapped foods of recent online results (bounded, 200). `FoodChoiceLoader` falls back to it when the pack lacks the ID, so the sheet and `LogFood` work unchanged (the entry stores its own snapshot, so later offline use is the history path). No persistence, no new table.
- **D5 Pack update.** `CatalogPackUpdater` (core/catalog): `getLatestCatalogPack()` → skip unless `schemaVersion == supportedPackSchema` and `version` > installed → `downloadCatalogPack(version)` → verify `sizeBytes` and SHA-256 (package `crypto`, already a dependency) → write `catalog-<v>.db.tmp`, rename to `catalog-<v>.db` (atomic on the same directory) → `db.reattachCatalog(newPath)` → delete older packs and stale `.tmp`. Any failure deletes the temp file and leaves the current pack attached. If the attach of the new pack fails, re-attach the previous pack and delete the new file.
- **D6 Trigger.** `AppBootstrap` runs the updater after the bundled install/attach, off the first-frame path, contained (errors → kind only, no paths/content). Once per launch, so a new release is "picked up on next launch". The bundled installer already keeps a newer downloaded pack (`newest > version`).

**WPs**
1. Online search + merge + online food cache + loader fallback (+ unit tests).
2. Pack updater + bootstrap trigger (+ unit tests with a temp dir and fake client).
3. Card Outcome / evidence after review (later session).

**Tests (spec IDs)**
- `FD-020 maps an API catalog food to a catalog food` / `drops unknown sources`.
- `FD-020 FD-021 online results append after local without duplicates` (catalog-ID and name+state dedup).
- `FD-020 offline: online failure keeps local results, no error` (controller with a throwing fake).
- `FD-020 stale online results are discarded` (revision guard).
- `FD-020 an online-only food loads through the cache`.
- `FD-023 pack update installs a newer verified pack and reattaches`.
- `FD-023 corrupted download (checksum/size mismatch) is rejected; old pack stays`.
- `FD-023 same or older version / unsupported schema is a no-op`.
- `FD-023 failed attach restores the previous pack`.

**Decisions taken (no TD needed; within card scope)**
- Debounce only on the network leg (local stays undebounced, A07).
- In-memory cache instead of persisting online foods: the diary entry snapshot already makes logged foods durable (TD-005 snapshots).
- Exit-criterion integration/E2E tests (merge on emulator; pack update against the laptop server) are deferred to the review session; this session ships unit tests only (owner time box, no local test runs).


## Progress log
- 2026-10-29: Plan committed (d63a9f3). WP1 online search + merge + cache + loader fallback (75c7676). WP2 verified background pack updater + bootstrap trigger (dff6b34). Only codegen + `make check-dart` run locally (owner rule: no local tests); CI on the branch is the test evidence. Deviation: app_check's lexical `update(` rule → method named `checkForUpdate()`; test phones switch the pack check off (`catalogPackUpdatesEnabledProvider`) so existing exact request-log tests stay valid. Open: emulator merge integration test and laptop-server pack E2E (exit criteria 1–2) not written yet; online-failure empty results are cached per query (no retry until the query changes).
- 2026-10-29 15:45: CI on 75c7676 (WP1) showed `dart-test (app:3/3)` failing; logs unreadable (anonymous GitHub API rate limit). Likely cause: the online-leg Timer left pending in widget tests, or online requests on TestPhone logs. Fix e4ee33f: decide synchronously before scheduling (no timer when online search is unavailable) and test phones switch online search off (`onlineFoodSearchEnabledProvider`). **Next session: read CI on e4ee33f first**; if app:3/3 is still red, check `online_search_test.dart` (controller-leg tests use real 10 ms delays) and the food-search widget tests.
- 2026-10-29 (review round 1, Codex review): merged origin/main (A44) into the branch; a rebase would have needed a force push, so I merged instead. #1 downloaded pack validated with real SQLite before promotion (`core/db/catalog/catalog_pack_validator.dart`: quick_check, all pack tables readable, meta schema + catalog version = manifest) + host integration test through the generated client (34c1303). #2 online failure (null) vs answer (list, empty included): only answers cached; failures retried 2/5/15 s for the same query; #4 waits via `onlineSearchWaitProvider`, no global `onlineDelay`, no real-time waits (34b16b0). #5 TestPhone `onlineSearch`/`packUpdates` opt-ins (94bb0d3). #6 one pack-check retry when the session next becomes ready (6c0a58c). #3a Patrol `patrol_test/online_search_test.dart` with `CatalogFakeAdapter` + Buddy's auth fake (`buddyFakeApi` now takes any adapter + flavor); #3b host integration test (in #1); laptop E2E recorded as an owner/A55 check (Owner involvement). Last commit tagged `[it]`.
- 2026-10-29 (Codex fix check): validator checks all schema-v1 columns per table; `OneRetry` with the listener registered before the attempt; online retry budget and deadline kept per normalized query across same-query refreshes (`OnlineSearchTime`, virtual time in tests).
- 2026-10-29 · Close: Outcome written, board ✅, backlog #185–#187; merge via `merge-step.sh` (CI incl. `[it]`).

## Outcome
**Built (2026-10-29).** Search now also asks the server catalog, and the offline pack updates itself in the background, safely.
- **Online search (FD-020/021):** local results still appear instantly and unchanged. 300 ms after a local result for a non-empty query, `OnlineFoodSearch` calls the generated `CatalogClient.searchFoods` (20 rows). New foods are appended after the local rows; duplicates are dropped by catalog ID, dish, or strict name + state (the A07 keys, `FoodSearchService.appendOnline`). A failure (offline, auth, server) returns `null`: no error state, nothing logged (the query is user content), retried for the same query after 2/5/15 s; the attempt count and next deadline belong to the normalized query, so a same-query refresh resumes the budget (and joins a request in flight) instead of restarting it. Only answers (empty included) are remembered per query. Server foods map to the app's `CatalogFood` in `core/catalog/catalog_api_mapping.dart` (`usda`/`reference` only; OFF waits for B10/A28). Online-only foods open from an in-memory `OnlineFoodCache` (200) that `FoodChoiceLoader` falls back to; logging stays `LogFood` → ChangeSetApplier, and the entry keeps its own snapshot.
- **Pack update (FD-023):** `CatalogPackUpdater.checkForUpdate()`: latest metadata → skip unless supported schema and newer → download → size + SHA-256 → temp file → **real-SQLite validation** (`core/db/catalog/catalog_pack_validator.dart`: quick_check, every pack table with all its schema-v1 columns readable, meta schema and catalog version = manifest) → atomic rename → reattach → delete older packs. Any failure keeps the current pack; a failed attach restores it. The bootstrap runs it after the bundled install, after the first frame, once per launch, with one retry when the session becomes ready (`OneRetry`; the readiness listener is registered before the first attempt, so readiness during it triggers the retry right after a failure). Never on the startup path.

**Deviations (and why):**
- `checkForUpdate()` instead of `update()`: app_check rule 11 matches `update(` lexically as a drift write.
- `onlineFoodSearchEnabledProvider` / `catalogPackUpdatesEnabledProvider` (on in the app) with TestPhone opt-ins (`onlineSearch`, `packUpdates`, default off): existing startup/session tests assert exact request logs; `realNetwork` tests can opt in.
- The validator lives in `core/db/` because only `core/db/` may open a SQLite connection (rule 11); it is read-only.
- Review round 1 merged `origin/main` into the branch instead of rebasing: a rebase needs a force push, which the permission system blocks; the squash merge makes the history moot.
- Laptop-server E2E can't run in CI → owner/A55 check #185; CI evidence is the host integration test.
- `buddyFakeApi` (A22a Patrol support) now takes any adapter and a store flavor, reused for the catalog fake.

**Follow-ups:** #185 (owner/A55 laptop-server pack E2E), #186 (no retry on resume/connectivity), #187 (stream large pack downloads, B14).

**TDs:** none (within card scope; no spec or Accepted-TD change).

**Metrics:** size M as planned. 2 WPs + 1 review round. Reviews: Codex code review round 1, 3 majors (pack validation, failure vs empty caching, missing integration evidence) + minors (test timing/global state, TestPhone opt-ins, updater retry), all fixed; Codex fix check: 1 major (missing-column packs accepted) + 2 minors (readiness during the first attempt, same-query refresh reset the retry budget), all fixed. Tests added: 34. 15 online search (mapping, cache, merge/dedup, loader fallback, controller incl. retry budget and stale discard), 11 updater unit (real SQLite packs, incl. a dropped column), 3 host integration (generated client, fake transport, real ATTACH, diary preserved), 4 retry helper, 1 Patrol (emulator merge). Local runs: codegen + `make check-dart` only (owner rule); CI on the branch is the test evidence.
