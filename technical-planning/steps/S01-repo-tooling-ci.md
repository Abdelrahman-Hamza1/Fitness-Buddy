# S01 — Repo, tooling & CI foundation

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | — | M | ✅ Done |

**Goal.** A monorepo where both stacks (Dart and .NET) build, lint and test with one command, locally and in CI, plus the traceability tool that tracks progress against the spec. Every later step builds on this.

**Spec:** AT-001 (traceability tool) · **Decisions:** TD-015, TD-018, TD-021

## Scope
- Rename `master` → `main` (TQ-15). Push to the new private GitHub repo. Protect `main` (PRs only, required checks).
- Directory skeleton per `10` §1, with a short README in each top-level folder.
- **Dart:** workspace root `pubspec.yaml` (pub workspaces), `packages/fb_domain` and `packages/fb_text` as empty pure-Dart packages with one passing test each, `very_good_analysis`, melos for scripts if useful.
- **.NET:** `backend/FitnessBuddy.sln`, `global.json` (pin the .NET 10 SDK), `Directory.Build.props` (net10.0, nullable, analyzers `latest-recommended`, warnings as errors, deterministic builds), `Directory.Packages.props` (central package management), `src/Host` (empty web app), `src/BuildingBlocks`, `tests/Architecture.Tests` with one ArchUnitNET rule.
- Root **Makefile**: `setup`, `check`, `test`, `test-dart`, `test-dotnet`, `trace` (later steps add `gen`, `up`, `eval`, `catalog`).
- `.editorconfig`, `.gitattributes`, `.gitignore` for both stacks. A PR template with the checklist from `10` §6. Conventional Commits documented.
- CI: `ci-dart` and `ci-dotnet` workflows with caching. Renovate or Dependabot config for pub, NuGet, Actions and Docker.
- **`tools/trace` v0** (Dart CLI): parse `spec/*.md` for requirement IDs + release tags (including table-style IDs such as NT-001 and UX-001), scan Dart and C# test trees for tags (`10` §5), and write a Markdown report (per release: covered / missing).
- Root `README.md`: prerequisites, setup in under 10 minutes.

## Out of scope
- The Flutter app (S06), the contract (S02), Docker/compose (S03/S04).

## Fixed by the plan
- Monorepo layout and tool choices in `10` §1–3 and `02` §6.
- The test tagging conventions in `10` §5.

## Decide in the low-level plan
- Renovate vs Dependabot (default: Renovate, with grouped updates).
- Whether melos adds value on top of pub workspaces for our scripts.
- Exact SDK versions to pin (latest stable Flutter/Dart, .NET 10 SDK patch).

## Exit criteria
- [x] A fresh clone on Linux: `make setup && make check && make test` passes.
- [x] Every push and PR runs both stacks, and `main` accepts only commits on which the single gate check `ci` passed (reworded per D7/A1, TD-039).
- [x] A deliberate lint violation or warning in either stack fails CI.
- [x] `make trace` prints the R1 IDs from the spec (319 after A5) with all reported as "not covered".
- [x] The repo is on GitHub (public per TD-042), `main` is the default branch, and `master` is gone.

## Read first
`10-engineering-practices.md` §1–3, §5–7 · `02-tech-stack.md` §6

## Owner involvement
Create the private GitHub repository and give the session push access (or share the remote URL to add).

---

## Low-level plan
_Written in Phase B (2026-10-11) by the step-planner, using the orchestrator's research decisions R1–R13._

### 1. Summary
After S01 the repo has a pinned, user-local toolchain (Flutter 3.47.7 / Dart 3.13.5 and .NET SDK 10.0.401) that `make setup` installs without sudo. It has a Dart pub workspace (`fb_domain`, `fb_text`, `tools/trace`), a .NET 10 solution skeleton (Host, BuildingBlocks, Architecture.Tests with one ArchUnitNET rule on xUnit v3/MTP), and one root `Makefile` used the same way locally and in CI. It also has two GitHub Actions workflows (`ci-dart`, `ci-dotnet`) that always report a status, Dependabot, repo hygiene files, and `tools/trace` v0, which prints the 308 R1 requirement IDs as "missing". `main` is protected by **required status checks**. Merges stay as owner-free squash pushes (TD-036), so the protection gates the pushed commit, not a PR (see D7).

### 2. Decisions

