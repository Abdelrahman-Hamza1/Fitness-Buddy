# fb_mobile: the Fitness Buddy app

Flutter app, Android in R1 (D-081), cross-platform code only. Architecture: `technical-planning/03-architecture.md` §2–3. Step: S06 (app shell).

## Layout

| Path | What it is |
|---|---|
| `lib/main.dart` | Entry point: reads the compiled-in flavor config, starts the app. No I/O before the first frame (UX-001). |
| `lib/app/` | Composition root: `app.dart` (MaterialApp, themes, localization; starts `bootstrap/` after the first frame), `app_scope.dart` (provider overrides), `bootstrap/` (deferred startup: error reporting, then the `/v1/config` refresh), `router/` (go_router; the only place that imports it; the update-gate redirect), `shell/` (the four tabs), `theme/`, `update/` (update screen + "Check again"). |
| `lib/core/` | Shared plumbing: `api/` (dio + the generated `FbApi`, client headers, 426 → update gate), `config/` (flavor config, `/v1/config` cache + refresh, app version, update gate), `errors/` (`Failure` + mapping from problem types, Sentry + PII scrubber), `storage/` (shared_preferences: device id, config cache), `ids/` (ID generator port), `navigation/` (typed `AppRoute`s + the `AppNavigator` port features use), `l10n/` (`context.l10n`). Screens never import `core/api/` (plan A3). |
| `lib/features/<feature>/` | One folder per feature. Others import only its barrel `<feature>.dart`; features never import `app/`. |
| `lib/l10n/app_en.arb` | Every user-facing string. `gen/` is generated. |
| `config/<flavor>.json` | Per-flavor defines: `FB_FLAVOR`, `FB_API_BASE_URL`, `FB_SENTRY_DSN`. |
| `test/` | Widget, unit and golden tests; `goldens/ci/` holds the golden images. |

## Commands (from the repo root)

```bash
make gen        # after editing an ARB file or a @riverpod provider: regenerate lib/l10n/gen + *.g.dart (commit them)
make check-dart # format + analyze (very_good_analysis + riverpod_lint)
make test-dart  # all workspace tests, including this app's
make goldens    # after an intended UI change: rewrite the golden images, then review and commit them
```

Tests against the running local API are tagged `live` and skipped by default: start the Host (`dotnet run --project src/Host --urls http://localhost:5198` from `backend/`, see `backend/README.md`), then `flutter test --tags live --run-skipped` here.

Running on a device needs the Android toolchain and Gradle flavors (S06b). The flavor config is passed with `--dart-define-from-file=config/<flavor>.json`; without it the app stops at start with an `AppConfigException`.

## Rules worth knowing

- Strings only in `lib/l10n/app_en.arb`, read with `context.l10n.<key>`. English only in R1 (LC-002).
- Directional layout only: `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`.
- Navigate with `ref.read(appNavigatorProvider).go(const ProgressRoute())`. New screens get an `AppRoute` in `lib/core/navigation/app_route.dart`; the router's exhaustive `switch` (a screen per route) and its test (every route registered) make you wire it up.
- Light/dark follows the system (UX-040). Real design tokens come with S07.
- Startup does no I/O before the first frame (UX-001): the config refresh, error reporting, the device id and the package info all start afterwards. `/v1/config` failures are silent; the app runs on the cache or the defaults.
- The update gate: any 426 (or the `/errors/upgrade-required` problem), or a cached/fresh `minimumAppVersion` above the installed version, shows the update screen everywhere. A malformed version never gates.
- Error reporting is off while the flavor's `FB_SENTRY_DSN` is empty. Never put user content (food text, weights, messages) in exceptions, logs or Sentry: the scrubber drops exception messages, but don't rely on it.
