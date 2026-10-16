# S03 — Backend host & HTTP conventions

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S02 | L | ✅ Done |

**Goal.** A production-shaped ASP.NET Core host. Every cross-cutting rule of the API style guide works once, here, so that modules added later only add endpoints and handlers.

**Spec:** supports UX-052 (proved by the first UI step that shows a `Failure`); the no-content-in-logs rule is `09` §4 (no spec ID; AC-041 is about AI context)

## Scope
- **Host roles:** `api`, `worker`, `migrate` selected by a command-line argument. Graceful shutdown.
- **Module system:** an `IModule` pattern (register services, map endpoint group, register jobs/handlers) and a sample `Account` module exposing `/v1/config` (moved from S02).
- **BuildingBlocks:** `Result<T>` / `Error` types, problem-details mapping (RFC 9457, `type` URIs from the contract), `TimeProvider`, `IIdGenerator` (UUIDv7 via `Guid.CreateVersion7`), user/auth context abstraction (filled in S24), `IFeatureFlags`.
- **HTTP pipeline:** forwarded headers (behind kamal-proxy), HSTS, request ID (`X-Request-Id`) + W3C `traceparent`, client headers parsing (`X-App-Version`, `X-Platform`, `X-Device-Id`), **minimum-version gate → `426`**, request size limits, rate limiting policies (per IP now, per user later), output of `RateLimit` headers, global exception handler (500 with request ID, no internals).
- **Validation:** request validation producing problem details with an `errors` map.
- **Observability:** structured JSON logs, OpenTelemetry tracing + metrics + logs (OTLP endpoint configurable, console in dev), Sentry SDK (DSN from config, scrubbing). **Log scrubbing:** no request/response bodies, with tests.
- **Health:** `/health/live`, `/health/ready` (database check added in S04). Not exposed in the public contract.
- **Configuration:** options classes with validation on start, environment-specific settings, secrets via environment variables.
- **Container:** a Dockerfile (multi-stage, small runtime base, non-root user). `infra/compose/docker-compose.yml` with the API (Postgres arrives in S04). `make up` / `make down`.
- **Architecture tests:** layer direction and module isolation rules (ArchUnitNET), shaped for future modules.

- **WP0:** .NET 10.0.13 / SDK 10.0.402 security bump, its own first commit (architect A6).

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

