# A51 — First run, sign-in screens & Me overhaul

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A13b, A33, A50 ✅ | L | Claude | ✅ Closed, awaiting merge |

_New step (UX overhaul 2026-10-31, owner-approved sketches; lane 1 of A51/A52/A53). Tier: Normal (UI; no contract, schema or sync change) → one combined Codex code + UX review. Estimate: 7–10 h including one fix round._

**Goal.** A fresh install opens on a short, skippable first run (welcome → goal → about you → activity → training → your plan → optional account); the sign-in screens are benefit-led with a branded Google button and a 6-box code entry; Me becomes an account card, a targets summary and grouped subpages.

**Spec:** UX-010, UX-060, AC-001, AC-002, TG-001, TG-010, TG-021 · **Decisions:** D-088, TD-110 · **Sources:** `~/work/ux-sketches/project/{Main,K2Goal,K3Body,K4Train,K5Result,K6Account,Me,MeAccount,SignUp,SignUpCode}.dc.html`, `~/work/ux-sketches/research.md` §3–5.

## Scope
1. **First run** (fresh installs only): welcome, then the question screens, one topic each, segmented progress bar, Skip on every question, Back keeps answers, one change set at "Looks good" (undoable), optional account step last. "I want a plan" opens the starter plans afterwards.
2. **Setup from the existing entry points** (Today card, Me, Targets empty state, Profile & goal): the same question screens without welcome and account.
3. **Sign-in screens** restyled (email step, code step); flow, states, conflict and errors unchanged.
4. **Me**: account card, targets summary, grouped rows → subpages (Targets & goal, Food & meals, Workouts, Ramadan, Preferences, Notifications, Account & data, Help & about). Nothing lost.

## Out of scope
- Starter-plans content and the training-days question (A52). Targets per weekday and food-name language (A53).
- Storing the account email/name on the phone (A33 keeps none; the card shows the state, see D7).

## Decisions

| # | Decision | Reason |
|---|---|---|
| D1 | **Gate (TD-110):** after the first frame the bootstrap asks `FirstRunGate`; it shows `/welcome` only when the device marker `fb.first_run.v1` is unset **and** the active profile is a guest with no profile row, diary entry, weigh-in, workout or personal food. Otherwise it sets the marker and does nothing. The marker is set when the user leaves the welcome screen by any button. | UX-001 (no storage before the first frame), no startup redirect, existing installs never see it. A device marker (shared preferences) survives a profile switch. |
| D2 | **Pages:** `goal, you, activity, training, plan, account`. You/activity show only for lose/keep/gain; plan only when every input is answered and valid; account only in the first run. The bar counts the pages on the current path. | Ask only what unlocks something (research §3); "just see what I eat" and skipped answers mean no targets, never invented data. |
| D3 | **Skip** marks a page skipped and moves on (typed text kept for Back). Skipping goal, you or activity → no plan page, nothing written. | Brief: no targets without the inputs; Today keeps "Set up your targets". |
| D4 | **Goal page = four cards.** Lose / keep / gain use `GoalDraft.withType` (0.5 kg or 0.25 kg a week prefilled, as today). "Change the numbers" on the plan page opens a sheet with the existing `GoalForm` (pace, target weight, date) and the activity options. | Reuse of today's goal logic; detail on demand (owner: "we make a suggestion, then the user adapts"). Per-day numbers stay A53's Targets. |
| D5 | **Save** at "Looks good" = today's `completeSetup` change set + Undo snackbar. First run: then the account page; "Not now"/sign-in finish. Finish goes to Today, or to the starter plans for "I want a plan". The week-start/halal/city page leaves setup: its stored values pass through unchanged. | One change set (D10 of A13); preferences live in Preferences and Ramadan. |
| D6 | **Sign-in:** same `SignInController`; adds `resend()` and `changeEmail()`. Code entry = 6 boxes over one hidden field (paste fills all, auto-submits at 6 digits). Resend countdown 30 s on the screen (view state). "Keep using without an account" pops. | Presentation only; resend reuses `submitEmail`. |
| D7 | **Account card** shows the state ("Guest · Data on this phone only, not backed up" / "Signed in · <sync status>"), no name or email. | A33 stores no email or name on the phone (privacy); adding one is a data decision outside this step. |
| D8 | **Me subpages** are routes nested in the Me tab (`/me/targets-goal`, `/me/food`, `/me/workouts`, `/me/preferences`, `/me/account`). Workouts rows `go` to the existing Workouts-tab routes. City moves to Ramadan only (it already has the row); halal moves to Food & meals. | Lossless; one place per setting. |
| D9 | **New design-system parts:** `FbStepBar` (segmented progress), `FbChoiceCard` (icon, title, subtitle, selected), `FbSegmented` (two-way switch), `FbCodeBoxes` (6 boxes), `FbGoogleButton` (Google's neutral branded button; its colours are Google's, kept inside the component) and a few icons. | Screens use only design-system parts. |

