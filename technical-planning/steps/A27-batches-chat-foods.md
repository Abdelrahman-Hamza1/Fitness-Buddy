# A27 — Batches, personal foods & saved meals by chat (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A09, A23, **B09a** (contract) | L | Claude | ⬜ Not started |

_Old ID: S37 app part (renumbered by TD-063, 2026-10-16)._

**Goal.** Home cooking the way it really happens: cook a pot, log your share now or keep it as leftovers to portion later, all by chat or form. Plus creating personal foods and saved meals by just describing them.

**Spec:** DY-040, DY-041, DY-042, DY-043, DY-044, DY-045, AI-054, AI-100, AI-101, AI-102, FD-070 (chat path), DY-031 (chat path), D-044, D-072, T20, T21, T22, T24 · **Decisions:** TD-011

## Scope
- **`batches`** table + domain: ingredients (food ref, grams, state), totals, optional cooked weight, `remaining` (grams or fraction), status open/closed, `auto_close_at` (7 days, configurable).
- **Portions** (DY-041): grams of the cooked dish (with total weight), a fraction, a share ("we were 6"), plates/bowls (typical weights). **Quick path** (DY-042): log the whole batch or your share now. **Leftovers path** (DY-043): keep it open, and later "leftover chicken rice, a plate" consumes from it.
- **Close** (DY-044): fully eaten, "threw the rest away", or auto-close. Open batches appear in quick-add chips.
- **Chat:** a `Batch` intent (B09's contract and prompt; the engine and card here): ingredients list, quick vs leftovers choice, the portion eaten now (T20). References to open batches (`openBatches` in the context, T21). Plain rice batch handling (T22).
- **Form:** create/edit a batch, log a portion (direct action with undo).
- **`PersonalFood` intent** (AI-054, T24-style creation): "my shake is 40g whey + 300ml milk" → a personal-food proposal.
- **Saved meal by chat** (DY-031): "the usual breakfast" → a proposal from the saved meal. "Save this as …" → a saved-meal proposal.
- Distinguish a family-cooked dish with unknown ingredients → reference dish, not a batch (DY-045).

## Handoff from B09a (contract)
Contract: `batch`, `batchPortion`, `batchClose`, `personalFoodCreate`, `savedMealLog`, `savedMealCreate` and the shared `BuddyPortion`, `BuddyStatedNutrients` (B09 card D9, D12, §3.1).
- **Portions:** `share.fraction` is a fraction of the whole batch (for `eatenNow` and `batchPortion`). `batchPortion` carries exactly one of a non-null `portion` or `rest: true` ("ate the rest"). `batchClose` closes the batch without logging anything (thrown away, DY-044). The app owns the remaining arithmetic.
- **Stated values (TD-092):** `stated` prefills the personal-food review form with FD-012 highlighting and the ⓨ "from your message" source; never a one-tap confirm. The server never fills kcal. `basis` is `per100g`, `per100ml` or `perServing`.
- **Estimates** inside `personalFoodCreate.components` or batch `ingredients` keep their badge and are review-only.
- `savedMealCreate.name` is never null (a nameless "save this" is clarified); exactly one source: `activeProposal`, `targets` or `source`.
- Exit criteria to add (B09 PA11): engine-level T20–T22, T24 creation.

## Out of scope
- The batch-closing notification (A40). Recipes (R2).

## Fixed by the plan
- The weekly-accuracy principle: splitting a batch across days is optional (D-044).

## Decide in the low-level plan
- How `remaining` is tracked when portions mix grams and fractions.

## Exit criteria
- [ ] T20, T21, T22, T24 work end to end with recorded fixtures (the eval is B09's).
- [ ] Domain tests: remaining decreases correctly across mixed portion types. Auto-close at 7 days (fake clock). A closed batch rejects portions.
- [ ] E2E: cook a pot by chat → log ⅓ → next day "leftovers, a plate" → remaining updated.

## Read first
`spec/12-diary-meals-recipes.md` §4–5 · `spec/10-ai-assistant.md` §9

## Owner involvement
Use it for a real batch cook.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
