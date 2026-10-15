# S06a verification (HEAD 4c839a0, branch step/S06-app-shell)

Result: PASS (S06b items out of scope).

## Full checks (clean tree, Flutter 3.47.7)
- make check -> exit 0 (includes dart analyze --fatal-infos, app-check "OK, 57 Dart files, 0 allow comments", contract selftest/breaking/conformance OK)
- make gen-check -> OK (generated code up to date)
- make test-dart -> 6 packages passed (apps/mobile: 93 passed, 1 skipped [the `live` tag, by design]; others 16/121/51/45/32)
- make trace -> UX-001, UX-010, UX-040, LC-002 covered (startup_test, client_config_test, app_shell_test, app_shell_golden_test, update_required_screen_test, l10n_test)
- CI for 4c839a0 (tools/scripts/ci-status.sh): ci, contract, dart, dotnet all success (run 38781641182)

## Tests for the exit criteria (apps/mobile/test/app/startup_test.dart, 13 tests, all pass)
- UX-001 nothing requested/prefs read before first frame; first frame already shows shell; then GET /v1/config
- config fetch failure (offline/timeout/500) keeps defaults, shell usable; cached config used offline on next start
- 426 on /v1/config shows UpdateRequiredScreen (no NavigationBar); 426 on any later request shows it too
- Golden: app_shell_golden_test (light/dark, text x2) passes

## Live /v1/config
Started `dotnet run --project src/Host --urls http://localhost:5198` (needs ~/.dotnet on PATH; without it the build's OpenAPI doc step fails with exit 150).
`flutter test --tags live --run-skipped test/live` -> All tests passed. Output:
live /v1/config from http://127.0.0.1:5198: {minimumAppVersion: 0.1.0, featureFlags: {}, thresholds: {}}
(Without the host running the test fails with connection refused, as expected.) Host stopped afterwards.

## Deliberate violations (make app-check, each reverted; git status clean at the end)
a go_router import in features/today/presentation -> exit 2: `today_screen.dart:1: go-router: imports package:go_router, which is only allowed in app/router/ ...`
b cross-feature non-barrel import -> exit 2: `feature-barrel: imports lib/features/progress/presentation/progress_screen.dart; another feature is imported only through its barrel lib/features/progress/progress.dart`
c Text('Hello') -> exit 2: `raw-string: raw string 'Hello' in Text(...); user-facing text comes from the ARB file`
d EdgeInsets.only(left: 8) -> exit 2: `directional: left: is a physical side; use start:`
e `// app-check: allow go-router reason` on a go_router import -> exit 2: `invalid-allow: go-router can't be allowed: import boundary rules have no exceptions` AND the go-router violation is still reported.

## DoD
- Strings in ARB: apps/mobile/lib/l10n/app_en.arb; raw-string check passes on all lib files.
- Directional layout: directional rule enforced and passing.
- TD-003/004/014 marked Accepted (S06a) in 12-decisions-and-questions.md; forward notes present in S03 (line 38) and S05 (line 36) cards.
- Review round 2: code, security, UX, architect all approve (S06 progress log, 2026-10-15); backlog rows 32-43 present.
- Not checked in depth: prose quality of docs updates.

## S06b, not in scope
A55 install, Android builds/CI jobs, cold-start measurement, patrol, backlog row 33 (trace scanning patrol_test/).
