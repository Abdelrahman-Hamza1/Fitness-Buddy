# B26 — Buddy agent breadth (server): workouts, body, imports, label, weekly review, Ramadan; interpret retired

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B25, **A66** (for the interpret removal) | M–L | Claude (Opus build), Codex review | ⬜ |

**Goal.** The rest of the server Buddy (spec 10 §4.6, §8, §11–§12, `15` §4, `14` §4, RM): the action tools and modes B25 left out, and the retirement of the one-shot interpret path (TD-128). Replaces the server halves of B10b, B11 and B12.

## Scope
1. `exercise_search` (library + aliases in the cached prompt part, custom names via `read_workouts`) and `propose_workout` (sets, per-dumbbell semantics hints, the deterministic set-notation parser cross-check WO-030–033) → `workout` intent.
2. `propose_measurement` → `measurement`; `propose_import` (pasted rows: date, value, unit?, original text) → `importRows`.
3. `check_fit` for suggestions; halal flag honoured in `search_foods`/`suggest_foods`.
4. `POST /v1/buddy/label`: one structured vision call → `LabelExtraction` (basis, serving, nutrients, name guess, per-field confidence), Usage-counted, content-free logs.
5. `mode: weeklyReview`: aggregates only, no phone tools, ≤ 2 observations, NumberGuard, banned words, optional attached check-in proposal passthrough.
6. Ramadan: `profile.ramadan` context and wording in `agent-v1` (suhoor/iftar slots, fasting-day phrasing).
7. **Retire interpret** once A66 is on `main`: remove `/v1/buddy/interpret` (contract, endpoint, prompt, parser, replay store columns no longer used via a forward migration), `tools/buddy_eval`, the CI `eval` job and `check-buddy-eval.py`; keep the resolvers.

## Exit criteria
1. Each new tool and mode produces its intent or event in a scripted laptop run (shared live budget with B25/A66, ≤ 3 requests).
2. CI green with interpret and buddy_eval gone; no dangling references (`cross-check`).
3. Codex review passed.

## Lane
Lane 1 (backend), after B25. Its contract additions for label/weeklyReview merge early if A68/A69 wait for them.

## Progress log

## Outcome
