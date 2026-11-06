# Fitness Buddy: full screen audit (main c520ea35, 2026-11-06)

Read-only audit: code, ARB and the 27 goldens. Nothing was run. The goldens use the Ahem test font, so they show layout only (light/dark at 1.0 and 2.0), not the actual look. Paths are relative to `apps/mobile/lib/`.

## Summary (5 lines)
1. The base is solid after A57/A63/A64. I found no hard-coded colours or fonts and no left/right-only layout. All copy is in ARB with no moral food words, and every screen has designed loading, empty and error states. Verdict: **approve with findings**, no blockers.
2. The weakest areas are the less-visited pages. Me's subpages use three different list styles: grouped cards, flat full-width rows, and a mix of both. Loading and error states also come in about five different forms.
3. Two daily-use gaps. The weight graph has no "Log weigh-in" button and no list of entries, so the only way to fix a wrong weigh-in is to tap a chart point. Targets, Your foods, Saved meals and Meal times are 3 taps from Today, against UX-013's limit of 2.
4. One safety gap. "Sign out → Remove from this phone" is a single tap with no confirmation and no warning about changes that haven't synced yet, while its copy says the data is safe on the server.
5. Smaller polish: copy that names screens which no longer exist ("in Settings"), a "Help & about" page with no help in it, exercise names that briefly show "Removed exercise" while the library loads, half-filled sheets lost on swipe-down, three styles of action menu, and no goldens for about 15 screens.

**Counts:** blocker 0 · major 4 · minor 19 · nit 10

