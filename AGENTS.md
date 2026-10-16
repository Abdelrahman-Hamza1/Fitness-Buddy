# Fitness Buddy: working agreement for Codex sessions

Fitness Buddy is a local-first nutrition & weight tracking app (Flutter, Android-first) with an AI assistant ("Buddy"), backed by an ASP.NET Core API on Hetzner VMs, joined by an OpenAPI contract. Built for the owner first (R1), then friends (R2), then possibly the public (R3).

Two AI implementers share this repo (TD-059, TD-061). **Codex is fully in charge of the backend, infra and integration, including their reviews. Claude owns the app.** Claude works from `CLAUDE.md`; this file is yours. The engineering rules are the same for both.

## Where the truth lives
- **`spec/`**: what and why (product). Changes only via a new entry in `spec/decisions.md`, **with the owner's approval**.
- **`technical-planning/`**: how. Start at its `README.md`. Backend: `04-backend.md`. Infra and ops: `08-infrastructure-and-operations.md`. Cross-cutting rules (logging, privacy, errors): `09-cross-cutting.md`. Code and test conventions: `10-engineering-practices.md`. Decisions (TDs): `12-decisions-and-questions.md`.
- **`technical-planning/steps/`**: the delivery plan, one card per step, with the status board in `steps/README.md` §4. Since TD-063 there are **two tracks**: yours is the **backend track `B01–B16`** (§4.2), Claude's the app track `A01–A43`. Cross-track dependencies are in **bold** and listed in §6; old `Sxx` IDs in the history map to new ones in §8. `steps/backlog.md` holds follow-ups.
- **`technical-planning/13-delivery-process.md`**: the step lifecycle, gates and owner communication. Its agent roster (`.claude/agents/`) is Claude's tooling. You follow the same phases and gates with your own tools (§10 there).
- `research-notes.md`: dated research findings. Use them, and append new dated sections when you research something.

## Your area
- **You own:** `backend/`, `infra/` (when it exists), the server side of `contracts/` (the server must conform), the server CI jobs (`dotnet`, `contract`, `image`) in `.github/workflows/ci.yml`, Docker/compose, deploys, backups and observability.
- **Your track** (`B01–B16`): the sync and AI spikes, the laptop test server, identity, sync, account deletion, the catalog and Buddy services, Hetzner staging and production (last, TD-064), the final eval and the R1 security review. You also own `tools/buddy_eval` and `tools/sync_sim` (Dart); they run in the `dart` CI job, and you fix their failures. `fb_domain`'s entry points you use are pinned by tests in that package.
- **You plan your own code** and own your track's cards: you write their **Low-level plan**. There are no shared steps: a feature needing both sides is a B card and an A card joined by a dependency.
- **Claude's area:** `apps/mobile/`, `packages/` (Dart), Dart `tools/` except `tools/buddy_eval` and `tools/sync_sim`, `data/`, and the planning docs' structure. Don't change Claude's area. If you need something there, write it in the card's Progress log or tell the owner.
- **Folder:** One folder, one implementer at a time (owner, 2026-10-16): both work in `~/work/fitness_buddy`. Before starting, check that the folder is clean (`git status`), commit and push your branch before handing over, and start your step branch from the latest `main`. Whoever merges second rebases on the new `main` and re-runs CI first.
- **Shared files** (`Makefile`, `ci.yml`, `contracts/`, `technical-planning/`, `steps/backlog.md`, the board): small, focused commits, rebased on `main` often. Edit only your sections. TD numbers: take the next free number on the latest `main`.

## The API contract is the meeting point (rule 4)
- `contracts/openapi/` is the source of truth: contract first → `make gen` (bundle + the generated Dart client in `packages/fb_api_client`) → server change → `make contract-conformance`.
- A contract change goes in **its own commit before any code**, with a Progress-log line in the card naming what changed, so Claude can adapt the app. Additive changes don't wait for Claude. **Breaking changes need the owner.**
- You may regenerate `packages/fb_api_client` with `make gen`, but never hand-edit it.

