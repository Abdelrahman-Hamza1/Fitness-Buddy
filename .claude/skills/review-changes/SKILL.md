---
name: review-changes
description: Run Fitness Buddy's review pipeline on the current step branch: choose reviewers (code, security, UX, architecture) from what changed, run them in parallel, consolidate severity-ranked findings, drive the fix loop with the right engineers (max 3 rounds), and report. Use in Phase D of a step, or whenever the owner asks for a review of a branch.
---

# Review changes

## 1. Scope the diff
```
git fetch origin main
git diff origin/main...HEAD --stat
```
Classify the changed paths:

| Changed paths / content | Reviewers |
|---|---|
| anything | `code-reviewer` (always) |
| `backend/**/Identity/**`, auth/JWT/token code, `userdata`/sync, RLS/migrations with policies, `infra/**`, `.github/workflows/**`, secrets/config, logging/telemetry, Buddy request/context building, outbound HTTP clients | `security-reviewer` |
| `apps/mobile/**/presentation/**`, `packages/fb_design_system/**`, `*.arb`, notification wording, any user-facing text | `ux-reviewer` |
| new module/package, new public interface (`*.Contracts`, barrels), `contracts/openapi/**` shape changes beyond additive fields, schema conventions, cross-cutting mechanisms | `architect` (structural review mode) |

Apply the triggers strictly (TD-054): placeholder screens don't need UX, a change inside an existing module doesn't need the architect.

## 2. Run reviewers in parallel
Brief each with: step ID, card path, branch, round number, and (for re-reviews) the exact findings to re-check. Ask for their standard output format.

## 3. Consolidate
- Merge the findings into one list, de-duplicated, most severe first: `[severity] [reviewer] path:line: issue → fix`.
- **Blockers + majors:** must be fixed. **Minors:** fix now if cheap, otherwise log in `technical-planning/steps/backlog.md`. **Nits:** optional.
- If reviewers conflict, or a finding challenges a recorded decision → `architect` arbitrates. Product/risk questions → the owner.

## 4. Fix loop (max 3 rounds)
- Group the fixes by area and brief the engineer who owns that area (one brief per group, with the findings verbatim + the expected tests).
- After the fixes: run `make check test`, commit (`fix(<ID>): address review round N`), then re-run **only the reviewers who had a blocker or major**, scoped to those findings + regressions. Minor/nit fixes: check the diff yourself and don't run another round (TD-054).
- Still blockers or majors after round 3 → stop and escalate to the owner with a summary and a recommendation.

## 5. Report (to yourself / the owner)
```
Review <ID>: round N: approved | open findings
Reviewers: code ✅, security ✅, ux –, architect –
Fixed: <count by severity> · Logged to backlog: <items>
Open: <none | list>
```
Add the review metrics (rounds, findings by severity) to the step's Outcome.
