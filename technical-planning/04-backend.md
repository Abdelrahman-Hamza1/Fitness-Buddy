# 04 — Backend: Architecture, API Contract & Auth

_The Fitness Buddy API: an ASP.NET Core service the app talks to through a versioned contract. Hosting and operations are in `08`. Decisions: TD-021 to TD-025, TD-030, TD-031._

## 1. Role of the backend

The app is **local-first** (TD-001): the phone holds the user's data and computes every number. The backend does what the phone can't:

| Job | Module |
|---|---|
| Accounts and sign-in (Google, Apple, email code, anonymous guests) | Identity |
| Store the account's copy of user data, and sync it between devices (with 30-day history) | UserData |
| Turn messages and photos into structured interpretations with an AI model | Buddy |
| Serve the global food catalog, online search, barcode lookups (Open Food Facts cache), offline pack manifests | Catalog |
| Count AI usage, enforce fair use (R2) and allowances (R3) | Usage |
| Account deletion and other account lifecycle jobs | Account |
| Push notifications (R2+), billing (R3) | Notifications, Billing (later) |

The backend **never computes nutrition numbers** (TD-009). It doesn't need to understand the user's data to sync it (TD-031). That keeps it thin where it matters and lets it scale horizontally.

## 2. Stack

**C# on .NET 10 (LTS, supported until Nov 2028), ASP.NET Core Minimal APIs, EF Core 10 + Npgsql, PostgreSQL 18.** Why, and the alternatives considered: `02` §2 and Appendix B.

## 3. Architecture: modular monolith, clean layers

One deployable, split into **modules (bounded contexts)**. Each module is a C# project that owns its own Postgres schema. Microservices are deliberately avoided: for a solo developer they add network failure modes and deploy overhead with no benefit. Because every module boundary is already an interface, any module can become its own service later.

### 3.1 Modules

| Module | Postgres schema | Owns | Outbound ports (adapters live in Infrastructure) | Release |
|---|---|---|---|---|
| **Identity** | `identity` | users, identities, devices, refresh-token families, signing keys | `IOidcTokenVerifier` (Google, Apple), `IEmailSender` | R1 |
| **UserData** | `userdata` | synced user documents, `row_history`, per-user `server_seq` cursor | — | R1 |
| **Buddy** | `buddy` | idempotency records, prompt registry metadata | `ILlmClient` (one adapter per provider), Catalog's `IFoodResolver` | R1 |
| **Catalog** | `catalog` | foods, names/aliases (normalized), reference dishes, yields, portion words, exercises, `off_cache` (licence-isolated, `07` §3), pack manifests | `IOpenFoodFactsClient`, `IObjectStorage` | R1 |
| **Usage** | `usage` | AI usage counters per user per day, limits | — | R1 counters · R2 fair use · R3 allowances |
| **Account** | `account` | deletion requests and their progress | integration events to every module | R1 |
| Notifications | `notifications` | push tokens, delivery log | `IPushSender` (FCM/APNs) | R2+ |
| Billing | `billing` | entitlements, store receipts | store receipt verification | R3 |

### 3.2 Layers inside every module (clean / hexagonal)

```
 HTTP ─► Api            endpoint group, request/response DTOs (from the contract), auth policy
           │
           ▼
         Application    one handler per use case (InterpretMessage, PushChanges, LookupBarcode…)
           │            + the ports (interfaces) it needs
           ▼
         Domain         entities, value objects, rules. Pure C#, no I/O
           ▲
         Infrastructure adapters implementing ports: EF Core/Dapper repositories,
                        Anthropic/OpenAI/Gemini clients, OFF client, S3, email
```

Dependencies point inward. Domain and Application never reference Infrastructure or ASP.NET. One **composition root** (`Host`) wires everything with the built-in dependency injection.

**SOLID in practice:**

| Principle | Where it shows up |
|---|---|
| Single responsibility | One handler per use case. Adapters only do I/O. Endpoints only map HTTP ↔ handler. |
| Open/closed | A new AI provider, email vendor or food source is a **new adapter class**. Pipelines aren't edited. |
| Liskov substitution | Every adapter of a port passes **the same contract test suite** (e.g. all `ILlmClient`s against recorded fixtures). |
| Interface segregation | Small ports (`IFoodSearch`, `IBarcodeLookup`, `TimeProvider`, `IIdGenerator`), never a "god service". |
| Dependency inversion | Application code depends on ports. Tests swap in fakes. No static calls to time, randomness or I/O. |

**No mediator library.** Handlers are plain classes injected into endpoints. It's explicit, debuggable, and has no licence risk.

