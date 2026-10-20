# backend/

The Fitness Buddy API: an ASP.NET Core (.NET 10) modular monolith. Architecture, modules and rules are in `technical-planning/04-backend.md`. Right now: the host with its three roles and module system (S03), the `Account` module (`GET /v1/config`) and the isolated experimental `UserData` sync module (B01), a build-time OpenAPI document that CI checks against `contracts/openapi.yaml` (S02), transactional Postgres persistence, outbox/jobs/schedules and POST replay (S04), and the Identity module (B04) for guest/Google/email sign-in and sessions.

## Layout

| Path | What it is |
|---|---|
| `FitnessBuddy.slnx` | The solution (XML `.slnx` format) |
| `global.json` | Pins the .NET SDK (10.0.402, latest patch) and selects Microsoft.Testing.Platform for `dotnet test` |
| `Directory.Build.props` | Settings for every project: `net10.0`, nullable, analyzers (`latest-recommended`) and code style in the build, warnings as errors, NuGet audit |
| `Directory.Packages.props` | Central package management: every package version lives here, with transitive pinning |
| `nuget.config` | nuget.org is the only package source (source mapping `*` → nuget.org) |
| `src/Host/` | Composition root (`Microsoft.NET.Sdk.Web`): `Program.cs` (role dispatch), `Roles/` (`api`, `worker`, `migrate`), `Platform/` (what the roles share), `ModuleCatalog.cs` |
| `src/Host/Http/` | The HTTP pipeline (below): request id, problem details, client headers and the 426 gate, rate limiting, forwarded headers, health |
| `src/Host/OpenApi/` | OpenAPI transformers that make the generated document match the contract's conventions (see below) |
| `src/BuildingBlocks/` | The lowest shared layer. `FitnessBuddy.BuildingBlocks.*`: results/errors, ids, feature flags, current user, client info, no ASP.NET Core. `FitnessBuddy.BuildingBlocks.Web.*`: `IModule`, the `/v1` group (`V1Api`), problem types, `Error` → problem mapping. Never depends on Host or a module |
| `src/Modules/<Module>/` | One project per module (`FitnessBuddy.Modules.<Module>`), with `Api/`, `Application/`, `Domain/`, `Infrastructure/` folders as needed. Installed: `Identity`, `Account`, `UserData`, `Buddy` |
| `tests/BuildingBlocks.Tests/` | Unit tests of BuildingBlocks |
| `tests/Host.Tests/` | Tests of the Host: roles and the HTTP pipeline, through `ApiFactory` (the real api role in environment `Testing`) and a test-only `ProbeModule` under `/v1/_probe/…`; golden problem bodies |
| `tests/Architecture.Tests/` | ArchUnitNET rules that keep the layers and module boundaries honest |
| `tests/Contract.Tests/` | HTTP tests (`WebApplicationFactory<Program>`) that check the runtime JSON against the contract |
| `artifacts/openapi/server.json` | *(generated, gitignored)* the server's OpenAPI document, written by every Host build |

