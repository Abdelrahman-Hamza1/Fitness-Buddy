# S06 — App shell

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S02 | L → S06a M + S06b M | 🟨 S06a in progress |

**Goal.** An installable Flutter app with the final skeleton: flavors, navigation with four tabs, themes, localization scaffolding, the generated API client, error reporting, and the test harnesses. It runs on the owner's A55 from a CI build. Every feature step plugs into this.

**Spec:** UX-010 (tabs, placeholders), UX-040 (light/dark following system), UX-001 (baseline measurement), LC-002 (English UI), C-1 (Android in R1, D-081) · **Decisions:** TD-003, TD-004, TD-014, TD-034

## Scope
- `apps/mobile` in the Dart workspace. Package ID, app name "Fitness Buddy".
- **Flavors:** `dev` (local API), `staging`, `prod`. Android `applicationIdSuffix` per flavor, so they can be installed side by side. Config via `--dart-define-from-file`.
- **material_ui** package, **Riverpod 3** with codegen, **go_router** behind `AppRouter` with a `StatefulShellRoute` for **Today / Progress / Workouts / Me** (placeholder screens).
- Theme wiring: light/dark following the system (real tokens come in S07).
- **Localization:** gen-l10n with an `en` ARB, a lint/grep check against raw strings in widgets and against `left/right` (RTL readiness, `09` §3).
- **Feature folder skeleton** (`03` §3.2) with barrels, and the **import-boundary check** in CI.
- **API client wiring:** `fb_api_client` on dio with interceptors (base URL per flavor, `X-App-Version`, `X-Platform`, `X-Device-Id`, `X-Request-Id`, timeouts). A **non-blocking** `/v1/config` fetch after the first frame, cached locally with defaults. `Failure` mapping skeleton from problem-details `type` (`09` §8). `426` → an "update required" screen.
- **Sentry** initialised after the first frame (deferred), with PII scrubbing.
- **Test harnesses:** golden tests (alchemist) with one golden, an integration test (patrol) that launches the app and switches tabs.
- **Builds:** Android debug/release APK + AAB in CI (`mobile-release` skeleton). **No iOS work in R1** (D-081): no iOS pipeline, but no Android-only shortcuts in shared code, and only plugins that also support iOS.
- **Cold-start baseline** on the A55 (time to first frame, measured and recorded).

## Out of scope
- Real design (S07), local DB (S09), sign-in (S25).

## Fixed by the plan
- Packages and versions in `02` §1. Layering rules in `03` §2.
- Startup does no network work before the first frame (UX-001).

## Decide in the low-level plan
- How the APK reaches the owner during P0–P2 (a GitHub Actions artifact sideload vs Firebase App Distribution vs Play internal testing early). Default: the GitHub artifact until S29.
- Typed routes approach for go_router (codegen or hand-written route constants).

## Notes from earlier steps
- **From S02:** the app fetches `/v1/config` in the background and caches it, never on the startup path (CLAUDE.md rule 3); the 426 gate never blocks startup on the network. Release builds use an HTTPS base URL and Android disallows cleartext. Construct union values through the generated union factories.

## Exit criteria
- [ ] The owner installs the staging build on the A55. Four tabs work, and light/dark follows the system.
- [ ] With staging up (S05) the app fetches `/v1/config`. With the API down it still starts normally (offline-first). Before S05, use the local API in `dev`.
- [ ] A forced `426` from the API shows the update screen.
- [ ] CI: analyze, unit, golden and integration tests green. The import-boundary and raw-string checks fail on deliberate violations.
- [ ] Cold start to first frame on the A55 recorded in the Outcome (budget: input bar ≤ 2 s, UX-001).

## Read first
`03-architecture.md` §2–3 · `02-tech-stack.md` §1 · `09-cross-cutting.md` §3, §6, §8–9

## Owner involvement
Install builds on the A55 and confirm they run.

---

## Low-level plan
_Written in Phase B (2026-10-13) by the step-planner, against main 7da45e5 + research notes "S06 — Android toolchain…" (R1) and "S06 — Flutter package set…" (R2). Proposed split: **S06a** (WP1–WP3, app skeleton + local checks, all host-side) and **S06b** (WP4–WP7, Android toolchain, builds, signing, CI, device). See §8._

### 1. Summary
`apps/mobile` (Dart package `fb_mobile`) joins the workspace: material_ui app, Riverpod 3 codegen, go_router behind `AppRouter` with hand-written typed routes, a four-tab `StatefulShellRoute` (Today / Progress / Workouts / Me placeholders), system light/dark, gen-l10n `en`. Data side: dio + `fb_api_client` with client-header interceptors, `/v1/config` fetched after the first frame and cached, `Failure` mapping from problem `type`, a 426 / minimum-version gate to an "update required" screen, deferred Sentry with a strict scrubber (empty DSN = off). A standalone `tools/app_check` enforces feature boundaries, raw strings and left/right in `make check`. Android: user-local JDK + SDK via `make setup`, three flavors side by side, stable release signing, CI jobs `android` (signed staging APK as an unzipped artifact + AAB) and `android-it` (Patrol on an emulator), and a cold-start baseline on the A55.

### 2. Decisions

