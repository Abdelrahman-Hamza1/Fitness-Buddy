# Crash reports setup (A11, errors only)

1. Create a free Sentry organization in the **EU region**, then a Flutter project.
2. In the project's Security & Privacy settings enable **Prevent storing IP
   addresses**, data scrubbing and default scrubbers; keep server-side scrubbing
   on. Enable spike protection in project quota/rate-limit settings. No product
   analytics, sessions, tracing, replay, native crash or ANR capture is intended.
3. **Wait for WP2's emulator envelope-sink proof to pass and be recorded** in
   `technical-planning/steps/evidence/A11-verification.md` before setting a DSN.
   The host self-test alone is insufficient. Until then, leave `FB_SENTRY_DSN`
   absent: error reporting stays off and builds still work.
4. Copy the EU ingest client DSN into GitHub repository **Actions secret**
   `FB_SENTRY_DSN` (not a variable, not Dependabot secrets). Never paste the DSN
   into an issue, command line, screenshot, run summary or committed config.
   Builds accept HTTPS EU ingest DSNs only and report key names on errors.
5. On the prod A55 build, long-press the About version and confirm the test
   report (once WP4 lands). Verify both handled and unhandled events appear.
   In event JSON, require scrubbed exception values, route templates only, no
   user content/canary, `user`, IP, device name/id or install identifiers; no
   session, log, metric or performance items. Record counts/results, never raw
   payloads or configuration values. Disable/delete the secret and investigate
   if any privacy check fails.

Dart error envelopes pass through the native SDK, whose initialization stays
on; native crash/ANR/NDK capture, native scope sync, sessions and client reports
are disabled. The independent security review must check these pins and the
emulator sink evidence before the real DSN is enabled.

## Crash-free check after dogfooding (A42, AT exit "crash-free sessions > 99.5 %")

Release health is **off** by design (A11 D11–D12, `09` §5: no sessions, no
native crash capture), so Sentry has no session count and can't show a
crash-free percentage. What can be read instead is **observed dogfood
errors**, a proxy: unhandled error events are not crashed sessions, the
number of opens is an estimate and native crashes aren't seen. The
"> 99.5 % crash-free sessions" criterion therefore stays **unverified**
unless release health is turned on (below) or the owner waives it. Until
then, after a dogfood period (e.g. two weeks of daily use on one release):

1. Sentry → Issues, filter `environment:prod`, `release:<the A55 build>`,
   `error.handled:false` (unhandled Dart errors: what a user feels as a crash
   or a broken screen). Note the issue count and each issue's event count.
2. The denominator is the app opens over the same period. The owner is the
   only R1 user: about 5–10 opens a day, so two weeks ≈ 100 opens.
   > 99.5 % crash-free over ~100 opens means **no unhandled error at all**;
   one unhandled event already fails it.
3. Native crashes (engine/plugin) aren't captured (`enableNativeCrashHandling`
   is off): ask the owner whether the app ever closed by itself, and check
   `adb logcat -b crash` on the A55 when it did.
4. Record it as "observed dogfood errors: N unhandled issues, M events over
   D days, release R" (counts only, never payloads) in the backlog item that
   tracks it (#262), not as a crash-free percentage.

Turning on Sentry release health (`enableAutoSessionTracking = true`, plus
native crash handling for "crashed" sessions) would give a real percentage,
but it sends a session envelope per app open with an installation identifier:
a privacy change to A11's design that needs the owner's approval first.
