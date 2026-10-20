# How work gets done (process v2)

_The one-page process for both implementers (TD-075, owner 2026-10-17). Part A is shared, Part B is Claude's, Part C is Codex's. Details and templates stay in `technical-planning/13-delivery-process.md`; where they differ, this page wins._

## A. Shared rules (Claude and Codex)

1. **Tracks.** Claude owns the app track `A01…`, Codex the backend track `B01…` (`technical-planning/steps/README.md` §4). App steps with no UI are marked **Codex** in the board's **By** column and are Codex's, as whole steps (TD-078); Claude reviews their app architecture before the merge (`13` §10). Each side plans, builds, reviews and merges its own steps. The API contract is the meeting point: contract changes go in their own commit with a Progress-log note; breaking changes need the owner.
2. **Step tiers**, set in the plan and shown on the card:
   - **Risky:** user-data write path, sync, sign-in and sessions, authorization/RLS, secrets, AI context or proposals, backups or data leaving the phone, infrastructure and production.
   - **Normal:** everything else that is code.
   - **Data/docs:** data files, docs, fixtures.
3. **Lifecycle:** orient → plan → review the plan → implement → review the code → close. One branch `step/<ID>-…` per step from `main`; Conventional Commits; `make check test` green before every commit. Related ready steps may be planned together as a wave (one plan review across them), but each step keeps its own branch, review, Outcome and merge.
4. **Review.** Every code step gets one independent review (not the session that wrote the code) that also checks every exit criterion against tests and CI evidence. Blockers and majors are fixed and re-checked; minors are fixed if cheap or logged in `steps/backlog.md`. A separate verification pass happens only at milestone steps (`steps/README.md` §5). Data/docs steps are gated by their validators and CI.
5. **Merge only through `tools/scripts/merge-step.sh <ID> "<name>" <branch>`.** It squashes onto a `merge/<ID>` branch, waits for the `ci` check and moves `main` only when it is green (TD-036, TD-039). Never push to `main` by hand. A red `ci` means stop: read the failing job, fix, rerun; a test that fails without a related change is re-run once, then treated as real.
6. **Owner gates (TD-037).** Self-approve plans and self-merge when the step has no owner item and every gate passes. **Ask first** for: a spec change, a change to an Accepted TD, a new paid service or vendor, a security trade-off, a scope cut affecting a milestone, a destructive production operation. Owner skims and phone checks are collected and never block a merge.
7. **One folder, one implementer.** Both work in `~/work/fitness_buddy`. Start only with a clean `git status` on an up-to-date `main`; hand over with everything committed and pushed and the folder back on `main`. Inside one session, parallel helpers commit only their own files by explicit path and never run a formatter over files they don't own.
8. **Never lose work.** Commit after every work package, and append one dated line to the card's Progress log at every phase change, then push. A lost session resumes from the Progress log.
9. **Budget.** The plan states the expected size; the Outcome records the actual size and review findings. When the owner's weekly limit is low, only finish open steps.
10. **Owner messages:** short and plain, result or decision first; every question comes with a recommendation answerable with "ok".

## B. Claude (app track)

| Tier | Plan + plan review | Implementation | Code review |
|---|---|---|---|
| Risky | Opus planner, Opus architect | Opus | Opus (+ security reviewer) |
| Normal | Opus planner, Opus architect (per wave) | Sonnet | Sonnet |
| Data/docs | Sonnet | Sonnet | validators + CI |

- A failed Sonnet work package or review round is retried on Opus.
- `ux-reviewer` joins real screens and user-facing copy; the architect reviews code only for new foundations and seams.
- The orchestrator (main session) briefs agents with self-contained briefs (`13` §6), checks their claims against diffs and CI, and writes the Outcome.

## C. Codex (backend track)

- **Model: GPT-6.1 Sol for everything** (planning, implementation, review), owner choice 2026-10-17.
- **Independent review:** a fresh GPT-6.1 Sol session (or reviewer agent) that did not write the code reviews the whole diff and checks the exit criteria.
- **Security review:** on every Risky step, plus any step touching auth, sync, RLS, secrets, logging/telemetry, AI context, deletion or infrastructure exposure, a **second, separate** fresh GPT-6.1 Sol session reviews the diff for security and privacy only (authorization and RLS, secrets, logging without user content, input handling, AI context minimisation, exposure). Its blockers and majors are fixed and re-checked like any review.
- **Risky steps** also record the security findings in the Outcome and a verification file `technical-planning/steps/evidence/<ID>-verification.md`.
- Working agreement, area and commands: `AGENTS.md`.
