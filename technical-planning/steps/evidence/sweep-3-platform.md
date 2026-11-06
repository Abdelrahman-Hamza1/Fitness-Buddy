# Backlog sweep 3, platform lane (2026-11-06)

Branch `chore/backlog-sweep-3-platform`. Scope: rows whose fix lives in `backend/`, `contracts/`, `infra/`, `.github/`, `tools/scripts/` and the Makefile, `tools/buddy_eval`, `tools/sync_sim`, Dependabot and `docs/` runbooks. App rows (`apps/mobile/`, `packages/`, `data/`, Dart tools) are the app lane's. `steps/backlog.md` is not edited here: the orchestrator applies this table.

Commits: `9bddc0bb` fix(tools) · `5a8aab1c` ci · `f44d269e` fix(backend).

| # | decision | note |
|---|---|---|
| 1 | open | Upstream: dependabot-core #13950 (lock files with downstream ProjectReferences) is still the blocker; recheck at the next dependency review |
| 3 | closed | Dependabot follows the pub workspace: its 2026-11-01 PR (`d2aecf72`, branch `dependabot/pub/pub-minor-patch-2d8db54c29`) updates `apps/mobile/pubspec.yaml`, `tools/catalog/pubspec.yaml` and the root `pubspec.lock` |
| 4 | open | Recurring process note (quarterly Flutter pin bump); nothing to fix |
| 5 | open (partly) | The nightly part is done: the schedule run's `dart` job runs `make trace` every night (ci.yml "trace" step). The "implemented" column is a `tools/trace` (Dart) change: app lane |
| 7 | open | `tools/trace` is Dart tooling: app lane |
| 8 | fixed | `9bddc0bb`: the Makefile reads `.fvmrc` with sed; `doctor.sh` reports a missing python3 and stops cleanly |
| 9 | fixed | `9bddc0bb`: `tools/scripts/check-pub-lock.py` (+ `test_pub_lock.py`) in `make check-dart`: only `hosted` on https://pub.dev with sha256, or `sdk` |
| 10 | open | Owner, GitHub settings. Rec: turn on private vulnerability reporting and "require actions pinned to a full SHA" (all actions already are); check 2FA. CodeQL for actions is optional |
| 11 | open | Accepted residual; revisit at B13 |
| 12 | fixed | `9bddc0bb`: `ci-nightly.sh` warns when the latest nightly is over 36 h old (schedule disabled after 60 days without activity) |
| 14 | fixed | `9bddc0bb`: `setup-dotnet.sh` URL parse can't traceback (ValueError → empty host → `die`); trap path quoted with `%q` |
| 15 | open | A committed sha512 would break every Dependabot `dotnet-sdk` PR (it can't update the hash). Low value (same host, TLS-pinned https). Revisit with B13 supply-chain review |
| 16 | open | When seen (no pull-limit failures so far) |
| 17 | closed | Dependabot bumps tag and digest together: `f85bed26` (redocly 2.70.0@sha256:…, oasdiff v1.34.1@…) |
| 18 | closed | Done in B09a: `backend/src/Host/OpenApi/BuddyContractTransformer.cs` types string enums; `backend/README.md` note updated in `f44d269e` (it still said "deferred") |
| 19 | open | Owner clicks at A43 (first `contracts-v*` tag) |
| 21 | open | Generic runtime validation against the bundled schema needs a JSON Schema validator (a new NuGet dependency, not approved in a sweep). Rec: decide at B13 |
| 23 | fixed | `9bddc0bb`: `contract-breaking.sh` blocking mode keeps only `::error/::warning/::notice` lines, like conformance |
| 24 | open | When needed (no nested ProblemDetails extension exists) |
| 25 | closed | Accepted limitation (row target "accepted"); now noted at the rule in `contracts/spectral.yaml` |
| 34 | open | B13 (Sentry project setup) |
| 40 | open | B13 |
| 46 | open | A43 (signing split + Gradle dependency verification) |
| 47 | fixed (partly) | `5a8aab1c`: cache usage was 10.9 GB / 10 GB on 2026-11-06; merge/PR refs held ~3 GB of NuGet copies. NuGet is now saved on main only. Recheck after a week (new row N3) |
| 49 | open | Nit; activating patrol_cli from a locked path package changes the nightly bootstrap; not worth the risk in a sweep |
| 50 | fixed | `5a8aab1c`: Dependabot `gradle` for `/apps/mobile/android`, majors ignored (they move with Flutter) |
| 51 | open | A43 |
| 52 | fixed | `9bddc0bb`: an attribute with an android framework id (0x01…) but no android namespace is rejected; self-test case `debuggable-no-namespace` (selftest now also supports `error` = exit 2) |
| 67 | closed | CI already builds the pack first: the `dart-test` job runs `make deps-dart catalog-pack test-dart`, so `bundled_pack_test.dart` runs in CI |
| 68 | open | Needs a draft-aware dev target: `run-dev`, `build-it` and `test-it` rerun `catalog-pack` (no drafts) and overwrite the assets that `CATALOG_DRAFTS=1 make catalog` built |
| 76 | open | Owner check (laptop reboot) |
| 77 | open | Not #112: there the first attempt passed 3/3 tests, then Gradle exited 1 and the retry hung; needs the full job logs when it recurs. Current gate green |
| 78 | open | Owner check (real Google sign-in) |
| 79 | open | Owner check (off-laptop identity recovery copy) |
| 80 | fixed | `f44d269e`: queue and schedule discovery = the 32 earliest due rows ∪ each owner's earliest due row (≤ 32 owners); lock order unchanged; test `A_busy_owner_with_33_due_jobs_does_not_starve_a_later_free_owner` |
| 82 | open | Needs a new paid scope / catalog data |
| 83 | open | B09/M3, B15 (paid) |
| 110 | open | API-wide `AllowDuplicateProperties=false` needs per-API coverage of envelope fields and failure behaviour; too broad for a sweep the night before a deploy |
| 112 | fixed | `5a8aab1c`: `patrol-android.sh` waits up to 240 s for `sys.boot_completed` + `pm` and fails "emulator/device did not start"; summary says "no test output" for an attempt without a Patrol result line |
| 113 | open | Phase 2 Buddy (B09, contract) |
| 122 | open | Phase 2 Buddy (A22/B09 trust boundary) |
| 132 | fixed (partly) | `f44d269e`: pull/history pages stop at 2 MiB of payload (`octet_length(payload::text)`), always ≥ 1 row; no contract change (all clients page until an empty page); test `Pull_and_history_pages_stop_at_the_byte_budget_but_always_carry_one_row`. The per-account storage quota stays open (before R3) |
| 133 | open | R3 privacy policy |
| 138 | open | B15 |
| 139 | fixed | `f44d269e`: the B08 deletion test counts `buddy.attempts` in the user's RLS session, and first asserts the claimed row is visible (was a vacuous migrator count) |
| 140 | open | Contract change (Buddy request bounds) before `contracts-v1.0.0`; phase 2 |
| 146 | open | B15 |
| 154 | open | Owner-approved paid smoke, run with B15 / at the A55 |
| 193 | open | Next Buddy contract-touching step (Buddy frozen, TD-105) |
| 206 | open | Cleanup of never-used sessions needs an Identity migration (identity tables are reachable only through security-definer functions); not before tomorrow's deploy. Rec: a small B-track chore |
| 211 | open | Additive contract problem type; B track before R2 |
| 225 | open | A48 |
| 228 | open | Owner check. Rec for (2): set `Catalog__OpenFoodFacts__UserAgent=FitnessBuddy/<version> (<owner contact>)` in the laptop server env |
| 238 | open | Owner check (optional) |
| 262 | open | Owner question. Rec: keep Sentry sessions off |
| 264 | open | Nightly/device first runs: app lane (see N1) |
| 287 | open | Nightly: app lane (see N1) |
| 298 | open | Owner OK on the Accepted TD-114 text |

## New rows found

- **N1 (stop-the-line, app lane):** the 2026-11-06 nightly is red: `android-it` failed both attempts on `offline_test OF-01 airplane mode: quick-add chip, entry edit, weigh-in, workout by form, Progress` (`Bad state: No element` in `dragUntilVisible`), run 42187022523.
- **N2:** six Dependabot PRs from 2026-11-01 are unmerged (pub, nuget, dotnet-sdk, docker, contract-tools, github-actions; `origin/dependabot/*`). Merge them as one deps chore (A12 merge path) after tomorrow's build.
- **N3:** Actions cache after #47: recheck usage in a week; the Flutter action still saves per-ref caches (~0.9 GB off main) and main holds two ~2 GB Gradle caches.
- **N4:** #132's budget counts stored jsonb text; the escaped JSON response can be larger for non-ASCII text (up to ~6x). A response-size cap belongs with the per-account quota before R3.