| # | Decision | Reason / source |
|---|---|---|
| D1 | **Package set** (R2 table). Exact pins: `material_ui 1.6.0`, `riverpod_annotation 4.0.7`, `riverpod_generator 4.0.9`, `riverpod_lint 3.1.9` (root `analysis_options.yaml` `plugins:` only), `alchemist 0.14.1`, `patrol 4.10.0` (+ `patrol_cli 4.8.0` in the Makefile), `build_runner 2.16.1`, `dio 5.11.1` (same as fb_api_client). Caret: `flutter_riverpod ^3.4.3`, `go_router ^18.0.2`, `sentry_flutter ^10.0.0`, `shared_preferences ^2.5.6`, `package_info_plus ^10.2.2`, `intl ^0.20.2`. Dependabot ignores the riverpod generator trio, material_ui and patrol (bumped deliberately: codegen/golden/native churn). `make check-dart` keeps `dart analyze --fatal-infos` (`flutter analyze` hides plugin diagnostics) | R2: all resolve under the analyzer < 14 cap. All support iOS (C-1, no Android-only plugins) |
| D2 | **Typed routes hand-written** (card decision): `sealed class AppRoute` with one `final class` per route holding its path and `location`; `AppRouter` builds the `GoRouter`; **`package:go_router` may only be imported under `lib/app/router/`** (app_check rule). Navigation: `ref.read(appRouterProvider).go(const ProgressRoute())` | No second generator over every file, a swap of go_router stays inside one folder (TD-004). Five routes don't justify codegen. **TD candidate** (refines TD-004) |
| D3 | **APK delivery until S29** (card decision): the signed staging release APK as an **unzipped** Actions artifact (`archive: false`, 30-day retention), uploaded **only when signed with the stable key**. The owner downloads it in Chrome on the A55 (GitHub login) | R1 research. No new vendor. Firebase App Distribution / Play internal testing stay S29 options |
| D4 | ⚠️ **OWNER: release signing.** Rec: stable keystore (generated by the orchestrator with `keytool`, backed up in the owner's password manager) in Actions secrets `FB_ANDROID_KEYSTORE_BASE64`, `FB_ANDROID_KEYSTORE_PASSWORD`, `FB_ANDROID_KEY_PASSWORD` (review r1: the alias `fitnessbuddy` is set in `ci.yml`, a secret would mask it in logs) (the owner pastes them in repo Settings, ~5 min on the laptop). `build.gradle.kts` reads `FB_KEYSTORE_PATH` + the 3 values from env; absent → debug signing + a Gradle warning (forks, Dependabot, local). **Alternative** (committed public dev keystore): no secrets and no owner step, but anyone can sign an "update", and moving to a private key before Play costs one uninstall (local data lost unless exported) | R1. Debug-signed CI builds can't update each other: an uninstall would wipe local-first data. **TD candidate** |
| D5 | ⚠️ **OWNER: application ID** (permanent once on Play, S29). Rec `io.github.abdelrahmanhamza1.fitnessbuddy` (tied to the owner's GitHub account, no domain needed); alternative: a domain the owner controls. Suffixes: dev `.dev`, staging `.staging`, prod none. Launcher labels: "Fitness Buddy" / "FB Staging" / "FB Dev" (`resValue` per flavor) | Card: side-by-side install. Labels let the owner tell them apart |
| D6 | **Flavors:** Android `productFlavors` (dimension `env`) + `apps/mobile/config/{dev,staging,prod}.json` via `--dart-define-from-file`, keys `FB_FLAVOR`, `FB_API_BASE_URL`, `FB_SENTRY_DSN` (`""` everywhere until S05). Dev = `http://127.0.0.1:5198` (the Host's documented port, `backend/README.md`) reached through `adb reverse tcp:5198 tcp:5198` (same on the emulator and the A55); cleartext allowed **only in the dev flavor and only to 127.0.0.1/localhost** (`src/dev/res/xml/network_security_config.xml`). Staging/prod = `https://api.staging.invalid` / `https://api.invalid` placeholders (`.invalid` never resolves; S05/S29 fill them) | 09 §9, S02 forward note (HTTPS + no cleartext in release). One `main.dart`, flavor from defines |
| D7 | **Owner build = `staging` release, `--target-platform android-arm64`, `--build-number=$GITHUB_RUN_NUMBER`** (each CI build installs over the last). The `android` job builds release APK + AAB only; the **debug build is the dev-flavor APK Patrol builds in `android-it`** (no second cold debug build, R1: 352 s cold) | Card's "debug/release APK + AAB" kept without duplicate work. No separate `mobile-release` workflow yet: the `android` job is its skeleton; S29 adds the `app-v*` tag workflow + Play upload (no dead workflow) |
| D8 | **Client headers** in one `ClientHeadersInterceptor`: `X-App-Version` = package_info `version` (e.g. `0.1.0`), `X-Platform` from `defaultTargetPlatform` (`android`/`ios`, no hard-coding), `X-Device-Id` = UUIDv7 from `fb_domain` `systemUuidV7Generator()` created **once** on first API use and stored in `SharedPreferencesAsync` (`fb.device_id`), `X-Request-Id` = a fresh UUIDv7 per request. Both lookups are lazy and memoised (never on the startup path). Timeouts: connect 10 s, send 15 s, receive 15 s (per-request override later for Buddy). No body/header logging | Contract headers (`contracts/README.md`), S02 forward note. Install ID, not a hardware ID |
| D9 | **Config:** `ClientConfigRepository` keeps the last good `ClientConfig` JSON in `SharedPreferencesAsync` (`fb.client_config.v1`, generated `toJson`/`fromJson`), defaults `minimumAppVersion "0.0.0"`, empty flags/thresholds. `AppBootstrap.afterFirstFrame` (post-frame callback) loads the cache, then refreshes from the API; any failure keeps cache/defaults silently | UX-001, rule 3, 09 §9, S02 note |
| D10 | **Update gate:** `UpdateGate` (Riverpod notifier, `required: bool`) turns true on (a) any 426 response or problem `type` `/errors/upgrade-required` (dio error interceptor), or (b) a cached/fresh `minimumAppVersion` above the app version (`AppVersion` = numeric MAJOR.MINOR.PATCH compare; malformed → no gate, fail open). The router's `redirect` sends every location to `/update-required` (outside the shell): plain-language copy + "Check again" (refreshes config). Blocking is intended: it is the kill switch (04 §8). No store link in R1 (sideload) | Card + 04 §4.2. (b) costs nothing and works offline from the cache, never blocking startup on the network |
| D11 | **`Failure` skeleton** (`lib/core/errors/`): sealed `Failure` = `OfflineFailure`, `TimeoutFailure`, `RateLimitedFailure(retryAfter?)`, `InvalidInputFailure(fieldErrors)`, `ConflictFailure`, `NotFoundFailure`, `UnauthorizedFailure`, `UpgradeRequiredFailure`, `ServerFailure(status)`, `UnexpectedFailure`. `FailureMapper.fromDio(DioException)`: connection error → Offline; timeouts → Timeout; a problem+json body → by catalogue `type` (constants `ProblemTypes`), else by status (401, 404, 412, 426, 429, 5xx). UI copy per failure comes with the first screen that shows one (`AiUnavailable` with S2x Buddy) | 09 §8, contracts/README catalogue. Strings are catalogue constants, not API types (rule 4 holds); a test keeps them in sync with the README table |
| D12 | **Sentry** (`lib/core/errors/`): after the first frame, **only if the DSN is non-empty**, `SentryFlutter.init` (no `appRunner`) with `sendDefaultPii=false`, `attachScreenshot/ViewHierarchy=false`, `maxRequestBodySize=never`, `tracesSampleRate=0` (S05 tunes), environment = flavor, release `fb_mobile@<version>+<build>`, and `beforeSend`/`beforeBreadcrumb` = `PiiScrubber`: drops `user`, `request`, `extra`, breadcrumb `message`/`data` (keeps category, level, navigation route **names**), and replaces exception **values** with `[scrubbed]` (type + stack kept). Errors before init are not reported (accepted, R2) | Rule 6 strictly: exception messages can carry user text. Empty DSN = off (R2: `''` disables, null throws) |
| D13 | **Feature skeleton:** `lib/features/{today,progress,workouts,me}/` each with its barrel `<feature>.dart` and `presentation/` (placeholder screen). `application/`, `data/` and the other features of 03 §3.2 are created by the steps that fill them (no empty folders). **`me/` is new** (Me tab composition, like `today/`): WP1 adds it to 03 §3.2 | The anatomy is shown and enforced; no speculative structure |
| D14 | **Generated app code is committed** (gen-l10n output under `lib/l10n/gen/`, riverpod `*.g.dart`), `make gen` gains `gen-app`, `make gen-check` covers it | Same pattern as TD-045; `dart analyze` and CI need no codegen before analyze |
| D15 | **Localization:** `l10n.yaml` (arb-dir `lib/l10n`, template `app_en.arb`, output `lib/l10n/gen`, `nullable-getter: false`). Delegates `[AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]` with `GlobalMaterialLocalizations` **from material_ui** (not the generated list); `context.l10n` extension | R2: the generated list breaks material_ui in `ar` |
| D16 | **`tools/app_check`** (workspace member `fb_app_check`, no runtime deps, from the scratch prototype): rules (1) other features only via their barrel, (2) `presentation/` never imports `data/`, (3) I/O packages (`ioPackages` in `tools/app_check/lib/src/checker.dart`: `dio`, `fb_api_client`, `shared_preferences`, `http`, the `drift*`/`sqlite3*`/`sentry*` families, platform plugins) only in `data/` and `core/` (A3), (4) `core/` never imports `features/`, (5) `go_router` only in `app/router/`, (6) raw user-facing literals in `Text(`, `label:`, `title:`, `hintText:`, `tooltip:`, `semanticLabel:` …, (7) `left/right` APIs (`EdgeInsets.only/fromLTRB`, `Alignment.*Left/Right`, `TextAlign.left/right`, `left:`/`right:`, `Icons.*_left/_right`, `BorderRadius.only`). Escape hatch (review r1, A-M1): `// app-check: allow <rule-id> <reason>` on the line, only for the lexical rules `raw-string` and `directional`; boundary rules have no inline hatch. Exit 1 with `file:line: rule: message`. Runs in `make check-dart` (`make app-check` alone) | Orchestrator pick; `import_lint` is dead under analyzer 13 (R2). 10 §3 rows "barrels" + "left/right, raw strings" |
| D17 | **Goldens:** alchemist **CI goldens only** (`PlatformGoldensConfig(enabled: false)` in `test/flutter_test_config.dart`), tag `golden` in `dart_test.yaml`, `make goldens` updates. One golden: the shell at Today, light + dark scenarios | Same pixels on the laptop and CI (Ahem font). Platform goldens differ per OS (R2) |
| D18 | **Integration test with Patrol** in `apps/mobile/patrol_test/` (dev flavor, debug), on a CI emulator (`android-it`, API 34 `google_apis` x86_64, parallel to `android`, in `ci.needs`). No local emulator needed (disk: the ATD image is 8.2 GB). `tools/trace` scans `patrol_test/` too (one line) | Card; R1. The CI emulator has no API → the test also proves offline start |
| D19 | **Android toolchain** (R1): `tools/scripts/setup-android.sh` installs Temurin **21.0.12+1** and cmdline-tools **22.0** (sha256-pinned) into `~/development/`, then `sdkmanager` `platform-tools`, `platforms;android-36`, `build-tools;36.0.0`, `ndk;28.2.13676358`, and accepts the SDK licences (⚠️ **OWNER**, asked: `yes \| sdkmanager --licenses` in `make setup`). Idempotent, disk check (≥ 8 GB free). Makefile: `JAVA_HOME ?=`, `ANDROID_HOME ?=` exported; `toolchain` gains `toolchain-android`; `doctor` reports them. `gradle.properties`: `org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=1G`, `kotlin.daemon.jvmargs=-Xmx1G`; laptop targets run `./gradlew --stop` after a build. `minSdk 26` (Sentry 10). CI: runner JDK 21 + SDK, NDK via the runner's `sdkmanager` | R1 measured. Extends TD-040. **TD candidate** |
| D20 | **Cold-start baseline method:** `make cold-start` (`tools/scripts/cold-start.sh <applicationId> [runs]`) over adb (USB or Wireless debugging): one discarded run, then 10× `am start -S -W`, prints each `TotalTime`, median and p90, device model and build. Flutter's Android embedding holds the first Android draw until Flutter's first frame, so `TotalTime` ≈ time to first Flutter frame; cross-checked once with `flutter run --profile --trace-startup` in the same session | Owner effort: enable USB/Wireless debugging once and plug in for ~10 min (same session runs the dev-flavor `/v1/config` demo). The measurement runs on the CI-built staging APK |

### 3. Design

**3.1 Layout (`apps/mobile/`, created with `flutter create --platforms android --project-name fb_mobile`, then `dart fix --apply --code=migrate_design_widgets`)**
```
pubspec.yaml (resolution: workspace, version 0.1.0+1) · l10n.yaml · build.yaml · dart_test.yaml · analysis_options.yaml (includes root; excludes **/*.g.dart, lib/l10n/gen/**)
config/{dev,staging,prod}.json                       D6
lib/main.dart                                        ensureInitialized → AppConfig.fromEnvironment() → ProviderContainer
                                                     → runApp(UncontrolledProviderScope(FitnessBuddyApp)) → addPostFrameCallback(AppBootstrap.afterFirstFrame)
lib/app/config/app_config.dart                       AppConfig(flavor, apiBaseUrl, sentryDsn) from String.fromEnvironment; validates (throws on missing keys)
lib/app/bootstrap/app_bootstrap.dart                 afterFirstFrame: ErrorReporting.start (D12) → ClientConfigRepository.load + refresh (D9); never awaited by the UI
lib/app/router/{app_route.dart,app_router.dart}      D2: TodayRoute /today, ProgressRoute /progress, WorkoutsRoute /workouts, MeRoute /me,
                                                     UpdateRequiredRoute /update-required; StatefulShellRoute.indexedStack, 4 branches; redirect from UpdateGate
lib/app/shell/app_shell.dart                         NavigationBar (material_ui) + StatefulNavigationShell; labels and icons from ARB/Icons
lib/app/theme/app_theme.dart                         light/dark ThemeData from ColorScheme.fromSeed; themeMode: ThemeMode.system (S07 replaces)
lib/app/app.dart                                     FitnessBuddyApp: MaterialApp.router, delegates (D15), supportedLocales [en]
lib/app/update/update_required_screen.dart           D10
lib/core/api/{dio_factory,client_headers_interceptor,upgrade_required_interceptor,device_id_store,api_providers}.dart   D8
lib/core/config/{client_config_repository,app_version,update_gate}.dart                                                 D9, D10
lib/core/errors/{failure,failure_mapper,problem_types,error_reporting,pii_scrubber}.dart                                 D11, D12
lib/core/l10n/l10n.dart                              context.l10n
lib/features/{today,progress,workouts,me}/<f>.dart + presentation/<f>_screen.dart                                       D13
lib/l10n/app_en.arb (+ gen/)                         appTitle, tab labels ×4, placeholder bodies ×4, update title/body/button
test/ (unit, widget, golden: test/goldens/ci/), patrol_test/app_test.dart
android/: app/build.gradle.kts (namespace + applicationId D5, minSdk 26, flavors D6, signing D4, Patrol runner + orchestrator),
          gradle.properties (D19), src/dev/res/xml/network_security_config.xml, src/androidTest/.../MainActivityTest.java (Patrol)
```
Root: `pubspec.yaml` workspace adds `apps/mobile`, `tools/app_check`; `analysis_options.yaml` adds `plugins: riverpod_lint: 3.1.9`.

**3.2 Providers** (`@Riverpod(keepAlive: true)` unless noted): `appConfig` (overridden in `main`), `sharedPreferences` (`SharedPreferencesAsync`), `packageInfo` (async, lazy), `deviceIdStore`, `dio`, `fbApi` (`FbApi(dio, baseUrl: appConfig.apiBaseUrl)`), `clientConfigRepository`, `clientConfig` (notifier: defaults → cache → fresh), `updateGate` (notifier), `appRouter`. Tests override `appConfig`, `sharedPreferences` (in-memory platform) and the dio `HttpClientAdapter`.

**3.3 Data flow.** Frame 1: no I/O except reading compile-time defines. Post-frame: Sentry (if DSN) → config cache → `GET /v1/config` with headers → cache + `UpdateGate.check`. Any 426 anywhere → `UpdateGate.trip()` → router `refreshListenable` → `/update-required`. Layering: widgets read providers only; dio/fb_api_client live in `core/` (data layer), enforced by app_check (03 §2 rule 1). No user data is written in S06 (no ChangeSetApplier yet; settings/cache aren't user data).

**3.4 Makefile** (group "Mobile app"): `gen-app` (in `gen`), `app-check` (in `check-dart`), `goldens`, `toolchain-android` (in `toolchain`), `build-android` (`FLAVOR=staging`, release APK arm64 + AAB, `BUILD_NUMBER`), `run-dev` (adb reverse + `flutter run --flavor dev`), `test-it` (patrol_cli 4.8.0 activate-if-missing, `patrol test --flavor dev`), `cold-start`. `GEN_DART_DIRS` extended with `apps/mobile/lib/l10n/gen` and `:(glob)apps/mobile/lib/**/*.g.dart`.

**3.5 CI** (`ci.yml`, SHAs from R1): job `android` (checkout, flutter-action, `JAVA_HOME_21_X64`, NDK install, `gradle/actions/setup-gradle` v6.4.0 `cache-provider: basic`, read-only off main; keystore restored from secrets into `$RUNNER_TEMP` only if `FB_ANDROID_KEYSTORE_BASE64` is set; `make build-android BUILD_NUMBER=$GITHUB_RUN_NUMBER`; `upload-artifact` v7.0.2 `archive: false`, retention 30, only when signed; APK sha256 into the job summary). Job `android-it` (checkout, flutter-action, JDK 21, KVM udev step, `ls -l /dev/kvm`, setup-gradle, `reactivecircus/android-emulator-runner` v2.38.0 API 34 google_apis x86_64, AVD cache, `make test-it`). `ci.needs: [dart, dotnet, contract, android, android-it]`. Secrets never echoed; `permissions: contents: read` unchanged.

### 4. Work packages (sequential; Gradle and an emulator never run together on the laptop)

**S06a**

| WP | Specialist | Tasks | Done when |
|---|---|---|---|
| WP1 App skeleton | flutter-engineer | `flutter create` + material_ui migration; workspace member; pins D1 (+ Dependabot ignores); root riverpod_lint plugin; l10n D15; `AppConfig` + config JSONs D6; router + shell + 4 placeholder features D2/D13; theme; update screen (static); golden harness D17 + one golden; `gen-app`, `goldens`, gen-check dirs D14; 03 §3.2 gains `me/` | `make deps-dart gen check-dart test-dart gen-check` green; widget + golden tests of §5 group A pass |
| WP2 Data wiring | flutter-engineer | `core/api` D8, `core/config` D9/D10, `core/errors` D11/D12, `AppBootstrap` post-frame; providers 3.2; `live`-tagged test against the local Host (skipped by default) | §5 groups B–D pass; live test passes against `dotnet run --project src/Host --urls http://localhost:5198` (output pasted) |
| WP3 app_check | flutter-engineer | `tools/app_check` from the prototype with rules D16, fixture tree under `test/fixtures/`, `app-check` in `check-dart`; `patrol_test` in `tools/trace`'s scanned dirs | §5 group E pass; `make check` green on the real app; a pasted local run on 3 deliberate violations (reverted) |

**S06b**

| WP | Specialist | Tasks | Done when |
|---|---|---|---|
| WP4 Toolchain + Gradle | platform-engineer | `setup-android.sh` D19 (+ licences), Makefile exports, `doctor`; `gradle.properties` caps; flavors + labels + `applicationIdSuffix` D5/D6, dev network security config, minSdk 26; signing from env D4; `build-android`, `run-dev`, `cold-start` script D20; README "Android" section (setup, installing on the A55: unknown apps, Auto Blocker, Play Protect) + `docs/runbooks/android-signing.md` (key generation, secrets, backup) | `make setup` idempotent on the laptop; `make build-android` builds the signed (local env) staging APK + AAB; `apksigner verify --print-certs` shows the stable cert; dev debug APK builds; `./gradlew --stop` leaves no daemon |
| WP5 Patrol | flutter-engineer | Patrol native setup (instrumentation runner, test orchestrator, `MainActivityTest`) under AGP 9.1 + flavors; `patrol_test/app_test.dart`; `make test-it` | `patrol build android --flavor dev` succeeds on the laptop (no emulator); the test runs green in WP6's `android-it` |
| WP6 CI | platform-engineer | jobs `android` + `android-it` (3.5), gate `needs`; measure both job times; record `/dev/kvm` result | CI green on the branch, signed APK artifact present (after the owner's secrets), timings in the Progress log |
| WP7 Device acceptance | orchestrator + owner | Owner installs the artifact on the A55, checks tabs + light/dark; one USB/wireless-adb session: `make cold-start` on the staging APK, `make run-dev` + Host for the `/v1/config` demo | Exit criteria 1, 2, 5 evidenced (§6) |

### 5. Test list (Dart tests carry the ID in the name, 10 §5)
- **A (WP1):** `UX-010 shell shows the four tabs Today, Progress, Workouts, Me` · `UX-010 tapping a tab shows its placeholder and keeps the other branches' state` · `UX-040 theme follows the system brightness (light and dark)` · `LC-002 app supports only en and every visible string comes from AppLocalizations` · golden `UX-010 UX-040 app shell light/dark` · `AppConfig reads every key; each config JSON has all keys; staging/prod URLs are https` · `typed routes: every AppRoute location is registered in the router`.
- **B (WP2, API):** `ClientHeadersInterceptor sets X-App-Version, X-Platform, X-Device-Id (uuid) and a new X-Request-Id per request` · `device id is created once and reused after a restart` · `dio timeouts are 10/15/15 s` · `base URL comes from the flavor config`.
- **C (WP2, config + gate):** `UX-001 nothing is requested before the first frame; /v1/config is requested after it` · `config fetch failure (offline, timeout, 500) keeps cache/defaults and the shell stays usable` · `fresh config is cached and read back on the next launch` · `426 response trips the update gate and shows the update screen` · `problem type /errors/upgrade-required trips the gate` · `minimumAppVersion above the app version shows the update screen; equal or below doesn't` · `AppVersion compares numerically (0.1.10 > 0.1.9); malformed input never gates` · `Check again lifts the gate when the fresh config allows the version`.
- **D (WP2, errors):** `FailureMapper maps each catalogue type` (table) · `status fallbacks 401/404/412/426/429/5xx` · `connection error → Offline, timeouts → Timeout, non-JSON body → by status` · `every type in the contracts/README.md catalogue has a ProblemTypes constant` · `PiiScrubber drops user, request, extra, breadcrumb data and exception values; keeps type and stack` · `Sentry is not initialised when the DSN is empty` (plain `test`, R2 gotcha) · `live: GET /v1/config against the local Host` (tag `live`).
- **E (WP3, app_check fixtures):** one failing fixture per rule 1–7 with the expected `file:line: rule` output · passing fixtures (barrel import, `Text(context.l10n.x)`, interpolation-only strings, `EdgeInsetsDirectional`, `AlignmentDirectional`, `// app-check: allow raw-string <reason>`) · `allow without a rule id or reason, or naming a boundary rule, fails and silences nothing` · `the real apps/mobile tree passes`.
- **F (WP5, Patrol):** `UX-010 app launches with no API reachable and switches through the four tabs`.

### 6. Exit-criteria mapping (reworded for the gaps: no staging until S05, no server 426 until S03)
| Card criterion | Demonstrated by |
|---|---|
| Owner installs the **staging** build on the A55; four tabs; light/dark follows the system | WP7: CI-signed staging release APK (artifact) installed on the A55; owner taps the tabs and toggles system dark mode (owner's "ok"). Tests A + golden back it up |
| `/v1/config` fetched; starts normally with the API down | **Reworded:** in `dev` against the local Host (`dotnet run`, port 5198, `adb reverse`) on the A55 during the WP7 session: Host log shows `GET /v1/config` with the four headers, and the live test. API down: Patrol test (CI emulator, no API), test C, and the owner's staging build (URL never resolves). The staging half moves to S05 |
| A forced `426` shows the update screen | **Reworded:** dio-adapter widget test (C) returning 426 and the upgrade-required problem; the server-forced 426 demo moves to S03 (forward note) |
| CI analyze, unit, golden, integration green; checks fail on violations | CI jobs `dart` (analyze incl. riverpod_lint, unit, golden, app_check, gen-check), `android`, `android-it` green; fixture tests E + the pasted violation run (WP3) |
| Cold start to first frame on the A55 recorded | `make cold-start` on the CI staging APK (median + p90 of 10) in the Outcome, cross-checked once with `--trace-startup`. Baseline only: the input bar arrives with Buddy |

### 7. Risks & unknowns
- **KVM / emulator on the standard public runner unverified** (R1): WP6 checks `/dev/kvm` first. Fallback: ask the owner to keep `android-it` out of `ci.needs` (report-only) until fixed; Patrol still runs locally on demand.
- **Patrol under AGP 9.1 + flavors** (KGP warning #3238, flavor wiring unverified): WP5 spikes it first (≤ 1 h); fallback: plain `integration_test` (same test body, `flutter test integration_test --flavor dev` on the CI emulator), Patrol revisited when a native dialog test needs it.
- **Runner's sdkmanager (cmdline-tools 12) vs repository XML v4:** fallback AGP's own NDK download (licences pre-accepted on runners) or install cmdline-tools 22 with `setup-android.sh`.
- **Gradle heap 2G** may OOM in R8 as the app grows: `GRADLE_JVMARGS` override in `build-android` for CI (16 GB).
- **riverpod_lint plugin** is fetched by the analysis server (network on the first analyze, not under `--enforce-lockfile`): exact pin; if CI flakes, cache `~/.dartServer`.
- **`am start -W` ≈ first Flutter frame** is medium confidence: the `--trace-startup` cross-check settles it.
- **`X-Request-Id` as a request header** isn't in the contract (only echoed in responses); harmless extra header, S03 decides whether the server adopts it (forward note).
- **Laptop disk** +6.5 GB (JDK, SDK, Gradle cache): the script checks free space first; no emulator image locally.
- **Owner country vs Android developer verification** (R1: four countries from 2026-09-30): confirm the A55 isn't affected; fallback `adb install`.
- **Card conflicts:** 09 §9 says "dev (local API in Docker)": no Docker API until S03/S04, dev uses `dotnet run`. The card's `mobile-release` skeleton is the `android` job (D7). `me/` adds a feature folder to 03 §3.2 (D13).

### 8. Size check
Estimate **L, ~2.5 sessions** (S06a ~1.25: WP1–WP3, all host-side Flutter/Dart; S06b ~1.25: WP4–WP7, toolchain install, Gradle builds, CI iterations on two new jobs, one device session). Above M, so **propose the split at the natural seam**: **S06a "App skeleton"** (exit: CI analyze/unit/golden + app_check green, checks fail on violations, 426 and offline-config tests, live config test) and **S06b "Android builds & device"** (exit: signed APK on the A55 with tabs + light/dark, `android`/`android-it` green, `/v1/config` on the device, cold-start baseline). S06b depends on S06a; the owner's signing and application-ID answers are needed before S06b, not S06a.

### 9. Amendments after architect review (2026-10-13, orchestrator-applied, these override the sections above)

| # | Change | Overrides |
|---|---|---|
| A1 | **No provider cycle in the update gate:** `upgradeSignal` (keepAlive bool notifier, no deps; the 426 interceptor calls `trip()`, session-only, never persisted, also triggers a config refresh) + derived `updateRequired = upgradeSignal \|\| minimumAppVersion > appVersion` (watches `clientConfig`, `packageInfo`); the router's `refreshListenable` listens to it. No imperative `UpdateGate.check`. `clientConfig` is the single owner of load/refresh; `AppBootstrap` only calls `notifier.refresh()` | §3.2, D10 |
| A2 | **Features never depend on `app/`:** go_router-free `sealed AppRoute` + an `AppNavigator` port (`go(AppRoute)`) live in `lib/core/navigation/`, provider overridden in `main`; `AppRouter` in `app/router/` implements it (go_router only there). app_check rule: `features/**` never imports `app/**`. WP1 adds `core/navigation` and `me/` to `03` §3.2 | D2, D16 |
| A3 | **Presentation never reaches HTTP via core:** app_check rule: `features/*/presentation/`, `app/shell/`, `app/update/` may not import `core/api/**`, `core/db/**`, `core/sync/**`. Rule 3's allow-list = `data/` and `core/` only (drop `app/bootstrap/`) | D16 |
| A4 | **No `X-Request-Id` request header** (not in the contract). Forward note S03: decide request correlation; if adopted, add it to `headers.yaml` first | D8, card scope |
| A5 | **Sentry privacy:** Dart scrubber also drops `contexts.device.name` and `server_name`; never set `user` (not even the device id); navigation breadcrumbs carry route names only. Forward note S05: native (Java/NDK) events bypass Dart `beforeSend` — decide native scrubber vs `enableNativeCrashHandling=false` and verify both paths before a DSN is set | D12 |
| A6 | **(S06b) Signing key → Play app signing key at S29** (PEPK upload) so Play builds update the sideloaded install; `docs/runbooks/android-signing.md` + S29 note. Debug-key fallback outputs are named `*-debugkey.apk` and never uploaded as the owner deliverable. Delete the restored keystore in an `if: always()` step | D4 |
| A7 | **(S06b) Emulator policy:** `timeout-minutes` on both Android jobs; at most one automatic retry of the emulator run inside the job, logged in the job summary; if `/dev/kvm` is missing or > 1 flaky failure in ~10 runs, `android-it` leaves `ci.needs` (report-only) only with the owner's ok + a tracking note; plain `integration_test` is the next fallback | D18, §3.5, §7 |
| A8 | **(S06b) Release builds prove no cleartext:** `build-android` checks the staging/prod merged manifest + network config (`cleartextTrafficPermitted=false`, no `usesCleartextTraffic=true`); `AppConfig` test asserts the dev URL host is loopback; dev `network_security_config` = base deny + `domain-config` for 127.0.0.1/localhost. No `versionNameSuffix` on any flavor; test for a malformed own app version (gate fails open) | D6, D10 |
| A9 | **TD-003, TD-004, TD-014 → Accepted at S06a close** (source S06a). TD-034 already Accepted | — |
| A10 | **Split hygiene:** patrol/patrol_cli pins and `patrol_test/` move to S06b WP5. Forward notes written in the same commit as S06a's close on S03 (server 426 demo, request correlation), S05 (`/v1/config` staging check, Sentry native scrubbing). `09` §9 dev line → `dotnet run` until S03/S04. app_check rules 6–7 scoped to `lib/`, generated files excluded | §8 |
| A11 | **(S06b, owner 2026-10-15) Device acceptance moves to S07:** WP7 (A55 install, tabs + light/dark, `make cold-start` baseline, `/v1/config` on the device) runs in S07's phone session, so the owner does one device session instead of two. S06b exits on WP4–WP6: `make setup` installs the toolchain, signed staging APK + AAB build (local env and CI), `android` + `android-it` green, Patrol test green on the CI emulator. Backlog #32 (cleartext only in dev, release not debuggable, backup rules exclude the device id, signing files out of git) and #33 (`patrol_test/` in trace) are in S06b scope | §4 WP7, §6, §8 |

**S06b plan approved by the owner 2026-10-15 (D4, D5, D19 = rec; A11).** **S06a plan approved by the orchestrator under TD-037 (no ⚠️ OWNER item in S06a), 2026-10-13. S06b waits for the owner on D4 signing, D5 application ID, D19 SDK licences (and A7's report-only fallback only if ever needed).**

## Progress log
_One dated line per event, newest last (process §8a)._

- 2026-10-13 · A: ready (S02 ✅, main green 7da45e5). Gaps to plan around: no staging (S05 deferred to P3) → `dev` flavor against the local API, staging flavor config only; no Sentry account yet → init with an empty DSN (no-op) until S05; 426 from the API → simulated (S03 not done). Owner prerequisite: A55 with "install unknown apps". B: research launched: (1) Android toolchain (JDK, SDK, Gradle) user-local + CI builds + emulator/patrol feasibility; (2) Flutter package set under Flutter 3.47.7 and the analyzer < 14 cap.
- 2026-10-13 · B: research (1) done: JDK 21.0.12+1, cmdline-tools 22.0, platform 36, build-tools 36.0.0, NDK 28.2.13676358 user-local (~6.5 GB incl. Gradle cache); Gradle heap must be capped (~2G) on the laptop; Patrol 4.10.0 on a CI emulator (parallel job); APK delivered as an unzipped Actions artifact. **Owner asked:** release signing (stable keystore in 4 GitHub secrets, rec) + accepting Google SDK licences in `make setup`. Waiting on research (2).
- 2026-10-13 · B: research (2) done: package set resolves under the analyzer cap (material_ui 1.6.0, Riverpod 3.4.3 + generator 4.0.9, go_router 18.0.2, alchemist 0.14.1, patrol 4.10.0, sentry_flutter 10.0.0 (minSdk 26, empty DSN = no-op), shared_preferences, package_info_plus). Orchestrator picks: material_ui delegates, hand-written typed routes, standalone Dart boundary/raw-string script. step-planner launched; signing still waiting on the owner (rec as default).
- 2026-10-13 · B: low-level plan written (L, ~2.5 sessions) → split S06a App skeleton (WP1–3, host-side) / S06b Android builds & device (WP4–7). ⚠️ OWNER: signing (D4), SDK licences (D19), application ID (D5, rec `io.github.abdelrahmanhamza1.fitnessbuddy`). Architect review launched.
- 2026-10-13 · B: architect approve with changes; A1–A10 applied; S06a approved under TD-037. C: S06a WP1 (flutter-engineer) launched. S06b waits on owner D4/D5/D19.
- 2026-10-13 · C: S06a WP1 committed (apps/mobile skeleton: four tabs, AppRoute + AppNavigator port, AppRouter, light/dark, gen-l10n en, Riverpod codegen, golden; 19 tests; UX-010/UX-040/LC-002 covered). No android/ folder yet: WP4 runs `flutter create --platforms android` with the D5 org. WP2 (data wiring) launched.
- 2026-10-14 · C: S06a WP2 committed (dio + client headers, device id, /v1/config after first frame with cache, update gate per A1 incl. 426 test, Failure mapping synced with the README catalogue, Sentry deferred + PII scrubber; 78 app tests; live /v1/config test against the local Host passed). Deferred: Sentry navigation breadcrumbs → S05. WP3 (app_check) launched.
- 2026-10-14 · C: S06a WP3 committed (tools/app_check: 9 rules + escape hatch with reason, 37 tests, wired into check-dart; real app passes; deliberate violations fail readably). D: S06a code + security + UX review launched.
- 2026-10-15 · D: resumed after the session hit its limit (review results lost). Branch green (`make check`, `make test-dart`). Re-running code + security + UX review.
- 2026-10-15 · D: review round 1 done, all approve-with-findings, 0 blockers. UX 2 major (update screen scroll, check-again feedback); architect 4 medium (app_check hatch scope, core/api↔core/config cycle, device id → core/storage, route-pattern note) + 5 low; security 4 minor (scrubber install ids, https-only non-dev, same-origin headers, replay off); code 3 minor + 4 nit. Fix round 1 (flutter-engineer) launched.
- 2026-10-15 · D: fix round 1 committed (all U/S/A/C findings fixed; mobile 92 tests, app_check 45; check + gen-check green). Card D16/§3.4/§5E synced to `app-check` + rule-scoped hatch. Forward note for S03: if `/v1/config` answers 426, `refresh()` should report it so the update screen says "still old", not "are you online?". Re-review launched (code, security, UX, architect, scoped to round-1 findings).
- 2026-10-15 · D: review round 2: code, security, UX, architect all approve. Last minors fixed in round 2 (API Dio never follows redirects + test; upgrade_signal comment wording; card D16 rule 3 synced with `ioPackages`/A3). Security residuals → backlog 40–43. Next: verifier.
- 2026-10-15 · D: close-out records (A9/A10): TD-003/004/014 → Accepted; TD-051 (navigation), TD-052 (app_check), TD-053 (install device id, Proposed); forward notes on S03 and S05. Verifier launched (S06a exit per §8 split).
- 2026-10-15 · D: verifier PASS (evidence/S06a-verification.md). E: Outcome written; S06a ✅ under TD-037 (no owner item); merging via merge/S06a.
- 2026-10-15 · S06b A: owner OK on D4 (stable keystore in 4 Actions secrets), D5 (`io.github.abdelrahmanhamza1.fitnessbuddy`), D19 (licences accepted in `make setup`). Owner asked whether the A55 test can wait; orchestrator rec sent (build/CI now, device check batched with S07).
- 2026-10-15 · S06b B/C: owner OK to defer the A55 check → A11 (WP7 moves to S07's phone session). Board 🟨. WP4 (platform-engineer: toolchain, Gradle, flavors, signing, Android hardening) launched.
- 2026-10-15 · S06b C: WP4 committed (setup-android.sh pinned JDK 21 + SDK, licences; android/ with flavors dev/staging/prod, appId io.github.abdelrahmanhamza1.fitnessbuddy, minSdk 26; env signing + debugkey fallback; release key made at ~/.fitness-buddy/keys, cert SHA-256 a0e79c3d…5226 pinned in build-android.sh; no-cleartext + not-debuggable APK check; backup excludes shared prefs/datastore; build-android, run-dev, cold-start; runbook android-signing). Laptop: cold staging APK 382 s, warm ~72 s; APK 22 MB. ⚠️ OWNER: back up the key + add 4 Actions secrets (runbook §2–3). WP5 (Patrol) next.
- 2026-10-15 · S06b C: WP5 committed (Patrol 4.10.0 + patrol_cli 4.8.0 work under AGP 9.1 + flavors, no fallback needed; `patrol_test/app_test.dart` UX-010 offline + four tabs; `make test-it`/`build-it` via tools/scripts/patrol-android.sh; trace scans patrol_test/ (backlog #33 done); equatable 3.0.0→2.1.0 forced by patrol). Test APKs build on the laptop (first 199 s, repeat ~33 s); first device run is WP6's CI emulator. Side effect on the laptop: an early manual patrol run added a completion block to ~/.bashrc and enabled patrol analytics (now off) → told the owner. WP6 (CI) next.
- 2026-10-15 · S06b C: WP6 committed by platform-engineer (9548e4f, 0ae6590): jobs `android` + `android-it` in `ci.needs`; /dev/kvm present; runner sdkmanager 12.0 worked. Run 72 (0ae6590): signed staging APK uploaded unzipped (22.4 MB, sha256 e6084bc9…0c29, cert pinned); Patrol UX-010 ✅ on API 34 emulator (35 s), no retry. Job times cold Gradle: android 482–835 s, android-it 524–634 s. Owner added the 4 secrets; skipped key backup (accepted, backlog #48). D: code + security review (TD-054: no UX, no architect).
- 2026-10-16 · S06b D: review r1: security approve (5 minor, 4 info), code approve (1 major: APK hardening check fails open + no self-test; 6 minor, 6 nits). TD-055 (signing), TD-056 (toolchain) recorded; deferred items → backlog #45–#51. Fix round 1 (platform-engineer) running; resumed after a session limit (no partial edits). Then re-review of the major only (TD-054), verifier, close.
- 2026-10-16 · S06b D: fix round 1 committed: APK hardening check moved to `apk_hardening_check.py`, fail-closed, trust anchors + domain-config rules, 13-case fixture self-test in `make check` and the android job; release builds without the key fail unless the script opts into debug signing; alias no longer a secret (3 secrets); one SDK package list; AAB verified with jarsigner; runbook S29/leak/no-secrets-in-APK; comment de-dup (TD-054). Re-review of the major (code-reviewer) next.
- 2026-10-16 · S06b D: re-review r2 of the major: resolved (approve). Its new minor (alias variant of network_security_config ignored) + jarsigner comment nit fixed by the orchestrator, fixture `nsc-alias-variant` (14 cases). Remaining nit (no-namespace attribute with android id, only hand-crafted binaries) → backlog #52. Verifier next.
- 2026-10-16 · S06b D/E: verifier PASS (evidence/S06b-verification.md; WP7 → S07 per A11). Outcome written, board ✅, merging via merge/S06b.

## Outcome

### S06a App skeleton (closed 2026-10-15, accepted by the orchestrator under TD-037)
**Built**
- `apps/mobile`: Flutter app with four tabs (go_router `StatefulShellRoute`, per-tab stacks), the go_router-free `AppRoute` + `AppNavigator` port, light/dark following the system, gen-l10n (en), and Riverpod 3 codegen. Composition root in `app/app_scope.dart`.
- API wiring: a dio client (API origin only, no redirects, no logging) with `X-App-Version`/`X-Platform`/`X-Device-Id`. The install device id is a UUIDv7 in `core/storage`.
- `/v1/config` after the first frame, with a versioned local cache.
- Update gate: any 426 / `upgrade-required` trips a session signal, or a cached `minimumAppVersion` above the app version blocks. The update screen scrolls and has check-again states.
- `Failure` mapping synced with the contracts catalogue.
- Error reporting deferred: Sentry is skipped with an empty DSN. An allow-list PII scrubber is in place, and replay, logs and metrics are dropped.
- `tools/app_check`: 9 rules (feature barrels, layers, I/O packages, go_router confinement, raw strings, left/right). A rule-scoped hatch exists only for the lexical rules. It runs in `make check-dart`.

**Deviations from the plan (all reviewed)**
- `AppConfig` is in `core/config/`, not `app/config/`, because core can't import app.
- `failure_mapper`, `problem_types` and `client_config_repository` are in `core/api/`, so the presentation-io rule covers them (architect L2/M2).
- The device id is in `core/storage/` (M3).
- `UpgradeSignal` is a dependency-free file. The config refreshes by listening to it, which removes the core/api↔core/config cycle (M2).
- The make target is `app-check` (the plan said `check-app`).
- New small ports: `idGeneratorProvider` and the `UpdateCheck` view model.
- The escape hatch is `allow <rule-id> <reason>`, for lexical rules only (M1).
- `ioPackages` gained prefix families and platform plugins.
- sentry_flutter 10 has no `enableLogs`, so logs and metrics are dropped with `beforeSendLog`/`beforeSendMetric`.
- Sentry navigation breadcrumbs were moved to S05.

**Follow-ups:** backlog #32–#43:
- S06b: Android hardening, `patrol_test/` in trace.
- S05: Sentry native scrubbing, logs/metrics and project settings.
- S03: the 426 on `/v1/config`.
- S07/S16: placeholder tabs.
- S09: ChangeSetApplier check.
- S25: auth interceptor origin.
- Plus the config read facade, route paths without user data, and the `system.dart` import rule.

**New TDs:**
- TD-051 (app navigation) and TD-052 (`tools/app_check`): Accepted.
- TD-053 (install device id): Proposed, confirm at S09.
- TD-003, TD-004 and TD-014 moved to Accepted (A9).

**Measurements:** none on the device yet. Cold start is measured in S06b.

**Evidence:** `steps/evidence/S06a-verification.md`
- `make check`, `gen-check` and `test-dart` green.
- CI green at 4c839a0.
- Deliberate violations: go-router, feature-barrel, raw-string and directional each fail readably. An allow on a boundary rule is `invalid-allow` and silences nothing.
- Live `/v1/config` against the local Host passed.
- Spec IDs UX-001, UX-010, UX-040 and LC-002 are traced 4/4.

**Metrics**
- Size: planned M (~1.25 sessions); took ~2 sessions, one lost to a session limit mid-review.
- 3 WPs plus 2 fix rounds.
- Review rounds: 2.
  - Round 1: 2 major (UX), 4 medium (architect), 15 minor/low, 9 nits.
  - Round 2: 1 minor, 2 low/minor, 5 nits. All approved.
- Tests added: mobile 93 (+1 live, skipped by default), app_check 45.

### S06b Android builds & device (closed 2026-10-16; owner decided D4/D5/D19, self-merge OK)
**Built**
- **Pinned Android toolchain** in `make setup` (`tools/scripts/setup-android.sh`): JDK 21 and the Android SDK, with licences accepted and one package list (`android-sdk-packages.txt`).
- **`apps/mobile/android/`** with dev/staging/prod flavors (`io.github.abdelrahmanhamza1.fitnessbuddy` plus `.dev`/`.staging`), minSdk 26, and the Gradle heap capped.
- **Release signing** with the stable key (TD-055):
  - The key lives on the laptop, plus 3 Actions secrets.
  - The certificate is pinned.
  - Release builds without the key fail unless the script opts into debug signing.
  - The AAB is verified with jarsigner.
- **Fail-closed APK hardening check** (`apk_hardening_check.py`): no cleartext outside dev, dev loopback only, not debuggable, system trust anchors only, a single network config file. A 14-case fixture self-test runs in `make check` and in CI.
- **Backup rules** exclude prefs and datastore, so the device id is never backed up.
- **Make targets:** `build-android`, `run-dev`, `cold-start`.
- **Patrol 4.10.0** integration test (UX-010) with `make test-it`/`build-it`; trace scans `patrol_test/`.
- **CI jobs** `android` (signed staging APK uploaded unzipped) and `android-it` (API 34 emulator, KVM), both in the `ci` gate.
- **Runbook** `docs/runbooks/android-signing.md`.

**Deviations**
- WP7 device acceptance moved to S07's phone session (A11, owner).
- 3 secrets, not 4: the alias is plain config (security r1).
- The device id lives in DataStore, not `shared_prefs`, so backup excludes both.
- INTERNET permission added to the main manifest, plus an explicit deny-cleartext config in main.
- Extra SDK packages `platforms;android-35` and `cmake;3.22.1` (needed by a plugin).
- equatable 3.0.0 → 2.1.0, forced by patrol.

**Follow-ups:** backlog #44–#52, among them:
- `abiFilters`
- the DB backup policy at S09
- signing outside Gradle plus dependency verification before S29
- the Actions cache size
- reminding the owner to back up the key
- Dependabot for gradle
- the S29 upload-key decision

**New TDs:** TD-055 (signing), TD-056 (Android toolchain).

**Measurements**
- Laptop, signed staging build: cold APK 382 s; warm about 72 s for the APK and 31–42 s for the AAB.
- Sizes: APK 22 MB (arm64), AAB 54 MB.
- CI, cold Gradle: `android` 482–835 s, `android-it` 524–634 s.
- Patrol UX-010: 35–36 s on the emulator.
- Cold start on the A55 is still pending (S07).

**Evidence:** `steps/evidence/S06b-verification.md`
- CI green on 1c50137 (run 77, signed=true).
- Patrol UX-010 ✅.
- Self-test 14/14.

**Metrics**
- Size: planned M; took about 1 session. WPs: 3 plus 1 fix round.
- Reviews: 2 rounds (code + security under TD-054).
  - Round 1: 1 major, 11 minor, 6 nits, 4 info.
  - Round 2: 1 minor (fixed by the orchestrator), 2 nits.
- Tests added: Patrol 1, trace 1, hardening fixtures 14.
