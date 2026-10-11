# S49 — Security review, restore drill & R1 sign-off

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P8 Hardening | S47, S48 | M | ⬜ Not started |

**Goal.** Close R1 properly: a security review of everything we built ourselves, a fresh restore drill, a complete traceability report, and two weeks of the owner using Fitness Buddy as their only tracker.

**Spec:** AT-001, AT-006, AT-007, SC-1, SC-6, AC-040–043 · **Decisions:** TD-024, TD-028

## Scope
- **Security review** (checklist-driven):
  - Auth: token lifetimes, refresh reuse, OIDC validation, email-code brute force, linking edge cases.
  - Authorization: every endpoint scoped by user, RLS tests, a crafted cross-user request suite.
  - Secrets and logs: no secrets in the repo/images, no user content in logs, traces or Sentry (sampled audit).
  - Dependencies: vulnerability scan clean or triaged.
  - Servers: SSH closed, firewall rules, OS patch status, TLS config scan.
  - AI: prompt-injection review (no write paths), context minimization check (AC-041).
  - Findings fixed or ticketed with a decision.
- **Restore drill:** a point-in-time restore of production into a scratch environment, timed, and the runbook updated (SC-6).
- **Traceability report** (AT-001): every R1 ID implemented and tested, or moved by a recorded decision.
- **AT-006:** reinstall + new-phone restore + export completeness, re-verified on production.
- **AT-007:** the owner uses it as the **only tracker for 2 weeks** with no blocking issue. SC-1 is checked at 4 weeks.
- Release notes for R1. Update `technical-planning/` to reflect what was built (Outcomes → docs).

## Out of scope
- R2 work.

## Fixed by the plan
- AT-001 to AT-007 in `spec/40` §1.

## Decide in the low-level plan
- The security checklist source (e.g. OWASP ASVS level 1 subset for APIs + MASVS-lite for the app).

## Exit criteria
- [ ] The security review is documented. No open high-severity findings.
- [ ] The restore drill meets the targets (≤ 1 min data loss, ≤ 1 h recovery).
- [ ] The traceability report shows 100% of R1 IDs covered or explicitly deferred.
- [ ] AT-006 and AT-007 met. **R1 done.**

## Read first
`09-cross-cutting.md` §4 · `08-infrastructure-and-operations.md` §5–6 · `spec/40-acceptance-criteria.md` §1

## Owner involvement
Two weeks of exclusive use. A final sign-off.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
