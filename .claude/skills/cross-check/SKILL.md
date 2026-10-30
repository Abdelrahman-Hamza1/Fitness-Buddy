---
name: cross-check
description: Before handing back work or merging, check the places OUTSIDE the files you touched that your change can break (other packages, the backend, generated files, fixtures, labels). A judgment checklist, not a full suite. Use at the end of every WP, after merging main into a step branch, and before starting merge-step.
---

# Cross-check: what else does this change touch?

Running only the test files you edited misses breakage in other parts of the repo, and CI catches it 20+ minutes later. (2026-10-30: three CI failures in one evening, all of this kind.) Full local suites stay off (owner rule). Instead, look at what you changed, find the matching rows below, and run only those checks. Each one takes seconds to a few minutes. Use judgment: skip a row that clearly doesn't apply, and add a check if you see a link this table misses (then add it to the table).

Toolchains: dart and flutter at `~/development/flutter-3.47.7/bin`. Run .NET from `backend/` with `DOTNET_ROOT=~/.dotnet PATH=~/.dotnet:$PATH`. Wrap heavy commands in `timeout 600 tools/scripts/heavy.sh …`.

## Change → also check

| You changed | Also check | How |
|---|---|---|
| `data/**` (foods, dishes, exercises, portions, names) or `tools/catalog/**` | Catalog tool tests (search cases T08/T12…, fixture hash, real data) | `make catalog`, then `cd tools/catalog && dart test` (~3 s) |
| | Server import of the shipped release (schema keywords, recipe ingredients, identities) | `dotnet test --project tests/Persistence.Tests -c Release -- --filter-class FitnessBuddy.Persistence.Tests.CatalogTests`, and the same with `BuddyPublicEvalTests` |
| | App labels and catalog reads (new portion unit = new ARB label; released vs draft dishes) | `flutter test` on `test/features/foods/presentation/unit_labels_test.dart` and `test/core/catalog/offline_catalog_test.dart` |
| | Buddy eval gates and the known-miss baseline (a released dish can change or fix a known miss) | after the `BuddyPublicEvalTests` run above: `python3 tools/scripts/check-buddy-eval.py backend/artifacts/buddy/B09b-aq-m3.json` (and `B09b-aq-b09.json`). A changed miss is re-triaged in `aq_known_misses.json` (same unit, never more entries) |
| A catalog JSON schema (`contracts/catalog/*.schema.json`, `data/schema/*`) | The server's closed schema vocabulary (`backend/src/Modules/Catalog/Infrastructure/ReleaseSchemas.cs`) supports every keyword you used | grep the keyword, then run the CatalogTests above |
| The pack layout (a column or table in `pack_builder.dart`) | The fixture hash in `tools/catalog/test/fixture_sql_test.dart` (re-pin it with a comment saying why) and the app's drift catalog reads | catalog tests, then `offline_catalog_test.dart` |
| `contracts/openapi/**` | Generated client and server conformance | `make gen`, `make check-contract`, the server's contract tests |
| Sync payloads or entities (either side) | Wire-rule parity (fb_domain ↔ server corpus) and `tools/sync_sim` | the parity test files, plus the sim if the rules changed |
| ARB strings or visible UI text | Patrol tests that find widgets by text, and goldens of affected screens | `grep -rn "<old text>" apps/mobile/patrol_test apps/mobile/test`; regenerate only the affected goldens, one at a time |
| Routes, tabs, app shell | Router test, app tabs test | `test/app/router/app_router_test.dart`, `test/app/app_tabs_test.dart` |
| Shared core (`lib/core/**`, `fb_domain`, `fb_design_system`) | Direct users outside your feature | `grep -rln "<symbol>" apps packages --include=*.dart`, then run the 2–3 most direct test files |
| Riverpod or drift annotations | Generated code is current | `make gen-app` produces no diff |
| Android manifest, Gradle, build scripts | Build self-tests and the hardening check | `tools/scripts/build-android-selftest.sh`, `make apk-hardening-selftest` |
| Backend module code | Format and analyzers | `make check-dotnet` (or `dotnet format <csproj> --verify-no-changes`) |
| Anything Dart | Format and analysis | `make check-dart` (retry once if the analysis server crashes for lack of memory) |

## After merging `origin/main` into a step branch

1. Regenerate, never hand-merge: `PROGRESS.md` (`make progress`), `data/catalog_release.yaml` (`make catalog`), l10n and `.g.dart` (`make gen-app`).
2. Stale-base check: `git diff --name-only origin/main HEAD` must list only files your step changed. Restore any other file from `origin/main`.
3. If main brought another step's data or schema changes, run the rows above for that change too. Their change plus yours is what CI will test.

## Report

In your hand-back, list the cross-checks you ran and what each showed, plus any row you skipped and why. Example: "cross-check: catalog tests ✓, CatalogTests ✓, unit labels ✓ (added 9), known-miss: none affected."
