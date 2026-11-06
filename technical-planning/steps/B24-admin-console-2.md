# B24 — Admin console 2: account controls

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B23 | S–M | Claude | ⬜ |

**Goal.** AD-011 controls and AD-007: revoke one device or all, disable/enable an account (refused requests with a clear problem type the app already treats as signed out), Buddy daily limit override, delete account through the existing B06 deletion. Typed confirmation, recent sign-in (< 15 min), audit rows, operator role only.

**Exit criteria**
1. Each control works end to end against the laptop server and is audited.
2. Revoked devices get 401 on the next request; a disabled account can't sync or use Buddy; delete leaves zero rows (B06 query).
3. Viewer can't run controls; a stale sign-in is asked to sign in again (tests).
4. Codex code + security review passed (Risky).

**Cross-card note (B23, 2026-11-06):** decide what `admin.audit_log` rows show for a deleted account (they keep the pseudonymous account ID as `target`; the log is append-only, so B24 picks a display rule or a documented retention, not an edit path). B24's deletion control also needs the recovery mount in the `admin` role (B23 P5).

## Low-level plan
_(after B23)_

## Progress log
- 2026-11-06: card created (runs right after B23, owner).