## Screens and verdicts
| Screen / sheet | File | Verdict |
|---|---|---|
| App shell (4 tabs) | app/shell/app_shell.dart | OK |
| Today (day pager, numbers, glance line, quick add, input bar) | features/today/presentation/today_screen.dart, day_page.dart, today_numbers.dart | OK |
| Today day menu (option sheet) | today_screen.dart:191 | OK |
| Progress | features/progress/presentation/progress_screen.dart | OK |
| Weekly summary | progress/presentation/weekly_summary_screen.dart | OK (nit N10) |
| Weight graph | progress/presentation/weight_graph_screen.dart | **needs work** (M3) |
| Past weigh-ins (batch add) | body/presentation/weight_history_screen.dart | OK |
| Measurements | progress/presentation/measurements_screen.dart | **needs work** (m14, m10) |
| Measurement type graph | progress/presentation/measurement_type_screen.dart | OK (m9) |
| Exercises list (Progress / Workouts) | workouts/presentation/exercise_picker_screen.dart | OK |
| Exercise page | workouts/presentation/exercise_screen.dart | OK |
| Workouts tab | workouts/presentation/workouts_screen.dart | needs work (m7) |
| Workout log / session | workouts/presentation/workout_log_screen.dart (+ exercise_log_card, set_row) | needs work (m7) |
| Workout history | workouts/presentation/workout_history_screen.dart | OK |
| Weekly plan ("Your plan") | workouts/presentation/weekly_plan_screen.dart | **needs work** (m5, m18, N4) |
| Starter plans | workouts/presentation/starter_plans_screen.dart | needs work (m7, N5) |
| Plan setup | workouts/presentation/plan_setup_screen.dart | OK |
| Template editor | workouts/presentation/template_editor_screen.dart | OK |
| Custom exercise | workouts/presentation/custom_exercise_screen.dart | OK |
| Me | me/presentation/me_screen.dart | **needs work** (M2) |
| Me › Targets & goal | me/presentation/me_pages.dart:20 | **needs work** (M2) |
| Me › Food & meals | me_pages.dart:63 | **needs work** (M2) |
| Me › Workouts | me_pages.dart:92 | needs work (m6) |
| Me › Preferences (+ units/theme/week/food-names option sheets) | me_pages.dart:147, settings/presentation/settings_section.dart, food_names_setting_row.dart | OK (m15) |
| Me › Account & data | me_pages.dart:185, account/presentation/account_section.dart | **needs work** (M1, m11) |
| Account name sheet | account_section.dart:180 | needs work (m11) |
| Sign-out sheet | account/presentation/sign_out_sheet.dart | **needs work** (M1) |
| Sync sheet | sync/presentation/sync_sheet.dart | needs work (m16) |
| Earlier versions sheet | sync/presentation/earlier_versions_sheet.dart | OK |
| Export sheet | settings/presentation/export_sheet.dart | OK |
| Delete account / local data | account/presentation/delete_account_screen.dart | needs work (m12) |
| Sign-in (email, code, Google, conflict) | account/presentation/sign_in_screen.dart | OK (N2) |
| Welcome | onboarding/presentation/welcome_screen.dart | needs work (m2) |
| Setup / first-run questions (goal, you, activity, training, plan, account) | onboarding/presentation/setup_screen.dart, pages/* | OK (N1, N2) |
| Targets | targets/presentation/targets_screen.dart | OK (N3) |
| Targets sheets: day target, How, More options, macro, manual target, below-limit | targets/presentation/*_sheet.dart, below_limit_screen.dart | OK (m8 for macro/manual) |
| Profile & goal (+ profile edit, goal, rename phase, past goals) | targets/presentation/profile_goal_screen.dart, goal_sheet.dart, profile_edit_sheet.dart, phase_history.dart | **needs work** (M4) |
| Notifications | notifications/presentation/notification_settings_screen.dart | **needs work** (M4, m4) |
| Ramadan | ramadan/presentation/ramadan_screen.dart | **needs work** (M4, m1, N8) |
| Meal times / Ramadan meal times (+ slot edit, slot remove) | diary/presentation/slots/meal_slots_screen.dart, slot_edit_sheet.dart, slot_remove_sheet.dart | OK (m10) |
| City picker (screen + sheet) | settings/presentation/city_picker_screen.dart, city_pick_sheet.dart, city_search_list.dart | OK (backlog #119) |
| About (+ licences, hidden test-report sheet) | settings/presentation/about_screen.dart | **needs work** (m3, M4) |
| Your foods | foods/presentation/personal_foods/personal_foods_screen.dart | needs work (m13) |
| Personal food form (+ merge sheet) | personal_food_form_screen.dart, merge_food_sheet.dart | OK |
| Saved meals | diary/presentation/saved_meals/saved_meals_screen.dart | needs work (m13) |
| Saved meal (+ rename sheet, ⋯ menu) | saved_meal_screen.dart, rename_saved_meal_sheet.dart | needs work (m9) |
| Food search | foods/presentation/food_search_screen.dart | OK |
| Food sheet | foods/presentation/food_sheet.dart | OK |
| Barcode scan (+ "add it yourself") | foods/presentation/barcode/barcode_scan_screen.dart | OK |
| Entry details / amount / move / copy / save-as-meal / meal menu | diary/presentation/entry_details.dart, entry_amount_sheet.dart, move_entry_sheet.dart, move_to_slot_sheet.dart, copy_meal_sheet.dart, save_meal_sheet.dart, meal_menu.dart | OK |
| Nutrient override sheet | diary/presentation/nutrient_override_sheet.dart | needs work (m8) |
| Estimate popup + sheet (meal and day) | diary/presentation/estimate_sheet.dart, day_estimate_rows.dart | needs work (m8, m9) |
| Weigh-in sheet | body/presentation/weigh_in_sheet.dart | OK |
| Measurement sheet, custom type sheet | body/presentation/measurement_sheet.dart, custom_type_sheet.dart | needs work (m8) |
| Discard-changes sheets | core/ui/discard_changes_sheet.dart, body/presentation/weight_history_discard_sheet.dart | OK |
| Buddy sheet + food picker | buddy/presentation/buddy_sheet.dart, cards/food_picker_sheet.dart | OK |
| Update required | app/update/update_required_screen.dart | needs work (m17) |
| Design preview | design_preview/* | OK (dev flavor only; Developer group hidden in prod) |

## Findings

### Blockers
None.

### Major

**M1. "Sign out → Remove from this phone" can silently lose unsynced changes.** account/presentation/account_section.dart:286-291, sign_out_sheet.dart:9-21, ARB `accountSignOutRemoveDetail` ("Your account data stays safe on the server."). Picking the option signs out at once: there's no confirmation, and `AccountTransitions.signOut(keep:false)` (core/account/account_transitions.dart:264) drops the profile however many changes are still waiting to sync. The copy promises the data is safe, but changes made offline aren't on the server yet. This breaks UX-030 (destructive actions need confirmation) and UX-052 (nothing typed is lost).
*Fix:* read `syncViewProvider` in the sheet. With pending > 0, run Sync now first. If changes are still pending, show a second step: "3 changes haven't synced and will be lost. Sync first / Remove anyway". Always confirm Remove, and make the copy honest: "Synced data stays on the server." **M**

**M2. Key settings are 3 taps from Today (UX-013 says at most 2).** me/presentation/me_screen.dart:78 and :213, me_pages.dart:20-60 and 63-80. The Me summary card and the "Targets & goal" row open a pass-through page with only two rows (Targets, Profile & goal). "Food & meals" likewise holds 3 links and a switch. So Targets, Profile & goal, Your foods, Saved meals and Meal times each take Me → group → screen, and the calories card on Today doesn't open Targets either.
*Fix:* point the summary card straight at `TargetsRoute`, and put the Targets and Profile & goal rows in Me's "Your plan" group (drop the 2-row page). Make Your foods, Saved meals and Meal times direct rows in a "Food" group, or open Your foods / Saved meals from food search. Optionally, a tap on Today's calories number opens Targets. **S–M**

**M3. The weight graph has no "Log weigh-in" button and no list of weigh-ins.** progress/presentation/weight_graph_screen.dart:52-101 (the Log button exists only in the empty state at :76) and :61 (app-bar icon `FbIcons.diary`, a book, means "Add past weigh-ins"). Once data exists, the only way to edit or delete a wrong weigh-in is to hit a small point on the chart, then Edit (:308). The sibling Measurement type screen has a pinned "Add measurement" button (measurement_type_screen.dart:83-101) and an "Entries" list with edit and delete (:362-374). These are similar screens that behave differently, a small-target problem (UX-071), and there's no easy fix for a typo.
*Fix:* reuse the measurement pattern: a pinned primary "Log weigh-in", and an "Entries" section under the summary (date, value, "not used for trend" marker, tap → edit sheet with Delete). Replace the book icon with a labelled "Add past weigh-ins" row in the list or an overflow menu. **M**

**M4. Me's subpages use three list styles, so the less-visited pages look older.** Me, the Me subpages (me_parts.dart `MeGroup`), Targets and Workouts use grouped `FbCard`s with section headers. Notifications (notification_settings_screen.dart:56-103), Ramadan (ramadan_screen.dart:29-55, 155-228, 272-340), About (about_screen.dart:32-149) and Profile & goal (profile_goal_screen.dart:68-111) use flat, full-width ListTiles straight on the background. Profile & goal even mixes flat rows with one card. Side by side in the Me tab this reads as two design generations (UX-041/043, the owner's A55 review).
*Fix:* use one "settings page" layout for every Me destination: `MePage` + `MeGroup` (section header + rows in one card, the same insets as Me), with notes as the quiet line under a group. Apply it to Notifications, Ramadan, About and Profile & goal. Lists of user content (Your foods, Saved meals, Measurements, Meal times) can stay flat but should share one list inset. Add goldens for each (see m19). **M**

### Minor

**m1. Copy names a "Settings" screen that no longer exists.** ARB `ramadanNotNowDone` (app_en.arb:7154): "You can switch Ramadan mode on in Settings". *Fix:* "…in Me › Ramadan". Also grep the Patrol tests per the copy rule. **S**

**m2. Welcome benefit with a mismatched line.** ARB `welcomeWorkoutsBody` (app_en.arb:2103) is "Your data stays on your phone", under the title "Workouts with or without a plan". *Fix:* "Log after the gym, or follow a weekly plan". If the privacy line is wanted, make it a separate fourth benefit. **S**

**m3. "Help & about" has no help, and About shows developer diagnostics.** me_screen.dart:133-137 → about_screen.dart. There's no help content: nothing on how logging works and no badge legend, though UX-010 lists "help" and UX-044 wants a legend. About also shows the barcode hit-rate counter (:139-148, a TD-064 metric) and a 5-line ML Kit paragraph (:129-137) right in the main column. *Fix:* add a short "How it works" section (source badges ⓨ/db/ref/~ with one line each, Undo, estimates) and a feedback or contact row. Move the barcode counter behind the dev flavor or the version long-press, and fold the ML Kit text into a "Privacy" row that opens a sheet. **S–M**

**m4. The Notifications screen needs a tidy-up.** notification_settings_screen.dart:72-101, 98, 216-220, ARB `notifMaster` / `notifSectionTypes` (both "Reminders"). (a) The master switch and the section header have the same label. (b) Suhoor and Iftar reminders show all year, even with Ramadan mode off or no city. (c) The Time and Day rows sit at the same level as the switches, so they don't read as belonging to the reminder above. *Fix:* call the master switch "All reminders". Show the Ramadan pair only while a Ramadan season is on, or with a note "Ramadan only · set a city" linking to Me › Ramadan. Indent the detail rows or group each reminder in its own card (with M4). **S**

**m5. One screen, three names.** The Me row says "Weekly plan" (`workoutPlanTitle`, me_pages.dart:117), the screen title says "Your plan" (weekly_plan_screen.dart:54, 68), and the Workouts tab row says "Your plan". *Fix:* use one name everywhere ("Weekly plan"). **S**

**m6. Me › Workouts leaves the Me tab.** me_pages.dart:92-140 (`go: true`). Back doesn't return to Me, and the note "These open in the Workouts tab" is needed to explain it. *Fix:* acceptable as it is. If kept, show a "switches tab" trailing icon instead of ›, or drop the page and keep a single "Workouts" row that jumps to the tab. **S**

**m7. Exercise names flash "Removed exercise" while the library loads.** `ref.watch(exerciseLibraryProvider).value ?? ExerciseLibrary.empty` in workouts_screen.dart:222, weekly_plan_screen.dart:40, starter_plans_screen.dart:74, workout_log_screen.dart:339, template_editor_screen.dart:128, plan_setup_screen.dart:315. With an empty library, `exerciseName` returns `workoutRemovedExercise` (workout_text.dart:35). *Fix:* while the library is loading, show a skeleton line (or nothing) in place of names, and keep "Removed exercise" for real misses. **S**

**m8. Half-filled sheets are lost on swipe-down or a tap outside.** `showFbSheet` / `showFbStatefulSheet` (packages/fb_design_system/lib/src/components/sheet.dart:88-124) have no "dirty" guard. Full screens and the slot editor ask before discarding. The estimate sheets (diary/presentation/estimate_sheet.dart, day_estimate_rows.dart), nutrient override, macro, manual target, measurement and custom-type sheets don't. *Fix:* add an optional `isDirty` callback to the sheet helpers (PopScope + `showDiscardChangesSheet`), and use it in sheets with more than one field. **M**

**m9. Action menus come in three styles.** Rows with icons (meal_menu.dart:23-40, workout_log_screen.dart:254-275); a selection list used for actions (measurement_type_screen.dart:113-125, `FbOptionList`); stacked secondary buttons (estimate_sheet.dart:42-80, day_estimate_rows.dart:236-280); and a one-row, untitled ⋯ menu on Saved meal (saved_meal_screen.dart, `_openMenu`; backlog #106). *Fix:* add one `showFbActionSheet` (title, rows with a leading icon, destructive row last in the error tone) and use it everywhere. Make Saved meal's Delete a direct action. **M**

**m10. Loading and error states take five different forms.** Skeletons: `LoadingRows` (personal_foods_screen.dart:289, weekly_plan_screen.dart:63), `FbSkeleton.row` (notification_settings_screen.dart:37, ramadan_screen.dart:50), `FbSkeleton.line(height: 56)` (measurements_screen.dart:78, saved_meals_screen.dart:61, saved_meal_screen.dart:224), `line(height: 40)` (meal_slots_screen.dart:69). Errors: `LoadFailedView` (me_pages, notifications, workouts), an inline error banner (targets, ramadan, meal times, foods), `FbEmptyState` with retry (measurements, weight graph), and plain text (ramadan_screen.dart:34-37). *Fix:* use `LoadingRows` / `FbSkeleton.row` for every list page and `LoadFailedView` for every whole-page failure, plus a shared `commonTryAgain` string (see N6). **S–M**

**m11. Account & data details.** account_section.dart:180-235: the Name sheet accepts an unchanged or empty value, gives no success feedback, and has no Undo. :265-293: Name has a leading icon, but Sync and Sign out don't. *Fix:* disable Save until the name changes, show a snackbar "Name saved", and give every row in the group an icon (or none). **S**

**m12. Destructive actions look like ordinary primary buttons.** delete_account_screen.dart:113-120 ("Delete") and :160-165 ("Yes, delete") use `FbButton.primary` in brand ink. While deleting, the page shows a free-standing `CircularProgressIndicator` (:86) instead of the button's busy state (sign-in already uses `busy:`). *Fix:* add an `FbButton.destructive` (muted brick, or error-container fill and text) for irreversible actions, and use `busy:` on the button. **S–M**

**m13. Your foods and Saved meals can't be searched.** personal_foods_screen.dart:268-279, saved_meals_screen.dart:356-367. These lists grow from barcode scans and labels (owner decision 2026-10-31), so a long A–Z scroll is the only option. *Fix:* put an `FbSearchField` at the top once there are more than about 8 items, filtering by both names. Optionally, sort Your foods by last used. **M**

**m14. Measurements lists all 7 standard types even when unused.** measurements_screen.dart:42-62. A user who tracks only waist and body fat sees five "No entries yet" rows. *Fix:* tracked types first; the others under a collapsed "More measurements" row or in the Add sheet only. **S**

**m15. The Imperial hint over-promises.** ARB `settingsUnitsImperialHint` (app_en.arb:4331) says "Ounces, fluid ounces, pounds", but workouts are always kg (spec WO-012), so the setting seems not to take effect in Workouts. *Fix:* "Ounces, fluid ounces, pounds · workouts stay in kg". **S**

**m16. The Sync sheet's controls are off-pattern.** sync_sheet.dart:20-70: pull-to-refresh inside a bottom sheet (it competes with drag-to-dismiss and can't be discovered), a `LinearProgressIndicator` under the button, and the parked-changes "Try again" left-aligned under a row. *Fix:* drop the `RefreshIndicator`, use `FbButton.primary(busy: view.running)`, and turn parked changes into an `FbInlineBanner` with a Try again action. **S**

**m17. Update required screen** (app/update/update_required_screen.dart:52) says "Install the latest one" but not where to get it (backlog #36). *Fix:* add one line pointing to the install runbook or the CI artifact page, or "Ask Abdelrahman for the new build" in R2. **S**

**m18. Rows with a button at the end squeeze their title at large text.** `FbListRow` is a bare ListTile (packages/fb_design_system/lib/src/components/list_row.dart:31-37). Rows that end in a button: Weekly plan's template "Log" (weekly_plan_screen.dart:96-101), Ramadan city "Try again" (ramadan_screen.dart:286-292), Recent workouts "Repeat" (workouts_screen.dart:146-152, inside `WorkoutSessionTile`). At text scale 2.0 the title gets squeezed. None of these have goldens, so it's unverified. *Fix:* give `FbListRow` a `trailingAction` slot that moves under the text when the text scale is above 1.3 (as `_Actions` in workouts_screen.dart does). **M**

**m19. About 15 screens have no goldens.** 27 goldens exist. Missing: Notifications, Ramadan, Meal times, Your foods, Saved meals, Saved meal, Measurements, Measurement type, Past weigh-ins, Weekly plan, Starter plans, Workout log, Delete account, Update required, Sync and Export sheets. Dark mode and text scale 2.0 are unproven there (UX-070/071). *Fix:* add light/dark × 1.0/2.0 goldens per screen family, together with M4. **M**

### Nits
- **N1.** Hard-coded sizes outside tokens: account_section.dart:84 (spacing 2), :111 and :122 (44), :340; onboarding/presentation/pages/page_parts.dart:105-113 (36, 20, 2); plan_page.dart:173 (6). → Avatar and icon-tile size tokens. **S**
- **N2.** Raw `IconButton` instead of `FbIconButton`: sign_in_screen.dart:114, setup_screen.dart:81, 304, 503, slot_header_row.dart:76, 115. **S**
- **N3.** The "Set up targets" empty state uses the person icon (`FbIcons.me`): targets_screen.dart:38, profile_goal_screen.dart:233 → `FbIcons.target`. The Measurements row on Progress uses `FbIcons.progress` (progress_screen.dart:128); a ruler-style icon would read better. **S**
- **N4.** Weekly plan day rows use ⌄ (`FbIcons.expand`, weekly_plan_screen.dart:80) to open an option sheet; everywhere else uses ›. **S**
- **N5.** The starter-plan tag is a hand-made `Container` chip (starter_plans_screen.dart:110-127); use a design-system chip or badge. **S**
- **N6.** Strings borrowed across features: Ramadan uses `mealTimesTryAgain` (ramadan_screen.dart:43), Progress uses `weightGraphTryAgain` (progress_screen.dart:108), Account uses `foodTryAgain`. Use a shared `commonTryAgain`. **S**
- **N7.** Sheets pad by s5 while pages pad by s4, and `FbListRow` inside a sheet (MoreOptionsSheet, the menus) adds its own inset, so sheet rows sit further in than page rows. **S**
- **N8.** Ramadan's "dates not available for this year" is plain body text (ramadan_screen.dart:34-37), not an empty state. **S**
- **N9.** `weekdayName` exists three times (targets_screen.dart:393, weekly_plan_screen.dart:20, core/l10n/day_label.dart), and the fallback week start `DayOfWeek.saturday` is repeated in five files instead of `AppSettings.weekStart.defaultValue`. **S**
- **N10.** Weekly summary changes weeks only with ‹ ›; Today changes days by swipe. A horizontal swipe would match. **S**

## Top 10 fixes for a daily user
1. **M1** Safe sign-out: warn and sync first when changes are pending, and confirm Remove. (M)
2. **M3** Weight graph: pinned "Log weigh-in" plus an Entries list with edit and delete. (M)
3. **M2** At most 2 taps: Me summary card → Targets; Targets, Profile, Your foods, Saved meals and Meal times as direct Me rows. (S–M)
4. **m8** Ask before discarding a half-filled sheet (estimate, override, measurement, targets). (M)
5. **m13** Search in Your foods and Saved meals. (M)
6. **M4 + m19** One grouped-card layout for Notifications, Ramadan, About and Profile & goal, with goldens. (M)
7. **m7** No "Removed exercise" flash while the exercise library loads. (S)
8. **m4** Notifications tidy-up: "All reminders", Ramadan reminders only in season, nested time rows. (S)
9. Copy batch: **m1, m2, m5, m15, m3** (remove "in Settings", fix the welcome line, one plan name, the kg note, a real Help section). (S)
10. **m9 + m10** One action-sheet component and one loading and error pattern. (M)

## Worth showing the owner on the A55
- Me tab, then Targets & goal, then Targets: the extra tap (M2).
- Progress, then weight card, then the graph: no way to log, and fixing a weigh-in means tapping a chart point (M3).
- Me › Preferences next to Me › Notifications and Me › Ramadan: the two list styles (M4).
- Me › Account & data, then Sign out: one tap to "Remove from this phone" (M1; try it only on a test account).
