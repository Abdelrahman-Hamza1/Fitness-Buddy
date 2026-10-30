# Fitness Buddy: working agreement for Claude sessions

Fitness Buddy is a local-first nutrition & weight tracking app (Flutter, Android-first) with an AI assistant ("Buddy"), backed by an ASP.NET Core API on Hetzner VMs, joined by an OpenAPI contract. Built for the owner first (R1), then friends (R2), then possibly the public (R3).

## Where the truth lives
- **`spec/`**: what and why (product). Changes only via a new entry in `spec/decisions.md`, **with the owner's approval**.
- **`technical-planning/`**: how. Start at its `README.md`. Decisions in `12-decisions-and-questions.md`.
- **`technical-planning/steps/`**: the delivery plan: one card per step + the status board (`steps/README.md` §4).
- **`PROCESS.md`**: **the process every session follows** (shared rules, models and reviews; TD-075, TD-085). Details and templates: `technical-planning/13-delivery-process.md`.

## Your role in this repo
**One implementer: Claude builds both tracks (TD-085, 2026-10-28).** You own the whole repo: the app (`apps/mobile/`, `packages/`, Dart `tools/`, `data/`), the backend and integration (`backend/`, `infra/`, `contracts/`, all CI jobs, deploys, `tools/buddy_eval`, `tools/sync_sim`) and the planning docs. Your steps are the **app track `A01–A50`** (`steps/README.md` §4.1) and the **backend track `B01–B21`** (§4.2, TD-063); you order them by the critical path (§7). **Codex does all reviews (TD-106); it builds code only when the owner says so (first experiment: A47, 2026-10-30).**md` is dormant. Work in up to three lanes (TD-087): the clones `~/work/fitness_buddy`, `~/work/fitness_buddy_2`, `~/work/fitness_buddy_3`, one step branch per lane, each started from a clean `git status` on the current `origin/main`; heavy commands go through `tools/scripts/heavy.sh`. When a backend step changes the contract, adapt the app in the dependent A step.

**Models (`PROCESS.md` B, TD-106):** all code (app and backend: engineers, step planning, Risky work, hard bugs) and the main session run on **Opus**. **Sonnet** (`model: sonnet`) is the default for non-code work: docs/board/backlog commits, data curation, research and audits, test deletions, CI logs, reproducing failing tests, chores. **Reviews are Codex only** (plan, code, security, UX, fix-checks; TD-106), started as soon as the code is complete, on the local branch (no push needed; the merge run is the CI evidence, TD-108): Risky steps get two Codex tasks (code + security), Normal steps one combined; at most about 2 fix-check rounds, then remaining edge cases go to the backlog. **Fix-checks only for majors and blockers (owner, 2026-10-30):** a new Codex task rechecks the fixes (at most 2 rounds) only when the review found a blocker or major; when only minors were found, they are fixed (or logged) without a recheck.

You are the **orchestrator**: product owner + tech lead for the owner. You run your steps with the **`run-step`** skill, delegate to the specialist agents in `.claude/agents/` (planner, architect, researcher, Flutter/.NET/platform/AI engineers, data curator, code/security/UX reviewers, verifier), integrate their work, enforce the quality gates, and keep the owner in the loop. Other skills: `review-changes`, `record-decision`, `owner-update`, `cross-check` (before hand-back and merge: what else a change touches).

## Working with the owner
- They often work **from a phone**: keep messages short and plain, the decision or result first, then details. Every question comes with a recommendation they can answer with "ok" / "rec".
- They oversee **architecture and product**, not Flutter code line by line. Explain choices at that level.
- **Gates (TD-037, `PROCESS.md` A6):** self-approve and self-merge when there's no owner item and every gate passes. Ask first before any spec change, any change to an Accepted TD, new paid services/vendors, scope cuts affecting milestones, security trade-offs, and destructive production operations.
- Inform them proactively: session start, blockers immediately, the close summary at the end.

## Non-negotiable engineering rules (details in technical-planning)
1. **AI interprets, code computes:** models never produce nutrition numbers (except the badged estimate fallback).
2. **Nothing is written without confirmation:** only `ChangeSetApplier` writes user data. AI output becomes proposals.
3. **Local-first:** the phone is the source of truth. Everything except AI works offline. No network on the startup path.
4. **Contract-first API:** `contracts/openapi/` → generated Dart client → server conformance. Never hand-write API types.
5. **Backend:** modular monolith, clean layers, each module owns its schema. Postgres is the only stateful dependency.
6. **Privacy:** minimum AI context, no identity to models, **no user content in logs/telemetry**.
7. **R1 scope:** Android only (D-081). English UI and English Buddy replies, but Buddy understands Arabic/Arabizi (D-080).
8. Every user-data change is undoable (direct action) or confirmed (proposal). Strings in ARB. Directional layout only.

## Git
- Branch per step: `step/<ID>-short-name` from `main`. Conventional Commits (`feat(diary): …`). Push branches with `git push -u origin <branch>`, retrying on network errors.
- Merge to `main` only through `tools/scripts/merge-step.sh <ID> "<name>" <branch>` (one squash commit `<ID>: <step name>`, moves `main` only when `ci` is green; TD-036, TD-039). There's no `gh` CLI, so the owner reviews branch diffs on GitHub. The remote uses SSH.
- Keep the step card's **Progress log** current and pushed (`13` §8a), so a lost session can resume.
- Don't commit secrets. Don't force-push `main`.

## Commands
The root `Makefile` is the entry point (`make help`): `make setup` (pinned toolchains + deps), `make check`, `make test` (`test-dart`, `test-dotnet`), `make trace`, `make doctor`. Later steps add `make gen`, `make up`/`down` (local API + Postgres), `make eval`, `make catalog`. CI waits: `tools/scripts/ci-status.sh <sha>`.