## Notes from earlier steps
- **From S02:** header middleware and `ClientHeadersOperationTransformer` derive from one definition (a `/v1` route group with endpoint metadata). `/v1/config` declares the client headers even if it is exempt from the 426 gate. Golden problem bodies in `contracts/testdata/problems/*.json`, used by C# and Dart `Failure` mapping tests. Always set `type`/`title`; runtime test for statuses without a framework default (429). `ValidationProblem` + 400/426/429 responses land here. A dio interceptor sets `X-App-Version`/`X-Platform`/`X-Device-Id` (skipped in the generated client) and decodes problem+json. Request DTOs: consider `RespectRequiredConstructorParameters`/`RespectNullableAnnotations`. `X-Device-Id` stays out of logs/telemetry. Keep `detail` free of exception messages and user content. `ASPNETCORE_ENVIRONMENT` is never `Development` outside local dev.
- **From S06a:** the app trips its update gate on any `426` or `/errors/upgrade-required` (dio interceptor); demo it with a server-forced 426 (the app only had a simulated one). If `/v1/config` itself answers 426 for old versions, make that distinguishable for the client (backlog #43). The app sends no `X-Request-Id` (A4): decide request correlation here, and if a header is added, add it to the contract first. The app's API Dio never follows redirects, so don't rely on them.

## Exit criteria
- [x] `make up` starts the API. `GET /v1/config` returns contract-conformant JSON, and the conformance check passes.
- [x] Tests: an old `X-App-Version` → `426` problem details. Validation errors → `400` with an `errors` map. An unhandled exception → `500` with a request ID and no stack trace. `X-Request-Id` is returned on every response and equals `traceId` (inbound values are ignored).
- [x] A log scrubbing test proves request bodies never reach logs.
- [x] Traces appear in the console exporter locally, and the OTLP exporter is configurable.
- [x] ArchUnitNET rules pass and fail correctly (one deliberately broken fixture).
- [x] The container image runs as non-root. Note its size in the Outcome.

## Read first
`04-backend.md` §2–4 · `09-cross-cutting.md` §4, §8 · `08-infrastructure-and-operations.md` §7

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B (2026-10-16) by the step-planner, from research-notes "S03 — Backend host (2026-10-16)" and the orchestrator's guidance. Versions and tags checked against NuGet/MCR on 2026-10-16._

### 1. Summary
After S03 the Host is production-shaped. One image runs as `api`, `worker` or `migrate`. Modules plug in through `IModule` and get a `/v1` route group, and that group is the **single definition** behind the client-header check, the `426` gate, per-IP rate limiting and the OpenAPI responses. `Account` is the first module and owns `GET /v1/config` (same `operationId`/tag). Every error is RFC 9457 with a catalogue `type` and a `traceId` that equals `X-Request-Id`. Logs (JSON console), traces and metrics (OpenTelemetry) and Sentry (errors only, empty DSN = off) carry **no bodies, no device id, no query values and no exception messages**, and canary tests prove it. `make up` runs the API in a digest-pinned chiseled container as non-root, and CI builds and smoke-tests that image on every push. ArchUnitNET enforces the layer and module rules, and fixtures prove each rule can fail.

### 2. Decisions

| # | Decision | Reason / source |
|---|---|---|
| D1 | **Validation: built-in `AddValidation()` + DataAnnotations.** Use `[property: …]` on positional record DTOs, so the rule both validates and documents itself. Cross-field rules use `IValidatableObject`. Rules that need data (ownership, uniqueness) live in handlers and return `Result` errors. `CustomizeProblemDetails` rewrites **every 400** to `type: /errors/validation-failed`, `title: "One or more validation errors occurred."`, with an `errors` map that is always present (possibly `{}`) and keys camelCased per path segment (`Items[0].Qty` → `items[0].qty`). JSON input: `RespectRequiredConstructorParameters = true`, `RespectNullableAnnotations = true` (a missing key, or `null` for a non-nullable member, is an unreadable body, see D2) | Research §1: no extra package, and the output already goes through `IProblemDetailsService`. FluentValidation has no Minimal API auto-validation and no OpenAPI constraints. The strict JSON flags make "every property required, `null` only where nullable" (TD-043) true on input. Fallback in R5 |
| D2 | **A malformed or unreadable request (bad JSON, wrong type, missing required member, failed parameter binding) reuses `/errors/validation-failed`** with `errors: {}` and the fixed `detail: "The request could not be read."` The framework's `detail` (which may echo input) is always replaced. No new catalogue entry | It's a client bug, not something the user can fix differently. The app maps both to `InvalidInputFailure`. One rule ("every 400 is `validation-failed` with `errors`") keeps the contract's 400 response to one schema, and the Dart `ProblemTypes` list (kept in sync with the README by a test) doesn't change. Additive and contract-first either way, so the cheaper option wins |
| D3 | **Logging: built-in `Microsoft.Extensions.Logging`**: `ClearProviders()` **then** `AddJsonConsole` (`UseUtcTimestamp`, `IncludeScopes`, ISO-8601) **then** `AddOpenTelemetry`. No Serilog, no `Microsoft.Extensions.Compliance.Redaction` yet. `Microsoft.AspNetCore` at `Warning` (this drops the Hosting "Request starting" lines that carry path+query, and the MVC "No action descriptors found" line, **backlog #22**). Never `AddHttpLogging`/`UseHttpLogging`, and no OTel `Enrich*` callbacks | Research §2: nothing we need is missing from the built-in stack, and Serilog would add a vendor. The order matters (research gotcha) |
| D4 | **Package pins follow our 7-day cooldown** (Dependabot `cooldown: 7`). Security fixes are the exception. Pins: OpenTelemetry, .Extensions.Hosting, .Exporter.OpenTelemetryProtocol, .Exporter.Console **1.19.1**; OpenTelemetry.Instrumentation.AspNetCore, .Http, .Runtime **1.19.0** (there is no 1.19.1); **Sentry.AspNetCore 6.12.0** (2026-10-01); test-only **Microsoft.Extensions.Diagnostics.Testing 10.10.0** (`FakeLogger`). Dependabot proposes 1.20.x / 6.12.1 once they are a week old. A one-line justification for each package goes in the commit body (`10` §2) | 1.20.0 is one day old, 6.12.1 three days, Diagnostics.Testing 10.11.0 two days. Same policy as our bots |
| D5 | **WP0: .NET security bump to SDK 10.0.402 / runtime 10.0.13** (released 2026-10-13 with about 40 CVEs). This covers `global.json`, the three `Microsoft.AspNetCore.*`/`ApiDescription` packages at 10.0.13, and the image tags in D15. Done before any S03 code | The image we ship should not start on a runtime with known CVEs. Security updates skip the cooldown (D4). Small and mechanical |
| D6 | **Exception messages never leave the process.** A `ScrubbingLoggerProvider` decorator wraps **every** registered `ILoggerProvider` (JSON console, OpenTelemetry) **except Sentry's**. It forwards everything unchanged, except that the `Exception` is replaced by a `ScrubbedException`: message = original type full name, overridden `StackTrace` = original stack, inner exceptions scrubbed recursively. It forwards `ISupportExternalScope`. The wrapping runs last in service registration (`services.ScrubLoggerProviders()`). Sentry is scrubbed by `BeforeSend` instead (D7), so Sentry keeps the original exception type for grouping and dedupes the middleware and logger events. Code rule (backend README): log templates take IDs/codes/enums only | Research §2(b): `Exception.ToString()` prints the message, and framework or driver messages can echo input (JSON `'x' is an invalid start…`, Postgres `Key (email)=(…)` from S04). One choke point covers every sink. Trade-off: in OTLP logs, `exception.type` shows `ScrubbedException` and the real type is in the message. Fallback in R2. **TD candidate** (privacy mechanism behind `09` §4 "Logging") |
| D7 | **Sentry.AspNetCore, errors only:** `WebHost.UseSentry`. DSN from `Sentry:Dsn` (env `Sentry__Dsn`); empty = no-op, which also covers the build-time document run. `SendDefaultPii = false`, `MaxRequestBodySize = None`, `TracesSampleRate = 0`, `IncludeActivityData = false`, `CaptureFailedRequests = false`, `AutoSessionTracking = false`, `MinimumEventLevel = Error`. `SetBeforeBreadcrumb(_ => null)` drops all breadcrumbs in S03 (S05 may allow an allowlist). `SetBeforeSendTransaction(_ => null)`. `SetBeforeSend(SentryScrubber.Scrub)`: request headers reduced to an allowlist {`X-App-Version`, `X-Platform`, `Content-Type`, `Content-Length`}; query string, data, cookies and env cleared; URL reduced to its path; `User` emptied; each `SentryException.Value` (message) and `Mechanism.Data` cleared; `Message.Formatted` and params cleared (template kept); `Extra` cleared. Worker/migrate use `Logging.AddSentry` with the same option function | Research §6: the SDK copies **all** request headers (incl. `X-Device-Id`, later `Authorization`) and the query into the event. No account yet (S05). TD-029 already accepts Sentry, so this is no new vendor |
| D8 | **Correlation: one id.** `X-Request-Id` (response, every status) = `Activity.Current.TraceId` (32 lowercase hex). If the caller sends a valid `X-Request-Id` (`^[A-Za-z0-9._-]{1,64}$`), that value is echoed instead, and added as log scope `ClientRequestId` and activity tag `fb.client_request_id`. Inbound W3C `traceparent` is honoured (framework default). `HttpContext.TraceIdentifier` = the echoed value. The header is set in `Response.OnStarting` by the first middleware after forwarded headers, so it survives the exception handler and appears on 429/426/413/404. Problem bodies carry **`traceId`** = the bare trace id; the framework's `requestId` extension (Kestrel's connection id) is removed. Log lines correlate through the standard `TraceId` scope. Contract-first: `XRequestId` goes on every response, plus optional `traceId` on `ProblemDetails`. The app sends nothing new (S06 A4 stands) | Research §5. The id a user quotes from a 500 finds the trace and the logs directly. **TD candidate** (amends `04` §4.2 "Tracing") |
| D9 | **Client headers + 426 gate**: `ClientHeadersMiddleware` runs after routing and acts only on endpoints with `ClientHeadersMetadata` (every `/v1` endpoint, set by the group, D12). (1) `X-App-Version` present, valid `MAJOR.MINOR.PATCH`, below `Clients:MinimumAppVersion`, and the endpoint isn't `AllowOutdatedClients()` → **426** `/errors/upgrade-required`, `title: "Upgrade required"`, `detail: "This app version is no longer supported. Update the app."`, with no `Upgrade` header. (2) Otherwise any missing or invalid header (`X-App-Version` not strict semver, `X-Platform` not exactly `android`/`ios`, `X-Device-Id` not a UUID) → **400** `validation-failed` with keys `x-app-version`, `x-platform`, `x-device-id` (lowercase, so the camelCase rewrite leaves them alone). (3) Otherwise the parsed `ClientInfo` goes into `HttpContext.Features`. **`/v1/config` is exempt from the 426** but not from the header check. The minimum comes from config (`Clients:MinimumAppVersion`), the same value `/v1/config` returns. **Backlog #43 is solved server-side:** config never answers 426, so the app's `refresh()` succeeds, caches the higher minimum, and `UpdateCheck` reports `stillOld` (verified in `apps/mobile/lib/app/update/update_check.dart`; no app change). **Demo path** (D16): `FB_MIN_APP_VERSION=99.0.0 make up`, then `make run-dev` → the update screen. The 426 *status* itself is proven by tests. No endpoint the app calls is gated until S24/S25 | The kill switch must win even over a malformed `X-Platform`, so old apps always reach the update screen. The app's interceptor already relies on "the server rejects a request without its headers" (`client_headers_interceptor.dart`) |
| D10 | **Rate limiting: built-in limiter.** One named policy `per-ip` (fixed window, `RateLimiting:PerIp:PermitLimit` 300 / `WindowSeconds` 60, `QueueLimit` 0) on the `/v1` group. Partition key = `RemoteIpAddress` after forwarded headers: the full IPv4 address, or the **IPv6 /64 prefix**; no address → `"unknown"`. `RejectionStatusCode = 429`. `OnRejected` writes, through `IProblemDetailsService`, `/errors/rate-limited`, `title: "Too many requests"`, plus `Retry-After: <s>` (from lease metadata, else the window), `RateLimit-Policy: "per-ip";q=300;w=60` and `RateLimit: "per-ip";r=0;t=<s>` (draft-ietf-httpapi-ratelimit-headers-11). **Headers only on 429 in v1**; the contract promises only that. Health endpoints aren't limited. Per-user policies: S24 | Research §4: nothing writes these headers for us, and per-partition "remaining" isn't exposed on 2xx. A /64 stops trivial IPv6 rotation. The numbers are generous for CGNAT and configurable |
| D11 | **Forwarded headers:** `XForwardedFor \| XForwardedProto`, `ForwardLimit = 1`, loopback trusted by default, plus `Proxy:TrustedNetworks` (CIDR list, parsed with `System.Net.IPNetwork`, validated on start) added to **`KnownIPNetworks`** (`KnownNetworks` is obsolete, ASPDEPR005). Never `ASPNETCORE_FORWARDEDHEADERS_ENABLED`. At startup, log the trusted networks (config values only). Production values: S05 | Research §4: kamal-proxy overwrites XFF with one hop, so the value is trustworthy only from the proxy's network |
| D12 | **Module system:** `public interface IModule { string Name { get; } void AddServices(IServiceCollection services, IConfiguration configuration); void MapEndpoints(RouteGroupBuilder group); }` in `BuildingBlocks.Web`. `Name` = the OpenAPI tag (later also the Postgres schema). The Host keeps an **explicit list** `ModuleCatalog.All = [new AccountModule()]` (no assembly scanning): it calls `AddServices` and registers each as an `IModule` singleton. After `Build()` it maps every `IModule` from DI into `V1Api.MapModuleGroup(v1, module)` = `v1.MapGroup("").WithTags(module.Name)`, so one tag per module holds by construction. Tests add a probe module through DI (D20). **The `/v1` group (`V1Api.MapV1`) is the one definition:** `ClientHeadersMetadata`, `RequireRateLimiting("per-ip")`, `ProducesValidationProblem()` (400), `ProducesProblem(429)`, `ProducesProblem(500)`, and a `Finally` convention that adds `ProducesProblem(426)` unless the endpoint has `AllowOutdatedClientsMetadata`. The OpenAPI transformers read the same metadata. Endpoints declare only their own domain errors. Job/event registration joins `IModule` in S04, together with the job and outbox types | Explicit beats magic and is trimming-safe. The group conventions answer S02 A8 (header middleware and transformer derive from one definition) |
| D13 | **BuildingBlocks: one project, two namespaces.** `FitnessBuddy.BuildingBlocks` has no ASP.NET (an arch rule enforces it): `Result`/`Result<T>`, `Error`/`ErrorKind`, `IIdGenerator` (UUIDv7), `IFeatureFlags` + options implementation, `ICurrentUser` (anonymous until S24), `AppVersion`, `ClientPlatform`, `ClientInfo`, `ClientCompatibilityOptions`. `FitnessBuddy.BuildingBlocks.Web` (`FrameworkReference Microsoft.AspNetCore.App`) has `IModule`, `V1Api` + metadata, `ProblemTypes`, and `Error` → `IResult` mapping. **Time = `System.TimeProvider`** (BCL; `FakeTimeProvider` in tests) instead of a home-made `IClock`. The card's and `04`/`10` wording (`IClock`) is updated at close | A second project would only formalise what a namespace rule already enforces. `TimeProvider` is the .NET port for time, and the framework (rate limiter, health checks) already accepts it |
| D14 | **Roles:** `Program` reads the first argument that doesn't start with `-`: `api` (default, so `WebApplicationFactory` and `GetDocument.Insider` work unchanged), `worker`, `migrate`; anything else exits with code 2 and a usage line. The api and worker share `AddFbPlatform(IHostApplicationBuilder)` (options, logging, OTel, Sentry, modules' services). `worker` = generic host + a placeholder `BackgroundService` that logs "no jobs until S04" and waits. `migrate` = logs "no migrations until S04" and exits 0. **Graceful shutdown:** `HostOptions.ShutdownTimeout = 25 s` (under Kamal's default 30 s stop wait). `dotnet` is PID 1 in exec form, so SIGTERM → Kestrel drains in-flight requests | TD-022 roles, stubs until S04 |
| D15 | **Runtime image `mcr.microsoft.com/dotnet/aspnet:10.0.13-noble-chiseled-extra@sha256:<digest>`**, build stage `sdk:10.0.402-noble@sha256:<digest>` (both after D5). Exact patch tags, so the image matches `global.json` and the 10.0.13 packages, and Dependabot bumps tag + digest together. Default non-root user `app` (UID 1654), stated explicitly with `USER $APP_UID`. Port 8080. No `HEALTHCHECK` (no shell); kamal-proxy probes `/health/ready` over HTTP (S05 `proxy.healthcheck.path`) | Research §3: 70.8 MB compressed. ICU + tzdata are cheap insurance for culture-aware Arabic work later |
| D16 | **Local container + CI:** `backend/Dockerfile` (multi-stage; restore layer from the csproj/props files; `publish -c Release -p:OpenApiGenerateDocuments=false -p:UseAppHost=false`), `backend/.dockerignore`. `infra/compose/docker-compose.yml`: service `api`, project `fitness-buddy`, `ports: 127.0.0.1:5198:8080` (**the port `make run-dev` / `config/dev.json` already use**), `ASPNETCORE_ENVIRONMENT=Development`, `Observability__ConsoleExporter=true`, `Clients__MinimumAppVersion=${FB_MIN_APP_VERSION:-0.1.0}`, `read_only: true`, `tmpfs: /tmp`, `cap_drop: [ALL]`, `security_opt: [no-new-privileges:true]`. `make up` = compose up `-d --build`, then poll `/health/ready` (30 s). `make down` = compose down. **`make image-smoke`** (`tools/scripts/image-smoke.sh`) builds the image and checks: non-root (`docker top` UID 1654, `Config.User` ≠ root); `/health/live` + `/health/ready` 200; `/v1/config` with headers 200 and the contract's keys; `X-Request-Id` present; the console exporter printed that trace id (Development); `migrate` exits 0; `docker stop` exits 0 within 10 s. It prints the image size (`docker image inspect .Size` + compressed). New CI job **`image`** runs it and is added to the `ci` gate's `needs:`. The Dependabot `docker` entry for `/backend` is uncommented (**backlog #2**) | Keeps the Dockerfile honest every push before S05 deploys it. Costs about 3–4 CI minutes per push (no new vendor) |
| D17 | **Architecture rules (ArchUnitNET 0.13.4, as pinned):** rules are **functions of an `Architecture` and a module list** (`ArchitectureRules.*`), so the real tests and the fixture tests run the same code. Real tests load BuildingBlocks + Host + `ModuleCatalog.All` assemblies | Research §7 |
| D18 | **Health:** `/health/live` (no checks) and `/health/ready` (checks tagged `ready`, none until S04), plain text. Outside `/v1`: no client headers, no rate limit, not in the contract, filtered out of traces. Restricting them to the private network is S05 | Card scope; `04` §4.3 ops row |
| D19 | **Contract changes (additive, WP1):** a **flat** `ValidationProblemDetails` (the ProblemDetails members + `traceId` + required `errors`), the same shape the server's `HttpValidationProblemDetails` produces (no `allOf`, so the conformance diff compares like with like; `fb-problem-json-errors` accepts a schema that requires type/title/status directly). Optional `traceId` (`pattern ^[0-9a-f]{32}$`) on `ProblemDetails`. Response components `ValidationFailed` (400), `UpgradeRequired` (426), `RateLimited` (429 + `Retry-After`, `RateLimit`, `RateLimit-Policy` headers). `X-Request-Id` on **every** response. `getConfig` gains 400 + 429 (never 426). Golden bodies in `contracts/testdata/problems/` | Contract-first (TD-023). Exact diff in §3.4 |
| D20 | **Test host:** `ApiFactory : WebApplicationFactory<Program>` runs in environment **`Testing`** (production-like: HSTS on, no console exporter, no OpenAPI endpoint), with config overrides per fixture. It registers a **`ProbeModule : IModule`** from the test assembly (routes under `/v1/_probe/…`), which also exercises "DTOs and endpoints in another assembly" for validation. A test-only `IStartupFilter` sets `Connection.RemoteIpAddress` from `X-Test-Peer` (the forwarded-header and rate-limit tests use a unique IP per test, so partitions don't collide). Kestrel-only behaviour (413 body limit, graceful drain) uses `WebApplicationFactory.UseKestrel()` (.NET 10) | Exercises the real pipeline. `TestServer` doesn't enforce Kestrel limits |
| D21 | **Transport hardening:** `UseHsts` outside Development (max-age 365 d, no preload, no subdomains until the domain is fixed in S05); **no** HTTPS redirection (TLS ends at kamal-proxy, and the app never follows redirects, S06a); `AddServerHeader = false`; `MaxRequestBodySize = 256 KB` (`04` §4.2; per-endpoint `IRequestSizeLimitMetadata` for the later 2 MB image routes); `UseStatusCodePages` so an empty 404/405/413 gets a problem body with `type`/`title`. Compression (gzip/brotli in `04` §4.2) is left to the proxy and decided in S05 (not in this card's scope) | `09` §4 API hardening |

**⚠️ OWNER:** none. No new vendor or cost (Sentry is TD-029; the CI `image` job uses existing Actions minutes), no Accepted TD changed, no spec change, no security trade-off (D6/D7 are stricter than the rule).

### 3. Design

**3.1 Files (new or changed)**
```
backend/Dockerfile, backend/.dockerignore                         D15, D16
backend/global.json (10.0.402), Directory.Packages.props          D4, D5
backend/src/BuildingBlocks/
  FitnessBuddy.BuildingBlocks.csproj                              + FrameworkReference Microsoft.AspNetCore.App
  Results/Result.cs, Results/Error.cs                             Result, Result<T>, Error(Kind, Code, Detail?, FieldErrors?), ErrorKind
  Ids/IIdGenerator.cs, Ids/UuidV7IdGenerator.cs                   Guid.CreateVersion7(timeProvider.GetUtcNow())
  Features/IFeatureFlags.cs, Features/OptionsFeatureFlags.cs      section "FeatureFlags": {name: bool}; missing = off
  Auth/ICurrentUser.cs, Auth/AnonymousCurrentUser.cs              UserId: Guid? (null until S24), IsAuthenticated
  Clients/AppVersion.cs                                           readonly record struct; strict TryParse (no leading zeros), IComparable
  Clients/ClientPlatform.cs, Clients/ClientInfo.cs                Android|Ios; record(AppVersion, Platform, Guid DeviceId)
  Clients/ClientCompatibilityOptions.cs                           section "Clients": MinimumAppVersion (required, semver)
  Web/Modules/IModule.cs                                          D12
  Web/Http/V1Api.cs                                               MapV1(app), MapModuleGroup(v1, module), conventions
  Web/Http/ClientHeadersMetadata.cs, AllowOutdatedClientsMetadata.cs, EndpointBuilderExtensions.cs (.AllowOutdatedClients())
  Web/Http/HttpContextClientExtensions.cs                         GetClientInfo() from the feature
  Web/Problems/ProblemTypes.cs                                    the 4 catalogue strings
  Web/Problems/ErrorResults.cs                                    Error → IResult; Result<T>.ToHttpResult(onSuccess)
backend/src/Modules/Account/FitnessBuddy.Modules.Account.csproj   Microsoft.NET.Sdk + FrameworkReference; refs BuildingBlocks
  AccountModule.cs (public; Name "Account")
  Api/ConfigEndpoints.cs                                          MapGet("/config").WithName("getConfig").AllowOutdatedClients()
  Api/ClientConfig.cs                                             DTO, moved unchanged from Host/Config
  Application/GetClientConfig.cs                                  handler: ClientCompatibilityOptions + ClientConfigOptions → model
  Application/ClientConfigOptions.cs                              section "Account:ClientConfig": FeatureFlags, Thresholds
backend/src/Host/
  Program.cs                                                      role dispatch only (D14)
  Roles/ApiRole.cs, WorkerRole.cs, MigrateRole.cs, RoleParser.cs
  Platform/PlatformSetup.cs                                       AddFbPlatform(IHostApplicationBuilder): options + ValidateOnStart (skipped
                                                                  in GetDocument.Insider), TimeProvider, ids, flags, modules
  ModuleCatalog.cs
  Http/RequestIdMiddleware.cs, ClientHeadersMiddleware.cs, UnhandledExceptionHandler.cs (IExceptionHandler),
       ProblemDetailsCustomizer.cs (D1, D2, D8, type/title defaults), ValidationKeyCasing.cs,
       RateLimiting.cs (policy + OnRejected), ForwardedHeadersSetup.cs, ProxyOptions.cs, RateLimitingOptions.cs
  Observability/ObservabilitySetup.cs (logging + OTel), ObservabilityOptions.cs, ScrubbingLoggerProvider.cs,
       ScrubbedException.cs, SentrySetup.cs, SentryScrubber.cs
  OpenApi/ClientHeadersOperationTransformer.cs                    metadata-driven (not path-prefix)
  OpenApi/ProblemDetailsSchemaTransformer.cs                      + traceId; HttpValidationProblemDetails: errors required, non-null
  OpenApi/ResponseHeadersOperationTransformer.cs                  X-Request-Id on every response; Retry-After/RateLimit* on 429
  appsettings.json, appsettings.Development.json                  §3.5
  (Host/Config/ removed)
backend/tests/BuildingBlocks.Tests/                               unit
backend/tests/Host.Tests/                                         ApiFactory, ProbeModule, TestPeerStartupFilter, pipeline/canary/golden/OTLP
backend/tests/Architecture.Tests/                                 ArchitectureRules.cs, rule tests, Fixtures/ (namespaces FitnessBuddy.Modules.Alpha|Beta…)
backend/tests/Contract.Tests/ConfigEndpointTests.cs               + X-Request-Id, + 400 without headers
infra/compose/docker-compose.yml; tools/scripts/image-smoke.sh; Makefile (up, down, image-smoke); .github/workflows/ci.yml (image job);
.github/dependabot.yml (docker /backend)
contracts/openapi/{openapi.yaml, components/problems.yaml, components/headers.yaml, modules/account.yaml}, contracts/openapi.yaml (bundle),
contracts/README.md, contracts/testdata/README.md, contracts/testdata/problems/*.json, packages/fb_api_client (regenerated)
apps/mobile/test/core/api/failure_mapper_test.dart                golden problems group
```

**3.2 Pipeline (api role), in order**
`UseForwardedHeaders` → `RequestIdMiddleware` (D8) → `UseExceptionHandler()` (+ `UnhandledExceptionHandler`: 500, framework 500 type/title, `traceId`, no `detail`; a `BadHttpRequestException` keeps its own status, e.g. 400/413) → `UseHsts` (non-Development) → `UseStatusCodePages` → `UseRouting` → `UseRateLimiter` → `ClientHeadersMiddleware` (D9) → [S24: authentication/authorization] → endpoints: `/health/*`, `V1Api.MapV1(app)` + each module's group, `MapOpenApi()` (Development). `AddProblemDetails(o => o.CustomizeProblemDetails = ProblemDetailsCustomizer.Apply)` makes every problem: `type`/`title` always set (fallback `about:blank` + reason phrase), `traceId` = trace id, `requestId` removed, 400 rules from D1/D2. Middleware-produced problems (426, 429, header 400) go through `IProblemDetailsService.WriteAsync` so the same customizer runs.

**3.3 Layers and boundaries.** Account: `Api` (endpoint + DTO) → `Application` (handler, options) and nothing below. The endpoint is thin: it binds, calls the injected `GetClientConfig` handler, and maps the result. `Application` uses only `Microsoft.Extensions.Options` and BuildingBlocks core (no ASP.NET). Everything is `internal` except `AccountModule`. The Host references modules only to list them in `ModuleCatalog`. The cross-cutting HTTP and observability code lives in the Host (composition root). Modules see only `BuildingBlocks(.Web)`. ArchUnitNET rules (§5, T-A*) pin all of this.

**3.4 Contract diff (WP1)**
```yaml
# components/problems.yaml
ProblemDetails.properties:
+ traceId: {type: string, pattern: '^[0-9a-f]{32}$', description: "W3C trace id of the request; equals X-Request-Id unless the caller sent its own. Quote it when reporting."}
+ ValidationProblemDetails:          # flat, same members as ProblemDetails + errors
+   type: object
+   required: [type, title, status, errors]
+   properties: {type, title, status, detail, instance, traceId (as above),
+     errors: {type: object, additionalProperties: {type: array, items: {type: string}},
+              description: "Field (camelCase JSON path, or lowercase header name) → messages. Empty when the request could not be read."}}
responses:
+ ValidationFailed: 400, application/problem+json → ValidationProblemDetails, headers X-Request-Id, example = testdata golden
+ UpgradeRequired: 426, → ProblemDetails, headers X-Request-Id
+ RateLimited:     429, → ProblemDetails, headers X-Request-Id, Retry-After, RateLimit, RateLimit-Policy
  InternalError:   + headers X-Request-Id
# components/headers.yaml (headers)
  XRequestId: description updated (D8); the "defined, not referenced" comment removed
+ RetryAfter:      {schema: {type: integer, minimum: 0}, "seconds until a retry may succeed"}
+ RateLimit:       {schema: {type: string}, 'draft-ietf-httpapi-ratelimit-headers-11, e.g. "per-ip";r=0;t=37. Sent on 429 only.'}
+ RateLimitPolicy: {schema: {type: string}, 'e.g. "per-ip";q=300;w=60. Sent on 429 only.'}
  AppVersion (parameter): description only: "MAJOR.MINOR.PATCH. Missing/invalid → 400; below minimumAppVersion → 426 (except getConfig)". Schema unchanged (fb-client-headers)
# modules/account.yaml getConfig
  '200': + headers X-Request-Id
+ '400': $ref ValidationFailed
+ '429': $ref RateLimited
  description: + "Never answers 426: it is how an outdated app learns minimumAppVersion."
# openapi.yaml: register ValidationProblemDetails, the three responses, the three headers
```
`contracts/README.md`: the catalogue row for `validation-failed` gains "also when the request can't be read (`errors` empty)", `version-conflict` gets "412, confirmed", and new notes on `traceId`, `X-Request-Id` and the 429 headers. `testdata/problems/`: `validation-failed.json`, `upgrade-required.json`, `rate-limited.json`, `version-conflict.json` (exact bodies the server emits; `traceId` an example value that tests check by pattern only). The testdata README gets a `problems/` section (format; pass = type/title/status/detail/error keys equal, `traceId` matches the pattern).

**3.5 Configuration** (options classes with DataAnnotations + `ValidateOnStart`, skipped under `GetDocument.Insider`; secrets only via env)

| Key | Default (`appsettings.json`) | Notes |
|---|---|---|
| `Clients:MinimumAppVersion` | `0.1.0` | semver regex; compose: `FB_MIN_APP_VERSION` |
| `Account:ClientConfig:FeatureFlags` / `:Thresholds` | `{}` / `{}` | returned by `/v1/config` |
| `FeatureFlags` | `{}` | server flags, `IFeatureFlags` |
| `RateLimiting:PerIp:PermitLimit` / `:WindowSeconds` | 300 / 60 | 1–100000 / 1–3600 |
| `Proxy:TrustedNetworks` | `[]` | CIDRs; invalid → start fails |
| `Observability:ConsoleExporter` | false (Development: true) | traces + metrics to console |
| `OTEL_EXPORTER_OTLP_ENDPOINT` (+ `_HEADERS`, `_PROTOCOL`) | unset | set → `UseOtlpExporter()` for traces, metrics, logs; `OTEL_SERVICE_NAME` default `fitness-buddy-<role>` |
| `Sentry:Dsn` | `""` | env `Sentry__Dsn` |
| `Logging:LogLevel` | Default Information, `Microsoft.AspNetCore` Warning | D3 |

### 4. Work packages
Sequential. WP1 + WP2 are pushed together (conformance is red between them). WP6 may run in a parallel worktree after WP2. WP7 after WP1.

| WP | Owner | Tasks | Expected files | Done when |
|---|---|---|---|---|
| **WP0** .NET security bump | platform-engineer | `global.json` → 10.0.402; `Microsoft.AspNetCore.OpenApi`, `ApiDescription.Server`, `Mvc.Testing` → 10.0.13; `make toolchain-dotnet` on the laptop; check `setup-dotnet.sh`/doctor messages | `backend/global.json`, `Directory.Packages.props` | `make deps-dotnet check-dotnet test-dotnet contract-conformance` green locally and on CI |
| **WP1** Contract | dotnet-engineer | §3.4 sources → `make gen` (bundle + Dart client) → `make contract-bundle-check contract-lint contract-selftest contract-breaking` (breaking: additive, report-only); golden JSON files + testdata README; contracts README | `contracts/**`, `packages/fb_api_client/**` (generated) | all contract checks green except conformance (expected red until WP2); `make gen-check` clean |
| **WP2** BuildingBlocks, modules, roles, OpenAPI | dotnet-engineer | §3.1 BuildingBlocks (core + Web); Account module + move `/v1/config` (delete `Host/Config`); `ModuleCatalog`; `V1Api` group + metadata + `Finally` 426 convention; transformers (metadata-driven headers, `traceId`, validation schema, response headers); roles + `AddFbPlatform` + options validation + shutdown timeout; appsettings; `BuildingBlocks.Tests`; update `backend/README.md` (layout, modules, conventions, log-template rule) | `backend/src/**`, `backend/tests/BuildingBlocks.Tests/**`, `.slnx` | `make check-dotnet contract-conformance test-dotnet` green; `ConfigEndpointTests` unchanged and green (the move changed nothing); T-B* pass |
| **WP3** HTTP pipeline | dotnet-engineer | **Step 1 spike (≤1 h): built-in validation for an endpoint + record DTO defined in another assembly (`ProbeModule` in Host.Tests).** If it fails, apply R1's fallback before continuing. Then §3.2: forwarded headers, request id, exception handler, problem customizer + key casing, client headers/426, rate limiter + `OnRejected`, body limit, HSTS, status-code pages, health; `Host.Tests` (ApiFactory, ProbeModule, TestPeer filter); golden-problem tests | `backend/src/Host/Http/**`, `backend/tests/Host.Tests/**` | T-H*, T-G* green; `make check test` green; conformance still green |
| **WP4** Observability + scrubbing | dotnet-engineer | D3, D6, D7, OTel (resource: service name/version/env, AspNetCore + Http + Runtime instrumentation, health filtered, console/OTLP exporters); the same setup for the worker; canary tests; OTLP receiver test; "meta" tests | `backend/src/Host/Observability/**`, Host.Tests | T-O* green; `dotnet run` (Development) shows a trace in the console; no new warnings |
| **WP5** Architecture rules | dotnet-engineer | `ArchitectureRules` (T-A list) + fixtures (`Fixtures/Alpha`, `Fixtures/Beta`, incl. an allowed `Beta.Contracts` use); real rules over the catalogue assemblies | `backend/tests/Architecture.Tests/**` | real rules pass; every fixture violation is reported (test asserts the failure and the offending type name); the clean fixture passes |
| **WP6** Container, compose, CI | platform-engineer | D15/D16: Dockerfile (digests via `docker buildx imagetools inspect`), `.dockerignore`, compose, `make up/down/image-smoke`, `image-smoke.sh`, CI `image` job + gate `needs`, Dependabot docker entry; root README (`make up`, demo of a forced minimum version); `make doctor` unchanged (Docker already checked) | as listed | `make image-smoke` green locally, and output (size, UID) pasted into the WP report; CI `image` job green; `make up` + `curl` `/v1/config` works; `make down` cleans up |
| **WP7** App golden mapping | flutter-engineer | a test group in `failure_mapper_test.dart` that reads every `contracts/testdata/problems/*.json` and asserts the `Failure` (`validation-failed` → `InvalidInputFailure` with field errors, `rate-limited` → `RateLimitedFailure`, `upgrade-required` → `UpgradeRequiredFailure`, `version-conflict` → `ConflictFailure`); confirm the regenerated client needs no app change | `apps/mobile/test/core/api/failure_mapper_test.dart` | `make check-dart test-dart` green |

Docs at close (orchestrator, Phase E): `04` §4.2 rows Tracing (D8), Rate limits (429 only), Errors (traceId, 400 rule); `04` §3.3 + `10` §2 (`TimeProvider`); `09` §4 Logging row (D6, D7); `02` stack (built-in validation/logging, OTel 1.19, Sentry 6.12, chiseled-extra); backlog #2, #20, #22, #43 → done.

### 5. Test list
C# tests carry `[Trait("Req", …)]` where a spec ID applies (`10` §5).

**BuildingBlocks.Tests**
- T-B1 `AppVersion_parses_strict_semver_and_rejects_leading_zeros_prerelease_and_two_parts`
- T-B2 `AppVersion_compares_numerically` (`0.10.0 > 0.9.9`)
- T-B3 `UuidV7IdGenerator_returns_version_7_ids_ordered_by_time` (FakeTimeProvider)
- T-B4 `OptionsFeatureFlags_missing_flag_is_off`
- T-B5 `ErrorResults_map_each_ErrorKind_to_status_and_type` (Validation→400 `validation-failed` + errors; VersionConflict→412 `version-conflict`; NotFound→404, Conflict→409, Unauthorized→401, Forbidden→403 with the framework default type) · Req UX-052
- T-B6 `Result_success_and_failure_are_exclusive`

**Host.Tests: pipeline** (ApiFactory, environment `Testing`)
- T-H1 `Old_app_version_gets_426_upgrade_required_problem` (probe GET, `X-App-Version: 0.0.9`, min `0.1.0`) · UX-052 · exit 2
- T-H2 `Config_is_exempt_from_the_version_gate_and_returns_the_configured_minimum` (`0.0.1` → 200, `minimumAppVersion` = config) · backlog #43
- T-H3 `Kill_switch_wins_over_a_malformed_platform_header` (old version + `X-Platform: web` → 426)
- T-H4 `Missing_or_invalid_client_headers_get_400_with_header_keys` (theory: each header missing/invalid; `x-device-id` not a UUID; platform `Android`) · UX-052
- T-H5 `Invalid_body_gets_400_validation_failed_with_camelCase_errors` (`name`, `items[0].qty`, nested `child.code`) · UX-052 · exit 2
- T-H6 `Malformed_json_gets_400_validation_failed_with_empty_errors_and_fixed_detail` (also the wrong-type number `"12"` and a missing required member under Respect*) · UX-052
- T-H7 `Unhandled_exception_gets_500_with_traceId_and_X_Request_Id_and_no_internals` (the body has no `detail`, stack, exception message or type name; `traceId` == header) · UX-052 · exit 2
- T-H8 `X_Request_Id_is_echoed_when_valid_and_generated_otherwise` (valid inbound → same; none or invalid (`<script>`, 65 chars) → 32-hex == `traceId` on an error; inbound `traceparent` → the response id equals its trace id) · exit 2
- T-H9 `X_Request_Id_is_present_on_200_400_404_413_426_429_500` (theory)
- T-H10 `Rate_limited_request_gets_429_problem_with_Retry_After_and_RateLimit_headers` (limit 2; exact header formats; problem body; 2xx responses carry no RateLimit headers) · UX-052
- T-H11 `Rate_limit_partitions_by_client_ip_and_ipv6_slash_64`
- T-H12 `Forwarded_for_is_honoured_from_a_trusted_network_and_ignored_otherwise` (probe `/peer`)
- T-H13 `Invalid_trusted_network_fails_startup`; `Invalid_minimum_app_version_fails_startup`
- T-H14 `Body_over_256KB_gets_413_problem` (Kestrel via `UseKestrel()`)
- T-H15 `Unknown_route_gets_404_problem_with_type_and_title`
- T-H16 `Health_live_and_ready_return_200_without_client_headers_and_are_not_rate_limited`
- T-H17 `Hsts_header_is_sent_outside_Development_over_https`
- T-H18 `In_flight_request_completes_during_graceful_shutdown` (Kestrel; slow probe + `StopAsync`)
- T-H19 `Role_parser_selects_api_by_default_and_rejects_unknown_roles`; `Migrate_role_exits_zero`
- T-H20 `Error_result_from_a_handler_maps_to_version_conflict_412` (probe) · UX-052

**Host.Tests: golden problems** (shared with Dart)
- T-G1 `Server_problem_bodies_match_contracts_testdata_problems` (theory over the 4 files; real pipeline via probe: 400, 426, 429, 412) · UX-052
- T-G2 `Every_catalogue_type_has_a_golden_file_and_a_ProblemTypes_constant` (README table ↔ files ↔ `ProblemTypes`)

**Host.Tests: observability and scrubbing** (canaries: `CANARY-BODY` in JSON fields, `CANARY-QUERY` in `?q=`, `cafecafe-0000-7000-8000-00000000ca11` as `X-Device-Id`, `CANARY-EXCEPTION` as the probe's exception message, `CANARY-AUTH` in `Authorization`)
- T-O1 `No_canary_reaches_logs_for_200_400_426_429_500` (FakeLogger wrapped by `ScrubbingLoggerProvider`: message, state values, scopes, exception `ToString()`) · AC-041 · exit 3
- T-O2 `No_canary_reaches_activity_tags_events_or_status` (ActivityListener on all sources, same requests) · AC-041
- T-O3 `No_canary_reaches_metric_tags` (MeterListener) · AC-041
- T-O4 `Sentry_event_for_a_500_is_scrubbed` (fake DSN + capturing transport: header allowlist, no query, no data, no user, no exception value, no canary anywhere in the serialized envelope; exactly one event) · AC-041
- T-O5 `Every_logger_provider_is_scrubbed_except_Sentry` (resolve `IEnumerable<ILoggerProvider>` from the real Host services)
- T-O6 `Http_logging_is_not_registered_and_no_instrumentation_enrich_callbacks_are_set` (services + `AspNetCoreTraceInstrumentationOptions`/`HttpClientTraceInstrumentationOptions` inspection)
- T-O7 `ScrubbedException_keeps_type_and_stack_and_drops_messages_recursively` (unit; inner + aggregate)
- T-O8 `Log_lines_during_a_request_carry_the_trace_id_equal_to_X_Request_Id`
- T-O9 `Otlp_exporter_sends_traces_when_the_endpoint_is_configured` (in-test HTTP listener on loopback receives `POST /v1/traces` after `ForceFlush`) · exit 4
- T-O10 `Console_exporter_is_on_only_when_configured` (Development appsettings true, Testing false)

**Architecture.Tests**
- T-A1 BuildingBlocks doesn't depend on Host or any module · T-A2 BuildingBlocks core (non-`.Web`) doesn't depend on `Microsoft.AspNetCore.*` · T-A3 module `Domain` depends on no other layer of its module and not on ASP.NET/EF · T-A4 `Application` doesn't depend on `Api`/`Infrastructure` or ASP.NET · T-A5 `Api` and `Infrastructure` don't depend on each other · T-A6 a module depends on another module only through `<Other>.Contracts` · T-A7 nothing depends on Host · T-A8 no type uses `Microsoft.AspNetCore.HttpLogging` · T-A9 module public types are only the `IModule` implementation and `*.Contracts` · exit 5
- T-AF1…AF5 `Rule_<x>_fails_on_the_broken_fixture` (Alpha.Domain → Alpha.Infrastructure; Alpha.Application → Beta.Application; Alpha.Application → ASP.NET; public non-contract type in Beta; BuildingBlocks-like fixture → AspNetCore) + `Rules_pass_on_the_clean_fixture` (Alpha → Beta.Contracts allowed) · exit 5

**Contract.Tests** · T-C1 existing `GetConfig_returns_200_json_with_contract_shape` (+ `X-Request-Id` 32-hex) · T-C2 `GetConfig_without_client_headers_returns_400_validation_problem` · exit 1

**Image smoke** (`make image-smoke`, CI `image`) · T-I1 non-root UID 1654 · T-I2 health + `/v1/config` 200 with contract keys · T-I3 trace id in console exporter output == `X-Request-Id` · T-I4 `migrate` exits 0 · T-I5 `docker stop` exit 0 < 10 s · size printed · exits 1, 4, 6

**Dart (WP7)** · `UX-052 golden problem bodies map to their Failure` (4 cases)

### 6. Exit-criteria mapping

| Exit criterion | Demonstrated by |
|---|---|
| `make up` starts the API; `/v1/config` conformant; conformance passes | WP6 demo (`make up`, `curl -H … 127.0.0.1:5198/v1/config`, output in evidence) + T-I2 in CI + T-C1/T-C2 + `make contract-conformance` in CI |
| Old `X-App-Version` → 426; validation → 400 with `errors`; unhandled → 500 with request id, no stack; `X-Request-Id` echoed | T-H1, T-H3, T-H5, T-H6, T-H7, T-H8, T-H9, T-G1 |
| Log scrubbing test proves request bodies never reach logs | T-O1 (+ T-O2–T-O7 for traces, metrics, Sentry and the meta rules) |
| Traces in the console exporter locally; OTLP configurable | T-I3 (container, Development) + local `dotnet run` screenshot/paste; T-O9 (OTLP really exports), T-O10 |
| ArchUnitNET rules pass and fail correctly | T-A1–A9 green + T-AF1–AF5 (each broken fixture reported) |
| Image runs as non-root; size noted | T-I1 in CI + `make image-smoke` output; size (`docker images` + compressed) written into the Outcome |

### 7. Risks & unknowns

| # | Risk | Handling |
|---|---|---|
| R1 | Built-in validation may skip DTOs/endpoints in other assemblies (the source generator works per compilation) | WP3 step 1 spike with `ProbeModule`. Try in order: the module calls `services.AddValidation()` in its own `AddServices` (generator runs there); `[ValidatableType]`. Fallback: a ~60-line endpoint filter on the `/v1` group doing recursive `Validator.TryValidateObject`, producing the same `HttpValidationProblemDetails` (D1 still holds: DataAnnotations, same output, no new package) |
| R2 | Wrapping providers (D6) clashes with OTel or console internals (scope provider, provider disposal/flush) | WP4 starts with T-O5 + T-O8. Fallback: a custom JSON `ConsoleFormatter` + an OTel `BaseProcessor<LogRecord>` that replaces `LogRecord.Exception`. Same `ScrubbedException`, same tests |
| R3 | Sentry's `Transport` may not be settable from tests | Fallback: the T-O4 assertions run `SentryScrubber.Scrub` on an event the SDK builds via `SentrySdk.CaptureException` with a `BeforeSend` capture hook. T-O5/T-O6 still prove registration |
| R4 | `RespectRequired…`/`RespectNullable…` change the build-time document (nullability) and break conformance | WP2 tries them first. If the document changes, keep them off and enforce required members with `[property: Required]` on request DTOs (record the deviation) |
| R5 | `UseExceptionHandler` clears headers, so `X-Request-Id` could vanish on 500 | Set in `OnStarting` (research §5); T-H9 covers 500. Fallback: the handler sets it again |
| R6 | oasdiff may or may not compare response headers (oasdiff #1094) | The transformer emits them either way; nothing depends on the answer |
| R7 | Docker `image` job time and flakiness (SDK image pull ~ 300 MB) | Pinned digests, one retry on pull. If it adds > 5 min, move the build to a cached `docker buildx` layer (orchestrator call; no owner impact) |
| R8 | Dependabot bumps `global.json` (dotnet-sdk) and the Dockerfile (docker) separately, so the SDK image can lag `global.json` | The `image` job fails fast on the mismatch. A comment next to both pins says "bump together" |
| R9 | The real 426 *status* can't be shown on the phone in S03 (the app calls only the exempt `/v1/config`) | Demo the forced minimum (D9) in S07's phone session (batched, TD-037). The 426 status is covered by T-H1 (+ the app's dio interceptor tests from S06a) |
| R10 | Per-IP limits behind CGNAT, or a misconfigured trust list making every client the proxy IP | 300/min default, configurable; startup log of trusted networks; T-H12. Real network values verified in S05/S29 (research "still to verify") |
| R11 | `GetDocument.Insider` runs `Program` (Sentry, OTel, `ValidateOnStart`) | Empty DSN = no-op; OTLP only with an endpoint; `ValidateOnStart` and the exporters are skipped under the build-time guard; `make contract-conformance` proves it |
| R12 | OTLP log records show `ScrubbedException` as `exception.type` (D6 trade-off) | Accepted: the type is in the message, the stack is intact, and Sentry keeps real types. Revisit with Grafana in S05 |

### 8. Size check
**L, about 2.5 sessions** (the card says M). The work: 8 WPs; WP3 and WP4 are the heavy ones, plus one new CI job. It isn't above L, so no split is proposed. If the orchestrator wants smaller gates, the natural seam is **S03a** "Host & HTTP conventions" (WP0–WP3, WP5, WP7: exit criteria 1, 2, 5) and **S03b** "Observability & container" (WP4, WP6: exit criteria 3, 4, 6). S03b depends only on S03a's pipeline.

### 9. Amendments after architect review (2026-10-16, orchestrator-applied; these override the sections above)

| # | Change | Overrides |
|---|---|---|
| A1 | **Role = `args[0]`** if present and not starting with `-`, else `api`. An unknown positional `args[0]` exits 2. The role token is stripped before the host builder. T-H19 adds `["--contentRoot","/x"]` → api and `["migrate","--foo=1"]` → migrate | D14, `Roles/RoleParser.cs` |
| A2 | **No inbound `X-Request-Id` echo:** it's a response-only header and always equals the trace id (32 lowercase hex) and `traceId`. Inbound correlation is `traceparent` only, and an inbound `X-Request-Id` is ignored. No regex, no `ClientRequestId` scope, no `fb.client_request_id` tag. Fallback `ActivityTraceId.CreateRandom()` when there's no Activity. T-H8 reworked (none → 32-hex == traceId; traceparent → its id; inbound X-Request-Id ignored). Exit criterion 2 reads "`X-Request-Id` returned on every response (= `traceId`)" | D8, §3.4, T-H8 |
| A3 | **`ScrubbingLoggerProvider` forwards `Dispose`/`DisposeAsync` and `ISupportExternalScope`** to the inner provider. Test: a line logged just before `StopAsync` reaches the sink. T-O5 fails closed: any non-Sentry `ILoggerProvider` that isn't a `ScrubbingLoggerProvider` fails | D6, T-O5 |
| A4 | **Rules without a spec ID** are tagged `[Trait("Rule", "<doc>.<section>-<slug>")]` plus a one-line class comment, never `Req`/`// covers:`. T-O1–T-O4 → `Rule 09.4-logging`. The UX-052 tags on T-B5, T-H1, T-H4–H7, T-H10, T-H20, T-G1 and the WP7 Dart test → `Rule 04.4.2-errors` (Dart names don't start with a spec ID). Card Spec line: "supports UX-052 (proved by the first UI step that shows a `Failure`)". `10` §5 gets the convention at close | §5, card Spec |
| A5 | `contracts/README.md` required/nullable exceptions: `ProblemDetails.traceId` is optional (with `detail`, `instance`) | D19, TD-043 wording |
| A6 | **Bookkeeping:** size M → L (card + board); WP0 is in Scope as its own first commit `build(deps): …`. Docs at close add: `04` §4.2 Versioning "426 + update screen; store link from S29"; `04` §3.2/§3.3 `IClock` → `TimeProvider` | card, Docs at close |
| A7 | (suggestions taken) ArchUnitNET rule in T-A: module code must not call `DateTime(Offset).UtcNow/Now`, `TimeProvider.System` or `Guid.NewGuid`. `IModule` docs drop "Name = Postgres schema later" (S04 decides). The compose file is commented that `Development` is local-only. Forward note to S05: the synthetic `/v1/config` uptime check must send the three client headers (fixed `X-Device-Id`) or it gets a 400 | T-A, D12, D16 |

Rulings: one step, not split (TD-054). WP0 inside S03. `TimeProvider` accepted (Dart keeps its `Clock`). D6 kept with A3. D2 (malformed JSON → `validation-failed` with `errors: {}`) and D12 approved. The `image` job joins the `ci` gate on every push. TD rows: TD-057 (D8 correlation), TD-058 (D3/D6/D7 telemetry privacy); D12 → `04` §3.3 + `backend/README.md`; D1/D3/D15/pins → `02` stack update.

**Plan approved by the orchestrator under TD-037 (no ⚠️ OWNER item), 2026-10-16.**

Codex implementation clarification (2026-10-16): T-A9 permits public positional records under a module's `Api` namespace for built-in validation, including nested request DTO types; responses stay internal by convention. T-A6 still rejects any cross-module use of these public records. Architecture targets include referenced type stubs; missing Domain/Infrastructure layers are allowed, with broken fixtures proving each restriction.

## Handoff to Codex (2026-10-16, TD-059)
The owner moved backend work to Codex. From here, Codex owns this step: plan changes, implementation, review, verify, close and merge (`AGENTS.md`, `13` §10). Claude did the plan and WP0–WP3 + WP7.

**State** (branch `step/S03-backend-host`, all green and pushed: `make check`, `make test`, `make gen-check`; 119 .NET tests):
- ✅ WP0: .NET 10.0.13 security bump.
- ✅ WP1: contract (traceId, ValidationProblemDetails, 400/426/429 responses, X-Request-Id, golden problems).
- ✅ WP2: BuildingBlocks, IModule + the Account module, `/v1` group, roles.
- ✅ WP3: HTTP pipeline.
- ✅ WP7: app golden mapping.
- ✅ **WP4** Observability + scrubbing (D3, D6, D7, A3; TD-058).
- ✅ **WP5** Architecture rules (T-A list, A7).
- ✅ **WP6** Container, compose, CI `image` job (D15, D16).

**What to know** (details in the Progress log and `backend/README.md`):
- **Validation:** built-in validation runs only when each module calls `services.AddValidation()` in its `AddServices` (Account does). The .NET 10.0.13 generator silently skips `internal` DTOs, so **validated request DTOs must be `public`**. WP5 must loosen T-A9 for public request records in `*.Api`, while T-A6 still blocks cross-module use.
- **WP4 seam:** `HttpSetup.AddFbHttp` sets `SuppressDiagnosticsCallback`. It suppresses only `BadHttpRequestException`, so real 500s still reach logging and Sentry. The `ProxyOptions` trusted-networks line logged at startup is configuration only.
- **426 demo:** on the phone only via `FB_MIN_APP_VERSION=99.0.0 make up` + `make run-dev` (config path). A real 426 needs a gated endpoint the app calls (S24/S25). Tests cover it.
- **Review:** your own independent review with a security pass (WP4 touches logging/telemetry; TD-061). No Claude cross-review. The contract (WP1) is already in.
- **At close:**
  - TD-057 and TD-058 become Accepted.
  - Docs at close: §4 "Docs at close" plus A6.
  - Forward notes: the S05 uptime check needs the client headers (A7); backlog #2, #20, #22 and #43 are closed by this step (#21 stays with S26: generic multi-endpoint response schema validation); tag `10` §5 with the `Rule` trait convention (A4).

## Progress log
_One dated line per event, newest last (process §8a)._

- 2026-10-16 · A: ready (S02 ✅, main green 2bdd88a, no owner prerequisites). Gaps: no Sentry account (empty DSN = off, as in the app), no Postgres until S04. B: one research brief (validation, logging, base image, rate-limit headers, request correlation) launched.
- 2026-10-16 · B: research done (research-notes "S03 — Backend host"): built-in AddValidation, built-in JSON logging + OTel, aspnet 10.0-noble-chiseled-extra (digest-pinned), built-in rate limiter + custom OnRejected headers, X-Request-Id = W3C trace id, Sentry.AspNetCore 6.12.1 errors-only with header allowlist, ArchUnitNET 0.13.4. step-planner launched.
- 2026-10-16 · B: low-level plan written (L, ~2.5 sessions, 8 WPs incl. WP0 .NET 10.0.13 security bump; no ⚠️ OWNER item). Card Spec line corrected (AC-041 is AI context). Architect review launched.
- 2026-10-16 · B: architect approve with changes; A1–A7 applied; plan approved under TD-037. Size L (one step). C: WP0 (.NET security bump, platform-engineer, Sonnet) launched.
- 2026-10-16 · C: WP0 committed (SDK 10.0.402, OpenApi/ApiDescription.Server/Mvc.Testing 10.0.13; check-dotnet/test-dotnet/conformance green). WP1+WP2 (contract + BuildingBlocks/modules/roles, dotnet-engineer) launched.
- 2026-10-16 · C: WP1 + WP2 committed and pushed together (contract: traceId, ValidationProblemDetails, 400/426/429 responses, X-Request-Id on every response, golden problems; backend: BuildingBlocks Result/Error/AppVersion/UUIDv7/flags, IModule + Account module owning /v1/config, V1Api group with the 426 Finally convention, roles per A1; 54 .NET tests). Deviations: Spectral fb-id-format exempts traceId; per-ip policy is metadata-only until WP3 registers it. WP3 (HTTP pipeline) launched.
- 2026-10-16 · C: WP7 committed (f1ed340: app maps every golden problem body; no mapper change). WP3 interrupted by a session limit (partial, uncommitted: Host/Http, Host.Tests Http/Infrastructure), resumed. Owner: from now on Codex does backend + integration, Claude frontend; after WP3 the collaboration model is discussed before WP4–WP6.
- 2026-10-16 · C: WP3 committed (pipeline: forwarded headers, X-Request-Id = trace id, exception handler, HSTS, client headers + 426 first, per-ip rate limit with RateLimit headers on 429, 256 KB body limit, problem customizer with camelCase errors, health; golden problem test; 119 .NET tests). Spike: built-in validation works per module (`AddValidation()` in each module). ⚠️ for WP5: the .NET 10.0.13 generator skips `internal` DTOs, so validated request DTOs must be public → adjust T-A9. Paused before WP4–WP6: owner is moving backend + integration to Codex; collaboration model to agree first.
- 2026-10-16 · Handoff: owner moved backend to Codex (TD-059). Handoff section written; Codex continues with WP4–WP6, review, verify, close.

- 2026-10-16 · C: Codex resumed; merged origin/main (TD-061). Re-read AGENTS Review: independent whole-diff review with a security pass, no Claude cross-review. WP4 → WP5 → WP6, then review/verify/close.

- 2026-10-16 · C: WP4 complete: JSON console + OTel traces/metrics/logs, configurable OTLP and local-only console exporters, errors-only Sentry, exception/provider scrubbing for all roles. Canary/serialized-envelope tests prove no content and one correctly grouped 500; OTLP HTTP receiver and lifecycle/scope tests pass. Gates: check-dart (format/analyze/app-check), check-dotnet, check-contract, APK hardening self-tests and make test green (132 .NET tests). Deviations: custom capturing logger instead of FakeLogger; exact ASP.NET/generic Sentry provider allowlist; metrics dropped by callback (EnableMetrics is ignored); public OTLP protocol/URL overload. Research and backend README updated. WP5 next.

- 2026-10-16 · C: WP5 complete: reusable ArchUnitNET rules over the real ModuleCatalog plus clean/broken fixtures; layer and module isolation, public surface (Api request-record exception), Host isolation, no HTTP logging and injected time/IDs. 15 broken-fixture cases identify offending types, including forbidden cross-module public DTO use. Referenced type stubs and method-call targets are included so framework/static-call bans cannot silently pass. make check test green, 158 .NET tests. WP6 next.

- 2026-10-16 · C: WP6 complete: digest-pinned SDK/runtime Dockerfile, non-root chiseled-extra image, loopback-only hardened compose, make up/down/image-smoke, Dependabot docker entry and required CI image job. Image smoke PASS: UID 1654, config/health 200, matching console trace, migrate exit 0, stop 0 s/exit 0; image 164,996,413 bytes, gzip archive 69,587,394 bytes. Compose normal and forced-minimum (99.0.0) configs both 200; down removed container/network. Local dotnet run Development also printed a matching trace. make check test gen-check green (158 .NET tests). Closeout conventions/stack/S05 forward notes updated. Image probe corrected to include PID in docker top output (Docker requires it).
- 2026-10-16 · D: independent whole-diff code/security review launched in separate reviewer agent s03_independent_review (TD-061), including inherited WP0–WP3/WP7. No heavy builds remain running; awaiting findings before formal verification. WP6 pushed for CI.

- 2026-10-16 · D: independent review r1 (whole diff + security) requested one major fix: ordinary AddHttpLogging/UseHttpLogging extension calls bypassed the namespace ban and optional-interceptor probe. Fix targets their assembly, adds both extension-call fixtures and checks the required pool service with a positive no-options registration test. One minor (unsupported Accept yields text/plain) logged as backlog #53; current app JSON requests unaffected. No production content leak or other blocker found. Scoped re-review follows green checks.

- 2026-10-16 · D: review r2 approved the HTTP-logging guard fix; no remaining blockers/majors or regressions. Verification: all six exit criteria passed with named tests, real OTLP receiver, dotnet/container console traces, compose demos, non-root/lifecycle/size measurements; evidence in steps/evidence/S03-verification.md. Full final checks rerun for the review fix (161 .NET cases).

- 2026-10-16 · E: verified 6/6 exit criteria after independent review r2 approval; full make check test (161 .NET cases), gen-check, image/compose/console/OTLP evidence recorded. Outcome, board, TD-057/058 and backlog updated. No owner action needed (TD-037/061). Preparing the CI-verified squash on merge/S03; main is fast-forwarded only after ci succeeds on that exact SHA.

- 2026-10-16 · C: squash 467013e held from main: CI .NET tests failed on the shutdown capture provider's immediate Disposed assertion (all other .NET cases passed; build/conformance/image passed). WebApplicationFactory and RunAsync may dispose the host concurrently. Reopened implementation: await an explicit disposal signal with a bounded timeout, retaining final-line, correlation and disposal assertions. No production-source change. Re-review and fresh squash CI required.

- 2026-10-16 · D/E: independent review r3 approved the disposal-signal fix; no open blockers/majors. Five focused shutdown-test runs and GITHUB_ACTIONS=true make check test pass (161 .NET cases). Verification/Outcome updated; source/image unchanged. Recreating merge/S03 from origin/main for a fresh squash CI run; failed 467013e will never be pushed to main.

- 2026-10-16 · E: replacement squash 0c2fd97 passed .NET and image CI jobs. Final closeout check found stale start-here status in AGENTS.md and technical-planning/README.md; updated only those status lines to S03 complete / S04 next. Rebuilding the squash so the final documentation and code share the same CI-verified SHA.

## Outcome
_Written 2026-10-16, Phase E._

**Built.** A modular ASP.NET Core host with api/worker/migrate roles, shared platform services, Account-owned `/v1/config`, contract-driven `/v1` conventions and complete HTTP error/client-header/version/rate-limit/forwarded-header/body-limit/health handling. Structured JSON logs, OTel traces/metrics/logs and errors-only Sentry share the TD-058 privacy boundary; canaries cover actual sink surfaces and serialized Sentry events. Architecture rules enforce boundaries and injected time/IDs, with positive failure fixtures. A digest-pinned, non-root chiseled-extra image runs through hardened local compose; the `image` CI job smoke-tests it and joins the required gate. Four golden problems also map through the app.

**Verification.** Six exit criteria pass; [evidence](evidence/S03-verification.md) names tests, real OTLP/console/compose demos and measurements. `make check test` passes: **161 .NET cases**, Dart/app/tool checks and tests, contract checks/conformance and APK hardening self-tests, zero new warnings. `make gen-check` is clean. Independent whole-diff code/security review: **3 rounds**, **0 blockers, 1 major fixed and re-reviewed, 1 minor logged** (#53), no open blocker/major. The major was a false-negative HTTP logging guard, corrected to cover the assembly and both ordinary extension calls plus the required-service meta probe. Merge uses only a squash SHA with a green `ci` gate (TD-036/039).

**Deviations.** Built-in validation requires per-module `AddValidation()` and public request records; T-A9 permits Api records while module isolation still forbids cross-module consumption (handoff amendment). A custom capturing logger replaces the planned FakeLogger dependency. Sentry ASP.NET has two specialized providers, so exact ASP.NET/generic identities bypass the exception wrapper and BeforeSend performs scrubbing; the one-event/original-type test proves deduplication. Sentry metrics use a drop callback because EnableMetrics is ignored. OTel 1.19.1 needs the public protocol/base-URL exporter overload. Image compression is measured as a gzipped image archive, clearly labelled rather than claimed as registry-transfer size. The first squash CI exposed a test-host disposal race: the shutdown test now awaits the sink's explicit disposal signal with a bounded timeout rather than assuming the host graph is already drained. Independent review round 3 approved this without weakening final-record/disposal checks. Amendments A1–A7 remain in force, including response-only request correlation and BCL TimeProvider.

**Follow-ups.** Backlog #2 (Dependabot Docker), #20 (Account move), #22 (MVC log noise) and #43 (old-version config refresh) closed. #21 remains S26's generic multi-endpoint runtime schema validator, outside this step's single-config scope. Review minor #53: unsupported Accept can yield plain-text fallback; app JSON requests are unaffected. S05 carries real proxy/telemetry/uptime-header checks. Phone forced-minimum demo is batched with S07 under TD-037; server/config behavior is verified here.

**TDs.** TD-057 (single trace-id correlation) and TD-058 (server telemetry privacy) Accepted. TD-061 governs independent Codex review; no new vendor, paid service, scope cut, Accepted-TD change or production operation.

**Metrics.** Planned **L (~2.5 sessions)**; actual **L**, completed across the inherited Claude work and this Codex continuation. **8 WPs + 2 fix packages**. **161 .NET cases** (159 added versus main's 2; 42 added after the 119-case handoff), four shared Dart golden cases, 17 broken architecture fixture cases plus the clean fixture. Runtime **UID 1654**, image **164,996,413 bytes (157.35 MiB)**, gzip archive **69,587,394 bytes (66.36 MiB)**; migrate exit 0, idle API stop **0 s / exit 0**. Lesson: privacy guard fixtures must exercise the ordinary extension methods, not only option types in the expected namespace.
