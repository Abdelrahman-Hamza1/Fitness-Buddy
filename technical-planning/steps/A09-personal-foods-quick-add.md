# A09 — Personal foods, saved meals & quick-add

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A08 | M | Claude | ⬜ Not started |

_Old ID: S17 (renumbered by TD-063, 2026-10-16)._

**Goal.** The fastest paths for repeat eating: your own foods, named saved meals, and quick-add chips that log a repeat meal in at most two taps, with no AI involved.

**Spec:** FD-070 (form path), FD-071, FD-073, FD-012 (user warning), DY-030, DY-031 (tap path), UX-004, MN-021 · **Decisions:** TD-011

## Scope
- **Personal foods:** a form to create, edit, rename, **merge duplicates** and delete (FD-073: history keeps its logged values). Names, aliases, per-100 g or per-serving entry (converted), servings with grams, brand, barcode(s) field (used by A28). A gentle sanity warning (FD-012).
- **Saved meals:** list, detail, rename, delete. **Log by tap** = a direct action with undo into the chosen slot (DY-031). Created from any logged meal (A08 action).
- **Quick-add chips** (DY-030): a ranking model over history (time of day, current slot, weekday, frequency, recency) producing the top chips (foods, saved meals, and later open batches). One tap logs with the last-used amount + undo. A "+" chip opens search.
- Personal foods appear first in search (A07 ranking) with the ⓨ badge.

## Out of scope
- Creating personal foods by chat or label (A27/A28). Batches (A27).

## Fixed by the plan
- Repeat logging never calls the AI (MN-021). Chips are direct actions, not proposals (D-079).

## Decide in the low-level plan
- The chip ranking formula (documented, unit-tested with scenarios).
- The merge semantics (which food survives, how aliases combine).

## Exit criteria
- [ ] A repeat meal logged in ≤ 2 taps from Today (integration test counts taps) (UX-004).
- [ ] Ranking tests: breakfast chips in the morning, dinner chips in the evening, a frequent item outranks a one-off.
- [ ] Merge test: diary entries referencing the merged food keep their snapshots.
- [ ] Goldens for the personal food form and the chip row.

## Read first
`spec/12-diary-meals-recipes.md` §4 · `spec/11-foods-and-data-quality.md` §8

## Owner involvement
Create your common foods and meals. Feedback on the chips after a few days.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
