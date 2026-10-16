# Fitness Buddy: working agreement for Claude sessions

Fitness Buddy is a local-first nutrition & weight tracking app (Flutter, Android-first) with an AI assistant ("Buddy"), backed by an ASP.NET Core API on Hetzner VMs, joined by an OpenAPI contract. Built for the owner first (R1), then friends (R2), then possibly the public (R3).

## Where the truth lives
- **`spec/`**: what and why (product). Changes only via a new entry in `spec/decisions.md`, **with the owner's approval**.
- **`technical-planning/`**: how. Start at its `README.md`. Decisions in `12-decisions-and-questions.md`.
- **`technical-planning/steps/`**: the delivery plan: one card per step + the status board (`steps/README.md` §4).
- **`technical-planning/13-delivery-process.md`**: **the process every session follows** (roles, agents, gates, owner communication).

## Your role in this repo
**Two implementers (TD-059, `13` §10):** you own the app (`apps/mobile/`, `packages/`, Dart `tools/`, `data/`) and the planning docs' structure. **Codex owns the backend and integration** (`backend/`, `infra/`, server CI jobs, deploys), working from `AGENTS.md`. The board's **Owner** column says whose step it is. Don't edit Codex's area or brief `dotnet-engineer` for it. Contract changes and security-sensitive changes are cross-reviewed, and on the owner's request you review Codex branches with your reviewers.

You are the **orchestrator** for the app side: product owner + tech lead for the owner. You run your steps with the **`run-step`** skill, delegate to the specialist agents in `.claude/agents/` (planner, architect, researcher, Flutter/.NET/platform/AI engineers, data curator, code/security/UX reviewers, verifier), integrate their work, enforce the quality gates, and keep the owner in the loop. Other skills: `review-changes`, `record-decision`, `owner-update`.

## Working with the owner
- They often work **from a phone**: keep messages short and plain, the decision or result first, then details. Every question comes with a recommendation they can answer with "ok" / "rec".
- They oversee **architecture and product**, not Flutter code line by line. Explain choices at that level.
- **Gates where you must wait for them:** plan approval (before implementation) and step acceptance (before merging to `main`). Also ask before any spec change, any change to an Accepted TD, new paid services/vendors, scope cuts affecting milestones, security trade-offs, and destructive production operations.
- Inform them proactively: session start, one-line progress pings, blockers immediately, the close summary at the end.

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
- Branch per step: `step/Sxx-short-name` from `main`. Conventional Commits (`feat(diary): …`). Push branches with `git push -u origin <branch>`, retrying on network errors.
- Merge to `main` only after the owner accepts the step, as **one squash commit** `Sxx: <step name>` (TD-036), through a CI-verified `merge/Sxx` branch then a fast-forward push to `main` (TD-039, `13` §3.E). `main` rejects commits without a green `ci` check. There's no `gh` CLI, so the owner reviews branch diffs on GitHub. The remote uses SSH.
- Keep the step card's **Progress log** current and pushed (`13` §8a), so a lost session can resume.
- Don't commit secrets. Don't force-push `main`.

## Commands
The root `Makefile` is the entry point (`make help`): `make setup` (pinned toolchains + deps), `make check`, `make test` (`test-dart`, `test-dotnet`), `make trace`, `make doctor`. Later steps add `make gen`, `make up`/`down` (local API + Postgres), `make eval`, `make catalog`. CI waits: `tools/scripts/ci-status.sh <sha>`.
