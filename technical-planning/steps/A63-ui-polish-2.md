# A63 — UI polish 2: visual Progress top, who's signed in, honest settings, sets without ticks

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A57 | L (upper end; split seam in Size check) | Claude plans and builds (one Opus `flutter-engineer`), two Codex reviews (Risky) | ✅ Closed (owner acceptance by use, TD-037) |

_2026-11-06. One combined step from the owner's next-UX review (mockups `~/work/ux-sketches/next-ux-2026-11-06/`: ProgressTop P1 B, MeHeader M1 A + M2, Settings S1 A + S2, WorkoutLog W4 A + W5 A) and the Codex settings audit (`technical-planning/settings-audit-2026-11-06.md`). Tier **Risky** (D1, amended PA4). Runs in lane 3 next to A62 (estimates, lane 2); overlaps are listed in Risks R1._

**Goal.** Progress opens on pictures and numbers, not sentences: the week lives in the calories chart. A new app-wide rule: no card is only text. Me shows who's signed in (a letter circle, the name and the email, kept only on this phone). Settings rows that look changeable always do something, and the audit's broken rows and false states are fixed. Workout sets count as soon as they have numbers: no tick, "Same as last time" per exercise, swipe a set away with Undo.

**Spec:** IN-001, IN-002, WO-034, WO-042, UX-010, UX-030, UX-050–052, UX-070, AC-001, AC-041, TG-034, TG-060, DY-004 · **Adds (draft D-097; A62 has D-096; owner-approved content 2026-11-06):** UX-047, UX-048, AC-005 · **Amends:** IN-001, WO-034, UX-010.

## Scope
- **P1 B** Progress top: the "This week" text card goes; the calories chart card carries the week (header "Calories · avg 1,940 / 2,100", one line "In target 4/5 · Protein 3/5 · −0.4 kg", target marks, dashed future days). Past weeks stay reachable. Check-in, Ramadan targets offer and incomplete-day cards become one-line rows with an icon and one action; the full card opens on tap.
- **Rule "no text-only cards"** (owner): sweep every sentence-only card (list in D8); design_preview is out.
- **M1 A + M2** Me header: letter circle + name + email + sync status, tap → Account & data. Name/email from Google sign-in or the email used; after email sign-in ask once "What should we call you?" (skippable, editable). Guests: "Guest" + person icon. Local only.
- **S1 A** Preferences: Energy and Language rows go; one quiet facts line.
- **S2** the audit's 9 majors and 6 of 7 minors (D18).
- **W4 A** set rows lose the tick; hints don't count; "Same as last time" per exercise; one header row per exercise.
- **W5 A** swipe a set sideways to remove it, with Undo; the set-number menu stays; TalkBack action "Remove set".

## Out of scope
- Estimates on Today, Progress bar striping, food search "~ Estimate" (A62).
- Energy in kJ (LC-012 "Later"), a Google profile photo (M1 B), tick-while-training mode (W4 C).
- design_preview no-op controls and dev-only text cards (backlog, D18).
- A Me/settings entry for adaptive mode (audit note; backlog, D18).

## Fixed by the plan
- Owner picks above are final (2026-11-06). Name and email never leave the phone (AC-041, rule 6).
- No contract change, no sync change, no drift migration (D4, D11).

## Exit criteria
1. Progress has no text-only card at the top; in week mode the calories card shows the week's average vs target and one line of key numbers; future days are dashed; the week's full numbers (IN-001) are one tap away; past weeks reachable.
2. Check-in, Ramadan offer and incomplete-day notices are one-line rows with one action; their proposals still need a confirming tap.
3. Every card in the D8 list leads with a number, picture or action, or is an inline helper.
4. Me shows the letter circle, name, email and sync status for an account, "Guest" for a guest; email sign-in asks for a name once; nothing of it reaches logs, the server, Buddy, sync, export or backup.
5. Preferences has no display-only row; the audit's majors are fixed and each fixed minor has a check (coverage table).
6. A set with valid numbers counts with no tick; hints never count; "Same as last time" fills empty sets; a swipe or the menu removes a set with Undo; stored data and the sync payload are unchanged.
7. `make gen-app` clean, affected goldens regenerated and viewed, Patrol/integration finders updated (WP6 list).

## Read first
- `technical-planning/settings-audit-2026-11-06.md` (the S2 table), the four mockups, `A57-ux-polish.md` (D17 `FbReveal`/`FbSizeFade`, `FbInert`, `LoadFailedView`/`LoadingRows`, layout stability helpers, D20 set-row compact layout), `A50-google-sign-in.md` D6/D9, `spec/15` §4, `spec/16` §2, `spec/20` §1, `spec/30`.

## Owner involvement
- None blocking. D-097 records content the owner approved on 2026-11-06 (rec: ok). Device checklist after merge (optional, D-087).

---

## Low-level plan
_Claude (step planner), 2026-11-06, branch `step/A63-ui-polish-2` from `origin/main` 367182d1. Paths are relative to `apps/mobile/` unless they start with `packages/`, `spec/`, `contracts/` or `technical-planning/`._

