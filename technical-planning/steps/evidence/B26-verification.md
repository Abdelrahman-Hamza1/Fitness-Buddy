# B26 security verification (Buddy agent breadth, server)

- **Review:** Codex security + privacy task, 2026-11-07. Verdict: changes required, 1 major, 2 minors.
- **Major:** turn streams kept the global recovery lease (connection pool exhaustion, account deletion blocked). Minors: label JPEG check only looked at the first bytes; label-only accounts never scheduled usage cleanup.
- **Fixes:** 3d586b73 (lease released for turn routes; ledger rechecks recovery per transaction), 249b1098 + dd6023bc (full base64 + JPEG structure incl. scan data and ≤1024 px before quota; cleanup scheduled in the label transaction).
- **Fix-check:** Codex, 2026-11-07: resolved (JPEG scan-data gap closed in dd6023bc).
- **Checked clean:** atomic message/send reservations, aggregate-only weekly context (images rejected), handle-scoped workout copy, no new content logging, label idempotency exemption.
- **Residual:** `buddy.attempts` kept until no pre-B26 instance can run (backlog #318), because laptop deploys aren't stop-the-world.