### 3.3 Module rules (enforced in CI)

1. A module **never touches another module's tables**. It calls the other module's **public interface** (a small `*.Contracts` namespace) in process, or reacts to its **integration events**.
2. Integration events go through a **transactional outbox**: written in the same transaction as the change, delivered by the worker, and handled idempotently. Nothing is lost and there are no dual-write bugs.
3. Module internals are `internal`, except validated request records under `*.Api` (the .NET validation generator requires public DTOs). **ArchUnitNET tests** enforce layer direction, module isolation (public DTOs are not contracts), the public surface, Host/BuildingBlocks boundaries and injected time/IDs. Broken fixtures prove the rules fail.
4. Shared code lives in `BuildingBlocks` and stays small: result/error types, outbox, job queue, auth context, `TimeProvider`, `IIdGenerator` (UUIDv7), problem-details mapping, test helpers.

### 3.4 Process roles

The same container image runs as:
- **`api`**: stateless HTTP. Add instances to scale.
- **`worker`**: outbox delivery and scheduled jobs: purge `row_history` older than 30 days (AC-012), compact tombstones, finalise account deletions (AC-031), expire the OFF cache, publish catalog packs.
- **`migrate`**: a one-shot command that applies database migrations before a deploy switches traffic (`08` §4).

**Job queue:** Postgres-backed (`FOR UPDATE SKIP LOCKED`), plus five-field UTC cron schedules. S04/TD-062 use an explicit connection/transaction session: database-only handler effects, processed markers and acknowledgement commit together, with savepoint rollback on failure and capped retries/dead letters. External effects need adapter idempotency keys. Schedule cursors persist; missed ticks coalesce into one job. No Redis or RabbitMQ until a measurement says so (TD-025).

## 4. The API contract (TD-023)

### 4.1 Contract-first

- **`contracts/openapi/` (OpenAPI 3.1) is the source of truth** for every endpoint, DTO, error code and header. It's split per module and bundled into one `openapi.yaml`. Contract changes are reviewed like code.
- **Dart client generated** into `packages/fb_api_client` (never hand-edited). The app depends only on this package.
- **Server conformance:** CI generates the backend's OpenAPI document and diffs it against the contract. Any mismatch fails the build.
- **Breaking-change gate:** `oasdiff` fails the build on a breaking change to a published version. Breaking changes need `/v2` next to `/v1`.
- **Style lint:** a Spectral ruleset encodes §4.2, so the conventions are checked, not just documented.
- **AI schemas are internal.** The JSON schemas sent to the AI provider live inside the Buddy module. The backend maps model output to the public `Interpretation` DTO, so changing provider, model or prompt never changes the app's contract.

**Why REST + OpenAPI** (not gRPC or GraphQL): our calls are simple request/response. REST is easy to inspect with curl, works through every proxy and CDN, and has the broadest tooling. gRPC is typed and streams, but is harder to debug and cache. GraphQL suits flexible read-heavy UIs, and our reads are local.

### 4.2 Conventions (the API style guide)