| # | Decision | Reason / source |
|---|---|---|
| D1 | **Flutter 3.47.7 (Dart 3.13.5)**, pinned in root `.fvmrc` `{"flutter":"3.47.7"}`. `tools/scripts/setup-flutter.sh` installs the official archive into `~/development/flutter-<ver>`, sha256-checked against `releases_linux.json`, idempotently. No FVM, no git clone. Analytics are disabled (`flutter --disable-analytics`, `dart --disable-analytics`) | Orchestrator R1. One pin file is read by the script, the Makefile and `subosito/flutter-action` (`flutter-version-file` accepts `.fvmrc`, verified in the action README) |
| D2 | **.NET SDK 10.0.401** pinned in **`backend/global.json`** (`rollForward: latestPatch`, `allowPrerelease: false`, `test.runner: Microsoft.Testing.Platform`), installed by `tools/scripts/setup-dotnet.sh` (tarball URL + sha512 from the official `releases.json`, verified before extraction; `dotnet-install.sh` dropped after review). **Location = `backend/`**: all .NET config (`global.json`, `Directory.*.props`, `nuget.config`) lives together and doesn't leak into the rest of the monorepo. The Makefile always runs `dotnet` with `cd backend`, because SDK and test-runner resolution follow the *working directory*. CI: `setup-dotnet` with `global-json-file: backend/global.json` | Orchestrator R2 |
| D3 | **Absolute toolchain paths in the Makefile**: `FLUTTER_ROOT ?= $(HOME)/development/flutter-$(FLUTTER_VERSION)`, `DART`/`FLUTTER` from it, `DOTNET_ROOT ?= $(HOME)/.dotnet` (exported), `DOTNET := $(DOTNET_ROOT)/dotnet`. CI overrides them on the command line (`make DOTNET=dotnet FLUTTER=flutter DART=dart …`), which doesn't depend on which env vars the setup actions export. Telemetry opt-out is exported (`DOTNET_CLI_TELEMETRY_OPTOUT=1`, `DOTNET_NOLOGO=1`). The README documents an optional PATH prepend | Orchestrator R2. The laptop's system .NET 8 and the old `~/.dotnet/tools/dotnet-ef` are never picked up by accident |
| D4 | **Renovate vs Dependabot → Dependabot** (card default was Renovate). Ecosystems: `pub` (`/`), `nuget` (`/backend`), `github-actions` (`/`), `dotnet-sdk` (`/backend`), monthly per A12 (was weekly), minor+patch grouped per ecosystem, majors individually, `commit-message.prefix: chore(deps)`. **`docker` is deferred to S03**: the stanza is left commented in the file, because Dependabot errors on a directory with no Dockerfile. Backlog item | Orchestrator R6. Built into GitHub: no third-party app with write access to the repo (Renovate needs the Mend app), so it means fewer vendors. **TD candidate** |
| D5 | **melos → skip.** The Makefile plus `tools/scripts/dart-test-all.sh` loops over `dart pub workspace list` and runs `flutter test` for packages that depend on the Flutter SDK, and `dart test` for the rest. Revisit at ~6 packages | Orchestrator R5. Pub workspaces already give one resolution and one lockfile, so melos would only be a script runner here. Changes `02` §6 ("melos inside the Dart workspace"). **TD candidate** |
| D6 | **No NuGet lock files yet** (Dependabot + CPM lock-file bugs). Reproducibility comes from CPM exact versions + `CentralPackageTransitivePinningEnabled` + `nuget.config` (`<clear/>`, nuget.org only, package source mapping `*` → nuget.org). Backlog: revisit lock files at S04 | Orchestrator R3 |
| D7 | **Protect `main` with a branch ruleset: required status checks `ci-dart` + `ci-dotnet`, block force pushes, restrict deletions, empty bypass list, *no* "require a pull request".** GitHub's rule is that a commit can reach `main` only if the required checks already passed on that exact SHA. So the merge flow (TD-036) becomes: squash on a local `merge/Sxx` branch → `git push -u origin merge/Sxx` → CI runs on that SHA → `tools/scripts/ci-status.sh <sha>` shows it green → `git push origin merge/Sxx:main` (fast-forward, same SHA) → delete `merge/Sxx` and the step branch. The board ✅ and the Outcome go into the squash commit (a separate docs commit pushed straight to `main` would now be rejected). The workflows still trigger on `pull_request`, so Dependabot PRs and any future PRs are gated too | The card says "PRs only", but `13` §3.E / TD-036 already say "no `gh`, no PRs". A PR requirement would block the orchestrator's merge. GitHub docs: required checks let a commit be "pushed to another branch and then merged or pushed directly to the protected branch" ([about protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)). **⚠️ OWNER** (process change, owner clicks, settings.json allow-rule). **TD candidate** (amends `10` §6 "merged by PR") |
| D8 | **Repo visibility stays the owner's call (currently public).** Facts for the decision: on GitHub Free, rulesets and branch protection exist **only for public repos**. Private needs GitHub Pro (~$4/mo) ([available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)). A private repo also loses anonymous CI verification from this machine and has an Actions minutes cap. **Rec:** stay public through P0–P2 (no secrets in the repo, enforced by `.gitignore` + free secret-scanning push protection), and revisit before R2 | **⚠️ OWNER** (cost if private + Pro). Exit criterion 5 reads "on GitHub" until decided |
| D9 | **NuGetAudit under warnings-as-errors:** `NuGetAuditMode=all`. `WarningsNotAsErrors=NU1901;NU1902` keeps low/moderate visible as warnings, and **NU1903/NU1904 (high/critical) stay errors**. `ci-dotnet` also runs **weekly on a schedule**, so new advisories surface without a commit. A specific advisory can be suppressed only with `<NuGetAuditSuppress>` + a backlog entry. This covers the "vulnerable-package check" in `10` §7 without a separate step | High/critical must stop the line. Low/moderate failing random unrelated builds would make CI non-deterministic. **⚠️ OWNER** (light: accepting low/moderate as non-blocking is a security trade-off). **TD candidate** |
| D10 | **Solution format `.slnx`**: `backend/FitnessBuddy.slnx` (card/`10` §1 say `.sln`) | Orchestrator R3. The .NET 10 default, merge-friendly XML |
| D11 | **Tests:** xunit.v3 **4.0.2** on MTP v2 (MTP mode via `global.json`), `TngTech.ArchUnitNET` + `TngTech.ArchUnitNET.xUnitV3` **0.13.4**, `Microsoft.Testing.Extensions.CodeCoverage` (referenced so `dotnet test --coverage` works; no gate in S01). No `Microsoft.NET.Test.Sdk` / `xunit.runner.visualstudio` | Orchestrator R4 |
| D12 | **`check-dotnet` = `dotnet format whitespace --verify-no-changes` + `dotnet build -warnaserror`** (style rules are enforced in the build via `EnforceCodeStyleInBuild` + `.editorconfig` severities). No full `dotnet format` (style/analyzers) pass | Avoids a second compile: about half the time and RAM on the laptop, with the same rules |
| D13 | **Required checks never get stuck "skipped"**: each workflow runs on every push/PR (no trigger-level `paths:`). A `changes` job runs `tools/scripts/ci-changes.sh <relevance-regex>` and fails *open* (runs everything on any doubt, and on `main`, schedule and dispatch). Heavy jobs are `if: run == 'true'`, and a final always-run gate job **named exactly `ci-dart` / `ci-dotnet`** passes on success or skip and fails on failure or cancel. Only the gate jobs are required | Orchestrator R8 |
| D14 | **CI action versions:** `actions/checkout` v7, `subosito/flutter-action` v2 (`cache: true`, `pub-cache-key: flutter-pub-:os:-:version:-${{ hashFiles('**/pubspec.lock') }}`), `actions/setup-dotnet` v6. **NuGet cache via `actions/cache` v-latest** on `~/.nuget/packages`, keyed on `hashFiles('backend/Directory.Packages.props','backend/**/*.csproj','backend/global.json')`, *not* setup-dotnet's `cache:`, which throws without `packages.lock.json` (setup-dotnet README). All actions are pinned by commit SHA with a `# vX.Y.Z` comment, resolved with `git ls-remote --tags`. `runs-on: ubuntu-24.04`, `permissions: contents: read`, concurrency cancels superseded runs except on `main` | Orchestrator R8, adjusted for the lock-file constraint (D6) |
| D15 | **Dart workspace:** root `pubspec.yaml` (`name: fitness_buddy_workspace`, `publish_to: none`, `environment.sdk: ^3.13.0`, `workspace:` list). Members have `resolution: workspace`. Root `analysis_options.yaml` includes `package:very_good_analysis/analysis_options.yaml` (**11.0.0**, dev-dependency of every member). Members' `analysis_options.yaml` include the root one. The root `pubspec.lock` is committed. `flutter pub get` runs at the root | Orchestrator R7 |
| D16 | **`fb_domain`/`fb_text` "one passing test" = the dependency-allowlist test** from `10` §3 (no Flutter SDK, deps ⊆ an allowlist, empty today). Libraries hold only a barrel with a library doc comment, no placeholder code | Gives the required test real value (TD-018), and adds no speculative code |
| D17 | **Shell scripts live in `tools/scripts/`** (not a second `tool/` folder). `tools/` holds Dart tools (workspace members) and plain scripts | One place for tooling. `10` §1 already has `tools/` |
| D18 | **Skeleton = only folders with content now** (`packages/`, `tools/`, `backend/`, `.github/`). `contracts/`, `apps/`, `data/`, `infra/`, `docs/` are created by the steps that fill them. The root README shows the full map from `10` §1 | No empty folders. Each top-level folder created gets a short README |
| D19 | **Trace release rules:** bullet tag `` `[R1]` `` etc. A table row whose first cell is an ID takes its release from a column named "Release" if the table has one (NT-001…010). Otherwise it's **untagged**, unless listed in a small in-code override map with a reason. The only override today is **UX-001…007 → R1**, because AT-004 makes the speed targets R1 acceptance criteria. Measured on the current spec: 291 bullet R1 + 10 NT + 7 UX = **308 R1**, 27 R2, 10 R3, 2 Later, 55 untagged (C, AT, OF, SC, PR, NG, AQ), 402 IDs, no duplicates | Matches the expected ≈300/308. Doesn't guess: everything else without a tag is reported as untagged |
| D20 | **Owner-free CI verification**: `tools/scripts/ci-status.sh <sha>` polls `GET /repos/Abdelrahman-Hamza1/Fitness-Buddy/commits/<sha>/check-runs` anonymously (public repo, 60 req/h, so it polls every 30 s, max ~20 min). It prints each check-run name + conclusion + html_url and exits 0 only if `ci-dart` and `ci-dotnet` are `success`. Ruleset evidence: `GET …/rules/branches/main` (anonymous, already confirmed to return `[]` today) | No `gh` and no token needed (orchestrator brief) |

