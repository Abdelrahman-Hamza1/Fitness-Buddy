# A62 — Estimates: a meal or a whole day in one number (A62a meal · A62b day)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App + Backend (contract-first) | A57, A38, A16, A39a, A34, B05 | A62a L (2–3 sessions) · A62b M (1–2 sessions), each incl. one fix round | Claude (Opus plan + build: `flutter-engineer`, `dotnet-engineer` for the server WPs), two Codex reviews per part (Risky) | ✅ Done (owner acceptance by use, TD-037) |

_2026-11-06. Owner-approved design (Estimates mockups `~/work/ux-sketches/next-ux-2026-11-06/Estimates.dc.html`: E1 A + B, E2 A, E3 A). Tier **Risky**: new user-data writes, new sync payload versions, and a server admission change. **Split (D1):** A62a = meal estimates + knowledge-aware aggregation (diaryEntry/savedMealItem v2); A62b = day estimate (dayMark v2), after A62a. One card, two branches, two merges._

**Goal.** Log "about 700" for a meal you ate out, or "about 2,300" for a day you didn't log, in a few taps and offline. The user types the number; the app never invents one. Estimates count like food; day estimates stay out of the adaptive target. A missing macro is unknown, never zero, everywhere it is summed or averaged. On screen an estimate is only "~" and the number; tapping "~" is the only explanation.

**Spec:** DY-004, DY-020–024, DY-031, AI-031, AI-032, AI-048, TG-031, TG-032, TG-041, IN-001–003, HM-001, HM-002, FD-010, FD-012, SF-041 · **Adds** DY-005, DY-006 and **amends** DY-004, TG-031, TG-032, IN-001–003, HM-001, HM-002, AI-032, FD-012, `spec/11` §2, glossary (D-096, after owner approval) · **Decisions:** D-011, D-045, TD-070, TD-080, TD-084, TD-104, TD-113.

## Scope
- **A62a.**
  - **E1 A:** "~ Estimate" next to Scan on a meal's add screen (the food search): one big kcal number, an optional Name, "+ Macros" reveals protein, carbs and fat, each optional on its own. "Add ~700 kcal". A direct action with Undo (AI-048), offline.
  - **E1 B:** a search row `~ Estimate "<query>"` (also when nothing matches) with the query as the name.
  - Edit (tap the row) and Swap for foods (from the "~" popup).
  - **Knowledge-aware aggregation everywhere:** explicit per-nutrient "known" flags flow through every sum and average, and "~" provenance flows through every total, including week lines, buckets, dish groups and saved meals.
- **A62b.**
  - **E2 A:** a past day with nothing logged shows a compact "Didn't log Tuesday?" card with "about ___ kcal" → a day estimate, stored on the day mark (dayMark v2). The day then shows "~2,300".
  - **E3 A:** it counts in Today, charts (hatched), averages and the weekly budget, but not in the adaptive target or macro averages.
- "~" + number only. Tapping "~" on your own estimate opens "~ Your estimate" with **Edit** and **Swap for foods**. Totals that include any estimate show "~".

## Out of scope
- E2 B (top up a partly logged day): use a meal estimate (owner).
- New Buddy features. Buddy's own `~ estimate` (AI-151) is unchanged. A25 (diary edits by chat, phase 2) inherits the knowledge flags.
- A range or "why" for your own estimates (they have none).

## Fixed by the plan
- Owner design above (2026-11-06), including the minimal text.
- Single writer (`ChangeSetApplier`), local-first, contract-first (contract WP → `make gen` → server → app), no user content in logs, frozen migrations (new migration files only).

## Exit criteria
**A62a**
1. A meal estimate can be added from the add screen and from a search query: kcal only, or with any subset of protein/carbs/fat. It applies at once with Undo and works in airplane mode.
2. Edit is prefilled. Swap for foods keeps the estimate while searching; on selection one change set replaces it, with one Undo; cancel or failure writes nothing.
3. An omitted macro is never displayed, summed as known, or averaged as 0. This holds in Today, meals, dish groups, saved meals (save and relog), Progress daily bars, week/month buckets, day details, the weekly summary (protein days, fiber), Buddy's day preview and export. An explicit 0 stays a known 0.
4. "~" appears on every total that includes an estimate, including the week line when the estimate was earlier in the week.
5. `diaryEntry` and `savedMealItem` v2 are in the contract; the server admits v1 and v2, rejects mismatches and W1–W3 violations, and refuses a v1 write over a stored v2 (tests). v1 documents upgrade losslessly. After an old-client edit, recovery keeps v2 (both sync orders).

**A62b**
6. A day estimate can be saved on a past day with nothing logged, edited and removed, with Undo. It is refused when the day now has food, and a stale editor gets a conflict, never an overwrite.
7. Logging or moving any food (including a dish move) onto a day with a day estimate replaces it in the same change set (one Undo), on every path. Deleting the last food reactivates a superseded estimate.
8. Day estimates count in Today, Progress (hatched), averages and the weekly budget, and are excluded from the adaptive estimate and from macro averages.
9. `dayMark` v2 is in the contract, admitted by the server and round-trips. After two offline devices sync (one logs food, one sets an estimate), the outcome is the D13 rule.

**Both:** the merge CI is green, including `gen-check`, goldens and `trace`. D-096 is applied, or, without approval, nothing in `spec/` changed.

## Read first
- The mockup above; `spec/12` §1, `spec/13` §4, `spec/16`, `spec/11` §2, `spec/10` AI-031/032/048/151.
- `05-data-and-sync.md` §1; TD-070, TD-080, TD-084; `contracts/README.md` (sync admission, **weighIn versions**: the v2 precedent).
- `A34-sync-engine-app.md` D7 (deferred and parked documents), `B19-body-targets-sync.md` (weighIn v2 server side), `A38`, `A16`, `A39a`, `A57` Outcome (stale `.g.dart` and goldens at merge).

## Owner involvement
- Approve the D-096 text (D21). **Rec: ok.**
- After merge: the laptop server is redeployed from `main` **before** the new APK is installed (D6). The orchestrator does it; the owner is told.
- Optional: try E1/E2 on the A55 (acceptance by use, D-087).

---

## Low-level plan
_Claude (step planner), 2026-11-06, **rework v2** after the Codex plan review (verdict "rework"; review of `a772e7d8`). The first plan, a pseudo meal slot and an inner-JSON knowledge marker with no contract change, is withdrawn. Paths are relative to `apps/mobile/` unless they start with `packages/`, `backend/`, `contracts/`, `spec/` or `technical-planning/`._

### Plan-review response
| Finding (Codex) | Amendment |
|---|---|
| 1 Missing meal macros become known zeros in Progress/summary | **PA1:** explicit per-nutrient `*Known` fields in diaryEntry/savedMealItem v2 (D3), and one knowledge-aware total type `IntakeTotals` with per-nutrient coverage used by every reader in the inventory (D8–D10); per-nutrient average denominators; unknown protein is not a missed target (D10) |
| 2 "~" scoped too narrowly | **PA2:** `estimated` is carried independently of day status: entries → `IntakeTotals.estimated` → `DailyTotals` → `DayIntake`/week line → `ProgressDay` → buckets → summary; dish groups and saved meals use `IntakeTotals` (D9) |
| 3 SetDayEstimate lacks transactional rules | **PA3:** the day estimate moves to `dayMark` v2 (D4). `SetDayEstimate` has explicit create/edit/clear/recreate modes with an expected-version check, and refuses creation when the day has food, inside the applier transaction (D12). Two-offline-devices rule and its tests (D13) |
| 4 Day swap deletes before replacement | **PA4:** every food log on a day with a day estimate clears the estimate in the **same** change set (handler rule, D12). Swap = search with the estimate kept; cancel writes nothing. Meal swap already works this way (D11) |
| 5 Older clients can corrupt the pseudo-slot / JSON | **PA5:** no pseudo slot, no inner JSON. New fields are a new schema version, and older builds **defer** v2 documents (A34 D7), so they can't rewrite them. Minimum writer rule in D6 |
| 6 Export shows unknown as zero | **PA6:** export gets the explicit columns (`user_estimate`, `*_known`, `estimate_kcal`), documented, with fixtures (D14) |
| 7 FD-012 exception | **PA7:** user estimates are totals, not foods: they never enter `SanityCheck`. Spec FD-012 gets the explicit exception (D-096), tested through the logging path (D7) |
| R2-1 Old writers can overwrite v2 | **PA9:** server-side downgrade refusal + new-app recovery order (D23) |
| R2-2 Explicit-zero overrides discarded | **PA10:** known state in both no-op checks, knowledge-aware override sheet (D24) |
| R2-3 Clear-on-food misses `MoveDishGroup` | **PA11:** `MoveDishGroup` added, one clear per destination date, last-food-deleted rule (D12, D13) |
| R2-4 Ramadan, Buddy preview, raw surfaces | **PA12:** Ramadan admits day estimates (D25), Buddy context carries `IntakeTotals` (D15), raw-surface inventory (D26) |
| R2-5 Zero-storage invariant unenforced | **PA13:** W3 "unknown ⇒ zero" in the server validator, the vectors and local construction; aggregation relies on it (D27) |
| 8 WP gates vs PROCESS.md | **PA8:** local = codegen + `make check-dart`/`check-dotnet`/`dotnet build` only; the merge CI runs the tests (PROCESS.md owner rules 2026-10-30). The reader inventory is done **in this plan** (below), before the model is fixed |

### Reader inventory (done before the model; `git grep` at `367182d1`)
Every reader of entry snapshots, day totals or day marks, and what A62 does with it:

| Reader | Today | A62 |
|---|---|---|
| `fb_domain` `DiaryTotals.day/slot/bySlot`, `DayLayout.totals`, `SlotSection.totals` (`diary/totals.dart`, `day_layout.dart`) | `Nutrients.sum` of snapshots | Add `DiaryTotals.intake(entries) → IntakeTotals`; `DayLayout.intake`, `SlotSection.intake` (A62a) |
| `DishGroup` header kcal (`diary/presentation/group_rows.dart:12`) | plain kcal | `GroupItem.intake` → "~" (A62a) |
| `SavedMeal.totals` (`fb_domain diary/saved_meal.dart:67`), `saved_meal_screen.dart:259`, `saved_meals_screen.dart` | plain sums, all macros numeric | `SavedMeal.intake`; screens use "~"/"—" (A62a) |
| `DiaryReads.dailyTotalsSql` → `DailyTotals` (`diary/data/diary_reads.dart:34`, `diary_day.dart:42`) | SUMs, n, meals | + `SUM(is_estimate)`, `SUM(NOT protein_known)` … per nutrient → `DailyTotals.intake` (A62a); + day-mark join (A62b, D9) |
| `watchDailyTotals` callers: `progress_providers.dart:39`, `ramadan_comparison_provider.dart:50` (+ D25), `targets_providers.dart:172` (`_weekIntake`), `adaptive_providers.dart:48`, `adaptive_actions.dart:597`, `notification_inputs.dart:179`, Buddy `proposal_input_loader.dart:240` | read `.totals` | all move to **one** projection `DiaryRepository.watchDayIntake(from, to)` → `List<DayIntakeTotals>` (entries + day mark, D9). Notifications use `entryCount`/kcal only (no change beyond the type) |
| `TodayNumbersView` (`today/application/today_numbers_view.dart:26`), `TodayNumbers`, `SlotHeaderTile`, `SlotMacrosLine`, `TodaySummaryCard` | `Nutrients` | `IntakeTotals` + week `estimated` (D9, D16) |
| `ProgressSeries` / `ProgressBuckets` / `WeeklySummary` (`fb_domain insights/*`) | `Nutrients eaten`, averages over counted days | `IntakeTotals eaten`, nullable per-nutrient averages, `estimated` (D10) |
| `macros_section.dart:182`, `calories_section.dart:103`, `progress_day_details.dart:57`, `progress_text.dart:92` | numeric zeros | `valueOf → null` = no bar / "—"; partial = "~" (D10, D16) |
| `TargetsTimeline` week intake (`DayIntake`, `targets_timeline.dart:258`) | kcal + incomplete | + `estimated` → `TargetDay.weekEstimated` → week line "~" (D9) |
| `intakeDaysOf` (`adaptive/application/adaptive_inputs.dart:14`) | kcal + mark | A62b: day-estimate days `incomplete: true` (D9) |
| `FoodColumns.of/fromEntry/fromSavedItem`, `entryChanges`, copy (`diary_copy.dart:98`), `LogSavedMeal`, `SaveMeal`, `ReplaceEntryFood`, `OverrideNutrients` | copy the column set | the new columns are in `FoodValueColumns`, so every copy carries them. A food change resets them (D3). Override of a user estimate sets the overridden nutrient known (D11) |
| `RamadanComparison.compute` (`fb_domain ramadan/ramadan_comparison.dart:83`), `ComparisonDay`/`ComparisonSide` | drops `entryCount == 0` days, no provenance | A62a: `estimated` on `ComparisonDay`/`ComparisonSide` → "~"; A62b: admit `dayEstimate` days explicitly (D25) |
| Buddy `ProposalDayContext.confirmed` + `_preview` (`proposal_targets.dart:23,107`), `food_proposal_card.dart:268` | `Nutrients`, card's own estimate flag | `Map<LocalDate, IntakeTotals>`; `_preview` → `IntakeTotals`; card "~" = own estimate ∨ preview `estimated` ∨ a shown macro not `full` (D15) |
| Notifications protein nudge (`notification_inputs.dart:119`) | `totals.protein` vs target | A62a: protein not `full` and lower bound < target → no protein nudge that day (unknown, not low) |
| Raw snapshot surfaces: entry details, `entry_amount_sheet` + `core/ui/nutrition_summary.dart`, `nutrient_override_sheet`, saved-meal item rows, `live_entry`/`live_meal` | `Nutrients` | D26 |
| Food history / quick-add (`diary_repository.dart:89`, `quick_add_ranker.dart:214`) | exclude estimates | unchanged |
| Export (`core/export/export_registry.dart:64,146,233`) | explicit column lists | add the new columns (D14) |
| Sync codec (`ColumnSyncCodec`), `SyncDocumentUpgraders.currentVersions` (`fb_domain sync/document_upgraders.dart:13`) | 1:1 columns, weighIn v2 | diaryEntry 2, savedMealItem 2 (A62a); dayMark 2 (A62b) |
| Server admission (`backend/.../SyncPayloads.cs:17`, registry `Schemas/entities.json`) and winner selection (`PostgresSyncStore.cs:122`, HLC only) | registry-driven: unknown version → `unsupported`; no schema-downgrade check | registry regenerated from the contract; row-local `DiaryEstimatePayloadValidator` (D5, D27); downgrade refusal (D23) |
| Phone parked/deferred (`drift_sync_store.dart:437` `retryParkedIfDue`, `:681` `_applyOne`, `fb_sync engine.dart:126`) | parked retried on app-version change or daily (exists); deferred retried each run; pulled docs skipped when `hlc ≤ local` | recovery order + server-refused-loses rule (D23) |

### Summary
**A62a.** Meal estimates are diary entries with two explicit new facts: `userEstimate`, and which of protein/carbs/fat/fiber are known (`proteinKnown` …). Both are columns in `diary_entries` and `saved_meal_items` (drift 14→15) and fields in **diaryEntry v2 / savedMealItem v2** (contract first, server admits them with a small row-local validator). Unknown values are stored as 0 but **every reader goes through `IntakeTotals`**, which tracks per-nutrient coverage (full / partial / none) and "estimated", so nothing shows or averages an unknown as zero. The add screen gets `~ Estimate` and `~ Estimate "<query>"`, one `EstimateSheet`, and a "~ Your estimate" popup with Edit and Swap.

**A62b.** The day estimate is an `estimateKcal` on the existing per-date day mark (**dayMark v2**, natural ID, drift 15→16). A transactional `SetDayEstimate` op handles create/edit/clear with version checks. A handler rule clears the estimate in the same change set whenever food is logged that day. One shared day-intake projection adds it to totals and excludes it from adaptive and macro averages. The UI has the "Didn't log Tuesday?" card and a "~2,300" day row.

### Decisions
- **D1 Split: A62a then A62b.** A62a (6 WPs) and A62b (5 WPs) are each one branch, one merge and two Codex reviews (Risky). A62b depends on A62a's projection and `IntakeTotals`. Reason: 11 WPs in one step is past the ~6-WP lesson from A57, and the seam is clean, because meal knowledge needs no day mark and the day estimate needs no meal UI. One engineer per part (`flutter-engineer`; `dotnet-engineer` for the server WP).
- **D2 Meal estimate row.**
  - `food_kind = 'estimate'`, `food_id = NULL`, `source = 'yours'`, `is_estimate = 1`, `edited_by_user = 1`, **`user_estimate = 1`**.
  - Values: per-100 = the typed totals, `amount = 100`, basis `g`, input `Quantity(1, 'serving')`. The snapshot equals the typed numbers (FD-073).
  - Unnamed: `name_en = 'Estimate'` plus `named` derived from it (`UserEstimate.unnamedName`). The UI shows the ARB label.
  - Reason: existing enum codes, so no TD-080 code addition. The explicit flag replaces the earlier "source tells it" inference.
- **D3 Explicit knowledge fields** (contract-facing, chosen over inner JSON).
  - New columns in `FoodValueColumns` (so both tables): `user_estimate BOOL NOT NULL DEFAULT 0`, `protein_known`, `carbs_known`, `fat_known`, `fiber_known BOOL NOT NULL DEFAULT 1`.
  - Wire: `userEstimate`, `proteinKnown`, `carbsKnown`, `fatKnown`, `fiberKnown` (booleans, required in v2). Unknown values are stored as 0 in the numeric columns, so SQL SUMs stay correct lower bounds. kcal is always known.
  - A user estimate sets `fiberKnown = false` (never asked), and protein/carbs/fat known exactly when typed. An explicit 0 typed = known 0.
  - A **food change** (swap, change food) resets to `userEstimate = false` and all known, because `FoodColumns.of` derives the fields from the new `EntryFood`.
  - Reason: once a payload version is bumped anyway, booleans cost the same upgrader work as JSON. They're readable in export, admissible by schema, aggregatable in SQL, and old clients defer them instead of silently dropping them (finding 5). The rejected options were inner JSON (opaque, lost on old rewrites) and nullable macro columns (a table rebuild, plus `Nutrients` nullable across the codebase).
- **D4 Day estimate on the day mark (A62b).**
  - `day_marks.estimate_kcal REAL NULL CHECK (estimate_kcal IS NULL OR estimate_kcal BETWEEN 1 AND 20000)`; wire `estimateKcal: number|null, minimum 1, maximum 20000`.
  - One row per date already (natural ID `dayMark:<date>`, TD-070), so there are no duplicates and no pseudo slot.
  - Clearing sets it to null (the row stays and keeps `incomplete`/`notFasting`). **Deviation (A62b review fix):** `day_marks.estimate_only BOOL NOT NULL DEFAULT 0` / wire `estimateOnly: boolean` marks a mark that exists only to hold the estimate (created by `SetDayEstimate` on a day with no live mark). Clearing the estimate of such a mark (by hand, Swap or food replacing it) **tombstones** it, so the day goes back to "no mark": its food is never read as an explicit "count again" confirmation and DY-004 can still suggest it. Any `MarkDay` makes the mark the user's own (`estimateOnly` false).
  - Reason: a day-level fact on the day-level record. Version checks are ordinary row versions, and nothing in the meal/copy/move code can see it (findings 3–5). Rejected: a new `dayEstimate` entity. It would be a second per-date natural-ID table with its own outbox triggers, export and erasure, and readers would join two day tables instead of one.
- **D5 Contract and server.**
  - `contracts/openapi/sync-entities.json`:
    - `diaryEntry` "2" = v1 fields in order + `userEstimate`, `proteinKnown`, `carbsKnown`, `fatKnown`, `fiberKnown`;
    - `savedMealItem` "2" likewise;
    - (A62b) `dayMark` "2" = v1 + `estimateKcal` + `estimateOnly` (review fix, D4).
  - v1 schemas stay. `make gen-sync-schemas` (embedded `backend/.../Schemas/entities.json`) + `make gen-contract`. Fixtures: `contracts/testdata/sync/entity-payloads-v2.json` gains the three v2 payloads.
  - Server: admission is registry-driven, so v2 is admitted once the registry has it. New **`DiaryEstimatePayloadValidator`** (row-local, dispatch by entity + version, **fail closed** on unknown versions, TD-080):
    - W1 `userEstimate` ⇒ `foodKind = estimate`, `source = yours`, `isEstimate`, `foodId = null`;
    - W2 any `*Known = false` ⇒ `userEstimate`;
    - W3 (D27) a nutrient with `*Known = false` has `0` in both its snapshot and per-100 field.
    - Failures return bare `invalidPayload`.
    - dayMark v2 is schema-only (bounds in the schema).
    - Downgrade refusal (D23).
  - Tests: v1 admitted as before; v2 admitted; a v2 payload sent as 1 and a v1 sent as 2 → `invalidPayload`; W1/W2/W3 violations rejected, downgrade refused. They use a shared vector file `contracts/testdata/sync/diary-estimate-validation-vectors.json`, generated by a Dart reference (`make gen-diary-estimate-vectors`) and pinned on both sides (B17–B21 pattern).
  - `contracts/README.md`: a "diaryEntry / savedMealItem / dayMark versions" section in the weighIn style.
