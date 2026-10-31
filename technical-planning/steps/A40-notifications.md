# A40 — Notifications

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A37c, A39a | M | Claude | ✅ closed, awaiting review/merge (with A39a) |

_2026-10-30 (TD-105): re-pointed from A27, A37, A39 to the non-AI halves A37c (workout reminder on planned days; A37a/A37c split 2026-10-30) and A39a (summary ready), so phase 1 needs no Buddy step. The batch-closing reminder (batches arrive with A27, phase 2) is added when batches exist; the pending-proposal reminder uses A23a's proposals (done)._

_Old ID: S45 (renumbered by TD-063, 2026-10-16)._

**Goal.** Moderate, configurable, never guilt-tripping reminders, all local, planned by a pure function and scheduled idempotently, each opening exactly the right place.

**Spec:** NT-001, NT-002, NT-003, NT-004, NT-005, NT-006, NT-007, NT-010 (NT-008/009 wired in A41), NT-020, NT-021, NT-022, NT-023, NT-024, NT-025, WB-043, PR-8 · **Decisions:** TD-013

## Scope
- **`NotificationPlanner`** (pure, `fb_domain`, `09` §1): inputs = prefs + now/tz + the next 7 days of state. Output = the exact notification set after quiet hours (NT-021), the max 2/day by priority (NT-022) and skip-if-not-applicable (NT-023). The iOS 64-limit is respected.
- **Types:** log reminder (only if < 2 meals logged), pending proposal (30 min after, once), weigh-in (weekly day), weekly review ready, workout on planned days, protein check, measurement (monthly), batch closing (day before auto-close). Ramadan types are plugged in by A41.
- **`NotificationScheduler`** (platform): diff planned vs scheduled → cancel/schedule, idempotent. **Re-plan triggers:** app start/resume, domain events, settings changes, a tz change.
- **Deep links** (NT-024) via go_router: pending card, weigh-in pad, review, workout form, batch.
- **Settings UI** (NT-020): master switch, per-type on/off and time, quiet hours. Defaults per `spec/17`.
- **Wording** (NT-025): ARB templates, neutral, checked against banned words.
- Android permission flow (POST_NOTIFICATIONS, exact alarms if needed).

## Out of scope
- Push notifications (R2+). Suhoor/iftar times (A41).

## Fixed by the plan
- All local, nothing personal leaves the phone for reminders (TD-013).

## Decide in the low-level plan
- Exact vs inexact alarms on Android (battery vs precision) per type.

## Exit criteria
- [ ] **Every NT rule has a table-driven planner test** (quiet hours, cap + priority, skip rules, conditional cancellation).
- [ ] Scheduler idempotency test (re-planning twice changes nothing).
- [ ] Each notification type's deep link opens the right screen (integration test).
- [ ] The owner runs with the defaults for a week. Feedback on noise.

## Read first
`09-cross-cutting.md` §1 · `spec/17-notifications.md`

## Owner involvement
Live with it for a week. Say if anything is annoying.

---

## Low-level plan
_Claude, 2026-10-31. **One combined plan for A39a (Weekly summary, no Buddy) and A40 (Notifications)**, built as one step on `step/A39a-A40-summary-notifications` (owner: one plan, one implementation, one Codex review). Tier **Normal** (no user-data write path beyond one more settings key through the existing writer; nothing leaves the phone). Expected size M–L._

