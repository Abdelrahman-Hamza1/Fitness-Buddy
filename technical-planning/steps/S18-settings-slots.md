# S18 — Settings & meal slots

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P1 Manual tracker | S16 | M | ⬜ Not started |

**Goal.** The Me tab and the settings the rest of R1 relies on: units, week start, halal, theme, city, meal slots, and an About page with the required attributions.

**Spec:** UX-010 (Me tab), DY-010, LC-010, LC-012, LC-021, LC-033 (city choice), LC-040, FD-080, UX-040, D-074 · **Decisions:** —

## Scope
- **Me tab structure:** Profile & goals (S20), Targets (S20), Buddy remembers (S36), Account (S25), Settings, About.
- **Settings:** unit system metric/imperial (display only, inputs accept any unit), energy in kcal, week start (default Saturday), halal on/off (default on for the owner, FD-080), theme (system/light/dark), **city** picker from the pack's city list (search by EN/AR name) with an "use my location" option stub (opt-in permission, D-074), notification settings placeholder (S45).
- **Meal slots** (DY-010): rename, add, remove, reorder, set time windows. Changes take effect for new entries and slot assignment (S14). Removing a slot with entries asks where to move them.
- **About:** version, licences, attributions (USDA FoodData Central, GeoNames, later Open Food Facts), a "not medical advice" line (R2 adds the onboarding version).
- All settings stored in `settings_kv` or `profile` via change sets (they sync later).

## Out of scope
- Profile/goals/targets screens (S20). Notification settings (S45). Ramadan settings (S46).

## Fixed by the plan
- Display follows the unit setting. Inputs accept any unit (LC-011).

## Decide in the low-level plan
- City picker UX (search-first list vs map), and the default city.

## Exit criteria
- [ ] Switching to imperial changes all displayed weights/volumes. Stored values are unchanged (test).
- [ ] Slot customisation works, and auto-assignment uses the new windows (integration test).
- [ ] The week start setting changes the week used by `WeekCalendar` (test).
- [ ] Goldens for the settings and slot editor screens.

## Read first
`spec/18-localization-and-culture.md` · `spec/12-diary-meals-recipes.md` §2

## Owner involvement
Set your real settings. Feedback.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
