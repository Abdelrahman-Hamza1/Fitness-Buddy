# tools/

Developer and CI tooling. Everything here runs through the root `Makefile`; you rarely call it directly.

| Path | What it is |
|---|---|
| `scripts/` | Plain Bash scripts (`set -euo pipefail`, Linux x64). No sudo, nothing installed outside your home directory. |
| `scripts/setup-flutter.sh` | Installs the Flutter SDK pinned in `.fvmrc` into `~/development/flutter-<version>`: the official stable archive, sha256-checked against Flutter's release index, analytics disabled. Skips if already installed, after checking that the SDK there really is the pinned version (`bin/cache/flutter.version.json`); any other version is an error, never silently used. Used by `make toolchain-flutter`. |
| `scripts/setup-dotnet.sh` | Installs the .NET SDK pinned in `backend/global.json` into `~/.dotnet` (or the directory given as argument). Takes the SDK tarball URL and sha512 from Microsoft's release metadata (`releases.json`), accepts only `https://builds.dotnet.microsoft.com/`, and checks the sha512 *before* extracting; no hash or no archive is a hard failure. Then merges into the install dir like `dotnet-install.sh` does (existing versioned folders only gain missing files, `dotnet` muxer replaced, `sdk/<version>` moved in last). Skips if that SDK (or a newer patch in the same feature band) is present. Never touches a system .NET. Used by `make toolchain-dotnet`. |
| `scripts/doctor.sh` | Prints tool versions, free disk and RAM, and fails if the pinned SDKs are missing. Used by `make doctor`. |
| `scripts/ci-status.sh` | `ci-status.sh <sha> [timeout-min]`: waits for the required check `ci` (`.github/workflows/ci.yml`) on a pushed commit and prints every check run with its URL. Anonymous GitHub API (public repo, 60 requests/hour; `GITHUB_TOKEN`/`GH_TOKEN` used if set). First poll after 3 min (capped so at least one poll happens before the timeout), then every 60 s, sleeps through rate limits. Only check runs from GitHub Actions count; if a commit has several `ci` runs, all must be finished and the newest decides. Exit 0 = `ci` passed, 1 = failed, 2 = timed out (default 25 min). Used in the merge flow before pushing a SHA to `main`. |
| `trace/` | Requirement traceability report (Dart package `fb_trace`, workspace member): spec IDs vs tagged tests, per release. Used by `make trace`. See `trace/README.md`. |

Later steps add more Dart tools here (`buddy_eval/`, `catalog/`), see `technical-planning/10-engineering-practices.md` §1.

Conventions for scripts: take paths as arguments (the Makefile passes them), print clear `name: error: …` messages to stderr, are safe to re-run, and keep downloads in a fresh temp directory that is removed on exit.
