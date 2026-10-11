# S15 — Food search & add flow

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P1 Manual tracker | S07, S13, S14 | M | ⬜ Not started |

**Goal.** Find any food in the offline catalog, your own foods or your history, pick an amount in any unit, and log it with one tap and an undo. This is the manual path that must always work, offline included.

**Spec:** FD-020 (offline part), FD-021, FD-022, FD-023, FD-010, FD-011, FD-060, FD-062, LC-005, LC-011, AI-048, UX-006 (structure), OF-01 (food parts) · **Decisions:** TD-009, D-080

## Scope
- **Search service** (data + domain): FTS5 over `catalog.db` + personal foods + recent/history items, query normalization via `fb_text`, **ranking & de-duplication** (`07` §5.2): yours/recent → verified → reference dishes, one row per distinct food, ties by usage count.
- **Search UI:** one box (EN, Arabic script, Arabizi via listed aliases), instant results as you type, recent foods when empty, food rows with source badge and kcal per default serving.
- **Food detail:** names (interface language + the other on details when present, LC-005), nutrients per 100 g and per serving, state, source badge, sanity status.
- **Amount & unit picker:** number pad, units incl. food-specific servings and local portion words, any unit accepted (LC-011), **defaults to the last used amount for that food** (FD-022). Raw/cooked state choice when relevant, with a yield note (FD-062).
- **Add = direct action:** a `ChangeSet` → applied → undo snackbar (AI-048). Slot assigned automatically, editable.
- Search performance budget and an empty/no-results state ("Try another name, or create your own food" → S17).

## Out of scope
- Online catalog search (S30), barcode (S38), personal food creation (S17).

## Fixed by the plan
- PR-5: never show duplicate clutter. Local results come first. No network needed.

## Decide in the low-level plan
- The ranking formula weights and tie-breakers (documented and unit-tested).
- How "recent foods" are derived (diary history query vs a cache table).

## Exit criteria
- [ ] In airplane mode: search "maqluba", "مقلوبة" and an Arabizi alias → the same single result, add 1 plate, and it appears in the diary data with an undo (integration test).
- [ ] Ranking/dedup unit tests with fixtures (duplicates collapsed, personal first).
- [ ] Search p95 < 50 ms on the A55 with the full pack (measured).
- [ ] Goldens for the search and amount-picker screens.

## Read first
`07-food-data.md` §5 · `spec/11-foods-and-data-quality.md` §1–3 · `spec/30-ux-principles.md` §1, §4

## Owner involvement
Try the flow on the A55 and comment.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
