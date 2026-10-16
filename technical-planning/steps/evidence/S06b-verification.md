# S06b verification (HEAD 1c50137, CI run 77)

Result: PASS (WP7 device acceptance moved to S07 by A11).

- Toolchain: `make toolchain-android` idempotent (JDK 21.0.12.1, cmdline-tools 22.0, SDK packages "already installed"); `make doctor` -> "toolchain OK".
- CI run 77 on 1c50137: ci, android, android-it, dart, dotnet, contract all success (`tools/scripts/ci-status.sh`). `ci.needs: [dart, dotnet, contract, android, android-it]` (.github/workflows/ci.yml:482).
- android job annotation: "signed=true: app-staging-release.apk uploaded, sha256 a70577ea7a82...eaabd". build-android.sh pins cert a0e79c3d...5226 (line 29) and fails otherwise. Run 72 per Progress log: signed APK, cert pinned.
- android-it annotation: "UX-010 app launches with no API reachable and switches through the four tabs" passed; Total 1, Successful 1, Failed 0, 36 s.
- `make apk-hardening-selftest`: OK, 14 cases as expected. build-android.sh:98 runs apk_hardening_check.py, deletes outputs and dies on failure. build.gradle.kts:36-48 throws on release without key unless FB_ALLOW_DEBUG_SIGNING=1.
- Local: `make check` exit 0; `make test-dart` 6 packages passed; `make gen-check` OK; `make trace` lists UX-010 -> patrol_test/app_test.dart, test/app/app_shell_test.dart, test/app_shell_golden_test.dart.
- Not run by verifier: Gradle builds (per brief); AAB signing evidence is by script (same pin check for AAB, build-android.sh:141-191), the AAB is not uploaded as a CI artifact.
