# A21 — ProposalEngine

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A07, A12, **B02** | L | Claude | ⬜ Not started |

_Old ID: S32 (renumbered by TD-063, 2026-10-16)._

**Goal.** The deterministic heart of Buddy on the phone: turn an interpretation into a proposal draft (numbers, assumption chips, at most two questions, "today after this") and recompute instantly on every tap, with no network and no AI cost.

**Spec:** AI-020, AI-021, AI-022, AI-023, AI-031, AI-032, AI-033, AI-034, AI-040–043 (recompute side), AI-060, AI-061, AI-062, AI-063, AI-064, AI-101 (shares), FD-060, FD-061, FD-062, D-072, AQ-04, AQ-05, AQ-06, AQ-07, AQ-08, AQ-10 · **Decisions:** TD-009

## Scope
- **`ProposalEngine`** in `fb_domain` (`06` §3.3):
  1. Resolve each dimension: stated → saved default (memory, from A26. Empty for now) → question candidate.
  2. Compute kcal per option. **Ask only if** the options differ by > 20% **and** > 50 kcal (thresholds from `/v1/config`). Keep **≤ 2 questions**, ranked by kcal impact. The rest become chips with defaults.
  3. Yields when the stated state ≠ the matched state, with the note.
  4. Cooking fat as its own line, the "all oil eaten" / "most oil left in the pan" chip (FD-061).
  5. Shares ("we were 6", fractions, plates).
  6. Totals (kcal, P, C, F, fiber) + **"today after this"** from local diary + targets.
  7. Estimate ranges (reference dish portion ranges, AI estimate ranges).
  8. **Draft `ChangeSet`** (entries + dish group).
- **Recompute API:** pick a chip option, answer a question, change an amount/unit, swap the food (alternatives or a search result), remove/add an item, change slot/time. Each returns a new draft + a **diff** (what changed, for UX-024 highlighting).
- **Proposal model** persisted in `proposals` (pending), with the interpretation and the draft as JSON.
- **For the eval:** a small, documented `fb_domain` entry point (interpretation in → draft + metrics-relevant fields out) that B09 wires into `buddy_eval` for the full AQ metrics.

## Out of scope
- UI (A22). Edits/deletes/other kinds (A25+). Memory defaults (A26 plugs in).

## Fixed by the plan
- Thresholds and the question budget are code + config, never prompts. AQ-08 must be impossible to violate.

## Decide in the low-level plan
- Data structures for dimensions and chips, so every proposal kind (later steps) can reuse them.
- How "today after this" behaves with rebalancing (today's target uses the A12 engine).

## Exit criteria
- [ ] **Property tests:** never more than 2 questions. Recompute is idempotent. Totals = sum of lines. Removing then re-adding an item restores the totals.
- [ ] Unit tests for T01–T06 and T09/T10 style scenarios (oil line, raw/cooked question, defaults suppressing questions per T03).
- [ ] Recompute ≤ 50 ms on the A55 for a 6-item card (measured).
- [ ] Scenario tests for the AQ-04/05/06/07/08/10 rules on recorded interpretations (the eval-level thresholds are checked at milestone M3, run by Codex).

## Read first
`06-buddy-ai.md` §3–5 · `spec/10-ai-assistant.md` §3–6 · `spec/40-acceptance-criteria.md` §2–3

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
