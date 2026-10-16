---
name: owner-update
description: Produce a short, mobile-friendly status report for the Fitness Buddy owner: where we are on the board and milestones, what changed since the last update, risks, open questions and what's needed from them. Use every ~5 steps, at milestones, at the end of a long session, or when the owner asks "where are we?" / "status".
---

# Owner status update

## Gather
1. `technical-planning/steps/README.md` §4: count ✅ / 🟨 / 🟦 / ⬜ per phase. The current step and its phase.
2. `git log --oneline` since the last update (look for the last "status" mention in the conversation, or the last ~2 weeks).
3. Recent step Outcomes: deviations, measurements, follow-ups.
4. `technical-planning/steps/backlog.md`: new or aging items.
5. `technical-planning/12-decisions-and-questions.md` §2.1: open TQs. New TDs since the last update.
6. The next 2–3 ready steps and their owner prerequisites (`steps/README.md` §3).

## Write (≤ 25 lines, plain language, no jargon without a gloss)
```
Status: <date>
Where we are: app A<nn>/A43 · backend B<nn>/B16 · next milestone: <M1–M7 / R1> (<n> app steps away)
Since last update:
- <step>: <one-line outcome>
Highlights / numbers: <e.g. cold start 1.1 s on A55, eval AQ-02 96%>
Risks: <top 1–3, each with what we're doing about it>
Decisions made: <TD-xxx …> (FYI)
Need from you:
1. <question or prerequisite> (rec: …)
Next up: <next steps>
```

## Rules
- Lead with what the owner must act on, if anything is blocking.
- Don't hide bad news: slips, failed gates, rising costs.
- Every question includes a recommendation the owner can accept with "ok".
