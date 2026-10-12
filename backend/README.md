# backend/

The Fitness Buddy API: an ASP.NET Core (.NET 10) modular monolith. Architecture, modules and rules are in `technical-planning/04-backend.md`. Right now (S01) it's only the skeleton: an empty web host, the shared building blocks project and one architecture test.

## Layout

| Path | What it is |
|---|---|
| `FitnessBuddy.slnx` | The solution (XML `.slnx` format) |
| `global.json` | Pins the .NET SDK (10.0.401, latest patch) and selects Microsoft.Testing.Platform for `dotnet test` |
| `Directory.Build.props` | Settings for every project: `net10.0`, nullable, analyzers (`latest-recommended`) and code style in the build, warnings as errors, NuGet audit |
| `Directory.Packages.props` | Central package management: every package version lives here, with transitive pinning |
| `nuget.config` | nuget.org is the only package source (source mapping `*` → nuget.org) |
| `src/Host/` | Composition root (`Microsoft.NET.Sdk.Web`). Later it runs as `api`, `worker` or `migrate` |
| `src/BuildingBlocks/` | The lowest shared layer (results, outbox, jobs, clock, ids). Must never depend on Host or a module |
| `src/Modules/<Module>/` | *(from S04)* one project per module, with Api/Application/Domain/Infrastructure folders |
| `tests/Architecture.Tests/` | ArchUnitNET rules that keep the layers and module boundaries honest |

Code style: `.editorconfig` at the repo root (C# section). Style and analyzer warnings fail the build.

## Build and test

Use the root `Makefile` (it uses the pinned SDK in `~/.dotnet`, never a system `dotnet`):

```bash
make deps-dotnet    # restore packages (fails on high/critical vulnerabilities)
make check-dotnet   # formatting check + Release build with warnings as errors
make test-dotnet    # run all test projects
```

To call `dotnet` yourself, run it from `backend/` with the pinned SDK, e.g. `DOTNET_ROOT=~/.dotnet ~/.dotnet/dotnet build FitnessBuddy.slnx`. The SDK version and the test runner are chosen from `global.json` in the current directory.

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
