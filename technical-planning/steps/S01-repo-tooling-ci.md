# S01 — Repo, tooling & CI foundation

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | — | M | ⬜ Not started |

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
- [ ] A fresh clone on Linux: `make setup && make check && make test` passes.
- [ ] A PR to `main` runs `ci-dart` + `ci-dotnet`, and both are required to merge.
- [ ] A deliberate lint violation or warning in either stack fails CI.
- [ ] `make trace` prints the R1 IDs from the spec (≈ 300) with all reported as "not covered".
- [ ] The repo is on GitHub (private), `main` is the default branch, and `master` is gone.

## Read first
`10-engineering-practices.md` §1–3, §5–7 · `02-tech-stack.md` §6

## Owner involvement
Create the private GitHub repository and give the session push access (or share the remote URL to add).

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
