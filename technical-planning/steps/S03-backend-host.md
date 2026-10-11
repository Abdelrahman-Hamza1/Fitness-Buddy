# S03 — Backend host & HTTP conventions

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S02 | M | ⬜ Not started |

**Goal.** A production-shaped ASP.NET Core host. Every cross-cutting rule of the API style guide works once, here, so that modules added later only add endpoints and handlers.

**Spec:** UX-052 (error shape), AC-041 (no content in logs) · **Decisions:** TD-021, TD-022, TD-023, TD-029

## Scope
- **Host roles:** `api`, `worker`, `migrate` selected by a command-line argument. Graceful shutdown.
- **Module system:** an `IModule` pattern (register services, map endpoint group, register jobs/handlers) and a sample `Account` module exposing `/v1/config` (moved from S02).
- **BuildingBlocks:** `Result<T>` / `Error` types, problem-details mapping (RFC 9457, `type` URIs from the contract), `IClock`, `IIdGenerator` (UUIDv7 via `Guid.CreateVersion7`), user/auth context abstraction (filled in S24), `IFeatureFlags`.
- **HTTP pipeline:** forwarded headers (behind kamal-proxy), HSTS, request ID (`X-Request-Id`) + W3C `traceparent`, client headers parsing (`X-App-Version`, `X-Platform`, `X-Device-Id`), **minimum-version gate → `426`**, request size limits, rate limiting policies (per IP now, per user later), output of `RateLimit` headers, global exception handler (500 with request ID, no internals).
- **Validation:** request validation producing problem details with an `errors` map.
- **Observability:** structured JSON logs, OpenTelemetry tracing + metrics + logs (OTLP endpoint configurable, console in dev), Sentry SDK (DSN from config, scrubbing). **Log scrubbing:** no request/response bodies, with tests.
- **Health:** `/health/live`, `/health/ready` (database check added in S04). Not exposed in the public contract.
- **Configuration:** options classes with validation on start, environment-specific settings, secrets via environment variables.
- **Container:** a Dockerfile (multi-stage, small runtime base, non-root user). `infra/compose/docker-compose.yml` with the API (Postgres arrives in S04). `make up` / `make down`.
- **Architecture tests:** layer direction and module isolation rules (ArchUnitNET), shaped for future modules.

## Out of scope
- Database, migrations, outbox, jobs, idempotency storage (S04). Auth and JWT (S24).

## Fixed by the plan
- Minimal APIs, no mediator, handlers injected into endpoints (`04` §3.2).
- The conventions table in `04` §4.2.

## Decide in the low-level plan
- Validation: built-in .NET 10 Minimal API validation vs FluentValidation.
- Logging: built-in `Microsoft.Extensions.Logging` JSON console vs Serilog (default: built-in + OpenTelemetry).
- Runtime base image (chiseled/distroless vs standard).
- The exact shape of `IModule` and endpoint-group conventions.

## Exit criteria
- [ ] `make up` starts the API. `GET /v1/config` returns contract-conformant JSON, and the conformance check passes.
- [ ] Tests: an old `X-App-Version` → `426` problem details. Validation errors → `400` with an `errors` map. An unhandled exception → `500` with a request ID and no stack trace. `X-Request-Id` is echoed.
- [ ] A log scrubbing test proves request bodies never reach logs.
- [ ] Traces appear in the console exporter locally, and the OTLP exporter is configurable.
- [ ] ArchUnitNET rules pass and fail correctly (one deliberately broken fixture).
- [ ] The container image runs as non-root. Note its size in the Outcome.

## Read first
`04-backend.md` §2–4 · `09-cross-cutting.md` §4, §8 · `08-infrastructure-and-operations.md` §7

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
