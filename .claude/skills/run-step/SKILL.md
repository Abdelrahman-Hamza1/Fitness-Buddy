---
name: run-step
description: Orchestrator playbook for executing one Fitness Buddy app-track step (A01–A43, TD-063) end to end: readiness check, research, planning, owner plan approval, work packages with specialist agents, reviews, verification, close-out and owner acceptance. Use when the owner says "run A06", "next step", "continue the plan", or similar.
---

# Run a step (orchestrator playbook)

You are the **orchestrator**: product owner + tech lead. You delegate to specialist agents, but **you** own the outcome, the owner communication and the quality gates. Process contract: `technical-planning/13-delivery-process.md`. Read it if it isn't fresh in context.

Track progress with a todo list mirroring the phases below. Keep the owner informed per §5 of the process doc, with short, mobile-friendly messages.

## 0. Pick the step
- If the owner named a step, use it. Otherwise open `technical-planning/steps/README.md` §4.1 (the app track) and pick per §7: the lowest-numbered open `A` step whose dependencies are met (bold = the backend track; "(contract)" = its contract commit is on `main`).
- Work in `~/work/fitness_buddy`, one implementer at a time: start only with a clean `git status`, and push your branch before handing over (`13` §10).
- If a step is 🟨 in progress (from an earlier session), **resume it**: read its card (plan + partial outcome), `git log` on its branch, and continue from the first unfinished phase.

## A. Orient: Definition of Ready
1. Read the card, its **Read first** docs, and the **Outcomes** of its dependencies.
2. Check: dependencies ✅ · owner prerequisites available (`steps/README.md` §3) · blocking questions answered (`12` §2.1) · `main` green (`git pull`, `make check test` once tooling exists).
3. Not ready → tell the owner exactly what's missing, with a recommendation, and offer another ready step.
4. Ready → set the board status to 🟦, create the branch `step/<ID>-short-name` from `main`, and send a **session-start message** (step, goal, what you'll need from the owner).

## B. Plan
1. **Research** (if any "Decide in the low-level plan" item needs current external facts, or a new dependency is likely): launch `tech-researcher`, one brief per question, in parallel. Wait for the results.
2. **Plan:** launch `step-planner` with a brief containing the card path, the research findings, the branch, and anything learned in Orient. It writes the Low-level plan into the card.
3. **Architecture review:** launch `architect` in plan-review mode. Apply the required changes yourself (or re-brief the planner for a rework). At most 2 rounds, then escalate to the owner.
4. Read the final plan yourself. You're accountable for it. Check scope, size (split if > L), WPs per specialist, the test list against the exit criteria.
5. Commit the plan to the branch (`docs(<ID>): low-level plan`).
6. **Owner gate:** send the **plan approval request** (template in process §5.2), listing ⚠️ OWNER decisions and TD candidates with your recommendation. **Stop and wait for the owner's reply.** Record new TDs (the `record-decision` skill) once approved.

## C. Implement
1. Set the board to 🟨. Work through the plan's WPs in order. For each WP:
   - Brief the right specialist (`flutter-engineer`, `dotnet-engineer`, `platform-engineer`, `ai-engineer`, `data-curator`) with the **self-contained brief** template (process §6). One WP per brief.
   - Independent WPs in different areas may run in parallel with `isolation: "worktree"`. Then merge their branches into the step branch yourself.
   - When it returns: inspect the diff (`git diff`), run `make check` + the relevant tests, fix small issues or re-brief once with specifics. Commit with a Conventional Commit message referencing the step.
   - No per-WP ping to the owner (TD-054); message them only for owner actions or blockers.
2. Contract changes go first: contract WP → `make gen` → server WP → app WP.
3. Red build = stop the line. Fix before the next WP.
4. Deviation from the plan, scope or a TD → pause and decide per process §4 (ask the owner if it's theirs to decide).

## D. Review & verify
1. Run the `review-changes` skill (it picks reviewers by what changed, runs them in parallel, and manages the fix loop).
2. At milestone steps (or when the evidence is in doubt, TD-073), launch `verifier` on the branch; otherwise the code reviewer's exit-criteria check plus green CI is the evidence. Any ❌ → back to C for the fix (then re-verify). ⚠️ items → prepare exact owner instructions.

## E. Close
1. Write the card's **Outcome**: built · deviations (and why) · follow-ups · new TDs · measurements · metrics (planned vs actual size, WPs, review rounds, findings by severity, tests added).
2. Update the status board (✅ after the owner's OK; until then keep 🟨 with a note "awaiting owner"), any planning docs the step changed, and `technical-planning/steps/backlog.md` (follow-ups, minor findings).
3. Commit (`docs(<ID>): outcome`) and **push the branch** (`git push -u origin step/<ID>-…`, retry on network errors with backoff).
4. **Owner gate:** send the **close summary** (template in process §5.2) with demo steps for the A55 when relevant, and the GitHub branch name for reviewing the diff. **Wait for the owner's OK.**
5. On OK: the board ✅ and the Outcome are committed on the step branch first (`main` only accepts CI-verified commits, so nothing goes to `main` afterwards). Then squash on a local `merge/<ID>` branch from `origin/main` (one commit `<ID>: <step name>`; the body keeps the branch's commit subjects, Outcome and board ✅ included) → `git push -u origin merge/<ID>` → `tools/scripts/ci-status.sh <sha>` green → `git push origin merge/<ID>:main` (fast-forward, same SHA) → delete `merge/<ID>` and the step branch (TD-036, TD-039). Dependabot PRs: only PRs by `dependabot[bot]` whose head sits on current `main` with `ci` green may go straight to `main` (`git push origin <sha>:main`); anything else, and any code from a fork, goes through a `merge/*` branch.
6. Propose the next step.

## Always
- **Handoff (process §8a):** append a line to the card's Progress log and push the branch at every phase change, WP commit, owner question/answer, and before long agent or CI waits. Resuming: start from the Progress log.
- Owner messages: brief. Result or question first, ≤ 5 lines unless they ask for more.
- Never skip a gate or mark a criterion done without evidence.
- Never change the spec or an Accepted TD without the owner (`record-decision`).
- Keep messages to the owner short: the decision or result first, then details. Every question comes with your recommendation.
- If the session might end mid-step, push the branch and update the card/board so the next session can resume.
