# How work gets done (process v3)

_The one-page process (TD-075, amended by TD-085). Part A is the shared rules, Part B the models and reviews. Details and templates stay in `technical-planning/13-delivery-process.md`; where they differ, this page wins._

## 0. Who runs what (TD-085, owner 2026-10-28)

**Claude builds everything; the owner talks only to Claude.** The main Claude session (Opus) is the orchestrator of both tracks: it picks the next step on either track, has it planned, briefs Claude's specialist agents (`.claude/agents/`), checks their work against diffs and CI, commits, pushes and merges. **Codex is retired** (the owner moved to the Claude Max plan): no Codex runs, no Codex reviews. Steps that Codex built keep their history; their cards and evidence still mention it.

## A. Shared rules

1. **Tracks.** The app track `A01…` and the backend track `B01…` (`technical-planning/steps/README.md` §4) are both Claude's. They stay separate tracks with their own order and cross-track dependencies. The API contract is still the meeting point: contract changes go in their own commit with a Progress-log note; breaking changes need the owner.
2. **Step tiers**, set in the plan and shown on the card. They decide **which reviews run**, not the model (Part B):
   - **Risky:** user-data write path, sync, sign-in and sessions, authorization/RLS, secrets, AI context or proposals, backups or data leaving the phone, infrastructure and production.
   - **Normal:** everything else that is code.
   - **Data/docs:** data files, docs, fixtures.
3. **Lifecycle:** orient → plan → review the plan → implement → review the code → close. One branch `step/<ID>-…` per step from `main`; Conventional Commits; `make check test` green before every commit. Related ready Normal steps may be planned together as a wave (one plan review across them); Risky steps get their own plan review. Each step keeps its own branch, review, Outcome and merge.
4. **Review.** Every code step gets one independent review by an agent that didn't write the code, which also checks every exit criterion against tests and CI evidence. Blockers and majors are fixed and re-checked; minors are fixed if cheap or logged in `steps/backlog.md`. A `verifier` pass runs on Risky steps and at milestone steps (`steps/README.md` §5). Data/docs steps are gated by their validators and CI.
5. **Merge only through `tools/scripts/merge-step.sh <ID> "<name>" <branch>`** (`docs` / `chore` instead of an ID for docs or tooling changes outside a step). It builds the squash commit without checking anything out, pushes it as `merge/<ID>`, waits for the `ci` check and moves `main` only when it is green (TD-036, TD-039, TD-086). The folder stays free while it waits: start the next step meanwhile (run it in the background). Never push to `main` by hand. A red `ci` means stop: read the failing job, fix, rerun; a test that fails without a related change is re-run once, then treated as real. If the script timed out while `ci` was still running (or finished green on that exact commit), rerun it with `MERGE_REUSE=1` (and `MERGE_CI_TIMEOUT_MIN=40` for the long device job): it reuses the previous attempt's commit when the tree and parent are unchanged, so no second CI run; never for a red `ci`. `tools/scripts/merge-step-selftest.sh` pins this.
6. **Owner gates (TD-037).** Self-approve plans and self-merge when the step has no owner item and every gate passes. **Ask first** for: a spec change, a change to an Accepted TD, a new paid service or vendor, a security trade-off, a scope cut affecting a milestone, a destructive production operation. Owner skims and phone checks are collected and never block a merge.
7. **One folder.** All work happens in `~/work/fitness_buddy`, one step branch at a time (no worktrees, no second clone unless the owner asks). Start only with a clean `git status` on an up-to-date `main`. Parallel agents inside one session commit only their own files by explicit path and never run a formatter over files they don't own. The laptop has 7 GB: one heavy build at a time.
8. **Fast CI (TD-086).** A regular run takes 5–10 minutes; the emulator tests (`android-it`) run nightly on `main`. Check `tools/scripts/ci-nightly.sh` at session start: a red nightly is stop-the-line, fixed before the next merge. Put `[it]` in a commit message to run the emulator tests on that push: always on the last commit of a milestone step, and when a step changes Patrol tests or native Android code.
9. **Never lose work.** Commit after every work package, and append one dated line to the card's Progress log at every phase change, then push. A lost session resumes from the Progress log.
10. **Budget.** The plan states the expected size; the Outcome records the actual size and review findings. If the owner's weekly limit runs low, finish open steps first and move Normal-step implementation to Sonnet, telling the owner.
11. **Owner messages:** short and plain, result or decision first; every question comes with a recommendation answerable with "ok".

## B. Models and reviews (TD-085)

**Opus by default for everything that needs judgment**: the orchestrator, planning, plan review, implementation on every tier, code review, security review, UX review, research, data curation and verification. **Sonnet only for mechanical work**, by a per-brief `model: sonnet` override:
- reproducing a failing test, reading CI logs, re-running flaky jobs;
- repo searches and inventories (`Explore`);
- mechanical chores with a fully specified result: ARB/codegen merges, renames, regenerating files, applying a review fix that's already written out word for word.

A Sonnet task that fails or needs a judgment call goes back to Opus.

| Tier | Plan + plan review | Implementation | Reviews |
|---|---|---|---|
| Risky | `step-planner` + `architect` (own review) | Opus engineers | `code-reviewer` + `security-reviewer` + `verifier` (+ `ux-reviewer` on UI) |
| Normal | `step-planner` + `architect` (per step or wave) | Opus engineers | `code-reviewer` (+ `ux-reviewer` on UI) |
| Data/docs | `step-planner` or the orchestrator | Opus (`data-curator` for food data) | validators + CI |

- **Engineers by area:** `flutter-engineer` (app, Dart packages and tools), `dotnet-engineer` (backend modules, EF Core, contract conformance), `platform-engineer` (CI, Docker, infra, deploys, backups, observability), `ai-engineer` (prompts, Buddy server AI, `buddy_eval`), `data-curator` (`data/`).
- `ux-reviewer` joins real screens and user-facing copy; the `architect` reviews code for new foundations and seams, on either track.
- `security-reviewer` covers both tracks, including B16's R1 security review; on Risky steps it also records a verification file `technical-planning/steps/evidence/<ID>-verification.md`.
- The orchestrator briefs agents with self-contained briefs (`13` §6), checks their claims against diffs and CI, and writes the Outcome.
