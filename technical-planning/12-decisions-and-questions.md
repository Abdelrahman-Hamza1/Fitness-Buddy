# 12 — Technical Decisions & Open Questions

## 1. Technical decision log (ADR-lite)

Same discipline as `spec/decisions.md`: a decision that's been **Accepted** is never rewritten. A change gets a new entry that supersedes it.

**Statuses:** **Proposed** (the plan's default; it becomes **Accepted** automatically when the step that implements it is merged, unless the owner objected) · **Pending spike** (decided by a Phase 0 spike or a feasibility check) · **Accepted** · **Rejected** · **Superseded by TD-xxx**.

| ID | Decision | Status | Main reason | Alternatives | Details |
|---|---|---|---|---|---|
| TD-001 | **Local-first**: the phone's SQLite is the source of truth. The server holds a synced copy | Proposed | Offline (D-007), speed (UX-007), guest mode, durability | Server-first with cache | `03` §2, `05` |
| TD-002 | All-Dart stack (app, packages, gateway, eval, tools) | **Rejected** (TQ-12, 2026-10-11) | Owner prefers a non-Dart backend | → TD-021 | — |
| TD-003 | **Riverpod 3** for state + DI (no experimental persistence or mutations) | Proposed | Compile-safe, async/stream-friendly, testable | Bloc, Provider | `02` §1 |
| TD-004 | **go_router** behind an `AppRouter` wrapper | Proposed | Official, deep links, tab shells. Maintenance mode is acceptable | auto_route | `02` §1 |
| TD-005 | **drift** with two DB files: `user.db` (r/w, one per account) and `catalog.db` (read-only offline pack) | Proposed | Typed SQL, reactive streams, migration tests, FTS5. The pack updates independently | Isar, ObjectBox, sqflite | `05` §3 |
| TD-006 | **Custom delta sync**: row-level LWW with HLC, outbox via triggers, `server_seq` pull cursor, 30-day history, behind a `SyncEngine` interface. PowerSync is plan B | **Pending spike S12** | Single-owner data makes sync simple. Keeps full drift features. No vendor | PowerSync, ElectricSQL | `05` §5 |
| TD-007 | Supabase (EU) + Dart gateway on Cloud Run | **Superseded by TD-021–TD-026** | Owner wants own backend on VMs and a decoupled contract | — | `02` App. A |
| TD-008 | **AI model chosen by an eval bake-off** (Claude Haiku 5.5 vs Gemini Flash-Lite class vs GPT-5.x nano/mini). `ILlmClient` port, per-task routing, fallback provider | **Pending spike S10** | Arabic/Arabizi quality and latency must be measured | Pick by reputation | `06` §9, §11 |
| TD-009 | **AI interprets, code computes.** Interpretations carry alternatives. **ProposalEngine and QueryEngine run on the phone.** Number guard on generated text (on the phone) | Proposed | D-011, AQ-01/08/09 guaranteed by construction. Instant chip taps. No AI cost for adjustments | Model computes numbers. Server builds proposals | `06` §3–6 |
| TD-010 | **Food data:** USDA FDC (CC0) basics + our reviewed reference dishes (YAML) + OFF via the API, **licence-isolated** + label scan. No commercial API in R1 | **Pending spike S11** | Licensing (C-5), local coverage, offline pack | FatSecret, Nutritionix, Edamam | `07` |
| TD-011 | **Single writer**: all user-data writes are `ChangeSet`s applied by `ChangeSetApplier`. Direct actions get undo. AI produces proposals only | Proposed | D-079, AQ-01, undo, atomicity, audit | Writes from view models | `03` §5 |
| TD-012 | **fl_chart** wrapped by design-system chart widgets, `CustomPainter` fallback | **Pending check at the start of S22** | Free, flexible, popular | Syncfusion, graphic | `02` §1 |
| TD-013 | **Local notifications only in R1**, from a pure `NotificationPlanner` + an idempotent scheduler | Proposed | All conditions are on the device. Privacy. No push infrastructure | FCM push | `09` §1 |
| TD-014 | **`material_ui` package** as the base, wrapped by `fb_design_system` | Proposed | Avoids the coming migration off in-framework Material | In-framework Material, Cupertino | `02` §1 |
| TD-015 | **Monorepo** (revised 2026-10-11): Dart pub workspace + .NET solution + `contracts/` + `infra/`, a root Makefile. Feature-first folders with barrels in the app. One project per module in the backend | Proposed | One place for everything a solo developer touches. Hard boundaries where they matter | Separate repos | `10` §1 |
| TD-016 | Guests = Supabase anonymous users | **Superseded by TD-024** | Same behaviour, own Identity module | — | `04` §5 |
| TD-017 | **Data conventions:** UUIDv7, canonical units + original input, nutrient snapshots, `local_date` + tz offset, provenance fields, tombstones, HLC | Proposed | Offline IDs, FD-073, DY-001/002, SC-4 | — | `05` §1 |
| TD-018 | **Quality gates in CI:** domain coverage ≥ 95%, migration tests (drift + EF), sync convergence tests, RLS tests, architecture tests (both stacks), contract gates, AI eval thresholds, traceability | Proposed | Reaching R3 with one developer needs safe refactoring | Manual testing | `10` §3–7 |
| TD-019 | **Sentry** for errors (scrubbed). **No product analytics in R1.** Proposal outcomes stay in the user's own data | Proposed | Privacy (AC-040). The owner is the only user | Firebase Analytics, PostHog | `09` §5 |
| TD-020 | **Export is generated on the device** (CSV + JSON) | Proposed | Works offline and for guests. No server job | Server-side export | `05` §6 |
| TD-021 | **Backend in C# on .NET 10 (LTS), ASP.NET Core Minimal APIs**. Dart stays for the app and dev tools. No mediator library | **Accepted** (owner, 2026-10-11) | Robust, fast, typed, rich built-in platform, LTS to Nov 2028 | Spring Boot, NestJS, Go | `04` §2, `02` App. B |
| TD-022 | **Modular monolith, clean/hexagonal layers per module.** Modules own their schema and talk via public interfaces or outbox events. One image, roles `api` / `worker` / `migrate` | **Accepted** (owner, 2026-10-11) | SOLID boundaries without microservice overhead | Microservices | `04` §3 |
| TD-023 | **Contract-first REST**: OpenAPI 3.1 in `contracts/` is the source of truth, generated Dart client, server conformance, oasdiff, Spectral. RFC 9457 errors, idempotency keys, cursor pagination, `/v1` versioning | **Accepted** (owner, 2026-10-11) | Decouples app and backend | gRPC, GraphQL, code-first | `04` §4 |
| TD-024 | **Own Identity module**: Google/Apple ID-token verification, passwordless email codes, anonymous guests, identity linking, own JWT (ES256) + rotating refresh tokens | **Accepted** (owner, 2026-10-11, TQ-21) | No auth vendor. Narrow, well-known flows | Supabase Auth, Firebase Auth, Zitadel | `04` §5 |
| TD-025 | **PostgreSQL 18 is the only stateful dependency** (Postgres-backed queue and outbox). RLS as defense in depth. Redis only when measured | **Accepted** (owner, 2026-10-11) | Fewer moving parts | Redis/RabbitMQ from day one | `04` §3.4, §6 |
| TD-026 | **Hetzner Cloud VMs, Germany**: app VM + separate db VM from Dogfood 1, a staging VM. Stage 2: load balancer, more app VMs, replica, PgBouncer. Self-hosted Postgres | **Accepted** (owner, 2026-10-11, TQ-19/20) | Cheap, simple, SSH control, clear scale path | DigitalOcean (managed PG), AWS/GCP, Supabase | `08` |
| TD-027 | **Kamal 2** deploys (zero downtime, rollback). **OpenTofu + cloud-init** for infrastructure. A separate `migrate` step before each deploy | **Accepted** (owner, 2026-10-11) | Repeatable servers, safe deploys | Compose by hand, Kubernetes | `08` §4 |
| TD-028 | **Backups:** WAL-G/pgBackRest point-in-time recovery → object storage in another DC + a second provider. **Automated weekly restore test** | **Accepted** (owner, 2026-10-11) | SC-6 "nothing is lost" | VM snapshots | `08` §5 |
| TD-029 | **Observability:** OpenTelemetry → Grafana Cloud + Sentry + an external uptime monitor | **Accepted** (owner, 2026-10-11) | Vendor-neutral telemetry | Provider-specific monitoring | `08` §7 |
| TD-030 | **Text normalization implemented twice** (Dart + C#) against one shared golden file. The weekly-review number guard runs on the phone | **Accepted** (owner, 2026-10-11) | The price of a non-Dart backend, kept small and tested | Normalization only on the client | `07` §5.1 |
| TD-031 | **Server stores synced user data as versioned JSON documents** per (user, entity, id), validated against contract schemas, not as mirrored relational tables. Server-side projections only if a future feature needs them | Proposed (confirmed or revised by S12) | Backend decoupled from the app's data model, one sync path, trivial deletion | Mirrored typed tables | `04` §7, `05` §4 |
| TD-032 | **User model = structured, on-device and visible**: explicit memory + habits derived deterministically from confirmed data, promoted to memory only by user acceptance. No hidden model-written profile | Proposed (owner's TQ-07 idea, interpretation to confirm) | AI-082 (nothing secret), AC-041, testable | A model-written free-text profile | `06` §5 |
| TD-033 | **Delivery in step cards** (`steps/`): one card per session, low-level plan + implementation + outcome in the card. Sessions follow `steps/README.md` | Proposed | Lets the owner run one focused session per step with a clear brief and exit criteria | One big roadmap | `steps/` |
| TD-034 | **Android-first R1**: build, test and ship to the owner on Android (A55, Play internal testing). **All iOS work in R2**: builds, TestFlight, Sign in with Apple, the iPhone performance check. No Android-only shortcuts in shared code | **Accepted** (owner, 2026-10-11, TQ-22 → spec D-081) | Owner is on Android with no Mac. No iPhone user in R1 | iOS in R1 via Codemagic | `11` §5 |
| TD-035 | **AI stack:** no agent framework. Our `ILlmClient` port (Buddy module) built on **Microsoft.Extensions.AI `IChatClient`** with the official provider SDKs (Anthropic, OpenAI, Google), structured output from C# record schemas + validation + one repair retry, versioned prompt files, OpenTelemetry GenAI tracing with **content capture off**, quality owned by our `buddy_eval` suite | **Accepted** (owner, 2026-10-11) | One standard .NET AI interface, swappable providers, no lock-in, minimal machinery. Buddy is one structured call per message, not an autonomous agent | Microsoft Agent Framework / Semantic Kernel, LangChain-style frameworks, raw REST per provider | `06` §9.1 |
| TD-036 | **Squash-merge each step** into `main` as one commit `Sxx: <step name>` | **Accepted** (owner, 2026-10-11) | A clean history: one commit per step, easy to revert | Merge commits, rebase | `13` §3.E |

## 2. Questions for the owner

### 2.1 Open

**TQ-01 Capacity.** Roughly how many hours a week will you build? Any target date for Dogfood 1? (Already answered: no Mac.) This lets me turn step sizes into dates.
**A:**

**TQ-07 (confirm) "Mental model" of each user.** I've designed it as TD-032: Buddy learns your habits (usual foods per meal, portions, cooking fat, variants, brands, times) **only from what you confirmed**, offers to remember them, and shows everything on "Buddy remembers". There's no hidden profile. Real messages can become test cases when you export them. OK?
_Rec: yes._
**A:**

**TQ-08 Reference dishes.** I draft each dish with cited sources, CI validates the numbers, and you skim batches. Any family recipes you'd like used as the reference (e.g. your mom's maqluba)?
**A:**

**TQ-10 Phase order.** The plan builds **sync before Buddy** (Dogfood 1 = a manual tracker with safely synced data, then Buddy). The alternative is Buddy first.
_Rec: sync first._
**A:**

**TQ-11 Sync approach.** Custom sync (recommended) vs PowerSync from day one. Either way the S12 spike decides on evidence. Any preference?
_Rec: let the spike decide._
**A:**

**TQ-16 Product analytics.** Any usage analytics in R1/R2 beyond crash reports?
_Rec: none in R1. Decide for R2, with consent._
**A:**

### 2.2 Answered (kept for the record)

| Q | Answer | Effect |
|---|---|---|
| TQ-01 (part) | No Mac | → TQ-22 |
| TQ-22 | "Use my Android to test, push iPhone stuff for later" | Spec D-081, TD-034: Android-only R1, iOS in R2 |
| TQ-02 | Samsung A55 | Reference device for AT-004 and performance budgets |
| TQ-03 | Process queued messages on next open/online; remove from spec if hard | `03` §6 |
| TQ-04 | rec: the weekly-review narrative is generated on the next online open | S44 |
| TQ-05 | rec: anonymous server identity for guests, data stays on the phone | `04` §5 |
| TQ-06 | rec: standard paid API terms for R1/R2, zero data retention before R3 | `06` §9 |
| TQ-09 | Budget not important for now | `08` §9 |
| TQ-12 | No Dart backend | TD-002 rejected → TD-021 |
| TQ-13 | Not experienced in Flutter. Oversees the architecture, not the Flutter code | Steps carry clear exit criteria and demos. Idioms follow mainstream defaults |
| TQ-14 | rec: I propose the design system + mockups | S07 |
| TQ-15 | "Whatever you like" | `main`, private repo (S01) |
| TQ-17 | Arabic scope trimmed | Spec D-080 |
| TQ-18–21 | rec: ASP.NET Core · Hetzner · self-hosted Postgres · email one-time codes | TD-021–TD-028 accepted |
