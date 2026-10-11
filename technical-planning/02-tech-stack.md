# 02 — Tech Stack

_Every layer: the choice, why, and the alternatives. Versions as researched in Oct 2026 (`research-notes.md`). Exact versions are pinned when each part is set up (S01–S06), and lockfiles are committed._

Selection rules, in order: (1) fits the drivers in `01` §1; (2) mature, maintained, widely used; (3) few moving parts and vendors; (4) replaceable without a rewrite (kept behind our own interfaces); (5) as few languages as the job allows. Today that's **Dart** for the app and dev tools, **C#** for the backend, joined by **one OpenAPI contract**.

## 1. Mobile app

| Concern | Choice | Why | Alternatives considered |
|---|---|---|---|
| Framework | **Flutter stable** (3.47 / Dart 3.13 at the time of writing) | Given (C-1) | — |
| UI kit | **`material_ui` package** (Material, decoupled from the framework in Aug 2026), wrapped by our `fb_design_system` | The in-framework Material is frozen and will be deprecated. Screens depend on *our* components | Fully custom widgets; Cupertino-first |
| State + DI | **Riverpod 3** with code generation. No experimental persistence or mutations | Compile-safe DI and state in one tool, clean async and streams (drift queries), easy test overrides | Bloc, Provider, get_it |
| Navigation | **go_router**, typed routes, behind an `AppRouter` wrapper | Official, deep links (NT-024), tab shells (UX-010). Maintenance mode is fine, and the wrapper keeps a swap local | auto_route |
| Local database | **drift** (SQLite) + `sqlite3_flutter_libs` | Typed SQL, reactive `watch()`, generated migration tests, transactions, FTS5 with trigram tokenizer, background isolate | Isar/ObjectBox, Hive, sqflite |
| Models | **freezed** + **json_serializable** | Immutable models, sealed unions, JSON | built_value |
| API client | **Generated from `contracts/openapi.yaml`** into `fb_api_client` (generator chosen in S02, e.g. `swagger_parser` or `openapi-generator` dart-dio), on **dio** | The app never hand-writes API types. Interceptors handle auth refresh, retry, `Idempotency-Key`, version headers, cancellation | Hand-written client |
| Sign-in SDKs | **google_sign_in**, **sign_in_with_apple** (iOS, R2, D-081) | Native flows. The ID token is sent to our API (`04` §5) | Firebase Auth, Supabase Auth |
| Barcode | **mobile_scanner** | On-device (ML Kit / Apple Vision), fast | — |
| Camera / images | **image_picker** + **flutter_image_compress** | Photos resized to ~1024 px JPEG before upload | `camera` |
| Charts | **fl_chart** behind design-system chart widgets. Feasibility check at the start of S22, with `CustomPainter` as the fallback | Free, flexible, popular | Syncfusion (licence), `graphic` |
| Local notifications | **flutter_local_notifications** + **timezone** | All R1 notifications are local (`09` §1) | FCM (R2+ if needed) |
| Prayer times | **adhan_dart** (offline) | No network. Multiple calculation methods | Aladhan API |
| Hijri calendar | An Umm al-Qura package (chosen in S46) + the user's ±1-day shift | LC-020, LC-030 | — |
| Localization | **gen-l10n (ARB)** + `intl` | Official. Strings externalized from R1, so the R2 Arabic UI is translation work | easy_localization |
| Secure storage | **flutter_secure_storage** | Tokens in Keychain/Keystore | — |
| Connectivity | **connectivity_plus** + a real reachability check | Drives queues (AC-020) | — |
| Errors / performance | **sentry_flutter** | Crashes, release health, traces, PII scrubbing | Crashlytics |
| R2 extras | `health`, `home_widget`, a share-intent package | Picked when R2 starts | — |

**Fonts:** bundled Latin + Arabic pair with matching weights, e.g. Inter + IBM Plex Sans Arabic (chosen in S07).

## 2. Backend (`04`)

