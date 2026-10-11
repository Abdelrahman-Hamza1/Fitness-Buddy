# S16 — Today screen & diary UI

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P1 Manual tracker | S15 | L | ⬜ Not started |

**Goal.** The home screen as specified: the day's numbers on top, the diary by slot, quick editing of anything logged, and day navigation. Targets are placeholders until S20.

**Spec:** HM-001 (layout; real targets in S20), HM-007, HM-008 (layout), HM-009, AI-072, DY-020, DY-021, DY-022, DY-023 (UI), DY-024, UX-013, UX-030, UX-050, UX-051, UX-052, AI-001 (input bar placement) · **Decisions:** TD-011

## Scope
- **Today layout** (`spec/16` §1): date header with ‹ ›, the big number area (eaten kcal until targets exist), macro line, slot sections with items, kcal and a compact macro line per slot, day totals.
- **Bottom area:** the quick-add chip row placeholder (filled in S17), the **input bar shell** with camera and barcode buttons (behaviour in S33/S38). Tapping the barcode/camera buttons shows "coming soon" in dev builds only.
- **Item expand** (DY-021): amount, full nutrients, source badge, assumptions, and direct edits of amount / food (via search) / slot / time, and **override a nutrient value** (recorded as "edited by you", AI-072). All direct actions with undo.
- **Swipe** (DY-022): delete (undo) or move to another slot.
- **Dish groups** (DY-024): collapsible under the dish name.
- **Meal actions** (DY-023): copy a meal to another day/slot, save as a saved meal (list UI in S17).
- **Day navigation** (HM-009): swipe left/right, date picker. Past days use the same layout.
- **States:** empty day ("Tell Buddy what you had for breakfast" + search), skeletons only where needed, offline/pending banners (calm, UX-053).
- Add-food entry points: "+" per slot → search (S15) with that slot preselected.

## Out of scope
- Targets, remaining calories, weekly line (S20). Weight card (S21). Pending strip (S34). Workout hint (S42).

## Fixed by the plan
- Nothing important more than 2 taps from Today (UX-013). Direct actions apply immediately with a 5 s undo (UX-030).

## Decide in the low-level plan
- The editing interaction for time and slot (sheet vs inline).
- How day navigation pages are cached for instant swipes.

## Exit criteria
- [ ] Integration test (airplane mode): add items to two slots, edit an amount, move one, delete one, undo, copy breakfast to tomorrow. Totals are correct after each step.
- [ ] Goldens: an empty day, a full day, an expanded item, a dish group (light/dark, scale 2.0).
- [ ] Today renders in < 100 ms from tap on the A55 with 30 entries (measured).
- [ ] The owner logs one real day manually on the A55 and gives feedback.

## Read first
`spec/16-insights-and-home.md` §1 · `spec/12-diary-meals-recipes.md` §3 · `spec/30-ux-principles.md`

## Owner involvement
Use it for a day. Feedback.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
