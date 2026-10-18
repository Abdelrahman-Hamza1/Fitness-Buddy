# B03 verification — 2026-10-18

**Live activation verified and full branch CI green at947777b; exact squash CI still gates main.** The owner completed the
phone checks. No AI calls or personal-data requests were made. The full laptop power-cycle check
is a collected owner follow-up (backlog#76), not claimed here.

## Exit evidence

| Exit | Evidence |
|---|---|
| A55 mobile data, valid HTTPS, contract config | Owner switched Wi-Fi off and confirmed **all five PASS** on a temporary same-origin diagnostic page: HTTPS, database readiness, config200 matching exact response fields/types, real proxy ignoring spoofed HTTP protocol (HSTS retained),32hex trace header. Required client headers were fixed synthetic values. Owner accessed normal system-trusted HTTPS; no certificate exception requested. |
| Outside-tailnet / non-A55 denial | Owner disabled Tailscale, reran the network check, confirmed blocked, then reconnected. The non-A55 laptop HTTPS client also failed while phone requests succeeded. Applied policy validation passed for A55IPv4/IPv6→443, denied22/5199 and other IPv4/IPv6 sources. No third physical peer was available, so none is claimed. |
| Dev reset isolation; nightly dump restores | Actual `make down up` on dev completed; private phone database aggregate counts and readiness unchanged. Actual `serve-phone-backup` and isolated `restore-check` succeeded (9 module tables). Nightly user timer enabled; actual systemd service invocation returned `Result=success`, `ExecMainStatus=0`. |
| Runbook from stopped server | Actual `serve-phone-stop` → `serve-phone` succeeded, preserving database aggregate counts and readiness. Docker/Tailscale system services and backup user timer are enabled. Actual machine reboot is backlog#76, deferred under PROCESS.md A6; stack starts manually after login. |

The temporary diagnostic path/proxy and its process/file were removed after owner checks. Final
Serve configuration has **one handler, HTTPS443, Funnel off**. API publishes only127.0.0.1:5199;
Postgres publishes no port. Worker runs. Disposable dev containers stopped after isolation proof.
Local HTTPS status can be false **by design**: the A55-only policy also denies the laptop client;
loopback readiness and the owner's phone test distinguish this from server failure.

## Storage decision and deployment

Root is plain ext4. After risk of a lost/accessed disk exposing database/state/backups was explained,
the owner corrected their initial choice and **explicitly approved unencrypted storage for this
private laptop test server**. This is not production approval. A0600 receipt binds project,
hashed machine identity, selected-device policy, resolved state/Docker/backup paths and backing
mount sources. No receipt, wrong project or changed context fails closed; inspection failures do
not bypass checks. Owner configured local operator, HTTPS certificates and saved the exact ACL.

Runtime uses immutable image built only from freshly fetched main
**3cca0a89e551fc9e7f3181caa4a32d0f0a336fdf**. Final post-merge refresh will use the merged main SHA.
State/credentials/device addresses/hostname remain outside git. API/worker receive only app DB
credentials; migrate receives only migrator; dedicated read-only backup role is not a superuser.
No provider key or outward telemetry configured. URL wiring remains A11; identity/Buddy are later.

## Automated checks

- **22 Python safety tests**, all pass, plus shell syntax. Private state/credential preservation,
  relocated runtime execution and checkout rejection; no child-output leakage; immutable image;
  host-environment isolation; exact policy/device attestation; owner storage receipt scope/context
  invalidation; owned Serve/Funnel checks; failed-backup retention; scratch cleanup. Regression
  verifies **every policy test destination matches its source IP family**. The owner policy-editor
  caught the original cross-family assertion bug; access grants never changed to fix it.
- Synthetic Docker image smoke passes with
  **sha256:cd979c2105bb47436326c243f85955d0273917ad422ef8ca8e2ebd52f03a449a**. API UID1654,
  read-only/no caps, Production, loopback-only, config valid, OpenAPI404/sync501. Exact single bridge
  gateway trusted, forwarded HTTPS has HSTS, direct HTTP does not. Production backup role cannot
  write and has no admin/createdb/createrole/replication rights. FORCE RLS rows from two synthetic
  users restore as **2 rows / sum33**. Actual relocated controller executes backup/restore with
  the timer interpreter/arguments; restored scratch contains10 module tables (includes synthetic
  table). Actual dev compose in a disposable separate project is destroyed without phone data
  loss; stop/restart/migrations/worker pass. Synthetic resources cleaned up.
- `make check-dotnet test-dotnet`: **244 passed,0 failed/skipped**,0 build warnings/errors.
  Existing trusted/untrusted `ForwardedHeadersTests` pass. No C# code changed.
- `make check-contract`: lint/bundle/compatibility selftests/conformance pass. `make test-dart`:
  all **10 workspace packages** pass. Dart format499 files,0 changes.
- Initial local root analyzer crashed under exhausted7GB RAM/4GB swap; this is **not a local
  check pass**. Full Dart format/analyze/tests and generation subsequently passed in CI.

## Independent reviews

All reviewers GPT-6.1 Sol, none authored implementation.

- Plan:1 major (dedicated backup role),3 minors; amended, scoped recheck approved.
- Whole-diff code and separate security reviews at52b0379: each found the same1 major (relocated
  controller inferred wrong repository root, breaking timer). Fixed at3836b10; both rechecks
  approved, no remaining findings. Actual copied-controller subprocess and Docker tests prove fix.
- Owner storage exception delta864292a: independent code and separate security approvals,
  no blockers/majors; stale docs minors corrected.
- Address-family policy fix947777b: independent code recheck approved, no findings; grants unchanged
  and owner successfully saved policy. Physical results above cover actual proxy/network behavior.

## CI status

[Run39119556898](https://github.com/Abdelrahman-Hamza1/Fitness-Buddy/actions/runs/39119556898)
on ecc75f4: backend/image/contract/catalog/full Dart/Android build passed. First emulator attempt
reported3/3 tests passing but Gradle returned1; retry hung until45min timeout. Required ci failed,
not bypassed. Failure is tracked as app CI follow-up#77; app source/runner untouched.

[Run39129316527](https://github.com/Abdelrahman-Hamza1/Fitness-Buddy/actions/runs/39129316527)
on947777b: **required ci succeeded at13:05:36UTC**, all jobs passed including Android/emulator,
full Dart/generation, dotnet/image/contract/catalog. No app source or runner change and no CI bypass.
The earlier runner failure remains tracked as an observed non-quarantined follow-up, not an open
red gate. Independent reviewer approved actual exit coverage with reboot follow-up collected.
Only `merge-step.sh` may move main, and only after required ci is green on the actual squash SHA.
