# 30 — UX Principles

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-035, D-039, D-043, D-060, D-079._

The product principles (PR-1 to PR-12 in `00-vision-and-scope.md`) apply everywhere. This file turns them into concrete interface rules.

## 1. Speed targets (D-060, D-079)

| ID | Action | Target |
|---|---|---|
| UX-001 | Open app → input bar ready to type | ≤ 2 s |
| UX-002 | Send a food message → proposal card shown | ≤ 5 s in 9 of 10 cases (skeleton card immediately) |
| UX-003 | Confirm a proposal | 1 tap |
| UX-004 | Log a repeat meal (quick-add chip) | ≤ 2 taps, no AI wait |
| UX-005 | Log a weigh-in | ≤ 3 taps |
| UX-006 | Barcode scan → logged (known product) | ≤ 3 taps after the scan |
| UX-007 | Any screen interaction | Responds instantly; no blocking spinners for local data |

## 2. Navigation

- **UX-010** `[R1]` Four tabs: **Today** (home), **Progress**, **Workouts**, **Me** (profile, goals, targets, "Buddy remembers", settings).
- **UX-011** `[R1]` The input bar lives on Today and Workouts. Typing opens Buddy's chat as a **bottom sheet**, so the screen behind stays visible and its numbers update live when a proposal is confirmed.
- **UX-012** `[R1]` The chat sheet can be pulled up to full height to see history, or swiped down to dismiss. Pending proposals survive dismissal (AI-045).
- **UX-013** `[R1]` Nothing important is more than **2 taps** from Today.

## 3. Proposal card pattern (D-079)

- **UX-020** `[R1]` One consistent card design for every proposal type (food, edit, delete, weigh-in, workout, import, target change). The parts are always in the same order: what → details → assumptions → totals/impact → actions.
- **UX-021** `[R1]` One clear primary action ("Log it" / "Save" / "Apply"), visually dominant. "Discard" is secondary.
- **UX-022** `[R1]` Adjustments happen **on the card itself** (inline number pad, chips, swipe). They never open a separate full-screen form.
- **UX-023** `[R1]` The keyboard stays available while a card is open, so a follow-up correction can be typed immediately (AI-044).
- **UX-024** `[R1]` What changed after an adjustment is briefly highlighted.
- **UX-025** `[R1]` Confirming gives light haptic feedback and a short animation of the numbers updating on the screen behind.
- **UX-026** `[R1]` Edits and deletions show **before → after**. Deletions show what will disappear.

## 4. Direct actions & undo

- **UX-030** `[R1]` Direct actions (AI-048) apply immediately and show an **undo** snackbar for 5 seconds. Destructive bulk actions (delete a day, delete account) need confirmation instead.

## 5. Visual direction (D-035, D-039)

- **UX-040** `[R1]` Light and dark themes, following the system by default.
- **UX-041** `[R1]` **Clean, not empty**: generous spacing, few colours, large key numbers, secondary information present but quieter. No clutter, no ad slots, no upsell banners.
- **UX-042** `[R1]` Colour carries meaning consistently (e.g. one colour per macro across all screens). Over-target is a neutral tone, never alarm red (SF-021).
- **UX-043** `[R1]` A modern look: the opposite of the dated look the owner disliked in MyFitnessPal and Cronometer (D-039).
- **UX-044** `[R1]` Source badges and estimate markers (FD-010, AI-032) are small and consistent, and readable without a legend once learned. A legend is available on tap.

## 6. States

- **UX-050** `[R1]` Every screen has a designed **empty state** that tells the user what to do ("Tell Buddy what you had for breakfast").
- **UX-051** `[R1]` Loading uses skeletons, not blank screens or full-screen spinners.
- **UX-052** `[R1]` Errors say what happened and what to do, in plain language. Nothing the user typed is ever lost because of an error.
- **UX-053** `[R1]` Offline and pending states are visible but calm (AC-013, AC-020).

## 7. Onboarding

- **UX-060** `[R1]` R1 (owner): minimal setup: profile (TG-001), goal (TG-010/011), units, halal, week start, city. Under 2 minutes.
- **UX-061** `[R2]` R2: guided onboarding for new users: the same steps plus age gate (SF-001), health questions (SF-002), a short "how logging with Buddy works" demo with a sample proposal card, and optional paste-import of weight history (WB-030).

## 8. Accessibility

- **UX-070** `[R1]` Supports system text size scaling without breaking layouts.
- **UX-071** `[R1]` Colour contrast meets WCAG AA in both themes. Meaning is never carried by colour alone.
- **UX-072** `[R2]` Screen reader labels for all controls, in English and Arabic.

## 9. Quick entry outside the app

- **UX-080** `[R2]` Home-screen widget: today's remaining calories + a tap target that opens the input bar.
- **UX-081** `[R2]` Share sheet: share a photo, text or URL into Fitness Buddy → it arrives as a Buddy message (a proposal follows).

## Open questions

None currently.
