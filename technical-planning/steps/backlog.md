# Backlog: follow-ups, tech debt & minor findings

Items found during steps that aren't done in that step. The orchestrator adds them at step close (`run-step` E2) and from reviews (`review-changes` §3), and schedules them into a later step's scope, or proposes a cleanup step to the owner when they pile up.

| # | From | Item | Severity | Target step | Status |
|---|---|---|---|---|---|
| 1 | S01 | NuGet lock files (`packages.lock.json`) once Dependabot + CPM support is solid. Rechecked S04 (2026-10-16): [upstream #13950](https://github.com/dependabot/dependabot-core/issues/13950) is still open for downstream ProjectReference lock updates; S01 baseline retained | minor | next dependency review / before B04 | open |
| 2 | S01 | Dependabot `docker` ecosystem entry (needs a Dockerfile) | minor | S03 | done (S03) |
| 3 | S01 | Verify Dependabot handles the pub workspace after its first monthly run; fallback: scheduled `dart pub outdated` | minor | next after first run | open |
| 4 | S01 | Flutter pin bump cadence: manual, quarterly (Dependabot covers the .NET SDK) | minor | recurring | open |
| 5 | S01 | Nightly `trace` workflow + "implemented" column in the report | minor | backlog | open |
| 6 | S01 | `fb_domain` coverage gate in CI | minor | S08 | done (S08 WP1) |
| 7 | S01 review | trace v0 counts `skip:` tests as covered (documented limitation) | minor | B15 or earlier | open |
| 8 | S01 review | Makefile: missing python3 is a parse-time error, so `make doctor` can't report it | nit | backlog | open |
| 9 | S01 review | `pubspec.lock` is `linguist-generated` (collapsed in diffs): add a check that every lock `url:` is `https://pub.dev` | nit | S02 | open |
| 10 | S01 security | Optional GitHub hardening: Actions allow-list + require full-SHA pinning, private vulnerability reporting, CodeQL for `actions`, owner 2FA check | minor | owner, any time | open |
| 11 | S01 security | Residual: flutter-action pins `actions/cache` by tag and doesn't verify the Flutter archive hash in CI (no secrets in CI, accepted) | nit | revisit at B13 | open |
| 12 | S01 security | Scheduled workflows stop after 60 days without repo activity (weekly NuGetAudit run) | nit | note | open |
| 14 | S01 security r2 | setup-dotnet.sh: unparseable URL port exits with a Python traceback instead of `die` (fails closed); cleanup trap quoting of `$work` | nit | next touch of the script | open |
| 15 | S01 security r2 | Optional: commit the expected .NET SDK sha512 next to `global.json` (today the hash comes from the same Microsoft host) | nit | backlog | open |
| 16 | S02 | Docker Hub anonymous pull limits on CI runners: if they bite, cache images (`docker save` + `actions/cache` keyed on digests) or mirror to GHCR | minor | when seen | open |
| 17 | S02 | Verify Dependabot's `docker-compose` updater bumps `tag@sha256` in `tools/contract-tools/compose.yaml` | minor | after first run | open |
| 18 | S02 | Enum schema transformer for the Host (proven snippet in `backend/README.md`) | minor | first step with an enum | open |
| 19 | S02 | Tag ruleset protecting `contracts-v*` (no update/delete), owner clicks | minor | A43 (first tag) | open |
| 20 | S02 | Move `Host/Config/` (`GET /v1/config`) into the Account module, same operationId + tag | minor | B04/A35 | done (S03) |
| 21 | S02 | Contract.Tests: validate runtime responses against the bundled schema generically, once there are several endpoints | minor | ~B05 | open |
| 22 | S02 | Host build prints an MVC "No action descriptors found" info line during OpenAPI generation; filter in logging config | nit | S03 | done (S03) |
| 23 | S02 r2 | contract-breaking.sh blocking mode: pass oasdiff githubactions output through the same annotation-only filter as conformance | nit | next touch | open |
| 24 | S02 r2 | fb-problem-json-errors accepts only one `allOf` level of ProblemDetails extension; recurse if a nested extension is ever needed | nit | when needed | open |
| 25 | S02 r2 | fb-oneof-discriminator compares mapping count, not targets (resolved doc loses `$ref` identity) | nit | accepted | open |
| 26 | S08 | Portion word علبة (can/box) is ambiguous and not mapped by the parser; resolve with real data | minor | A05/A07 | open |
| 27 | S08 | Promote `ManualClock` from fb_domain test helpers to a shared test package if A01+ needs a fake clock | nit | A01 | open |
| 28 | S08 r2 | Parser: two quantities in a row via x-count or glued unit ("2 x2 eggs", "2 100g rice") should be null; pin cases | minor | A07 | open |
| 29 | S08 r2 | Parser: zero gives null without `original` ("Coke 0"); document that callers catalog-match the raw text on null, pin "Coke 0" | minor | A07 | open |
| 30 | S08 r2 | Ban list shorthand: `clock?.now()` false positive; `[.now()]` / `{.now()}` not caught; stripComments EOF backslash guard | minor | A01 | open |
| 31 | S08 r2 | End-quantity-wins rule also applies to English implicit start portions ("cup of tea 2 tbsp"); document or pin | nit | A07 | open |
| 13 | S01 | Spec tidy: add a Release column to the UX-/AQ- tables, then drop the trace overrides | minor | owner, later | open |
| 32 | S06a review | Android hardening for the first APK: cleartext only in the dev build and only for 127.0.0.1/localhost (`network_security_config` in the dev source set); release not debuggable; `allowBackup`/`dataExtractionRules` exclude the install device id (a restore must not clone it); signing files out of git | minor | S06b | done (S06b WP4, review r1) |
| 33 | S06a review | `tools/trace` scans only `test/` and `integration_test/`: add `patrol_test/` | minor | S06b | done (S06b WP5) |
| 34 | S06a security | Before setting a Sentry DSN: native (Java/NDK) event scrubbing or `enableNativeCrashHandling=false` (A5); Sentry project with "Prevent storing IP addresses", server-side scrubbing, EU region | minor | B13 | open |
| 35 | S06a UX | Tab placeholders are text only, with an AppBar repeating the tab name; replace them with designed empty states, and drop the plain title bar on Today (16) | minor | A02/A08 | open |
| 36 | S06a UX | Update-required screen: tell R1 sideload users where to get the new build (once the release channel exists) | minor | A11 | open |
| 37 | S06a review | app_check rule: only `app/app_scope.dart` may import `package:fb_domain/system.dart` | nit | next touch of app_check | open |
| 38 | S06a architect | app_check rule for "only ChangeSetApplier writes user tables" (`03` §5, `10` §3); decide whether `presentation-io` extends to `application/` for `core/db` | minor | A01 | open |
| 39 | S06a architect | Small read facade over `clientConfigProvider` (`isEnabled(flag)`, `threshold(key, fallback)`) so presentation never names the generated DTO | minor | first flag/threshold consumer | open |
| 40 | S06a security r2 | Native Android Sentry logs/metrics are forced on in sentry_flutter 10: add a native `beforeSendLog`/`beforeSendMetric` that drops everything, keep the Gradle plugin's logcat instrumentation off | minor | B13 | open |
| 41 | S06a security r2 | The auth (`Authorization`) interceptor reuses `ClientHeadersInterceptor.isApiOrigin` (or a shared helper), so tokens never leave the API origin | minor | A20 | open |
| 42 | S06a security r2 | Route paths are kept in navigation breadcrumbs: route paths must never carry user data (food names, free text) | nit | every routing step | open |
| 43 | S06a fix r1 | If `/v1/config` answers 426 for old versions, `refresh()` should report it, so the update screen says "still old", not "are you online?" | minor | S03 | done (S03) |
| 44 | S06b WP4 | Plugin native libs ship for 3 ABIs while the Flutter engine is arm64 only: add `abiFilters` (arm32 phones could install then crash) | minor | before R2 / A43 | open |
| 45 | S06b WP4 + security | DB backup policy (AC-040–044): the local DB goes to Google backup/device transfer by default (`allowBackup=true`, only prefs/datastore excluded). Decide explicitly; if backed up, `disableIfNoEncryptionCapabilities="true"` on `<cloud-backup>`. Also the Android 16 QPR2 `cross-platform-transfer` section | minor | A01 | open |
| 46 | S06b WP6 | Signing passwords are in the Gradle build env (plugin/Maven code could read them): build unsigned, then sign with `apksigner` in a separate step; together with Gradle dependency verification (`gradle/verification-metadata.xml`, sha256, refreshed on each bump) | minor | before A43 | open |
| 47 | S06b WP6 | Actions cache could approach the 10 GB repo limit (Flutter, pub, Gradle per job, AVD, NuGet): check usage after the merge | minor | after S06b merge | open |
| 48 | S06b | Owner skipped backing up the release key (2026-10-15, accepted: regenerating costs one uninstall). Remind to copy the key + password off the laptop before real data: the owner's daily prod build is signed with it from A11 (TD-064) | minor | before A11 | open |
| 49 | S06b security | `dart pub global activate patrol_cli 4.8.0` resolves its transitive deps fresh in CI (no lockfile); job has no secrets. Accepted; later activate from a path package with a lockfile | nit | backlog | open |
| 50 | S06b review | Dependabot has no `gradle` ecosystem: AGP, KGP, androidx orchestrator and the Gradle wrapper get no update/security PRs | minor | A02 or next platform touch | open |
| 51 | S06b review | A43: decide sideload builds vs Play upload key (the CI pin is the app-signing cert); verify the AAB manifest too, not only the APK | minor | A43 | open |
| 52 | S06b r2 | apk_hardening_check keys `<application>` attributes by namespace+name: reject an attribute with an android resource id but no android namespace (only a hand-crafted binary can produce it) | nit | next touch | open |
| 53 | S03 review r1 | Unsupported `Accept` (e.g. `text/html`) makes framework problem writing decline and status pages return text/plain for 400/404. Current app JSON requests are unaffected. Guarantee problem+json (or define explicit negotiation) across middleware, status pages and exceptions, with unsupported-Accept tests. | minor | B04 / next HTTP-pipeline touch | open |
