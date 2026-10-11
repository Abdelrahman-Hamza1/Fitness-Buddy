# S44 — Weekly summary & Buddy review

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P7 Insights & time | S42, S43 | M | ⬜ Not started |

**Goal.** Each week starts with a clear, kind look back: a deterministic weekly summary (always available, offline) plus a short Buddy review with at most two observations, never making up a number.

**Spec:** IN-001, AI-122 (review exception), AI-130, AI-131, AI-132, WO-043, AI-056 (attached), SF-020, SF-022, PR-6, SC-5, G1 · **Decisions:** TD-009, TD-030

## Scope
- **`WeeklySummary`** in `fb_domain` (IN-001): average calories vs budget, days within target, protein-target days hit, fiber average, trend weight change, workouts done vs planned + PRs (WO-043). Any past week.
- **Weekly summary card** on Progress, the top of the tab (SC-5: one tap from Today).
- **Buddy review** (AI-130): the client sends **aggregates only** → `POST /v1/buddy/review` → ≤ 2 short observations or suggestions, in a factual, kind tone (AI-131, < 30 s to read). Generated at the **next online open** after week start (G1/TQ-04) and cached.
- **NumberGuard** on the phone: every number in the text must exist in the aggregates, else regenerate once, else use a template. **Banned-word check** (SF-020).
- **Check-in proposal** (S43) attached to the review as a card (AI-056).
- **Past reviews** viewable from the weekly summary (AI-132).

## Out of scope
- The "review ready" notification (S45).

## Fixed by the plan
- Numbers come from the summary, never the model. Text only interprets them (`06` §8).

## Decide in the low-level plan
- The review prompt and the fallback templates (EN).

## Exit criteria
- [ ] NumberGuard tests: an injected wrong number → regeneration → template fallback.
- [ ] Eval: ≥ 10 synthetic weeks → no guard failures after regeneration, no banned words, length within the limit. The tone is scored separately (model judge, reported).
- [ ] The summary works offline. The review appears after the next online open (E2E with fixtures).

## Read first
`spec/16-insights-and-home.md` §2 · `spec/10-ai-assistant.md` §12 · `06-buddy-ai.md` §8

## Owner involvement
Read your first real weekly review. Tone feedback.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