Code style: `.editorconfig` at the repo root (C# section). Style and analyzer warnings fail the build.

## Roles

One executable, three roles, chosen by the first argument (`args[0]`, when it doesn't start with `-`; default `api`): `FitnessBuddy.Host [api|worker|migrate] [host options]`. Anything else exits with code 2 and a usage line. The role token is removed before the host builder sees the arguments.

| Role | Does |
|---|---|
| `api` | Stateless HTTP (`WebApplication`) |
| `worker` | Polls durable outbox/jobs and UTC schedules using fb_app; handles shutdown cancellation without consuming attempts |
| `migrate` | Applies registered schema migrations with fb_migrator; verifies/explicitly initializes recovery state and holds the global maintenance lock for seeds, keys and dataset rotation; exits1 on failure |

`api` and `worker` share `PlatformSetup.AddFbPlatform` (options with validation on start, `TimeProvider`, ids, flags, the current user, every module's services). Shutdown waits up to 25 s for in-flight work (under Kamal's 30 s stop wait).

## Modules

A module is a project under `src/Modules/<Name>/`. Its public surface is the `IModule` implementation, `*.Contracts` types for other modules, and validated request records under `*.Api` (the validation generator requires public types). Response DTOs and other implementation types are `internal`. Public API records remain inaccessible to other modules under the architecture rules.

```csharp
public interface IModule
{
    string Name { get; }                                                     // = its OpenAPI tag
    UserDataOwnership UserData { get; }                                      // table classification + eraser
    void AddServices(IServiceCollection services, IConfiguration configuration);
    void MapEndpoints(RouteGroupBuilder group);                              // routes relative to /v1
}
```

- **Add a module:** create the project (`Microsoft.NET.Sdk` + `<FrameworkReference Include="Microsoft.AspNetCore.App" />`, referencing BuildingBlocks), add it to the solution and as a reference of the Host, add one line to `ModuleCatalog.All`, and include its project in the Dockerfile restore-copy list. There is no assembly scanning. Declare every owned/global table and its deletion participant; the inventory and missing-eraser tests enforce B06 coverage.
- **The `/v1` group is the one definition** of what every endpoint shares (`V1Api.MapV1`): the client-header requirement (`ClientHeadersMetadata`), the `per-ip` rate limit, and the shared error responses 400 (`ValidationProblem`), 429, 500, plus 426 for every endpoint that isn't `.AllowOutdatedClients()`. The Host maps each module into `V1Api.MapModuleGroup`, which tags the group with the module's name. Endpoints declare only their own success and domain-error responses.
- **Layers** (`04` §3.2): `Api/` (endpoints + DTOs) → `Application/` (one handler per use case, ports as interfaces, options) → `Domain/` (pure). `Infrastructure/` implements ports. Application and Domain never use ASP.NET Core.
- **Endpoints are thin:** bind, call the injected handler, map the result. A handler returns `Result<T>`/`Result` for expected failures, and the endpoint maps it with `result.ToHttpResult(TypedResults.Ok)`: Validation → 400 `validation-failed` with `errors`, VersionConflict → 412 `version-conflict`, NotFound/Conflict/Unauthorized/Forbidden → 404/409/401/403 with the framework's default `type`. `Error.Code` is for logs and tests and is never sent; `Error.Detail` is, so it must be English and free of user content.
- **Time and ids:** inject `TimeProvider` (BCL; tests use a fake) and `IIdGenerator` (UUIDv7). Never `DateTime.UtcNow`, `DateTimeOffset.UtcNow`, `TimeProvider.System` or `Guid.NewGuid()` in module code.
- **Client headers** are validated before the endpoint runs; read them with `HttpContext.GetClientInfo()`. `ClientInfo.DeviceId` never goes into logs or telemetry.
- **Validation** (built-in, DataAnnotations): put the rules on the request DTO with `[property: …]` (validates *and* documents the constraint). Two traps of the .NET 10 source generator, both silent (the endpoint just isn't validated):
  - **Every module calls `services.AddValidation()` in its own `AddServices`.** The generator only sees the endpoints and DTOs of the assembly that makes the call, so a call in the Host doesn't cover a module.
  - **Request DTOs that carry validation are `public`** (and so are the types nested in them). The generator skips `internal` types, and `[ValidatableType]` doesn't change that. Response DTOs and everything else stay `internal`.

  Cross-field rules use `IValidatableObject`. Rules that need data (ownership, uniqueness) belong in the handler and return a `Result` error.

## Architecture gate

`tests/Architecture.Tests/ArchitectureRules.cs` builds the same ArchUnitNET rules for the real module
catalogue and the clean/broken fixtures. Rules cover BuildingBlocks core/web boundaries, inward layers,
module contracts, the public surface, Host isolation, no HTTP logging and injected time/IDs. Dependency
targets include referenced type stubs, so framework bans cannot pass merely because a framework assembly
wasn't loaded. Empty future layers are permitted; broken fixtures prove positive failures and name the
violating types, including all banned static time/ID calls.

## HTTP pipeline (api role)

In order (`src/Host/Http/HttpSetup.cs`): forwarded headers → request id → exception handler → HSTS (not in Development) → status-code pages → routing → rate limiter → client headers + 426 gate → authentication (B04) → opted-in POST idempotency → endpoints (`/health/*`, `/v1`).

- **Forwarded headers:** `X-Forwarded-For`/`-Proto`, one hop, trusted from loopback and `Proxy:TrustedNetworks` (CIDRs, checked at startup) only.
- **Request id:** every response has `X-Request-Id` = the W3C trace id (32 lowercase hex), also the problem's `traceId`. An inbound `traceparent` is honoured; an inbound `X-Request-Id` is ignored.
- **Problems:** everything goes through `IProblemDetailsService`, so `ProblemDetailsCustomizer` shapes every error body: `type`/`title` always set, `traceId` added, every 400 is `/errors/validation-failed` with `errors` (keys camelCased; empty, with a fixed `detail`, when the body can't be read). Middleware writes its problems the same way. Unhandled exceptions: 500 with no `detail`.
- **Client headers:** `/v1` endpoints need valid `X-App-Version`, `X-Platform`, `X-Device-Id` (400, keyed by the lowercase header name). A valid version below `Clients:MinimumAppVersion` gets 426 first, unless the endpoint is `.AllowOutdatedClients()` (`/v1/config`).
- **Limits:** request bodies ≤ 256 KB (Kestrel, 413). Rate limit `per-ip` on `/v1` (`RateLimiting:PerIp`, IPv6 by /64): 429 with `Retry-After`, `RateLimit`, `RateLimit-Policy`.
- **Health:** `/health/live` is independent; `/health/ready` executes a bounded Postgres probe and returns 503 when it fails. Both are plain text outside `/v1`: no client headers, no rate limit, not in the contract.

## Persistence and background work (S04, TD-062)

`make up` builds one image, starts a private Postgres 18.6, applies migrations, then starts api + worker.
Only the API publishes a loopback port (5198). `make down` preserves the database volume. Bootstrap
passwords in `infra/compose/postgres/001-roles.sql` are **local-only**; B03 uses independent secrets for the private phone server; B13 provisions Hetzner secrets.
Neither the API nor worker receives migrator credentials. Password/SCRAM connections disable native GSS/Kerberos discovery; explicit GSS Require is rejected rather than downgraded. TLS settings are preserved. Do not point this bootstrap at an existing
production database. A changed bootstrap script only applies to a fresh local volume.

For native `dotnet run`, set `ConnectionStrings__Application` to a reachable fb_app connection;
the Development default points at localhost, but compose deliberately publishes no database port.
Use compose for the full stack. Supply `ConnectionStrings__Migrator` **only** to the migrate process.
Build-time OpenAPI generation never opens a database or runs migrations.

- A module registers `ModuleMigration(schema, connection => new MyContext(DatabaseConfiguration.ContextOptions<MyContext>(connection, schema)))` in its `AddServices`. Its context derives from `ModuleDbContext`, configures entities, then calls base. Each schema has its own `__ef_migrations_history`. Migrations are ordered by schema and then EF migration ID, under a shared session lock. Avoid cross-module migration dependencies. Expand first; destructive contractions need a later release.
- Infrastructure repositories start `UserDatabase.BeginAsync(ct)` (identity from ICurrentUser), create a context with `session.Connection`, and call `session.EnlistAsync(context, ct)`. Use the injected clock/UUIDv7 generator for values. Context and raw commands then share one transaction. User-owned tables require ENABLE + FORCE RLS with USING and WITH CHECK against `NULLIF(current_setting('app.user_id', true), '')::uuid`. No identity means no rows; never set a session-level user. Ordinary repositories still scope queries by the principal.
- `QueueWriter` uses that same scoped session. Publish events before committing the business change. User identity is copied from the session into the durable envelope and set transaction-locally by the worker. System jobs have no user context. `ops.*` is internal infrastructure owned by BuildingBlocks; product modules never query it directly. No product tables have been added yet: a test-only module proves the pattern.
- Register database-only `IOutboxHandler` / `IJobHandler` implementations. Their writes use the supplied session, with **no commits or network calls**. Keep event type and handler name stable across deploys. Effects, per-handler processed marker and acknowledgement commit together. A crash rolls them all back; duplicate delivery skips processed handlers. This provides exactly-once database effects, not exactly-once remote calls. External adapters must accept a stable operation key and be independently idempotent.
- Default retries: five attempts, starting at 5 seconds, doubling to a one-hour cap. Failures roll back to a savepoint before persisting attempts. Exhausted/unknown message types become dead letters; payloads and exception messages never enter logs. Shutdown cancellation rolls back without counting an attempt. Dead letters remain for inspection; there is no public administrative queue API.
- `JobScheduler.RegisterAsync` uses five-field UTC cron. Durable cursors survive restarts; missed ticks coalesce into one run. Claims and uniquely keyed job insertion share a transaction. The worker registers `ops.cleanup` every five minutes: expired replay records and completed queue records older than seven days are removed; dead letters stay. Future history/account purge handlers arrive with their modules.
- An unsafe POST opts in using `.RequireIdempotency()` and declares its header/400/409 responses in the contract **before** becoming a product endpoint. The middleware requires authenticated ICurrentUser (B04 must define any pre-auth scope), serializes user + method + path + key, fingerprints body bytes/content type/query, and commits business effects + response atomically. Replays last 24 h; changed fingerprints get 409. Buffers: 256 KiB request, 1 MiB response. 5xx, exceptions and cancellation roll back. Only ETag/Location replay; never cookies. Problem bodies refresh traceId to match the current X-Request-Id. All actual product POSTs are still later steps.
- Postgres logs only infrastructure-level FATAL/PANIC messages, with terse detail and statement/parameter logging disabled; ordinary SQL errors can echo private values. API/worker logs retain scrubbed error types and IDs. Carry these settings into B13.
- SQL diagnostics/logging and Npgsql command/batch/COPY/open tracing are disabled at the source, including under broad listeners. Never enable sensitive data, parameter logging, SQL enrichment or driver error detail.

`tests/Persistence.Tests` uses one assembly-shared Testcontainers Postgres 18.6 (digest matches compose),
real application/migrator logins, a test-only schema/context and isolated IDs. Tests terminate a backend
connection after an effect, race workers/requests, advance a fake clock, pause Postgres for health
checks and inject private canaries into database errors. Docker must be available for `make test-dotnet`.

## Logging rule

Log message templates take **IDs, codes and enums only**: never request or response bodies, message text, emails, tokens, codes sent to users, device ids, query values or exception messages (`09` §4). Use `[LoggerMessage]` source-generated methods.

## Observability

All roles use JSON console logging (UTC, trace scopes), OpenTelemetry and errors-only Sentry (TD-058).
Every non-Sentry logger provider is decorated: exceptions keep their original type name and stack,
with messages, Data and inner messages removed. Sentry preserves real exception types for grouping;
its final `BeforeSend` clears request content, query, cookies, user, extra and exception values, retaining
only the client version/platform and content headers. Breadcrumbs, transactions, logs and metrics from
Sentry are disabled. Keep logger registration last (`ScrubLoggerProviders`); provider meta tests fail
if a new sink bypasses it.

- `Observability:ConsoleExporter=true` enables trace/metric console exporters **only in Development**
  (`appsettings.Development.json` enables this locally). Health requests are excluded from traces.
- `OTEL_EXPORTER_OTLP_ENDPOINT` enables OTLP traces, metrics and logs. Standard `_HEADERS` and
  `_PROTOCOL` environment settings apply (`http/protobuf` by default, `grpc` supported).
- `OTEL_SERVICE_NAME` defaults to `fitness-buddy-<role>`; resources include service version and environment.
- `Sentry__Dsn` enables error reporting; an empty DSN is off. Build-time document generation starts no exporters.
- Never enable HTTP logging, exception recording on spans or instrumentation `Enrich*` callbacks.

## Build and test

Use the root `Makefile` (it uses the pinned SDK in `~/.dotnet`, never a system `dotnet`):

```bash
make deps-dotnet    # restore packages (fails on high/critical vulnerabilities)
make check-dotnet   # formatting check + Release build with warnings as errors
make test-dotnet    # run all test projects
make contract-conformance  # build the Host, then diff its OpenAPI document with the contract
```

To call `dotnet` yourself, run it from `backend/` with the pinned SDK, e.g. `DOTNET_ROOT=~/.dotnet ~/.dotnet/dotnet build FitnessBuddy.slnx`. The SDK version and the test runner are chosen from `global.json` in the current directory. Building the Host also runs the build-time OpenAPI generator, which calls a bare `dotnet`, so put the pinned SDK first on PATH: `export PATH=~/.dotnet:$PATH DOTNET_ROOT=~/.dotnet`, then e.g. `dotnet run --project src/Host --urls http://localhost:5198` and `curl localhost:5198/v1/config`.

## OpenAPI conventions (contract conformance)

`contracts/openapi.yaml` is the source of truth (TD-023, `contracts/README.md`). The server is written by hand to match it, and CI proves it does:

1. Every Host build writes the server's OpenAPI document to `artifacts/openapi/server.json` (`Microsoft.Extensions.ApiDescription.Server`, options in `src/Host/FitnessBuddy.Host.csproj`). It costs about 0.4 s per Host build.
2. `make contract-conformance` rebuilds the Host (incremental) and runs `oasdiff changelog contracts/openapi.yaml artifacts/openapi/server.json --fail-on INFO`. Any API difference fails: paths, parameters, status codes, media types, fields, types, formats, patterns, required/nullable, `operationId`, tags. Descriptions, examples and component names don't count. It is part of `make check`.
3. `tests/Contract.Tests` call the real endpoints and check the JSON that actually goes on the wire (the document only describes it).

When conformance fails, the contract wins: fix the C#, or change the contract first (`contracts/openapi/`, then `make gen`) and then the C#.

**Build-time generation gotchas.**
- The generator runs plain `dotnet` from `PATH`. The Makefile puts `~/.dotnet` first. If you build by hand on the laptop (where `/usr/bin/dotnet` is .NET 8), do the same: `PATH=~/.dotnet:$PATH`.
- It is incremental on the assembly only (`obj/FitnessBuddy.Host.OpenApiFiles.cache`). After deleting `server.json` or changing the generator options, delete that cache file (`make contract-conformance` always does).

**Endpoints.**
- Name every operation with the contract's `operationId` (`.WithName("getConfig")`). The tag is the module's `Name`, set by its group (`IModule`, above). They become the Dart method and client class names.
- Return `TypedResults` so the success response is documented. Declare each domain error status the contract lists for the operation with `.ProducesProblem(status)` (`ProblemHttpResult` and `TypedResults.NotFound()` document no problem body on their own).
- Don't declare the client headers or the shared 400/426/429/500 responses per endpoint: the `/v1` group sets the metadata, and the transformers below document it.

**DTOs (S02 D4 + A3).**
- Request and response DTOs are hand-written **positional records** (`sealed`, `internal` where the build allows). The generator then lists every property in `required`, and nullable ones as `[T, null]`, which is the contract's rule.
- Absent values are sent as JSON `null`, never as a missing key. So **no `JsonIgnoreCondition.WhenWritingNull`** (or `WhenWritingDefault`), neither on a property nor in `JsonSerializerOptions`.
- The only optional members: a request property added to a published version (a non-positional `init` property with a default), and the optional `ProblemDetails` members.
- JSON options (`Roles/ApiRole.cs`): `NumberHandling = Strict` (the web default would document every number as `number | string`), enums as camelCase strings, `RespectRequiredConstructorParameters` and `RespectNullableAnnotations` (a missing member, or `null` for a non-nullable one, is an unreadable body).
- Constraints the contract states (`pattern`, `minimum`, …) are mirrored with data annotations so the document carries them, e.g. `[property: RegularExpression(AppVersion.Pattern)]` on `ClientConfig.MinimumAppVersion`.

**Transformers** (`src/Host/OpenApi/`, registered in `AddOpenApi("v1", …)`):
- `ProblemDetailsSchemaTransformer`: the framework's `ProblemDetails` schema is all-nullable and all-optional. This rewrites it into the contract's RFC 9457 shape: `type` (uri-reference), `title`, `status` (int32) required and non-null, `detail`, `instance` and `traceId` optional. On `HttpValidationProblemDetails` (the contract's `ValidationProblemDetails`) it also makes `errors` required and non-null.
- `ClientHeadersOperationTransformer`: the client headers, on every operation with `ClientHeadersMetadata`.
- `ResponseHeadersOperationTransformer`: `X-Request-Id` on every response; `Retry-After`, `RateLimit` and `RateLimit-Policy` on 429.
- **Deferred: enum schema transformer.** .NET 10 emits string enums as `enum: [...]` *without* `type: string`. The first step that adds an enum to the API adds this transformer (proven in the S02 research) and a conformance check of the enum:

  ```csharp
  // .NET 10 emits string enums as `enum: [...]` without `type: string`.
  options.AddSchemaTransformer((schema, context, ct) =>
  {
      var type = Nullable.GetUnderlyingType(context.JsonTypeInfo.Type) ?? context.JsonTypeInfo.Type;
      if (type.IsEnum && schema.Enum is { Count: > 0 })
      {
          schema.Type = JsonSchemaType.String;
      }

      return Task.CompletedTask;
  });
  ```

**Startup must stay side-effect free (rule for S04 on).** To write the document, the build runs the Host's `Program.cs` inside the `GetDocument.Insider` tool, with no database, secrets or network. Any startup work with side effects (database migrations, connecting to Postgres, starting jobs, failing on missing secrets, options `ValidateOnStart`) must be skipped there, with `PlatformSetup.IsBuildTimeDocument`:

```csharp
if (!PlatformSetup.IsBuildTimeDocument)
{
    options.ValidateOnStart(); // migrations, eager connections, ...
}
```

The live document (`/openapi/v1.json`) is mapped only in Development. The build-time document doesn't need it.

## Tests run on Microsoft.Testing.Platform

Test projects use xUnit v3 on Microsoft.Testing.Platform (MTP), not VSTest:

- A test project is an executable (`<OutputType>Exe</OutputType>`) that references `xunit.v3`. Don't add `Microsoft.NET.Test.Sdk` or `xunit.runner.visualstudio`.
- `dotnet test` uses the MTP syntax: `dotnet test --solution FitnessBuddy.slnx`, or `--project <csproj>`. Test options go straight on the command line, e.g. `--filter-method "*BuildingBlocks*"` or `--report-xunit-trx`. List them with `dotnet test --project <csproj> --help`. MSBuild switches like `-m:4` are passed on to the test app and fail it.
- You can also run a built test project directly (`tests/Architecture.Tests/bin/Release/net10.0/FitnessBuddy.Architecture.Tests`). It then uses xUnit's own option syntax (`-method`, `-trait`, see `--help`).
- Tag tests with the spec IDs they cover: `[Trait("Req", "AC-012")]` (see `technical-planning/10-engineering-practices.md` §5). A test of a rule without a spec ID gets `[Trait("Rule", "<doc>.<section>-<slug>")]` (e.g. `"04.4.2-errors"`) and a one-line class comment.

## Container

`backend/Dockerfile` uses digest-pinned SDK 10.0.402 and ASP.NET 10.0.13 noble-chiseled-extra stages.
Bump the SDK image together with `global.json` (the image smoke test checks this). ICU and tzdata
are present; there is no shell or HEALTHCHECK. The executable runs as UID 1654 on port 8080;
proxy health is `/health/ready`. `api` is the default command; `worker` and `migrate` use the same image.

From the root: `make up` / `make down` use `infra/compose/docker-compose.yml`, with loopback port 5198,
a read-only filesystem, `/tmp` tmpfs, no capabilities and no privilege escalation. Development and the
console exporters are local-only. `make image-smoke` builds and checks the production artifact and
prints its size (engine bytes and a gzipped image archive, not a registry transfer size).

## Low RAM

The laptop has about 3 GB free, so the Makefile builds with `-m:4`, turns off MSBuild node reuse and runs at most 2 test projects at once. The C# compiler server still stays in memory for a few minutes after a build. After a long session, free that memory with:

```bash
DOTNET_ROOT=~/.dotnet ~/.dotnet/dotnet build-server shutdown
```

## Private phone server (B03)

`make serve-phone-prepare` builds an immutable backend image from `origin/main`, with its own
credentials, compose project, volume and external snapshots. `make serve-phone` is gated on
confirmed A55-only Tailscale policy, HTTPS and encrypted database/backup storage (or the explicit owner-approved private-laptop exception). The loopback
API is 5199; dev remains 5198. Nightly private dumps and isolated restore checks use a dedicated
read-only backup role. See [the runbook](../docs/runbooks/laptop-test-server.md); a connected
Tailscale client alone does not mean the server is activated. `make phone-server-smoke` proves
synthetic isolation/backup boundaries in CI without touching the owner's stack or tailnet.

## Document sync (B05)

Registered users use bearer-authenticated push/pull/history; guests receive403. Every production
transaction takes the shared user lock, checks current Identity user/session state and uses forced
RLS. The experimental key/environment bypass has been removed. The HTTP contract and embedded
closed payload registry are the authority; `make gen-sync-schemas` / `make check-sync-schemas`
export/check it without network or a runtime file dependency.

Unbound/mismatched pushes never write or acknowledge an immutable version. Discover the dataset
at pull cursor0, bind writes, merge a changed dataset before re-upload, and never advance a pull
cursor from a push acknowledgement. Sequences are commit ordered per user. History expires after
30days; payload compaction retains deletion fences and minimal immutable-version receipts until
account erasure. Background cleanup is bounded and transactional. Recurring user-owned Ops schedules are registered
with sync and seeded for legacy data by the migrator; no application-wide cleanup enumeration or
elevated UserData function is granted.

`make sync-spike` is the retained target name for the **production-authenticated** synthetic harness:
50 real randomized seeds, connection/replay/crash faults,10,000-row batched push/fresh pull and bounded
server duration measurements. It uses isolated pinned Postgres and ephemeral local email/keys, with
no owner data or external provider calls. Fake seeds/reset recovery run in `make test-dart`.

See [sync operations](../docs/runbooks/sync.md) and `05` §5.5. A34 owns real Flutter/SQLite sync.

## Buddy interpretation spike (B02)

The dark Buddy module has no HTTP endpoints; `backend/tools/BuddySpike` is a local JSONL CLI, with no database or user identity. `make eval` builds it and runs three synthetic provider fixtures through the real OpenAI SDK and Dart graders. CI never loads an API key. `make eval-live` explicitly makes at most three small `gpt-6-luna` calls, using the owner's external 0600 key file; no retries or fallback. `make eval-schema` refreshes the internal C# record schema snapshot. See [Buddy](src/Modules/Buddy/README.md) and [harness](../tools/buddy_eval/README.md). Public contract, production auth/routing/usage and catalog resolution are B08.

## Identity (B04)

Identity is off by default. Explicit private laptop configuration enables guest/Google/email sign-in,
opaque rotating refresh tokens, live-session revocation, guest linking and public ES256 JWKS.
Only the named pre-auth database capabilities receive app-role execution; forced RLS and denied
app table grants protect credential tables (TD-077). The Host supplies principal-backed ICurrentUser,
`any-user` / `registered-user` policies and content-free auth problems.

See [identity operations](../docs/runbooks/identity.md) for private secret mounts, explicit migration-role
signing-key provisioning/rotation/rewrap, local email opt-in, and recovery. Normal API/worker startup
never generates keys. Google token checks use offline signed fixtures in CI; never run live AI evals
as part of identity testing. App integration is A20/A33; production sender/configuration is B14.

## Account deletion (B06)

`DELETE /v1/me` accepts only the validated guest/registered principal and no body. A204 follows
one durable transaction containing every installed module's database-only outbox eraser and final
Ops purge. Participant failure rolls back session revocation and data removal; old credentials
return401 after a committed deletion. Shared installation secrets/global data and another account
survive. No completed user mapping or generic response-cache record is retained.

The coordinator requires all declared erasers and matching protected recovery state before effects.
Its global generation is durably reserved outside the dump before erasure and committed in the DB
with it. Missing/corrupt/mismatched state fails closed; an ambiguous commit never restores an older
marker. Lifecycle locks also fence Identity mutation, sync, generic replay and worker scheduling/
claims. See [account deletion operations](../docs/runbooks/account-deletion.md) and the B06 card.

B06 recovery initialization is explicit: supply the existing private `Recovery:Directory` and use
`migrate --Recovery:Initialize=true` only for a never-initialized database (or matching repeat).
API/worker/readiness require file/DB generation equality; every installed module's HTTP routes
except config hold a shared recovery lease before authentication. DELETE releases its preliminary
lease before its own exclusive transaction. Worker/scheduler effects check the same fence before
user/row locks. The Host uses a separate bounded gate pool to avoid exhausting business connections.
