# 09 — Cross-Cutting Concerns

## 1. Notifications (`17-notifications.md`)

**All R1 notifications are local.** Every condition they depend on (meals logged, weigh-ins, plan days, Ramadan times, pending proposals, open batches) lives on the device. So there's no push server, no push tokens, and nothing personal leaves the phone for reminders (TD-013).

**Design: a pure planner + an idempotent scheduler.**

```
NotificationPlanner (fb_domain, pure):
  input:  prefs (on/off, times, quiet hours, master switch), now + tz, the next 7 days of:
          diary state, weigh-ins, weekly plan, Ramadan prayer times, pending proposals, open batches
  output: the exact list of notifications that should exist for the next 7 days
          (after NT-021 quiet hours, NT-022 max 2/day by priority, NT-023 skip-if-not-applicable)

NotificationScheduler (platform):
  diff(planned, currently scheduled) → cancel / schedule   (idempotent)
```

- **Re-plan triggers:** app start/resume, any change set (domain event), a settings change, a time-zone change, a Ramadan toggle, and the first open of each day.
- **Conditional reminders** (NT-001 "only if < 2 meals logged", NT-006 protein check) are scheduled assuming the condition holds, then **cancelled as soon as data makes them irrelevant**. Edge case: data logged on *another* device arrives only when this one syncs. That's acceptable and documented.
- **iOS limit:** 64 pending local notifications. A 7-day horizon × ≤ 2–3 per day fits, and the planner enforces the cap.
- **Deep links** (NT-024): each notification carries a route (`/today/pending/{id}`, `/body/weigh-in`, `/progress/review/{week}`), handled by go_router.
- **Wording** (NT-025): templates in ARB files, checked against SF-020's banned words.
- The planner is a pure function, so every rule in `17` gets a table-driven unit test.

## 2. Time, days & Ramadan

- **Day boundary:** an entry's `local_date` is the calendar date at the time eaten, in the zone at that time (DY-001/002). Suhoor at 03:30 on the 5th counts toward the 5th automatically (T31).
- **Week:** the `week_start` setting (default Saturday, LC-021). All weekly math (budget, summary, review, check-in) uses one `WeekCalendar` in `fb_domain`.
- **Ramadan calendar (LC-030):** Umm al-Qura Hijri conversion → Ramadan start/end per year + the user's ±1-day shift + a manual on/off. `RamadanCalendar` emits the periods used by slots (DY-012), targets (TG-060), chart shading (WB-021), the comparison (IN-008) and the "switch on Ramadan mode?" proposal (LC-031).
- **Prayer times (LC-033, NT-026):** `adhan_dart` computes Fajr/Maghrib offline from the city's coordinates (bundled city list) or opt-in device location. The calculation method is a setting with a regional default (G12).
- **Ramadan slot windows** derive from prayer times (e.g. Iftar = Maghrib → +3 h, Suhoor = Fajr − 3 h → Fajr), so automatic slot assignment works in Ramadan.
- **Testing:** a fake clock is injected everywhere. Time-zone and DST transitions and dates around Ramadan start/end are explicit test cases.

## 3. Localization & RTL (English UI in R1, Arabic UI in R2)

Cheap now, expensive later, so from the **first screen**:
- All strings in ARB files (gen-l10n). No string literals in widgets (lint check).
- **Directional layout only:** `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end`, never `left/right` (lint/grep check in CI).
- Numbers and dates go through `intl` formatters that will respect the digit-style setting (LC-004, R2).
- Golden tests for design-system components run in **LTR and RTL** from A02. Screen goldens run in LTR in R1, with RTL added at the start of R2.
- Bilingual food names (LC-005): display in the interface language, with the other language on details **when the food has one** (D-080).
- Buddy **understands** EN/AR/Arabizi in R1. Replies are English (AI-143). Per-message reply language comes in R2 (AI-141).
- Charts: time axes stay chronological (LC-003), handled in our chart wrappers.

## 4. Security & privacy

