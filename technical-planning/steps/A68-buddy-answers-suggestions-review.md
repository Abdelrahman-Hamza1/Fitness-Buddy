# A68 — Buddy answers, suggestions, weekly review & Ramadan (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A66, **B25**, **B26** (weeklyReview, check_fit) | M–L | Claude (Opus build), Codex review | ⬜ |

**Goal.** Buddy answers questions about your data with code-computed numbers, suggests food that fits, writes the weekly review, and speaks Ramadan: spec 10 §10–§12 (AI-110–AI-132), halal (D-064, FD-081/082), the Buddy parts of Ramadan. Replaces A31, A39b and A41b.

## Scope
1. **QueryEngine** in `fb_domain` over the closed QueryPlan grammar (`06` §6) and the `query_data` phone tool; answer links to charts and diary days (AI-112).
2. **Suggestions:** `suggestion` cards (2–4 options, each tap → a food card, AI-121), the app's fit check drops options that don't fit, halal warning check.
3. **Weekly review:** at the week start (D-070) a `weeklyReview` turn with the `WeeklySummary` aggregates; the review card, cached per week, past reviews in the weekly summary (AI-130–132); the attached check-in proposal.
4. **Ramadan:** Ramadan state in the profile; suhoor/iftar wording checked on the A55 on a Ramadan-mode day.
5. **Tests (TD-128):** the confirmation guard for suggestion taps; the QueryEngine is code, so it gets its own small tests where a number could be wrong (AQ-09).

## Exit criteria
1. On the A55: "how much protein left", "avg calories last week", "when did I last do legs" answer with correct numbers and a link; "what can I eat with 600 kcal left" gives fitting options; a weekly review appears and reads in under 30 s.
2. CI green; Codex review passed.

## Lane
Lane 1 (after B26) or lane 2, whichever frees first; touches `fb_domain` and different cards than A67/A69.

## Progress log

## Outcome
