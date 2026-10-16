# B15 — AI eval expansion & tuning

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B09–B12, B14, **A41** | M | Codex | ⬜ Not started |

_Old ID: S47 (renumbered by TD-063, 2026-10-16)._

**Goal.** Prove Buddy is good enough for R1 on a broad, realistic test set, and tune prompts, routing and cost with evidence.

**Spec:** AT-002, AQ-01 to AQ-12 (AQ-11 reported only, D-080), SC-2, SC-3, C-3 · **Decisions:** TD-008

## Scope
- Expand `buddy_eval` to **≥ 150 cases**: more of each category, the owner's real exported misses (TQ-07), ≥ ¼ Arabic/Arabizi in the owner's style, edge cases found in dogfooding.
- Run the full AQ table with per-language breakdowns. **AQ-01** verified by construction tests + E2E (no write without confirm).
- **Tuning loop:** prompt revisions, few-shot examples, routing (model/effort per task), rerank on/off. Every change measured, with cost per message and p90 latency tracked.
- **Cost review:** actual $/message and $/user/month from production metrics vs the estimate (`06` §10). Inputs for R3 allowances (MN-003).
- Re-check provider terms (retention, ZDR path) and record them for R3 (TQ-06).

## Out of scope
- R2 AQ-11 parity work (R2).

## Fixed by the plan
- Thresholds from `spec/40` §2. The eval is the judge, not impressions.

## Decide in the low-level plan
- Which tuning experiments to run first (by largest metric gap).

## Exit criteria
- [ ] ≥ 150 cases. **Every AQ threshold met** (AQ-11 reported). The report is committed.
- [ ] p90 ≤ 5 s from the owner's location on production (AQ-12).
- [ ] The cost per message is recorded in `06` §10 (actuals).

## Read first
`06-buddy-ai.md` §10–11 · `spec/40-acceptance-criteria.md` §2–3

## Owner involvement
Export your real misses. Add messages in your style.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
