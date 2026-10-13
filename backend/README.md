# backend/

The Fitness Buddy API: an ASP.NET Core (.NET 10) modular monolith. Architecture, modules and rules are in `technical-planning/04-backend.md`. Right now it's the skeleton (S01) plus the contract pipeline (S02): one endpoint, `GET /v1/config`, and a build-time OpenAPI document that CI checks against `contracts/openapi.yaml`.

## Layout

| Path | What it is |
|---|---|
| `FitnessBuddy.slnx` | The solution (XML `.slnx` format) |
| `global.json` | Pins the .NET SDK (10.0.401, latest patch) and selects Microsoft.Testing.Platform for `dotnet test` |
| `Directory.Build.props` | Settings for every project: `net10.0`, nullable, analyzers (`latest-recommended`) and code style in the build, warnings as errors, NuGet audit |
| `Directory.Packages.props` | Central package management: every package version lives here, with transitive pinning |
| `nuget.config` | nuget.org is the only package source (source mapping `*` → nuget.org) |
| `src/Host/` | Composition root (`Microsoft.NET.Sdk.Web`). Later it runs as `api`, `worker` or `migrate` |
| `src/Host/OpenApi/` | OpenAPI transformers that make the generated document match the contract's conventions (see below) |
| `src/Host/Config/` | `GET /v1/config` (temporary, see below) |
| `src/BuildingBlocks/` | The lowest shared layer (results, outbox, jobs, clock, ids). Must never depend on Host or a module |
| `src/Modules/<Module>/` | *(from S04)* one project per module, with Api/Application/Domain/Infrastructure folders |
| `tests/Architecture.Tests/` | ArchUnitNET rules that keep the layers and module boundaries honest |
| `tests/Contract.Tests/` | HTTP tests (`WebApplicationFactory<Program>`) that check the runtime JSON against the contract |
| `artifacts/openapi/server.json` | *(generated, gitignored)* the server's OpenAPI document, written by every Host build |

Code style: `.editorconfig` at the repo root (C# section). Style and analyzer warnings fail the build.

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
- Name every operation with the contract's `operationId` (`.WithName("getConfig")`) and tag it with its module's tag (`.WithTags("Account")`). They become the Dart method and client class names.
- Return `TypedResults` so the success response is documented. Declare every error status the contract lists with `.ProducesProblem(status)` (`ProblemHttpResult` and `TypedResults.NotFound()` document no problem body on their own).
- `/v1/` operations get the client headers (`X-App-Version`, `X-Platform`, `X-Device-Id`) from `ClientHeadersOperationTransformer`; don't declare them per endpoint. S03 adds the middleware that enforces them, and both should then come from one definition (S02 A8).

**DTOs (S02 D4 + A3).**
- Request and response DTOs are hand-written **positional records** (`sealed`, `internal` where the build allows). The generator then lists every property in `required`, and nullable ones as `[T, null]`, which is the contract's rule.
- Absent values are sent as JSON `null`, never as a missing key. So **no `JsonIgnoreCondition.WhenWritingNull`** (or `WhenWritingDefault`), neither on a property nor in `JsonSerializerOptions`.
- The only optional members: a request property added to a published version (a non-positional `init` property with a default), and the optional `ProblemDetails` members.
- JSON options (`Program.cs`): `NumberHandling = Strict` (the web default would document every number as `number | string`), enums as camelCase strings.
- Constraints the contract states (`pattern`, `minimum`, …) are mirrored with data annotations so the document carries them, e.g. `[property: RegularExpression(...)]` on `ClientConfig.MinimumAppVersion`.

**Transformers** (`src/Host/OpenApi/`, registered in `AddOpenApi("v1", …)`):
- `ProblemDetailsSchemaTransformer`: the framework's `ProblemDetails` schema is all-nullable and all-optional. This rewrites it into the contract's RFC 9457 shape: `type` (uri-reference), `title`, `status` (int32) required and non-null, `detail` and `instance` optional.
- `ClientHeadersOperationTransformer`: the client headers above.
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

**Startup must stay side-effect free (rule for S04 on).** To write the document, the build runs the Host's `Program.cs` inside the `GetDocument.Insider` tool, with no database, secrets or network. Any startup work with side effects (database migrations, connecting to Postgres, starting jobs, failing on missing secrets, options `ValidateOnStart`) must be skipped there:

```csharp
var isBuildTimeDocument = Assembly.GetEntryAssembly()?.GetName().Name == "GetDocument.Insider";
if (!isBuildTimeDocument)
{
    // migrations, eager connections, ...
}
```

The live document (`/openapi/v1.json`) is mapped only in Development. The build-time document doesn't need it.

**`GET /v1/config` lives in the Host for now.** That is a temporary exception to `04` §3 (endpoints belong to modules): it moves into the Account module when that module is created, with the same `operationId` and tag, and conformance proves the move changed nothing (S02 A6). Its values are hard-coded (`ClientConfig.Defaults`) until then.

## Tests run on Microsoft.Testing.Platform

Test projects use xUnit v3 on Microsoft.Testing.Platform (MTP), not VSTest:

- A test project is an executable (`<OutputType>Exe</OutputType>`) that references `xunit.v3`. Don't add `Microsoft.NET.Test.Sdk` or `xunit.runner.visualstudio`.
- `dotnet test` uses the MTP syntax: `dotnet test --solution FitnessBuddy.slnx`, or `--project <csproj>`. Test options go straight on the command line, e.g. `--filter-method "*BuildingBlocks*"` or `--report-xunit-trx`. List them with `dotnet test --project <csproj> --help`. MSBuild switches like `-m:4` are passed on to the test app and fail it.
- You can also run a built test project directly (`tests/Architecture.Tests/bin/Release/net10.0/FitnessBuddy.Architecture.Tests`). It then uses xUnit's own option syntax (`-method`, `-trait`, see `--help`).
- Tag tests with the spec IDs they cover: `[Trait("Req", "AC-012")]` (see `technical-planning/10-engineering-practices.md` §5).

## Low RAM

The laptop has about 3 GB free, so the Makefile builds with `-m:4`, turns off MSBuild node reuse and runs at most 2 test projects at once. The C# compiler server still stays in memory for a few minutes after a build. After a long session, free that memory with:

```bash
DOTNET_ROOT=~/.dotnet ~/.dotnet/dotnet build-server shutdown
```
