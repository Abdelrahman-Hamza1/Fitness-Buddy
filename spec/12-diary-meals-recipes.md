# 12 — Diary, Meals, Batches & Recipes

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-015, D-016, D-017, D-023, D-044, D-050, D-052, D-072, D-079._

## 1. Days

- **DY-001** `[R1]` A diary day is the **calendar day** in the user's current time zone. Food eaten after midnight counts toward the new day, including suhoor, which counts toward the fasting day (D-052). Any entry can be moved to another day.
- **DY-002** `[R1]` Each entry keeps the local time it was eaten. Travelling across time zones doesn't move past entries.
- **DY-003** `[R1]` Food can be logged for any past day ("yesterday dinner", D-017). Logging for future days (planning): **Later**.
- **DY-004** `[R1]` A day can be marked **"incomplete"** (e.g. "I didn't log everything"). Incomplete days are excluded from adaptive target calculations (`13` §4). The app suggests this marking for days with suspiciously low logged intake (e.g. under 50% of target with fewer than 2 meals). The suggestion is a proposal, never automatic.

## 2. Meal slots (D-050)

- **DY-010** `[R1]` Default slots: Breakfast, Lunch, Dinner, Snacks. The user can rename, add (e.g. "Pre-workout", "Meal 4"), remove and reorder them, and give each a time window.
- **DY-011** `[R1]` A new entry goes into a slot automatically, based on its time and the slot windows. The user can override in the proposal card or later.
- **DY-012** `[R1]` In Ramadan mode the slots become **Iftar, Suhoor, Snacks** (customizable separately). Normal slots return when Ramadan ends (`18-localization-and-culture.md` §4).

## 3. Diary view

- **DY-020** `[R1]` The Today screen shows the day's slots, each with its items, kcal and a compact macro line, plus day totals. Other days are reached by swiping or a date picker (`16-insights-and-home.md`).
- **DY-021** `[R1]` Tapping an item expands it: amount, full nutrients, source badge, assumptions used. Its amount, food, slot and time can all be edited directly (a direct action with undo, AI-048).
- **DY-022** `[R1]` Swiping an item: delete (with undo) or move to another slot.
- **DY-023** `[R1]` A meal can be copied to another day or slot, or saved as a saved meal (§4).
- **DY-024** `[R1]` Items cooked together show grouped under their dish name (AI-020), collapsible.
- **DY-025** `[R1]` Pending (unconfirmed) proposals are never shown as diary entries. They appear only in the "to confirm" strip (AI-045).

## 4. Fast re-logging (D-016)

- **DY-030** `[R1]` **Quick-add chips** above the input bar: the foods and meals you're most likely to log right now (based on time of day, slot and history). One tap logs with undo, so a repeat meal takes ≤ 2 taps (D-060).
- **DY-031** `[R1]` **Saved meals** ("the usual breakfast"): a named group of items, created from any logged meal or by chat. Logging one by tap applies directly. Logging one by chat ("the usual breakfast") goes through a proposal (D-079).
- **DY-032** `[R1]` "Same as yesterday / Monday's lunch" works by chat (proposal) and from the copy action (DY-023).

## 5. Batch dishes (D-044, D-072)

A batch is something cooked once and eaten across several meals or shared with others.

- **DY-040** `[R1]` A batch is created by chat ("cooked a pot: 1kg chicken, 500g dry rice, 2 onions, 3 tbsp oil") or with a form. It records the ingredients (with raw/cooked state) and, optionally, the **cooked total weight**.
- **DY-041** `[R1]` Portions can be logged as: grams of the cooked dish (most accurate, needs the total weight), a fraction ("a third"), a share ("we were 6"), or plates/bowls (estimated from typical portion weights).
- **DY-042** `[R1]` **Quick path**: log the whole batch, or your share of it, now, and be done. The weekly total is what counts, so splitting across days is optional (D-044 weekly-accuracy principle).
- **DY-043** `[R1]` **Leftovers path**: the batch stays **open**, and Buddy understands later references ("leftover chicken rice, a plate"). The remaining amount goes down with each portion.
- **DY-044** `[R1]` An open batch closes when fully eaten, when the user closes it ("threw the rest away"), or automatically after **7 days** (configurable). Open batches show in quick-add chips and suggestions (AI-120).
- **DY-045** `[R1]` A dish cooked by someone else, with unknown ingredients, isn't a batch. It's logged as a reference dish portion (AI-021).

## 6. Recipes (D-023)

- **DY-050** `[R2]` Recipe library: a reusable batch template (ingredients, servings, optional cooked weight). Recipes can be scaled by servings and cooked → becomes a new batch.
- **DY-051** `[R2]` Any batch can be saved as a recipe.
- **DY-052** `[R2]` Recipe import from a URL (D-066): the app reads the page and produces a recipe proposal to confirm (D-079).

## Open questions

None currently.
