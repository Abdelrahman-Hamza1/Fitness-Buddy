# Fitness Buddy — Technical Planning

> How we build what `spec/` describes. `spec/` stays the source of truth for **what** and **why**. This folder covers **how**.
> If something here contradicts the spec, the spec wins. Either this folder gets fixed, or a spec change goes through `spec/decisions.md` first.

_Status: **Plan v2** · 2026-10-11 · Based on spec D-001 to D-081. R1 is Android-only (D-081). Backend reworked to an own ASP.NET Core API on Hetzner VMs (TD-021–TD-030, owner-accepted). Delivery split into 49 step cards (`steps/`)._

## Status

| Item | State |
|---|---|
| Spec read in full (all files, D-001–D-080) | ✅ |
| Research (versions, prices, licences, hosting) | ✅ rounds 1–2, `research-notes.md` |
| Technical decisions | 34 TDs: backend/infra **accepted**, spikes pending, others Proposed (accepted when implemented) (`12`) |
| Open owner questions | 6 (`12` §2.1), none blocking. TQ-22 answered: Android-first R1 (D-081) |
| Delivery plan | 49 steps + 6 data batches, each with a card (`steps/README.md`) |
| Code | S01, S02, S03, S06, S08 done. Two implementers (TD-059/061): Codex on backend + integration (`AGENTS.md`, S04 next), Claude on the app (`CLAUDE.md`). See the board's Owner column |

## The plan in one page

**Local-first app + a modular backend behind a versioned contract.**

```
 Phone (Flutter, Dart)                                Cloud (Hetzner, Germany)
┌───────────────────────────────────────┐        ┌─────────────────────────────────────────┐
│ UI (features) ── Riverpod view models │        │ Fitness Buddy API  (ASP.NET Core, C#)   │
│        │                              │ HTTPS  │  modular monolith, clean layers:        │
│ Application: actions, proposals,      │ OpenAPI│  Identity · UserData (sync) · Buddy ·   │
│   ChangeSetApplier (the ONLY writer)  │  v1    │  Catalog · Usage · Account              │
│        │                              │◄──────►│  roles: api · worker · migrate          │
│ Domain (fb_domain, pure Dart):        │  JWT   ├─────────────────────────────────────────┤
│   nutrition math, ProposalEngine,     │        │ PostgreSQL 18 (only stateful part)      │
│   targets, trend, QueryEngine, …      │        │  + point-in-time backups, 2 providers   │
│        │                              │        └───────────────┬─────────────────────────┘
│ SQLite (drift) = source of truth      │                        ▼
│ Offline food pack + exercise library  │          AI provider (chosen by eval) · OFF · email
└───────────────────────────────────────┘
        ▲ generated client (fb_api_client) ◄── contracts/openapi.yaml ──► server conformance
```

The ideas that carry the design:

1. **The phone's SQLite is the source of truth.** Everything except AI works offline (D-007). Reads are instant. Sync copies data to the account.
2. **AI interprets, code computes.** The model turns text/photos into structured interpretations. Deterministic Dart on the phone produces every number (D-011, AQ-09).
3. **One writer.** Every change goes through `ChangeSetApplier`, only on a user tap. The AI's response type can't express a write, so AQ-01 holds by construction.
4. **The contract is the only coupling.** `contracts/openapi.yaml` defines the API. The Dart client is generated, and the server is checked against it. Either side can change freely as long as the contract holds.
5. **A modular monolith with clean layers** (SOLID): each backend module owns its schema and talks to others only through interfaces or outbox events. It's simple to run now, and modules can be extracted later.
6. **The server stores synced data as validated JSON documents**, so the backend doesn't change when the app's data model grows (TD-031).
7. **Postgres is the only stateful component**, on its own VM, with point-in-time backups to two providers and a **restore test every week**.
8. **Servers are built from code** (OpenTofu, cloud-init) and deployed with zero downtime and one-command rollback (Kamal).
9. **The AI model is chosen by measurement** (S10 bake-off) behind a provider-agnostic port. The eval suite gates every AI change.
10. **The user model is structured and visible**: Buddy learns habits only from confirmed data and shows everything it uses (TD-032).

**Stack:** Flutter · Riverpod 3 · go_router · drift · freezed · `material_ui` · **ASP.NET Core (.NET 10 LTS)** · EF Core + Npgsql · **PostgreSQL 18** · OpenAPI 3.1 (Redocly, Spectral, oasdiff) · **Hetzner** · OpenTofu · Kamal 2 · Tailscale · OpenTelemetry → Grafana Cloud · Sentry · GitHub Actions. Details and alternatives: `02`.

**Delivery:** P0 foundations and spikes → P1 manual tracker → P2 targets & weight → P3 accounts, sync, production → **Dogfood 1** → P4 Buddy core → P5 Buddy breadth → **Dogfood 2** → P6 workouts → P7 insights, notifications, Ramadan → P8 hardening → **R1**. See `11` and `steps/`.

## File map

| File | What it answers |
|---|---|
| `01-drivers-and-risks.md` | Quality drivers, R1 scale, top risks, spec gaps and their handling |
| `02-tech-stack.md` | Every layer's choice, why, and the alternatives. Appendix A: why not Supabase. Appendix B: backend frameworks compared |
| `03-architecture.md` | System context, app layers and modules, the write pattern (proposal → change set), Buddy message lifecycle, cross-boundary contracts |
| `04-backend.md` | The API: modules, clean layers, the contract and its conventions, endpoints, identity & auth, authorization, server storage, scaling |
| `05-data-and-sync.md` | Data conventions, entities, local DB, server storage, the sync protocol, guest mode and account lifecycle, retention |
| `06-buddy-ai.md` | The AI pipeline: interpret → resolve → propose, ask-vs-assume, the user model, Q&A without made-up numbers, photos/labels/imports/review, providers, budgets, evals |
| `07-food-data.md` | Food sources and licensing, the reference-dish pipeline, normalization and search, catalog builds, barcodes |
| `08-infrastructure-and-operations.md` | Hetzner environments, topology and scaling stages, provisioning and deploys, backups and restore, server security, observability, runbooks, cost |
| `09-cross-cutting.md` | Notifications, time & Ramadan, localization/RTL, security & privacy, observability, performance, accessibility, errors, configuration |
| `10-engineering-practices.md` | Repo layout, conventions for both stacks, enforced architecture rules, testing, traceability, git workflow, CI/CD, Definition of Done |
| `11-roadmap.md` | Phases, milestones, the step list with dependencies, R2/R3 outlines |
| `12-decisions-and-questions.md` | Technical decision log (TD-001–TD-034) and the owner's open/answered questions |
| `13-delivery-process.md` | **How work gets done:** orchestrator + specialist agents, the step lifecycle, owner gates, decision rights, communication, quality gates |
| `steps/` | **One card per step** + the session protocol, card template, status board and owner prerequisites (`steps/README.md`) |
| `research-notes.md` | What was looked up, sources, and what still needs verifying |

## How to use this folder

- **To start building:** ask the session to run the next step. It uses the `run-step` skill and the process in `13-delivery-process.md`. Agents live in `.claude/agents/`, skills in `.claude/skills/`.
- **To challenge a decision:** find it in `12`. Proposed decisions can be changed by discussion. Accepted ones get a new superseding entry.
- **To understand a part of the system:** the file map above. Each step card lists the sections to read.
- **When reality differs from the plan:** fix the plan in the same PR (an outdated doc is a bug), and record significant changes as TDs.
