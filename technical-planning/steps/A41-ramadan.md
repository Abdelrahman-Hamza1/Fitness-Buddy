# A41 — Ramadan mode (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A41a: A05b, A15, A38, A40; A41b: A41a, A39b, **B12** (contract) | A41a L + A41b S (split 2026-10-30) | Claude | ✅ A41a closed, awaiting review/merge · ⬜ A41b (phase 2) |

_Old ID: S46 app part (renumbered by TD-063, 2026-10-16)._

**Goal.** Ramadan is first-class: detected automatically (proposed, not forced), with iftar/suhoor slots, Ramadan targets, prayer-time reminders, honest weight expectations and a Ramadan comparison.

**Spec:** LC-020, LC-030, LC-031, LC-032, LC-033, LC-034, DY-012, TG-037, TG-060, TG-061, NT-008, NT-009, NT-026, WB-021 (Ramadan shading), IN-008, AI-120 (Ramadan suggestions), T30, T31, T32, J9, J11 · **Decisions:** TD-013

## Split (2026-10-30, TD-105)
- **A41a Ramadan mode without Buddy** (phase 1, wave 4): calendar and detection proposal, prayer times, Ramadan slots, Ramadan targets (offered through the weekly summary/check-in instead of the Buddy review), not-fasting days, suhoor/iftar reminders, chart shading, adaptive-target confidence, the Ramadan comparison (IN-008). J9/J11 parts that need no Buddy.
- **A41b Ramadan Buddy parts** (phase 2): Ramadan context for suggestions (AI-120), the "maintain during Ramadan" offer in the Buddy review, T30–T32 on B12's contract.

## Scope
- **`RamadanCalendar`** (`fb_domain`): an Umm al-Qura Hijri package (chosen here) → Ramadan start/end per year + the user's ±1-day shift + a manual on/off (LC-030). The Hijri date shown alongside during Ramadan (LC-020).
- **Proposal to switch on** a few days before (LC-031). A proposal, never silent.
- **Prayer times** (LC-033, NT-026): `adhan_dart` from the chosen city's coordinates (or opt-in location), a calculation method setting with a regional default checked against a local timetable (G12).
- **Ramadan slots** (DY-012): Iftar / Suhoor / Snacks (customizable separately), windows from prayer times. **Suhoor counts toward the calendar day eaten** (T31, DY-001). Normal slots return afterwards.
- **Ramadan targets** (TG-060/061): a separate setting, "maintain during Ramadan" offered via the first Ramadan weekly review. Normal targets resume automatically.
- **Not-fasting days** (LC-034): mark a day, and normal slots and reminders apply.
- **Reminders:** suhoor (45 min before Fajr, allowed in quiet hours) and iftar log nudge (90 min after Maghrib), plugged into the A40 planner.
- **Weight:** shaded Ramadan periods on charts (WB-021), lower confidence in adaptive targets (TG-037).
- **Ramadan comparison** (IN-008): intake, trend and workouts during Ramadan vs the month before.
- **Suggestions** favour suhoor-appropriate options and iftar staples (AI-120 context).
- The Ramadan context for suggestions and the T30–T32 eval cases are B12's.

## Out of scope
- —

## Fixed by the plan
- Day boundaries are calendar days, so no special day logic (`09` §2).

## Decide in the low-level plan
- The Hijri package and the default prayer calculation method for Palestine (verified against a local timetable).

## Exit criteria
- [ ] **J9, J11, T30–T32** pass (E2E with a fake clock across Ramadan start/end).
- [ ] Prayer times for the owner's city match a local timetable within ±2 minutes for 10 sampled days.
- [ ] Time-zone/DST and Ramadan boundary tests (incl. the ±1-day shift).
- [ ] Planner tests for the suhoor/iftar rules (quiet-hours exception).

## Read first
`spec/18-localization-and-culture.md` §3–4 · `09-cross-cutting.md` §2 · `spec/01-personas-and-journeys.md` J9, J11

## Owner involvement
Check the prayer times for your city. Review during the next real Ramadan.

---

## Low-level plan
_A41a only. Claude, 2026-10-31. Tier **Risky** (a user-data write path: the not-fasting day mark, slot editing per mode, a migration). One engineer, one Codex review (code + security/data). Expected size L (one fix round included)._

