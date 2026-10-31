# fb_mobile: the Fitness Buddy app

Flutter app, Android in R1 (D-081), cross-platform code only. Architecture: `technical-planning/03-architecture.md` §2–3. Step: S06 (app shell).

## Layout

| Path | What it is |
|---|---|
| `lib/main.dart` | Entry point: reads the compiled-in flavor config, starts the app. No I/O before the first frame (UX-001). |
| `lib/app/` | Composition root: `app.dart` (MaterialApp, themes, localization; starts `bootstrap/` after the first frame), `app_scope.dart` (provider overrides), `bootstrap/` (independent deferred startup: error reporting, catalog install, public `/v1/config` refresh and API session), `router/` (go_router; the only place that imports it; the update-gate redirect), `shell/` (the four tabs), `theme/`, `update/` (update screen + "Check again"). |
| `lib/core/` | Shared plumbing: `api/` (dio + the generated `FbApi`, client headers, 426 → update gate), `config/` (flavor config, `/v1/config` cache + refresh, app version, update gate), `errors/` (`Failure` + mapping from problem types, Sentry + PII scrubber), `storage/` (shared_preferences: device id, config cache), `ids/` (ID generator port), `navigation/` (typed `AppRoute`s + the `AppNavigator` port features use), `l10n/` (`context.l10n`). Screens never import `core/api/` (plan A3). |
| `lib/features/<feature>/` | One folder per feature. Others import only its barrel `<feature>.dart`; features never import `app/`. |
| `lib/l10n/app_en.arb` | Every user-facing string. `gen/` is generated. |
| `config/<flavor>.json` | Per-flavor defines: `FB_FLAVOR`, `FB_API_BASE_URL`, `FB_SENTRY_DSN`, `FB_GOOGLE_SERVER_CLIENT_ID` (`""`; release-key builds merge it in, A50). |
| `test/` | Widget, unit and golden tests; `goldens/ci/` holds the golden images. |
| `patrol_test/` | Integration tests on a device or emulator (Patrol): the real app, plugins and network. `android/app/src/androidTest/` holds Patrol's Android runner. |

## Commands (from the repo root)

```bash
make gen        # after editing an ARB file or a @riverpod provider: regenerate lib/l10n/gen + *.g.dart (commit them)
make check-dart # format + analyze (very_good_analysis + riverpod_lint)
make test-dart  # all workspace tests, including this app's
make goldens    # after an intended UI change: rewrite the golden images, then review and commit them
```

Tests against the running local API are tagged `live` and skipped by default: start the Host (`dotnet run --project src/Host --urls http://localhost:5198` from `backend/`, see `backend/README.md`), then `flutter test --tags live --run-skipped` here.

The flavor config is passed with `--dart-define-from-file=config/<flavor>.json`; without it the app stops at start with an `AppConfigException`. The Make targets below pass it for you.

## API session (A20)

Bootstrap activates `sessionLifecycleProvider` only after the first frame. The
session coordinator restores secure credentials or acquires a guest identity;
public config, catalog and Sentry do not await it. `sessionStateProvider` exposes
only token-free status/readiness. Protected API calls use the origin-bound auth
interceptor; transport/plugin errors never reach logs with request material.

`SessionRetryScheduler` owns one foreground timer and listens for coordinator
completion, resume and successful same-origin responses. Every wake uses the
coordinator's single monotonic deadline (including uncapped Retry-After); only
auth success resets backoff. Background/disposal cancels the timer. Storage,
validation and registered-session expiry failures never schedule automatic retries.
Tests in `test/app/session_bootstrap_test.dart` and `test/core/session/` exercise
first-frame isolation, offline navigation, retry bursts and lifecycle disposal.

## Android

### Toolchain (once per laptop)

`make setup` (or just `make toolchain-android`) installs, user-locally and pinned (S06 plan D19):

- Temurin JDK 21 into `~/development/jdk-21.0.12.1+1`.
- The Android SDK into `~/development/android-sdk`: cmdline-tools 22.0, platform-tools, platform 36, build-tools 36.0.0, NDK 28.2.

It also **accepts the Android SDK licences** (owner decision D19). It needs about 8 GB free (JDK + SDK ~3 GB, plus the Gradle cache filled by the first build, ~3.5 GB). Running it again does nothing. `make doctor` shows what is installed.

