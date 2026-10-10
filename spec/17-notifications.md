# 17 — Notifications

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-032, D-052, D-074, D-079._

Principles: **configurable, moderate by default, never guilt-tripping** (D-032, PR-8, PR-12).

## 1. Notification types & defaults

| ID | Notification | Default | Default timing | Release |
|---|---|---|---|---|
| NT-001 | **Log reminder**: only fires if fewer than 2 meals are logged today | On | 21:00 | R1 |
| NT-002 | **Pending proposal**: you have something unconfirmed | On | 30 min after it was created, once | R1 |
| NT-003 | **Weigh-in reminder** | On | Weekly, on the user's chosen day, 08:00 | R1 |
| NT-004 | **Weekly review ready** (includes any target proposal) | On | Week start day, 09:00 | R1 |
| NT-005 | **Workout reminder** on planned days | Off | 18:00 | R1 |
| NT-006 | **Protein check**: protein far below target late in the day | Off | 20:00 | R1 |
| NT-007 | **Measurement reminder** | Off | Monthly | R1 |
| NT-008 | **Suhoor reminder**: eat and log suhoor | On during Ramadan | 45 min before Fajr | R1 |
| NT-009 | **Iftar log nudge**: log your iftar | Off | 90 min after Maghrib | R1 |
| NT-010 | **Batch closing**: an open batch is about to auto-close | On | Day before auto-close (DY-044) | R1 |

## 2. Rules

- **NT-020** `[R1]` Every notification can be switched on or off, and its time changed. There's also a master switch.
- **NT-021** `[R1]` **Quiet hours** (default 23:00–07:00) block everything except the suhoor reminder in Ramadan.
- **NT-022** `[R1]` No more than **2 non-Ramadan notifications per day** in total. Lower-priority ones are dropped first (priority: pending proposal > weekly review > weigh-in > log reminder > others).
- **NT-023** `[R1]` Notifications are skipped when they don't apply (e.g. no log reminder if dinner is already logged, no weigh-in reminder if you weighed today).
- **NT-024** `[R1]` Tapping a notification opens exactly the relevant place (pending card, weigh-in pad, review, etc.).
- **NT-025** `[R1]` Wording is neutral and short, e.g. "Anything to log from today?", never "You forgot…" or "Don't break your streak".
- **NT-026** `[R1]` Prayer-time-based reminders use the user's chosen city, or the phone's location if they opted in (D-074).

## Open questions

None currently.
