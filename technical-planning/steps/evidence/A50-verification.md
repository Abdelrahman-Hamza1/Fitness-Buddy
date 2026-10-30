# A50 verification (2026-10-30)

Google sign-in on the phone: `google_sign_in` 7.2.0 behind A33's
`GoogleIdTokenSource`. Tier Risky. No contract, backend, spec or Accepted-TD
change. Local evidence only (TD-108): the merge run is the CI evidence.
No token, email, client ID or other secret appears here.

## Exit criteria → tests

| Exit criterion | Evidence |
|---|---|
| Sign-in with a fake source passes the sign-in journey | T12 host replay `AC-001 AC-003 host replay: a guest upgrades with Google (fake source), same data and user id` (passes locally; it seeds a diary entry and checks it survives unchanged). T13 Patrol `AC-001 AC-003 guest upgrades with Google via a fake token source, keeps data and user id` (compiles; runs in the next nightly or manual `android-it`, TD-086) |
| The plugin adapter has a unit test | T1–T7 in `test/core/account/google_plugin_id_token_source_test.dart` (10 cases) |
| Owner A55 check against the laptop server (collected, non-blocking) | Pending, optional under D-087(b). See "Owner A55 check" below |

Other tests: T8/T9 + the Google-refusal case in `account_service_test.dart`;
T10 `app_config_test.dart`; T11 `build-android-selftest.sh`; T14
`sign_in_screen_test.dart`; the `biometric-permission` fixture in
`apk-hardening-selftest.sh`.

## Security and data-integrity checks

| Concern | How it is held | Proof |
|---|---|---|
| Nothing written without confirmation / undo | Google only yields an ID token; all writes stay in A33's `AccountTransitions` (unchanged) | T8, T9 (`AC-002 a Google failure leaves the guest untouched`: no server call, no session, registry unchanged) |
| No user content in logs (rule 6) | `GoogleIdTokenException.toString` shows the kind only; the adapter catches every plugin error (no `PlatformException` reaches Sentry's unhandled hook); `account.email`/`displayName`/`photoUrl` never read; `GoogleSignInAuthentication.toString` (prints the token) never called | T6 `Rule:09.4-no-content-logging google failures carry no token or plugin text` |
| Plugin initialized exactly once (7.2.0: a second `initialize` is undefined) | One process-wide kept future in `PluginGoogleSignInDriver`, failures kept and never retried; the adapter keeps its own single attempt too | T2 + `the production driver initializes the plugin once per process with the web client id; a failure is kept and shared` |
| Sign-out can't be blocked (AC-004) | Adapter sign-out: no-op unless initialized; one 5 s timeout; swallows errors. `AccountService.signOut` also guards it | T5, `AC-004 sign-out completes when Google sign-out throws` |
| Local-first startup (rule 3) | Provider construction does nothing; init on the first `idToken()` only | T2 ("construction does nothing"), T7 |
| Client ID only where it can work | `FB_GOOGLE_SERVER_CLIENT_ID` merged only into staging/prod release builds signed with the release key (decided after signing is resolved); debug, debug-key release and dev always `""`; validated with the B04 regex; never printed (logs say "on/off" + source) | T11 (incl. a canary grep of the build output) |
| Fail-closed config | Missing key → `AppConfigException`; malformed non-empty value rejected; error text never carries the value | T10 + the existing AppConfig privacy test (iterates every key) |
| Server-refused Google token | 400/401 on the Google paths → `rejected` ("Try again"), email keeps `invalidCode` | `AC-001 a Google token the server refuses is a sign-in failure, not a wrong code` |
| No extra Android permissions | `androidx.credentials` 1.6.0 → `androidx.biometric` 1.1.0 asked for `USE_BIOMETRIC`/`USE_FINGERPRINT`; removed with `tools:node="remove"`. Merged prodRelease manifest (`processProdReleaseMainManifest`, 2026-10-30): only `INTERNET` and the androidx.core `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. `apk_hardening_check.py` now fails a release that has either | `apk-hardening-selftest`: 27/27 incl. `biometric-permission` |
| Dependency pin | `google_sign_in: 7.2.0` exact (BSD-3, flutter.dev); lock sha256 `521031b65853b4409b8213c0387d57edaad7e2a949ce6dea0d8b2afc9cb29763`; resolves `google_sign_in_android` 7.2.18 (+ ios 6.3.8, web 1.1.3, platform_interface 3.1.0, `google_identity_services_web` 0.3.3+1). No Firebase, no `google-services.json` | `pubspec.lock` |

## R8 (PA3): fallback evidence

The release keystore is on the laptop, but both `make build-android FLAVOR=prod
FB_BUILD_AAB=0` runs (through heavy.sh) were OOM-killed inside
`minifyProdReleaseWithR8` (kernel log: Gradle daemon ~2.5 GB RSS, swap full
from other lanes). Evidence instead:

- `androidx.credentials:credentials-play-services-auth:1.6.0` consumer rules:
  `-if class androidx.credentials.CredentialManager` →
  `-keep class androidx.credentials.playservices.CredentialProviderPlayServicesImpl { *; }`.
- `androidx.credentials:credentials:1.6.0`: "safe to shrink" (empty rules);
  `googleid:1.2.0`: only `-dontwarn module-info`. The plugin calls `googleid`
  classes directly (no reflection).
- Merged prodRelease manifest declares `androidx.credentials.CREDENTIAL_PROVIDER_KEY`
  → `CredentialProviderPlayServicesImpl`; AAPT's rules keep
  `CredentialProviderMetadataHolder` and both hidden activities.

Conclusion: no explicit keep rule needed. The merge CI build is the first full
R8 pass with these libraries; real provider execution is the owner A55 check.

## Review

| Round | Reviewer | Verdict | Findings | Status |
|---|---|---|---|---|
| Plan | Codex | Changes requested → amended (PA1–PA4) | 2 major, 2 minor | Fixed in the plan |
| Code (combined code + security, round 1) | Codex | **APPROVE** | 0 blocker / 0 major / 3 minor | All 3 fixed in `172ee4f` (no fix-check: minors) |

Minors: biometric permissions (removed + hardening check), Google 400/401
message (`rejected`), host journey data check (seeded entry survives).

## Owner A55 check (optional, non-blocking)

Laptop server on + Tailscale connected → `make build-android FLAVOR=prod` +
`make install-android FLAVOR=prod` over USB (the build reads
`google-clients.json` itself) → Me › Account › Sign in → **Continue with
Google** → pick the account → "You're signed in", the same diary (a guest
upgrade keeps the data). Claude then confirms `POST /v1/auth/link/google`
(or `/v1/auth/google`) 200 in the laptop API log, without token or email in
the evidence; on failure, `adb logcat` for the Credential Manager reason.
This is also the only check of risk R1 (which package the Android OAuth client
was registered for). Status: **pending**.
