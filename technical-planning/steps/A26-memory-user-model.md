# A26 — Memory & user model (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A23, **B09** (contract) | M | Claude | ⬜ Not started |

_Old ID: S36 app part (renumbered by TD-063, 2026-10-16)._

**Goal.** Buddy gets to know the user (the owner's "mental model" idea, TQ-07): it remembers what was said or confirmed, learns habits from confirmed data, offers to remember repeated answers, and shows everything openly so it can be edited. Fewer questions, better guesses.

**Spec:** AI-055, AI-065, AI-080, AI-081, AI-082, AI-083, AI-084, AC-032, T03, T25 · **Decisions:** TD-032

## Scope
- **`memory_items`** (explicit and learned kinds: default, portion, alias, brand, nickname, personal-food link, habit) + **`answer_log`** + **proposal outcomes** (confirmed unchanged / adjusted chips / discarded).
- **`UserModel`** in `fb_domain` (`06` §5): deterministic habits from **confirmed** data only (AI-081): usual foods per slot/weekday, usual portions per food, usual cooking fat, usual dish variants, usual brands, typical meal times.
- **Using it:** the ProposalEngine applies defaults (no question when a default settles it, T03, with chips labelled "your default"). The context builder sends the **relevant slice** (≤ ~20 items) with each request. Quick-add chips and search ranking use habits (AI-083).
- **Offer to remember** (AI-065): the second identical answer to the same question kind → a memory proposal attached to the card. **`Memory` intent** for explicit statements ("remember i always weigh rice raw", T25, AI-055).
- **Weighing nudge** (AI-084): at most once per food per month, for estimated foods logged weekly or more.
- **"Buddy remembers" screen** (AI-082, AC-032): plain-language list grouped by kind. Edit, delete, and see where each item came from. Learned habits are shown as "Buddy noticed…" and are used as defaults **only after the user accepts** them.
- **Eval export** (TQ-07): an action exporting discarded/edited proposals as anonymised eval case drafts (user-initiated only).

## Out of scope
- Q&A and suggestions (A31), which consume the model.

## Fixed by the plan
- No hidden, model-written profile. Nothing remembered in secret. Learning from confirmed data only (TD-032).

## Decide in the low-level plan
- Habit thresholds (how many confirmations make a habit) and decay for old habits.

## Exit criteria
- [ ] T03 and T25 work end to end with recorded fixtures (the eval is B09's). The second identical answer triggers the offer (test).
- [ ] Property: unconfirmed or discarded proposals never change the user model (test).
- [ ] Deleting a memory item immediately stops it being used (test).
- [ ] Goldens for "Buddy remembers".

## Read first
`06-buddy-ai.md` §5 · `spec/10-ai-assistant.md` §7

## Owner involvement
Review what Buddy has learned after a week. Confirm TQ-07.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
