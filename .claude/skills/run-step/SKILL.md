---
name: run-step
description: Orchestrator playbook for executing one Fitness Buddy step on either track (app A01–A50, backend B01–B21; TD-063, TD-085) end to end: readiness check, research, planning, owner plan approval, work packages with specialist agents, reviews, verification, close-out and owner acceptance. Use when the owner says "run A06", "next step", "continue the plan", or similar.
---

# Run a step (orchestrator playbook)

You are the **orchestrator**: product owner + tech lead. You delegate to specialist agents, but **you** own the outcome, the owner communication and the quality gates. Process contract: `technical-planning/13-delivery-process.md`. Read it if it isn't fresh in context.

Track progress with a todo list mirroring the phases below. Keep the owner informed per §5 of the process doc, with short, mobile-friendly messages.

## 0. Pick the step
- If the owner named a step, use it. Otherwise open `technical-planning/steps/README.md` §4 (app track §4.1, backend track §4.2) and pick per §7: by the critical path across both tracks (milestones first, then what unblocks the other track), else the lowest-numbered ready step (bold = the other track; "(contract)" = its contract commit is on `main`).
- Up to three lanes in parallel (TD-087, `PROCESS.md` A7): clones `~/work/fitness_buddy`, `~/work/fitness_buddy_2`, `~/work/fitness_buddy_3`, one step branch per lane, each started from a clean `git status` on the current `origin/main`. Give every agent brief its lane folder (absolute paths) and the rule that heavy commands go through `tools/scripts/heavy.sh`. Pick lanes with disjoint areas.
- If a step is 🟨 in progress (from an earlier session), **resume it**: read its card (plan + partial outcome), `git log` on its branch, and continue from the first unfinished phase.

## A. Orient: Definition of Ready
1. Read the card, its **Read first** docs, and the **Outcomes** of its dependencies.
2. Check: dependencies ✅ · owner prerequisites available (`steps/README.md` §3) · blocking questions answered (`12` §2.1) · `main` green (`git pull`) · last night's emulator run green (`tools/scripts/ci-nightly.sh`; red = fix it first, TD-086).
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
1. Set the board to 🟨. **One engineer builds the whole step (TD-095):** brief the right specialist (`flutter-engineer`, `dotnet-engineer`, `platform-engineer`, `ai-engineer`, `data-curator`) once with the **self-contained brief** template (process §6) covering **all WPs in order**, one commit per WP, focused tests + `make check-*` locally (full suites run in CI). Continue the same agent (SendMessage) for review fixes. Start a fresh agent only for another specialty or when its context is getting large. Agents run on Opus; pass `model: sonnet` only for mechanical work (`PROCESS.md` B).
   - Independent WPs touching disjoint files may run in parallel in the same folder (no worktrees); each agent commits only its own files by explicit path. Heavy commands through `tools/scripts/heavy.sh`, one at a time machine-wide (7 GB laptop).
   - When it returns: inspect the diff (`git diff`), run `make check` + the relevant tests, fix small issues or re-brief once with specifics. Commit with a Conventional Commit message referencing the step.
   - No per-WP ping to the owner (TD-054); message them only for owner actions or blockers.
2. Contract changes go first: contract WP → `make gen` → server WP → app WP.
3. Red build = stop the line. Fix before the next WP.
4. Deviation from the plan, scope or a TD → pause and decide per process §4 (ask the owner if it's theirs to decide).

## D. Review & verify
1. Run the `review-changes` skill (it picks reviewers by what changed, runs them in parallel, and manages the fix loop).
2. At milestone steps, or when the evidence is in doubt (TD-095), launch `verifier` on the branch; otherwise the code reviewer's exit-criteria check plus green CI is the evidence. Any ❌ → back to C for the fix (then re-verify). ⚠️ items → prepare exact owner instructions.

## E. Close
1. Write the card's **Outcome**: built · deviations (and why) · follow-ups · new TDs · measurements · metrics (planned vs actual size, WPs, review rounds, findings by severity, tests added).
2. Update the status board (✅ after the owner's OK; until then keep 🟨 with a note "awaiting owner"), any planning docs the step changed, and `technical-planning/steps/backlog.md` (follow-ups, minor findings).
3. Commit (`docs(<ID>): outcome`). No `[it]`: the emulator runs nightly and manually only (TD-104). Push the branch only when the owner will review it on GitHub (step 4); otherwise `merge-step.sh` carries it, and a separate push just starts a redundant CI run.
4. **Owner gate:** send the **close summary** (template in process §5.2) with demo steps for the A55 when relevant, and the GitHub branch name for reviewing the diff. **Wait for the owner's OK.**
5. On OK: commit the Outcome and board ✅ on the step branch, then run `tools/scripts/merge-step.sh <ID> "<step name>" step/<ID>-…` in the background with `MERGE_TRAILER` set to the attribution line. It builds the squash commit without touching the folder, pushes `merge/<ID>`, waits for `ci` and moves `main` only when green (TD-036, TD-039, TD-086, `PROCESS.md` A5). Never push to `main` by hand. While it waits, start the next step's Orient and Plan (new branch from `origin/main`; if it depends on the step being merged, rebase it once the merge lands).
6. Propose the next step.

## Always
- **Handoff (process §8a):** append a line to the card's Progress log and push the branch at every phase change, WP commit, owner question/answer, and before long agent or CI waits. Resuming: start from the Progress log.
- Owner messages: brief. Result or question first, ≤ 5 lines unless they ask for more.
- Never skip a gate or mark a criterion done without evidence.
- Never change the spec or an Accepted TD without the owner (`record-decision`).
- Keep messages to the owner short: the decision or result first, then details. Every question comes with your recommendation.
- If the session might end mid-step, push the branch and update the card/board so the next session can resume.
