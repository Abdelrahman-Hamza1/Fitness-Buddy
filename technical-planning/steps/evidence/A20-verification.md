# A20 verification (2026-10-23)

WP1–WP4 are implemented. **PA1 restart checks and automated PA2 40 kill
cycles passed on 907a550 (android-it green), as reported by Claude.** Receipt:
CI run https://github.com/Abdelrahman-Hamza1/Fitness-Buddy/actions/runs/39948124422 on 6526a0e (strict comparison; two `base64_wrapping_only` notices). The strict follow-up passed in that run. Comparison means **stored Base64 content
identity, line breaks ignored**; neither pointer re-encryption nor key re-wrapping
was observed. The manual PA2 matrix is not executed (deferred by the owner, 2026-10-23, to before A33 registered accounts; backlog #94). The independent security re-check of this
evidence (Claude) approved it. Earlier sections retain historical receipts and investigations;
the current status here supersedes their pending/failing automated-native claims.
No git writes or live Identity/model calls here.

## Exact-release selection gate (PA1/PA2)

- Exact app dependency `flutter_secure_storage: 11.2.0`, shared root lockfile.
- Inspected the extracted publisher archive, not `develop`:
  [release](https://pub.dev/packages/flutter_secure_storage/versions/11.2.0),
  [version metadata](https://pub.dev/api/packages/flutter_secure_storage/versions/11.2.0),
  [source archive](https://pub.dev/api/archives/flutter_secure_storage-11.2.0.tar.gz).
- Independently downloaded archive SHA-256 equals publisher metadata, pub cache
  hash and lockfile: `d4e1fb6b2cb524868929e78dc0282fa000554b22060fb53789dc481c9fc95bb8`.
- `session_storage_release_test.dart` hashes the inspected files below on every
  mobile test run, checks the exact dependency/lock hash, native store mapping and
  source backup exclusions. A version/source mismatch requires a fresh audit.

| Release file | SHA-256 |
|---|---|
| `lib/options/android_options.dart` | `18bcd09b5444a5f2b8651b4d84995e83148b7521e1616ca6351ed2e1709da86e` |
| `android/build.gradle` | `0013e75fdbf4ec4c80db514f5d01bd966fdcbbd9f65e115835e184266b2858fb` |
| `android/src/main/java/com/it_nomads/fluttersecurestorage/FlutterSecureStorage.java` | `fe83c8fe978f0bc4e66a8cfe33d020b484683fe837a3e53fd6945a2cba758ed3` |
| `android/src/main/java/com/it_nomads/fluttersecurestorage/FlutterSecureStoragePlugin.java` | `bcf44e85c3f4cca0a26a23b11152c198db1c9d8f2fda70c29ed531b7dc8923ae` |
| `android/src/main/java/com/it_nomads/fluttersecurestorage/FlutterSecureStorageConfig.java` | `0ae8ff90d2a7d20605b989e970d9d5908099ec6729a5224785e5499a6cec55e0` |
| `android/src/main/java/com/it_nomads/fluttersecurestorage/NamespacedConfigSource.java` | `efee7d10515b89c4818b675a6fc53dc9fc13a2f702f4c6988e6e5a92e33d40e6` |
| `android/src/main/java/com/it_nomads/fluttersecurestorage/ciphers/StorageCipherFactory.java` | `1b5aa836d15b42886885fbb05b6fac92244ffc11c2df75c41c133aec6baacb65` |
| `android/src/main/java/com/it_nomads/fluttersecurestorage/ciphers/StorageCipherImplementationGCM.java` | `d2a7a88658799fa529da57d98d942ce7fe8cc89df69f22e091c2280476f11c38` |
| `android/src/main/java/com/it_nomads/fluttersecurestorage/ciphers/LegacyNamespaceKeyRecovery.java` | `794f9eefe8216c6469f7bbee91416d77007217b3c4c261e927af0ce9bf1f2ece` |
| `android/src/main/java/com/it_nomads/fluttersecurestorage/ciphers/KeyCipherImplementationRSAOAEP.java` | `2de69a4ea9b7546ccc97ecfa175ce8d71a74e64553e4e2127fe3ac7e49bc6a46` |

### Recovery and mutation paths

`AndroidOptions` explicitly forwards `resetOnError=false`,
`migrateOnAlgorithmChange=false`, `migrateWithBackup=false` and fixed
`storageNamespace=fb.session.secure.v1` on **each** read/write/delete. The normal
non-biometric constructor uses RSA OAEP SHA-256 / AES-GCM (confirmed at the
platform boundary). No deleteAll/reset/default-options path exists in the app.

In this release, `FlutterSecureStorage.handleStorageError` returns false before
any deletion when reset is disabled; read/write return errors, not empty values.
`handleKeyMismatch` skips migration and deletion with these options and returns
an error. Other initialization exceptions return through the error callback.
`LegacyNamespaceKeyRecovery` may copy a verified wrapped key to the namespaced
key store, retaining the source; it does not delete envelopes or pointers. Its
write target is included below. RSA initialization may generate a missing OS
key, but a previously wrapped AES key cannot then unwrap and initialization
fails; ciphertext/pointer/markers remain. Native plugin exceptions include
messages/details: the store drops them and emits only fixed typed categories.
Plugin error logs can name preference keys, so envelope keys use a hashed server
id rather than a raw id; no credential/user content is used in key names.

`writeUnsafe` encrypts then `editor.apply()`, returning success through
`FlutterSecureStoragePlugin` immediately after that call. Delete also uses
`apply()`. Awaiting Dart success therefore does **not** establish persistence.
Cipher factory initialization writes algorithm metadata with `apply()` and
`StorageCipherImplementationGCM` writes its wrapped AES key with `apply()`.

### Native mapping and durability

The namespace option resolves via `FlutterSecureStorageConfig` and
`NamespacedConfigSource` to these application-context **MODE_PRIVATE** files:

| Commit order | Preference name | Relevant contents |
|---|---|---|
| 1 | `FlutterSecureKeyStorage:fb.session.secure.v1` | RSA-wrapped AES key, including namespace-key recovery target |
| 2 | `FlutterSecureStorageConfiguration:fb.session.secure.v1` | Algorithm metadata |
| 3 | `fb.session.secure.v1` | Encrypted envelopes, pointer, recovery intent |

Legacy global config is read-only fallback; the new app namespace has no legacy
session data. No session writes target the global legacy config/key stores.
Keystore alias: application package + `.FlutterSecureStoragePluginKeyOAEP` +
`.fb.session.secure.v1`; OS Keystore material is not an app backup file.

`SessionStorageCommitter` commits a changed `long` under
`fb_session_commit_barrier_v1` in each mapped file. This key is outside the
plugin's encrypted-key prefix. `SessionStorageDurability.kt` runs this work on
one background executor and posts only a boolean on the main thread. Channel
`fitness_buddy/session_storage`, method `commit`, accepts no arguments. There is
no path/key/token input or arbitrary store access. Only all-three-success is an
acknowledgement. Dart has a 10-second timeout; false/null/error/timeout fails
closed. The store latches failed mutations unavailable, so a late acknowledgement
cannot publish or release usable credentials.

Android documents that synchronous `commit()` waits for outstanding `apply()`
work on the same SharedPreferences and reports disk success:
[SharedPreferences.Editor.apply](https://developer.android.com/reference/android/content/SharedPreferences.Editor#apply()).
This is the platform contract, not a claim about hardware failure or collected
process-kill evidence.

Every store operation is serialized. Save order: encrypted recovery intent +
barrier → complete envelope + barrier → pointer/kind + barrier → delete intent +
barrier → caller completion. Selection uses intent/pointer/clear with barriers.
Deletion removes only the chosen envelope with a barrier and retains the active
pointer/kind. Reads validate schema version, namespace, identity hash, kind,
complete token pair and pending flag. Exceptions never mean no account; a
readable registered marker survives corrupt/missing credentials. Any interrupted
intent makes all operations unavailable on reopen; it is never automatically
cleared or interpreted as absence. Later WPs must not bypass this error to
acquire a guest or resend a token. Registered expiry persists as a registered
envelope with no credentials; rotationPending persists in the same envelope.

### Android compatibility and backup

Inspected actual release `android/build.gradle`: **minSdk 24**, Java 17,
Flutter-provided compileSdk, Java-only implementation, inherited Android library
plugin (no separate Kotlin/AGP pin). This differs from the package README's
older minSdk 23 statement. App: minSdk **26**, Java/JVM **17**, Kotlin **2.4.0**,
AGP **9.1.0**, Gradle **9.3.1**, Flutter **3.47.7**. Static requirements align;
only the real Android build can confirm dependency resolution, Java/Kotlin
compilation, manifest merge and runtime method-channel/plugin registration.

Existing manifest references `backup_rules` and `data_extraction_rules`.
Both already exclude `sharedpref/.`; that covers all three plugin/barrier files,
legacy stores and their metadata under cloud backup, device transfer and the
Android 16 cross-platform transfer rules. Existing device-id DataStore/profile/
catalog exclusions remain. Added comments only. Installed/merged verification
is pending Android build/WP5; no release TLS rule changed.

## Public seams and deviations

- `SessionState`, status/kind/readiness enums and redacted `SessionStorageFailure`.
- Core-only `SessionEnvelope`/`SessionCredentials` (redacted toString); never put
  them in public Riverpod state or reporters. WP2 consumes them privately.
- `SecureSessionStore`: `accountKey`, `readActive`, `read`, `save`, `select`,
  `remove`; injected `SessionSecretStorage` and `SessionStorageDurability`.
- `PluginSessionSecretStorage`, `AndroidSessionStorageDurability`; no providers.
- Additional encrypted **recovery-intent** marker closes the orphan-envelope /
  first-pointer crash window required by PA2's partial-completion rule. It holds
  only opaque key and kind and is non-destructively retained on failure. Account
  key suffix hashes the server id to prevent native key-name logs revealing it.
  There is still one credential envelope per account, scoped by flavor and
  canonical scheme/host/effective port. No coordinator behavior implemented.

## Host evidence and outstanding execution

- Storage tests cover mutation/barrier order and failure at all four save phases,
  serialization, lost acknowledgement, account/origin/flavor isolation, canonical
  ports, expired registered/pending restart, corrupt/mismatched data, interrupted
  first registered save, retained pointer/kind, explicit option forwarding,
  redacted errors and exact-release mapping. Fakes do not prove Android crypto or
  SharedPreferences disk behavior.
- `bash apps/mobile/android/test-session-storage-host.sh`: **6 cases passed**
  using pinned JDK 21. Ordered all-file success, each of three commit failures,
  exception and held-work/no-early-acknowledgement. Pure Java ordering seam only.
- `make deps-dart`: passed; six new resolved packages, exact root-lock archive
  hash recorded above. No unrelated dependency bumps.
- `make check-dart`: passed; formatter 758 files unchanged, analyzer no issues,
  app_check 177 mobile / 39 design-system source files, frozen-migration checks,
  and 4 Python offline-source tests passed.
- `make test-dart` final run: **1,233 passed, 1 skipped across 10 packages**
  (mobile 503, API client 16, design system 135, domain 263, text 56, app_check 71,
  catalog 137, trace 33, Buddy eval 11, sync simulator 8). The mobile total
  includes **27 WP1 tests**. The existing local-API test is skipped because it
  requires port 5198; no live API pass claimed. Domain/text line coverage both
  100%; minimum 95%.
- `make trace`: passed; 319 R1 requirements, 115 covered, 204 missing; existing
  unknown `ZZ-060` scanner-fixture warning. No coverage regression claimed.
- `make gen-app`: not applicable; no provider/generated-output changes.
- `git diff --check`: passed. No repository git writes.
- `make build-it`: **failed before app compilation** in Gradle, “The settings are
  not yet available for build.” No Android compatibility/runtime pass claimed.
  Claude must rerun it and inspect merged/installed manifest/rules. WP5 owns
  native corruption/invalidated-key tests and process-kill receipts on the same
  installed app (including apply-returned/disk-held); no device test claimed.


## WP2 coordinator and generated auth transport

Implemented `core/session/{auth_transport,session_clock,session_service,
session_providers}.dart` and generated providers. No contract/generated API
client, storage plugin/options, native code, dependencies, interceptor or
bootstrap/lifecycle wiring changed.

Public seams:
- `sessionStateProvider` exposes token-free state. Watching it, constructing the
  service or calling `ensureAvailable` before explicit post-frame startup does
  no storage/network I/O. Injectable service/store/transport/clock/auth adapter
  providers are keepAlive. Auth Dio has its own adapter, client headers and
  upgrade signaling; no dependency on normal Dio and no auth interceptor.
- `SessionService.startAfterFirstFrame`, `ensureAvailable`,
  `refreshIfCurrent(generation)`, `acceptAuthenticatedSession(AuthTokens)`,
  `state`, `nextAttemptAt`, `dispose`. `SessionLease` is a redacted **core-only**
  request credential with generation and opaque account reference; never
  publish it as state or diagnostics. WP3 must compare account references
  before replay and enforce one replay. A33 must coordinate its database
  selection/merge separately before calling acceptance.
- `AuthTransport` / `GeneratedAuthTransport`, `AuthFailure`, `SessionFailure`,
  and injected `SessionClock` (existing app wall clock plus stopwatch elapsed
  time). Failures retain no raw exception/request/response/generated object.

Properties and fake-based evidence:

| Test file under `apps/mobile/test/core/session/` | Evidence |
|---|---|
| `session_service_test.dart` | Ten concurrent acquisitions/401s; stale 401; timed-out waiter; pending barrier before send; all four pending/rotated-save barrier failures; pair acknowledgement before readiness; terminal guest recovery vs durable registered expiry/restart; pending restart and death after server consumption; lost response cooldown; unreadable registered storage; late results and queued mutations fenced by A33; acceptance failure; mismatched response identity; disposal |
| `session_service_test.dart` | PA3 sequential callers/401s immediately before and at deadlines, exponential 1–60 s progression, >60 s floor, auth-success-only reset, failed guest-recovery acquisition uses same deadline; wall skew ±40 days, wall jumps during/after issuance, past issuance dates and monotonic freshness cap |
| `auth_transport_test.dart` | Actual generated anonymous/refresh routes/body; no bearer/redirect/replay; terminal problem/status catalogue, unknown/malformed outcomes, connection/send/receive timeouts, 426 upgrade signal, Retry-After delta/date/malformed conversion and redacted generated-parser errors |
| `session_providers_test.dart` | Safe watch and service construction have no auth/storage I/O; committed token-free state publication |
| `session_data_test.dart` | Real drift diary fixture and full row/outbox snapshot unchanged by terminal guest/registered recovery; outbox remains populated |
| `session_fakes.dart` | Shared deterministic ports; no live server/identity/provider calls |

PA2 uses the existing WP1 store exclusively: save pending envelope and await all
barriers before physically sending refresh; save rotated pair/pointer and await
all barriers before readiness or waiter release. All coordinator mutations and
A33 acceptance serialize. An ambiguous result keeps pending; a deadline never
makes an old secret safe. Known pre-handler 429 and Dio connect-timeout/TLS
rejection can clear pending **with barriers** because no Identity consumption
occurred. Generic connection errors, send/receive timeouts and 5xx do not prove
this and retain pending. Restart or later recovery uses a new guest or durable
registered-expired marker, never resends the ambiguous credential. Interrupted
storage mutations remain typed unavailable, with no automatic storage retry.
A fully committed new pair may be restored after lost final acknowledgement;
it is the **consumed old secret** that must never be resent.

PA3's one monotonic deadline gates all current automatic methods, including
sequential callers between flights. Retry-After converts once at receipt,
retains an uncapped floor, and only successful auth resets pacing. WP4 must route
resume/reachability/timer wakeups through this gate; no timers or lifecycle
callbacks were installed in WP2. Clock expiry hints never expire an account:
restore asks the server once, refresh expiry hints do not reject locally, and
new access freshness is bounded at 15 minutes in monotonic time (30 s margin
when the wall hint is plausible). Past/skewed issuance hints permit server use
rather than an immediate repeated-refresh loop.

No plan/scope deviation. WP2 additionally distinguishes provably undispatched
connection/TLS failures from ambiguous transport outcomes. Native corruption,
apply-returned/disk-held, external process-kill, merged manifest/rules and
installed channel/plugin behavior remain **unproven by these host fakes**;
Claude runs the WP5 Android evidence gate. Sink-wide Sentry/error-observer
canaries, interceptor replay/origin tests, lifecycle scheduling and enabled
Identity local-server receipt remain in their planned later WPs.

### WP2 gate receipts (2026-10-23)

- `make gen-app`: passed; committed-output generation performed normally;
  only the new `session_providers.g.dart` changes generated Dart. No hand edits.
- `make check-dart`: passed; 768 Dart files formatted without changes, analyzer
  no issues, app_check 182 mobile / 39 design-system files, frozen-migration
  selftest/check and 4 Python offline-source tests passed.
- `make test-dart`: **1,295 passed, 1 existing skip, 10 packages**. Mobile 565
  (includes **62 WP2 tests**), API client 16, design system 135, domain 263,
  text 56, app_check 71, catalog 137, trace 33, Buddy eval 11, sync simulator 8.
  Domain/text line coverage 100% (95% minimum). The mobile local-API opt-in
  skip remains; no live server result is claimed.
- `make trace`: passed; 319 R1 requirements, 115 covered, 204 missing; existing
  `ZZ-060` scanner-fixture warning only.
- `make deps-dart`: not applicable; no dependency or lockfile change.
- `make gen-check`: not applicable to WP2's unchanged generated API client;
  Claude stages the new provider output before the index-based freshness gate.
- `make build-it`: attempted; **failed before app compilation**, Gradle
  “The settings are not yet available for build.” Same host limitation as WP1;
  no Android build/runtime result is claimed. Claude must rerun Android/Patrol
  build, full Android CI and the planned WP5 native/plugin/process-kill tests.
- `git diff --check`: passed. Branch remains `step/A20-api-session`; all changes
  left in the working tree, no repository git writes.

## WP3 origin-bound interceptor and once-only replay

`core/api/api_origin.dart` is the shared exact scheme/host/effective-port
predicate used by client headers and auth. The factory installs a boundary
interceptor on both transports: force `followRedirects=false` on each request,
and strip Authorization case-insensitively on foreign and public requests.
Anonymous/refresh, config, JWKS and the other unauthenticated Identity routes
never start the coordinator or receive a bearer. Auth Dio has no auth
interceptor; provider integration uses the real generated auth client and proves
one acquisition/rotation without recursion, with the same lazy client headers.

`AuthInterceptor` is last in the normal API request chain, after asynchronous
client-header work. Private Expando request metadata records the lease and a
body snapshot; no caller extra can authorize a replay. A 401 joins WP2's flight
and PA3 deadline. Delayed old-generation responses use the committed new pair.
Only one same-account replay is allowed. Coordinator ownership/epoch and token
generation are checked again immediately before dispatch; even A33 acceptance
of the same account fences an older attempt. JSON collections are snapshotted;
null/scalars/bytes are reproducible. Streams, multipart, unknown body objects
and custom request encoders are not replayed. Query, method, headers, caller
extra, idempotency key, timeouts, callbacks and cancellation remain intact.
Cancelling one waiter leaves shared auth running and prevents its replay.

### WP3 property evidence

- **43 interceptor tests**, plus **1 new provider integration test** (44 added).
  Exact-origin/default-port/case positives; scheme/port/subdomain/lookalike/
  foreign negatives; caller Authorization stripped; foreign/public 401s never
  acquire/refresh; every public route and both transports' redirect overrides.
- Ten concurrent 401s plus a separately held delayed old-generation response
  produce one refresh and exactly one replay each. A second 401 stops. Guest
  replacement, A33 replacement during rotation and delayed A33 responses
  (including same-account acceptance) never receive the old request.
- PA2 fake barriers hold pending before the refresh send and rotated-pair before
  replay. A failed pair barrier sends no replay. PA3 throttling floor survives
  ten sequential resource callers and successful public transport responses.
- **Real host sockets**, 301/302/303/307/308: source receives initial and replay
  requests despite caller `followRedirects=true`; second origin receives **zero
  requests** for each code. Uses a real Dio IO adapter and loopback HttpClient,
  bypassing Flutter's mock only in these tests.
- Success/failing-refresh canaries inspect captured print, Flutter errors,
  token-free state and actual serialized Sentry transport envelopes using the
  production ErrorReporting configuration. Includes generated-token objects and
  request/response-bearing Dio errors: no synthetic secrets/content in sinks.
- Existing upgrade widget/config-resource tests now explicitly supply a ready
  fake session, so they continue to exercise real HTTP 426/problem signalling
  through the protected request path. No production bootstrap change.

### WP1 host-test CI correction

Converted `SessionStorageCommitterHostTest` from an undiscovered Java `main`
into six JUnit 4.13.2 tests. Added the explicit test-only Gradle dependency and
`make test-android-unit` (`:app:testDevDebugUnitTest`), called by the `android`
CI job after Flutter's release build initializes `android/local.properties`.
Removed the redundant `android/test-session-storage-host.sh`. Direct host
`javac` + JUnitCore with cached JUnit/Hamcrest passed **6/6**. This proves host
ordering/failure behavior; Android Keystore/disk/process-death claims still
require WP5's device evidence.

### WP3 gate receipts (2026-10-23)

- `make gen-app`: passed; only `api_providers.g.dart` changes generated output.
  No generated API-client/contract edits; no hand-edited generation.
- `make check-dart`: passed; 771 Dart files, analyzer clean, app_check 184 mobile
  / 39 design-system files, frozen-migration selftest/check and 4 Python tests.
- `make test-dart`: **1,339 passed, one existing skip, 10 packages**. Mobile
  609 (includes the 44 added WP3 tests), API client 16, design system 135,
  domain 263, text 56, app_check 71, catalog 137, trace 33, Buddy eval 11,
  sync simulator 8. Domain/text coverage 100%; existing opt-in local-API skip.
  Initial full run exposed five older resource-response tests without sessions;
  their fake-session setup was corrected and the full gate rerun successfully.
- Targeted interceptor/provider run: **45/45** (includes one existing provider
  test). Corrected upgrade startup test **1/1**, config tests **19/19**.
- Direct Java compilation + JUnitCore: **6/6 passed**. No native persistence
  claim; `make test-android-unit` stops before compilation with Gradle
  “The settings are not yet available for build.” Claude must run the Gradle
  target and confirm CI discovery/results (all six tests).
- `make build-it`: attempted, same pre-compilation Gradle settings failure.
  Claude must run Android/Patrol builds and merged backup rules/plugin/channel
  compatibility, plus WP5's separate native corruption/process-kill gate.
- `make trace`: passed; 319 R1 / 115 covered / 204 missing, existing `ZZ-060`
  scanner-fixture warning only.
- `make deps-dart`: not required; Dart dependency and lockfile unchanged.
  JUnit is an explicit test-only Gradle dependency, already cached locally.
- `git diff --check`: passed. All work remains uncommitted on
  `step/A20-api-session`; no git writes, live Identity calls or paid calls.

No product/plan deviation. The additional coordinator lease checks make the
planned same-account/generation replay fence explicit. Backlog #41 is ready to
close with WP3. Bootstrap/lifecycle remains WP4; remaining device evidence and
fresh independent code/security/app reviews remain with Claude.

## WP5 verification status (2026-10-23)

**PA1 and automated PA2 cycles passed (907a550; CI run https://github.com/Abdelrahman-Hamza1/Fitness-Buddy/actions/runs/39948124422 on 6526a0e (strict comparison; two `base64_wrapping_only` notices)).
Follow-up security re-check: approve (Claude). The manual PA2 matrix is deferred (#94).** Historical WP1–WP3 receipts above describe those WPs,
not the current device status. No live Identity or paid model calls were made.
WP4 added 30 host tests; its committed gate receipt is in the card Progress log.

### Security property to executable evidence

Paths below are relative to `apps/mobile/`; parameterized names denote every
listed variant, not just one representative. Host storage/auth/barriers/clocks
are fakes unless explicitly identified as real.

| Property | File:test name (or parameterized prefix) | Boundary / remaining evidence |
|---|---|---|
| No startup I/O; first frame and offline diary independent of Sentry/config/auth | `test/core/session/session_service_test.dart:UX-001 construction and pre-frame ensure perform no I/O`; `test/app/session_bootstrap_test.dart:UX-001 AC-002 post-frame isolation: hung ...`; `test/core/session/session_providers_test.dart:UX-001 watch state and build service are lazy and token-free` | Real widgets/providers and local DB, fake network/storage/startup services |
| Per-origin/flavor/account isolation; pair/pointer ordering | `test/core/storage/secure_session_store_test.dart:AC-001 origin/flavor/account isolation and canonical effective port`; `AC-001 pair barrier precedes pointer barrier and publication` | Fake secret store/barrier; real hashing/serialization/queue |
| Registered markers and pending survive reopening | Same file: `AC-001 registered expired and rotationPending survive reopen`; `AC-001 interrupted first registered save retains recovery identity`; `AC-001 readable registered pointer survives malformed credentials` | Service recreation, not process death |
| PA1 non-destructive options on every operation; failure is never absence | Same file: `AC-001 plugin boundary forwards non-destructive options`; `AC-001 key-unwrapping exception retains bytes and never means no account` (also initialization/decryption); `test/core/session/session_service_test.dart:AC-001 unreadable registered storage never acquires anonymous` | Actual plugin Dart adapter with fake method channel, plus fake native faults. Real plugin faults and restart checks passed in android-it on 907a550; CI run https://github.com/Abdelrahman-Hamza1/Fitness-Buddy/actions/runs/39948124422 on 6526a0e (strict comparison; two `base64_wrapping_only` notices) |
| PA2 barrier failure/lost ack cannot publish or send | Storage tests: `AC-001 barrier 1 failure never publishes or retries` (1–4); `AC-001 lost barrier acknowledgement times out`; service tests: `Rule:04.5-session-rotation pending barrier precedes physical send`; `AC-001 pending commit 1 failure sends zero refreshes` (1–4) | Host fakes plus real-plugin Patrol native false/lost channel acknowledgements (zero refresh/anonymous sends); six native committer JUnit ordering cases. Held disk-writer proof remains manual below |
| PA2 consumed refresh never resent; pending retained through ambiguity | Service tests: `AC-001 death after consumption never resends old secret`; `AC-001 pending restart registered=true never resends` (true/false); `OF-01 lost response registered=true retains pending in cooldown` (true/false) | Host consumption ledger plus adb pending restore with zero sends and rotated-pair survival, 20 kills each. Additional interrupted-write matrix remains pending below |
| Acquisition and rotation single flight, stale generation fenced | Service tests: `AC-002 ten concurrent acquisitions share one durable flight`; `Rule:04.5-session-rotation ten 401s and stale 401 rotate once`; `Rule:04.5-session-rotation A33 acceptance fences late network result` | Fake transport with held futures |
| Safe same-account bounded replay; payload/key/cancellation preserved | `test/core/api/auth_interceptor_test.dart:AC-001 replay preserves payload query options key and cancellation`; `AC-001 second 401 stops after one replay`; `AC-002 guest replacement never receives original request`; `AC-001 A33 acceptance fences delayed request sameAccount=...`; `Rule:04.5-session-rotation ... is never replayed`; `AC-002 cancellation of one waiter leaves shared refresh alive` | Real Dio/interceptor, fake HTTP adapter |
| Exact origin only; public/foreign bearer stripped; redirects disabled | Same file: `Rule:TD-053-api-origin bearer on exact origin ...`; `Rule:TD-053-api-origin foreign 401 strips bearer ...`; `Rule:TD-053-api-origin public request never authenticates ...`; `Rule:TD-053-api-origin socket 301 redirects reach no second origin` (301/302/303/307/308) | Origin tests use fake HTTP; redirect tests use real loopback sockets and real IO adapter |
| Registered expiry cannot become guest or mutate diary/outbox | Service tests: `AC-001 pending restart registered=true never resends`; `test/core/session/session_data_test.dart:OF-01 terminal auth registered=true leaves diary/outbox intact` (true/false) | Real Drift fixture with full row/outbox snapshot, fake auth |
| PA3 shared monotonic pacing, uncapped throttle floor, auth-success-only reset | `test/core/session/session_service_test.dart:Rule:04.5-session-rotation PA3 paces ten sequential callers`; `Rule:04.5-session-rotation Retry-After survives wall jumps`; `test/core/session/session_retry_scheduler_test.dart:AC-002 Rule:04.5-session-rotation PA3 foreground scheduler offline: sequential callers, public successes and resume bursts retain one deadline, one flight and one timer` (offline/503/429) | Fake scheduler/clock; actual scheduler/coordinator; lifecycle widget tests exercise binding callbacks |
| Clock skew cannot invalidate identity or create refresh loops | Service tests: `AC-001 wall jump during issuance cannot cause an auth loop`; `AC-001 wall jumps never extend monotonic access freshness cap` | Fake clock and transport |
| Generated transport, terminal/transient error classification and Retry-After | `test/core/session/auth_transport_test.dart:AC-002 generated anonymous and refresh requests use existing contract`; `Rule:04.5-session-rotation HTTP-date converts once to monotonic deadline`; `Rule:09.4-no-content-logging malformed generated body never escapes`; `test/core/session/session_providers_test.dart:AC-001 provider auth transport rotates without interceptor recursion` | Real generated client/Dio, fake HTTP |
| No canaries in print, Flutter errors, safe zone errors, observer/state strings, serialized telemetry | `test/core/api/auth_interceptor_test.dart:Rule:09.4-no-content-logging interceptor sinks fails=false` and `fails=true`; `test/core/session/session_privacy_test.dart:Rule:09.4-no-content-logging plugin zone provider and serialized sinks` | Success/failing refresh; real plugin Dart adapter with channel exception; generated object's raw toString intentionally contains canary and is scrubbed at reporting. Production Sentry configuration + SDK serializer + fake transport, no network. Observer inspects actual provider values. Flutter/zone paths receive the safe storage failure exposed by core; arbitrary raw content sent to print is not claimed safe |
| Real plugin roundtrip, fresh store, selection/removal and native true acknowledgement | `patrol_test/session_storage_test.dart:AC-001 real secure plugin round trip selection removal and commit barrier` | Real plugin/Keystore/native channel, pinned resetOnError:false adapter; execution receipt pending. Four additional Patrol cases inject ciphertext/key faults and false/lost acknowledgements |
| Real Identity issuance/me/rotation/reuse revokes rotated access | `test/core/session/session_local_api_test.dart:AC-002 local Identity issuance rotation reuse revokes family` | Opt-in, generated client, real server; Claude pass recorded below. Booleans/kinds/status/expiry relations only; raw transport/parser failures suppressed |

### Exact local Identity command (Claude)

From the repository root, with the private laptop server running on port 5199
and Identity enabled (no Buddy/model call):

```bash
cd apps/mobile
FB_LOCAL_IDENTITY_API=http://127.0.0.1:5199 /home/abood/development/flutter-3.47.7/bin/flutter test test/core/session/session_local_api_test.dart --reporter expanded
```

Alternatively use `--dart-define=FB_LOCAL_IDENTITY_API=http://127.0.0.1:5199`.
Without either value the test is skipped; this is not a live-server pass.
The sequence creates a disposable anonymous family and revokes it by reusing
its old refresh; no token is printed or included in assertion operands.

### Automated Android checks added after independent reviews

**PA1 and automated PA2 passed on 907a550 (android-it green), reported by
Claude; CI run https://github.com/Abdelrahman-Hamza1/Fitness-Buddy/actions/runs/39948124422 on 6526a0e (strict comparison; two `base64_wrapping_only` notices).** The strict comparison/notice and emulator guard follow-up passed in that run. No new device run
was executed in this sandbox.

| Requirement | Automated check | What it establishes on a green run |
|---|---|---|
| PA1 ciphertext corruption | Patrol `AC-001 native ciphertext failure retains identity and blocks acquisition` | Real production plugin saves registered envelope and kind-bearing active pointer; debug hook commits corrupt envelope ciphertext and recreates native plugin; fresh store/service reports typed storage failure/unavailable, zero anonymous/refresh sends, envelope and kind-bearing pointer retain stored Base64 content identity, line breaks ignored; pointer plaintext additionally checked; plugin internal values unchanged under the same comparison |
| PA1 deleted Keystore key | Patrol `AC-001 native key failure retains identity and blocks acquisition` | Deletes the exact namespaced RSA-OAEP alias after asserting it exists, verifies deletion, recreates native plugin (no cached AES key), then the same unavailable/retention/no-send assertions |
| PA1 after process restart | `session-native-evidence.py`, ciphertext/key phases then `check-ciphertext`/`check-key` | Each fault is checked before SIGKILL and after a new PID: envelope, pointer and plugin internals retain stored Base64 content identity, line breaks ignored; typed unavailable and zero auth sends. Ciphertext fault additionally checks pointer account key/kind through the production adapter. No data clear between fault and check |
| PA2 false and lost acknowledgements | Patrol `AC-001 native false acknowledgement prevents refresh send` and `AC-001 native lost acknowledgement prevents refresh send` | Real plugin seed, native barrier channel returns false or never replies; production 10-second timeout/poisoning produces typed unavailable and zero refresh/anonymous sends |
| PA2 pending survives process death | adb harness `pending` then `check-pending`, 20 iterations | Saves real pair, saves pending marker through all native barriers, signals ACKED; external SIGKILL/force-stop, new PID restores exact old pair with pending=true; fresh real coordinator expires registered session with zero refresh/anonymous sends |
| PA2 rotated pair survives process death | adb harness `pair` then `check-pair`, 20 iterations | Writes pending old pair then rotated pair through all barriers; after ACKED and external death, new PID restores exact new access/refresh pair, registered kind and pending=false |
| Release boundary and backup exclusions | `android` job `A20 release session safety on the built APK` | Scans packaged DEX/native/Dart artifacts for debug hook/probe markers; resolves merged manifest `fullBackupContent` and `dataExtractionRules` resource references and checks all packaged variants exclude shared preferences for legacy backup, cloud, device and cross-platform transfer |

`make build-it` / `make test-it` discover all five storage Patrol cases; ASCII
names contain no slash/semicolon and each has a four-minute timeout. Hooks live
in `src/debug/`, require the exact dev package at runtime, additionally gate
destructive fault/barrier methods on public Build emulator heuristics
(goldfish/ranchu hardware or emulator fingerprints), and have empty
release/profile source-set counterparts. They never expose raw values to Dart,
logs or CI. Only an isolated synthetic fixture may invoke destructive hooks.

After Patrol (including its existing single retry), `android-it` incrementally
builds `tool/session_durability_probe.dart` as a separate dev debug APK (four-
minute step limit), installs it on the API-34 emulator and runs the Python adb
harness (eight-minute step limit, seven-minute harness timeout). The harness
refuses physical devices/non-34 APIs, uses per-phase 25-second and per-adb
15-second timeouts, validates changed PIDs, and emits fixed `::error::`
annotations on failures. Forty durability cycles alternate SIGKILL via `run-as`
and `am force-stop`; two additional SIGKILL cycles cover PA1. `pm clear` runs
only before the full durability experiment and before each independent fault,
never between write/fault, kill and check. The signal file contains stage/status
only and is atomically replaced after acknowledgement. No logcat/prefs dump,
real auth or model calls. Added CI work is bounded to 12 minutes inside the
unchanged 45-minute job; actual total runtime still needs a CI receipt.

To rerun on a disposable API-34 emulator after building the probe:

```bash
adb install -r apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk
python3 -u tools/scripts/session-native-evidence.py
```

### Kind-marker evidence boundary (M2)

`save()` deletes the recovery-intent marker before the native fault snapshot.
Natively, account kind is therefore proven through the registered pointer plus
envelope; these fixtures do not prove retention of a present intent marker.
Intent-marker retention under failures is host-proven only. The harness's
“kind marker” refers to the kind carried by pointer/envelope, not a separate
retained intent entry.

### Plugin logging residual (M3)

Pinned flutter_secure_storage 11.2.0 calls `Log.e` with preference key names on
read failures, including in release. Our envelope keys contain `sha256(userId)`
and an origin namespace hash: pseudonymous identifiers, no tokens/content.
Dropping exception details at the Dart boundary does not suppress native logs.
Residual: wrap or filter those plugin logs before A33 registered accounts;
tracked in backlog #93. No plugin-log suppression is claimed here.

### Remaining manual native evidence (not passed)

The automated kill cycles establish **after-ack durability**, not behavior with
the actual Android disk writer deliberately suspended. No validated emulator
fault injector for that framework thread is supplied. The remaining PA2
interrupted-write matrix is **not executed; (deferred by the owner, 2026-10-23, to before A33 registered accounts; backlog #94)**. It must not be claimed as
passed by these tests:

1. On the isolated dev API-34 emulator, set a JDWP method breakpoint at
   `android.app.SharedPreferencesImpl.writeToFile`, suspending only the
   QueuedWork disk-writer thread. Confirm its targeting on that image. Use a
   Dart breakpoint in `SecureSessionStore._mutate` after `await action()` and
   before `await _durability.commit()` to establish plugin-returned/disk-held.
   Resume Dart while holding only the disk writer. With an isolated counting
   fake auth server, observe zero refresh sends and no completed barrier.
2. Release the writer: record barrier acknowledgement preceding the first
   send. In an independent fixture, force-stop while held and relaunch without
   reinstall/data-clear: registered identity must remain registered/expired or
   typed unavailable, never silently acquire anonymous. Record stage, PID and
   counts only.
3. Repeat external pause/kill at: after server consumption before response;
   after response before rotated-pair barrier; after pair/pointer barrier
   before publication; interrupted pointer and registered-expiry commits.
   Retain the fake server consumption ledger across app restart. Assert no
   consumed refresh is resent, no pre-ack pair becomes ready, and registered
   identity is retained or typed unavailable. A sleep in Dart or suspending
   every thread is not disk-held evidence. Host tests cover these coordinator
   branches, but cannot replace native receipts.

PA1 deletion models Keystore key loss; biometric enrollment/hardware-specific
key invalidation and OEM power-loss/filesystem behavior are outside this
API-34 process-death check. No hardware/power-loss pass is claimed.

### Remaining execution/review receipts

- PA1 restart checks and PA2 automated 40 kill cycles: **passed**, android-it
  green on 907a550; CI run https://github.com/Abdelrahman-Hamza1/Fitness-Buddy/actions/runs/39948124422 on 6526a0e (strict comparison; two `base64_wrapping_only` notices). receipt recorded;
  runs Kotlin compilation/CI for this strict follow-up. Release artifact checks
  and other Android receipts remain Claude-owned.
- Manual disk-held/interrupted-write matrix: **not executed**; (deferred by the owner, 2026-10-23, to before A33 registered accounts; backlog #94).
- Local enabled-Identity test passed: Claude receipt below.
- Prior independent code/security reviews: no code defects, evidence blockers
  per the current brief. New changes need their follow-up review; Claude's
  app-architecture review remains to be recorded.
- Collected owner acceptance (TD-037): A55 background anonymous readiness after
  first frame/offline diary check; record build/date/result without tokens.

### WP5 host gate receipts (2026-10-23)

- `make check-dart`: passed on final Dart sources; 782 formatted files unchanged,
  analyzer clean, app_check 187 mobile / 39 design-system source files, frozen
  migration checks/selftests and four Python offline-source tests passed.
- `make test-dart`: **1,370 passed, 2 skipped across 10 packages**: mobile 640,
  API client 16, design system 135, domain 263, text 56, app_check 71, catalog
  137, trace 33, Buddy eval 11, sync simulator 8. Both skips are opt-in local
  tests. Domain/text line coverage both 100% (95% minimum).
- After the full run, expanded the observer success-path assertion: targeted
  privacy rerun **1/1 passed**. Final change explicitly bypasses the global
  Flutter mock HttpClient in the opt-in test; a temporary synthetic loopback
  HTTP fixture ran that generated-client test **1/1 passed**, with anonymous=1,
  refresh=2, me=3 receipts. This validates the real IO adapter/route sequence,
  **not** the real Identity server's security behavior. Fixture is outside the
  repository; no laptop-server pass claimed.
- `make trace`: passed, 319 R1 / 115 covered / 204 missing; existing synthetic
  `ZZ-060` scanner-fixture warning remains.
- `git diff --check`: passed. No generated API/provider/dependency changes;
  gen-app/gen-check/deps-dart not applicable. All changes left in working tree.
- Android builds, native unit execution, device receipts, enabled-Identity run
  and reviews deliberately remain with Claude as listed above; not run here.


## Local Identity run (Claude, 2026-10-23)
`FB_LOCAL_IDENTITY_API=http://127.0.0.1:5199 flutter test test/core/session/session_local_api_test.dart` in `apps/mobile`, against the private laptop server with Identity enabled: **1 passed** (issuance, `/v1/me`, rotation, reuse rejection, family revocation). No tokens printed. The test sends the app's client headers and reads the app version from `pubspec.yaml` (the server answers 400 without headers and 426 below its minimum version).

## Native-evidence follow-up host gates (2026-10-23)

- `make check-dart`: passed; 783 files formatted, analyzer clean, app_check,
  frozen-migration checks/selftests and four offline-source helper tests passed.
- `make test-dart`: passed; **1,370 passed, two opt-in skips, ten packages**;
  domain and text line coverage both 100%. These are host tests, not Patrol.
- `make trace`: passed; R1 319 total / 115 covered / 204 missing, unchanged
  existing synthetic `ZZ-060` scanner-fixture warning.
- Release-checker self-tests: **3/3 passed**, including missing exclusions in
  each transfer mode and packaged debug channel/probe rejection. Python compile
  checks, workflow YAML parse and `git diff --check` passed.
- No Gradle, `make build-it`, `make test-android-unit`, emulator or CI execution
  performed here. Claude owns those receipts. No git writes, dependency changes
  or generated-code changes.

### PA2 iteration-1 timeout investigation (2026-10-23)

Audited `e16eb11..34ae53b`: the pending/pair cases, one-shot claim logic,
`pm clear` placement and force-stop/status-removal order are unchanged. The
pointer plaintext check is reached only by ciphertext fault phases. No direct
PA2 behavioral regression in that diff was established from source. An empty
status file alone cannot prove which intent executed or where it stopped.

The harness now requests `NEW_TASK | CLEAR_TASK` (`0x10008000`) as well as
force-stop, explicitly replacing retained task history while preserving app
data. This hardens a candidate failure mechanism: replay of an already claimed
write intent after the harness deletes its ACK file returns without a new ACK.
Claims remain one-shot, and no extra `pm clear` occurs between writes/checks.
Native debug claims now record only `CLAIMED` / `CLAIM_SKIPPED` in a separate
progress file, leaving final ACKs and snapshots intact on recreation. Timeouts
report the last fixed progress code (`no_status` / `invalid_status` otherwise).

The Python self-test runs real `main`, `launch` and `stop` against stateful fake
adb for all 20 pending and 20 pair iterations and both independent fault stages.
It checks fixture persistence, reset boundaries, PID changes, kill modes,
launch ordering and both fault-specific restart checks. A modeled retained
pending-0 intent on pending-1 reproduces the timeout when task-clear flags are
removed; this is a host simulation, **not confirmation of the CI device cause**.
Claude must rerun Gradle/CI; no native execution is claimed here.

### PA1 pointer writer trace and launch isolation (2026-10-23)

At `f3ef4d6`, Claude reports `check-fault iteration 0: FAIL:pointer_value`.
The only Dart pointer write is `SecureSessionStore._select`
(`secure_session_store.dart:320`), called by `save:363` and `select:372`.
`select` first requires a readable envelope. `save` is reached by the probe's
`ciphertext`/`key` fixture at `session_durability_probe.dart:72`; neither
`check-fault` nor `assertProbeUnavailable` calls it. Product `readActive`,
`_checkIntent` and `_readMarker` perform no storage mutations. The service
blocks on `SessionStorageFailure` before acquire/rotate/recover; its registered
pending recovery writes only after a successful envelope read. No product
restore/repair writer was found on an unreadable-envelope path.

The adb harness previously launched after SIGKILL without stopping the old
Android task. SIGKILL leaves the package unstopped, allowing Activity recreation
with the old write-phase intent. Replaying that fixture can write a fresh-IV
pointer and then put the same `invalid-ciphertext` envelope back. **This is a
source-based race diagnosis, not an observed replay receipt.** No emulator is
attached here, so the exact post-snapshot invocation remains unproven.

`launch` now force-stops the package before removing the status file and starting
the explicitly requested phase, without clearing app data. In addition, every
write phase claims a debug-only, fsynced per-phase/iteration file **before**
calling `save`; an Activity recreated with the same old intent returns before
any secure writes or status/snapshot replacement. This closes the interval
between SIGKILL and force-stop too. The existing fault snapshot is already after the
fixture's save and committed corruption; its timing and every raw-byte
comparison remain unchanged (pointer, envelope, intent/kind and plugin stores).
The external SIGKILL still occurs first, and the next launch still reads the
same installed app's stored data. No product storage options or reads changed.

Four host regressions use a write/delete-counting fake: readable registered
pointer with unavailable, malformed or missing envelope, plus retained recovery
intent. Two fresh store/service instances per case each cold-start and call
`ensureAvailable` three times; all must make zero writes, deletes, commits and
auth sends. Same-value writes are counted. A Python regression pins the launch
order, including force-stop before any status removal or new Activity launch.
A Dart channel test covers one-shot write claims, distinct iterations/phases
and check phases performing no claim. Native claim compilation/execution is
Claude's Gradle/CI gate.
**PA1 stays open until Claude's native rerun confirms or rejects the race.**

Host gates: `make check-dart` passed; `make test-dart` passed (1,377 tests,
two opt-in skips, 10 packages); session script self-tests passed 8/8;
`git diff --check` passed. No Gradle/CI execution or git writes.

### Native restart failure diagnostics (2026-10-23)

Claude reports native evidence committed as `09448dd`: all five Patrol storage
cases and all 40 PA2 kill cycles pass; first PA1 ciphertext restart check fails
with the old undifferentiated `FAIL`. **PA1 restart evidence remains failing;
its cause is not established by this source audit.** No Android rerun claimed.

- `session_durability_probe.dart` now emits `FAIL:<fixed-code>` from an explicit
  allowlist, including original assertion stages, `absent`, `present_readable`,
  `wrong_failure_kind` and a small fixed exception-type set. No messages,
  stack traces, dynamic runtime type strings or credential values are emitted.
  `session-native-evidence.py` validates stage/iteration and the same allowlist
  before including the code in `::error`; unknown output becomes `invalid_status`.
- Debug `SessionTestHooks.kt:43` already committed ciphertext corruption
  synchronously before acknowledging. Keystore deletion at line 50 calls the
  AndroidKeyStore service; verification now reopens the provider. Plugin
  replacement at lines 60–61 discards the cached AES key before checking the
  same-process fault. The native retention snapshot now also fsyncs before ACK.
  No missing ciphertext commit or memory-only key deletion was found.
- Exact pinned **11.2.0** local pub archive (hash gate above), paths relative to
  `android/src/main/java/com/it_nomads/fluttersecurestorage/`:
  `FlutterSecureStorage.java:51–83,163–179,241–286,353–438,1017–1073,1323–1369`;
  `FlutterSecureStoragePlugin.java:96–118,187–231,271–293`;
  `ciphers/StorageCipherImplementationGCM.java:28–54,88–107`;
  `ciphers/KeyCipherImplementationRSAOAEP.java:39–44,65–71,121–130`.
  The plugin caches storage instances/cipher keys, **not decrypted entry values**;
  each read fetches raw ciphertext from preferences. A new process opens prefs
  from disk and initializes the cipher again. Corrupt envelope ciphertext leaves
  cipher initialization intact, then read/decode/decrypt errors propagate without
  deletion (`resetOnError=false`). Missing RSA alias creates a new RSA key, but
  unwrapping the retained AES key fails during initialization. With both migration
  and reset disabled this returns an error before `containsKey`/read; the envelope,
  pointer and wrapped AES key remain. Even loss of the wrapped AES value generates
  a different AES key whose reads of existing ciphertext fail authentication.
  This source path does **not** silently return absence or wipe user entries.
- No production change justified yet. If rerun shows raw values present but
  successful-null production reads, that is a real PA1 defect: add a debug-free,
  narrowly scoped raw-presence check to the production storage adapter and map
  present-but-unreadable values to `SessionStorageFailure.unavailable`. Plugin
  `containsKey` itself initializes crypto first, so it cannot serve as an
  independent pre-initialization check. If initialization actually deletes values,
  a check *after* reading is insufficient: guard before initialization and replace
  or fix that plugin behavior. Never enable reset or acquire a guest as recovery.

Host gates for this diagnostic follow-up: `make check-dart` passed (784 files,
clean analyzer/app_check/frozen migrations, four offline helper tests);
`make test-dart` passed (**1,371 tests, two opt-in skips, 10 packages**);
`python3 -I -m unittest discover -s tools/scripts -p 'test_session*.py'`
passed **7/7** (four harness, three release-checker self-tests); diff-check passed.
Gradle and Android CI remain Claude's gates. No git writes.

### PA1 raw-value category diagnostics (2026-10-23)

Claude's follow-up CI result at `ae5092b`: PA2 kill stages and all 13 Patrol tests
pass; ciphertext fault reaches ACKED, but cold `check-fault` reports
`raw_values_changed`. **Cause (a) versus (b) remains unproven.** No emulator is
attached in this worker (`adb devices` empty), and Gradle/CI belong to Claude.
The former snapshot already selected only plugin-prefixed `fb.session.*` keys:
`SessionStorageCommitter.BARRIER_KEY` is outside that prefix, so a changing
barrier counter cannot explain that particular failure. No exclusion or product
option change is justified by the available evidence.

Rechecked pinned 11.2.0 Android source (paths under
`android/src/main/java/com/it_nomads/fluttersecurestorage/`):

- `FlutterSecureStorage.java:241–286,353–379`: cold init opens preferences,
  checks algorithm mismatch and initializes the cipher; mismatch goes through
  `handleKeyMismatch`, not an unconditional entry rewrite.
- `FlutterSecureStorage.java:1017–1072`: migration is conditional on
  `migrateOnAlgorithmChange`; with migration and reset disabled, return error.
  The enabled migration path can re-encrypt data; the production adapter already
  explicitly sets both options false, with backup migration false as well.
- `FlutterSecureStorage.java:486–510,614–671`: non-biometric migration first
  decrypts every matching entry; an undecryptable entry aborts before key deletion,
  marker updates or re-encryption. It does not silently skip/delete that entry.
  Successful migration re-encrypts the cache, but is disabled in our adapter.
- `ciphers/LegacyNamespaceKeyRecovery.java:77–79`: a present namespaced wrapped
  key makes legacy recovery a no-op; this fixture has one from its committed save.
- `FlutterSecureStorage.java:55–83,1323–1345`: read/decrypt failure propagates
  without deleting the entry when `resetOnError=false`.
- `ciphers/StorageCipherFactory.java:25–60`: missing algorithm markers are
  initialized in the separate configuration preferences; matching saved/current
  algorithms do not require re-encryption.
- `ciphers/StorageCipherImplementationGCM.java:28–54`: an existing wrapped AES
  key is unwrapped and returned, not regenerated on a normal cold init.

Debug diagnostics now snapshot structured entries across all three durability
stores, keeping the existing file fsync before ACK. Comparison is per entry,
independent of serialization order, and reports only `envelope_value`,
`envelope_removed`, `pointer_value`, `pointer_removed`, `kind_marker`,
`barrier_counter`, `plugin_internal_0`, `plugin_internal_1`,
`plugin_internal_2`, or `extra_key_added`. Internal indices identify the data,
wrapped-key, and configuration stores respectively; they never encode a key.
The recovery intent carries kind; kind embedded in the active pointer/envelope
is covered by their exact ciphertext comparison. Baseline still requires an
existing envelope and pointer. Comparison also runs immediately after the first
production read so removed entries are diagnosed before `absent` can mask them.

Only the exact unprefixed commit counter in each store may differ: it forces a
real SharedPreferences disk commit and carries no identity or cryptographic
state. This extends visibility; it does not relax the former identity snapshot.
All other changes, including plugin internals and additions, fail. Unknown
channel codes become `raw_values_changed`; script annotations retain their fixed
allowlist. Dart channel tests cover every category, counter-only success and
unknown-code suppression. **No finding is marked fixed and PA1 remains open
until Claude reruns native evidence.**

Host gates for this follow-up: `make check-dart` passed (784 formatted files,
clean analyzer, app_check, frozen-migration checks/selftests, four offline helper
tests); `make test-dart` passed (**1,372 tests, two opt-in skips, 10 packages**);
script self-tests `python3 -I -m unittest discover -s tools/scripts -p
 'test_session*.py'` passed **7/7**; `git diff --check` passed. Native Kotlin
compilation and emulator receipts remain Claude's Gradle/CI gates. No git writes.


### Owner-amended PA1 evidence definition (2026-10-23) — superseded

**Historical, superseded:** 907a550 passed with line-break normalization and no
pointer-ciphertext/key-rewrap notices. The cause was Base64.DEFAULT line wrapping
after the preferences round trip, not re-encryption or re-wrapping. The allowance
and debug AES unwrap below are no longer used. Current comparisons require
stored Base64 content identity, line breaks ignored; no writer investigation is
needed (backlog #92 closed).


The owner amended PA1: after a corrupted-envelope fault, compare the active
pointer by decrypted account key and registered kind, read through the real
`PluginSessionSecretStorage` with production options. Require the account key
written by the fault fixture (`probeStore().accountKey('synthetic-registered')`)
and schema version 1. Missing, undecodable or failed reads report only
`pointer_unreadable`; a changed decoded value reports `pointer_plaintext_changed`.
The envelope and account-kind/recovery-intent marker remain raw byte-identical.
For key loss, keep strict raw pointer/envelope/kind-marker comparisons: nothing
is decryptable by design. Plugin internals (except the same-material wrapped-key allowance below),
unexpected keys and pointer removal still fail; only the commit-barrier counter is generally permitted to change.

Reason: native cold start changes the pointer ciphertext while retaining its
decrypted account. Counting-fake restore tests prove no product writes; plugin
re-encryption with a fresh IV is suspected, but the writer is unidentified.
Retention is the security property, rather than pointer ciphertext identity.
Backlog #92 requires identifying the writer before A33's registered accounts.
The earlier strict-ciphertext diagnostics above are historical and superseded
only for the corrupted-envelope pointer comparison.

`pointer_ciphertext_changed` is a fixed informational notice, forwarded by the
probe status and harness to CI without any pointer/key/ciphertext values. It
does not waive pointer plaintext validation. Both faults still check typed
unavailable and zero anonymous/refresh sends before ACK and after a new PID.
The harness launches distinct `check-ciphertext` / `check-key` phases so the
key-loss path cannot accidentally accept pointer ciphertext changes. Android
execution of this amended definition remains Claude's Gradle/CI gate; no new
native receipt is claimed here.

Host gates for the owner-amended definition: Gates: `make check-dart` passed; `make test-dart` passed (1,379 tests, two opt-in skips, 10 packages; domain/text coverage 100%); session script self-tests passed (12/12); `git diff --check` passed. Gradle and CI remain Claude-owned.


### Wrapped-key retention classification (2026-10-23) — superseded

**Historical, superseded:** 907a550 passed with line-break normalization and no
pointer-ciphertext/key-rewrap notices. The cause was Base64.DEFAULT line wrapping
after the preferences round trip, not re-encryption or re-wrapping. The allowance
and debug AES unwrap below are no longer used. Current comparisons require
stored Base64 content identity, line breaks ignored; no writer investigation is
needed (backlog #92 closed).


The owner-amended ciphertext-fault policy also permits wrapped-key ciphertext
changes **only for the same AES key material**, verified by local unwrap of both
post-fault and current values with the existing namespaced RSA-OAEP private key
and `MessageDigest.isEqual`. Debug hooks emit only `wrapped_key_rewrapped`,
`wrapped_key_replaced`, `wrapped_key_removed` or `wrapped_key_unreadable`.
Only `wrapped_key_rewrapped` is informational for ciphertext faults; every other
category and any wrapped-key change during the key-loss fault still fail.
Envelope/kind bytes, decrypted pointer, typed unavailable and zero auth sends
remain required. Status accepts zero or more distinct fixed notices; unknown,
duplicate and non-ciphertext notices are rejected by the host harness.

Source assessment (local flutter_secure_storage 11.2.0 Android source):
`FlutterSecureStorage.continueInitialize` calls
`LegacyNamespaceKeyRecovery.recoverIfNeeded` before cipher initialization,
independently of the three disabled reset/migration options. Recovery re-wraps
the same AES key only if the target wrapper is absent, a source legacy wrapper
exists, and that source key decrypts a sample of this namespace's own data.
It uses randomized RSA-OAEP wrapping and asynchronous `apply()`. With the target
wrapper already present, it does nothing: ordinary GCM initialization unwraps
the existing key and returns without rewriting it. Recovery thus offers a
conditional re-wrap path, not proof of the observed writer in this fresh fixture.

If a wrapped-key `apply()` is lost before SIGKILL and recovery is unavailable,
`StorageCipherImplementationGCM` generates and stores a **new** random AES key
on absence, even with `resetOnError:false`. That is replacement and a real
data-loss risk, never accepted by this policy. Unwrap errors with migration and
reset disabled fail rather than intentionally rotate the AES key. The hook's
plugin remove/add discards caches and enables initialization again; it does not
itself re-wrap. `SessionStorageCommitter` commits wrapped-key/config stores
before ciphertext and changes only its barrier counter; it does not generate
or re-wrap keys. A prior successful barrier should therefore mitigate the
lost-apply explanation. The exact observed path remains unproven until Claude's
native rerun reports the new classification; PA1 remains open. Production code
is unchanged.

Host gates for wrapped-key classification: `make check-dart` passed; full mobile
subset (`flutter test -j 2` in `apps/mobile`) passed (649 tests, two opt-in skips);
`python3 -m unittest discover -s tools/scripts -p 'test_session*.py'` passed
(16 tests across both native-evidence and release-check harnesses);
`git diff --check` passed. Kotlin compile, `make build-it` and CI remain
Claude-owned and were not run here.

### Strict comparison follow-up (2026-10-23)

Removed both allowances and the debug AES unwrap. All pointer changes fail;
wrapped-key store changes classify as `plugin_internal_1`. Exactly one fixed
informational notice, `base64_wrapping_only`, records unequal strings that
compare equal under `sameValue`. It is permitted in any phase and printed as
`::notice`; real retention failures remain failures. Unknown/duplicate notices
are rejected without echoing values. The only mutable bookkeeping exception
is the commit-barrier counter. Host tests cover strict pointer/plugin rejection,
notice forwarding in all phases and failure preservation. Public Build checks
refuse destructive fault/barrier hooks on non-emulators; debug/dev gates remain.

Host gates for this follow-up: `make check-dart` passed (784 files, analyzer,
app_check, frozen migrations and four offline helper tests); mobile session,
storage, API and session-bootstrap tests passed (**199 passed, one opt-in
Identity skip**); `python3 -m unittest discover -s tools/scripts -p
 'test_session*.py'` passed (**15 tests**, both harness files);
`git diff --check` passed. Offline dependency refresh changed no tracked
lockfile/manifest. Kotlin compile and this follow-up's native CI remain
Claude-owned.