The Makefile exports `JAVA_HOME` and `ANDROID_HOME` for every target, defaulting to the two dirs above. A value already in your environment wins (that is how CI passes the runner's JDK and SDK), so if your shell exports a system JDK, unset `JAVA_HOME` or point it at `~/development/jdk-21.0.12.1+1`; `make doctor` shows which one is used. To run `flutter` or `./gradlew` by hand, export the same two first:

```bash
export JAVA_HOME=~/development/jdk-21.0.12.1+1 ANDROID_HOME=~/development/android-sdk
```

No emulator is installed locally (8 GB image, and it can't run next to Gradle on 7 GB of RAM). The integration tests run on a CI emulator (see "Integration tests" below).

### Flavors

| Flavor | Application ID | Launcher label | API | Cleartext HTTP |
|---|---|---|---|---|
| `dev` | `io.github.abdelrahmanhamza1.fitnessbuddy.dev` | FB Dev | `http://127.0.0.1:5198` (the laptop's API via `adb reverse`) | only to 127.0.0.1 / localhost |
| `staging` | `io.github.abdelrahmanhamza1.fitnessbuddy.staging` | FB Staging | `https://api.staging.invalid` (placeholder; CI sets the laptop test server from A11, Hetzner staging from B13) | none |
| `prod` | `io.github.abdelrahmanhamza1.fitnessbuddy` | Fitness Buddy | `https://api.invalid` (placeholder; the laptop test server from A11, production from B14) | none |

All three install side by side. `minSdk` is 26 (Android 8.0, needed by Sentry 10). Hardening is in `android/app/src/main/AndroidManifest.xml`: no cleartext outside dev, release not debuggable, and the install's device id excluded from cloud backup and device transfer.

### Build

```bash
make build-android                       # staging release: arm64 APK (for the phone) + AAB (for Play, A43)
make build-android FLAVOR=prod BUILD_NUMBER=42
make build-android FLAVOR=dev MODE=debug # dev debug APK
```

Outputs: `build/app/outputs/flutter-apk/app-<flavor>-<mode>.apk` and `build/app/outputs/bundle/<flavor>Release/app-<flavor>-release.aab`. For release builds the target checks the built APK's manifest and network security config (`tools/scripts/apk_hardening_check.py`): not debuggable, no cleartext (dev: only to 127.0.0.1 / localhost), system CAs only. Anything it can't read as safe fails the build.

Version code: a laptop build needs a `BUILD_NUMBER` above the one installed on the phone (CI builds carry the run number), otherwise Android refuses the downgrade. Never uninstall to work around it.

Signing: release builds use the stable release key from `~/.fitness-buddy/keys/release.env` (laptop) or the CI secrets, and the target checks the certificate. Without a key, the outputs are signed with this machine's debug key and renamed `*-debugkey.apk` / `*-debugkey.aab`. A debug-key build can't update a real install, so never hand one out. Gradle refuses a release build without a key unless `FB_ALLOW_DEBUG_SIGNING=1` (the target sets it), so a plain `flutter build apk --release` can't produce one by accident. The key, the secrets and their backup are covered in [`docs/runbooks/android-signing.md`](../../docs/runbooks/android-signing.md).

Times on the laptop: the first build is slow (it downloads Gradle and the dependencies). After that, a release APK + AAB takes a few minutes. Every target stops the Gradle daemons when it is done, to free the RAM.

### Run the dev flavor on the phone

1. On the phone, turn on Developer options, then USB debugging (or Wireless debugging).
2. Start the local API: `dotnet run --project src/Host --urls http://localhost:5198` from `backend/`.
3. Connect the phone, then run `make run-dev`. This sets `adb reverse tcp:5198 tcp:5198`, then runs `flutter run --flavor dev` with hot reload. With several devices connected, set `ANDROID_SERIAL=<serial>`.

### Install a build on the Galaxy A55 (sideload, until A43)

1. Download the APK on the phone. From CI, open the run's artifact in Chrome while signed in to GitHub. It downloads as a plain `.apk`, not a zip.
2. **Install unknown apps:** the first time, Android asks to allow installs from Chrome (or My Files). Allow it for that app only: Settings → Apps → Chrome → Install unknown apps.
3. **Auto Blocker** (Samsung, One UI 6.1+) blocks every sideload while it is on. Turn it off while installing (Settings → Security and privacy → Auto Blocker), then back on.
4. **Play Protect** may warn that the app is unknown, or offer to scan it. Choose "Install anyway" (after "More details"). It is our own build.
5. Install only the **signed** staging APK (`app-staging-release.apk`, never `*-debugkey.apk`). Later builds then install over it and keep the data. A build with a different signature fails with "App not installed" or a conflicting-signature error. Don't uninstall to work around it: uninstalling deletes the app's data.

### Integration tests (Patrol, S06 plan D18)

`patrol_test/` holds the integration tests. They run the real app (dev flavor, `config/dev.json`) on a device or emulator, with the real plugins and network. Nothing serves `127.0.0.1:5198` on an emulator, so they also prove the app works with no API.

```bash
make build-it   # build the two APKs only (dev debug app + Patrol's instrumentation APK); no device needed
make test-it    # build, install and run them on the one running emulator or connected phone
```

- **CI runs them.** The `android-it` job runs `make test-it` on an emulator. Never start an emulator on the 7 GB laptop. `make test-it` on a laptop only makes sense with a phone connected. It uninstalls FB Dev (the dev flavor) before and after the run, which deletes that app's local data. FB Staging and Fitness Buddy are separate apps and are not touched.
- **Pins.** `patrol` is pinned in `pubspec.yaml`, and `patrol_cli` in the Makefile (`PATROL_CLI_VERSION`). Bump the two together (compatibility table at patrol.leancode.co). The targets activate `patrol_cli` globally when it is missing or at another version, with its analytics and shell-completion install turned off.
- **Patrol's Android wiring** is in `android/app/build.gradle.kts`: `PatrolJUnitRunner`, `clearPackageData`, and the test orchestrator. `MainActivityTest.java` is in `src/androidTest/`. Release builds leave Patrol out, because it is a dev dependency.
- **Generated files.** `patrol_cli` writes `patrol_test/test_bundle.dart` on every run. The targets delete it afterwards, and git ignores it.
- **Known warning.** Flutter prints "plugins that apply Kotlin Gradle Plugin (KGP): patrol" (patrol issue #3238). The build works. Re-check when bumping Flutter or Patrol.

### Buddy device round trip (A22 D19, manual)

`integration_test/buddy_round_trip_test.dart` drives the real chat sheet on a connected phone against the API in the flavor config (dev: the laptop server over `adb reverse`) and sends 20 fixed synthetic messages. **Each is a real, paid interpret call: run it only with the owner's go-ahead.** It never runs in CI or `make test-dart`, and it skips unless `A22_ROUND_TRIP=1` is defined. It uses a throw-away profile and prints only `case-<n> <ms>`, then the median and p90 (send tap → first frame with the reply).

```bash
cd apps/mobile
flutter test integration_test/buddy_round_trip_test.dart --profile -d <adb-device-id> \
  --dart-define-from-file=config/dev.json --dart-define=A22_ROUND_TRIP=1
```

### Cold-start baseline (S06 plan D20)

With the phone connected (USB or Wireless debugging) and the CI staging build installed:

```bash
make cold-start                                   # 1 warm-up + 10 cold starts of the staging app
make cold-start COLD_START_APP=io.github.abdelrahmanhamza1.fitnessbuddy RUNS=20
```

It prints each `TotalTime` (`am start -S -W`, about the time to Flutter's first frame), then the median and p90, the device model and its Android build. Measure release builds only: debug builds use the JIT and are slow.

### Device benchmarks (A42)

With the phone connected over adb (one device, or set `ANDROID_SERIAL`):

```bash
make perf-startup                                 # UX-001: 1 seed run + RUNS=10 fresh processes, p50/p90
make perf-device                                  # the other three, profile mode, dev flavor
make perf-device PERF_TARGETS=jank_benchmark_test
```

- `startup_benchmark_test` (`make perf-startup`): UX-001 end to end, one sample per fresh app process, from the process's own start to Today ready (numbers drawn from the loaded seeded day and targets, input bar on screen and tappable), then the bar must open Buddy's sheet and take text. Target p90 ≤ 2,000 ms. `make cold-start` (first frame of a release build) stays as a second view.
- `jank_benchmark_test`: UX-007, real flings in fully live frame scheduling over Today (swipes, a long day), Progress (scroll, period switch) and a long workout history; prints p90/p99/max and the share of frames over 16 ms; fails on any frame over 16 ms (`09` §6).
- `progress_benchmark_test`: each Progress chart's first frame with data, one year of data (< 300 ms, A16).
- `proposal_recompute_benchmark_test`: proposal recompute after a tap (≤ 50 ms, A21).

## Rules worth knowing

- Strings only in `lib/l10n/app_en.arb`, read with `context.l10n.<key>`. English only in R1 (LC-002).
- Directional layout only: `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`.
- Navigate with `ref.read(appNavigatorProvider).go(const ProgressRoute())`. New screens get an `AppRoute` in `lib/core/navigation/app_route.dart`; the router's exhaustive `switch` (a screen per route) and its test (every route registered) make you wire it up.
- Light/dark follows the system (UX-040). Real design tokens come with A02.
- Startup does no I/O before the first frame (UX-001): the config refresh, error reporting, the device id and the package info all start afterwards. `/v1/config` failures are silent; the app runs on the cache or the defaults.
- The update gate: any 426 (or the `/errors/upgrade-required` problem), or a cached/fresh `minimumAppVersion` above the installed version, shows the update screen everywhere. A malformed version never gates.
- Error reporting is off while the flavor's `FB_SENTRY_DSN` is empty. Never put user content (food text, weights, messages) in exceptions, logs or Sentry: the scrubber drops exception messages, but don't rely on it.
