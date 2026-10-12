# Backlog: follow-ups, tech debt & minor findings

Items found during steps that aren't done in that step. The orchestrator adds them at step close (`run-step` E2) and from reviews (`review-changes` §3), and schedules them into a later step's scope, or proposes a cleanup step to the owner when they pile up.

| # | From | Item | Severity | Target step | Status |
|---|---|---|---|---|---|
| 1 | S01 | NuGet lock files (`packages.lock.json`) once Dependabot + CPM support is solid | minor | S04 | open |
| 2 | S01 | Dependabot `docker` ecosystem entry (needs a Dockerfile) | minor | S03 | open |
| 3 | S01 | Verify Dependabot handles the pub workspace after its first monthly run; fallback: scheduled `dart pub outdated` | minor | next after first run | open |
| 4 | S01 | Flutter pin bump cadence: manual, quarterly (Dependabot covers the .NET SDK) | minor | recurring | open |
| 5 | S01 | Nightly `trace` workflow + "implemented" column in the report | minor | backlog | open |
| 6 | S01 | `fb_domain` coverage gate in CI | minor | S08 | open |
| 7 | S01 review | trace v0 counts `skip:` tests as covered (documented limitation) | minor | S47 or earlier | open |
| 8 | S01 review | Makefile: missing python3 is a parse-time error, so `make doctor` can't report it | nit | backlog | open |
| 9 | S01 review | `pubspec.lock` is `linguist-generated` (collapsed in diffs): add a check that every lock `url:` is `https://pub.dev` | nit | S02 | open |
| 10 | S01 security | Optional GitHub hardening: Actions allow-list + require full-SHA pinning, private vulnerability reporting, CodeQL for `actions`, owner 2FA check | minor | owner, any time | open |
| 11 | S01 security | Residual: flutter-action pins `actions/cache` by tag and doesn't verify the Flutter archive hash in CI (no secrets in CI, accepted) | nit | revisit at S05 | open |
| 12 | S01 security | Scheduled workflows stop after 60 days without repo activity (weekly NuGetAudit run) | nit | note | open |
| 14 | S01 security r2 | setup-dotnet.sh: unparseable URL port exits with a Python traceback instead of `die` (fails closed); cleanup trap quoting of `$work` | nit | next touch of the script | open |
| 15 | S01 security r2 | Optional: commit the expected .NET SDK sha512 next to `global.json` (today the hash comes from the same Microsoft host) | nit | backlog | open |
| 13 | S01 | Spec tidy: add a Release column to the UX-/AQ- tables, then drop the trace overrides | minor | owner, later | open |