### Summary
After A63 the Progress tab starts with zero to three one-line notice rows, then the period bar and a calories card whose header is the week (average vs target, one key line, tap → the week's numbers as tiles). A new DS `FbNoticeRow` replaces sentence-only cards app-wide. Me opens on a letter-circle header fed by a phone-only identity store (name + email, per local profile, in shared preferences). Preferences lists only changeable rows. The workout log treats "has valid numbers" as "done": the tick, `toggleSet` and the stored-nowhere `checked` flag go; "Same as last time" and swipe-to-remove with Undo arrive. Nine audited majors and six minors are fixed. No contract, sync or database change.

### Decisions
- **D1 Tier Risky** (PA4, Codex plan review). WP2 changes which user actions persist workout data (a user-data write path) and WP4 changes the sign-in result and adds persistent identity (sign-in), both Risky under `PROCESS.md` A2. Reviews: two parallel Codex tasks, (a) code/architecture and (b) security/data integrity scoped to the workout form's save semantics (D14/D16), the identity lifecycle (D9–D12) and settings writes (D17/D20); the orchestrator records (b) in `technical-planning/steps/evidence/A63-verification.md`. Still no `ChangeSetApplier`, schema, sync or contract change.
- **D2 P1 B layout.** Progress order: notice rows (D5) → `ProgressPeriodBar` → `CaloriesSection` → macros → weight → Ramadan comparison → goal → Measurements → Exercise progress → Expenditure. `WeeklySummaryCard` is deleted. In **week mode** the calories card's title row becomes `CaloriesWeekHeader` (new file `progress/presentation/calories_week_header.dart`): "Calories" + "avg 1,940 / 2,100" (`FbNumberSlot`s, sample "8,888") + `›`, and under it one line `In target 4/5 · Protein 3/5 · −0.4 kg` (each part only when it has data, as `WeeklySummaryBlock._lines` does now). The source is `weeklySummaryProvider(view.period.start)`, so the numbers agree with the chart (same `progressDaysProvider` series). Loading: two reserved skeleton lines of the same height (UX-045). Error: see PA5 (content-free failure + Try again; the header stays tappable). **Month/phase:** the plain "Calories" title, as today. One averaging rule, no new domain code. Reason: owner P1 B; a second averaging rule for months would be speculative.
- **D3 Past weeks and the full IN-001 numbers.** Past weeks: the period bar's ‹ in week mode (already there). Tapping the week header opens `WeeklySummaryRoute(start)` (kept; it's also the NT-004 notification target). `WeeklySummaryScreen` keeps ‹ › and the check-in row and shows `WeekSummaryTiles` (replaces `WeeklySummaryBlock`): a big "1,940 / 2,100 kcal avg" number, then tiles In target x/y · Protein x/y · Fiber g/day · Trend · Workouts n (of planned) · PRs, and one muted caption "5 of 5 days counted". The "Past weeks" row on Progress goes (the period bar replaces it for weeks with food or weight data; workout-only weeks via the week screen, PA8). Reason: keeps every IN-001 fact one tap away, numbers first (P1 A's tiles reused where the owner wanted detail).
- **D4 Workouts and fiber on Progress.** Fiber: dropped from the top; it already has its own chart in Macros and its weekly average is on the tiles. Workouts: the "Exercise progress" row gets a subtitle from `weeklyWorkoutSummaryProvider(currentWeekStart)`: "2 of 3 this week · 1 PR" (planned part only with a plan; nothing when 0 sessions). Reason: IN-001 meaning kept, no new section.
- **D5 `FbNoticeRow`** (DS, `packages/fb_design_system/lib/src/components/notice_row.dart`, exported): `FbNoticeRow({required IconData icon, required String text, required String actionLabel, required VoidCallback onAction, VoidCallback? onTap, String? dismissTooltip, VoidCallback? onDismiss, Key? key})`. A `surfaceContainer` rounded row, min 48 dp: icon, `Expanded` text (`maxLines: 1` at scale < 1.3, else 2, ellipsis), a trailing `FbButton.text(actionLabel)`, optional `×` icon button. The row's tap = `onTap ?? onAction`. Semantics: one container, label = text, the button its own action. Reason: one shape for every notice; it's the "row with an icon and one button" from the mockup.
- **D6 Notice rows on Progress** (`adaptive/presentation/adaptive_cards.dart`, `ramadan/presentation/ramadan_targets_offer.dart`): each card's current body moves unchanged into a sheet (`showFbSheet`), opened from a row; the proposal semantics stay (nothing written until a button in the sheet is tapped, D-079/TG-034).
  - Pending check-in: "Weekly check-in · new target 2,050" · **Review** → sheet with `_ProposalCard` (±, Keep / Use). The sheet pops after a tap that wrote.
  - Applied: "Target now 2,050 (was 2,100)" · **Review** → sheet with Got it / Change back (A48: never disappears while the note is unseen).
  - Stale: "Check-in out of date" · **Dismiss** (direct; it was already the only action).
  - Incomplete day: "Fri 3 Nov · 640 kcal · incomplete?" · **Review** → sheet with Complete / Mark incomplete.
  - Ramadan offer: "Ramadan targets: maintain?" · **Review** → sheet with the offer body and its two buttons.
  - Load failures keep their `_CardLoadFailed` banners (already one line + Try again).
  - `CheckInCard` keeps its name and keys `check-in-*` on the sheet's controls; new row keys `check-in-row`, `incomplete-day-row`, `ramadan-offer-row`.
- **D7 Dashed future days** (`packages/fb_design_system/lib/src/charts/bar_chart_painter.dart`, placeholder branch only, today `return`): a dashed rounded outline, height = the mean of the drawn bars' targets (none → 40 % of the plot), in `outlineVariant`. No semantics node (as now), no hit target. Reason: mockup; kept to one method so A62's bar-style work doesn't collide (R1).
- **D8 Text-only card sweep** (UX-047). Criterion: a card/container whose content is only sentences (no number, bar, picture or control) becomes an inline helper (icon + text, no surface) or an `FbNoticeRow`; a card with sentences plus numbers leads with the number. List (engineer greps `FbCard(` / `DecoratedBox` for more and adds them to this list in the Progress log):
  1. `progress/presentation/weekly_summary_card.dart` → deleted (D2/D3).
  2. Check-in / incomplete day / Ramadan offer → rows (D6).
  3. `today/presentation/today_numbers.dart:~285` `_EmptyDayHint` → inline helper (icon + the same copy, no `FbCard`).
  4. `workouts/presentation/plan_setup_screen.dart:332` empty day → inline helper with the existing "Find any exercise" action inside it (audit minor).
  5. `account/presentation/account_today_banner.dart:~80` guest prompt → `FbNoticeRow` ("Back up what you've logged" · **Sign in**, × = Not now).
  6. `adaptive/presentation/adaptive_cards.dart:~430` Expenditure before enough data → two number tiles ("2 weigh-ins", "5 days" to go) + a "How this works" row that opens `adaptiveIntro` in a sheet.
  7. `progress/presentation/ramadan_comparison_card.dart` → kept (a numbers table: already number-led).
  8. `onboarding/presentation/pages/plan_page.dart:69`, `workouts/presentation/exercise_screen.dart:247` → kept (number-led).
  Skipped: `design_preview/**` (dev only, backlog).
- **D9 Identity store** (`core/account/local_identity_store.dart`, new; TD candidate): `LocalIdentity {String? name, String? email}` with a redacted `toString` ("LocalIdentity(name: set, email: set)"). `LocalIdentityStore(SharedPreferences, {namespace})`: `read(profileKey)`, `save(profileKey, LocalIdentity)`, `setName(profileKey, String?)`, `prune(Set<String> liveKeys)`. Key `<namespace>.identity.<profileKey>`, JSON `{"n":…, "e":…}`. Name: trimmed, ≤ 40 runes, newlines removed; empty → null. **Why shared preferences, not drift:** it is account metadata like the profile registry and `account_removed_note_store.dart`, not user data; it must not sync (AC-010 lists synced data; this is the exception), must not enter the export snapshot or `ChangeSetApplier`'s undo, and shared preferences are already excluded from cloud backup and device transfer (`backup_rules.xml`, `data_extraction_rules.xml`). Per profile, so a read-only copy shows its own name and a removed profile's identity is pruned. Writes are a confirmed edit (sheet Save), no undo entry (rule 8 covers user data in `user.db`).
- **D10 Where the name and email come from.**
  - `GoogleIdTokenSource.idToken()` → `Future<GoogleCredential?> credential()`; `GoogleCredential {String idToken, String email, String? displayName}` with a redacted `toString`. The driver reads `account.authentication.idToken`, `account.email` (non-null in 7.2.0) and `account.displayName` (nullable), verified on pub.dev 2026-11-06. **This reverses A50 D9** ("we never read email, displayName") on purpose: the owner's M1 needs them; they stay in memory until the success path stores them locally. Fakes change in `test/core/account/account_fakes.dart` and `patrol_test/support/account_fake_api.dart`.
  - **Superseded by PA2** (a redacted `SignInResult` built before `cancel()`; no `lastGoogleProfile` getter).
  - `SignInController` saves from `SignInResult.identity` (PA2). A failed save is swallowed (the header falls back; sign-in already succeeded).
  - **M2:** the email path's `SignInStep.done` shows `FbTextField` "What should we call you?" (supporting "Shown only on this phone. You can skip.", key `sign-in-name`) above the existing Done button; Done saves a typed name, empty = skip. Google's done step is unchanged. Asked once per sign-in by construction; editable later (D11).
  - Existing signed-in installs (the owner) have no stored identity: the header shows "Signed in" with the backed-up icon until the next sign-in or until a name is typed in Account & data.
- **D11 Me header (M1 A)** (`account/presentation/account_section.dart`): `AccountCard` gains `onTap` and reads `localIdentityProvider` (new, `account/application/local_identity.dart`: watches `accountStatusProvider` and the registry's active key, prunes on build). Signed in / expired / read-only: `FbLetterAvatar` (new DS, `components/letter_avatar.dart`: first grapheme of `name ?? email` uppercased via `characters`, so Arabic works; icon fallback) + name (or email when no name) + email (when a name is shown) + the existing status line (sync / expired / read-only). Guest: `FbIcons.me` (person) + "Guest" + the existing detail and Sign in button. On Me: `AccountCard(onTap: → MeAccountRoute)` with a `›`. On Account & data: no tap, plus a new row "Name · Abood ›" (key `account-name`) for accounts → sheet with the field and Save (clear = remove). Loading vs error (audit major 9): `accountStatusProvider` error → an `FbInlineBanner` with Try again in the card's slot; loading keeps the skeleton.
- **D12 Privacy checklist (for the plan review and Codex).** Name/email: never in a log, breadcrumb, exception text or `toString` (redacted types; `PiiScrubber` stays as the backstop); never sent to the server (no API call takes them), never in Buddy context (the context builders read `user.db` only, AC-041), never synced, never in export (`export_snapshot.dart` reads drift only), never in cloud backup (shared prefs excluded). Removed with the profile through the `onDeleted` hook of the profile-file lifecycle, so journaled recovery covers it, plus serialized reconciliation pruning (PA3). Semantics read the name aloud locally only.
- **D13 S1 A.** `MePreferencesScreen` (`me/presentation/me_pages.dart:130`) drops `LanguageSettingRow` and `EnergySettingRow` (both deleted from `settings_section.dart`; grep readers) and ends with one muted line `prefsFixedFacts` "Calories are shown in kcal. The app is in English; Buddy also understands Arabic." UX-048 rule.
- **D14 W4 "numbers = done".** `checked` was never stored (drift `workout_sets` and the sync payload hold only saved sets; `LogFormDraft` saves sets whose `checked` is true), so no migration and no contract change.
  - `LogSetRow.checked` is removed; `bool get counts => saved != null`. `toFormSet()` passes `checked: counts` (the `fb_domain` `LogFormSet` API stays; only its doc says "counts").
  - `editSet`: empty input → `saved: null`, no issue (the set leaves the session at the next save); valid → `saved` = the values, issue null; non-empty invalid → keep `saved` (the last valid number stays stored, as a checked row did before) and set `issue`. Every edit schedules autosave (no `save: row.checked` gate).
  - Hints (last time) never count. `toggleSet` is deleted.
  - New `fillFromLastTime(cardId) → int`: rows with empty input and a hint get `input = SetInput.of(type, hint)` and `saved = LoggedSet(id, hint)`; one `_updateCard`, autosave. Returns how many were filled.
  - `removeSet` returns the removed `(LogSetRow row, int index)`; new `restoreSet(cardId, row, index)` puts it back (clamped index), autosave. In-form Undo, like A57 A69; the visit keeps its one undo-stack entry.
  - Unchanged: edit mode opens stored sets with `saved` (they count); Repeat and template launches start empty with hints; delete-when-empty (`finishVisit` → `_deleteEmpty` when `savedDraft == null`), conflicts, `_reId`, PR detection (`prs.ofSet` from history), template offers.
  - `LogFormState.hasChecked` → `hasSets`; `workout_log_screen.dart` `_collapsedByDefault` uses `!input.isEmpty`, `_SessionSummary` counts `counts`.
  - **Issue display:** the row shows `issue` only after focus leaves the row (a `Focus(onFocusChange)` around the inputs), so typing "62.5" before the reps doesn't flash an error. A half-typed row that never became valid isn't saved; its error mark is visible after leaving it.
- **D15 W4 set row and card** (`workouts/presentation/set_row.dart`, `exercise_log_card.dart`):
  - Normal layout: one header row per card (`workout-set-header-<cardId>`): Set · Last · the type's field names (kg/Reps, Added kg/Reps, Assist kg/Reps, Reps, Time, Minutes/km), excluded from semantics. Rows: number (menu) · last (fixed width) · inputs · the fixed PR/error status slot (A57 D20). No checkbox. Fields hide their visible label (`FbNumberField.hideLabel`, new DS flag; the label stays the semantics label).
  - Compact layout (width < 360 dp or text ≥ 1.3): no header row; per-row labels stay; "last" above the inputs; reserved status line (A57 D20 unchanged).
  - Hints: an empty field with a hint shows it in `onSurfaceVariant` with a **dashed outline** (`FbNumberField` / `FbTextField` `dashedWhenEmpty: true`, a DS `InputBorder` subclass painting a dashed rounded rect while empty and unfocused). Hints are not counted (semantics "Last time 60 × 8").
  - "Same as last time" (`FbButton.text`, a new `FbIcons.sameAsLast` token (`Icons.content_copy_rounded`), key `workout-same-as-last-<cardId>`) next to "Add set"; shown only when a row is empty and has a hint; tap → `fillFromLastTime`.
  - PR marker shows only on counted sets (`isPr && row.counts`).
- **D16 W5 swipe to remove** (`set_row.dart` via the card): each row is wrapped in DS `FbSwipeActions(dismissAction: FbSwipeAction(label: "Remove set", icon: FbIcons.delete, onTriggered: …))`; it already provides the threshold haptic, RTL mirroring, reduced motion and the TalkBack custom action. Removal (swipe or the number menu) → `removeSet`, then `showUndoFeedback`-style snackbar "Set 2 removed" · Undo → `restoreSet`. Inside `RevealedColumn`, keyed by row id (A57 A22 exit motion stays). Rows of an unknown exercise (`type == null`) aren't swipeable. Exit ownership: PA7.
- **D17 Ramadan field-level writes** (audit major 7, re-verified: A57's queue serializes writes but each still replaces the whole season with a snapshot copy, so a second rapid edit can restore an old field). `SettingsActions.updateRamadanSeason(int hijriYear, RamadanSeason Function(RamadanSeason current) change)` applies `change` to the **stored** season inside `_change` (seasons missing → `RamadanSeason(hijriYear: year)` as base). `ramadan_screen.dart`, `ramadan_targets_offer.dart` and `ramadan_proposal_card.dart` pass field changes (`(s) => s.copyWith(startShift: picked)`). `setRamadanSeason` stays for whole-season callers if any remain (grep; else delete).
- **D18 S2 coverage.** In: majors 1–9 and minors Energy, Language (D13), Ramadan city state, Targets forced-fixed, About target, plan-setup card (D8). Out → backlog: design_preview no-op controls (dev only), adaptive mode has no Me entry (product placement; Progress has it). Details in the coverage table.
- **D19 Unsaved-edits guard** (audit major 8): move `showDiscardChangesSheet` from `foods/presentation/personal_foods/discard_changes_sheet.dart` to `core/ui/discard_changes_sheet.dart` (foods re-imports it; no copy). `TemplateEditorScreen` and `CustomExerciseScreen` wrap in `PopScope(canPop: !dirty)`; on a blocked pop they ask and pop on Discard. Dirty = the form differs from what it opened with (`TemplateEditor`/`CustomExerciseForm` gain `bool get dirty`).
- **D20 Storage failures in settings** (audit major 3): `_write` also catches `Exception` from `store.read`/`put`/`reset` → `SettingsFailed(SettingsFailure.storage)` (new enum value). `reportSettingsOutcome` already shows `settingsSaveFailed` for any `SettingsFailed`. No user value in the outcome (as today). Scope widened to prerequisite reads: PA6.
- **D21 Lean tests (TD-104).** Logic tests for D14/D16/D17/D9/D20 and one happy path per changed screen; no new goldens; touched goldens regenerated and viewed; keys, not copy.
- **D22 Spec draft D-097** (below). **A62 has D-096**, so A63 takes **D-097** (PA9). Every reference (card, spec text, test names, ARB descriptions, TD text) uses D-097; WP1 greps for D-096 in A63's own diff before committing. WP1 writes it only after the orchestrator's OK (content owner-approved 2026-11-06).

**Draft spec entry (WP1 writes it into `spec/decisions.md`):**
```
## D-097 — Visual first: no text-only cards, honest rows, who's signed in, sets count by their numbers
- Date / Source: 2026-11-06 · owner review of the next-UX mockups (P1 B, M1 A + M2, S1 A, W4 A, W5 A)
- Status: Accepted by the owner. Adds UX-047, UX-048, AC-005. Amends IN-001, WO-034, UX-010.
- Decision:
  - No card is only sentences (UX-047). A card leads with a number, a bar, dots or a picture; notices are one-line rows with an icon and one action; longer explanations open on tap. Text stays minimal.
  - A row that shows a value or › always opens something (UX-048). Facts that can't change are one quiet line (calories in kcal, the app in English).
  - Progress: no "This week" text card. The week lives in the calories chart card (average vs target in its header, one line of key numbers, future days dashed); its full numbers are one tap away; past weeks stay reachable. Check-in, Ramadan targets offer and incomplete-day notices are one-line rows.
  - Me shows who's signed in (AC-005): a letter circle, the name, the email and the sync status; a tap opens Account & data. Name and email come from Google sign-in or the email used; after an email sign-in the app asks once "What should we call you?" (skippable, editable later). They are kept only on this phone: never synced, sent to Buddy or the server, or logged. Guests see "Guest".
  - Workout sets count as soon as they have numbers (WO-034): no tick. Last time's numbers show as grey hints that don't count; "Same as last time" fills an exercise's empty sets; swiping a set sideways removes it, with Undo.
- Why: the owner's rule "no text-only cards; focus is visual, text minimal". Text cards were read last and skipped; rows that looked changeable but weren't felt broken; Me didn't say whose data it was; an unticked set with numbers was silently lost. Step A63.
```
**Spec text drafts (WP1):**
- `spec/30` §5: **UX-047** `[R1]` **Visual first** (D-097): no card is only sentences; it leads with a number, bar, dots or picture. Notices are one-line rows with an icon and one action; longer explanations open on tap. **UX-048** `[R1]` A row that shows a value or › always opens something; facts that can't change are one quiet line.
- `spec/20` §1: **AC-005** `[R1]` Me shows who's signed in: a letter circle, name, email and sync status; guests see "Guest". Name and email come from Google or the email used; after an email sign-in the app asks once for a name (skippable, editable). Kept only on this phone: not synced, not sent to the server or Buddy (AC-041), not logged (D-097).
- `spec/15` WO-034: "… → each exercise shows **last session's numbers** as hints → enter or adjust sets; a set counts as soon as it has numbers (no tick), and "Same as last time" fills the empty sets. Swipe a set sideways to remove it, with Undo. The form **saves as you type** (a direct action with undo, D-085, D-097)."
- `spec/16` IN-001: append "On the Progress tab the week lives in the calories chart card (average vs target and a line of key numbers); the full summary opens from it and from the weekly notification (D-097)."
- `spec/30` UX-010: "Me (who's signed in, AC-005; a targets summary, then grouped subpages …)".

**Amendments after the Codex plan review (2026-11-06, verdict approve with changes; `PA1…`):**
- **PA1 Clearing `saved` (D14).** `LogSetRow.copyWith(saved:)` keeps the old value on null (`saved ?? this.saved`), so D14's "empty → saved: null" needs an explicit clear: `copyWith({…, bool clearSaved = false})` (`saved: clearSaved ? null : saved ?? this.saved`); `editSet` with empty input passes `clearSaved: true`. Tests (T-W2, extended): (a) valid → empty → autosave → leave: the set leaves the session; when it was the last counted set the session is deleted at leave with the visit's Undo; (b) a set cleared while the session's **first** save (create) is still in flight: after it completes, the drain writes the cleared form (the set is gone; with nothing left, leave deletes the session); (c) numbers typed again while `_deleteEmpty` runs: the existing restore path puts the session back and the drain saves it. The existing serialization and compensating-Undo tests are kept, rewritten from `toggleSet` to `editSet`; only tests that test the tick itself are deleted.
- **PA2 Google identity through a redacted success result (D10).** `SignInFlow._finish` calls `cancel()` before returning, which clears the flow's memory, so nothing is read from the flow afterwards. Instead:
  - `AccountService._complete` returns the **committed** local profile key with the outcome (it resolves the target profile for the transition).
  - `_finish` returns `SignInResult {AccountOutcome outcome; SignedInIdentity? identity}`; `SignedInIdentity {String profileKey, String? email, String? displayName}` with a redacted `toString`. It is built inside `_finish` **before** `cancel()`, from the method that actually authenticated: the Google profile captured with the token (`_googleProfile`, set in `signInWithGoogle`, kept through the 409 merge/discard choice) or the email of the verified challenge (`_challengeEmail`, set in `startEmail`). Starting Google clears `_challengeEmail` and starting email clears `_googleProfile`, so Google after an email attempt never falls back to that email.
  - `SignInController` saves `LocalIdentityStore.save(identity.profileKey, …)` from the result (never a re-read of "the active key" after other async work) and keeps `identity.profileKey` for M2's name field.
  - Tests (T-M2, extended): direct Google; 409 → merge and 409 → discard (identity under the committed key of each); cancel at the Google sheet and cancel at the conflict (nothing stored); Google after an abandoned email attempt (the Google email, not the typed one); email verify (the challenge's email).
- **PA3 Identity removal follows the profile-file lifecycle (D9, D12).** `account_providers.dart`'s `OpenProfileHost.onDeleted` hook (already removing a profile's pending scans) also calls `LocalIdentityStore.remove(key)`. `deleteFiles` runs it after the directory is gone, and `AccountTransitions`' journaled cleanup and startup recovery call `deleteFiles`, so an interrupted removal is retried by the journal; a failing remove fails `deleteFiles` like today's pending-scan remove, so the journal retries it. Reconciliation: `localIdentityProvider` still prunes keys missing from the registry, and the store serializes `save`/`setName`/`remove`/`prune` through one internal queue (a future chain), so a prune never races a just-committed save. The controller-side prunes of the first plan are dropped. Tests (new `test/core/account/local_identity_lifecycle_test.dart` with the transition fakes): sign-out-remove removes it; sign-out-keep keeps it on the read-only copy; deletion interrupted after the directory removal → recovery removes the identity; a guest profile never shows another profile's identity; two profiles keep separate identities and pruning one leaves the other.
- **PA4 Tier Risky** (D1 rewritten).
- **PA5 Weekly-summary failure stays visible (D2).** `weeklySummaryProvider` also reads the workout summary, which can fail while the calories chart is fine. In week mode the header stays a tappable entry in every state: loading = reserved skeleton lines; data = D2; **error = "Calories" + a content-free line "Week summary unavailable" with Try again** (invalidates `weeklySummaryProvider(start)` and `weeklyWorkoutSummaryProvider(start)`), same reserved height, and the header still opens the week screen, which has its own error + retry (`weekly-summary-error`). Test T-P5: workout-summary read fails with healthy calorie data → the chart renders, the header shows the failure; Try again after the source recovers → the numbers appear.
- **PA6 Prerequisite reads in the storage mapping (D20).** The mapping wraps the whole public command, not only `_write`: one `_guarded(() async …)` around every `SettingsActions` command's own reads (e.g. `setNotFasting`'s season read, `updateRamadanSeason`'s base read) and `_write`'s read/put/reset. `ChangeRejected` keeps its specific mapping, checked first. Tests (T-S3, extended): a failing prerequisite read, a failing `_write` read, a failing put and a failing reset each return `SettingsFailed(storage)`; a write queued behind a failed write still runs and lands; a `ChangeRejected` still maps to its own failure.
- **PA7 One owner for the swipe exit (D16).** `FbSwipeActions` collapses the `Dismissible` and then resets its key, while `RevealedColumn` keeps a removed child for its own exit: two exits. **`RevealedColumn` owns the exit.** DS `FbSwipeActions` gains `collapseOnDismiss` (default `true`, today's behaviour for diary rows); with `false` the row only slides out (no resize) and the key is not reset, and the parent's removal collapses it. The card passes `false`. The restored row after Undo mounts with a fresh swipe identity (the wrapper is keyed `(row.id, restoreCount)`), so it never comes back slid out. Menu removal uses only `RevealedColumn`'s exit. Tests (T-W8, extended): intermediate frames show one collapse and no full-height reappearance; Undo immediately after the swipe (mid-exit) shows the row once, at full width, with its numbers; menu removal; reduced motion removes at once; RTL swipes mirror (dismiss toward the start edge). Checks, no tests: a drag that starts in a focused field, vertical scrolling over rows.
- **PA8 Earliest-week boundary (D3), documented, not aligned.** The period bar's ‹ stops at `progressEarliestDateProvider` (diary, weights), while `summaryEarliestDate` also counts workout-only weeks. A63 doesn't change `progress_providers.dart` (A62 reworks the aggregation there). Workout-only older weeks stay reachable through the week screen: header tap → ‹ on `WeeklySummaryScreen`, which already stops at `summaryEarliestDate`. Test T-P7: with a workout logged before any food or weigh-in, the period bar stops at the first data week, and the week screen's ‹ reaches the workout-only week and shows its workouts tile. D3's "the period bar replaces Past weeks" is narrowed to "for weeks with food or weight data".
- **PA9 A62 coordination and numbering**: Risks R1 checks, D22.
- **PA10 Testing rule**: the WP gate above; per-WP "Done when" means the tests are written and `make check-dart` is green, with CI as the evidence.

### Design

**Progress (after P1 B):**
```
ProgressScreen ListView
 CheckInCard          → 0–2 FbNoticeRow (pending/applied/stale), sheets hold the old cards (D6)
 RamadanTargetsOfferCard → FbNoticeRow → sheet
 IncompleteDayCard    → FbNoticeRow → sheet
 ProgressPeriodBar    (unchanged; ‹ = past weeks)
 CaloriesSection
   CaloriesWeekHeader (week mode; tap → WeeklySummaryRoute)   new
   FbBarChart         (unchanged API; placeholders dashed in the painter, D7)
   legend + day details (unchanged; A62 owns legend changes)
 MacrosSection, WeightSection, RamadanComparisonCard, GoalProgressCard (unchanged)
 Measurements row, Exercise progress row (+ "2 of 3 this week · 1 PR", D4), ExpenditureCard (D8.6)
WeeklySummaryScreen: ‹ week › · WeekSummaryTiles (new, replaces WeeklySummaryBlock) · CheckInCard rows
```

**Me:**
```
MeScreen: AccountCard(onTap → Account & data)  [FbLetterAvatar | name / email / status | ›]
MeAccountScreen: AccountCard · "Name" row (account only) · AccountRows
SignInScreen done (email): "You're signed in" · name field (optional) · Done
```
Data flow: `SignInController` (success) → `LocalIdentityStore` (shared prefs) ← `localIdentityProvider` → `AccountCard`. Nothing else reads the store. `core/account` holds the store; `features/account` the provider and UI (layers per `03`).

**Workout log:** `WorkoutLogController` (D14) → `LogFormState` → `ExerciseLogCard` (header row, Same as last time, swipe rows) → `SetRow` (no checkbox, dashed hints, focus-gated issue).

**DS additions** (`packages/fb_design_system`, exported): `FbNoticeRow` (D5), `FbLetterAvatar` (D11), `FbNumberField`/`FbTextField` `hideLabel` + `dashedWhenEmpty` (D15), dashed placeholder bars (D7).

**No contract, sync, drift or writer change.** `contracts/` untouched; `workout_sets` unchanged; `ChangeSetApplier` paths unchanged (the Ramadan write still goes `SettingsStore → ChangeSetApplier`).

**ARB (en) new:** `progressCaloriesWeekAvg` "avg {kcal} / {target}", `progressCaloriesWeekLine` parts (`progressWeekInTarget` "In target {n}/{of}", `progressWeekProtein` "Protein {n}/{of}"), `progressWeekOpen` (semantics), tile captions, `progressExercisesWeek` (plural), `checkInRowPending`, `checkInRowApplied`, `checkInRowStale`, `incompleteDayRow`, `ramadanOfferRow`, `noticeReview` "Review", `guestPromptShort`, `adaptiveToGoWeighIns`, `adaptiveToGoDays`, `adaptiveHowItWorks`, `meGuestName` "Guest", `accountName` "Name", `accountNameAdd`, `signInNameLabel`, `signInNameHint`, `prefsFixedFacts`, `workoutSameAsLast`, `workoutSetHeader` "Set", `workoutLastHeader` "Last", `workoutSetRemoved` "Set {number} removed", `customExerciseSaveFailed`, `exercisePickerLoadFailed`, `notifLoadFailed`, `ramadanCityLoadFailed` (reuse existing `*LoadFailed`/`foodTryAgain` where they fit). **Removed:** `workoutSetDone`, `settingsEnergy`, `settingsLanguage`, `settingsLanguageEnglish` (if unused), `weeklySummaryPastWeeks` (if unused).

### Work packages (one Opus `flutter-engineer`; one local commit per WP; no pushes)
**WP gate (PA10, `PROCESS.md` "No local test runs by default"):** locally only codegen (`make gen-app` or the touched generator) and `make check-dart`, then the `cross-check` skill and `git grep` of changed keys/copy in `patrol_test/`, `integration_test/`, `test/`. Each WP writes its tests; **the merge-step CI run is the test evidence**. On a CI failure, reproduce only the failing tests via `timeout 600 tools/scripts/heavy.sh flutter test <file>`, one at a time.

- **WP1 Spec + design system.** Spec drafts above into `spec/decisions.md`, `spec/30`, `spec/20`, `spec/15`, `spec/16` (after the orchestrator's OK; renumber if A62 took D-097). TD candidate (D9) into `12-decisions-and-questions.md` as the next TD. DS: `FbNoticeRow`, `FbLetterAvatar`, `hideLabel` + `dashedWhenEmpty` on the two fields, dashed placeholder bars. Files: `packages/fb_design_system/lib/src/components/{notice_row,letter_avatar,number_field,text_field}.dart`, `charts/bar_chart_painter.dart`, `lib/fb_design_system.dart`, DS ARB if a DS string is needed, tests `test/components/{notice_row,letter_avatar,number_field}_test.dart`, `test/charts/bar_chart_test.dart`. Done when: DS tests written, `make check-dart` green, `make trace` shows UX-047/048, AC-005 only as "untested until WP2–WP4".
- **WP2 Workout log: numbers = done, Same as last time, swipe + Undo (W4, W5).** D14–D16. Files: `features/workouts/application/{workout_log_state,workout_log_controller}.dart` (+ `.g.dart`), `features/workouts/presentation/{set_row,exercise_log_card,workout_log_screen}.dart`, `packages/fb_domain/lib/src/workouts/log_form_draft.dart` (doc only), `lib/l10n/app_en.arb`. Tests: rewrite `test/features/workouts/application/workout_log_controller_test.dart` (≈20 `toggleSet` uses → `editSet`/`fillFromLastTime`), `test/features/workouts/presentation/workout_screens_test.dart` (lines ~260/285/361/556/568). **Patrol:** `patrol_test/offline_test.dart:259–279` (taps `workout-set-done-*` → one tap on `workout-same-as-last-<cardId>`). Done when: T-W1–T-W8 written and `make check-dart` green (PA10); `git grep -n "toggleSet\|workout-set-done\|\.checked" apps/mobile/{lib,test,patrol_test}` finds no workout hits.
- **WP3 Progress top + text-card sweep (P1 B, UX-047).** D2–D8. Files: `features/progress/presentation/{progress_screen,calories_section,calories_week_header (new),weekly_summary_card (delete),weekly_summary_screen,week_summary_tiles (new)}.dart`, `features/progress/progress.dart`, `features/adaptive/presentation/adaptive_cards.dart`, `features/ramadan/presentation/ramadan_targets_offer.dart`, `features/today/presentation/today_numbers.dart` (`_EmptyDayHint` only), `features/workouts/presentation/plan_setup_screen.dart`, `features/account/presentation/account_today_banner.dart`, ARB. Tests: `test/features/progress/presentation/{progress_screen_test,weekly_summary_test}.dart`, `test/features/adaptive/adaptive_cards_test.dart`, `test/features/ramadan/ramadan_targets_offer_test.dart`, `test/features/account/guest_prompt_test.dart`, `test/features/notifications/notification_links_test.dart` (route kept: check only), `test/app/router/app_router_test.dart` (check). Goldens: `progress_screen`, `today_empty_day`, `app_shell` (if Today's empty day shows). Done when: T-P1–T-P5, T-P7, T-X1–T-X2 written, `make check-dart` green (PA10); T-P6 after the A62 rebase.
- **WP4 Me header, name, honest Preferences (M1 A, M2, S1 A, audit major 9).** D9–D13. Files: `core/account/{local_identity_store (new),google_id_token_source,google_plugin_id_token_source,account_service,account_providers}.dart` (+ `.g.dart`), `features/account/application/{local_identity (new),sign_in_controller}.dart`, `core/account/account_providers.dart` (`onDeleted`, PA3), `features/account/presentation/{account_section,sign_in_screen}.dart`, `features/me/presentation/{me_screen,me_pages}.dart`, `features/settings/presentation/settings_section.dart`, ARB. Tests: `test/core/account/{local_identity_store_test (new),google_plugin_id_token_source_test,sign_in_flow_test,account_fakes}.dart`, `test/features/account/{sign_in_screen_test,account_upgrade_journey_test}.dart`, `test/features/me/me_screen_test.dart`, `test/features/settings/presentation/settings_screens_test.dart`. **Patrol:** `patrol_test/support/account_fake_api.dart` (`FakeGoogleIdTokenSource` implements `credential()`; returns a synthetic email/name), `account_sign_in_test.dart` (check: 'Done' stays unique on the email done step; `_openMeRow('Account & data')` still finds the Me row). Goldens: `account_data_guest`, `account_data_signedIn`, `me_preferences`, `me_settings`, `sign_in_*` (if the done step is in them). Done when: T-M1–T-M6 written, `make check-dart` green (PA10).
- **WP5 Settings audit fixes (S2).** D17–D20 and the coverage rows below. Files: `features/settings/application/settings_actions.dart`, `features/ramadan/presentation/{ramadan_screen,ramadan_proposal_card}.dart`, `features/targets/presentation/targets_screen.dart`, `features/workouts/application/{custom_exercise_form,template_editor}.dart`, `features/workouts/presentation/{custom_exercise_screen,template_editor_screen,exercise_picker_screen}.dart`, `features/notifications/presentation/notification_settings_screen.dart`, `features/me/presentation/me_pages.dart` (Targets & goal states), `features/settings/presentation/about_screen.dart`, `core/ui/discard_changes_sheet.dart` (moved), `features/foods/presentation/personal_foods/*` (import only), ARB. Tests: T-S1–T-S9 in the existing files (`settings_test.dart`, `ramadan_screen_test.dart`, `targets_screen_test.dart`, `template_editor_test.dart`, `exercise_picker_screens_test.dart`, `settings_screens_test.dart`, `me_screen_test.dart`). Done when: tests written, `make check-dart` green (PA10); each audit row in the coverage table has its fix or backlog line.
- **WP6 Generate, goldens, Patrol/integration sweep, close.** `make gen-app` (l10n + Riverpod + drift: expect no drift diff) and commit any generated drift; regenerate only failing goldens and **view each image** (expected: `progress_screen`, `today_empty_day`, `app_shell`, `account_data_*`, `me_preferences`, `me_settings`, `about`, maybe `workouts_tab`, `sign_in_*`); `git grep` every changed/removed string and key in `patrol_test/` and `integration_test/`. **Known Patrol hits:** `offline_test.dart` step 4 (`workout-set-done-*` → Same as last time; WP2) and the Progress step 5 (keys unchanged: check); `app_test.dart:79–99` (Progress: `progress-calories-chart` and its empty-branch icon stay; the header above it changes height only) and the tab checks (`'Food & meals'`, `'Your workouts will show up'`, `'Tell Buddy what you ate'`: unchanged); `account_sign_in_test.dart` (email done step + `'Done'`, Google fake, Me row `'Account & data'`); `support/account_fake_api.dart` (compile). **Integration:** `progress_benchmark_test.dart` (keys `progress-calories-chart`, `progress-macro-protein`, bar counts unchanged: check), `jank_benchmark_test.dart` (Progress period text taps: check). Backlog lines (D18 outs). `make trace`, board row, `make progress`, Progress log, Outcome. A manual CI run with `android-it` before merge is recommended (Patrol touched).

### Coverage (S2 audit + owner items)
| Item | WP | How |
|---|---|---|
| P1 B | WP3 | D2–D4, D7 |
| Text-only cards | WP3 | D8 list |
| M1 A, M2 | WP4 | D9–D12 |
| S1 A (audit minors Energy, Language) | WP4 | D13 |
| W4 A | WP2 | D14, D15 |
| W5 A | WP2 | D16 |
| Major 1 Targets weekday rows | WP5 | outer `Semantics(onTap:)` = the row's tap (`targets_screen.dart:476`) |
| Major 2 Custom exercise save/delete | WP5 | `try/catch` storage → `WorkoutActionOutcome` failure + `finally saving: false`; screen shows `customExerciseSaveFailed`, inputs kept |
| Major 3 Settings storage exceptions | WP5 | D20 |
| Major 4 Notifications read failure | WP5 | error → `LoadFailedView` + retry; controls only with data |
| Major 5 Exercise picker | WP5 | loading → `LoadingRows`, error → `LoadFailedView`, empty only with data |
| Major 6 Me › Targets & goal | WP5 | loading → `LoadingRows(2)`, error → banner + retry (invalidate `setupStatusProvider`) |
| Major 7 Ramadan rapid edits | WP5 | D17 |
| Major 8 Editors lose drafts on Back | WP5 | D19 |
| Major 9 Account card stuck loading | WP4 | D11 error state |
| Minor Ramadan city read failure | WP5 | `selectedCityProvider` error → "Couldn't load city" + retry, not "no city"; prayer rows hidden only with no city |
| Minor Targets forced-fixed segmented | WP5 | `FbSegmented(enabled: false)` (new DS flag: dimmed, `Semantics(enabled: false)`) when forced; the note stays |
| Minor About long-press | WP5 | `ConstrainedBox(minHeight: 48)` on the version block (hidden by design, A11 D17) |
| Minor plan-setup empty card | WP3 | D8.4 |
| Minor design_preview no-ops | — | backlog (dev only) |
| Note: adaptive mode has no Me entry | — | backlog (placement decision) |

### Test list
Workouts (W4/W5):
- T-W1 `a set with valid numbers is saved without a tick; a hint-only row is never saved` (WO-034, D-097).
- T-W2 `clearing a set removes it from the session; a session left with no counted set is deleted on leave, with Undo` (WO-034, A37 D8).
- T-W3 `invalid numbers keep the last valid value saved and report the issue` (WO-034).
- T-W4 `Same as last time fills only empty rows that have hints, after Repeat and after a template start` (WO-024, WO-020, WO-034).
- T-W5 `remove then restore puts the set back at its index with its numbers and saves` (W5, UX-030).
- T-W6 `edit mode opens stored sets as counted; PR shows only on counted sets` (WO-042).
- T-W7 `set rows: one header per card and no checkbox at 1.0; compact rows keep labels at 2.0 / 320 dp; the issue mark appears only after focus leaves the row` (UX-070, UX-045).
- T-W8 `swiping a set row or the Remove set semantics action removes it with an Undo snackbar` (W5, UX-030); plus PA7's frames, immediate Undo, menu removal, reduced motion, RTL.
- T-W2 extended per PA1 (a)–(c); serialization and compensating-Undo tests kept.
Progress and sweep:
- T-P1 `week mode: the calories header shows the week's average / target and the key line from the weekly summary; month mode shows the plain title; tap opens that week` (IN-001, IN-002).
- T-P2 `check-in, Ramadan offer and incomplete day show as one-line rows; Review opens the card; nothing is written until its button` (UX-047, TG-034, TG-060, DY-004).
- T-P3 `weekly summary screen shows the IN-001 numbers as tiles and moves between weeks` (IN-001).
- T-P4 DS `placeholder bars paint a dashed outline and add no semantics or hit target` (IN-002).
- T-P5 `a failed workout-summary read with healthy calories: the header shows the week failure with Try again; recovery shows the numbers` (IN-001, UX-052; PA5).
- T-P6 `mixed food + day-estimate week after the A62 rebase: averages and "In target" include estimates (a day estimate within range adds to targetDays and daysWithinTarget), protein/fiber denominators exclude them, estimate bars and dashed future slots together` (IN-001, IN-002; PA9).
- T-P7 `workout-only early week: the period bar stops at the first data week; the week screen reaches the workout week` (IN-001; PA8).
- T-X1 `Today's empty day shows an inline helper, not a card` (UX-047, UX-050).
- T-X2 `Expenditure before enough data shows the two numbers to go and How this works opens the explanation` (UX-047, TG-031).
Me and privacy:
- T-M1 `LocalIdentityStore round-trips per profile, trims and caps names, prunes removed profiles; toString shows no name or email` (AC-005, rule 6).
- T-M2 `Google sign-in stores the Google name and email; email sign-in stores the email and the typed name; skipping stores no name` (AC-005, AC-001).
- T-M3 `Me header: the letter from the name (an Arabic name's first letter), the email, the sync line; Guest for a guest; tap opens Account & data` (AC-005, UX-010).
- T-M2 extended per PA2: direct Google, 409 merge, 409 discard, cancel (sheet and conflict), Google after an email attempt, email verify.
- T-M4 `GoogleCredential, SignedInIdentity, LocalIdentity and AccountFailure texts carry no email, name or token` (AC-041, rule 6).
- T-M6 `identity lifecycle` (PA3): sign-out-remove, sign-out-keep, interrupted deletion + recovery, guest isolation, two profiles, prune serialized with a save.
- T-M5 `Preferences has no Energy or Language row and shows the facts line` (UX-048).
Audit (S2):
- T-S1 `a TalkBack tap on a weekday row opens its target editor` (TG-043).
- T-S2 `a failed custom-exercise save re-enables Save and keeps the inputs` (UX-052).
- T-S3 `storage exceptions return SettingsFailed(storage)`: prerequisite read, `_write` read, put, reset; a queued write after a failure still lands; `ChangeRejected` keeps its mapping (UX-052; PA6).
- T-S4 `notification settings read failure shows retry, not defaults` (UX-052).
- T-S5 `exercise picker read failure shows retry, not "no results"` (UX-050–052).
- T-S6 `Me › Targets & goal shows loading and an error with retry` (UX-051).
- T-S7 `two quick Ramadan edits (first day, then last day, slow store) both land` (LC-030/031).
- T-S8 `Back with unsaved template/custom-exercise edits asks before discarding` (UX-052).
- T-S9 `account card shows an error with retry when the status read fails` (UX-052).
Patrol (CI `android-it` only): `offline_test` (workout via Same as last time), `app_test` (Progress), `account_sign_in_test` (email done step).

### Exit-criteria mapping
1. Progress top → T-P1, T-P3, T-P4, `progress_screen` golden, `app_test` Progress check.
2. Notices → T-P2.
3. Sweep → D8 list + T-X1, T-X2, T-P2; Codex checks the list against a grep.
4. Who's signed in → T-M1–T-M4, D12 checklist in the Codex brief.
5. Settings → T-M5, T-S1–T-S9, coverage table.
6. Sets → T-W1–T-W8, `offline_test`; "no data change" = no diff under `contracts/`, `lib/core/db/` and `drift_schemas/`.
7. WP6 commands and the golden/Patrol list in the Progress log.

### Risks and unknowns
1. **Overlap with A62 (lane 2).** Shared files: `progress/presentation/calories_section.dart` (A62 striping/legend; A63 swaps only the title for `CaloriesWeekHeader`), `packages/fb_design_system/lib/src/charts/bar_chart_painter.dart` (A62 new bar style; A63 only the placeholder branch, D7), `today/presentation/today_numbers.dart` (A62 Today totals; A63 only `_EmptyDayHint`), maybe `macros_section.dart` (A63 doesn't touch it), `foods/` search (A63 doesn't touch it), `lib/l10n/app_en.arb`, `spec/decisions.md` (D-097 numbering), `steps/README.md`, `PROGRESS.md`. Mitigation: keep A63's edits in those files minimal and in new files where possible; whichever merges second rebases (ARB and board conflicts are additive). Prefer **A62 first**: its data changes are deeper; A63's Progress edits rebase easily. **Semantic checks after the rebase (PA9; A62 is being reworked: day estimates become a day-level record and per-nutrient "known" flags flow through aggregation):** with a mixed week (food entries + a day estimate) check that (a) the calories header and tiles show averages that include the estimates; (b) protein/fiber denominators exclude day estimates, while "In target" includes an eligible day estimate in both `targetDays` and `daysWithinTarget` (A62 D10), all read from A62's summary fields, never recomputed in A63's widgets; (c) A62's estimated-bar style and labels coexist with D7's dashed future slots in the same painter; (d) Today keeps A62's estimate indicators next to the D8.3 inline helper. One widget test after the rebase covers (a)–(c) (`calories_week_header_test`, named T-P6); (d) is a device check.
2. **W4 behaviour change.** A half-typed row (weight without reps) is not saved; before, it was also lost unless ticked. The error mark after leaving the row tells the user. A set edited to invalid keeps its last valid number (same as a checked row before). Codex is asked to check D14 against `_deleteEmpty`/conflict paths.
3. **Controller test churn.** ~20 `toggleSet` calls in `workout_log_controller_test.dart`; rewrite them to `editSet`/`fillFromLastTime`, delete the ones that only tested ticking (TD-104).
4. **A50 D9 reversal** (reading Google email/name). Deliberate (M1). `displayName` can be null (falls back to the email letter); real device check on the A55 (checklist 4). If the plugin returns an empty email, store none.
5. **The owner's current install** has no stored identity (signed in before A63): the header shows "Signed in" until a name is typed in Account & data or the next sign-in. Checklist item.
6. **Tier.** Risky (D1/PA4): budget two Codex tasks and their fix-checks.
7. **Dashed field outline** (custom `InputBorder`) must not change the field's height or its error border (UX-045): the DS test checks equal sizes empty vs filled.
8. **Patrol** changes have never run on the emulator; budget one `[it]` fix round. The emulator can't run on the 7 GB box.
9. **Swipe inside a scrollable form** with text fields: `FbSwipeActions` is already used on diary rows and proposal lines; a horizontal drag starting in a focused field might move the cursor instead. Acceptable (the menu and TalkBack action remain).

### Size check
**L, upper end: 3.5–4.5 sessions including one fix round** (WP1 0.4, WP2 0.9, WP3 0.8, WP4 0.8, WP5 0.6, WP6 0.3, review fixes 0.6; up from 3–4 after PA1–PA8 and the second Codex review). One step by the owner's choice. If it must split, the seam is after WP3: **A63a** = WP1–WP3 (spec/DS, workouts, Progress) and **A63b** = WP4–WP5 (Me identity + audit fixes), each with its own WP6-style close.

### Owner device checklist (A55, after merge; optional, D-087)
1. Progress: no text card on top; the calories card shows "avg … / …" and the key line in Week; future days dashed; tap the week header → the week screen (tiles); ‹ for last week; at big text the header stacks.
2. A check-in, the Ramadan offer (in Ramadan) or an incomplete day shows as one line; Review opens it; nothing changes until you tap a button.
3. Today with an empty day; plan setup with no exercises; the guest prompt (guest only); Expenditure before enough data.
4. Sign out and sign in with Google: Me shows your letter, name and email; tap → Account & data. Me header: letter circle + name (+ email). Sign in with email: the name question; on a profile-switching sign-in Today asks "What should we call you?" once; skip once and check the email letter; edit the name in Account & data.
5. Preferences: only changeable rows (no Energy or Language rows), the facts line at the bottom. Retry buttons (Progress, Me targets, workouts) reload after a failure.
6. Workout: Repeat a session; the dashed hints don't count; type one set; "Same as last time" fills the rest; no tick on sets; swipe a set away and Undo (Remove set also by TalkBack action); large text keeps stacked rows.
7. Ramadan settings: change the first and last day quickly; both stay (Ramadan dates). Edit a template, press Back: it asks.
8. TalkBack: a weekday target row opens; "Remove set" action on a set row.

## Progress log
- 2026-11-06: card written from the owner's next-UX picks and the Codex settings audit; low-level plan written (planner, lane 3). Awaiting the orchestrator's plan approval and the D-097 number check against A62.

- 2026-11-06: plan amended after the Codex plan review (approve with changes: 6 majors, 4 minors → PA1–PA10); tier Risky; A63 takes D-097 (A62 has D-096). (planner)
- 2026-11-06: WP1 done (ef907c42): D-097 + spec text as approved, TD-115 (identity store; A62 has TD-114), DS FbNoticeRow, FbLetterAvatar, field hideLabel/dashedWhenEmpty (FbDashedInputBorder), dashed placeholder bars (grid colour), FbSwipeActions collapseOnDismiss (PA7, moved from WP2 into the DS commit), FbIcons.sameAsLast. check-dart green; tests written, not run (owner rule). (flutter-engineer)
- 2026-11-06: WP2 done (fa6e2c20): numbers = done (LogSetRow.checked gone, `counts`; toggleSet deleted), fillFromLastTime, removeSet/restoreSet, header row, dashed hints, focus-gated issue, swipe + Undo (KeyedSubtree `workout-set-<id>` in RevealedColumn, FbSwipeActions keyed by restore count). Tests T-W1–T-W8 + PA1 a–c written; also fixed checkbox taps in `app_tabs_test`, `notification_links_test` (3), `acceptance/offline_of01_test` (cross-check finds outside the plan's list). Patrol `offline_test` step 4 → Same as last time. check-dart green. (flutter-engineer)
- 2026-11-06: WP3 done (16de82b6): CaloriesWeekHeader (keys `progress-week-header/-average/-line/-failed/-retry`), WeekSummaryTiles (`weekly-summary-<start>`, `weekly-summary-average`), WeeklySummaryCard deleted, notice rows (`check-in-row`/`check-in-review`, `check-in-applied-row`/`-review`, stale `check-in-dismiss`, `incomplete-day-row`/`-review`, `ramadan-offer-row`/`-review`, `guest-prompt-row`/`-sign-in`), FbNoticeRow gained `actionKey`, Exercise progress subtitle. D8 sweep grep: no further sentence-only `FbCard`s found outside design_preview beyond the plan's list. 15 ARB keys left unused were removed. Tests T-P1, T-P2 (check-in, incomplete, Ramadan), T-P3, T-P5, T-P7 (renamed A40 r7), T-X1 (new `empty_day_hint_test`), T-X2 written; no guest-prompt widget test (provider setup heavy; DS row covered). Goldens expected: `progress_screen`, `today_empty_day`, maybe `app_shell`. check-dart green. (flutter-engineer)
- 2026-11-06: WP4 done (19b1346a): LocalIdentityStore (`fb.identity.v1|<ns>|<key>`; `prune` takes a live-keys callback read inside the queue, so a stale snapshot can't drop a just-saved identity: small strengthening of PA3), `meIdentityProvider` (class `MeIdentity`; the data class is `LocalIdentity`), GoogleCredential, SignInResult/SignedInIdentity (flow methods now return SignInResult; tests use `.outcome`), sign-in done step `sign-in-name` + `sign-in-done`, AccountCard (`account-card-title/-letter/-error`), `account-name` row + sheet (`account-name-field/-save`), `prefs-fixed-facts`. Lifecycle test uses a host that mirrors OpenProfileHost (files, then identity). Tests T-M1–T-M6, T-S9 written. Goldens expected: `account_data_guest`, `account_data_signedIn`, `me_preferences`, `me_settings` (maybe). check-dart green. (flutter-engineer)
- 2026-11-06: WP5 done (abb3df05): majors 1–8 + minors (city, forced-fixed, About, plan-setup in WP3) fixed. Deviations: D19 uses the existing `UnsavedEditsGuard` (PopScope + tab-switch registry) instead of a bare PopScope; editors expose `hasUnsavedEdits()` (riverpod_lint forbids a public notifier getter); `WorkoutActionFailure.storage` added; `setRamadanSeason` kept (tests, acceptance). Keys: `notif-load-failed`, `workout-pick-failed`, `me-targets-failed`, `ramadan-city-retry`, `about-version`. Tests T-S1–T-S8 + checks for the minors (DS `segmented_test`, About size, Ramadan city). check-dart green. Next: WP6 (gen, golden list, Patrol sweep, backlog, trace, board). (flutter-engineer)
- 2026-11-06: WP6 done: `make gen-app` leaves no diff; `make check-dart` green; `make trace` lists UX-047/048, AC-005 with tests. Patrol/integration sweep: `offline_test` step 4 → Same as last time (WP2); `app_test` Progress (`progress-calories-chart` + chart icon), `account_sign_in_test` ('Done', 'Sign in', 'Account & data' rows) and `progress_benchmark_test`/`jank_benchmark_test` keys unchanged: no edits needed; `account_fake_api.dart` implements `credential()`. Backlog #288–#290 (D18 outs + guest-row test). Goldens not regenerated locally (owner rule): expected to change `progress_screen`, `today_empty_day`, `me_settings`, `me_preferences`, `about`, maybe `app_shell`, `account_data_guest`, `account_data_signedIn`. Not done here: T-P6 (post-A62-rebase, orchestrator), board/Outcome. A manual `android-it` run before merge is recommended (Patrol touched). (flutter-engineer)
- 2026-11-06: Codex code review fixes (db98c106, c70f89e2, 47e89d01): (1) picker's A63 group moved into `main()` (no other helper registers tests); (2) goldens regenerated and viewed: `progress_screen`, `today_empty_day`, `me_settings`, `me_preferences`, `about`, `app_shell`, `account_data_guest` (`account_data_signedIn` unchanged); (3) Try again rereads sources: `exerciseLibraryRetryProviders`, `workoutWeekRetryProviders` (in `retryProgress` with weigh-ins, week start, floor acks; the week header uses `retryProgress`), Me targets invalidates `targetsDataProvider`; recovery tests fail the sources under the real derived providers; (4) the account service keeps who signed in (`keepSignedIn` → `onSignedIn`, after the commit) and records `RecentSignIn`; the controller skips a disposed ref; Today shows `sign-in-name-prompt` once when the switch closed the screen; container test with a generation-bumping, delayed activation; (5) `restoreSet` returns `SetRestore.full` at 40 sets with a snackbar (`workoutSetRestoreFull`), boundary test; (6) week sample includes "avg ", header stacks (`progress-week-stacked`) when it doesn't fit, test asserts no clipping at 1.0/2.0. gen-app no diff, check-dart green; tests written, not run (owner rule). (flutter-engineer)
- 2026-11-06: Codex plan review round 2 (task-mw4jaxq9-7mni9e): all 10 resolved; one new major (in-target denominator vs A62 D10) fixed in R1(b) and T-P6 by the orchestrator. Plan ready for owner approval. (orchestrator)
- 2026-11-06: owner approved the plan and its spec decision ("Ok"). Implementation starts. (orchestrator)
- 2026-11-06: merge CI run 42183057345 failed (12 tests, first test evidence). Fixed (1011b7fa, 3d5806cf, 518eede6): **code** - the week average slot was measured without the inherited letter spacing and cut ("avg 2,200 / 2,2…"): measured with the resolved style, `progress_screen` golden regenerated and viewed; **tests** - swipe PA7 row given full width; D15 hidden-label checks match the name the hint is appended to and "not dashed" instead of a null border; Google adapter test reads `credential()?.idToken`; workout C1 row uses a UUID set ID; T-W8 finds the row's `FbReveal` (the keyed child shares the key) and pumps one frame so Undo is this removal's; T-S1 and T-S5 unmount their apps (pending timers); T-M2 sign-in reads the identity store in the fake zone (runAsync hung 10 min). Each failing file re-run green locally; `make gen-app` no diff; `make check-dart` green. Note: `FbNumberSlot` itself measures without inherited letter spacing, so other slots can cut by a pixel: logged for the orchestrator, not changed (golden churn). (flutter-engineer)

## Outcome

_Claude, 2026-11-06. Tier **Risky**, one `flutter-engineer` (Opus), 6 WPs, one local commit per WP, two Codex reviews (code/architecture + security/data) plus one fix-check. Planned L upper end (3.5-4.5 sessions incl. one fix round)._

**What was built**
- **WP1 spec + design system**: D-097 (UX-047, UX-048, AC-005; amends IN-001, WO-034, UX-010), TD-115 (local identity store); DS `FbNoticeRow`, `FbLetterAvatar`, field `hideLabel`/`dashedWhenEmpty` (dashed border), dashed placeholder bars and future bars, `FbSwipeActions.collapseOnDismiss`, `FbIcons.sameAsLast`.
- **WP2 workouts**: sets count by their numbers (no tick; `LogSetRow.checked` and `toggleSet` gone), "Same as last time" per exercise, swipe to remove with Undo (`removeSet`/`restoreSet`), header row, dashed hints, focus-gated issue.
- **WP3 Progress**: week in the calories card (`CaloriesWeekHeader`, tap to the week screen with `WeekSummaryTiles`), `WeeklySummaryCard` deleted, check-in, applied check-in, incomplete day, Ramadan offer and guest prompt as one-line notice rows, Exercise progress subtitle, plan-setup text card removed.
- **WP4 Me identity**: `LocalIdentityStore` (phone only), `meIdentityProvider`, Google credential name, sign-in name step, `AccountCard` with letter circle, name and email, editable name in Account & data, `prefs-fixed-facts` line.
- **WP5 settings audit fixes**: majors 1-8 and minors from the Codex settings audit (Preferences without Energy/Language, load-failed states with Retry, unsaved-edits guard on editors, city retry, About version, forced-fixed rows).
- **WP6 close**: gen-app no diff, `make check-dart` green, `make trace` lists UX-047/048 and AC-005, Patrol sweep, backlog #288-#290.
- **New UI**: one-time Today "What should we call you?" row after a profile-switching sign-in (kept in memory only).

**Reviews**
- Plan: Codex round 1 "approve with changes" (6 major, 4 minor, PA1-PA10); round 2 found one new major (in-target denominator vs A62 D10), fixed by the orchestrator in R1(b) and T-P6.
- Code: Codex code/architecture (3 major, 1 minor) and security/data (2 P2, treated as major): all 6 fixed (picker group moved into `main()`; goldens regenerated; Try again rereads sources; who signed in survives the profile switch; Undo of a removed set respects the 40-set limit; week header sample and stacking). Codex fix-check: "fixes OK", one non-blocking coverage gap (backlog).

**Deviations (Progress log)**
- Lifecycle: `prune` of the identity store takes a live-keys callback read inside the queue (small strengthening of PA3); sign-in flow methods return `SignInResult`.
- D19 uses the existing `UnsavedEditsGuard`; editors expose `hasUnsavedEdits()` (riverpod_lint forbids a public notifier getter); `WorkoutActionFailure.storage` added; `setRamadanSeason` kept.
- No guest-prompt widget test (backlog #290); T-P6 not done in this step (see merge order).
- Extra checkbox-tap fixes found by cross-check: `app_tabs_test`, `notification_links_test`, `acceptance/offline_of01_test`.

**Merge order changed**: A63 merges BEFORE A62 (A62 is still in fixes). A62 rebases onto main and owns the post-rebase semantic checks (T-P6: mixed-estimate / in-target denominator in the Progress week header).

**Measurements**
| Item | Planned | Actual |
|---|---|---|
| Size | L upper end, 3.5-4.5 sessions incl. fix round | 6 WPs + 1 fix round, 19 commits; 119 files, +6707 / -1543 |
| Review rounds | 2 Codex plan reviews, 2 Codex code reviews (Risky) + fix-checks | 2 plan + 2 code reviews + 1 fix-check ("fixes OK") |
| Findings | n/a | 0 blocker / 5 major (3 code + 2 security P2) + 1 code minor; all 6 fixed |

**Tests**: written for T-W1-T-W8 + PA1 a-c, T-P1-T-P3, T-P5, T-P7, T-X1, T-X2, T-M1-T-M6, T-S1-T-S9 and the review fixes. **No local test runs** (owner rule) except targeted golden regeneration; the CI merge run is the first test evidence.

**Goldens changed**: progress_screen, today_empty_day, me_settings, me_preferences, about, app_shell, account_data_guest (account_data_signedIn unchanged); each viewed.

**Not proven yet**: Patrol `offline_test` step 4 (Same as last time) and `account_fake_api` `credential()` changed; the emulator suite has not run, so the next nightly proves them.

**Follow-ups**: backlog #288-#290 plus the three new entries below (40-set test gap, T-P6 moved to A62, name prompt memory-only); owner device checklist above.

**New decisions**: D-097 (spec/decisions.md); TD-115.

**Exit criteria**: all built; tests written, proven by CI at merge; owner acceptance by use (TD-037).
