# A39 — Weekly summary & Buddy review (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A39a: A37c, A38; A39b: A39a, A23b, **B12** (contract) | A39a M + A39b S (split 2026-10-30) | Claude | ⬜ A39a (wave 4) · ⬜ A39b (phase 2) |

_Old ID: S44 app part (renumbered by TD-063, 2026-10-16)._

**Goal.** Each week starts with a clear, kind look back: a deterministic weekly summary (always available, offline) plus a short Buddy review with at most two observations, never making up a number.

**Spec:** IN-001, AI-122 (review exception), AI-130, AI-131, AI-132, WO-043, AI-056 (attached), SF-020, SF-022, PR-6, SC-5, G1 · **Decisions:** TD-009, TD-030

## Split (2026-10-30, TD-105)
- **A39a Weekly summary** (phase 1, wave 4): `WeeklySummary` in `fb_domain`, the summary card on Progress, past weeks, the A38 check-in proposal attached to the summary. Workouts "done vs planned" only when there's a plan (D-085). Works fully offline, no Buddy.
- **A39b Buddy weekly review** (phase 2): `POST /v1/buddy/review` (B12), NumberGuard, banned-word check, caching, past reviews.

## Scope
- **`WeeklySummary`** in `fb_domain` (IN-001): average calories vs budget, days within target, protein-target days hit, fiber average, trend weight change, workouts done vs planned + PRs (WO-043). Any past week.
- **Weekly summary card** on Progress, the top of the tab (SC-5: one tap from Today).
- **Buddy review** (AI-130): the client sends **aggregates only** → `POST /v1/buddy/review` (B12) → ≤ 2 short observations or suggestions, in a factual, kind tone (AI-131, < 30 s to read). Generated at the **next online open** after week start (G1/TQ-04) and cached.
- **NumberGuard** on the phone: every number in the text must exist in the aggregates, else regenerate once, else use a template. **Banned-word check** (SF-020).
- **Check-in proposal** (A38) attached to the review as a card (AI-056).
- **Past reviews** viewable from the weekly summary (AI-132).

## Out of scope
- The "review ready" notification (A40).

## Fixed by the plan
- Numbers come from the summary, never the model. Text only interprets them (`06` §8).

## Decide in the low-level plan

## Exit criteria
- [ ] NumberGuard tests: an injected wrong number → regeneration → template fallback.
- [ ] With B12's recorded fixtures: a review passes the NumberGuard and the banned-word check, or falls back to the template. (The ≥ 10-week eval is B12's.)
- [ ] The summary works offline. The review appears after the next online open (E2E with fixtures).

## Read first
`spec/16-insights-and-home.md` §2 · `spec/10-ai-assistant.md` §12 · `06-buddy-ai.md` §8

## Owner involvement
Read your first real weekly review. Tone feedback.

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: split into a/b (TD-105, owner).

## Outcome
_Written in Phase E._