### D1 Calendar: our own Umm al-Qura table (`fb_domain/src/ramadan/umm_al_qura.dart`)
- Only 1 Ramadan and 1 Shawwal are needed (Ramadan's dates, its day number for LC-020), so a two-dates-per-year table for Hijri 1440–1499 (2019–2076) instead of a package: `fb_domain` stays dependency-free.
- Data: the Umm al-Qura month-start series of `hijri-converter` 2.3.2 (MIT, the same series as van Gent's tables and the `hijri` Dart package), epoch 1858-11-16, which makes 1447–1450 match van Gent's published list exactly; 1447 also matched Palestine's announced dates (1 Ramadan Wed 2026-02-18, Eid Fri 2026-03-20). Tests pin 1447–1457 and the 29/30-day / ~354-day invariants. Rejected: `hijri` 3.0.1 (BSD-2, real table, but app-side only and an unverified uploader), `hijri_calendar` (stale), `hijri_date`/`jhijri` (Flutter deps).
- `RamadanCalendar` (pure) over the setting `ramadan.seasons` (D3): shifted periods, `isOn(date)` (charts, comparison), `isFastingDay(date, notFasting)` (slots, targets, reminders, adaptive), `slotModeOn`, `maintainOn`, `relevant(today)` and `proposalOn(today)`.

### D2 Prayer times: own implementation, default Muslim World League (`prayer_times.dart`)
- The standard spherical-astronomy formulas (PrayTimes algorithm; Astronomical Almanac low-precision sun), one refinement, rounded to whole minutes, UTC instants; the app converts with the device zone at that instant (`Clock.offsetMinutesAt`), so DST days are right without a tz database. One-seventh rule for Fajr at high latitudes, null for polar day. _(Amended in review round 1: reminders keep dated UTC instants; the city's times are shown in its IANA zone via `timezone`; the middle-of-the-night rule, one bound for both the limit and the fallback.)_
- Rejected `adhan_dart` 2.0.1 (MIT, fine) only to keep the computation in pure `fb_domain`, where the planner consumes it; the verification test is the guard. `adhan` 2.0.0 can't resolve on Dart 3.
- **Default method: Muslim World League (Fajr 18°, Maghrib = sunset).** No published official Palestinian (Awqaf / Dar al-Ifta) angle or timetable could be found (the official calendar is a fixed table; research 2026-10-31). The published Ramallah timetable we verify against is IslamicFinder's (geonames 282239, MWL): 12 sampled days across 2026 (Ramadan 1447 start/end, both DST changes, summer, winter) within ±2 min (`prayer_times_test.dart`). Other methods offered: Egyptian 19.5°, Jordan (18°, Maghrib +5), Umm al-Qura 18.5°, ISNA 15°. Setting `prayer.method` (synced). A per-prayer minutes adjustment is a follow-up (backlog).
- City only (LC-033 default): the chosen city's coordinates from the bundled list; **no location permission** in A41a (opt-in device location: backlog).

### D3 Settings, no new entity
- `ramadan.seasons` (synced settings key): JSON `{"<hijriYear>": {"on", "startShift", "endShift", "maintain"}}`. _(Review round 2: each not-fasting decision is its own key `ramadan.fasting.d<yyyymmdd>`.)_ No entry = undecided (the proposal shows). Unreadable years are skipped. Last writer wins on the whole value (rare edits).
- `prayer.method` enum, default `muslimWorldLeague`.
- Writes through `SettingsActions` (direct action with Undo).

### D4 Proposal (LC-031)
- Today shows a card from 3 days before the (shifted) start until the end while undecided: "Ramadan is expected to start on …", **Switch on** / **Not now** (a decision either way is stored; Not now = `on: false`, switch on later in Settings › Ramadan). Never silent.

### D5 Ramadan slots (DY-012)
- Seeded Suhoor / Iftar / Snacks (`mode: ramadan`, UUIDv5 `mealSlot:ramadan:<key>`), migration v12 → v13 (also adds `ix_proposals_kind`, backlog #235). The contract already allows `mode: ramadan`; seeded rows sync only after an edit (A01 D7).
- Suhoor/Iftar have no stored window: their window follows the day's prayer times (Suhoor = Fajr − 3 h → Fajr, Iftar = Maghrib → +3 h, `09` §2); a fallback window without a city; a window the user sets wins (clear it to follow prayer times again).
- "Customizable separately": the Meal times editor takes a mode; `AddMealSlot` gains `mode`; the slot handler edits within the slot's own mode (limits, reorder set, remove destination).

### D6 Which slots a day uses
- `daySlotsProvider(date)`: mode = Ramadan on a fasting day (on period, not marked not fasting), effective windows from that day's prayer times. Today's layout, the add flow's slot choice and auto-assignment, quick add, saved meals and move/copy sheets use it.
- The handlers' fallback (an entry without a slot) reads the stored seasons and the day mark in the transaction (fallback windows, no prayer times). `requireUsableSlot` accepts an active slot of either mode: the day's mode is the screens' choice and the day layout shows any slot that holds food. Suhoor counts toward the calendar day it's eaten (T31, DY-001): no day-boundary change (`09` §2).

### D7 Not-fasting days (LC-034)
- ~~New op `MarkNotFasting` on `day_marks.not_fasting`~~ _Amended in review round 1:_ the not-fasting days are stored on the season (`ramadan.seasons`, `notFasting` dates), a settings write with Undo, so a diary day mark keeps meaning only "the user judged this day's logging" (A38's complete-day rule is unchanged). `day_marks.not_fasting` stays unused. Today's day menu on a Ramadan day: "Not fasting today" / "Fasting today".

### D8 Targets (TG-060/061)
- `TargetsTimeline.day(ramadanMaintain:)`: on a fasting day of a "maintain" season, a generated base drops the goal's (SF-011-capped) energy, never below the floor; manual bases stay; normal targets resume after Ramadan by construction. `DayTargets.ramadanMaintain` for the UI.
- Choosing it: Settings › Ramadan "During Ramadan: keep my goal / maintain my weight" now; the one-tap offer in the first Ramadan weekly summary/check-in is wired when A40's weekly summary is on main.

### D9 Weight and insights
- Charts: `chartHighlightPeriodsProvider` returns the on periods (WB-021; the hook and label exist). Adaptive: `isRamadan` = fasting day (TG-037; closes #232).
- Ramadan comparison (IN-008) on Progress from the first day until 30 days after: average intake (logged, complete days), trend change, workouts per week, Ramadan so far vs the 30 days before.
- The Hijri day shows next to the date on Today during Ramadan (LC-020: "Ramadan 5").

### D10 Reminders (NT-008/009/026), after A40 lands
- Suhoor 45 min before Fajr (allowed in quiet hours, on by default during Ramadan), iftar log nudge 90 min after Maghrib (off by default), only on fasting days, through A40's planner `extra` candidates (`quietHoursExempt`, `capExempt`). Planner tests for both rules.

### Out of A41a
Buddy's Ramadan context and slots in proposals (A41b/AI-120, backlog), T30–T32 (B12), opt-in device location, per-prayer minute adjustments.

### Tests
- fb_domain: `ramadan_calendar_test` (1447–1457 dates, invariants, ±1 shifts both ways, on/off, not fasting, maintain stops, proposal window), `prayer_times_test` (12 timetable days ±2 min incl. DST days, order, methods, high latitude, polar), `ramadan_slots_test` (windows, T31 suhoor 03:30 → Suhoor, user window wins, fallback, wrap), `ramadan_comparison_test`, timeline maintain tests, op equality.
- App: not-fasting op (write, keep incomplete, future limit, Undo), slot handler per mode, handler fallback on a Ramadan day, migration v12→v13 (seeds + index), J11 with a fake clock across Ramadan start and end (proposal → switch on → Suhoor/Iftar slots → not fasting → normal slots after the end), Ramadan settings screen happy path, comparison provider.

### Work packages
WP1 domain + tests · WP2 data (migration, ops, handlers, settings keys) · WP3 providers + Today/Settings/Progress UI + ARB · WP4 (after A40) reminders + check-in offer · WP5 cross-check, docs, Outcome.

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: split into a/b (TD-105, owner).
- 2026-10-31: A41a plan written (Claude, self-approved; research on Hijri/prayer libraries and the Ramallah timetable).
- 2026-10-31: WP1 domain (88e9b88), WP2 data (1470128); merged origin/main with A39a+A40 (e69b001); WP4 domain (9152883, 48e63b0); WP3/WP4 app (ea9b9e2). Closed, awaiting Codex review and merge.
- 2026-10-31: Codex fix-check round 2 (reminder date range; per-date fasting keys) fixed in 10242e8. Local: fb_domain ramadan/notifications ✓; app ramadan (incl. two-phone sync), diary, today, progress, notifications, adaptive, targets, settings, core settings/export/db sync, quick add, app ✓; analyze, format, gen-app, app_check clean.
- 2026-10-31: Codex review round 1 (3 major, 3 minor) fixed in 58cc98a; origin/main unchanged (a59cc64). Local: fb_domain ramadan/diary/notifications/timeline ✓; app ramadan (journey, zone, offer, screen), diary data/application, adaptive, notifications, today, progress, quick add, targets, settings, foods, body, workouts, buddy presentation, export, app ✓; analyze, format, gen-app, app_check clean.

## Outcome
### A41a (Claude, 2026-10-31; the orchestrator adds the Codex review, CI and merge)

**Built** (commits 8dce663 plan, 88e9b88 WP1, 1470128 WP2, e69b001 merge of A39a+A40, 9152883 + 48e63b0 WP4 domain, ea9b9e2 WP3/WP4 app):
- `fb_domain/src/ramadan/`: `UmmAlQura` (1 Ramadan / 1 Shawwal, Hijri 1440–1499), `RamadanCalendar` (shifts, on/off, fasting day, slot mode, maintain, proposal window, targets offer), `RamadanSettings`/`RamadanSeason` (JSON, tolerant), `PrayerTimes` (+ `PrayerMethod`, `GeoPoint`), `RamadanSlots` (seed rows, prayer windows, fallback), `RamadanComparison`, `RamadanReminders`; `TargetsTimeline.day(ramadanMaintain:)`; ops `MarkNotFasting`, `AddMealSlot(mode:)`; `NotificationType.suhoor`/`iftar`.
- App: migration v12 → v13 (Ramadan slot seeds + `ix_proposals_kind`, #235); `MarkNotFasting` handler; slot handler per mode; the handlers' fallback reads the day's mode in the transaction; settings `ramadan.seasons`, `prayer.method`; `daySlotsProvider` used by Today's layout, the add flow, quick add, saved meals, move/copy sheets; Settings › Ramadan (mode, first/last day ±1, Ramadan meal times, During Ramadan, city, today's Fajr/Maghrib, method, link to reminders); Today: the proposal card, "Ramadan N" next to the date, Not fasting today / Fasting today in the day menu and a note; Ramadan meal times editor (the Meal times screen by mode); chart shading (weight graph and Progress); Ramadan comparison card on Progress; adaptive `isRamadan` (#232); `dayTargets` maintain; the targets offer card in the weekly summary; suhoor/iftar candidates in the notification inputs, settings rows, texts and links. 71 ARB strings; the Me › Settings golden regenerated (the new Ramadan row).

**Decisions** as planned (D1–D10), plus while building:
- **Maghrib is rounded up** to the minute (the fast is never shown ending early); Fajr to the nearest. With that, all 182 days of IslamicFinder's 2026 Ramallah timetable we have (Feb, Mar, Jun, Jul, Oct, Dec) are within ±2 min for both (Fajr −1…+2, Maghrib 0…+2); nearest rounding left 8 October days at +3 for Maghrib.
- The targets offer state is a season field (`targetsAnswered`); shown in the first seven days of an on Ramadan for generated (not manual) targets.
- Adaptive confidence uses Ramadan days with the mode on (`isOn`), not-fasting days included (weight still fluctuates around them).
- A new timed Ramadan meal is placed by the fallback Suhoor/Iftar windows (the stored ones are empty).
- Buddy keeps normal slots (A41b; backlog #252).

**Verification samples (exit 2).** IslamicFinder, Ramallah (geonames 282239), MWL, fetched 2026-10-31; local time (UTC+2; +3 from 2026-03-28 to 2026-10-23), Fajr / Maghrib: 02-18 04:58/17:29 · 02-25 04:51/17:34 · 03-05 04:42/17:41 · 03-19 04:24/17:51 · 03-28 05:10/18:58 · 03-29 05:09/18:58 · 06-15 03:54/19:48 · 07-15 04:08/19:48 · 10-01 05:13/18:26 · 10-24 04:28/17:00 · 10-31 04:33/16:53 · 12-15 05:05/16:38. All within ±2 min (`prayer_times_test.dart`). **Not the official Palestinian calendar:** no published Awqaf/Dar al-Ifta angles or timetable could be found (the official one is a fixed table); owner check #254.

**Schema/sync.** Drift v13 (seeds + one index; frozen-migration check OK). No new synced entity: `day_marks.not_fasting` and `meal_slots.mode = ramadan` were already in the schema and the contract; two new settings keys (open vocabulary). No contract change.

**Tests** (single files through `heavy.sh`, all green): fb_domain `test/ramadan/` (calendar 1447–1457 + invariants + shifts + proposal + offer, prayer times 12 days + methods + high latitude + polar, slots, comparison, reminders with the real planner: quiet-hours exemption, cap exemption, fasting days only, defaults, midnight wrap), timeline maintain (4), notifications prefs. App: `ramadan_diary_ops_test` (not fasting ×4, handler Ramadan slots incl. T31 suhoor 03:30, shifted start, not-fasting day, after Ramadan, other-mode explicit slot, Ramadan set editing ×3), `ramadan_slots_migration_test`, seed tests, `ramadan_journey_test` (J11 with a fake clock across the start and the end), `ramadan_screen_test`, updated router, day menu, notification links, food/quick-add overrides. Batches run: today, ramadan, progress, diary presentation, quick add, notifications, app, targets, adaptive, settings, foods, export, me, onboarding, body, workouts, buddy presentation, unit display, app tabs, l10n. `dart analyze --fatal-infos apps packages tools` clean, format clean, `make gen-app` no diff, `app_check` OK.

**Exit criteria.** J11 (no Buddy part) ✓ app-level journey; J9's Ramadan part (the targets offer in the weekly summary) ✓ provider + card; T30–T32 are A41b's · prayer times ±2 min on 12 days ✓ (published timetable, not the official calendar) · TZ/DST (both 2026 DST days in the timetable test, local minutes via the device zone at each instant) and Ramadan boundaries incl. ±1 shifts ✓ · planner suhoor/iftar rules incl. quiet hours ✓.

**Open items.** Backlog #252–#259; #232 and #235 done; #250 partly done.

**Review round 1** (Codex, CHANGES-REQUIRED: 3 major, 3 minor; all fixed in 58cc98a, 2026-10-31):
- (1, major) Fasting status could confirm diary completeness: a not-fasting toggle left a `day_marks` row that A38 read as "count again". Not-fasting days now live on the season setting (`RamadanSeason.notFasting`, `SettingsActions.setNotFasting`, Undo); `MarkNotFasting`/`FastingMarked` removed; `intakeDaysOf` back to A38's rule. Test: `ramadan_diary_ops_test` group "not fasting never touches the diary marks" (both directions, an existing count-again day, the setting written and reverted: day marks and `confirmed` identical); journey: no `day_marks` row after marking a day.
- (2, major) Prayer conversion dropped the date and used the device zone: `RamadanReminders` takes the dated UTC instants and the clock, and gives each candidate its `atUtc` and the device-local date/minute of that instant; `prayerTimesProvider` adds the city's wall-clock minutes from its IANA zone (`CityZone`, `timezone` 0.11.2 already pinned by A40; database loaded lazily). Tests: `ramadan_reminders_test` (a device 6 h behind, a city west of the device crossing midnight, a DST change between days), app `prayer_zone_test` (New York device, Ramallah times across Hebron's 2026-03-28 DST start against the timetable; a UTC+14 device gets the iftar nudge on its next day; unknown zone falls back).
- (3, major) The ended Ramadan was not editable on Shawwal 1: `relevant()` keeps a season while its end could still be extended (+1), the proposal never shows after the end. Tests: calendar "on the calendar first day of Shawwal …", journey: Settings status on 2027-03-09 is 1448, end +1 makes it a fasting day.
- (4, minor) High-latitude rule: the middle of the night is both the limit and the fallback (PrayTimes NightMiddle). Test: Oslo March–June, Fajr never earlier than the bound, equal to it in June, no day-to-day jump of hours.
- (5, minor) The MIT notice of hijri-converter 2.3.2 is kept as `UmmAlQura.sourceLicence`, in `packages/fb_domain/THIRD_PARTY_NOTICES.md`, and registered on About › Licences (`main.dart`).
- (6, minor) `ramadan_targets_offer_test`: the provider (generated vs manual targets, season off, after the first week) and the card (Maintain stored, Undo brings the offer back, Keep my goal stored).

**Review round 2** (Codex fix-check: 1, 3–6 fixed; 2 partly; one new major; both fixed in 10242e8, 2026-10-31):
- (2, major, remaining) Reminder dates: the city's fasting dates are enumerated around the device horizon (a day either side, in `RamadanReminders` and the notification inputs), and the planner filters by date and instant. Tests: a replan at 06:00 on a UTC+14 phone keeps the previous city day's iftar nudge (06:59); after the last fasting day its nudge past the device midnight is still planned.
- (new major) Whole-value LWW could erase daily marks: each day's decision is its own synced setting `ramadan.fasting.d<yyyymmdd>` = `notFasting` | `fasting` (explicit fasting-again), read as a set (`SettingsStore.watchValues`, `ramadanNotFastingProvider`); `ramadan.seasons` holds only the season preferences. Undo per mark. The handlers' fallback reads the date's key in the transaction; export knows every per-date key name. Test: `ramadan_sync_test`, two drift phones and the fake sync server: offline marks on different days plus a concurrent "maintain" edit converge on both; a later explicit fasting-again wins; Undo syncs.
- Sweep for test rigs without a database (coordinator, after round 1): core, account, sync, onboarding, me, design preview, buddy application/data, app shell golden, drift, l10n all green; no change needed beyond `day_view_test` (round 1).