| Concern | Rule |
|---|---|
| Transport | HTTPS only (TLS 1.2+), JSON (UTF-8), gzip/brotli |
| Versioning | `/v1/...` in the path. Only additive changes within a version. Deprecation via the `Sunset` header. **Minimum app version gate:** `426 Upgrade Required` + the app update screen when `X-App-Version` is below the configured minimum; `/v1/config` is exempt so outdated apps can learn the minimum. Store link added with the release channel in A43 |
| Auth | `Authorization: Bearer <access JWT>` (≈ 15 min, ES256, `kid` header). Refresh tokens are opaque, rotated on every use and stored hashed. Reusing a refresh token revokes its whole family |
| Errors | **RFC 9457** `application/problem+json` with a stable `type` URI (relative, e.g. `/errors/rate-limited`, `/errors/version-conflict`, `/errors/upgrade-required`) and an `errors` map on every 400 (camelCase field paths; `{}` with fixed detail for unreadable input). Every problem carries `traceId`; 500s contain no exception detail. The app maps `type` to its `Failure` values (`09` §8) |
| Idempotency | `Idempotency-Key` header on every unsafe POST. The server stores the result for 24 h and replays it. Buddy uses the chat message ID (MN-005) |
| Concurrency | Single-resource updates use `ETag` / `If-Match`. Sync uses HLC last-write-wins (`05` §5) |
| Pagination | Cursor-based (`cursor`, `limit`, response `nextCursor`). Never offsets |
| Formats | IDs: UUIDv7 strings. Times: RFC 3339 UTC + explicit `tzOffsetMin` where local time matters. Canonical units: g, ml, kcal, kg, cm (`05` §1). Decimals as JSON numbers with documented precision |
| Client headers | `X-App-Version`, `X-Platform` (`android`/`ios`), `X-Device-Id`, `Accept-Language` |
| Tracing | W3C `traceparent` accepted and propagated. Response `X-Request-Id` = W3C trace id (32 lowercase hex), the problem `traceId` and request-log `TraceId`. Inbound `X-Request-Id` is ignored (TD-057) |
| Rate limits | `429` + `Retry-After` + `RateLimit-Policy` / `RateLimit` headers (IETF draft -11; headers only on 429 in v1). Per IP now (IPv6 /64), per user from B04 |
| Size limits | Body ≤ 256 KB, except image uploads (≤ 2 MB, JPEG ≤ 1024 px, `09` §4) |
| Schema shape (TD-043) | Every property is in `required`; a value that can be absent is `type: [T, 'null']` and is sent as `null`, never as a missing key (a server emission rule: no `WhenWritingNull`). No merge-patch semantics: updates are full replacement (`If-Match`) or command POSTs. A request property added within a version is optional with a server default. Unions are discriminated (`discriminator` + complete `mapping`). One tag per module = one Dart client class; `operationId` = the Dart method name |
| Error types (TD-043) | `ProblemDetails.type` is a relative `/errors/<kebab-slug>`, compared as an opaque string, never renamed or removed within a version. `type`, `title`, `status` always present. Catalogue: `contracts/README.md` (+ golden bodies in `contracts/testdata/problems/` from S03) |
| Forward compatibility | Clients ignore unknown fields. Every enum has an `unknown` fallback on the client. New intent kinds degrade to "Buddy can't do that in this version yet" |

### 4.3 Endpoint map (v1)

| Area | Endpoints |
|---|---|
| Auth | `POST /v1/auth/anonymous` · `POST /v1/auth/google` · `POST /v1/auth/apple` (R2, D-081) · `POST /v1/auth/email/start` · `POST /v1/auth/email/verify` · `POST /v1/auth/refresh` · `POST /v1/auth/logout` · `POST /v1/auth/link/{provider}` · `GET /.well-known/jwks.json` |
| Account | `GET /v1/me` · `DELETE /v1/me` (AC-031) · `GET /v1/config` (minimum version, feature flags, client thresholds such as AI-060) |
| Sync | `POST /v1/sync/push` · `GET /v1/sync/pull?cursor=&limit=` · `GET /v1/sync/history/{entity}/{id}` (earlier versions) |
| Buddy | `POST /v1/buddy/interpret` · `/v1/buddy/suggest` · `/v1/buddy/review` · `/v1/buddy/label` · `/v1/buddy/import` (`06`) |
| Foods | `GET /v1/foods/search?q=` · `GET /v1/foods/{id}` · `GET /v1/foods/barcode/{code}` · `GET /v1/catalog/packs/latest` |
| Ops (private network only) | `GET /health/live` · `GET /health/ready` · `GET /metrics` |

## 5. Identity & auth (TD-024)

| Flow | Design |
|---|---|
| **Google** | Native sign-in in the app (`google_sign_in`). The app sends the Google **ID token**. The backend verifies the signature (Google JWKS), `aud` (our client IDs), `iss` and `exp`, then finds or creates the user and issues our tokens |
| **Apple** (iOS, **R2**, D-081) | Same pattern with Apple's JWKS. A nonce protects against replay. Apple's "hide my email" relay addresses are supported |
| **Email** | **Passwordless one-time code**: `email/start` sends a 6-digit code (valid 10 min, ≤ 5 attempts, throttled per address and IP). `email/verify` exchanges it for tokens. No passwords to store, reset or leak. The code is sent through `IEmailSender` (vendor chosen in B04) |
| **Guests** (AC-002) | `auth/anonymous` creates an anonymous user, used **only** for rate limiting and abuse protection. **Sync endpoints refuse anonymous users**, so guest data never leaves the phone |
| **Upgrade** (AC-003) | `auth/link/{provider}` attaches an identity to the current anonymous user. **The user ID stays the same.** The app then enables sync and pushes everything. If the identity already belongs to another account, the API returns a `409` and the app asks: merge this device's data into that account, or discard it (`05` §6) |
| **Tokens** | Access JWT ≈ 15 min, ES256, keys rotatable (`kid`, JWKS published). Refresh tokens are opaque and random, stored as hashes, rotated on use, with family revocation on reuse. Logout revokes the family |
| **Hardening** | Per-IP and per-identity limits on auth endpoints. Constant-time comparisons. Audit log of sign-ins (no content). R3: device attestation (App Attest / Play Integrity) on anonymous sign-up |
| **Escape hatch** | Identity is a module behind ports. A dedicated identity server (Zitadel, Keycloak) could replace it later. That changes only the token-issuing endpoints, not the rest of the API |