| Concern | Choice | Why | Alternatives considered |
|---|---|---|---|
| Runtime / language | **.NET 10 (LTS, supported to Nov 2028), C#** | Fast, strongly typed, rich built-in platform, long support | Spring Boot (Kotlin), NestJS (TypeScript), Go, FastAPI (Python). See Appendix B |
| Web | **ASP.NET Core Minimal APIs** (endpoint groups per module) | Lean, fast, first-class OpenAPI generation, built-in rate limiting, health checks, output caching, problem details | Controllers (more ceremony) |
| Architecture | **Modular monolith, clean/hexagonal layers per module** | SOLID boundaries without microservice overhead (`04` §3) | Microservices, flat layered app |
| Data access | **EF Core 10 + Npgsql**, **Dapper** for hot paths | Migrations, JSONB, strong Postgres support. Raw SQL where it matters | Dapper only, Marten |
| Database | **PostgreSQL 18**: `pg_trgm` for search, JSONB for synced documents, RLS for defense in depth | One relational store for everything | — |
| Jobs / events | **Postgres-backed queue** (`SKIP LOCKED`) + transactional outbox, in `BuildingBlocks` (or Hangfire if S04 finds the in-house version insufficient) | One stateful dependency (TD-025) | Redis + queue library, RabbitMQ |
| Auth | Our **Identity module**: JWT ES256 via `Microsoft.IdentityModel`, JwtBearer validation, OIDC ID-token verification for Google/Apple, email one-time codes | No auth vendor. Narrow, well-known flows (`04` §5) | Supabase Auth, Firebase Auth, Zitadel/Keycloak |
| Validation | ASP.NET Core built-in validation or FluentValidation (decided in S03) + JSON Schema validation of sync payloads (JsonSchema.Net) | Contract-driven input checks | — |
| AI providers | Official SDKs where stable (`Anthropic` NuGet, beta; `OpenAI`; `Google.GenAI`), or plain REST, **always behind our `ILlmClient` port** | Swappable, testable, per-task routing (`06` §9) | Semantic Kernel / Microsoft.Extensions.AI (possible inside an adapter) |
| Observability | **OpenTelemetry .NET** (traces, metrics, logs) + **Sentry .NET** | Vendor-neutral telemetry | — |
| Tests | **xUnit v3**, **Testcontainers** (real Postgres), `WebApplicationFactory`, **ArchUnitNET**, Verify (snapshots), recorded LLM fixtures | Real-database tests, enforced architecture | — |

## 3. Contract & code generation

| Concern | Choice |
|---|---|
| Contract | **OpenAPI 3.1**, written per module in `contracts/openapi/`, bundled by **Redocly CLI** into `contracts/openapi.yaml` |
| Style lint | **Spectral** with our ruleset (`04` §4.2) |
| Breaking changes | **oasdiff** in CI against the last released contract |
| Dart client | Generated into `packages/fb_api_client` (S02 picks the generator) |
| Server conformance | The backend's generated OpenAPI document must match the contract (S02 sets up the diff) |
| Shared test data | `contracts/testdata/` holds the golden files both stacks run: text normalization cases (TD-030), sync payload examples, problem-details examples |

## 4. Infrastructure (`08`)

| Concern | Choice |
|---|---|
| Cloud | **Hetzner Cloud**, Germany: VMs, private network, firewalls, volumes, object storage, load balancer at stage 2 |
| Infra as code | **OpenTofu** (`hcloud` provider) + **cloud-init** |
| Deploys | **Kamal 2** (zero downtime, automatic TLS, one-command rollback), images in **GHCR** |
| Access | **Tailscale** for SSH. No public SSH |
| DNS | **Cloudflare** (DNS only) |
| Backups | **WAL-G** (or pgBackRest) → object storage in another DC + weekly copy to a second provider |
| Monitoring | **Grafana Cloud** (OpenTelemetry), **Sentry**, an external uptime monitor |
| Email (sign-in codes) | Transactional email provider, chosen in S24 (e.g. Postmark, Amazon SES, Resend) |

## 5. AI

| Concern | Choice | Why |
|---|---|---|
| Model provider | **Chosen by the S10 bake-off** on the spec's test set. Candidates (paid tiers, no training on our data): **Claude Haiku 5.5** ($0.10 in / $0.50 out per M tokens), **Gemini Flash-Lite class**, **GPT-5.x nano/mini** | Arabic/Arabizi understanding and latency from the region must be measured |
| Integration | `ILlmClient` port in the Buddy module, one adapter per provider, structured output (JSON schema) on every call, per-task routing table, fallback provider | Swappable, measurable |
| Vision | The same provider's multimodal model if it passes the label eval, otherwise route vision separately | On-device ML Kit has no Arabic script, and labels can be Arabic (D-073) |
| Embeddings | Only if the eval shows trigram + alias matching isn't enough (`pgvector`) | Avoid unmeasured complexity |

## 6. Tooling & delivery