## Non-negotiable engineering rules (details in technical-planning)
1. **AI interprets, code computes:** models never produce nutrition numbers (except the badged estimate fallback).
2. **Nothing is written without confirmation:** only the app's `ChangeSetApplier` writes user data. AI output becomes proposals.
3. **Local-first:** the phone is the source of truth. Everything except AI works offline. The server holds a synced copy.
4. **Contract-first API:** see above. Never hand-write API types.
5. **Backend:** modular monolith, clean layers, each module owns its schema. Postgres is the only stateful dependency. Minimal APIs, no mediator (`04` §3).
6. **Privacy:** minimum AI context, no identity to models, **no user content in logs/telemetry** (`09` §4; TD-058 is the mechanism).
7. **R1 scope:** Android only (D-081). English UI, but Buddy understands Arabic/Arabizi (D-080).
8. Comments say what the code can't (why, constraints, spec/TD IDs), at the right density (`10` §2, TD-054).
9. Tests prove spec rules by ID (`[Trait("Req", "XX-000")]`), and rules without a spec ID use `[Trait("Rule", "<doc>.<section>-<slug>")]` (`10` §5).

## How a step runs (`13` §3, §10)
1. **Orient:** read the board, the card, its **Read first** docs, the **Outcome** of its dependencies, and the card's **Progress log** (that's where a step resumes).
2. **Plan:** write the Low-level plan in the card: design, file list, tests mapped to spec IDs and exit criteria, work packages, risks. Review it yourself against `03`/`04`/`09`/`10` and the TDs. Architecture-level choices become TD entries.
3. **Owner gate:** under TD-037 you approve your own plan and merge your own step when it has **no ⚠️ OWNER item** (spec change, Accepted-TD change, new paid service/vendor, security trade-off, scope cut, destructive production operation) and every automated gate passes. Otherwise ask the owner and wait.
4. **Implement:** branch `step/<ID>-short-name` from `main`, Conventional Commits (`feat(B05): …`), `make check test` green after every commit. Don't expand scope: anything new goes to `steps/backlog.md` or a later card.
5. **Review:** an independent review of the whole diff before verification, by a separate reviewer agent or a fresh review session, not the session that wrote the code. It covers correctness, design and the rules above, with a security pass for auth, sync, RLS, secrets, logging/telemetry and infrastructure exposure. Fix blockers and majors, then re-review them. Log minors in `steps/backlog.md`. Record the rounds and findings in the Outcome.
6. **Verify:** tick every exit criterion with evidence (test names, outputs, measurements) in `technical-planning/steps/evidence/<ID>-verification.md`.
7. **Close:** write the card's **Outcome** (built, deviations and why, follow-ups, new TDs, measurements). Update the board, `steps/backlog.md` and any doc the step changed (an outdated doc is a bug). Then merge as below.

**Handoff:** append one dated line to the card's Progress log at every phase change and work-package commit, and push. A lost session must be able to resume from it.

## Git
- Push with `git push -u origin <branch>`; retry on network errors. The remote uses SSH. There is no `gh` CLI, so the owner reviews branch diffs on GitHub.
- **Merge to `main`** (TD-036, TD-039): one squash commit `<ID>: <step name>` on a local `merge/<ID>` branch from `origin/main` (the body keeps the branch's commit subjects) → `git push -u origin merge/<ID>` → `tools/scripts/ci-status.sh <sha>` green → `git push origin merge/<ID>:main` (fast-forward, same SHA) → delete `merge/<ID>` and the step branch. `main` rejects commits without a green `ci` check.
- Don't commit secrets. Don't force-push `main`.

## Commands
The root `Makefile` is the entry point (`make help`): `make setup`, `make check`, `make test` (`test-dotnet`, `test-dart`), `make gen`, `make gen-check`, `make contract-conformance`, `make trace`, `make doctor`. Backend details and conventions: `backend/README.md`. The laptop has 7 GB of RAM: run one heavy build at a time and `~/.dotnet/dotnet build-server shutdown` after .NET sessions.

## Working with the owner
- They often work **from a phone**: keep messages short and plain, the decision or result first, then details. Every question comes with a recommendation they can answer with "ok".
- They oversee **architecture and product**, not code line by line. Explain choices at that level.
- Tell them at step start, when you need an owner action or decision, when something blocks, and at step close (a short summary).

## Start here
**The plan was restructured into two tracks on 2026-10-16 (TD-063, TD-064).** S03 and S04 are done (their IDs stay). **B01 (sync spike) and B02 (OpenAI interpretation spike) are done.** B02 is OpenAI GPT-6 Luna only (TD-067), with offline CI and an owner-limited three-prompt live smoke; further paid testing needs a new explicit owner scope. Next is **B03 (laptop test server)** once the owner has Tailscale; if one is blocked, take the next ready B step (`steps/README.md` §7). **Hetzner (B13, B14) waits until the app track reaches A38.** As you touch your own files (`backend/README.md`, comments in `backend/` and `infra/`), update old step IDs to the new ones (§8).