### 3. Design

**3.1 Files created (by WP)**
```
.editorconfig  .gitattributes  .gitignore  .fvmrc  Makefile  README.md          (WP1, README finished in WP6)
tools/README.md  tools/scripts/{setup-flutter.sh,setup-dotnet.sh}                (WP1)
pubspec.yaml  pubspec.lock  analysis_options.yaml                                (WP2)
packages/README.md
packages/fb_domain/{pubspec.yaml,analysis_options.yaml,README.md,lib/fb_domain.dart,test/dependencies_test.dart}
packages/fb_text/  (same shape)                                                  (WP2)
tools/scripts/dart-test-all.sh                                                   (WP2)
tools/trace/{pubspec.yaml,analysis_options.yaml,README.md,bin/trace.dart,
  lib/fb_trace.dart, lib/src/{requirement.dart,spec_parser.dart,release_overrides.dart,
  test_scanner.dart,report.dart,cli.dart}, test/{spec_parser_test,test_scanner_test,report_test,cli_test}.dart}   (WP3)
backend/{README.md,global.json,nuget.config,Directory.Build.props,Directory.Packages.props,FitnessBuddy.slnx}
backend/src/Host/{FitnessBuddy.Host.csproj,Program.cs}
backend/src/BuildingBlocks/{FitnessBuddy.BuildingBlocks.csproj,BuildingBlocksAssembly.cs}
backend/tests/Architecture.Tests/{FitnessBuddy.Architecture.Tests.csproj,LayerRulesTests.cs}            (WP1 global.json; rest WP4)
.github/workflows/{ci-dart.yml,ci-dotnet.yml}  .github/dependabot.yml  .github/pull_request_template.md
tools/scripts/{ci-changes.sh,ci-status.sh}                                       (WP5)
```

**3.2 Makefile** (`SHELL := bash`, `.SHELLFLAGS := -euo pipefail -c`, `.NOTPARALLEL:`, default goal `help`)

| Target | Does |
|---|---|
| `help` | Lists the targets (default) |
| `doctor` | Versions: git, make, python3, curl, xz, Flutter/Dart (pinned dir), `dotnet --version` (run in `backend/`), free disk in `$HOME`, free RAM. Warns if `~/.dotnet` is on PATH ahead of `/usr/lib/dotnet` with the old global `dotnet-ef` |
| `setup` = `toolchain deps` | `toolchain` = `toolchain-flutter toolchain-dotnet` (scripts, idempotent: they skip when the pinned version exists). `deps` = `deps-dart` (`$(FLUTTER) pub get` at root) + `deps-dotnet` (`cd backend && $(DOTNET) restore FitnessBuddy.slnx`) |
| `check` = `check-dart check-dotnet` | Dart: `$(DART) format --output=none --set-exit-if-changed .` then `$(DART) analyze --fatal-infos`. .NET: `cd backend && $(DOTNET) format whitespace FitnessBuddy.slnx --verify-no-changes && $(DOTNET) build FitnessBuddy.slnx -c Release --no-restore -m:4 -nodeReuse:false` |
| `test` = `test-dart test-dotnet` | Dart: `tools/scripts/dart-test-all.sh` (per member, sequentially, `-j 2`). .NET: `cd backend && $(DOTNET) test --solution FitnessBuddy.slnx -c Release --max-parallel-test-modules 2` |
| `trace` | `$(DART) run tools/trace/bin/trace.dart --root . --release $(RELEASE)` with `RELEASE ?= R1` (`RELEASE=all` for every release) |

