# S06 — App shell

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S02 | M | ⬜ Not started |

**Goal.** An installable Flutter app with the final skeleton: flavors, navigation with four tabs, themes, localization scaffolding, the generated API client, error reporting, and the test harnesses. It runs on the owner's A55 from a CI build. Every feature step plugs into this.

**Spec:** UX-010 (tabs, placeholders), UX-040 (light/dark following system), UX-001 (baseline measurement), LC-002 (English UI), C-1 (Android in R1, D-081) · **Decisions:** TD-003, TD-004, TD-014, TD-034

## Scope
- `apps/mobile` in the Dart workspace. Package ID, app name "Fitness Buddy".
- **Flavors:** `dev` (local API), `staging`, `prod`. Android `applicationIdSuffix` per flavor, so they can be installed side by side. Config via `--dart-define-from-file`.
- **material_ui** package, **Riverpod 3** with codegen, **go_router** behind `AppRouter` with a `StatefulShellRoute` for **Today / Progress / Workouts / Me** (placeholder screens).
- Theme wiring: light/dark following the system (real tokens come in S07).
- **Localization:** gen-l10n with an `en` ARB, a lint/grep check against raw strings in widgets and against `left/right` (RTL readiness, `09` §3).
- **Feature folder skeleton** (`03` §3.2) with barrels, and the **import-boundary check** in CI.
- **API client wiring:** `fb_api_client` on dio with interceptors (base URL per flavor, `X-App-Version`, `X-Platform`, `X-Device-Id`, `X-Request-Id`, timeouts). A **non-blocking** `/v1/config` fetch after the first frame, cached locally with defaults. `Failure` mapping skeleton from problem-details `type` (`09` §8). `426` → an "update required" screen.
- **Sentry** initialised after the first frame (deferred), with PII scrubbing.
- **Test harnesses:** golden tests (alchemist) with one golden, an integration test (patrol) that launches the app and switches tabs.
- **Builds:** Android debug/release APK + AAB in CI (`mobile-release` skeleton). **No iOS work in R1** (D-081): no iOS pipeline, but no Android-only shortcuts in shared code, and only plugins that also support iOS.
- **Cold-start baseline** on the A55 (time to first frame, measured and recorded).

## Out of scope
- Real design (S07), local DB (S09), sign-in (S25).

## Fixed by the plan
- Packages and versions in `02` §1. Layering rules in `03` §2.
- Startup does no network work before the first frame (UX-001).

## Decide in the low-level plan
- How the APK reaches the owner during P0–P2 (a GitHub Actions artifact sideload vs Firebase App Distribution vs Play internal testing early). Default: the GitHub artifact until S29.
- Typed routes approach for go_router (codegen or hand-written route constants).

## Exit criteria
- [ ] The owner installs the staging build on the A55. Four tabs work, and light/dark follows the system.
- [ ] With staging up (S05) the app fetches `/v1/config`. With the API down it still starts normally (offline-first). Before S05, use the local API in `dev`.
- [ ] A forced `426` from the API shows the update screen.
- [ ] CI: analyze, unit, golden and integration tests green. The import-boundary and raw-string checks fail on deliberate violations.
- [ ] Cold start to first frame on the A55 recorded in the Outcome (budget: input bar ≤ 2 s, UX-001).

## Read first
`03-architecture.md` §2–3 · `02-tech-stack.md` §1 · `09-cross-cutting.md` §3, §6, §8–9

## Owner involvement
Install builds on the A55 and confirm they run.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