## Work packages
1. WP1 docs: card, board row, D-088, spec (UX-010, UX-060), TD-110.
2. WP2 design system: D9 components + tests.
3. WP3 setup flow view model (pages, skip, training, finish) + tests.
4. WP4 setup screens (question pages, plan, account page) + tests/goldens.
5. WP5 first-run gate, welcome screen and routes + tests.
6. WP6 sign-in screens + tests/golden.
7. WP7 Me overhaul + subpages + tests/goldens; test helpers for Me rows.
8. WP8 device tests (patrol/integration disable the gate), cross-check, Codex review, fixes, outcome.

## Tests
- `setup_flow_test`: UX-060 path with skip/back, save + undo, "just see what I eat" writes nothing, "I want a plan" opens starter plans, offline, text scale 2.0.
- `first_run_test`: UX-060 fresh install shows welcome; existing data/marker never; skip sets marker.
- `sign_in_screen_test`: AC-001 code boxes paste/auto-submit, resend countdown, change email, conflict still works.
- `me_screen_test`: UX-010 every former Me destination reachable from the new Me.
- DS component tests; goldens: welcome, goal page, plan page, sign-in email + code, Me.

## Progress log
- 2026-10-31: card written; WP1 docs (D-088, TD-110, board rows) committed.
- 2026-10-31: WP2 design-system parts; WP3–5 question screens, first-run gate and welcome; WP6 sign-in; WP7 Me + subpages; WP8 device tests disable the gate. Local runs: touched test files, acceptance sweep, analyze clean. Codex review started.
- 2026-10-31: Codex combined review: no blockers, four majors (first-run gate too narrow for upgrades; gate could replace a sheet; Google button had no TalkBack tap; Welcome's sign-in listener could bypass the account step) and one minor (skipped training still opened the starter plans). All five fixed with tests; no major left, so no fix-check (orchestrator wrap-up). Merged origin/main (A52).

## Outcome
- Built: first-run gate (TD-110) + welcome; question screens (goal, about you, activity, training, plan, account) with step bar, Skip, Back keeping answers, one undoable change set at "Looks good", "Change the numbers" sheet (goal pace + activity), starter plans after "I want a plan"; sign-in restyle (Google button, email, 6 code boxes, resend countdown, change email, keep using without an account); Me = account card + targets summary + grouped subpages (Targets & goal, Food & meals, Workouts, Ramadan, Preferences, Notifications, Account & data, Help & about).
- Deviations: no week-start/halal/city page (D-088); training days not asked (A52's plan flow); no name/email on the account card (D7, backlog #274); no "Open email app" and no Privacy row (backlog #273); Workouts rows switch to the Workouts tab.
- Deferred: backlog #272 (starter plans lost after signing in to an existing account during the first run), #273, #274.
- Device tests (Patrol, integration) turn the gate off; the merge run should include the emulator job.