| Area | Measure |
|---|---|
| Authentication | Our Identity module (`04` §5): verified Google/Apple ID tokens, email one-time codes, short-lived ES256 JWTs, rotating refresh tokens with reuse detection |
| Authorization | Every handler scopes by the JWT's `UserId`. **Postgres RLS as defense in depth** (`04` §6). Tests assert user A can't read or write user B's data |
| Transport | HTTPS only (TLS by kamal-proxy / load balancer). HSTS. No plaintext endpoints |
| Secrets | No API keys in the app. AI provider keys, signing keys and database credentials live only in server secrets (`08` §4) |
| Tokens on the device | Keychain/Keystore via flutter_secure_storage |
| API hardening | Rate limits (per user, per IP), request size limits, strict schema validation in and out, timeouts on every outbound call, `Idempotency-Key` on unsafe POSTs, minimum-version gate |
| Abuse (R2/R3) | Fair-use limit (MN-020). Device attestation (App Attest / Play Integrity) on anonymous sign-up and AI calls before R3 |
| AI data minimization | Context builder whitelist (AC-041). No identity to the model. No images stored server-side. Paid no-training tiers. Zero data retention before R3 |
| Local data | App sandbox + OS full-disk encryption. **SQLCipher** is an R3 decision (performance and complexity cost) |
| Progress photos (R2) | App-private directory, excluded from OS backups, never synced, never sent to AI (WB-050, AC-043) |
| **Logging** | **No user content** (food text, weights, messages) in server logs, traces or Sentry. IDs and codes only. TD-058: JSON console + OpenTelemetry logging; every non-Sentry provider wraps exceptions into type + stack without messages, Data or inner messages. No HTTP logging or instrumentation `Enrich*`. Sentry errors-only `BeforeSend` allowlists headers and clears query/data/cookies/user/extra/exception values; breadcrumbs, transactions, SDK logs and metrics are dropped. Postgres ordinary statement-error logs are suppressed (FATAL/PANIC only, terse; no statement or parameter logs). Npgsql SQL/parameter/error-detail logging and command/batch/COPY/open tracing are disabled at source; EF uses a null logger with command diagnostics suppressed. Canary tests inspect logs, spans, metric tags and serialized Sentry envelopes |
| Dependencies | Lockfiles (pub, NuGet `packages.lock.json`). Renovate/Dependabot. Vulnerability scanning in CI. A one-line justification for every new package |
| Servers | `08` §6 |
| Compliance prep (R3) | Privacy policy EN/AR (AC-044), store data-safety forms. Account deletion and export already exist from R1 |

## 5. Observability

- **App:** Sentry crashes and errors (scrubbed), release health, performance spans for **cold start** (UX-001), the **Buddy round trip** (AQ-12) and slow frames.
- **API:** OpenTelemetry traces, metrics and logs (`08` §7). Per-request: request ID, user hash, endpoint, status, latency. Buddy calls add task, model, prompt version, tokens, cost and outcome code. **No content.**
- **Product-quality signals stay with the user:** proposal outcomes (confirmed unchanged / adjusted chips / discarded) are stored in the user's own data. They feed the user model, the owner's "how good is Buddy" view and, by choice, eval cases. **No product analytics in R1** (TQ-16).

## 6. Performance budgets (UX-001–007, AT-004)

| Budget | Target | How |
|---|---|---|
| Cold start → input bar ready | ≤ 2 s on the reference mid-range Android (**Samsung A55**, TQ-02) | Nothing network-bound before the first frame. DB opened in a background isolate. Indexed Today queries. Deferred init for Sentry, sync and notifications. Measured with an integration test on the device for each release candidate |
| Interaction latency | No frame > 16 ms on common screens. No blocking spinners on local data | Reactive local reads. Heavy computation (adaptive TDEE, long-range charts) off the UI isolate |
| Proposal recompute after a tap | ≤ 50 ms | Pure engine, no I/O |
| Buddy | ≤ 5 s p90 | `06` §10 |
| API (non-AI) | p95 ≤ 200 ms server time | Indexed queries, async I/O, measured by OpenTelemetry |
| App size | < 40 MB download | Offline pack < 10 MB. No heavy SDKs |

## 7. Accessibility (UX-070–072)

- Text scaling: layouts tested at 1.0 and 2.0 in golden tests (2.0 bounds 1.5; the big number, which clamps its scale at 1.5, also has a 1.5 row; A02 D9). The big numbers use responsive type.
- Contrast: design tokens checked for WCAG AA in both themes (automated test over the palette).
- Never colour alone: macro colours always come with labels. Over-target uses a neutral tone + text (SF-021).
- R2: semantics labels on all controls in EN + AR.

## 8. Error handling model

- **App:** expected failures are values: `sealed class Failure` (Offline, Timeout, RateLimited, AiUnavailable, InvalidInput, Conflict, NotFound, Unauthorized, UpgradeRequired…). The API client maps RFC 9457 `type` codes to them. Unexpected errors are exceptions, reported to Sentry. The UI maps each failure to plain-language copy + an action (UX-052). User input is always saved first, so no failure loses it.
- **API:** handlers return `Result<T, Error>`. A single mapping turns errors into problem details. Unhandled exceptions return a generic 500 with the request ID, never internals.
- **Buddy:** any failure → the message becomes `pending` with a retry path. Never a dead end.

## 9. Configuration & feature flags

- **App flavors:** `dev` (local API + worker + Postgres: `make up`, via `adb reverse`), `staging`, `prod`, each pointing at its own API base URL. Config via `--dart-define-from-file` (`apps/mobile/config/<flavor>.json`); from A11 the staging and prod CI builds take the URL from a GitHub Actions variable: the laptop test server until production (TD-064). The owner's daily app is the prod flavor.
- **Remote config:** `GET /v1/config` returns the minimum app version, feature flags (e.g. `buddy.photo_enabled`) and client thresholds (AI-060 values, so tuning needs no release). Cached locally, with safe defaults offline.
- **API configuration:** standard .NET configuration (appsettings + environment variables + secrets). Feature flags in config, read through an `IFeatureFlags` port.
- Unfinished features ship dark behind flags rather than living on long branches.
