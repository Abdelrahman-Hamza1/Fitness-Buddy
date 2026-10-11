# S33 — Chat sheet & proposal card

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P4 Buddy core | S16, S31, S32 | L | ⬜ Not started |

**Goal.** The most important interaction in the app: type what you ate → a proposal card appears within seconds → adjust with taps or a follow-up sentence → one tap to log. It must feel instant and never like filling in a form.

**Spec:** AI-001, AI-030, AI-031, AI-032, AI-033, AI-034, AI-035, AI-036, AI-037, AI-040, AI-041, AI-042, AI-043, AI-044, AI-140, AI-143, UX-002, UX-003, UX-011, UX-012, UX-020–026, HM-008 · **Decisions:** TD-011, D-079, D-080

## Scope
- **Input bar** (AI-001, HM-008) on Today (and Workouts in S42): focus opens the **chat bottom sheet** (UX-011) over the current screen, with the numbers behind it still visible. Pull up to full height for history, swipe down to dismiss (UX-012).
- **Send:** the message is saved first (the full lifecycle is in S34), the **skeleton card** appears immediately (AI-030), then the interpret call runs → the ProposalEngine builds the draft → the card renders.
- **Food proposal card** (`spec/10` §4.1, UX-020): slot · time, dish name, item lines (name, amount + unit, kcal, source badge), estimate markers with a range sheet (AI-032), **assumption chips** (AI-033), **in-card questions** with answer chips (AI-034, AI-063), totals + "today after this" (AI-031), primary **Log it** and secondary **Discard**.
- **Adjusting:** tap an amount → inline number pad + unit picker (AI-040). Tap a name → up to 3 alternatives + search (AI-041). Swipe to remove, "+ add item" by text or search (AI-042). Tap slot/time (AI-043). **Follow-up typing updates the open card** (AI-044, UX-023) with the change highlighted (UX-024).
- **Confirm:** the ChangeSetApplier writes it, the card collapses to "logged ✓" + a one-line reply (AI-140, **English per AI-143**), the numbers behind animate (UX-025), haptics, undo available (AI-035).
- **Discard** (AI-037). Nothing counts until confirmed (AI-036).
- Reply templates in ARB (EN), checked against the SF-020 banned words.

## Out of scope
- Offline queue, pending strip, failure states (S34). Other proposal kinds (S35+). Camera/barcode buttons' behaviour (S38/S39).

## Fixed by the plan
- One consistent card layout for all proposal kinds (UX-020). Adjustments happen on the card, never in a separate form (UX-022).

## Decide in the low-level plan
- Card component structure so later kinds (edit, delete, weigh-in, workout, import, target change) reuse it.
- Keyboard/sheet interaction details on Android.

## Exit criteria
- [ ] **Journeys J1, J2, J3** pass as patrol E2E tests against the local API with recorded AI fixtures.
- [ ] A follow-up "make it 2 eggs" updates the same card with a highlight (test).
- [ ] Goldens for the card states: loading skeleton, with question, with estimate, after confirm (light/dark, scale 2.0).
- [ ] On the A55 against staging: message → card p90 ≤ 5 s over 20 real messages (recorded).
- [ ] The owner logs real meals for 2–3 days and gives feedback.

## Read first
`spec/10-ai-assistant.md` §4 · `spec/30-ux-principles.md` §2–3 · `spec/01-personas-and-journeys.md` J1–J3 · `03-architecture.md` §5–6

## Owner involvement
Daily use + feedback. This is the moment the core value appears.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