- **D6 Versions on the phone, and the minimum-writer rule.**
  - `SyncDocumentUpgraders.currentVersions` += `diaryEntry: 2, savedMealItem: 2` (A62a), `dayMark: 2` (A62b). The v1→v2 steps add `userEstimate: false`, all `*Known: true`, and `estimateKcal: null`. Upload is v2 only.
  - **Old writers:** older builds defer v2 documents they pull (A34 D7) and so never apply them. Deferral alone doesn't stop them **editing a v1 copy they already hold**, which would win by HLC. The server therefore refuses such downgrades (**D23**), and the new app recovers in a fixed order (D23).
  - **Deploy order:** the server must admit v2 before a v2 upload. A push the server can't admit yet is parked `unsupported`, and parked versions are **already retried** on an app-version change or daily (`retryParkedIfDue`, `drift_sync_store.dart:437`, called from `sync_providers.dart:193`). So a phone that runs ahead of the server heals with no new code. The orchestrator still redeploys the laptop server before each part's APK.
- **D7 Bounds and FD-012.**
  - Meal kcal 1–10,000 and each given macro 0–1,000 g (`UserEstimate.check`); day 1–20,000 (D4).
  - User estimates are **totals, not foods**: no `SanityCheck` (FD-012) ever runs on them. The logging path never calls it for `userEstimate` (asserted by a test with 10,000 kcal "per 100 g"). Ordinary foods are unchanged. D-096 adds the exception to FD-012.