### Decisions
- **D1 `WeeklySummary` (fb_domain, `insights/weekly_summary.dart`, IN-001, WO-043).** Pure: `WeeklySummary.of(weekStart, today, days: List<ProgressDay>, trendOn, workouts)`. Reuses A16's `ProgressDay` (per-date targets = Today's, G10) so a summary agrees with the charts. Counted days only (logged, not incomplete, not today; A16 D4/TG-032). Fields: elapsed days (earlier days of the week; 7 for a past week), counted days, **average kcal vs average target** (counted days with a target), **days within target** (counted days with a target where |eaten − target| ≤ 10 % of the target; a 10 % band, D1a), **protein-target days hit** (eaten ≥ the day's protein target, of the counted days with one), **fiber average**, **trend change** (trend on the week's last elapsed day, or today for the current week, minus the trend on the day before the week), **workouts** (`WeeklyWorkoutSummary`: sessions, planned only with a plan (D-085, WO-024: no "missed" count), PRs). Any past week; a future week is refused. "Planned" reads the current plan (no plan history exists; noted).
- **D2 Summary card at the top of Progress (SC-5).** `WeeklySummaryCard` replaces A16's `ProgressWeekHeader` (same tinted block): this week so far. The A38 check-in (`CheckInCard`, backlog #231) moves **inside** the card's widget, under the numbers, for the current week (the check-in lives in the current week, `checkInOfWeek(weekStartOf(today))`); the proposal rows and actions are unchanged. The incomplete-day suggestion stays a separate card below. A "Past weeks" row opens **`WeeklySummaryScreen`** at last week (`/progress/week/:start`, nested in Progress), with ‹ › between weeks (bounded by the earliest data date and this week). The same route is the "weekly summary ready" deep link.
- **D3 Notification prefs = one synced settings key** `notifications.prefs` (JSON, `NotificationPrefs` in fb_domain with a tolerant reader: a malformed field falls back to its default, unknown types ignored). Master switch, quiet hours (default 23:00–07:00), per type on/off + minute of day, weigh-in day (default: the week-start day), measurement day of month (fixed 1st). Written through `SettingsActions` (single writer, Undo). No schema change, no sync entity, no migration (settings rows already sync).
- **D4 `NotificationPlanner` (pure, fb_domain, `notifications/`).** Input: prefs, today + minute now, the shown-today count, and `NotificationState` (meals logged today, protein eaten/target today, weighed-in dates, measurement dates, plan weekdays → template, logged workout dates, pending proposal times (local), active dates of the last two weeks, week start). Output: the exact future notifications for today + 6 days. Rules, each with a table test:
  - **NT-020** master off → nothing; a type off → none of it; times from prefs.
  - **NT-021** quiet hours (a window that may cross midnight) drop a candidate inside it; a candidate may be `quietHoursExempt` (the suhoor hook).
  - **NT-022** at most 2 non-Ramadan per local day, by priority pending proposal > weekly summary > weigh-in > log reminder > workout > protein > measurement; today's already-shown count (from the scheduler's ledger) uses up slots first; `capExempt` candidates (Ramadan hook) don't count.
  - **NT-023** skip rules: log reminder only if < 2 meals today (future days assumed, cancelled on re-plan when it stops applying, `09` §1); weigh-in not if weighed that day; workout only on planned weekdays and not if a session is logged that day; protein only with a protein target and eaten < 50 % of it (today); measurement not if measured in the 7 days up to it; weekly summary only if the ending week has any activity (diary day, weigh-in or session; assumed for a week not over yet); pending proposal 30 min after creation, once (a past time is never rescheduled), the earliest per day.
  - Past times are never planned; at most 64 pending (iOS limit; trimmed latest first).
  - **Ramadan hook (A41a):** `extra: Iterable<NotificationCandidate>` goes through the same rules with its own `capExempt` / `quietHoursExempt` flags; A41a adds the suhoor/iftar types and feeds candidates. No batch-closing type (batches arrive with A27; added then).