| Concern | Choice |
|---|---|
| Repo | **Monorepo** (`10` §1): Dart pub workspace (app, packages, tools) + a .NET solution (`backend/`) + `contracts/` + `infra/` |
| Task runner | Root **Makefile**: one entry point for both stacks (`make check`, `make gen`, `make test`, `make eval`, `make up`). **melos** inside the Dart workspace |
| Lints | Dart: `very_good_analysis` + import-boundary check. C#: .NET analyzers at `latest-recommended`, warnings as errors, `dotnet format` |
| CI/CD | **GitHub Actions** (`10` §7). Android builds on Linux runners. iOS builds (R2, D-081) via **Codemagic** or GitHub macOS runners |
| Distribution | R1: **Google Play internal testing** (owner, Android). R2: + iOS via TestFlight (D-081). R3: stores |
| Dependency updates | Renovate or Dependabot for pub, NuGet, GitHub Actions and Docker base images |

## 7. Running cost

See `08` §9: **≈ €35–55/month** in stage 1 plus store fees. AI is cents per month for the owner and ≈ $5–15 per month for R2 friends (`06` §10).

---

## Appendix A — Why not Supabase (owner request, 2026-10-11)

Supabase is managed Postgres (on AWS) plus an **auto-generated REST API over your tables**, Auth, Storage, Realtime and Edge Functions. The app talks **directly to the database** with a public key, and security comes from row-level security (RLS) policies. It was the first draft's choice.

**What it does well:** it saves weeks (auth with Google/Apple/email/anonymous and identity linking, a managed database with backups, a dashboard), needs almost no ops, starts free (Pro $25/mo), and the data is plain Postgres.

**The catches:**

| # | Catch | Why it matters for us |
|---|---|---|
| 1 | **The database is the API.** The table shape becomes the contract | Against our "decoupled, defined contract" requirement. Schema changes can break installed apps |
| 2 | **RLS is the only wall.** The public key ships in every app | A common real failure: a Sept 2026 UpGuard report found 16,000+ misconfigured Supabase databases exposing personal data. CVE-2025-48757 hit 170+ apps. With our backend, RLS is a *second* wall |
| 3 | **Logic gets scattered** across SQL functions, RLS policies, Edge Functions (TypeScript) and the app | Harder to test, review and grow |
| 4 | **Pro backups are daily, kept 7 days.** Point-in-time recovery is an add-on (reported ≈ $100/mo per 7 days of retention) | Without it, up to 24 h of data can be lost (against SC-6) |
| 5 | **Cost steps.** Pro includes only a Micro instance (1 GB RAM). Bigger compute, PITR, egress and MAU overages add up. Team (SOC 2, SSO) is $599/mo | Fine for R1/R2. Several times the cost of VMs at R3 scale |
| 6 | **Lock-in in the edges.** The `auth` schema, `auth.uid()` in policies, the SDK all over the app | Leaving means rewriting auth and the app's data layer. Self-hosted Supabase is ~10 containers and lacks some cloud features |
| 7 | **Limited control.** No SSH, no superuser, curated extensions, their maintenance and outages | The owner wants machines they control |
| 8 | Free projects pause after 7 days idle | Affects staging and dev |

| Criterion | Supabase-centric | **Own backend on VMs** ⭐ | Hybrid (own backend + managed Postgres/Auth) |
|---|---|---|---|
| Time to the first usable app | Fastest | +2–4 weeks | +1–2 weeks |
| Ops burden | Lowest | 1–2 h/month | Low |
| App ↔ backend contract | Weak | **Strong** | Strong |
| Security model | RLS only | **Backend authorization + RLS** | Backend + RLS |
| Data loss window | 24 h without the add-on | **≈ 1 min, tested weekly** | Depends on the add-on |
| Cost at R3 scale | Highest | **Lowest** | Middle |
| Lock-in | Auth + SDK + RLS design | **None** | Auth |

**Verdict:** own backend. **The hybrid is the fallback** if running Postgres becomes a burden. Because the backend owns the API, the app never notices.

## Appendix B — Backend frameworks considered

| Language | Frameworks | Strengths | Why not chosen |
|---|---|---|---|
| **C#** | **ASP.NET Core** ✅ | Fast, typed, built-in DI/config/rate limiting/health/OpenAPI, LTS, few dependencies | — |
| Kotlin / Java | Spring Boot, Quarkus, Micronaut, Ktor | The enterprise default, huge ecosystem | Heavier (JVM memory), more framework magic. A close second |
| TypeScript | NestJS, Fastify, Express, Hono | Best AI SDK coverage | Types are compile-time only, large npm trees, dependency churn |
| Go | net/http + chi/Gin/Echo | Small, fast, simple to deploy | Verbose for JSON/schema-heavy work, structure is all on us |
| Python | Django, FastAPI | Best AI/data ecosystem | Slower, weaker typing, heavier ops |
| Dart | shelf, dart_frog, Serverpod | Shares code with the app | Thin server ecosystem, no official AI SDKs. Rejected by the owner (TQ-12) |
