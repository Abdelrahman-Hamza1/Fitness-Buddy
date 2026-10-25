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
