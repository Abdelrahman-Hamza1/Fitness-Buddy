# A65 — Screen audit fixes: safe sign-out, weigh-in list, one settings layout

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A64 | L (one engineer session) | Claude builds (one Opus `flutter-engineer`), Codex review | ✅ merged with backlog sweep 3 (Codex review: 1 major + 4 minors fixed, fix-check PASS) |

_2026-11-06. Fixes the full screen audit `evidence/A65-screen-audit.md` (main c520ea35, 0 blocker · 4 major · 19 minor · 10 nits) plus four backlog rows the orchestrator added (#165, #263, #283, #289). Tier **Risky** for M1 (sign-out drops a profile), Normal for the rest._

**Goal.** The daily-use gaps and the safety gap from the audit are gone: "Remove from this phone" never silently drops unsynced changes, a wrong weigh-in is fixed from a list, and every Me page reads as one design with one loading and error pattern. The minors and the cheap nits are fixed; the rest are logged.

## Scope
- Every finding of the audit (`evidence/A65-screen-audit.md`) **except M2** (the "at most 2 taps" Me restructure): the owner decided on 2026-11-06 that it's a non-issue, so Me → Targets & goal / Food & meals stays as it is.
- Backlog rows added by the orchestrator: #165 (weight graph UX pass, overlaps M3), #263 (snackbars on route change), #283 (focus after a reveal), #289 (Adaptive mode row in Me › Targets & goal, owner-approved).

## Out of scope
- M2 (owner, 2026-11-06).
- `steps/backlog.md` and the board (the orchestrator updates them; new rows are listed below).

## Progress log
- 2026-11-06: audit committed (6e55a8ff). Engineer started on `step/A65-screen-audit-fixes` from c520ea35. (flutter-engineer)
- 2026-11-06: M1 + m11/m12/m16 committed (f9fde723): sign-out confirmation step with sync-first and the unsynced count, `FbButton.destructive`, delete screen busy button, name sheet, sync sheet. (flutter-engineer)
- 2026-11-06: M3 committed (822bee1a): weight graph pinned Log weigh-in and the Entries list. (flutter-engineer)
- 2026-11-06: building blocks (dfa9c1f8), M4 group (590a9daa), the remaining minors and nits (223d901e), goldens (929ca83d). `make check-dart` green before every commit; `make gen-app` leaves no diff. No local test runs (owner rule) except the golden regeneration of the six golden files touched. Sweep branch (`chore/backlog-sweep-3-app`) not final yet: no rebase done. (flutter-engineer)
- 2026-11-06: Codex review fixes. #1 (major) c255e827: "Remove from this phone" holds writes (synchronous denial + quiesce) before the final unsynced-count check and through the server logout and the removal; bound to the confirmed profile; more changes than confirmed stop it and the step asks again (with #2 caller-gone → nothing, #3 error-reporting live count, same files). #4/#5 next commit: weigh-in delete failures split removed/changed/failed; real swipe + Undo + swipe tests; dirty estimate and macro sheets tested through Back, outside tap, Keep editing, Discard and Save. `make check-dart` green; no local test runs. (flutter-engineer)

## Outcome

_Claude, 2026-11-06. One Opus `flutter-engineer`, 6 local commits, not pushed. CI has not run yet: the merge run will be the first test evidence._

| Finding | Fixed / logged | Commit |
|---|---|---|
| M1 safe sign-out | Fixed: "Remove from this phone" opens a confirmation step; with changes waiting it syncs first; still waiting (offline, expired session, failure) it says "N changes haven't synced yet and will be lost", with Sync now / Remove anyway / Cancel; an unreadable count warns too. Honest copy "Synced data stays on the server. Changes that haven't synced are lost." | f9fde723 |
| M2 2-tap Me | Not done (owner: non-issue) | — |
| M3 weigh-in log + list | Fixed: pinned "Log weigh-in", Entries list (newest first, "not used for the trend" marker, tap → edit sheet with Delete, swipe → delete with Undo, 30 at a time), the book icon became a labelled "Add past weigh-ins" row | 822bee1a |
| M4 one settings layout | Fixed: `FbRowGroup` + `SettingsPage` (Me's `MeGroup`/`MePage` are now aliases); Notifications, Ramadan, About and Profile & goal use it | dfa9c1f8, 590a9daa |
| m1 "in Settings" | Fixed ("in Me › Ramadan"); no other value names Settings | 223d901e |
| m2 welcome line | Fixed ("Log after the gym, or follow a weekly plan") | 223d901e |
| m3 Help & about | Fixed: "How it works" (source legend, Undo, estimates); ML Kit text behind a Privacy row; barcode counter kept visible as a quiet bottom row (TD-064 is the owner's metric, so not hidden behind dev). Feedback/contact row logged (no channel decided) | 590a9daa |
| m4 Notifications | Fixed: "All reminders"; one card per reminder with its time/day; Suhoor/Iftar apart under a "Ramadan only, needs Ramadan mode and a city" note (the switches stay; conservative over hiding them) | 590a9daa |
| m5 one plan name | Fixed: the screen title is "Weekly plan" (WO-021), inner section "Days". The Workouts tab row keeps "Your plan" because spec D-089 names it so (spec wins) | 223d901e |
| m6 Me › Workouts | Fixed: rows end in an "other tab" arrow (`FbIcons.otherTab`) | 590a9daa |
| m7 "Removed exercise" flash | Fixed: blank name while the library loads (`ExerciseLibrary.empty`), "Removed exercise" only for real misses | 223d901e |
| m8 dirty sheets | Fixed for the multi-field sheets (meal estimate, macro targets): `SheetDiscardGuard` + `enableDrag: false` (Flutter's drag-dismiss pops past `PopScope`, so guarded sheets hide the handle; tap outside and Back ask). Single-field sheets (day estimate, nutrient override, manual target, measurement, custom type) left as they are, per the audit's "more than one field" | dfa9c1f8, 223d901e |
| m9 action menus | Fixed: `showFbActionSheet` (icon rows, destructive last in error tone) for the meal, workout, measurement-type and both estimate menus; Saved meal's Delete is a direct app-bar action with Undo (#106) | dfa9c1f8, 223d901e |
| m10 loading/error | Fixed: `LoadingRows` for list pages (measurements, saved meals, saved meal, meal times, notifications, ramadan), `LoadFailedView` for whole-page failures (weight graph, measurements, measurement type, ramadan, profile & goal) | 590a9daa, 223d901e |
| m11 Account & data | Fixed: Save off until the name changes, "Name saved" snackbar, icons on Sync / Sign out / Continue as guest. No Undo for the name: it is phone-only identity metadata outside the change sets (TD-115) | f9fde723 |
| m12 destructive buttons | Fixed: `FbButton.destructive` (errorContainer fill, error text: an AA pair in the palette checks); delete screen uses `busy:` instead of a free spinner | f9fde723 |
| m13 list search | Fixed: search field past 8 items in Your foods (English + Arabic names) and Saved meals (meal + its foods' names), search folding via `fb_text` `normalizeKey`. "Sort Your foods by last used" logged | 223d901e |
| m14 Measurements | Fixed: types in use (and custom types) first, unused standard types under "More measurements" | 223d901e |
| m15 Imperial hint | Fixed ("· workouts stay in kg") | 223d901e |
| m16 Sync sheet | Fixed: no pull-to-refresh, Sync now busy while running, parked changes as a banner with Try again | f9fde723 |
| m17 Update required | Fixed for R1 ("Install the latest build, the same way you installed this one"); the R2 wording stays backlog #36 | 223d901e |
| m18 squeezed rows | Fixed: `FbListRow.trailingAction` moves the button under the text from scale 1.3 (weekly plan Log, Ramadan city Try again, Repeat) | dfa9c1f8, 223d901e |
| m19 missing goldens | Partly: new Notifications and Ramadan goldens; the other ~13 screens logged (TD-104 keeps goldens lean) | 929ca83d |
| N1 hard-coded sizes | Fixed: `FbSize` tokens (avatar, icon tile, small icon, line gap), macro bar height token | dfa9c1f8, 223d901e |
| N2 raw IconButton | Fixed: `FbIconButton` in sign-in, setup, slot header | 223d901e |
| N3 icons | Fixed: target icon for "Set up targets", ruler icon for Measurements | 590a9daa |
| N4 plan day chevron | Fixed (›) | 223d901e |
| N5 tag chip | Fixed: `FbTag` | dfa9c1f8, 223d901e |
| N6 borrowed strings | Fixed: `commonTryAgain` across features (`commonCancel` added) | f9fde723, 590a9daa |
| N7 sheet insets | Partly: action-sheet rows align with the sheet title; other sheet rows logged | dfa9c1f8 |
| N8 Ramadan outside table | Fixed: an empty state | 590a9daa |
| N9 weekday helpers | Fixed: one `weekdayNameIn`; week-start fallback is `AppSettings.weekStart.defaultValue` | 223d901e |
| N10 weekly summary swipe | Logged (gesture next to the charts needs a device check) | — |
| #165 weight graph UX pass | Partly: M3 (pinned action, labelled history row, entries); the rest of the review pass stays open | 822bee1a |
| #263 snackbars on route change | Not changed: the reported snackbar ("Weigh-in saved") carries Undo, and clearing it on navigation would break UX-030. Logged: lift bottom-pinned actions above the snackbar instead | — |
| #283 focus after reveal | Logged (needs a TalkBack check on the phone) | — |
| #289 Adaptive mode row | Fixed: Me › Targets & goal › "Adaptive mode" with the current mode, opens Progress (Expenditure). It lands on the Progress tab top; scrolling to the card logged | 590a9daa |

**Tests added** (no local runs; CI is the evidence): `sign_out_sheet_test.dart` (A65 M1 ×5, AC-004 keep), delete screen busy (m12), sync sheet (m16 ×2), weight graph (A65 M3 ×4), measurements (m14), `workout_text_test.dart` (m7 ×2), `name_filter_test.dart` (m13 ×3), Me (#289 + m6), notifications (m4), ramadan (N8), About (m3), DS `a65_components_test.dart` (m12, M4 group, m18, m9, m8 handle, N5). Updated: saved meal delete (direct action), sync sheet (no RefreshIndicator).

**Goldens**: new `notification_settings`, `ramadan_outside_table`; regenerated and viewed `account_data_signedIn`, `about`, `weight_graph_ranges`, `first_run_welcome`, `workouts_tab`.

**Deviations**
- m5: spec D-089 names the Workouts tab row "Your plan"; only the screen title changed.
- m8: guarded sheets lose swipe-to-close (Flutter's drag-dismiss ignores `PopScope`); they hide the drag handle.
- m3: the barcode counter stays visible (TD-064 owner metric).
- New goldens are only two (TD-104 lean goldens vs the audit's m19).

**New backlog rows** (for the orchestrator to add)
1. A65 m3: About feedback/contact row once a channel is decided (R2).
2. A65 m13: sort Your foods by last used.
3. A65 m19: goldens for Meal times, Your foods (long list), Saved meals, Saved meal, Measurements, Measurement type, Past weigh-ins, Weekly plan, Starter plans, Workout log, Delete account, Update required, Sync and Export sheets.
4. A65 N7: sheet rows (MoreOptionsSheet, option lists) sit further in than the sheet title.
5. A65 N10: weekly summary week change by swipe.
6. A65 #263: lift bottom-pinned actions above a shown snackbar instead of clearing Undo snackbars.
7. A65 #289: open Progress scrolled to the Expenditure card.
8. A65 m8: sheets with one field (day estimate, manual target, measurement, nutrient override, custom type) have no discard guard.
9. #165 and #283 stay open as they are (#165 partly done by M3).
