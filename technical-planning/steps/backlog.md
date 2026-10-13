# Backlog: follow-ups, tech debt & minor findings

Items found during steps that aren't done in that step. The orchestrator adds them at step close (`run-step` E2) and from reviews (`review-changes` §3), and schedules them into a later step's scope, or proposes a cleanup step to the owner when they pile up.

| # | From | Item | Severity | Target step | Status |
|---|---|---|---|---|---|
| 1 | S01 | NuGet lock files (`packages.lock.json`) once Dependabot + CPM support is solid | minor | S04 | open |
| 2 | S01 | Dependabot `docker` ecosystem entry (needs a Dockerfile) | minor | S03 | open |
| 3 | S01 | Verify Dependabot handles the pub workspace after its first monthly run; fallback: scheduled `dart pub outdated` | minor | next after first run | open |
| 4 | S01 | Flutter pin bump cadence: manual, quarterly (Dependabot covers the .NET SDK) | minor | recurring | open |
| 5 | S01 | Nightly `trace` workflow + "implemented" column in the report | minor | backlog | open |
| 6 | S01 | `fb_domain` coverage gate in CI | minor | S08 | done (S08 WP1) |
| 7 | S01 review | trace v0 counts `skip:` tests as covered (documented limitation) | minor | S47 or earlier | open |
| 8 | S01 review | Makefile: missing python3 is a parse-time error, so `make doctor` can't report it | nit | backlog | open |
| 9 | S01 review | `pubspec.lock` is `linguist-generated` (collapsed in diffs): add a check that every lock `url:` is `https://pub.dev` | nit | S02 | open |
| 10 | S01 security | Optional GitHub hardening: Actions allow-list + require full-SHA pinning, private vulnerability reporting, CodeQL for `actions`, owner 2FA check | minor | owner, any time | open |
| 11 | S01 security | Residual: flutter-action pins `actions/cache` by tag and doesn't verify the Flutter archive hash in CI (no secrets in CI, accepted) | nit | revisit at S05 | open |
| 12 | S01 security | Scheduled workflows stop after 60 days without repo activity (weekly NuGetAudit run) | nit | note | open |
| 14 | S01 security r2 | setup-dotnet.sh: unparseable URL port exits with a Python traceback instead of `die` (fails closed); cleanup trap quoting of `$work` | nit | next touch of the script | open |
| 15 | S01 security r2 | Optional: commit the expected .NET SDK sha512 next to `global.json` (today the hash comes from the same Microsoft host) | nit | backlog | open |
| 16 | S02 | Docker Hub anonymous pull limits on CI runners: if they bite, cache images (`docker save` + `actions/cache` keyed on digests) or mirror to GHCR | minor | when seen | open |
| 17 | S02 | Verify Dependabot's `docker-compose` updater bumps `tag@sha256` in `tools/contract-tools/compose.yaml` | minor | after first run | open |
| 18 | S02 | Enum schema transformer for the Host (proven snippet in `backend/README.md`) | minor | first step with an enum | open |
| 19 | S02 | Tag ruleset protecting `contracts-v*` (no update/delete), owner clicks | minor | S29 (first tag) | open |
| 20 | S02 | Move `Host/Config/` (`GET /v1/config`) into the Account module, same operationId + tag | minor | S24/S28 | open |
| 21 | S02 | Contract.Tests: validate runtime responses against the bundled schema generically, once there are several endpoints | minor | ~S26 | open |
| 22 | S02 | Host build prints an MVC "No action descriptors found" info line during OpenAPI generation; filter in logging config | nit | S03 | open |
| 23 | S02 r2 | contract-breaking.sh blocking mode: pass oasdiff githubactions output through the same annotation-only filter as conformance | nit | next touch | open |
| 24 | S02 r2 | fb-problem-json-errors accepts only one `allOf` level of ProblemDetails extension; recurse if a nested extension is ever needed | nit | when needed | open |
| 25 | S02 r2 | fb-oneof-discriminator compares mapping count, not targets (resolved doc loses `$ref` identity) | nit | accepted | open |
| 26 | S08 | Portion word علبة (can/box) is ambiguous and not mapped by the parser; resolve with real data | minor | S13/S15 | open |
| 27 | S08 | Promote `ManualClock` from fb_domain test helpers to a shared test package if S09+ needs a fake clock | nit | S09 | open |
| 28 | S08 r2 | Parser: two quantities in a row via x-count or glued unit ("2 x2 eggs", "2 100g rice") should be null; pin cases | minor | S15 | open |
| 29 | S08 r2 | Parser: zero gives null without `original` ("Coke 0"); document that callers catalog-match the raw text on null, pin "Coke 0" | minor | S15 | open |
| 30 | S08 r2 | Ban list shorthand: `clock?.now()` false positive; `[.now()]` / `{.now()}` not caught; stripComments EOF backslash guard | minor | S09 | open |
| 31 | S08 r2 | End-quantity-wins rule also applies to English implicit start portions ("cup of tea 2 tbsp"); document or pin | nit | S15 | open |
| 13 | S01 | Spec tidy: add a Release column to the UX-/AQ- tables, then drop the trace overrides | minor | owner, later | open |