Later steps add `gen`, `up`/`down`, `eval`, `catalog` (comment placeholder only).

**3.3 .NET skeleton** (respects `04`/TD-021/TD-022: Host = composition root, BuildingBlocks lowest layer)
- `Directory.Build.props`: `TargetFramework=net10.0`, `Nullable=enable`, `ImplicitUsings=enable`, `TreatWarningsAsErrors=true`, `AnalysisLevel=latest-recommended`, `EnforceCodeStyleInBuild=true`, `GenerateDocumentationFile=true` + `NoWarn CS1591` (needed so IDE0005 is reported in builds), `ContinuousIntegrationBuild=true` when `$(GITHUB_ACTIONS)=='true'`, `Deterministic=true`, NuGet audit settings per D9.
- `Directory.Packages.props`: `ManagePackageVersionsCentrally`, `CentralPackageTransitivePinningEnabled`, the four test packages (D11).
- `src/Host`: `Microsoft.NET.Sdk.Web`, `Program.cs` = builder → build → run, no endpoints (S03 adds them). `src/BuildingBlocks`: class library with one `public static class BuildingBlocksAssembly` marker (the arch test needs a non-empty type set, because ArchUnitNET fails rules on empty sets by default).
- `tests/Architecture.Tests`: `OutputType=Exe`, references Host + BuildingBlocks. One rule: `BuildingBlocks_does_not_depend_on_Host` (`Types().That().ResideInAssembly(BuildingBlocks).Should().NotDependOnAny(Types().That().ResideInAssembly(Host))`, checked through `ArchUnitNET.xUnitV3`).
- `.editorconfig` C# section: file-scoped namespaces, `using` outside namespace, `IDE0005`/`IDE0161`/`IDE0055` at `warning` (→ errors), sealed-by-default left to review for now.

**3.4 Dart workspace**: see D15/D16. `dart-test-all.sh` reads member paths from `dart pub workspace list` (`--json` if the installed Dart supports it, else the text output) and fails on the first red package.

**3.5 `tools/trace` v0 (package `fb_trace`, deps: `args`, `path`; dev: `test`, `very_good_analysis`)**
- `Requirement(id, release, file, line, title)`, `enum Release {r1, r2, r3, later, untagged}`.
- `SpecParser.parse(fileName, text)` reads `spec/*.md` top level only (not `research/`, `questions/`), skipping `README.md`, `decisions.md`, `glossary.md`. Rules: bullet `^\s*[-*]\s+\*\*([A-Z]{1,3}-\d+)\*\*` + optional `` `[R1|R2|R3|Later]` ``; table rows whose **first cell** (with `**` stripped) is an ID, with the header tracked per table block (reset on a non-`|` line); release from a header cell equal to "Release" (case-insensitive). `T01`-style test cases are ignored (no hyphen), and so are IDs in prose. Duplicate IDs → error listing both locations. A tag value it doesn't recognise → untagged + warning.
- `releaseOverrides` (const map, each entry with a reason comment). It applies only to untagged IDs. An override that targets a tagged or unknown ID → warning.
- `TestScanner` scans `.dart` files under any `test/` or `integration_test/` directory in `apps/`, `packages/`, `tools/`, and `.cs` files under `backend/tests/`. It skips `.dart_tool`, `build`, `bin`, `obj` and `tools/trace/test/fixtures`. Recognised: the leading run of IDs in the string literal right after `test(`, `testWidgets(`, `group(`, `patrolTest(`; `// covers: ID, ID`; C# `[Trait("Req", "ID")]`. IDs in the middle of a description are deliberately *not* counted. IDs in tests that aren't in the spec → "Unknown IDs" warning.
- `Report` builds deterministic Markdown (no timestamps): a summary table per release (total/covered/missing), then per selected release "Missing (n)" and "Covered (n)" tables (`ID · spec file:line · title ≤ 80 chars · covering test files`), then "Untagged (n)" when `--release all`, then "Warnings". Exit codes: 0 report written (any coverage), 2 spec errors (duplicates), 64 usage error. `--out <file>` writes to a file instead of stdout.
- Hermetic tests build temp trees in `Directory.systemTemp`. Any checked-in fixtures use the `.txt` extension and a fake `ZZ-` prefix, so they are never analysed or counted.

**3.6 CI**
- `ci-dart.yml`: `on: push (branches '**', branches-ignore 'dependabot/**'), pull_request, workflow_dispatch`. Jobs: `changes` (checkout `fetch-depth: 0`, `ci-changes.sh --self-test`, then `ci-changes.sh '^(packages/|apps/|tools/|spec/|pubspec\.(yaml|lock)$|analysis_options\.yaml$|\.fvmrc$|Makefile$|\.editorconfig$|\.github/workflows/ci-dart\.yml$)'`) → `dart` (flutter-action → `make deps-dart check-dart test-dart trace` with tool overrides; trace output appended to `$GITHUB_STEP_SUMMARY`) → gate job `ci-dart`.
- `ci-dotnet.yml`: same shape, plus `schedule: cron '0 4 * * 1'`. Relevance regex `'^(backend/|Makefile$|tools/scripts/|\.editorconfig$|\.github/workflows/ci-dotnet\.yml$)'`. setup-dotnet + actions/cache → `make deps-dotnet check-dotnet test-dotnet` → gate job `ci-dotnet`.
- `ci-changes.sh`: base = PR base SHA, or the push `before`. If `before` is all zeros or unreachable → `git merge-base origin/main HEAD`. On `main`, schedule, dispatch, or any error → `run=true`. Writes `run=` to `$GITHUB_OUTPUT` and prints the changed files. `--self-test` builds a temp git repo and asserts 4 cases (relevant change → true, irrelevant → false, new branch → merge-base, broken base → true).
- `pull_request_template.md`: the `10` §6 checklist (step + spec IDs, tests, migrations, contract + client, eval, screenshots, runbook, no new warnings, one-line justification for new dependencies) + a Conventional Commits reminder.

