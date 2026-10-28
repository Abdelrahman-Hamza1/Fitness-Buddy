# 13 — Delivery Process: Orchestrator, Agents & Gates

_**`PROCESS.md` (TD-075) is the one-page process and wins where this file differs;** this file keeps the details and templates._

_How the work in `steps/` actually gets done: who does what, which specialist agent runs when, where the owner is consulted, and which quality gates every step passes. This file is the process contract. `CLAUDE.md` points every session here._

## 1. Roles

| Role | Who | Owns | Never does |
|---|---|---|---|
| **Owner** | You | Product direction, the spec, architecture approval, plan approval, step acceptance, accounts and prerequisites | — |
| **Orchestrator** (product owner + tech lead) | The main Claude session on Opus (both tracks, the planning docs, the board; TD-085) | Runs the step lifecycle. Briefs agents, integrates their work, guards scope and quality, keeps the owner informed, writes Outcomes, commits, pushes, merges after approval | Changes the spec or an accepted TD without the owner. Skips a gate. Lets an agent's claim stand without evidence |
| **Specialist agents** | `.claude/agents/*.md` | One job each (§2), with a self-contained brief from the orchestrator | Talk to the owner directly, push, merge, or widen scope |

Subagents can't spawn other agents. **All orchestration happens in the main session**, using the `run-step` skill.

## 2. The agent roster

