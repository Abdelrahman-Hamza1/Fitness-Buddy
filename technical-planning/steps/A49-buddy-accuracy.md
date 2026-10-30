# A49 — Buddy accuracy

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App (+ eval) | A23b, **B09b** ✅ | M | Claude | ⬜ Not started |

_New step (owner, 2026-10-30). Phase 2 (TD-105). Tier: Risky (resolver and proposal policy are production code). Owner note: "Buddy could change later on, so it matters less": fix the known misses, don't over-tune._

**Goal.** Close the M3 accuracy gap: the four known-miss groups from B09b's triage are fixed and the AQ gate runs with an empty known-miss baseline.

**Spec:** AI-021, AI-033, AI-103 (D-086), T01–T16, T19, T39–T41 · **Decisions:** TD-097, D-086

## Scope
- **#148** density data so ml amounts convert (with A47).
- **#149** shared dish portions default to one person's typical portion as an assumption with −/+ (D-086, AI-103).
- **#150** a fuzzy-only catalog hit never overrides the model's estimate.
- **#151** an item issue blocks its card, never the whole message.
- Shrink `tools/buddy_eval/cases/aq_known_misses.json` to empty.

## Out of scope
- New Buddy features. Threshold changes (never, TD-097).

## Exit criteria
- [ ] The B09b AQ gate is green with an empty known-miss baseline.
- [ ] Tests for each fix (policy and decoder unit tests).

## Read first
Backlog #148–#151 · B09b card (triage) · TD-097 · `spec/10-ai-assistant.md` §9

## Owner involvement
None (the paid M3 phone run is the A23b/M3 item, run later with the owner).

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: card created (owner decisions 2026-10-30, TD-105).

## Outcome
_Written in Phase E: built · deviations · follow-ups · new TDs · measurements._