**3.7 Hygiene**: `.gitattributes` (`* text=auto eol=lf`, `*.sh eol=lf`, `*.{bat,cmd} eol=crlf`, binary images/fonts/jar/keystores, `pubspec.lock linguist-generated`). `.gitignore`: Dart/Flutter (`.dart_tool/`, `build/`, `.flutter-plugins*`, `pubspec_overrides.yaml`, `*.iml`), .NET (`bin/`, `obj/`, `TestResults/`, `*.trx`, `*.user`, `artifacts/`, `coverage*`), IDE/OS (`.idea/`, `.vscode/*` except `extensions.json`, `.DS_Store`), secrets (`.env*` except `.env.example`, `.kamal/secrets*`, `*.pem`, `*.key`, `*.jks`, `*.keystore`, `key.properties`, `appsettings.*.local.json`), `.claude/settings.local.json`. `git add --renormalize .` must produce no diff on the existing docs.

### 4. Work packages (sequential; the laptop has ~3 GB free RAM)

| WP | Specialist | Tasks | Done when |
|---|---|---|---|
| **WP1 Toolchain bootstrap + hygiene** | platform-engineer | `.fvmrc`, `backend/global.json`, `tools/scripts/setup-flutter.sh` (curl releases_linux.json → find `version==3.47.7 && channel==stable` with `python3 -I` → download into a fresh temp dir → `sha256sum -c` → extract → move to `~/development/flutter-3.47.7` → disable analytics), `setup-dotnet.sh`. Makefile skeleton (`help`, `doctor`, `toolchain*`, variables per D3). `.editorconfig` (base), `.gitattributes`, `.gitignore`, `tools/README.md`, README stub | On **this laptop**: `make toolchain && make doctor` shows Flutter 3.47.7 / Dart 3.13.5 / .NET 10.0.401. A second `make toolchain` is a no-op in < 10 s. `bash -n` on the scripts. `git add --renormalize .` → no diff |
| **WP2 Dart workspace** | flutter-engineer | Root `pubspec.yaml`, `analysis_options.yaml`, `fb_domain`, `fb_text` (D15, D16), `pubspec.lock`, `dart-test-all.sh`, Makefile `deps-dart`/`check-dart`/`test-dart`, `packages/README.md` + package READMEs | `make deps-dart check-dart test-dart` green. A temporary unformatted line or unused import in `fb_domain` makes `check-dart` fail (reverted, output pasted in the report) |
| **WP3 tools/trace v0** | flutter-engineer | §3.5, Makefile `trace`, `tools/trace/README.md` | Unit tests green (§5). `make trace` exits 0 and prints **R1: 308 total, 0 covered, 308 missing**, no errors. `make trace RELEASE=all` lists 55 untagged |
| **WP4 .NET skeleton** | dotnet-engineer | §3.3 files, `.editorconfig` C# section, Makefile `deps-dotnet`/`check-dotnet`/`test-dotnet`, `backend/README.md`. **First task (spike, ≤ 30 min):** confirm that xunit.v3 4.0.2 + ArchUnitNET.xUnitV3 0.13.4 restore under transitive pinning and that the rule runs under MTP | `make deps-dotnet check-dotnet test-dotnet` green, and the output shows **1 test passed** through MTP. A temporary unused variable / `IDE0005` in BuildingBlocks makes `check-dotnet` fail (reverted, output in the report). No `Microsoft.NET.Test.Sdk` in the restore graph |
| **WP5 CI, Dependabot, PR template** | platform-engineer | §3.6 files, `ci-status.sh` (D20), `dependabot.yml` (D4). SHAs resolved via `git ls-remote` | `actionlint` clean (via `docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint:<pinned>`). `ci-changes.sh --self-test` passes locally. After the orchestrator pushes the branch, `ci-status.sh <sha>` → `ci-dart` ✅ `ci-dotnet` ✅ |
| **WP6 Aggregate targets + README + fresh clone** | platform-engineer | `setup`/`deps`/`check`/`test` aggregates. Root README (prerequisites: Linux x64, git, curl, python3, make, xz-utils, ~6 GB disk; what `make setup` downloads and where; commands; RAM notes from R9; optional PATH; CI + merge flow from D7; Conventional Commits; traceability). Make sure every created top-level folder has its README | In a scratch clone: `time (make setup && make check && make test)` passes, with toolchain already present **< 10 min** (number recorded). `make help` lists every target |

**Orchestrator/owner steps (not engineer WPs), in order:**
- **O1** Push `step/S01-repo-tooling-ci` once WP5 is done and verify both checks with `ci-status.sh`.
- **O2** **Owner (⚠️)** creates the ruleset. The check names appear only after CI has run once:
  1. Repo → **Settings → Rules → Rulesets → New ruleset → New branch ruleset**.
  2. Name `main`, **Enforcement status: Active**, **Bypass list: leave empty**.
  3. **Target branches → Add target → Include default branch**.
  4. Tick **Restrict deletions** and **Block force pushes**.
  5. Tick **Require status checks to pass** → **Add checks** → type `ci-dart`, select it (source: GitHub Actions) → type `ci-dotnet`, select it. Leave "Require branches to be up to date" **unticked**.
  6. Leave **Require a pull request before merging** **unticked**.
  7. **Create**.

  Also: **Settings → Advanced Security** (or "Code security"): enable **Dependabot alerts**, **Dependabot security updates**, **Secret Protection → Push protection**. On a phone, use the browser in "Desktop site" mode, because the GitHub app can't edit rulesets.