- **D5 Scheduler (app, `features/notifications/`).** `NotificationPlatform` port (initialize/tap callback, launch payload, pending, schedule, cancel, enabled, request permission) with a `flutter_local_notifications` adapter and a fake for tests. `NotificationScheduler.sync(planned)`: payload = `v1|<epoch minute>|<text hash>|<route>`; schedule a planned item whose payload differs from the pending one with its ID, cancel a pending future item not planned; past-due pending items are left alone (inexact delivery may still be on its way). **Idempotent**: a second sync with the same plan makes no platform call. A small device-local **ledger** (shared_preferences `fb.notifications.ledger`: ID + time only, nothing personal) gives the shown-today count for NT-022. Stable IDs: `type code × 1,000,000 + epoch day`.
- **D6 Re-plan triggers.** A keep-alive `NotificationCoordinator`, started by the bootstrap after the first frame (never before it, UX-001): first run, app resume (also catches a time-zone change and the first open of a day), every domain event (debounced 1 s), the prefs stream, today changing. Runs are serialized (one in flight, one queued). OS notifications off → plan nothing and cancel ours. All local, no network (TD-013).
- **D7 Android.** Plugin **`flutter_local_notifications` 22.3.2** (BSD-3, maintained, published 2026-10-12) + `timezone` 0.11.2 (its required companion; only `tz.UTC` is used: instants are computed in Dart, so no time-zone database lookup or extra plugin). Manifest: the plugin adds `POST_NOTIFICATIONS` and `VIBRATE`; we add `RECEIVE_BOOT_COMPLETED` and the two plugin receivers (not exported) so reminders survive a reboot/update. Core library desugaring enabled (the plugin requires it). **All types inexact** (`inexactAllowWhileIdle`): none needs minute precision, and no `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` (Play policy, battery). `apk_hardening_check.py` gains a rule failing a release that asks for an exact-alarm permission, with a fixture (A41a revisits for suhoor if needed). One channel "Reminders", small icon `ic_launcher_monochrome`.
- **D8 Permission flow (Android 13+).** Asked once in context: the first time the coordinator runs with the master switch on after setup (a device flag, so never again automatically), and from the Notifications screen's banner ("Notifications are off for Fitness Buddy" + Allow) whenever the OS says they're off.
- **D9 Deep links (NT-024).** Payload = a go_router location: log reminder and protein → `/today`; pending proposal → `/today?open=buddy` (Today opens the Buddy sheet, where the pending cards are); weigh-in → `/today?open=weigh-in` (the weigh-in pad); weekly summary → `/progress/week/<last week start>`; workout → `/today/workout-log?template=<id>&date=<day>` (the planned template's log form), `/workouts` without one; measurement → `/progress/measurements`. `TodayRoute` gains an optional `open`; Today handles it once and clears it. Taps while running (`onDidReceiveNotificationResponse`) and the launch tap (`getNotificationAppLaunchDetails`, after the first frame) both go through one handler; a payload that isn't a relative app path is ignored.
- **D10 Settings UI (NT-020).** Me › Settings › **Notifications** (`/me/notifications`): OS-permission banner, master switch, quiet hours (from/to), then each type: switch + time (weigh-in also its day; pending proposal has no time). Defaults per `spec/17`. Each change is a direct action with Undo.
- **D11 Wording (NT-025).** ARB templates, neutral and short ("Anything to log from today?"), no numbers or names on the lock screen; a test checks the notification strings against SF-020's words plus "forgot", "streak", "missed", "don't break".

### Files
- fb_domain: `src/insights/weekly_summary.dart`, `src/notifications/notification_prefs.dart`, `src/notifications/notification_planner.dart`; barrel; tests `weekly_summary_test.dart`, `notification_prefs_test.dart`, `notification_planner_test.dart`.
- App: `features/notifications/` (barrel, `application/` coordinator, inputs, scheduler, ledger, links, texts; `data/` platform port + plugin adapter; `presentation/notification_settings_screen.dart`); `features/progress/` (`weekly_summary_providers.dart`, `weekly_summary_card.dart`, `weekly_summary_screen.dart`; `ProgressWeekHeader` removed); settings key + action; routes `WeeklySummaryRoute`, `NotificationSettingsRoute`, `TodayRoute.open`; bootstrap start; Today `open` handling; ARB strings; Android manifest + Gradle; `apk_hardening_check.py` + fixture.
- Tests: planner table tests (every NT rule), prefs codec, scheduler idempotency + diff + ledger, coordinator trigger (fake platform), deep links through the router (each type → its screen/sheet), weekly summary providers/card happy path, notification copy guard; the Progress golden regenerated.

### Work packages
1. fb_domain: WeeklySummary, prefs, planner + tests.
2. Progress: summary providers, card (+ check-in inside), past-weeks screen + route; golden.
3. Notifications app layer: platform port/adapter, scheduler + ledger, inputs, coordinator, texts, links, Today `open`, bootstrap; Android manifest/Gradle; hardening rule.
4. Settings UI + permission flow; ARB; tests; cross-check; close-out.

### Exit criteria mapping
- Every NT rule → `notification_planner_test.dart` (tables per rule). Scheduler idempotency → `notification_scheduler_test.dart`. Deep links → `notification_links_test.dart` (router-level, every type). Summary offline → domain tests (synthetic weeks) + card widget test on the in-memory profile. The owner's week with the defaults is the acceptance by use (D-087).

## Progress log
- 2026-10-31: combined A39a + A40 plan written (one step, owner) f6f8efd1.
- 2026-10-31: built: domain 7b7cf144, app 0aa81c9a, fix c47121df; close-out (Outcome, board, backlog #236–#243, renumbered #243–#250 at the main merge).
- 2026-10-31: merged origin/main (A34 + A35) 3cd8d9fa; Codex review 1 fixed in 6ba8f5d9 + 0992aa1b. Local: fb_domain notifications 27 ✓; app notifications 23 ✓, weekly summary 4 ✓, progress screen/golden ✓, test/app (router, tabs, shell, bootstraps, startup) ✓, account deletion, delete-account screen, sync wiring, settings screens/golden, export, adaptive cards, l10n ✓; check-dart, gen-app clean.
- 2026-10-31: Codex fix-check fixed in bd7a3e2d + 8db3f452. Local: fb_domain notifications 28 ✓; app notifications 28 ✓, test/app, account deletion, workouts presentation, today navigation ✓ (92); check-dart, gen-app clean.
- 2026-10-31: Codex recheck: the same workout link while its tab is hidden (Me) finished the visit; fixed in df121e5f (per-tab location, the tab is just brought back). Regression test fails without the fix. Local: notification_links 9 ✓, workouts presentation + test/app 56 ✓ (with links), analyze/format clean.

## Outcome
_Claude, 2026-10-31: **A39a + A40 as one step** (the orchestrator adds the Codex review, CI and merge). Actual size M–L, as planned._

**Built.**
- **fb_domain** (7b7cf144): `WeeklySummary` (IN-001, WO-043) over A16's `ProgressDay` series (counted days only; average kcal vs target, days within ±10 %, protein days hit, fiber average, trend change, workouts with "planned" only with a plan, PRs; any past week; `weekStarts` for stepping). `NotificationPrefs` (one synced value, tolerant field-by-field reader, spec/17 defaults) and the pure `NotificationPlanner` (D4).
- **Progress (A39a)**: `WeeklySummaryCard` replaces A16's `ProgressWeekHeader` (and `weekGlanceProvider`) at the top; the A38 `CheckInCard` now sits inside it (backlog #231 done); "Past weeks" opens `WeeklySummaryScreen` (`/progress/week/:start`, ‹ › bounded by the first data week and this week). `weeklySummaryProvider(weekStart)` reuses `progressDaysProvider`, the trend and `weeklyWorkoutSummaryProvider`. All local.
- **Notifications (A40)**, new feature `features/notifications/`: `NotificationPlatform` port + `PluginNotificationPlatform` (flutter_local_notifications), `NotificationScheduler` (payload `v1|<epoch minute>|<text hash>|<location>` diff, device ledger for NT-022, idempotent), `notificationInputsProvider` (follows prefs, diary totals, day mark, targets, weigh-ins, measurements, plan, sessions, Buddy's pending meal cards), `NotificationCoordinator` (bootstrap after the first frame; inputs, domain events, resume; serialized runs; one coordinator across profile switches), `notificationRoute`/`notificationText`, `NotificationSettingsScreen` (Me › Settings › Notifications). `TodayRoute(open:)` opens the weigh-in pad or the Buddy sheet once and clears itself.
- **Android**: `RECEIVE_BOOT_COMPLETED`, the plugin's two receivers (not exported), core library desugaring (`desugar_jdk_libs` 2.1.4), `res/raw/keep.xml` for the small icon. The plugin's own manifest adds `POST_NOTIFICATIONS` and `VIBRATE`. **All reminders inexact** (`inexactAllowWhileIdle`); no exact-alarm permission, and `apk_hardening_check.py` now fails a release that asks for `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` (new fixture `exact-alarm-permission`). `tools/app_check` lists `flutter_local_notifications` as an I/O package (only `data/` may import it).

**Decisions while building** (beyond D1–D11):
- NT-002 covers Buddy's pending **meal cards** (`foodLog`); the weekly check-in is announced by the summary notification (NT-004 "includes any target proposal"), so it isn't reminded twice.
- One notification per type and day (stable IDs): a type already shown today isn't scheduled again even if its time moves later.
- The permission is asked automatically once, only after first use (any diary day, weigh-in or session in the last two weeks), never on a fresh install's first screen; afterwards only from the screen's Allow.
- Notifications are built with the English strings outside the widget tree (`lookupAppLocalizations(en)`, R1 English only).
- With OS notifications off or the master switch off, the coordinator cancels ours and plans nothing.
- Widget tests of other features run with scheduling off (`TestPhone(notifications: false)` default, fake platform and store), so no existing test touches a platform channel or the recorded preferences.

**Data/schema.** No drift change, no migration, no sync entity: one more synced settings key (`notifications.prefs`, in `AppSettings.all` for export). Device-local, never synced: `fb.notifications.ledger.v1` (IDs and times only) and `fb.notifications.permission_asked.v1`.

**Tests.** fb_domain: `notification_planner_test` (20: a table per rule: NT-020 switches/times, NT-021 quiet hours incl. midnight crossing and the exempt hook, NT-022 priority order, shown-today, cap-exempt, NT-023 per type (log, weigh-in, summary, workout, protein, measurement, pending), horizon, 64 limit, stable IDs, determinism), `notification_prefs_test` (5), `weekly_summary_test` (6, synthetic weeks). App: `notification_scheduler_test` (6, incl. **idempotency**: re-planning twice makes no platform call), `notification_coordinator_test` (4: first run, settings change, new day, permission once), `notification_links_test` (4: **every type's deep link opens its screen or sheet through the router**, launch tap and running tap, unknown links ignored), `notification_settings_screen_test` (1), `notification_bootstrap_test` (1), `nt025_copy_test` (1), `weekly_summary_test` (2: card with the check-in inside, past weeks); router test rows; Progress and Me goldens regenerated.

**Local checks.** Single files via `timeout 600 tools/scripts/heavy.sh` (all green): the new tests above, `app_router_test`, `progress_screen_test`, `adaptive_cards_test`, export tests, `startup_test`, `app_tabs_test`, `settings_test`, `settings_screens_test`, `me_screen_test`, `today_screen_test`, `today_navigation_test`, `app_shell_test`, `weight_graph_navigation_test`, the bootstrap tests, `sf020_copy_test`, fb_domain structure/determinism/dependencies; `make check-dart` ✓ (format, analyze, app-check, frozen migrations); `make gen-app` no diff; `apk-hardening-selftest.sh` ✓ (28 cases); `build-android-selftest.sh` ✓. No Android build locally (owner rule): the merge run's CI builds it.

**Review round 1** (Codex, CHANGES-REQUIRED: 4 major, 4 minor; all fixed, 2026-10-31; domain 6ba8f5d9, app 0992aa1b, after merging origin/main with A34 + A35 in 3cd8d9fa):
- (1, major) Profile isolation: inputs carry the profile generation and a profile tag (FNV hash of the profile key); payloads are `v1|<tag>|<minute>|<hash>|<location>`. Every account transition (sign-in, sign-out, account deletion into a fresh guest: all bump the generation in `OpenProfileHost.activate`) drops the old inputs, stops runs in flight from scheduling (`isCurrent`), then purges every notification of the app, scheduled and shown (`cancelAll` of the plugin), and the ledger, before the new profile's inputs plan. Taps of another profile's notification are ignored. Tests: switch with a new key, a run held on a delayed platform call during a switch, unreadable replacement inputs (nothing scheduled), other-profile payload ignored.
- (2, major) Due alarms: a pending notification whose time has passed stays only while it still applies today (`NotificationPlanner.applyingToday`: switches, skip rules, quiet hours, no cap); one that stopped applying (second meal, resolved card, type or master off) or a prior day's is cancelled and leaves the ledger; `cancelAll` cancels due ones too. Not fixable from Dart: the plugin's boot receiver fires alarms whose time passed during a reboot right away, before the app re-plans (backlog #251).
- (3, major) `AppRouter.openLocation` asks the target tab's screen with unsaved edits first (`UnsavedEdits.confirm` on that branch's navigator, now keyed): the food form's discard sheet (keep editing cancels the link), the workout log's visit exit (edits saved, visit finished). Tests for both.
- (4, major) `WeeklySummaryScreen` is stateless and route-driven: ‹ › go to the neighbour week's location, so a link always shows its week, also to an open screen after browsing. Test: open, browse with ›, the same link again.
- (5) Allow after a permanent denial (or on Android ≤ 12) opens the app's notification settings (`openAppNotificationSettings`), then re-reads the permission. Test.
- (6) The pending-card delay is added to the creation instant (`NotificationState.pendingDue`), the candidate carries the exact instant; DST tests for both occurrences of the fall-back overlap and spring forward.
- (7) The summary's first week is the earlier of the charts' first data date and the first logged workout (`summaryEarliestDateProvider`; `allWorkoutSessionsProvider` now in the workouts barrel). Test.
- (8) Last week's (the NT-004 link) and this week's summary screens show this week's check-in. Test.

**Review round 2** (Codex fix-check: 3, 4, 5, 7, 8 confirmed; 1 and 6 open plus one new major; all fixed, 2026-10-31; domain bd7a3e2d, app 8db3f452):
- (1, major) Durable ownership: the device store keeps the owner tag (`fb.notifications.owner.v1`, a hash, never the key) of the profile whose notifications may be on the phone; a purge clears it and it is written only after the purge succeeded. Every start (before the launch tap is opened) and every run claims the phone for the open profile: another owner means purge first (scheduled and shown). A crash between a switch and its purge is therefore finished at the next start. A due alarm is kept only if its payload carries the open profile's tag. Tests: crash between switch and purge then a restart (old notifications gone, owner updated, only new tags scheduled); a foreign due alarm with an applying ID is cancelled; `claim`.
- (new major) Workout links: a link to the current location does nothing (the live visit stays); workout log and session screens are keyed to their location, so a link to another visit runs the open visit's exit and builds a fresh screen and controller. Test: the same link keeps the live state with no exit run; another visit's link finishes the first (its Undo) and opens a fresh, editable screen.
- (6) The planner compares exact-instant candidates with `nowUtc`. Test: created at the first 02:45 (Berlin fall-back), due at the second 02:15, kept while in the future, dropped after.
- (#251, boot replay) Kept in the backlog, deliberately not filtered natively: the plugin's boot receiver restores every reminder after a reboot, and only those whose time passed during the reboot fire at once (late, never another profile's after a completed purge). Filtering would mean app code in the plugin's package against its private cache format; removing the receiver would lose every reminder after a reboot until the app is opened. The owner can say if late reminders after a reboot bother him.

**Open items.** Backlog #243–#251; #230 retargeted (not in A39a); #235 still waits for a drift migration. Owner: a week with the defaults (#249).

