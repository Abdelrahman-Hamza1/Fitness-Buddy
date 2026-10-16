# Fitness Buddy

A local-first nutrition and weight tracking app (Flutter, Android first) with an AI assistant, "Buddy", backed by an ASP.NET Core API. The phone is the source of truth and everything except the AI works offline. This monorepo holds the product spec ([`spec/`](spec/README.md)), the technical plan ([`technical-planning/`](technical-planning/README.md)), the Dart packages and app, the .NET backend, and the tooling that builds and checks them with one command.

## Prerequisites

- Linux x64, about **14 GB** of free disk (6.5 GB for Flutter + .NET, about 7.5 GB for the Android JDK, SDK and the Gradle cache). The SDKs install under your home directory, no sudo needed.
- `git`, `curl`, `python3`, `make`, `tar`, `xz-utils`, `unzip`.
- **Docker Engine + Docker Compose v2** (the `docker compose` plugin), usable without sudo. They run the API contract tools (Redocly, Spectral, oasdiff) as pinned images with no network access, so no Node.js is needed. `make doctor` checks them.

On Debian/Ubuntu: `sudo apt-get install git curl python3 make tar xz-utils unzip`. For Docker, follow [Docker's install guide for Ubuntu](https://docs.docker.com/engine/install/ubuntu/) (it includes the Compose plugin), then let your user run it: `sudo usermod -aG docker "$USER"` and log out and back in. These are the only steps that need sudo, and only if something is missing.

## Quick start

```bash
make setup    # install the pinned Flutter, .NET and Android toolchains (user-local), then fetch all dependencies
make check    # format + static analysis (Dart, .NET), then the API contract checks
make gen      # after editing contracts/openapi/: re-bundle the contract and regenerate the Dart client
make test     # all tests, Dart then .NET
make trace    # requirement coverage report (RELEASE=R1|R2|R3|Later|all, default R1)
make doctor   # tool versions, free disk and RAM; fails if a pinned SDK is missing
make help     # every target, with a one-line description
```

The first `make setup` downloads the SDKs and packages (about 3.5 GB on disk once unpacked, plus caches in `~/.pub-cache` and `~/.nuget`), the Android JDK + SDK (about 3.3 GB), and pulls the three contract tool images (about 0.5 GB). It also **accepts the Android SDK licences** (S06 plan D19). The first Android build fills `~/.gradle` (about 4 GB). Later runs skip what is already there. CI runs the same `make` targets.

### What `make setup` installs, and where

| Tool | Version pinned in | Installed to |
|---|---|---|
| Flutter SDK (includes Dart) | `.fvmrc` | `~/development/flutter-<version>` |
| .NET SDK | `backend/global.json` | `~/.dotnet` |
| JDK (Temurin 21) and Android SDK (cmdline-tools, platforms 36 + 35, build-tools, NDK, CMake) | `tools/scripts/setup-android.sh` (+ the default paths in the `Makefile`) | `~/development/jdk-<version>`, `~/development/android-sdk` |
| Contract tools: Redocly CLI, Spectral, oasdiff | `tools/contract-tools/compose.yaml` (tag + digest) | Docker's image store |

Downloads are checksum-verified. A system-wide .NET or JDK is never touched or used. The Makefile calls the SDKs by full path, so nothing needs to be on your `PATH`.

To bump a version, edit `.fvmrc` (`"flutter"`) or `backend/global.json` (`sdk.version`) and run `make toolchain`. Old SDK folders are left in place; delete them by hand if you want the space back.

Optional, if you want `flutter`, `dart` and `dotnet` in your own shell (prepend, so the pinned ones win):

```bash
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$HOME/development/flutter-3.47.7/bin:$DOTNET_ROOT:$PATH"   # use the version from .fvmrc
```

### Low-RAM machines (7 GB)

Targets run one at a time (`.NOTPARALLEL`), the build uses `-m:4`, and tests use `--max-parallel-test-modules 2`, so a full `make check test` fits in 7 GB. Don't run `make -j`. Gradle is capped at 2 GB of heap (`apps/mobile/android/gradle.properties`), and the Android targets stop its daemons when they finish. After a .NET session, free the memory of the build servers:

```bash
~/.dotnet/dotnet build-server shutdown
```

## Run the local API

```bash
make up     # start Postgres, migrate, then api + worker; wait for readiness on 127.0.0.1:5198
curl -H 'X-App-Version: 0.1.0' -H 'X-Platform: android' \
  -H 'X-Device-Id: 0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b' \
  http://127.0.0.1:5198/v1/config
make down
make image-smoke  # isolated Postgres, repeat migrations, api/worker, DB-down health, trace, UID and shutdown
```

The compose setup uses Development **locally only**, prints traces/metrics and binds only loopback.
Postgres 18.6 stays on the private Docker network; migrations run with a separate schema-owner login.
`make down` preserves the database volume. Credentials in compose are local-only. The chiseled image has no shell and runs as UID 1654 with a read-only
filesystem, `/tmp` tmpfs and no Linux capabilities. Image defaults remain production-shaped.

To exercise the app's update screen: `FB_MIN_APP_VERSION=99.0.0 make up`, then `make run-dev`
(with the phone connected). `/v1/config` stays readable so the app learns the forced minimum;
automated tests prove the 426 status on gated endpoints. Restore with `make up`.

Bump the SDK tag/digest in `backend/Dockerfile` together with `backend/global.json`.
The smoke test rejects a mismatch. The runtime image tag tracks the patched ASP.NET packages.

## Repository map

Exists today:

| Folder | What it is |
|---|---|
| [`spec/`](spec/README.md) | Product spec: what and why. The source of truth for requirements. |
| [`technical-planning/`](technical-planning/README.md) | Architecture, decisions (TDs) and one card per delivery step in `steps/`. |
| [`apps/mobile/`](apps/mobile/README.md) | The Flutter app (`fb_mobile`): four-tab shell, flavors (dev/staging/prod), localization, Android build (`make build-android`). |
| [`packages/`](packages/README.md) | Shared Dart packages (`fb_domain`, `fb_text`) in the pub workspace. |
| [`backend/`](backend/README.md) | .NET 10 modular API, observability, architecture tests and Docker image. |
| [`infra/compose/`](infra/compose/docker-compose.yml) | Local API + worker + Postgres, with a one-shot migration service. |
| [`contracts/`](contracts/README.md) | The API contract: OpenAPI 3.1 sources, the committed bundle, Spectral rules, self-test fixtures, shared golden test data. |
| [`tools/`](tools/README.md) | Bash scripts behind the Makefile, the contract tool images, and `trace/` (requirement coverage). |
| [`docs/runbooks/`](docs/runbooks/) | Operational procedures. Today: Android release signing. |
| `.github/` | CI workflow (`workflows/ci.yml`) and Dependabot config. |
| `.claude/` | Agent and skill definitions for the delivery process. |
| `Makefile`, `pubspec.yaml`, `pubspec.lock` | One entry point; the Dart workspace root and its single lockfile. |

Planned (full map: [`technical-planning/10-engineering-practices.md`](technical-planning/10-engineering-practices.md) §1):

| Folder | What it will be |
|---|---|
| `packages/fb_api_client/`, `packages/fb_design_system/` | Generated API client, UI kit (planned) |
| `data/` | Reference dishes, exercises, portion words (planned) |
| `tools/buddy_eval/`, `tools/catalog/` | AI acceptance suite, catalog build/validate (planned) |
| `infra/tofu/`, `infra/cloud-init/`, `infra/kamal/` | Infrastructure provisioning and deployments (S05/S29) |

## CI

One workflow, `.github/workflows/ci.yml`, runs on every push and pull request. Its gate job **`ci`** is the one required check on `main`: it passes only if Dart, .NET, contract and image jobs pass, plus Android jobs when required (TD-060). In CI, `make deps-dart` runs `flutter pub get --enforce-lockfile`, so `pubspec.lock` can never be re-resolved silently; to update it, run `make deps-dart` locally and commit the result.

To wait for and read the result of a pushed commit (no `gh` or token needed, public repo):

```bash
tools/scripts/ci-status.sh <sha>     # exit 0 = ci passed, 1 = failed, 2 = timed out
```

## Merge flow

Work happens on a step branch (`step/Sxx-name`) with Conventional Commits. At the end of a step:

1. Squash the branch on a local `merge/Sxx` branch, one commit `Sxx: <step name>`, and push it.
2. Wait for `ci` to be green on that SHA (`tools/scripts/ci-status.sh <sha>`).
3. Fast-forward `main` to the same SHA (`git push origin merge/Sxx:main`), then delete both branches.

`main` only accepts commits on which `ci` already passed. Details: [`technical-planning/13-delivery-process.md`](technical-planning/13-delivery-process.md).

## Conventions

- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/), e.g. `feat(diary): …`, `fix(api): …`, `build(S01): …`.
- **Traceability:** every test that proves a spec requirement carries its ID, and `make trace` reports coverage per release.
  - Dart: `test('AI-060 rejects an empty proposal', …)`, or a `// covers: AI-060, AI-061` comment.
  - C#: `[Trait("Req", "AI-060")]`, or the same `// covers:` comment.
  - Details: [`tools/trace/README.md`](tools/trace/README.md).
- **Code style:** `dart format` + `very_good_analysis` (infos are errors); `dotnet format` + analyzers with warnings as errors. `make check` enforces both.
