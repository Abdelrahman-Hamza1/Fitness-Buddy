# B04 verification

Local implementation/review gates passed. The exact-squash CI gate in `merge-step.sh` is required before main moves.

## Scope and trust boundary

Guest accounts, Google/email sign-in, refresh/logout, guest linking, JWKS/current account and
private laptop configuration/recovery. Owner accepted TD-077 on2026-10-18. Pre-auth capabilities
trust application-validated provider proofs/principal IDs; API has no migrator credentials or
unrestricted database bypass. Unencrypted storage remains private-laptop only under B03 approval.
No paid AI calls or real Google sign-in were made during implementation.

## Independent reviews

- Fresh GPT-6.1 Sol concrete SQL review: fixed ambiguous output-column predicates and simultaneous
  cross-session guest upgrade race; user-row-before-session locking and exact upgrade check approved
  on scoped recheck before schema implementation.
- Fresh GPT-6.1 Sol whole-diff code review: fixed Docker restore project copy and auth-specific
  privacy evidence; majors cleared on recheck. Failure-delivery code canary minor fixed.
- Separate fresh GPT-6.1 Sol security review: key tamper/rotation recovery, exact ACL/RLS and actual
  logging/telemetry/audit canary tests added; Google optional nbf check fixed. Scoped recheck approved
  security code, subject to remaining full verification evidence.

## Evidence so far

- Full backend baseline274 tests:274 passed,0 failed/skipped.
- Expanded focused auth/provider/key/privacy suite30 tests passed;3 additional concurrent email/link/logout/refresh cases pass in the full290-test suite.
-25 Python phone operator tests passed, including missing-secret refusal, stable secrets, web-only
  Google audience, private unprivileged overlay and recovery excluding delivered codes.
- Contract lint and server conformance passed after contract-first generated-client handoff.
- Expanded full290 tests caught2 framework default-type regressions (404/500); writer corrected to
  apply framework defaults before customization; repeat `make check-dotnet test-dotnet` passed290/290 with0 failures/skips.

## Image and integration evidence

- Baseline image smoke passed: UID1654, config200, repeated migrations exit0, worker exit0,
  readiness503 when Postgres is unavailable while liveness stays200, graceful stop1second.
  Engine image180472055 bytes; gzipped local image archive74356107 bytes.
- Enabled private overlay smoke passed using synthetic OAuth IDs/keys and the shipped Production
  image: unprivileged operator UID and read-only key mounts, explicit key provisioning, guest/me,
  refresh rotation/reuse revocation, email challenge/verify/logout and recovery backup.
- Backup role's complete RLS dump restored into scratch;20 module tables present and the synthetic
  two-user data preserved (2rows/sum33). No real user database, Tailscale policy or Google provider touched.
- `make gen-check` passed. Repository analyzer is clean. All10 Dart workspace packages pass;
  domain and text line coverage remain100%.
- App catalogue consistency required a4-file owner-approved exception: auth error constants,
  typed ForbiddenFailure, mappings and expectations. Independent code/security rechecks approved it.

## Remaining evidence

Full root `make check test` completed successfully (10 Dart packages and290 backend tests). CI on the exact squash commit is required by the merge script. Private main-image activation/readiness and backup/recovery
receipts are maintained in the operator log after the merge; branch images are never deployed.
Owner real Google sign-in remains an explicit collected follow-up under PROCESS A6; no success claim
until actually performed. App-side native Google integration is A20/A33.
