# B16 security audit (pre-production part), 2026-11-07

Scope: everything built by R1 on `main` 6130e178, before production exists (B13/B14 not started). Production checks (Hetzner hardening, SSH/firewall, TLS scan, restore drill, AT-006 on production) remain in B16.

## Method
- Five read-only Codex audits, checklist basis OWASP ASVS 4 Level 1 (+ selected L2 for auth/session) for the API and MASVS-lite for the app:
  1. Identity, auth and sessions (Google OIDC, email codes, guest linking, tokens, refresh reuse, devices, disable/deletion, console auth, rate limits).
  2. Server authorization, data and privacy (endpoint scoping, RLS and grants per role, SECURITY DEFINER functions, sync, export, worker, admin reads, quota, logging, retention).
  3. Buddy AI server (prompt injection paths and what an injected model can do, sealed continuation, ledger fencing, minimum context, label endpoint, cost/DoS limits, key handling).
  4. Mobile app (secure storage, backups, manifest exposure, network config, logging/telemetry, export files, photos, trace gating, sign-out/deletion wipe, release flags).
  5. Infrastructure, secrets and supply chain (laptop compose stack, Tailscale exposure, secret files, backups, images, GitHub Actions, git history).
- Mechanical checks: `dotnet list package --vulnerable --include-transitive` (all projects clean); OSV batch query of all 200 pub packages in `pubspec.lock` (no known vulnerabilities); scan of tracked files for secret-shaped strings and tailnet names (none; the infra audit also scanned 9,397 historical blobs, only the synthetic test credential).
- Raw reports: kept in the session scratchpad; findings and fixes summarised here.

## Result: no critical or high findings

| # | Area | Severity | Finding | Resolution |
|---|---|---|---|---|
| 1 | Identity | Medium | Unauthenticated code requests for someone's email invalidate their live code and burn the hourly quota (sign-in denial) | Fixed on `chore/security-audit-server`: issued codes stay valid, guesses bounded per challenge. Quota exhaustion remains, backlog #337 |
| 2 | Server data | Medium | Expired email challenges, idle throttle buckets and expired sessions are never deleted | Fixed: bounded Identity cleanup (server branch) |
| 3 | Server data | Low | `admin_device_keys` returned `app_version` unscrubbed | Fixed: `identity.admin_version` (server branch) |
| 4 | Buddy | Medium | An injected model could encode private numbers as a GTIN and leak them to Open Food Facts via `lookup_barcode` | Fixed: only a digit run the user typed in a message that names a barcode (server branch); spaced/dashed codes refused, backlog #338 |
| 5 | Buddy | Low | Turn photos checked only by their first bytes (size/dimension bound not enforced) | Fixed: the label endpoint's full JPEG validator (server branch) |
| 6 | Infra | Medium | `init-roles.sh` passed database passwords as `psql --set` arguments (visible in the process list during first init) | Fixed: `\getenv` inside the SQL heredoc (server branch) |
| 7 | App | Medium | Export share copies survived account deletion / "remove" on sign-out | Fixed on `chore/security-audit-app` (owned handoff list, deleted at removal, in-flight exports abandoned; a removal mid-share deletes the exact copies, a plain switch keeps them) |
| 8 | App | Low | Gallery originals (with EXIF) stay in the image_picker cache | Not reliably fixable with the pinned plugin; backlog #335 |
| 9 | App | Low | No FLAG_SECURE: sensitive screens visible in Recents/screen capture | Owner decision (it also blocks the owner's screenshots); backlog #336 |

## Fix-checks
Two Codex fix-check rounds. Round 1 found three fixes incomplete (a shared guess budget that let an attacker lock out a valid code, barcode lookups allowed for any typed digit run, export copies left by a removal that raced the platform copy, plus a switch that broke a legitimate share); fixed. Round 2 confirmed the email lockout gone (brute-force bound unchanged) and the switch/generation fixes, and found two last gaps, fixed without a third round: barcode words matched inside other words ("lean"), and a share that failed after copying skipped the cleanup.

## Checked and clean (summary of the audits' lists)
OIDC validation (signature, audience, issuer, nonce, expiry); email-code randomness, expiry, attempt limits, HMAC with external pepper, constant-time compare; 15-min ES256 access tokens, 30-day refresh families with rotation and reuse revocation; device revocation and disabled-account gates; atomic deletion with lifecycle fencing; console subject-pinned allow-list, 12 h sessions, antiforgery + origin checks, re-auth; FORCE RLS on user tables and role separation; definer search paths and PUBLIC revocations; sync limits and parameterized queries; atomic quota reservations; content-free logs, scrubbed exceptions and telemetry; Buddy continuation crypto and binding, attempt fencing, disclosure budgets, proposals-only action tools, aggregate-only weekly mode, `store:false`, no SDK retries; mobile Keystore storage, backup exclusions, no exported components or deep links, HTTPS-only staging/prod, origin-bound bearer, telemetry scrubbing, release debugging off; loopback-only host ports, no Funnel, non-root read-only containers with dropped capabilities, digest/SHA pins, read-only CI tokens, no `pull_request_target`.

## Not verified here
Live Tailscale ACLs and deployed file modes, device behaviour of the photo/export fixes, and everything production (B13/B14).