- **D8 `IntakeTotals`** (new `packages/fb_domain/lib/src/diary/intake_totals.dart`):
  - `sum: Nutrients` (unknowns are 0, so lower bounds);
  - `coverage(NutrientField) → full | partial | none` for protein/carbs/fat/fiber (kcal is always full);
  - `valueOf(f) → double?` (null when `none`); `isLowerBound(f)` (`partial`);
  - `estimated: bool` (any `isEstimate` entry, Buddy's included, or a day estimate);
  - `dayEstimate: bool`;
  - built by `IntakeTotals.ofEntries`, from SQL counts (`fromCounts`), and by `+`.
  - It replaces `Nutrients` in every display and aggregate in the inventory; `Nutrients` stays for per-food math.
  - Content-free `toString`.
- **D9 One day-intake projection.**
  - `DiaryRepository.watchDayIntake(from, to)` → `DayIntakeTotals {date, intake: IntakeTotals, entryCount, mealCount, mark: DayMark?}`, from `dailyTotalsSql` + `marksBetween` in one watch (tables `diary_entries`, `day_marks`).
  - SQL adds `SUM(is_estimate) AS est`, `SUM(1 - protein_known) AS p_unk` … `f_unk`, `fib_unk`.
  - **A62b:** a day whose mark has `estimateKcal` and **no live food** → intake kcal = estimate, all macros `none`, `estimated`, `dayEstimate`, `entryCount = 0`, `logged` true. A day with both (only after an offline conflict, D13) → foods win in totals; `dayEstimate` stays true for exclusion.
  - All callers switch to it:
    - `_weekIntake` → `DayIntake(estimated:, dayEstimate:)`;
    - `intakeDaysOf` → A62b `incomplete: mark.incomplete || dayEstimate`. It counts toward the 14 logged days, not the 10 complete. This also stops the DY-004 suggestion;
    - Progress `DayLog(intake:)`, Ramadan comparison, notifications, the Buddy loader.
- **D10 Progress and weekly summary.**
  - `ProgressDay.eaten: IntakeTotals`.
  - `DayStatus` gains `estimated` (A62b, day estimate only; precedence incomplete > inProgress > estimated > logged > unknown). It is counted for kcal and drawn hatched.
  - **Buckets:** kcal average over counted days. Each macro's average uses its **own denominator**: counted days where that nutrient's coverage is `full` (partial and none are left out, never zero). `avgEaten` becomes `IntakeAverages {double? kcal, protein, carbs, fat, fiber, bool estimated}`, where `estimated` = any day in the bucket estimated.
  - **WeeklySummary:**
    - a protein day is *evaluated* when coverage is full, or partial with the known part ≥ target (a certain hit);
    - partial below target and `none` are **not evaluated**, never "missed";
    - `proteinTargetDays` and `proteinDaysHit` count evaluated days only;
    - `averageFiber` is over full-coverage days;
    - `estimated` → "~" on the average kcal.
  - **Daily bars:** `none` → no bar; partial → bar + "~" label; estimated kcal → "~" label.
- **D11 Meal-estimate ops (single writer).**
  - **Log:** `LogEntries(NewDiaryEntry(food: UserEstimate.food(...)))`; no slot → `SlotAssigner`.
  - **Edit:** `UpdateDiaryEntry(EntryPatch(food: UserEstimate.food(...)))`, amount unchanged.
  - **Swap:** the existing `FoodSearchRoute(replace: VersionedId)` → `ReplaceEntryFood` = one `UpdateDiaryEntry` on selection, one Undo. The estimate stays while searching; cancel writes nothing; a version conflict or failure writes nothing (existing behaviour, now tested for estimates).
  - **Remove:** `DeleteEntries`.
  - **Override** (AI-072 sheet) of a user estimate marks the overridden nutrient known (D24).
  - **Copy/save/relog** carry the columns (`FoodValueColumns`).
- **D12 `SetDayEstimate` (A62b), inside the applier transaction.** `SetDayEstimate(date, {double? kcal, required int? expectedVersion, required bool expectEstimate})`. The handler reads the live day-mark row and the day's live entry count, then:
  - `date ≥ today` → `InvalidOp('notPast')`; kcal outside D4 → `InvalidOp('outOfRange')`.
  - **Create** (`kcal != null`, `expectEstimate = false`): reject `InvalidOp('dayHasFood')` if the day has live food; reject `VersionConflict` if the row's version ≠ `expectedVersion` (null = no row, or a tombstone) or if it now has an estimate. Write: `UpsertRow` (no row or tombstone, keeping `incomplete`/`notFasting` defaults) or `UpdateRow(expectedVersion:)`.
  - **Edit** (`kcal != null`, `expectEstimate = true`): `UpdateRow(expectedVersion:)`; a missing estimate → `VersionConflict`.
  - **Clear** (`kcal == null`, `expectEstimate = true`): `UpdateRow(estimate_kcal = null, expectedVersion:)`; on an `estimateOnly` mark a `TombstoneRow(expectedVersion:)` instead (review fix, D4). Create on no live mark writes `estimateOnly = true`.
  - **`MarkDay`** (review fix) writes every content column: a live mark keeps its `estimateKcal` and gets `estimateOnly = false`; a revived tombstone gets `estimateKcal = null`, so an estimate undone earlier (its tombstone keeps the value) never comes back.
  - **Recreate** after a clear is a create against the current version. Unchanged value → no write.
  - Events `DayMarked`-style `DayEstimateChanged(date)`.
  - **Food logging rule:** `LogEntries`, `CopyMeal` (into a date), `LogSavedMeal`, `MoveEntries`, a moving `UpdateDiaryEntry` and **`MoveDishGroup`** (`_moveGroup` relocates member rows itself, `diary_op_handler.dart:387`) that put live food on a date with a live estimate all go through one helper, `_clearEstimatesOn(Set<LocalDate> destinations)`.
    - The helper appends **one** `UpdateRow(dayMarks, estimate_kcal = null, expectedVersion: current)` per destination date (a `TombstoneRow` for an `estimateOnly` mark, D4), deduplicated across all entries and groups the op moves.
    - Its revert restores the estimate, so one Undo restores both the food's location and the estimate.
    - This covers search, quick-add, barcode, saved meals, copy, dish moves and Buddy confirm, since they all go through these ops.
- **D13 Two offline devices (A62b).** Device A logs food for Tue offline; device B sets a Tue estimate offline (B saw an empty day); both sync.
  - The rows don't conflict (entry rows vs the day-mark row), so both survive.
  - **Rule:** food wins in every total. The estimate stays stored, and the day is still left out of adaptive (it may be incomplete).
  - Today shows the day-estimate row dimmed ("~2,300", key `day-estimate-superseded`). Its "~" popup offers **Swap for foods** = clear (one Undo; an `estimateOnly` mark is tombstoned, D4) and Edit is hidden. A superseded `estimateOnly` mark is never a "count again" confirmation.
  - The next food logged that day clears it anyway (D12). The same day-estimate row on two devices merges by LWW (natural ID).
  - **Last food deleted on a day with a superseded estimate:** the estimate becomes **active again** (the projection rule "estimate counts while the day has no live food"). The user never removed it; it was visible (dimmed) with its own clear action. The delete's Undo makes it superseded again. `DeleteEntries` doesn't touch the day mark.
  - Tests run both sync orders (A first, B first).
- **D14 Export.** The diaryEntry and savedMealItem specs add `user_estimate`, `protein_known`, `carbs_known`, `fat_known`, `fiber_known`; dayMark adds `estimate_kcal`. `technical-planning/09-cross-cutting.md` (export section) documents that `*_known = 0` means the value column is not data. Fixtures cover a known 0 versus an unknown and a day estimate (`test/core/export/export_builder_test.dart`).
- **D15 Buddy preview** (correctness, not a new feature).
  - `ProposalDayContext.confirmed: Map<LocalDate, IntakeTotals>` (was `Nutrients`), filled from `DayIntakeTotals`, so kcal includes day estimates.
  - `ProposalTargets._preview` (`proposal_targets.dart:107`) returns `IntakeTotals` = confirmed + the card's own lines (lines are full, non-estimate unless their provenance says so). **Deviation (A62b review fix):** when the confirmed intake *is* a day estimate (`IntakeTotals.dayEstimate`), the preview is the card's lines alone, since confirming replaces the estimate (D12); a superseded estimate (food wins) is unchanged.
  - The card's approximation flag (`food_proposal_card.dart:268`, via `FoodCardView`) = its own estimate ∨ `preview.estimated` ∨ any shown "after" macro not `full`. So an ordinary food card over a day that holds an estimate shows "~" on "after this".
  - Nothing new is sent to the server (the interpret request carries personal foods and the message, not day totals).
- **D16 UI.**
  - **A62a:**
    - The search screen (not replacing) gets an action row under the field: `Scan` → `BarcodeScanRoute(date, slotId)` and `~ Estimate` → `showEstimateSheet` (keys `food-search-scan`, `food-search-estimate`), plus a `~ Estimate "<query>"` row after the results and in the no-match state (`food-search-estimate-query`; name prefilled, ≤ 80 chars, never in the URL).
    - `EstimateSheet` (`features/diary/presentation/estimate_sheet.dart`, `showFbStatefulSheet`): "Estimate {meal}", `FbAmountDisplay` + pad for kcal, optional Name, "+ Macros" `FbReveal` with three optional `FbNumberField`s, pinned "Add ~{kcal} kcal" / "Save ~{kcal} kcal", reserved error line (UX-045), Undo snackbar + `successHaptic()`.
    - Your-estimate rows: leading `FbEstimateMarker.action` → `showEstimatePopup` (a short `FbSheet` "~ Your estimate": Edit, Swap for foods); title = name or `estimateUnnamed`; subtitle = given macros only; trailing "~700". Row tap → the sheet prefilled.
    - "~" / "—" in `TodayNumbers` (big number, eaten/left, week line from `weekEstimated`), slot headers, `SlotMacrosLine`, group headers, saved-meal screens, Progress labels.
  - **A62b:** past date with no food and no estimate → `DayEstimatePromptRow` (replaces the past-day `EmptyHintRow`): "Didn't log {weekday}?", inline "about ___ kcal", "Save day estimate". With an estimate → `DayEstimateRow` "~2,300" (tap → sheet day mode; "~" → popup Edit / Swap for foods = `FoodSearchRoute(date)` with the estimate kept, D12; swipe → clear with Undo). Calories/macros sections: `DayStatus.estimated` hatched + "~".
- **D17 Copy (ARB, minimal).**
  - `estimateAction` "~ Estimate", `estimateFromQuery` "~ Estimate “{query}”", `estimateSheetTitle` "Estimate {meal}", `estimateName` "Name", `estimateMacros` "+ Macros", `estimateAdd` "Add ~{kcal} kcal", `estimateSave` "Save ~{kcal} kcal", `estimateUnnamed` "Estimate", `estimatePopupTitle` "~ Your estimate", `estimateEdit` "Edit", `estimateSwap` "Swap for foods", `approx` "~{value}", `approxSpoken` "about {value}", `unknownValue` "—";
  - undo labels `estimateAdded`, `estimateChanged`;
  - A62b: `dayEstimatePrompt` "Didn't log {weekday}?", `dayEstimateAbout` "about", `dayEstimateSave` "Save day estimate", undo `dayEstimateSaved`, `dayEstimateRemoved`.
  - Tests assert keys, never copy.
- **D18 Privacy.** Names and values are user content: `UserEstimate`, `IntakeTotals`, `SetDayEstimate` and `EstimateDraft` get content-free `toString`. No log lines are added, and server `invalidPayload` never echoes values. The only new data leaving the phone is the sync payload fields (booleans, `estimateKcal`), with the same protection as all diary data.
- **D19 Migrations.** A62a: `from_14_to_15.dart` adds the five columns to `diary_entries` and `saved_meal_items` with defaults (no rebuild). A62b: `from_15_to_16.dart` adds `day_marks.estimate_kcal`. Each comes with a schema dump plus a migration test (existing rows read as known / non-estimates).
- **D20 Tests lean (TD-104).** Logic and data integrity, one happy path per new surface, no new goldens. Touched goldens are regenerated and looked at.
- **D21 ⚠️ OWNER: D-096 text** (applied in A62a WP1 only after "ok"; the whole decision, covering both parts). Without approval nothing in `spec/` changes and tests tag existing IDs. **Rec: ok**: it writes down the approved design, plus three explicit consequences: "~" also shows for Buddy estimates on totals; unknown protein days aren't counted as missed; FD-012 doesn't apply to your estimates.
- **D22 TD candidate TD-114** (recorded in A62a WP1; orchestrator-approvable, no cost, vendor or lock-in impact):
  - user estimates are explicit `userEstimate` + per-nutrient `*Known` fields in diaryEntry/savedMealItem v2;
  - unknown values are stored as 0 and only ever read through knowledge-aware `IntakeTotals` (coverage full/partial/none, per-nutrient denominators, `estimated` carried through every aggregate);
  - the day estimate is `dayMark.estimateKcal` (v2), with food logging clearing it in the same change set; a mark made only for it is `estimateOnly` and is tombstoned when it's cleared (A62b review fix, D4);
  - unknown ⇒ stored 0 (W3), enforced locally, on the server and in the shared vectors;
  - the server refuses schema downgrades for `diaryEntry`, `savedMealItem` and `dayMark`, and a server-refused local version loses to the server document after the app update (D23);
  - server: schema + row-local `DiaryEstimatePayloadValidator` (W1–W3), fail closed.

- **D23 Server downgrade refusal + recovery** (A62a for `diaryEntry`/`savedMealItem`, A62b adds `dayMark`).
  - **Server** (`PostgresSyncStore` winner selection, before the HLC comparison): for an entity in `DowngradeProtected = {diaryEntry, savedMealItem, dayMark}`, an incoming version whose `schemaVersion` is lower than the stored document's is refused with `invalid` / `unsupported`, whatever its HLC, tombstones included. The stored v2 and its history stay untouched; the refused version goes to `row_history` like a stale one (no loss server-side). Other entities are unchanged (weighIn could adopt the rule later; backlog).
  - **Old client:** parks the version (`unsupported`, an existing closed reason). Its local row keeps the edit until it updates. Its pull compares HLCs before schemas, so it usually **skips** the v2 document (older HLC) and moves its cursor on: no `sync_deferred` copy can be relied on.
  - **Marking (phone):** `sync_parked` / `sync_displaced` gain `refused_schema` (in the unshipped 14→15 migration). A push refused `unsupported` for a downgrade-protected entity records the schema version it sent; the migration marks versions older builds parked that way as `1` (they only wrote v1). The server's answer can't tell a downgrade from "not admitted yet" (deploy order), so the mark means *possible* downgrade.
  - **New client after the update** (`retryParkedSafely`, the engine's `afterDeferredRetry` hook, after the deferred retry and before any push), when the parked retry is due (app-version change or daily):
    - (1) **Recovery first:** for the marked rows, the app re-reads the server's current documents (a pull scan from cursor 0 that leaves the stored cursor alone and stops once all marked rows were seen; the pull API has no by-id read) and resolves each mark in one remote-apply transaction (`resolveRefusedDowngrades`):
      - the server document's schema is **newer** than the refused one (a real downgrade) and the refused version is still the local row: the document applies as the winner **whatever its HLC**; the refused version moves to `sync_displaced` as `superseded` (kept for "earlier versions", never pushed, retried or counted). A marked displaced version is marked `superseded` likewise. If a newer local edit replaced the refused version meanwhile, that edit syncs by ordinary LWW;
      - otherwise (no document, or the same schema): the mark is dropped and the version is an ordinary parked one.
    - (2) Then `retryParkedIfDue`. Marked versions are never retried ("Try again" included) or re-encoded before (1): a v2 re-encode under the old HLC would be a `versionConflict`, which the engine acknowledges, leaving phone and server apart.
    - Only marked versions get this. Every other parked reason (`tooLarge`, `encodeFailed`, `invalidPayload`, …) keeps normal HLC behaviour; there is no general "parked loses" rule in `_applyOne`.
    - Net effect: the v2 estimate survives, and the old-device edit is preserved locally but not applied.
  - **Order cases:**
    - (a) v2 reaches the server first → the old edit is refused → recovery as above.
    - (b) The old edit reaches the server first with a newer HLC → the server holds v1, the v2 push is `stale` → ordinary LWW: the later edit wins, the estimate change is kept in the upgraded device's `sync_displaced`. This is no downgrade, because the server never stored a newer v2.
  - **Tests** (server + phone, both orders): existing v1 row → remote v2 → old-client edit, for (i) a diary entry, (ii) a saved-meal item (A62a) and (iii) a day-mark flag edit such as `incomplete` (A62b); refused version archived; the phone test runs the real old-client state (v14 database, cursor past the v2, nothing deferred) through the migration and a sync run: v2 applied, the old edit `superseded` in `sync_displaced`, never re-sent; a newer v2 edit parked for another reason, or refused at the same schema, is not superseded.
- **D24 Overrides and known state** (A62a).
  - `DiaryActions.overrideNutrients` (`diary_actions.dart:227`) and the handler's shortcut (`diary_op_handler.dart:136`) are "unchanged" only when, for every given field, the stored value equals the new one **and** the field is already known. Unknown → explicit 0 is therefore a real write: it sets `*_known = 1`, keeps 0, and the per-100 is unchanged.
  - `nutrient_override_sheet.dart:55` prefills unknown fields **empty**, with the "—" placeholder (never "0"). Leaving a field empty keeps it unknown and doesn't put it in `values`.
  - Undo restores the content columns, including `*_known`, so unknown comes back.
  - Test (application action → applier → sync encode): unknown protein → 0 writes once, the second identical save is unchanged, the v2 payload has `proteinKnown: true, proteinG: 0`, Undo restores `proteinKnown: false`.
- **D25 Ramadan comparison** (A62a provenance, A62b admission).
  - Day estimates count in its averages, like Progress (owner E3 A: "count in averages").
  - `ComparisonDay` gains `estimated` and `dayEstimate`. `RamadanComparison.compute` (`ramadan_comparison.dart:83`) admits a day when `entryCount > 0` **or** `dayEstimate` (explicit, not via `entryCount`).
  - `ComparisonSide.estimated` = any admitted day estimated → "~" on its average kcal in the display. Its macro figures (if any) use D10's per-nutrient denominators.
  - Tests: a Ramadan side with a day-estimate day and a meal-estimate day: kcal average includes both and is marked "~".
- **D26 Raw snapshot surfaces** (A62a; each reads `EntryFood.known` / `IntakeTotals`, not bare `Nutrients`):
  - **Entry details** (`entry_details.dart`): unknown → "—". User-estimate rows open the estimate sheet instead (D16), but the panel stays correct if reached (e.g. from a group).
  - **`NutritionSummary`** (`core/ui/nutrition_summary.dart`, used by `entry_amount_sheet.dart:177` and `food_sheet.dart:312`): gains an optional `known` set; unknown shows "—" (A57's dash slot). The entry amount sheet is not offered for user estimates (the row tap opens the estimate sheet) but passes `known` if reached. `food_sheet` shows foods, which are always known.
  - **Override sheet:** D24.
  - **Saved-meal item rows** (`saved_meal_screen.dart`): per item "—" / "~"; meal total via `SavedMeal.intake`.
  - **`live_entry`/`live_meal`** (watchers that hand the entry/section to the sheets): pass the entry/`intake` through, no formatting.
  - **Buddy proposal lines** (`proposal_line_row.dart`, `food_proposal_card.dart`): Buddy lines are always known; only the preview changes (D15).
  - A test per changed widget family is in the list. Compile-time safety is not relied on: WP5's commit body lists every surface above as checked.
- **D27 Zero-storage invariant** (A62a).
  - **Rule W3:** for each of protein/carbs/fat/fiber, `*Known = false` ⇒ snapshot `= 0` **and** per-100 `= 0`.
  - Enforced in three places:
    - **local construction:** `UserEstimate.food` builds it; `EntryFood`'s constructor asserts it (`ArgumentError`, content-free); `FoodColumns.of` re-checks before any write;
    - **server:** `DiaryEstimatePayloadValidator` W3;
    - **shared vectors:** `diary-estimate-validation-vectors.json` holds W3 accept/reject rows, pinned by the Dart and C# tests.
  - Aggregation **relies on it**: SQL sums and `IntakeTotals` add stored values, and only coverage marks unknowns. So a partial total is a true lower bound, and "partial ≥ target = certain hit" (D10) is sound.
  - A pulled row that breaks W3 can't arrive (the server refuses it). A local row breaking it would be a bug: the mapper treats the value as unknown and logs a content-free counter.
  - Tests:
    - a mixed day of a known food (P 25) + a kcal-only estimate → protein `partial`, sum 25, the average leaves it out;
    - a known food (P 40 ≥ target 30) + an estimate → certain hit;
    - W3 vectors on both sides.

#### D-096 draft (to apply after owner approval; A63 takes D-097)
```
## D-096 — Estimates: a meal or a day in one number
- Date / Source: 2026-11-06 · owner review of the Estimates mockups (E1 A+B, E2 A, E3 A)
- Status: Accepted by the owner. Adds DY-005, DY-006. Amends DY-004, TG-031, TG-032, IN-001, IN-002, IN-003, HM-001, HM-002, AI-032, FD-012, the `~ estimate` row of spec/11 §2 and the glossary.
- Decision:
  - **Meal estimate** (DY-005): a meal's add screen offers "~ Estimate" next to Search and Scan: one calorie number, an optional name, and optional protein, carbs and fat, each on its own. Search also offers "~ Estimate "<query>"" with the query as the name. It applies at once with Undo (AI-048), never as a proposal, and works offline.
  - **Day estimate** (DY-006): a past day with nothing logged offers "Didn't log {day}?" with "about ___ kcal". One per day. Logging or moving food onto that day replaces it (one Undo). No top-up for partly logged days: a meal estimate covers that.
  - **What they count for:** meal estimates count everywhere like food, including the adaptive target. Day estimates count in Today, charts (hatched), averages (including the Ramadan comparison) and the weekly budget, but are left out of the adaptive target, like incomplete days, and out of macro averages.
  - **Missing stays missing:** a macro you didn't give is unknown, never 0. Totals that include unknowns show "~"; a value with nothing known shows "—". Averages leave unknown days out per nutrient, and a day whose protein isn't known is never counted as a missed protein target.
  - **How they show:** only "~" and the number. Tapping "~" on your own estimate opens "~ Your estimate" with Edit and Swap for foods, the only explanation. Tapping the row edits it; Swap for foods opens the food search and replaces the estimate only when you pick a food (one Undo). Any total that includes an estimate, including Buddy's, shows "~".
  - Your estimates are totals, not foods: the per-100 sanity check (FD-012) doesn't apply to them.
- Why: Eating out or a forgotten meal is common, and finding each food or faking a personal food was slow. You type the number, so the app still never invents nutrition numbers (D-011). One wrong day guess shouldn't move targets for weeks (option E3 A). Steps A62a, A62b.
```
Spec edits:
- `spec/12`:
  - status line + D-096.
  - DY-004 append "A day with a day estimate (DY-006) is left out the same way."
  - New after DY-004:
    - **DY-005** `[R1]` **Meal estimate:** from a meal's add screen ("~ Estimate", or "~ Estimate "<query>"" in search), one calorie number, an optional name and optional protein, carbs and fat, each on its own. A direct action with undo (AI-048). It counts like food. Macros not given stay unknown (never 0) in every total and average. It shows as "~" + the number; tapping it edits it; "~" offers Edit and Swap for foods (D-096).
    - **DY-006** `[R1]` **Day estimate:** a past day with nothing logged offers "about ___ kcal" for the whole day; one per day, undoable; logging food that day replaces it. It counts in totals, charts and averages, not in adaptive targets (TG-032) or macro averages (D-096).
- `spec/13`:
  - TG-031: "at least **10 complete** (not marked incomplete, DY-004, and without a day estimate, DY-006)".
  - TG-032: "Incomplete days and day estimates (DY-006) are left out of the calculation; meal estimates (DY-005) count like food. Missing days are treated as unknown, never as zero."
- `spec/16`:
  - status line + D-096.
  - HM-001 append: "When an estimate is included the numbers show "~"; a macro with nothing known shows "—" (D-096)."
  - HM-002 append: "It shows "~" when the week includes an estimate."
  - IN-001: after "average calories vs. budget" add "(day estimates count); protein days and fiber average count only days whose values are known".
  - IN-002: "… with incomplete days and day estimates drawn hatched; day estimates count in the averages, incomplete days don't."
  - IN-003 append: "Unknown macros draw no bar and are left out of averages; day estimates have none."
- `spec/10` AI-032 append: "Your own estimates (DY-005, DY-006) have no range: tapping "~" shows "~ Your estimate" with Edit and Swap for foods (D-096)."
- `spec/11`:
  - §2 table, row `~ estimate`: source "AI estimate when nothing else matches, or a number you typed (DY-005, DY-006)"; trust "Low: always marked; AI estimates show a range".
  - FD-012 append: "Your own estimates (DY-005, DY-006) are totals, not foods, and are never sanity-checked (D-096)."
- `spec/glossary.md` "Estimate (~)": "… a photo portion, an AI estimate, or a number you typed for a meal or a day (DY-005, DY-006). Always marked; AI estimates show a range on tap (D-045)."

### Design
**Domain (`packages/fb_domain`)**

| Type / change | File | Part |
|---|---|---|
| `UserEstimate` (limits, `check`, `food({kcal, protein?, carbs?, fat?, name?}) → EntryFood`, `unnamedName`) | new `diary/user_estimate.dart` | a |
| `EntryFood.userEstimate`, `EntryFood.known: Set<NutrientField>` (default all) | `diary/diary_entry.dart` | a |
| `IntakeTotals`, `NutrientCoverage`, `IntakeAverages` | new `diary/intake_totals.dart` | a |
| `DiaryTotals.intake`, `DayLayout.intake`, `SlotSection.intake`, `GroupItem.intake`, `SavedMeal.intake` | `diary/*.dart` | a |
| `DayIntake.estimated` (+ `dayEstimate` in b), `TargetDay.weekEstimated` | `targets/targets_timeline.dart`, `weekly_budget.dart` | a (+b) |
| `DayLog.intake`, `ProgressDay.eaten: IntakeTotals`, bucket per-nutrient denominators, `WeeklySummary` evaluated-protein rule | `insights/*.dart` | a |
| `DayStatus.estimated` | `insights/progress_series.dart` | b |
| `DayMark.estimateKcal`, `SetDayEstimate` op | `diary/diary_entry.dart`, `diary_ops.dart` | b |
| Upgraders `diaryEntry@1`, `savedMealItem@1` (a), `dayMark@1` (b) + `currentVersions` | `sync/document_upgraders.dart` | a / b |
| `DiaryEstimateWireRules` (W1, W2) + vector generator | new `diary/diary_estimate_wire_rules.dart` | a |

**App data**
- `core/db/tables/diary_tables.dart`: the `FoodValueColumns` columns (a) and `DayMarks.estimateKcal` (b); migrations (D19).
- `features/diary/data/`:
  - `FoodColumns` reads and writes the flags (food change resets them);
  - `diary_mappers.dart` maps them;
  - `diary_op_handler.dart`: the override known-rule (a); `_setDayEstimate` + the clear-on-food rule (b);
  - `diary_reads.dart` SQL + `DayIntakeTotals` + `watchDayIntake` (a; the mark join in a already, the estimate in b).
- Export registry (D14). Callers per the inventory.

**Server (`backend/src/Modules/UserData`)**
- Regenerated `Infrastructure/Schemas/entities.json`.
- New `Infrastructure/DiaryEstimatePayloadValidator.cs`, wired in `SyncPayloads.InvalidReason` next to the other validators.
- Tests: `backend/tests/UserData.Tests/DiaryEstimatePayloadTests.cs` + `DiaryEstimateCases.cs` (vectors), plus the existing dayMark admission test extended for v2 (b).

**App UI:** as D16. DS: `FbEstimateMarker.action({onTap, semanticsLabel})`.

**Data flow (meal estimate):** sheet → `EstimateDraft` → `EstimateActions.logMeal` → `ChangeSet([LogEntries(...)])` → applier → outbox (`diaryEntry` v2) → server admission (schema + W1/W2) → other device pulls v2 → mapper → `IntakeTotals` → "~" and "—".

**Rules kept:**
- One writer.
- Barrels only; presentation never imports `data/` (app_check 1, 2, 12).
- Offline: no network on any new path.
- Contract-first: contract WP → `make gen` → server WP → app WPs.
- Frozen migrations: new files only.

### Work packages
**Local gates (PROCESS.md, owner rules 2026-10-30):** before each commit run codegen if touched (`make gen-app`, or `build_runner` + `gen-l10n`), plus `make check-dart` / `make check-dotnet` / `dotnet build` through `tools/scripts/heavy.sh`. Tests are written in the WP and **run in the merge CI**, not locally. On a CI failure only the failing tests are reproduced (`timeout 600 tools/scripts/heavy.sh …`). After each WP: `git grep` the changed keys/strings in `test/`, `patrol_test/` and `integration_test/`, then the `cross-check` skill. One local commit per WP; contract changes in their own commit with a Progress-log line.

**A62a — meal estimates + knowledge-aware aggregation (branch `step/A62-estimates`)**
- **WP1 Docs + contract** (`flutter-engineer`).
  - Commit 1 (docs): D-096 + spec edits if approved, TD-114, `05` §1/§2.1, the `09` export note.
  - Commit 2 (contract): `diaryEntry`/`savedMealItem` "2" in `sync-entities.json`, `entity-payloads-v2.json` fixtures, `contracts/README.md` versions section, `make gen-contract gen-sync-schemas`.
  - Done when `make contract-lint` / `check-sync-schemas` / `make trace` are clean.
- **WP2 Server** (`dotnet-engineer`).
  - `DiaryEstimatePayloadValidator` (W1, W2, W3, fail closed by version) wired into admission.
  - Downgrade refusal in `PostgresSyncStore` (D23) for `diaryEntry` and `savedMealItem` (A62a; `dayMark` joins in A62b WP2).
  - Dart reference `DiaryEstimateWireRules` + `make gen-diary-estimate-vectors` → `contracts/testdata/sync/diary-estimate-validation-vectors.json`.
  - `DiaryEstimatePayloadTests` (v1 still admitted, v2 admitted, cross-version mismatch, W1/W2, no value echo).
  - Done when `make check-dotnet` and `dotnet build` pass and the tests are written.
- **WP3 Domain** (`flutter-engineer`).
  - `UserEstimate`, `EntryFood` flags, `IntakeTotals`/coverage/averages.
  - `DiaryTotals`/`DayLayout`/`SlotSection`/`GroupItem`/`SavedMeal` intake, `DayIntake.estimated` + `weekEstimated`, Progress/bucket/summary rules (D10 without `DayStatus.estimated`).
  - Upgraders, `DiaryEstimateWireRules` vector test.
  - Done when `make check-dart` passes.
- **WP4 App data + sync** (`flutter-engineer`).
  - Columns, migration 14→15 (+ schema dump, migration test), `FoodColumns`/mapper.
  - Override known-rule, SQL + `DayIntakeTotals`/`watchDayIntake` (with the mark join), all callers in the inventory, export columns + fixtures.
  - New-app recovery order + the server-refused-loses rule (D23, phone side).
  - Done when `make gen-app` and `make check-dart` pass.
- **WP5 Meal-estimate UI** (`flutter-engineer`).
  - `EstimateActions`/`EstimateDraft`, `EstimateSheet`, the search action row + query row, the row branch, `FbEstimateMarker.action`, `showEstimatePopup` (Edit, Swap).
  - "~" / "—" on Today, slots, groups, saved meals, Progress, day details and the Buddy card flag (D15); ARB.
  - Done when `make check-dart` passes.
- **WP6 Integration before hand-back** (`flutter-engineer`).
  - `make gen` (contract bundle, sync schemas, Dart client, app `.g.dart` + l10n + drift steps) and `make gen-check`.
  - Regenerate and **look at** the touched goldens: expected `food_search_results`, `today_full_day` (its estimate entry → "~"), `progress_screen` if macro bars change. Grep the rest.
  - `git grep` in `patrol_test/` and `integration_test/` for `food-search-*` and the search layout; retarget finders by key.
  - `make trace`, `cross-check`.
  - Done when gen-check is clean, goldens are viewed, and the grep is recorded in the commit body.

**A62b — day estimate (branch `step/A62b-day-estimate`, after A62a merges)**
- **WP1 Contract** (`flutter-engineer`): `dayMark` "2" + fixture + README; `make gen-contract gen-sync-schemas`.
- **WP2 Server** (`dotnet-engineer`): add `dayMark` to the downgrade-protected set (D23) and its tests; dayMark v2 admission tests (schema bounds 1–20,000, null, v1 still admitted, cross-version rejected).
- **WP3 Domain + data** (`flutter-engineer`): `DayMark.estimateKcal`, `SetDayEstimate`, the upgrader, migration 15→16, `_setDayEstimate` (D12), the clear-on-food rule in `LogEntries`/`CopyMeal`/`LogSavedMeal`/move-in, projection estimate (D9), `intakeDaysOf`, `DayStatus.estimated`, export column.
- **WP4 UI** (`flutter-engineer`): `DayEstimatePromptRow`/card, `DayEstimateRow` (+ superseded state D13), sheet day mode, popup, Progress hatched + "~"; ARB.
- **WP5 Integration** (`flutter-engineer`): as A62a WP6 (gen, gen-check, goldens viewed, Patrol/integration grep for the past-day empty hint key/copy, trace, cross-check).

### Test list
| Test | Proves | Part |
|---|---|---|
| `DY-005 user estimate food: typed values, userEstimate, protein known only when typed, fiber unknown, explicit 0 known` | D2, D3 | a |
| `DY-005 UserEstimate.check bounds (kcal 0, 10001, macro 1001)` | D7 | a |
| `FD-012 logging a 10,000 kcal estimate never runs SanityCheck and is stored` | D7 | a |
| `IntakeTotals coverage full/partial/none; valueOf null for none; estimated from Buddy and user estimates` | D8 | a |
| `IN-003 bucket macro average uses per-nutrient denominators; a kcal-only estimate day doesn't lower protein` | D10, finding 1 | a |
| `IN-001 protein day: full counts, partial ≥ target is a hit, partial below target and none are not evaluated; fiber average over full days` | D10 | a |
| `IN-002 daily bar: none → no value, partial → lower bound flagged` | D10 | a |
| `HM-002 an estimate earlier in the week marks the week line on a later ordinary day` | D9, finding 2 | a |
| `DY-024 dish group with an estimate member is estimated; DY-031 saved meal save + relog keeps known flags and "~"` | finding 2 | a |
| `diaryEntry and savedMealItem v1→v2 upgrade adds userEstimate false and all known` | D6 | a |
| `older-version guard: a v2 diaryEntry pulled by a v1-only codec is deferred, not applied` | D6, finding 5 | a |
| `sync round trip: user estimate and a saved item with an estimate are identical under v2` | exit 5 | a |
| `migration 14→15: existing rows read as known non-estimates` | D19 | a |
| `DY-005 log meal estimate writes the flags; Undo removes it` | E1 | a |
| `DY-005 edit keeps id; Undo restores; override of a missing macro makes it known` | D11 | a |
| `DY-005 swap: estimate kept while searching; selection = one change set, one Undo restores; cancel writes nothing; version conflict writes nothing` | D11, finding 4 | a |
| `daily intake SQL counts estimates and unknowns per nutrient; query plan keeps the local_date index` | D9 | a |
| `export: known 0 vs unknown and user_estimate columns in the fixture` | D14, finding 6 | a |
| server `DiaryEstimatePayloadTests` (v1 ok, v2 ok, v2-as-1 / v1-as-2 invalid, W1, W2, unknown version unsupported, no echo) | D5 | a |
| `DiaryEstimateWireRules match the shared vectors` (Dart) | D5 | a |
| `toString of UserEstimate, IntakeTotals, EstimateDraft holds no user content` | D18 | a |
| `D23 server refuses a v1 write over a stored v2 diaryEntry / savedMealItem (incl. tombstone), archives it, keeps v2` (C#) | D23 | a |
| `D23 old-client edit of an existing v1 entry and saved-meal item after a remote v2: refused, parked, v2 skipped by HLC (no deferred copy); after update the recovery re-reads the server, v2 applies, the edit is superseded in sync_displaced and never re-sent; other parked reasons keep LWW; both sync orders` | D23 | a |
| `AI-072 override unknown protein → 0 writes once, syncs as proteinKnown true, Undo restores unknown; sheet prefills unknown empty` | D24 | a |
| `W3 EntryFood rejects unknown with nonzero snapshot or per-100; vectors accept/reject on Dart and C#` | D27 | a |
| `IN-001 known food P25 + kcal-only estimate → partial 25, left out of the protein average; known P40 ≥ 30 + estimate → certain hit` | D27, D10 | a |
| `AI-031 an ordinary Buddy card over a day holding a fully-known estimate shows ~ on after-this` | D15 | a |
| `D25 Ramadan side with a meal estimate is marked estimated` | D25 | a |
| `NutritionSummary and entry details show — for unknown` | D26 | a |
| `protein nudge skipped when protein isn't fully known and the lower bound is below target` | inventory | a |
| `AI-048 estimate sheet adds ~kcal with Undo from the add screen` (happy path) | E1 A | a |
| `food search estimate row prefills the name from the query` | E1 B | a |
| `HM-001 Today shows ~ with an estimate and — for an unknown macro` | D16 | a |
| `AI-032 tapping ~ on your estimate offers Edit and Swap for foods` | D16 | a |
| `AI-031 Buddy day preview flags lower-bound macros` | D15 | a |
| `DY-006 MoveDishGroup into an estimated day clears it once (two members, one date); one Undo restores group location and estimate` | D12, PA11 | b |
| `DY-006 deleting the last food on a day with a superseded estimate reactivates it; Undo of the delete supersedes it again` | D13 | b |
| `D23 dayMark: existing v1 mark → remote v2 estimate → old-client incomplete flag edit: server refuses, recovery keeps v2; both orders` | D23 | b |
| `D25 Ramadan comparison admits day-estimate days (entryCount 0) and marks the side estimated` | D25 | b |
| `DY-006 SetDayEstimate create on an empty past day; rejects today/future, out of range, and a day that now has food` | D12, finding 3 | b |
| `DY-006 stale create (an estimate appeared), stale edit (version moved), edit after remote clear → VersionConflict, nothing written` | D12 | b |
| `DY-006 clear then recreate; Undo of each; Undo after a synced remote edit conflicts instead of overwriting` | D12 | b |
| `DY-006 logging food (search, quick-add, saved meal, copy, move-in) on an estimated day clears it in the same change set; one Undo restores both` | D12, finding 4 | b |
| `DY-006 day swap: search keeps the estimate; cancel writes nothing` | finding 4 | b |
| `two offline devices: food on A + estimate on B → food wins in totals, day excluded from adaptive, superseded row shown` | D13 | b |
| `two devices setting the same day estimate converge on one day-mark row` | D4 | b |
| `TG-032 intakeDaysOf excludes day-estimate days; meal estimates count` | D9 | b |
| `IN-002 estimated day hatched, counted for kcal, no macro values` | D10 | b |
| `TG-041 week budget counts a day estimate as intake` | D9 | b |
| `dayMark v1→v2 upgrade, migration 15→16, round trip, export column` | D6, D14, D19 | b |
| server dayMark v2 admission tests | D5 | b |
| `DY-006 past empty day card saves; today and future show none` (happy path) | E2 A | b |

Tests tag DY-005/DY-006 only if D-096 is applied (D21); otherwise DY-004/AI-048/TG-032/IN-002.

### Exit-criteria mapping
| # | Evidence |
|---|---|
| 1 | Sheet + search-row happy paths, log/undo op test; no network on the paths |
| 2 | Swap and edit tests (D11) |
| 3 | IntakeTotals, bucket, summary, daily-bar, group, saved-meal, export and Buddy-flag tests |
| 4 | Week-line test, group/saved-meal "~" tests, Today widget test |
| 5 | Contract diff + server tests + upgrade/defer/round-trip tests |
| 6 | SetDayEstimate create/stale/clear/recreate tests |
| 7 | Clear-on-food tests across logging ops |
| 8 | intakeDaysOf, Progress and budget tests |
| 9 | dayMark v2 server tests, round trip, two-device tests |
| Both | Merge CI runs (gen-check, goldens, trace) + integration WP commit bodies |

### Risks and unknowns
- **R1 Deploy order** (D6). If the APK uploads v2 before the laptop server has it, rows park as `unsupported` and `retryParkedIfDue` heals them after the server update. The orchestrator redeploys the server first anyway.
- **R9 Old-device edits are held until it updates** (D23). They are kept locally in `sync_displaced`, never silently merged into a v2 row. An old-device delete of a v2 row comes back after the update (its tombstone is v1). This is rare (one phone) and recorded.
- **R2 Wide aggregation change.** `IntakeTotals` touches about 20 readers (inventory). The mitigation is one type and one projection, so a missed reader shows at compile time where `Nutrients` changes to `IntakeTotals`. Codex is briefed with the inventory table.
- **R3 Incomplete and estimated days are both hatched** (owner E3 A). The label ("~") and the counting differ; making them distinct is one switch. The popup is a small sheet, not an anchored menu (also one switch).
- **R4 "~" on totals now also shows for Buddy estimates**, stated in D-096. `today_full_day` changes.
- **R5 Per-100 = total at 100 g** for meal estimates looks odd in a raw export. The `user_estimate` column says what it is (D14). A25 inherits the flags.
- **R6 The search layout changes** may break Patrol finders: grep in WP6, and the nightly run proves it.
- **R7 The D13 superseded state** is rare (two offline devices). It is tested, and the next food log clears it.
- **R8 No owner approval for D-096** → no spec edits, tests tag existing IDs, and the code is unchanged.

### Size check
- **A62a:** 6 WPs, L. Roughly: WP1–WP2 (now with the downgrade refusal) about half to one session, WP3–WP4 one session, WP5–WP6 + fixes one session, so 2.5–3 sessions.
- **A62b:** 5 WPs, M, 1–2 sessions.
- Each part is under the ~6-WP ceiling. If A62a WP5 grows, its Progress/Buddy display flags can move to A62b's UI WP.

## Progress log
- 2026-11-06: card and low-level plan written (planner) on `step/A62-estimates` in lane 2; board row 🟦. Waiting: Codex plan review, owner "ok" on D-096.
- 2026-11-06: Codex plan review = rework (5 majors, 3 minors). Plan reworked (planner): day estimate moves to dayMark v2 (A62b), explicit knowledge fields in diaryEntry/savedMealItem v2 + `IntakeTotals` (A62a), transactional `SetDayEstimate`, atomic swap, reader inventory first; split A62a → A62b. Waiting: Codex re-review, owner "ok" on D-096.

- 2026-11-06: Codex round-2 recheck = another round (5 majors, no blockers). Amended (planner): server downgrade refusal + recovery (D23), override known state (D24), MoveDishGroup + last-food rule (D12, D13), Ramadan (D25), Buddy preview (D15), raw surfaces (D26), zero-storage W3 (D27); retry contingency dropped (retryParkedIfDue exists). Final plan round; orchestrator verifies.
- 2026-11-06: A62a WP1 done (dotnet-engineer): D-096 + spec edits, TD-114, 05 notes; **contract:** `diaryEntry`/`savedMealItem` "2" (v1 + `userEstimate`, `proteinKnown`, `carbsKnown`, `fatKnown`, `fiberKnown`), registry regenerated, v2 fixtures, README versions section. Export note went into `05` §6 (09 has no export section). contract-lint and check-sync-schemas clean.
- 2026-11-06: A62a WP2 done (dotnet-engineer): `DiaryEstimatePayloadValidator` (W1–W3, fail closed, versions {1,2}) in admission; downgrade refusal for `diaryEntry`/`savedMealItem` in `PostgresSyncStore` (`SyncRules.DowngradeProtected`; refused = `invalid`/`unsupported`, archived with its receipt, replays get the same answer); Dart reference `DiaryEstimateWireRules` + `make gen-diary-estimate-vectors` → `diary-estimate-validation-vectors.json` (106 cases) and its Dart vector test; C# `DiaryEstimatePayloadTests`, `DiaryEstimateSyncTests` (HTTP, both orders), `SemanticValidatorTests` row. Tests written, not run (CI). check-dotnet, check-dart, check-contract clean.
- 2026-11-06: A62a WP3 done (flutter-engineer): `UserEstimate`, `EntryFood` flags + local W1–W3, `IntakeTotals`/`IntakeAverages`, intake on layout/groups/saved meals/Progress/summary, week-line `estimated` (on `WeekPosition`, not `TargetDay`), Buddy preview `IntakeTotals`, upgraders v1→v2. Tests written (CI). check-dart clean.
- 2026-11-06: A62a WP4 done (flutter-engineer): drift 14→15 (flags on both tables), `FoodColumns`/mappers, D24 override rule, SQL counts → `DailyTotals.intake` and all inventory callers, upload v2, D23 phone side (`SyncEngine.afterDeferredRetry`; parked local loses to a newer-schema doc, kept as `superseded`), export columns. Deviation: no separate `watchDayIntake` projection (DailyTotals carries `IntakeTotals`; A62b adds the mark join). Tests written (CI). check-dart clean.
- 2026-11-06: A62a WP5 done (flutter-engineer): search Scan / `~ Estimate` row + query row, `EstimateSheet`, `FbEstimateMarker.action` + "~ Your estimate" popup (Edit, Swap), estimate rows, "~"/"—" on Today, slots, groups, saved meals, Progress, summary, Ramadan, Buddy after-this, details/NutritionSummary/override. Not done: protein-nudge test; "~" on copy/save sheet kcal, saved-meals list and Targets week line (minor). Tests written (CI). check-dart clean.
- 2026-11-06: A62a WP6 done (flutter-engineer): `make gen-check` clean (no diff), `make trace` (DY-005/IN-003 covered, no new warnings), `make check-dart` clean. Patrol/integration grep for `food-search-*`, `create-personal-food`, `FoodSearchScreen`, `TodayNumbers`, the changed macro ARB keys, Scan/Estimate: only `startup_benchmark_test` read `TodayNumbers.totals` (now `intake.sum`, fixed in WP5); `food_search_add_test` finds the single `TextField` and `Add`, unaffected. Goldens expected to change (not regenerated locally): `food_search_results` (action row), `today_full_day` (its estimate entry → "~" on totals). Cross-check: sync_sim generic (no change), wire vectors test in place. A62a code complete; ready for the two Codex reviews.
- 2026-11-06: A62a Codex review fixes (flutter-engineer): **D23 reworked** (deviation, card D23 updated): the generic "parked loses to a newer-schema doc" rule is gone; `refused_schema` marks possible downgrades (folded into the unshipped 14→15 migration, which also marks old builds' parked v1 versions and adds the v1 defaults to kept diary/saved-meal snapshots); before any parked retry the app re-reads the server rows (pull scan from 0, cursor untouched) and supersedes only real downgrades. Also: estimate edit keeps fiber/extras/provenance; "~" on saved-meal list, copy/save sheets, Targets week line, Buddy logged line (day total provenance); migration test compares full rows; protein-nudge, popup Edit/Swap tests. Goldens: `food_search_results` regenerated and viewed; `today_*` regenerated identical (`fullDay` holds no estimate). Tests written (CI); check-dart, gen-app clean.
- 2026-11-06: A62b WP1 done (flutter-engineer): **contract:** `dayMark` "2" (v1 + `estimateKcal`, number 1–20000 or null), registry regenerated, v2 fixture (2,300 kcal), README "dayMark versions" section (and the D23 recovery sentence updated to the as-built rework), `05` §5 line. Branch: continuing on `step/A62-estimates` (orchestrator brief), not a separate A62b branch. check-contract, check-sync-schemas clean.
- 2026-11-06: A62b WP2 done (flutter-engineer for the small server change): `dayMark` in `SyncRules.DowngradeProtected`; `DiaryEstimateCases.DowngradeProtected` + `EditedV1` (dayMark flips `incomplete`); the HTTP downgrade theories (both orders, tombstones, replay, cleanup) now run for dayMark too; new `DayMarkVersionTests` (v1/v2 own-version admission, estimateKcal null/1–20000 bounds and types, required fields). No row rule needed (schema-only). check-dotnet clean; tests written (CI).
- 2026-11-06: A62b WP3 done (flutter-engineer): `DayMark.estimateKcal`/`version`, `SetDayEstimate` (create/edit/clear/recreate against the shown version, `notPast`/`outOfRange`/`dayHasFood`, tombstone revive), `DayEstimate` bounds, `DayEstimateChanged`; dayMark v1→v2 upgrader, `downgradeProtected` += dayMark (the D23 marks/recovery are generic, so dayMark is covered); drift 15→16 (`estimate_kcal` + CHECK; marks old builds' parked `unsupported` day marks `refused_schema = 1`; kept displaced marks gain `estimate_kcal`); clear-on-food in `LogEntries`/`CopyMeal`/`LogSavedMeal` (by the logged dates), `MoveEntries`/moving `UpdateDiaryEntry`/`MoveDishGroup` (destination dates that change) — one `UpdateRow` per date, events `DayEstimateChanged`; **the combined projection is `DiaryReads.dailyTotals`** (entries + day-estimate marks, watched on both tables; deviation from the planned separate `watchDayIntake`): `DailyTotals.estimateKcal`/`hasDayEstimate`/`dayEstimate`, `IntakeTotals.ofDayEstimate`; `intakeDaysOf` (logged, never complete; superseded too), `DayIntake.dayEstimate` (TG-041), `IntakeDay.dayEstimate` (logged), `DayLog.dayEstimate` → `DayStatus.estimated` (counted, kcal only), Ramadan `dayEstimate` admission (D25), `DiaryDay.intake`, export `estimate_kcal` + docs. Also fixed two A62a upgrader assertions that still treated diaryEntry as v1. Tests written (CI). check-dart, gen-app clean.
- 2026-11-06: A62b WP4 done (flutter-engineer): `DayRows.of(mark:)` → `DayEstimatePromptRow` (replaces the past-day empty hint; today keeps it) / `DayEstimateRow` (active, or superseded when the day has food); the numbers header shows the estimate as the day intake. `DayEstimatePrompt` card ("Didn't log {weekday}?", "about ___ kcal", Save), `DayEstimateTile` ("~2,300"; tap → `DayEstimateSheet`; "~" → popup Edit / Swap for foods = `FoodSearchRoute(date)` with the estimate kept; swipe → remove with Undo; superseded: muted number, no Edit, Swap removes it), `DiaryActions.setDayEstimate` (+ kinds, `dayHasFood` → changed); Progress hatched for `DayStatus.estimated`. ARB: `dayEstimatePrompt`, `dayEstimateAbout`, `dayEstimateKcalLabel`, `dayEstimateSave`, `dayEstimateTitle`, `dayEstimateOutOfRange`, `dayEstimateSaved`, `dayEstimateRemoved`. Keys: `day-estimate-prompt`, `-kcal`, `-save`, `-row`, `-superseded`, `-marker`, `-popup-edit`, `-popup-swap`, `-submit`, `-sheet-kcal`, `-message`. Superseded dimming = muted number only (no DS opacity token; deviation). Tests written (CI). check-dart clean.
- 2026-11-06: A62b WP5 done (flutter-engineer): `make gen-check` clean (no diff), `make trace` (DY-006 and TG-032 covered; the 14 warnings are the pre-existing unknown-ID ones), `make check-dart`, `make check-dotnet`, `make check-contract` clean. Goldens: none changed (no golden shows a past day, a day estimate or an estimated Progress day; not regenerated). Patrol/integration grep for the past-day hint text, `EmptyDayHint`, `Previous day`/`Yesterday`, `day-estimate-*`, `dayMark`/`day_marks`, `TextField` finders: no match on Today past days (Patrol types into TextFields only on the Buddy sheet, food search and sign-in; the jank benchmark's day swipes take the page's first Scrollable, which is the day list, not the card's field). Cross-check: sync_sim uses weighIn only (no change); the D4 unit-display guard patterns don't occur in the new presentation file; DayStatus/ComparisonDay/IntakeDay users all updated (analyzer clean). A62b code complete; ready for the two Codex reviews.
- 2026-11-06: rebased onto main b98f6517 (A63; a rebase, not a merge). Conflicts: board/PROGRESS, D-096/D-097, TD-114/TD-115, IN-001 text, ARB (additive); A63 deleted `weekly_summary_card.dart`, so A62's "~" on the weekly average moved to `CaloriesWeekHeader` (sample sized for "~") and `WeekSummaryTiles`. Today: A62's `DayRows.of` makes the day-estimate rows and A63's `EmptyDayHint` exclusive (today empty → hint; past empty → "Didn't log X?"; estimate → its row), so the past-day hint copy is no longer reached. `make gen-app` (l10n only), `make check-dart`, `check-dotnet`, `check-contract`, `trace` clean; `progress_screen` golden regenerated and viewed. T-P6 written (`test/features/progress/presentation/calories_week_header_test.dart`, backlog #292 done); runs in CI. (flutter-engineer)
- 2026-11-06: A62b Codex review fixes (flutter-engineer). **Schema/contract deviation (D4):** dayMark v2 gains `estimateOnly` (contract, registry, v2 fixture, README; server `DayMarkVersionTests`; `day_marks.estimate_only` in the unshipped 15→16 migration, v16 dump regenerated; upgrader, export). Clearing an estimate-only mark tombstones it (replacement by food, manual clear, Swap) so DY-004 still applies; `MarkDay` writes `estimateKcal` explicitly (live kept, tombstone cleared: no resurrection after Undo) and makes the mark the user's own; `intakeDaysOf` uses `DayMark.confirmedComplete`. Buddy preview on an estimated day = the card alone (D15 deviation). `dailyTotals` is one UNION ALL statement (one snapshot; no interleaving test, atomic by construction). Notifications: day-estimate days are active (`activeDatesOf`). T-P6 inspects paint calls (hatched outline + 3 dashed paths). First-save Undo test fixed. TD-114 in `12` not edited (Accepted; the card D22 text notes `estimateOnly`). gen-app (no further diff), check-dart, check-contract, check-dotnet clean; tests written (CI).
- 2026-11-06: merge CI run 42195993557 failed (8 app tests); fixed (flutter-engineer). **Code:** `editEstimate` compared the replacement food with the read food, whose `editedByUser` lives on the entry, so an unchanged edit wrote a no-op change set (now compares with the food as stored); the Today list row key `day-estimate-prompt` duplicated the prompt card's key (row key now `estimate-prompt`). **Tests:** D23 "only a real downgrade" fixture raw-edited the HLC without this device's `device_id` (the server rightly refused it as `unsupported`); DY-004 day-mark reads now expect `version: 1` (`DayMark.toString` shows the version); day-estimate widget tests dispose the rig's undo stack; the meal-estimate Swap test builds a fresh search controller per open and settles reads in 3 rounds. All 6 files green locally; `make gen-app` (hash only), `make check-dart` clean.

## Outcome

_Claude, 2026-11-06. Tier **Risky**, split A62a (meal estimates) and A62b (day estimates), one branch, `flutter-engineer` (Opus) plus `dotnet-engineer` for the server WPs; two Codex plan reviews, then two Codex code reviews per part and one fix-check per part. Planned A62a L (2-3 sessions) + A62b M (1-2 sessions), each incl. one fix round._

**What was built**
- **A62a, meal estimates**: D-096 (DY-005, DY-006; amends DY-004, TG-031/032, IN-001..003, HM-001/002, AI-032, FD-012), TD-114. Contract `diaryEntry`/`savedMealItem` v2 (`userEstimate` + `proteinKnown`, `carbsKnown`, `fatKnown`, `fiberKnown`). Domain `UserEstimate`, `IntakeTotals`/`IntakeAverages` (an unknown macro is unknown, never zero). Drift 14 to 15, upload v2, export columns. Server: `DiaryEstimatePayloadValidator` (W1-W3) and downgrade refusal. UI: search "~ Estimate" row, `EstimateSheet`, "~ Your estimate" popup (Edit, Swap), "~"/"-" on Today, slots, groups, saved meals, copy sheets, Progress, summary, Ramadan, Buddy.
- **D23 downgrade recovery (rebuilt after review)**: `refused_schema` marks possible downgrades; before a parked retry the app scans the server rows from cursor 0 (cursor untouched) and supersedes only real downgrades.
- **A62b, day estimates**: contract `dayMark` v2 (`estimateKcal`, `estimateOnly`), server `dayMark` downgrade refusal, drift 15 to 16, `SetDayEstimate` (create/edit/clear/recreate against the shown version), clear-on-food rule on every food write path, `DayEstimatePromptRow` ("Didn't log X?") and `DayEstimateRow` "~2,300", hatched days and "avg ~" on Progress, Buddy preview on an estimated day. Day estimates count as activity for the weekly summary and stay out of the adaptive target.
- **Rebase onto A63** (merged first): "~" on the weekly average moved to `CaloriesWeekHeader` and `WeekSummaryTiles`; T-P6 (mixed-estimate week, in-target denominator) written here (backlog #292 done).

**Reviews**
- Plan: Codex round 1 "rework" (5 major, 3 minor), plan reworked (dedicated fields, split into a/b); round 2 "needs another round" (5 major), fixed and verified by the orchestrator (round limit reached, no round 3).
- A62a code: code/architecture (3 major, 1 minor) and data (3 high, 2 medium): all fixed, D23 recovery rebuilt as above. Fix-check "fixes OK"; minor left: "Try again" cannot force marked-row recovery before the daily/app-update gate (backlog).
- A62b code: code (3 major, 1 minor) and data (1 major, 2 minor): all fixed, including the new `dayMark` v2 field `estimateOnly`. Fix-check "fixes OK"; non-blocking gaps (backlog): no estimate-vs-MarkDay two-device matrix test, no export assertion for `estimate_only=true`.

**Deviations (Progress log)**
- D23 reworked: the generic "parked loses to a newer-schema doc" rule is gone for `refused_schema` marks plus a cursor-0 scan (orchestrator direction after the data review).
- The combined projection lives in `DiaryReads.dailyTotals` (entries + day-estimate marks, one UNION ALL statement), not in the planned separate `watchDayIntake`.
- A62b stayed on the same branch (`step/A62-estimates`), one merge.
- `dayMark` v2 gained `estimateOnly` after review; clearing an estimate-only mark tombstones it so DY-004 still applies. **TD-114 (Accepted) was not edited**; card D22 documents it (owner follow-up, backlog).
- Superseded day-estimate dimming is a muted number only (no DS opacity token).

**Measurements**
| Item | Planned | Actual |
|---|---|---|
| Size | A62a L + A62b M, each incl. one fix round | 11 WPs (A62a 6 + A62b 5) + review-fix rounds; 39 commits; 166 files, +72715 / -742 (includes generated and fixtures) |
| Review rounds | 2 plan + 2 code reviews per part (Risky) | 2 plan + 4 code reviews + 2 fix-checks (both "fixes OK") |
| Findings | n/a | A62a: 3 major + 1 minor (code), 3 high + 2 medium (data); A62b: 3 major + 1 minor (code), 1 major + 2 minor (data); all fixed |

**Tests**: written for the plan's test list (W1-W3 vectors with 106 cases, server downgrade theories incl. dayMark, domain, drift migrations 14-16, widget flows, T-P6) and the review fixes. **No local test runs** (owner rule) except targeted golden regeneration (`food_search_results`, `progress_screen`); the CI merge run is the first test evidence.

**Goldens changed**: food_search_results (Scan / Estimate rows), progress_screen; each viewed. No golden shows a past day or a day estimate.

**Not proven yet**: the emulator suite has not run (Patrol greps found no hits); the two-device sync paths run only in the server HTTP tests.

**Deploy note**: the laptop server must be redeployed from `main` before the next APK is installed (schema v2 admission).

**Follow-ups**: backlog #295-#298 (Try again recovery, two-device matrix test, export assertion, TD-114 text needs owner OK); owner device checklist below.

**New decisions**: D-096 (spec/decisions.md); TD-114.

**Exit criteria**: all built; tests written, proven by CI at merge; owner acceptance by use (TD-037).

### Owner device checklist (A55, after merge; optional, D-087)
- Redeploy the laptop server first, then install the APK.
- "~ Estimate" from a meal and from search.
- "+ Macros" with only protein (the other macros show "-", not 0).
- The "~" popup: Edit and Swap.
- Today total shows "~".
- Saved meals list and copy sheet show "~".
- "Didn't log X?" on an empty past day; then log a food that day: the estimate disappears, and one Undo brings both back.
- Progress: hatched day and "avg ~".
- Buddy preview on an estimated day.
- 2026-11-06: Codex plan review r1 (rework) and r2 (5 majors) addressed in 9d616787 and 628ede74; orchestrator verified D23–D27, MoveDishGroup and W3 are in the plan (round limit reached, no r3). Waiting for owner approval of the plan and D-096. (orchestrator)
- 2026-11-06: owner approved the plan and its spec decision ("Ok"). Implementation starts. (orchestrator)
