# S14 — Diary domain & storage

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P1 Manual tracker | S09 | M | ⬜ Not started |

**Goal.** The diary's data model and rules (entries, slots, groups, day marks, copies) as tested domain logic and drift tables, with every write going through change sets. The UI comes in S16.

**Spec:** DY-001, DY-002, DY-003, DY-004 (manual mark), DY-010 (default slots), DY-011, DY-021–024 (data side), DY-023 (copy/save data side), DY-032 (copy op), FD-010, FD-073, SC-4 · **Decisions:** TD-011, TD-017

## Scope
- **Tables:** `diary_entries`, `dish_groups`, `meal_slots` (defaults: Breakfast, Lunch, Dinner, Snacks with time windows), `day_marks`, `saved_meals` + `saved_meal_items` (data only; UI in S17).
- **Entry model:** `local_date`, `occurred_at_utc`, `tz_offset_min`, `slot_id`, `dish_group_id?`, `food_ref`, display name snapshot (EN + AR when present), input amount/unit, grams, **nutrient snapshot**, provenance fields (`05` §1).
- **ChangeOps:** create / update (amount, food, slot, time, day) / delete / move entry, create/update/delete group, copy meal (slot or day → another slot/day, DY-023/032), save meal as saved meal, mark day incomplete.
- **Domain:** `SlotAssigner` (time + windows → slot, DY-011), day totals (kcal, P, C, F, fiber), slot totals, past-day logging (DY-003), entries never move when the time zone changes (DY-002).
- **Repositories:** watch streams for a day, a slot, a date range (for charts later).
- **Domain events:** `EntriesLogged`, `EntryChanged`, `EntryDeleted`, `DayMarked`.

## Out of scope
- Search and adding foods (S15), UI (S16), batches (S37), the incomplete-day *suggestion* (S43).

## Fixed by the plan
- Nutrient snapshots at log time. Editing a food never rewrites history (FD-073).
- All writes via `ChangeSetApplier`, with undo.

## Decide in the low-level plan
- How dish groups relate to slots when entries move (move the group vs split it).
- Indexing for range queries (charts over a year).

## Exit criteria
- [ ] Unit tests: slot assignment at window edges, past-day entries, tz changes not moving entries, totals = sum of snapshots (property test).
- [ ] Data tests: each op + its undo restores the exact state. Copy produces new IDs with the same snapshots.
- [ ] Migration test from the S09 schema version.
- [ ] A day query with 30 entries < 5 ms on the A55.

## Read first
`05-data-and-sync.md` §1–2 · `spec/12-diary-meals-recipes.md` §1–4 · `03-architecture.md` §5

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