- **O3** Proof branches `ci-proof/dart-lint` and `ci-proof/dotnet-warning` (one deliberate violation each, based on the step branch): push, `ci-status.sh` shows the matching gate **failure**, then delete both.
- **O4** Negative merge test: an empty commit on top of `origin/main` pushed straight to `main` must be **rejected** ("required status checks"). If it's accepted, protection is misconfigured, and the empty commit is harmless.
- **O5** Docs at close: `02` §6 (no melos, Dependabot), `10` §1 (`.slnx`, `tools/scripts/`), `10` §6 + `13` §3.E + `run-step` skill E5 + CLAUDE.md "Git" (merge flow D7), `10` §7 (workflows as built), TDs in `12`, `steps/README` §3 (S01 prerequisite done), backlog items (§7). Adding `git push -u origin merge/*` and `ci-proof/*` to `.claude/settings.json` needs the **owner's approval (⚠️)**.
- **O6** Merge S01 itself through the D7 flow. That is the first live demonstration.

### 5. Test list

| Test | Proves |
|---|---|
| `fb_domain: has only allow-listed dependencies (no Flutter, no I/O)` | `10` §3 purity rule, TD-018 |
| `fb_text: has only allow-listed dependencies (no Flutter, no I/O)` | same |
| `AT-001 parses bullet IDs with release tags` | AT-001 |
| `AT-001 bullet without a tag is untagged (C-1 style)` | AT-001 |
| `AT-001 table rows take release from a Release column (NT-001 style)` | AT-001, card "table-style IDs" |
| `AT-001 table rows without a Release column are untagged (UX-001 style)` | AT-001 |
| `AT-001 override maps UX-001 to R1; override on a tagged ID warns` | D19 |
| `AT-001 ignores IDs in prose, non-first cells and T01 cases` | no false positives |
| `AT-001 table header resets between tables` | parser robustness |
| `AT-001 duplicate ID is an error with both locations` | spec integrity |
| `AT-001 scans leading IDs in Dart test()/testWidgets()/group() names` | `10` §5 Dart convention |
| `AT-001 does not count an ID in the middle of a test name` | precision |
| `AT-001 scans // covers: lists in Dart and C#` | `10` §5 |
| `AT-001 scans C# [Trait("Req", "AC-012")]` | `10` §5 C# convention |
| `AT-001 skips .dart_tool, build, bin, obj and trace fixtures` | no self-coverage |
| `AT-001 reports unknown referenced IDs as warnings` | typo detection |
| `AT-001 report lists covered/missing per release, deterministic` | AT-001, exit criterion 4 |
| `AT-001 cli: --release R1 on a temp repo prints summary + missing table; exit 0` | exit criterion 4 |
| `AT-001 cli: duplicate IDs exit 2; bad flag exits 64` | CLI contract |
| `BuildingBlocks_does_not_depend_on_Host` (C#) | TD-018 architecture tests, ArchUnitNET on xUnit v3/MTP |
| `ci-changes.sh --self-test` (4 cases) | D13: required checks are never wrongly skipped |

### 6. Exit-criteria mapping

| Exit criterion | Demonstrated by |
|---|---|
| Fresh clone on Linux: `make setup && make check && make test` passes | WP6 scratch-clone run with timing. **Recommended stronger evidence (verifier):** run in `docker run ubuntu:24.04` (apt-get the README prerequisites, then `make setup check test`). That proves the prerequisite list on a truly fresh machine. Most of the ~15–20 min is downloads |
| A PR to `main` runs `ci-dart` + `ci-dotnet`, and both are required to merge | **Reworded per D7 (⚠️):** "every push and PR runs both, and `main` accepts only commits on which both passed". Evidence: `ci-status.sh` on the step and `merge/S01` SHAs; `GET …/rules/branches/main` showing `required_status_checks` with both contexts + `non_fast_forward` + `deletion`; O4 rejected push. The first Dependabot PR shows the `pull_request` trigger |
| A deliberate lint violation or warning in either stack fails CI | O3 proof branches (check-run conclusions = failure, URLs in the Outcome) + the local proofs in WP2/WP4 |
| `make trace` prints the R1 IDs (≈ 300), all "not covered" | WP3: output summary `R1 · 308 · 0 · 308`, pasted in the Outcome. Also in each `ci-dart` run summary |
| On GitHub (private), `main` default, `master` gone | `git ls-remote origin` (only `main` + step branches, no `master`) + `GET /repos/…` → `default_branch: main`. **Visibility per D8 (⚠️ owner)**: currently `public` |

### 7. Risks & unknowns

| Risk | Handling |
|---|---|
| xunit.v3 4.0.2 vs ArchUnitNET.xUnitV3 0.13.4 conflict (it may pin xunit.v3 3.x extensibility) under transitive pinning | WP4 spike first. Fallback: reference only `TngTech.ArchUnitNET` and assert with a 10-line `ArchRuleAssert.Check(rule)` helper on `HasNoViolations`/`Evaluate`. Note it in the Outcome |
| Laptop RAM (~3 GB free) | Sequential WPs and targets (`.NOTPARALLEL`), `-m:4 -nodeReuse:false`, `-j 2`, `--max-parallel-test-modules 2`. README tip: `dotnet build-server shutdown` after long sessions |
| `dart pub workspace list --json` might not exist | Script falls back to the text output, or to the root `workspace:` list |
| Dependabot `pub` may not handle pub workspaces / Flutter 3.47 constraints | Check after the first run (owner-visible Dependabot logs). Fallback: a scheduled `dart pub outdated` job, or Renovate later. Backlog item |
| No CI logs without auth (anonymous API gives conclusions + annotations only) | Reproduce failures locally with the same make targets. Optional later: a read-only fine-grained PAT (⚠️ owner, not needed now) |
| Ruleset needs the check names to have run within 7 days | O2 happens right after O1 |
| Dependabot PRs need merging without `gh` | Orchestrator fetches the `dependabot/*` branch at step start and merges it through the D7 flow. Note it in the `run-step` update (O5) |
| Card conflicts flagged, not changed silently | "PRs only" (D7), "private" (D8), `.sln` → `.slnx` (D10), Docker in Dependabot deferred (D4), melos vs `02` §6 (D5) |
| Flutter archive is ~1 GB, ~3 GB extracted | `doctor` shows free disk. README states sizes. "< 10 min" is measured without downloads, per the card |
| Old global `dotnet-ef` in `~/.dotnet/tools` breaks if the user puts `~/.dotnet` first on PATH | The Makefile doesn't use PATH. `doctor` warns. S04 adds dotnet-ef through a repo-local manifest (none needed in S01) |
| Out-of-scope items from `10` §7 (`fb_domain` coverage gate, codegen check, Testcontainers, nightly trace) | Backlog with targets: coverage gate → S08, codegen → S02/S06, Testcontainers → S04, nightly trace workflow + "implemented" column → backlog |

Backlog items to add at close: NuGet lock files (S04), Dependabot `docker` entry (S03), Flutter/.NET pin bump cadence (Dependabot covers the .NET SDK; Flutter is manual, quarterly), Dependabot pub workspace verification, nightly `trace` workflow, `fb_domain` coverage gate (S08).

### 8. Size check
**M, upper end: ~1.5 sessions.** WP1–WP4 are local and predictable. Most of the uncertainty is in WP5, where the CI iteration loop is slow because only push-and-poll is available, and in owner step O2. If the session runs long, split at the natural seam: **S01a**: toolchain, both stacks, Makefile, trace (WP1–WP4, WP6 locally green). **S01b**: CI, Dependabot, protection, merge flow (WP5, O1–O6). No split is proposed up front.

### 9. Amendments after architect review (2026-10-11, orchestrator-applied, these override the sections above)

| # | Change | Overrides |
|---|---|---|
| A1 | **One workflow, one required check.** A single `.github/workflows/ci.yml` with jobs `dart` and `dotnet` and an always-run gate job **named `ci`**, which `needs:` every other job and **fails if any `needs.*.result` is `failure` or `cancelled`** (`skipped` passes only for intentionally skipped jobs). The ruleset requires only `ci`. The weekly `schedule` (Mon 04:00 UTC) moves into `ci.yml`. Later gates (contract, catalog, eval, android) become jobs, or local reusable workflows called from `ci.yml`, so the owner never edits the ruleset again | D13, D20, §3.6, O2 step 5, exit criterion 2 |
| A2 | **No path filtering yet.** Drop `ci-changes.sh` and its self-test. Every push runs everything (public-repo minutes are free, CI is small). Revisit when CI takes ≥ 8 min or `eval` arrives | D13, WP5 |
| A3 | Triggers: `push: branches: ['**', '!dependabot/**']`, `pull_request`, `workflow_dispatch`, `schedule` | §3.6 |
| A4 | **Trace bullet regex anchored:** `^\s*[-*]\s+\*\*([A-Z]{1,3}-\d+)\*\*\s*` then an optional `` `\[(R1\|R2\|R3\|Later)\]` `` immediately after. New test: "AT-001 a release tag later in the line does not count" (AT-001's own prose contains `[R1]`) | §3.5 |
| A5 | **Consistent overrides:** UX-001…007 → R1 (AT-004), **AQ-01…AQ-10, AQ-12 → R1 (AT-002), AQ-11 → R2** (its text says "R2 gate"). Expected R1 total **319**. Backlog: a spec tidy adding a Release column to those tables (owner, later) | D19, WP3 done-when, §6 |
| A6 | **`ci-status.sh`:** waits ~3 min before the first poll, then polls every 60 s, uses `filter=latest`, treats a missing check-run as pending, and on 403/429 sleeps until `X-RateLimit-Reset`. Exit codes 0 = success, 1 = failure, 2 = timeout (default 25 min). Requires check `ci` | D20 |
| A7 | **NuGetAudit:** `WarningsNotAsErrors=NU1900;NU1901;NU1902`. NU1903/NU1904 stay errors. D9 is downgraded to FYI (stricter than the docs, not an accepted risk) | D9 |
| A8 | **Dependency test checks "no I/O" too:** besides the pubspec allowlist and "no `sdk: flutter`", scan `lib/**/*.dart` for imports of `dart:io`, `dart:ui`, `dart:ffi`, `dart:isolate`, `dart:html`, `package:flutter/` | D16 |
| A9 | **Risk-first order:** WP4's xUnit v3 + ArchUnitNET spike runs right after WP1 (WP1 → WP4-spike → WP2 → WP3 → WP4-rest → WP5 → WP6). The Host adds `public partial class Program;` and the arch test loads the Host assembly through `typeof(Program).Assembly` | §4, §3.3 |
| A10 | **Drop `Microsoft.Testing.Extensions.CodeCoverage`** until a step gates on backend coverage. **Drop the PR template**: there are no PRs except Dependabot's. The `10` §6 checklist goes into run-step E and the squash commit body | D11, §3.6 |
| A11 | **TestScanner:** allow whitespace/newlines and `r'…'`/`"…"` between `(` and the literal. Call names come from a const set: `test`, `testWidgets`, `group`, `patrolTest`, `goldenTest` | §3.5 |
| A12 | **Dependabot:** version updates **monthly**, `open-pull-requests-limit: 3` per ecosystem. Security updates arrive immediately. Merge path: if the PR head sits directly on current `main` and `ci` passed on it → `git push origin <sha>:main`. Otherwise squash onto `merge/deps-YYYYMMDD` | D4 |
| A13 | **O2 additions:** Settings → Actions → General: "Require approval for all external contributors", and default workflow permissions **read-only**. O4 runs only after `GET …/rules/branches/main` shows the rule | O2, O4 |
| A14 | **O5 doc fix (`10` §6):** Conventional Commits on step branches. `main` gets one `Sxx: <name>` commit per step whose body keeps the branch's commit subjects. Release notes come from those bodies + the Outcomes. Every change to `main` (docs, Dependabot, hotfixes) goes through a CI-verified SHA. Remove the `melos *` allow rule. Add **ask** rules `Bash(git push *:main*)` and `Bash(git push *:refs/heads/main*)` (applied now by the orchestrator: tightening only) | O5 |
| A15 | **Forward notes:** S02's generated `fb_api_client` must be formatted by `make gen` and excluded from analysis. Its dependency allowlist will need `dio`. Recorded for the S02 card | — |

**TD candidates accepted for recording at close:** TD-039 CI-verified fast-forward merges (owner ⚠️), TD-040 tooling baseline (Makefile + pub workspaces, Dependabot, user-local pinned toolchains, `.slnx`, xUnit v3 on MTP), TD-041 dependency vulnerability policy, TD-042 public repo through P0–P2 (owner ⚠️; revisit before real owner messages, prod config or R2).

**Owner items — APPROVED 2026-10-11 ("Rec is good"):** D7/TD-039 merge model + ruleset clicks + allowing `merge/*` and `ci-proof/*` pushes (allow rules added; pushes to `main` still ask); D8/TD-042 public repo through P0–P2; D9/TD-041 vulnerability policy.

## Progress log
_One dated line per event, newest last (process §8a). Entries before 2026-10-12 were reconstructed from git and GitHub after a lost session._

- 2026-10-11 · B: plan + architect amendments committed; owner approved D7/D8/D9 ("Rec is good").
- 2026-10-11 · C: WP1–WP6 committed (`9a49483`…`dc2a2d5`); CI green on `dc2a2d5` (dart, dotnet, ci).
- 2026-10-12 · O2: owner created the `main` ruleset (verified via API: required `ci`, non_fast_forward, deletion) and confirmed B/C settings. The previous session was lost during Phase D, and its review results were lost with it.
- 2026-10-12 · Remote switched to SSH (owner added laptop key). O3 proof branches pushed: `ci-proof/dart-lint` 3c0c984, `ci-proof/dotnet-warning` c03392d. D: code + security reviews re-launched. Pending: review findings → fixes, O3 results, O4, verifier, O5 docs, O6 merge.
- 2026-10-12 · O4 ✅ empty commit pushed to `main` rejected: "Required status check \"ci\" is expected". O3: `ci-proof/dotnet-warning` dotnet job = failure ✅ (run 38293180619); dart proof pending. Security review: approve, 0 blockers, 1 major (settings.json ask-rule gap: multi-refspec push can reach main; needs owner OK, since it's a permission file), 5 minor, 5 nits. Waiting on the code review before one batched fix WP.
- 2026-10-12 · O3 ✅ both proofs failed CI as intended; proof branches deleted. Owner approved: ask-rules for any push touching main (done, 1245430) and noreply commit email (done). Code review: 1 major (trace counted commented-out tests), 3 minor, 7 nits. Fixes: WP-F1 trace (23ee0fe), WP-F2 platform (0ee6ba1). O5 docs + TD-039..042 + backlog (45a9583). Running: round-2 code + security re-review, verifier. Next: Outcome → merge/S01 → main.
- 2026-10-12 · D/E: round-2 reviews approved (code: 2 minor fixed; security: 1 minor fixed, 2 nits logged). Verifier PASS (5/5). Outcome written, board ✅. Merged via `merge/S01` → `main` (TD-039).

## Outcome
_Written 2026-10-12 (Phase E)._

**Built.** Pinned user-local toolchains (Flutter 3.47.7 / Dart 3.13.5, .NET SDK 10.0.401) installed by `make setup` without sudo, checksum-verified before extraction. Dart pub workspace (`fb_domain`, `fb_text`, `tools/trace`) with `very_good_analysis` and the dependency/no-I/O allowlist tests. .NET 10 skeleton (`.slnx`, Host, BuildingBlocks, Architecture.Tests with ArchUnitNET on xUnit v3/MTP), warnings as errors, NuGetAudit (TD-041). Root Makefile (`help doctor setup check test test-dart test-dotnet trace`). One CI workflow `ci.yml` (jobs `dart`, `dotnet`, gate `ci`, weekly schedule), Dependabot (monthly, 7-day cooldown). `tools/trace` v0 (AT-001), which ignores commented-out tests. `ci-status.sh` for token-free CI checks. `main` ruleset: required `ci` (GitHub Actions), no force push, no deletion, no bypass.

**Evidence.** Verifier PASS on 17381f6: fresh clone `make setup && make check && make test` exit 0 in 20 s (toolchains present). CI green on 17381f6. `make trace`: R1 319 total, 0 covered, 319 missing, 0 warnings. O3: the Dart lint proof (3c0c984) and the .NET warning proof (c03392d) each failed only their own stack. O4: an unverified push to `main` was rejected ("Required status check \"ci\" is expected").

**Deviations.** Single `ci` gate instead of `ci-dart`/`ci-dotnet` (A1). No PR requirement; CI-verified fast-forward merges (D7, TD-039). Public repo (TD-042). Dependabot over Renovate, no melos (TD-040). `.slnx` (D10). R1 count 319, not ≈300 (A5 overrides). `Program` uses the .NET 10 generated public partial class instead of declaring one (A9, ASP0027). `setup-dotnet.sh` dropped `dotnet-install.sh` after review (verify-before-extract). TD-038 (agent model policy, 91211b3) and the session-handoff process (`13` §8a) land in this squash too.

**Follow-ups.** Backlog #1–#15 (NuGet lock files → S04, Dependabot docker → S03, `fb_domain` coverage gate → S08, `skip:` tests counted, optional GitHub hardening, …).

**New TDs.** TD-039 merge model, TD-040 tooling baseline, TD-041 vulnerability policy, TD-042 public repo.

**Metrics.** Planned M (~1.5 sessions), actual ~2.5 sessions (one session lost in Phase D, then resumed). 6 WPs + 2 fix WPs. 2 review rounds. Findings: code review 1 major, 3 minor, 7 nits; security 1 major, 5 minor, 5 nits (round 2: 1 minor fixed, 2 nits logged). Tests: 3 + 3 Dart dependency tests, 32 trace tests, 1 .NET architecture test. Lesson: a lost session cost re-running reviews, which led to the Progress log rule (`13` §8a).
