# A71 — Home-screen widgets (app, Android)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A70 (`BuddyEntry` voice mode, for the Speak button only) | M | Claude (Opus build), Codex review (code + security) | 🟨 |

**Goal.** Three Android home-screen widgets that show today at a glance and open the app (UX-080, UX-082–085, D-101). Design: the owner's canvas (boards "On the home screen", "Small, numbers only", "Sizes and states"; the dark look is the pick; https://claude.ai/artifact/J4SeT5YnJzhY8McY4PLx4k).

## Scope
1. **Medium 4 × 2:** calories-left ring ("1,240 kcal left", over target in the neutral over tone), "eaten of target", protein/carbs/fat/fiber bars against targets (macro colours), buttons Speak · Ask · Weigh.
2. **Small 2 × 2:** ring + protein bar. **Small 2 × 1:** Speak · Ask icons.
3. Light/dark follow the phone (Ink & Sky palettes). Native Android widget (Jetpack Glance or RemoteViews, chosen in the plan) fed by the app through a bridge plugin (chosen in the plan); the widget never opens the database.
4. Taps only open the app (UX-083): Speak → Buddy listening (A70 `BuddyEntry.voice`; until A70 merges, keyboard), Ask → Buddy keyboard, Weigh → weigh-in, numbers → Today. Explicit intents only: no new exported deep-link intent filter; the only new exported component is the widget receiver the platform requires.
5. Refresh on every change to today's intake/targets and at midnight; no targets → calories eaten. Profile switch shows the active profile; sign-out / remove / delete clears the numbers. "Hide numbers" setting (buttons only).
6. Tests (lean): the snapshot the app writes (numbers, hidden, cleared) and the tap routing.

## Exit criteria
1. On the A55: add each widget, log a meal → numbers update; tap each button → the right screen; hide numbers; sign out → numbers gone.
2. CI green; Codex code + security review passed.

## Lane
Lane 2.

## Progress log
- 2026-11-07: card written from D-101; engineer briefed (plan in this card, then build).