| Agent | Job | Called when | Edits code? |
|---|---|---|---|
| `step-planner` | Writes the step card's **Low-level plan** (design, files, tests, task order, decisions) | Phase B of every step | Card only |
| `architect` | Guards the architecture (`03`, `04`, `05`, TDs): reviews plans and structural changes, drafts TDs, arbitrates review disputes | Every plan review. Any new module/public interface/schema convention/contract shape. Disputes | No |
| `tech-researcher` | Researches current facts and best practices (versions, APIs, libraries, prices, licences) with cited, dated sources | A plan decision depends on facts that change or on unfamiliar territory. Before adding a dependency | No (may append to `research-notes.md`) |
| `flutter-engineer` | Implements app work: Flutter, Riverpod, drift, `fb_domain`, `fb_text`, `fb_design_system`, Dart tools | Phase C, app work packages | Yes |
| `dotnet-engineer` | Implements backend work: ASP.NET Core modules, EF Core, Postgres, contract conformance | Phase C, backend work packages | Yes |
| `platform-engineer` | CI/CD, OpenTofu, cloud-init, Kamal, Docker, backups, observability, Makefile | Phase C, infra/tooling work packages | Yes |
| `ai-engineer` | Prompts, model routing, `ILlmClient` adapters, `buddy_eval` cases and graders, eval reports | App-side AI work (e.g. A21's engine fixtures) and the Buddy server's AI work and `buddy_eval` (B09–B12, B15) | Yes |
| `data-curator` | Reference dishes, basics data, portion words, exercises (`data/`) with cited sources | The dish batches (A04, A17–A19, A30, A32), A03, A05 data work | Data files only |
| `code-reviewer` | Reviews the diff for correctness, design, tests, spec/DoD compliance | Phase D of **every** step | No |
| `security-reviewer` | Reviews auth, authorization, secrets, logging/privacy, infra exposure, AI context | Phase D when the diff touches identity, sync, user data, infra, secrets, logging, AI requests | No |
| `ux-reviewer` | Reviews UI against the spec's UX rules (states, copy, colour, taps, accessibility) | Phase D when the diff touches screens or user-facing copy | No |
| `verifier` | Independently checks every exit criterion with evidence (runs tests, measurements) | End of Phase D, before close | No (may add evidence notes) |

### 2.1 Model policy (TD-085; replaces TD-038/TD-073)

**Every agent defaults to Opus**, and so does the orchestrator. The step tier (`PROCESS.md` A2) picks the reviewers, not the model.

Per-brief override **down to Sonnet** (the Agent tool's `model` parameter) only for mechanical work with a checkable result:
- reproducing a failing test, reading CI logs, re-running flaky jobs;
- repo searches and inventories;
- fully specified chores: ARB/codegen merges, renames, regenerating files, applying a review fix already written out word for word.

A Sonnet task that fails, or turns out to need judgment, is redone on Opus. If the owner's weekly limit runs low, Normal-step implementation may move to Sonnet, with the owner told (`PROCESS.md` A9).

## 3. Step lifecycle (what runs when)

```
 A Orient ──► B Plan ──► [OWNER: approve plan] ──► C Implement ──► D Review & verify ──► E Close ──► [OWNER: accept]
   │            │                                    │                 │                  │
   │            ├ tech-researcher (if facts needed)  ├ engineers per   ├ code-reviewer    ├ Outcome, board,
   │            ├ step-planner                       │ work package    ├ security / ux /  │ docs, merge
   │            └ architect (plan review)            └ tests each WP   │ architect (if)   └ owner update
   └ Definition of Ready                                               └ verifier
```

### A. Orient: Definition of Ready (orchestrator)
A step is **ready** when: its dependencies are ✅ on the board, the owner prerequisites it needs exist (`steps/README.md` §3), questions blocking it are answered, and `main` is green. If it's not ready, tell the owner what's missing and pick another ready step.

### B. Plan
1. **Research first** if the card's "Decide in the low-level plan" items need external facts → `tech-researcher` (one brief per question, run in parallel).
2. **`step-planner`** writes the Low-level plan into the card, using the research.
3. **`architect`** reviews the plan → `approve` / `approve with changes` / `rework`. At most 2 rework rounds, then the orchestrator escalates to the owner.
**S-sized steps (TD-054):** one pass: the planner writes a short plan and the architect reviews it in the same brief. No separate research unless a new dependency or an external fact is involved.
4. **Owner gate (mandatory):** the orchestrator sends a compact plan summary (§5.2). Implementation starts only after the owner's OK. For S-sized steps, the owner may answer "ok" without reading the full plan.

### C. Implement
1. Create the branch `step/<ID>-short-name` from `main` (IDs per TD-063: `A01…` app, `B01…` backend).
2. Split the plan's task list into **work packages** (WPs) by specialty (app / backend / platform / AI / data). Each WP is small enough to review on its own.
3. Brief the right engineer per WP (§6). **Sequential by default.** Independent WPs in different areas (e.g. backend vs app) may run in parallel, each in an isolated worktree, and are merged by the orchestrator.
4. After each WP: the orchestrator runs `make check test` (or the relevant subset), inspects the diff, and commits (Conventional Commits). A red build stops the line until fixed.
5. **API changes are contract-first:** contract WP → client regeneration → server WP → app WP.

### D. Review & verify (the `review-changes` skill)
1. Pick reviewers by what changed (§2, TD-073): `code-reviewer` always; it also checks each exit criterion against the tests and CI evidence. `architect` only for **new foundations and seams** (new modules or packages, public interfaces other steps build on, cross-cutting mechanisms), not for feature steps that build on existing seams; its plan review per wave is unchanged (Risky steps get their own plan review, TD-085). `security-reviewer` on every Risky step (TD-085) and otherwise only for sync, sign-in and sessions, backups or data leaving the phone, logging/telemetry and AI requests. `ux-reviewer` for real screens or user-facing copy (not placeholders). Run them in parallel.
2. Findings have a severity: **blocker** / **major** / **minor** / **nit**. Blockers and majors must be fixed. Minors are fixed or logged in `steps/backlog.md`. Nits are optional.
3. Fixes go back to the engineer who wrote the code. **Re-review only when the round had a blocker or major** (by the same reviewer, scoped to those findings + regressions); fixes of minors and nits are checked by the orchestrator (diff + `make check test`) without another reviewer round (TD-054). **At most 3 rounds**, then the architect arbitrates, then the owner decides.
4. **`verifier`** on Risky steps (TD-085), at milestone steps (A11 M1, A16 M2, A23 M3, A31/A32 M4, A35 M5, A41 M6, A42/A43 M7 and R1) and when the orchestrator doubts the evidence (TD-073). It checks every exit criterion with evidence (test names, outputs, measurements, screenshots), marking each ✅ / ❌ / ⚠️ (needs the owner, e.g. on-device checks). Any ❌ returns to C. Other steps: the code reviewer's exit-criteria check plus green CI.

### E. Close
1. The orchestrator writes the card's **Outcome** (built, deviations, follow-ups, new TDs, measurements, review rounds).
2. Update the status board, any planning doc the step changed, and `steps/backlog.md`.
3. Push the branch. Send the owner the **close summary** (§5.2) with demo instructions for the A55 when relevant.
4. **Owner gate:** on the owner's OK (or after on-device checks pass), merge into `main` through the CI-verified flow: squash on a local `merge/<ID>` branch from `origin/main` (one commit `<ID>: <step name>`; the body keeps the branch's commit subjects, Outcome and board ✅ included) → `git push -u origin merge/<ID>` → `tools/scripts/ci-status.sh <sha>` green → `git push origin merge/<ID>:main` (fast-forward, same SHA) → delete `merge/<ID>` and the step branch (TD-036, TD-039). The `main` ruleset rejects any commit on which the `ci` check hasn't passed. Without `gh` there are no PRs: the owner can review the branch diff on GitHub.

## 3a. Delegated gates (TD-037)

The owner delegated both gates (2026-10-11). For a step with **no ⚠️ OWNER item** where **all automated gates pass**, the orchestrator approves the plan and accepts/merges the step itself, then continues to the next ready step. The plan summary and the close summary are still sent (FYI). Any ⚠️ OWNER item, a failed gate that can't be fixed within the loop limits, or a needed prerequisite → stop and ask. Owner on-device checks are collected in a running list and don't block merging.

## 3b. Waves (TD-068)

Several ready steps (of either track) can run as one **wave**:
1. **Group plan:** the orchestrator groups the wave's steps into **lanes** of related steps (e.g. local data A01+A06, food data A03–A05, design A02) and briefs one `step-planner` per lane, in parallel. Each step's plan still goes into its own card. Plans may rely on an earlier step's plan in the same lane.
2. **Group plan review:** one `architect` pass over every plan in the wave, checking cross-step seams too. Plans are committed together on a `plan/wave-N` branch and merged to `main` as `docs: wave N low-level plans`.
3. **Implement lane by lane:** each step on its own `step/<ID>-…` branch, in dependency order, sequentially in the one folder.
4. **Group review:** the reviewers for every finished step of the wave run in parallel (one brief per step). Then a verifier per step.
5. **Close per step:** its own Outcome and squash merge (TD-036), in dependency order. TD-037 gates are unchanged; owner on-device checks and skims are collected for the whole wave.

## 4. Decision rights

| The orchestrator decides (and informs the owner) | The owner decides (the orchestrator asks first) |
|---|---|
| Low-level design inside the approved plan | **Any spec change** (new D-entry) |
| "Decide in the low-level plan" items, when researcher + architect agree and there's no cost, vendor or lock-in impact | **Changing an Accepted TD**, or a new TD with cost/vendor/lock-in impact |
| Test strategy details, refactors inside the step scope | New paid services, accounts, or anything with a running cost |
| Splitting an oversized step into a/b (inform immediately) | Cutting scope that affects a milestone or an R1 requirement |
| Fixing or logging review findings per §3.D | Security trade-offs. Accepting a known risk |
| Ordering of ready steps (each track's numbers, `steps/README.md` §7) | Destructive operations on production data or infrastructure |
| | Accepting a step as done (close gate) |

When in doubt, ask. A short question costs less than rework.

## 5. Keeping the owner in the loop

### 5.1 Cadence

| When | What | Format |
|---|---|---|
| Session start | Which step, the goal, what will be needed from the owner | 2–4 lines |
| Plan ready | **Plan approval request** (gate) | §5.2 template |
| Immediately | Owner actions needed, blockers, missing prerequisites, any deviation from spec/TDs, cost or security concerns | Short, with a recommendation |
| Step done | **Close summary** + demo instructions (gate) | §5.2 template |
| Every ~5 steps or on request | **Status report** (the `owner-update` skill): board, milestone progress, risks, open questions | ≤ 25 lines |

Messages are **mobile-friendly**: short, plain language, the decision first, then the details. Every question comes with a recommendation the owner can answer with "ok" or "rec".

### 5.2 Templates

**Plan approval request**
```
A06 · Diary domain & storage: plan ready for approval
What it builds: <1–2 lines>
Key design choices: <3–5 bullets, each with a 1-line why>
Decisions for you (if any): <question + my rec>
Size / risks: <M, ~2 sessions · main risk + mitigation>
Reply "ok" to start implementation, or comment.
```

**Close summary**
```
A06 · Diary domain & storage: done, ready for your OK
Built: <3–5 bullets>
Evidence: <tests passing, measurements>
Deviations: <none | what + why>
Follow-ups: <items logged in backlog>
Try it: <steps on the A55, if any>
Next: <proposed next step>
```

## 6. Briefing agents

Agents start with no memory of the conversation. Every brief is **self-contained**:

```
Step: A06 · Diary domain & storage · branch step/A06-diary-domain
Card: technical-planning/steps/A06-diary-domain.md (read the Low-level plan)
Work package: WP2: ChangeOps for entries + SlotAssigner
Do: <exact tasks from the plan>
Files: <expected files to touch>
Constraints: <rules from the plan/TDs that matter here>
Done when: <tests to add/pass, commands that must be green>
Report back: summary of changes, files touched, tests added, anything unexpected or deferred
```

Rules: one WP per brief. Never ask an engineer to "do the whole step". Never forward an agent's output to the owner unverified.

## 7. Quality gates (all must hold to close a step)

1. The Definition of Done (`10` §9).
2. CI green on the branch: lint, tests, architecture checks, contract checks, eval if AI-related.
3. Required reviewers report no open blockers or majors.
4. The verifier passes every exit criterion (or the owner explicitly accepts a ⚠️).
5. Card Outcome written, board updated, docs current.

## 8. Tracking

| What | Where |
|---|---|
| Step status | `steps/README.md` §4 status board |
| Plan and outcome per step | The step card |
| Follow-ups, tech debt, minor findings | `steps/backlog.md` |
| Decisions | `12-decisions-and-questions.md` (TDs), `spec/decisions.md` (product) |
| Research | `research-notes.md` |
| Code history | Branch per step, merged to `main` |

**Per-step metrics** (in the Outcome): planned vs actual size, number of WPs, review rounds, findings by severity, tests added, notable measurements. Every ~10 steps the orchestrator reviews these and proposes process changes to the owner (e.g. a step-size rule, a recurring finding becoming a lint).

## 8a. Session handoff (sessions can be lost)

Every step card has a **Progress log** section above the Outcome: one dated line per event, newest last, with what happened, what's pending, and what the owner was asked. The orchestrator **appends a line and pushes the branch** at each phase change, each WP commit, each question to the owner and each owner answer, and before any long-running agent or CI wait. The board status is updated at the same moments.

**Resuming a lost session:** read the card's Progress log → `git log` on the step branch → check CI and the ruleset with `tools/scripts/ci-status.sh` / the GitHub API → re-run any agent whose result isn't recorded in the log → tell the owner in 3 lines where things stand.

## 9. Failure handling

| Situation | Response |
|---|---|
| An agent's output is wrong or incomplete | Re-brief once with specifics. If it's still wrong, the orchestrator does it directly, or splits the WP |
| CI red | Stop the line. Fix before any new WP |
| A flaky test | Quarantine with a backlog entry and an owner-visible note. Fix within 2 steps |
| The plan is wrong mid-step | Pause. Architect consult. Update the plan in the card, and ask the owner if it changes approved scope or design |
| The step is too big | Close the finished part as `<ID>a`, create `<ID>b`, update the board, inform the owner |
| Reviewers disagree | Architect arbitrates. If it's still unresolved, the owner decides |
| A prerequisite is missing | Tell the owner immediately. Pick another ready step meanwhile |

## 10. One implementer, two tracks (TD-085, 2026-10-28)

Until 2026-10-28 the work was split between Claude (app) and Codex (backend and the no-UI app steps; TD-059, TD-061, TD-078, TD-079). **Codex is retired; Claude builds both tracks.** Finished cards, evidence and research notes keep their Codex history; `AGENTS.md` is dormant.

| Track | Steps | Main engineers | CI jobs |
|---|---|---|---|
| **App** | `A01…` (`steps/README.md` §4.1) | `flutter-engineer`, `data-curator`, `ai-engineer` (app side) | `dart`, `dart-test`, `android`; `android-it` nightly (TD-086) |
| **Backend** | `B01…` (§4.2) | `dotnet-engineer`, `platform-engineer`, `ai-engineer` (Buddy server, `buddy_eval`) | `dotnet`, `contract`, `image` |

**Rules**
- **Tracks stay separate:** a feature that needs both sides is two steps, one per track, joined by an explicit dependency (`steps/README.md` §6). Both follow §3's phases and §7's gates with the same agents and evidence standard.
- **Contract:** changes go in their own commit before any code (`10` §6), with a Progress-log line naming what changed; the dependent A step adapts the app. "(contract)" dependencies need only the B step's contract handoff merge (`Bxx (contract): …`, TD-065). Breaking changes need the owner.
- **Order:** the orchestrator picks across both tracks by the critical path (`steps/README.md` §7).
- **Reviews:** every code step gets a fresh Opus `code-reviewer`; Risky steps add `security-reviewer` and `verifier` (`PROCESS.md` B).
- **One folder:** `~/work/fitness_buddy`, one step branch at a time, from a clean `git status` on the latest `main`. No worktrees or second clone unless the owner asks. The laptop has 7 GB: one heavy build at a time (`make test-dotnet` and the Android builds don't run together).
- **Shared Dart seams:** `fb_domain`'s entry points used by `buddy_eval` (A21) and the sync engine interfaces used by `tools/sync_sim` are public APIs pinned by tests in their package; both tools run in the `dart` CI job. The pub workspace lockfile is shared.
