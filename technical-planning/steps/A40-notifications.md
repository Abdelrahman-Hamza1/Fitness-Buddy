# A40 — Notifications

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A27, A37, A39 | M | Claude | ⬜ Not started |

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
_Written in Phase B._

## Outcome
_Written in Phase E._