## 6. Authorization & data access

- Every authenticated request carries a `UserId` (from the JWT). Every repository query is scoped by it. Handlers never accept a user ID from the request body.
- **Defense in depth:** Postgres **row-level security** on user-owned tables. The backend sets `app.user_id` per transaction (`SET LOCAL`), so a forgotten `WHERE user_id = …` still can't leak another user's rows. Tests assert user A can't read or write B's data.
- **Two database roles:** the application role (with RLS) and a migration role (owns the schema). Elevated paths are limited to the audited Account deletion job and narrowly scoped Identity pre-auth functions (TD-077). The API never receives migration credentials or a general RLS bypass; Identity functions have explicit grants, fixed trusted search paths and proof-bound operations (B04 D3).
- EF Core for most access. Dapper and raw SQL for the sync and search hot paths.
- **Migrations:** explicitly registered EF Core migrations per module context (S04), schema-local history and a shared advisory lock in the migrate role only. User sessions attach EF contexts/raw commands to one transaction with transaction-local identity (TD-062). EF Core migrations per module context (raw SQL where needed: `pg_trgm`, RLS policies, partitioning). Always **expand → migrate code → contract** across releases, so old and new instances both work during a deploy.

## 7. Server storage of user data (TD-031)

The phone's SQLite is the source of truth, and the server's job is to **store and sync** it, not to query it. So the UserData module stores synced data as **versioned JSON documents**, not as relational tables that mirror the app's schema:

```
userdata.documents(
  user_id uuid, entity text, id uuid,          -- PK (user_id, entity, id)
  schema_version int, hlc text, device_id uuid,
  deleted_at timestamptz null, payload jsonb,
  server_seq bigint                             -- CACHE 1 sequence, indexed (user_id, server_seq)
)
userdata.row_history(…same columns…, replaced_at timestamptz)   -- 30-day retention
```

| Why | |
|---|---|
| Decoupling | The backend doesn't change when the app adds a field or an entity. Only the contract's entity list and JSON schemas do |
| Simplicity | One push/pull implementation for every entity. Deletion = `DELETE … WHERE user_id = $1` |
| Safety | Payloads are validated against the entity's JSON schema (from the contract) and size limits. Unknown entities are rejected |
| Future server features | If R2/R3 needs server-side queries over user data, a module **projects** documents into typed read tables via outbox events. The sync path stays unchanged |

B01 confirms this storage design with two synthetic entities. Pushes take a per-user transaction lock **before** allocating a sequence (`CACHE 1`); a bare sequence does not guarantee commit order. Deduplicated history preserves stale incoming as well as displaced versions, including same-device versions to enforce immutable HLC retry identity. The spike has a separate history cursor sequence. Normal environments return 501 for its experimental routes; production authentication, payload-schema validation, clock recovery and 30-day cleanup remain B04/B05. No real user data is served by the prototype.

Details of the protocol: `05` §5.

## 8. Contracts & versioning across app releases

- **The server supports the last N app versions** (N decided before R2. In R1 the owner updates quickly).
- **Additive within `/v1`.** Breaking changes get `/v2` alongside `/v1` until old apps age out. The `426` gate is the kill switch for broken releases.
- **Sync payloads carry `schemaVersion`.** The server stores what it receives. The app migrates older documents on pull (drift migrations + document upgraders in `fb_domain`).

## 9. How it scales

| Pressure | Answer |
|---|---|
| More users | `api` is stateless: add instances behind the load balancer (`08` §3). One mid-size VM serves ≈ 10k daily users at our call volume (`08` §3.4) |
| Long AI calls | Fully async I/O. Thousands of in-flight requests per instance. Per-provider concurrency limits and timeouts |
| Database | Indexes on `(user_id, server_seq)`, connection pooling (PgBouncer at stage 2), a read replica for catalog search, partitioning `userdata.documents` by user hash when it grows large |
| AI cost | Per-task model routing, prompt caching, usage counters → R3 allowances |
| New features | A new module (own schema, own endpoints in the contract). Existing modules are untouched |
| A module outgrows the monolith | Extract it: its public interface becomes HTTP, and its events go through a broker. The contract the app sees doesn't change |
